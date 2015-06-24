/*
 * Copyright (c) 2013 Northwestern Polytechnical University, China
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * LowpanP - Implementation of 6LoWPAN
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author WU Wen<wuwen21999@126.com>
 * @author Wu Qian
 * @date 2011/04/17
 * @description
 */
#include "tinyv6.h"
#include "lowpan.h"

module LowpanFragP {
    provides interface LowpanFrag;

    uses interface Boot;
    uses interface AMSend;
    uses interface Receive;
    uses interface SplitControl as RadioControl;
    uses interface Ipv6Packet;
    uses interface Leds;
    uses interface AMPacket;
    uses interface PacketAcknowledgements as Acks;
}
implementation {

    enum {
        S_IDLE,
        S_SEND_NO_FRAG,
        S_SEND_FIRST_FRAG,
        S_SEND_SUSBSEQUENT_FRAG,
    };

    enum {
        RETX_MAX = 8,
    };

    uint8_t state;
    message_t pkt;
    uint8_t pkt_size;
    uint8_t rx_buf[IPV6_MIN_MTU];

    uint8_t *sending_buf;
    uint16_t sending_buf_len;
    uint16_t sending_buf_remaining_len;
    am_addr_t sending_buf_dst;
    uint8_t n_retx;

    uint16_t current_datagram_tag;

    event void Boot.booted()
    {
        call RadioControl.start();
        state = S_IDLE;
    }

    event void RadioControl.startDone(error_t e) { }
    event void RadioControl.stopDone(error_t e) {}

    command error_t LowpanFrag.send(uint8_t *buf, uint16_t len, am_addr_t am_next_hop)
    {
        nx_struct lowpan_frag1_hdr *hdr;
        uint8_t max_payload_size;

        if (state == S_IDLE) {
            lowpanfrag_printf("next hop:<%u>\n", am_next_hop);
            max_payload_size = call AMSend.maxPayloadLength();
            sending_buf_dst = am_next_hop;
            sending_buf = buf;
            sending_buf_len = len;
            if (len < max_payload_size) {
                /* can fit in a single am packet */
                uint8_t *p;
                p = (uint8_t*) call AMSend.getPayload(&pkt, len);
                memcpy(p, buf, len);
                n_retx = 0;
                call Acks.requestAck(&pkt);
                state = S_SEND_NO_FRAG;
                call AMSend.send(am_next_hop, &pkt, len);
                lowpanfrag_printf("AMSend to %u\n", am_next_hop);
            } else {
                /* need frag */
                uint8_t lowpan_frag_header_size;
                uint8_t frag_size;
                lowpanfrag_printf("==== frag start ====\n");
                sending_buf_remaining_len = len;
                lowpan_frag_header_size = sizeof(*hdr);
                frag_size = ((max_payload_size - lowpan_frag_header_size)>>3)<<3;
                pkt_size = frag_size + lowpan_frag_header_size;
                lowpanfrag_printf("pkt_size=%u\n", pkt_size);
                hdr = (nx_struct lowpan_frag1_hdr *) call AMSend.getPayload(&pkt, pkt_size);
                hdr->lowpan_frag_datagram_size = len;
                hdr->lowpan_frag_dispatch |= LOWPAN_DISPATCH_FRAG1&0xf8;
                hdr->lowpan_frag_datagram_tag = ++current_datagram_tag;
                memcpy(hdr->lowpan_frag_data, buf, frag_size);
                n_retx = 0;
                call Acks.requestAck(&pkt);
                call AMSend.send(sending_buf_dst, &pkt, pkt_size);
                sending_buf_remaining_len -= frag_size;
                state = S_SEND_FIRST_FRAG;
            }
            return SUCCESS;
        } else {
            lowpanfrag_printf("state=%hhu, not S_IDLE, FAIL\n", state);
            return FAIL;
        }
    }

    void send_done()
    {
        lowpanfrag_printf("sendDone\n");
        signal LowpanFrag.sendDone(sending_buf, sending_buf_len);
    }

    event void AMSend.sendDone(message_t *m, error_t e)
    {
        uint8_t max_payload_size;

        if (sending_buf_dst != AM_BROADCAST_ADDR && !call Acks.wasAcked(m)) {
            /* previous send not ACKed, resend this pkt */
            /* NOTE: broadcast pkts have no ACK */
            if (n_retx < RETX_MAX) {
                n_retx++;
                lowpanfrag_printf("retx=%hhu\n", n_retx);
                call AMSend.send(sending_buf_dst, m, pkt_size);
            } else {
                state = S_IDLE;
                lowpanfrag_printf("retx > MAX, to S_IDLE\n");
            }
        } else {
            if (state == S_SEND_NO_FRAG) {
                state = S_IDLE;
                send_done();
            } else if (state == S_SEND_FIRST_FRAG || state == S_SEND_SUSBSEQUENT_FRAG) {
                if (sending_buf_remaining_len > 0) {
                    uint8_t lowpan_frag_header_size;
                    uint8_t frag_size;
                    nx_struct lowpan_fragn_hdr *hdr;

                    lowpanfrag_printf("continue send frag\n");
                    max_payload_size = call AMSend.maxPayloadLength();
                    lowpan_frag_header_size = sizeof(*hdr);
                    if (sending_buf_remaining_len + lowpan_frag_header_size > max_payload_size) {
                        frag_size = ((max_payload_size - lowpan_frag_header_size)>>3)<<3;
                    } else {
                        frag_size = sending_buf_remaining_len;
                    }
                    pkt_size = frag_size + lowpan_frag_header_size;
                    lowpanfrag_printf("pkt_size=%u\n", pkt_size);
                    hdr = (nx_struct lowpan_fragn_hdr *) call AMSend.getPayload(&pkt, pkt_size);
                    hdr->lowpan_frag_datagram_size = sending_buf_len;
                    hdr->lowpan_frag_dispatch |= LOWPAN_DISPATCH_FRAGN&0xf8;
                    hdr->lowpan_frag_datagram_tag = current_datagram_tag;
                    hdr->lowpan_frag_datagram_offset = 
                        (sending_buf_len - sending_buf_remaining_len)>>3&0xff;
                    lowpanfrag_printf("buf_len=%u, sending_buf_remaining_len=%u\n", sending_buf_len, sending_buf_remaining_len);

                    memcpy(hdr->lowpan_frag_data,
                            sending_buf + (sending_buf_len - sending_buf_remaining_len),
                            frag_size);
                    call AMSend.send(sending_buf_dst, &pkt, pkt_size);
                    sending_buf_remaining_len -= frag_size;
                    state = S_SEND_SUSBSEQUENT_FRAG;
                } else {
                    lowpanfrag_printf("==== frag end ====\n");
                    state = S_IDLE;
                    send_done();
                }
            }
        }
    }

    event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len)
    {
        static unsigned int size;
        static unsigned int tag;
        static uint16_t offset;
        uint8_t *buf = rx_buf;
        uint8_t dispatch;
        lowpanfrag_printf("recv:\n");
        dispatch = *((uint8_t*)payload);
        if (dispatch == LOWPAN_DISPATCH_IPV6 || dispatch == LOWPAN_DISPATCH_HC1) {
            memcpy(buf, payload, len);
            signal LowpanFrag.recv(buf, len, call AMPacket.source(msg));
        } else if ((dispatch&0xf8) == LOWPAN_DISPATCH_FRAG1) {
            /* reconstruct packet */
            nx_struct lowpan_frag1_hdr *hdr;
            hdr = (nx_struct lowpan_frag1_hdr*) payload;
            lowpanfrag_printf(" --- start reconstruct ---\n");
            size = (nx_uint16_t)(hdr->lowpan_frag_datagram_size&0x07ff);
            tag = hdr->lowpan_frag_datagram_tag;
            lowpanfrag_printf("header=0x%04x, tag=%u\n", hdr->lowpan_frag_datagram_size, hdr->lowpan_frag_datagram_tag);
            offset = len - sizeof(*hdr);
            lowpanfrag_printf("local offset=%u\n", offset);
            memcpy(buf, hdr->lowpan_frag_data, len - sizeof(*hdr));
        } else if ((dispatch&0xf8) == LOWPAN_DISPATCH_FRAGN) {
            nx_struct lowpan_fragn_hdr *hdr;
            hdr = (nx_struct lowpan_fragn_hdr*) payload;
            if ( size == (nx_uint16_t)(hdr->lowpan_frag_datagram_size&0x07ff) &&
                    tag == hdr->lowpan_frag_datagram_tag &&
                    offset == hdr->lowpan_frag_datagram_offset<<3) {

                lowpanfrag_printf("header=0x%04x, tag=%u, offset=%u\n", hdr->lowpan_frag_datagram_size, hdr->lowpan_frag_datagram_tag, hdr->lowpan_frag_datagram_offset);

                memcpy(buf+(hdr->lowpan_frag_datagram_offset<<3),
                        hdr->lowpan_frag_data,
                        len - sizeof(*hdr));
                offset += len - sizeof(*hdr);
                lowpanfrag_printf("local offset=%u\n", offset);
            } else {
                lowpanfrag_printf("something mismatch\n"); 
            }

            if (offset == size) {
                lowpanfrag_printf("--- end reconstruct ---\n");
                signal LowpanFrag.recv(rx_buf, size, call AMPacket.source(msg));
            }
        }
        return msg;
    }
}
