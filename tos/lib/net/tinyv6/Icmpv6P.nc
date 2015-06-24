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
 * Icmpv6P
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/17
 * @description
 */
#include "tinyv6.h"

module Icmpv6P {
    provides interface Icmpv6;
    uses interface Ipv6;
    uses interface Ipv6Packet;
    uses interface Ipv6Address;
    uses interface Leds;
}
implementation {
    /* type for ICMPv6 message */
    enum {
        ICMP_DESTINATION_UNREACHABLE = 1,
        ICMP_PACKET_TOO_BIG = 2,
        ICMP_TIME_EXCEEDED = 3,
        ICMP_PARAMETER_PROBLEM = 4,

        ICMP_ECHO_REQUEST = 128,
        ICMP_ECHO_REPLY = 129,
        ICMP_NDP_ROUTER_SOLICITATION = 133,
        ICMP_NDP_ROUTER_ADVERTISEMENT = 134,
        ICMP_NDP_NEIGHBOR_SOLICITATION = 135,
        ICMP_NDP_NEIGHBOR_ADVERTISEMENT = 136,
        ICMP_NDP_REDIRECT = 137,
    };

    /* code for ICMP_DESTINATION_UNREACHABLE */
    enum {
        NO_ROUTE_TO_DESTINATION = 0, 
        COMMUNICATION_WITH_DESTINATION = 1,
        BEYOND_SCOPE_OF_SOURCE_ADDRESS = 2,
        ADDRESS_UNREACHABLE = 3,
        PORT_UNREACHABLE = 4,
        SOURCE_ADDRESS_FAILED_INGRESS_EGRESS_POLICY = 5,
        REJECT_ROUTE_TO_DESTINATION = 6
    };

    /* code for ICMP_PARAMETER_PROBLEM */
    enum {
        ERRONEOUS_HEADER_FIELD_ENCOUNTERED = 0,
        UNRECOGNIZED_NEXT_HEADER_TYPE_ENCOUNTERED = 1,
        UNRECOGNIZED_IPV6_OPTION_ENCOUNTERED = 2,
    };

    uint8_t ip6_buf[128];
    ip6_t ip6_pkt = {
        .data = ip6_buf,
    };

    command void Icmpv6.destinationUnreachable(nx_struct t6_addr dst, uint8_t code)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);

        memset(ip6_buf, 0, sizeof(ip6_buf));
        ip6hdr->t6_plen = sizeof(*icmp6hdr);
        ip6hdr->t6_nxt = ICMP;
        ip6hdr->t6_dst = dst;
        ip6hdr->t6_src = call Ipv6Address.global();
        icmp6hdr->t6_icmptype = ICMP_DESTINATION_UNREACHABLE;
        icmp6hdr->t6_icmpcode = code;
        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }
    command void Icmpv6.packetTooBig(nx_struct t6_addr dst, uint32_t mtu)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);

        memset(ip6_buf, 0, sizeof(ip6_buf));
        ip6hdr->t6_plen = sizeof(*icmp6hdr);
        ip6hdr->t6_nxt = ICMP;
        ip6hdr->t6_dst = dst;
        ip6hdr->t6_src = call Ipv6Address.global();
        icmp6hdr->t6_icmptype = ICMP_PACKET_TOO_BIG;
        icmp6hdr->t6_icmpcode = 0;
        icmp6hdr->t6_icmpmtu = mtu;
        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }
    command void Icmpv6.timeExceeded(nx_struct t6_addr dst)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);

        memset(ip6_buf, 0, sizeof(ip6_buf));
        ip6hdr->t6_plen = sizeof(*icmp6hdr);
        ip6hdr->t6_nxt = ICMP;
        ip6hdr->t6_dst = dst;
        ip6hdr->t6_src = call Ipv6Address.global();
        icmp6hdr->t6_icmptype = ICMP_TIME_EXCEEDED;
        icmp6hdr->t6_icmpcode = 0;
        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }
    command void Icmpv6.parameterProblem(nx_struct t6_addr dst, uint8_t code)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);

        memset(ip6_buf, 0, sizeof(ip6_buf));
        ip6hdr->t6_plen = sizeof(*icmp6hdr);
        ip6hdr->t6_nxt = ICMP;
        ip6hdr->t6_dst = dst;
        ip6hdr->t6_src = call Ipv6Address.global();
        icmp6hdr->t6_icmptype = ICMP_PARAMETER_PROBLEM;
        icmp6hdr->t6_icmpcode = code;
        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }

    command void Icmpv6.echoRequest(nx_struct t6_addr dst, uint16_t id)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);
        static uint16_t seq = 0;

        memset(ip6_buf, 0, sizeof(ip6_buf));
        ip6hdr->t6_plen = sizeof(*icmp6hdr);
        ip6hdr->t6_nxt = ICMP;
        ip6hdr->t6_dst = dst;
        ip6hdr->t6_src = call Ipv6Address.global();
        icmp6hdr->t6_icmptype = ICMP_ECHO_REQUEST;
        icmp6hdr->t6_icmpcode = 0;
        icmp6hdr->t6_icmpid = id;
        icmp6hdr->t6_icmpseq = seq++;
        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }

    /*
     * commands for NDP
     */

    command void Icmpv6.ndpTxRouterSolicitation()
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);

        memset(ip6_buf, 0, sizeof(ip6_buf));

        ip6hdr->t6_plen = sizeof(*icmp6hdr);
        ip6hdr->t6_nxt = ICMP;

        /* all-router multicast address = ff02::2 */
        ip6hdr->t6_dst.t6_ipaddr32[0]= 0xff020000; 
        ip6hdr->t6_dst.t6_ipaddr32[1]= 0; 
        ip6hdr->t6_dst.t6_ipaddr32[2]= 0; 
        ip6hdr->t6_dst.t6_ipaddr32[3]= 2; 

        ip6hdr->t6_src = call Ipv6Address.global();
        icmp6hdr->t6_icmptype = ICMP_NDP_ROUTER_SOLICITATION;
        icmp6hdr->t6_icmpcode = 0;
        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }

    command void Icmpv6.ndpTxRouterAdvertisement(uint8_t cur_hop_limit, uint8_t flags, uint16_t router_lifetime,
            uint32_t reachable_time, uint32_t retx_timer)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);
        nx_struct ndp_ra_msg *ram;

        memset(ip6_buf, 0, sizeof(ip6_buf));
        ram = (nx_struct ndp_ra_msg *)icmp6hdr->t6_icmpdata8;
        ip6hdr->t6_plen = sizeof(*icmp6hdr)+sizeof(*ram);
        ip6hdr->t6_nxt = ICMP;

        /* all-nodes multicast address = ff02::1 */
        ip6hdr->t6_dst.t6_ipaddr32[0]= 0xff020000; 
        ip6hdr->t6_dst.t6_ipaddr32[1]= 0; 
        ip6hdr->t6_dst.t6_ipaddr32[2]= 0; 
        ip6hdr->t6_dst.t6_ipaddr32[3]= 1; 

        ip6hdr->t6_src = call Ipv6Address.global();
        icmp6hdr->t6_icmptype = ICMP_NDP_ROUTER_ADVERTISEMENT;
        icmp6hdr->t6_icmpcode = 0;

        ram->cur_hop_limit = cur_hop_limit;
        ram->flags = flags;
        ram->router_lifetime = router_lifetime;
        ram->reachable_time = reachable_time;
        ram->retx_timer = retx_timer;

        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }

    command void Icmpv6.ndpTxNeighborSolicitation(nx_struct t6_addr target)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);
        nx_struct ndp_ns_msg *nsm;

        memset(ip6_buf, 0, sizeof(ip6_buf));
        nsm = (nx_struct ndp_ns_msg*)icmp6hdr->t6_icmpdata8;
        ip6hdr->t6_plen = sizeof(*icmp6hdr)+sizeof(*nsm);
        ip6hdr->t6_nxt = ICMP;
        /* all-nodes multicast address = ff02::1 */
        ip6hdr->t6_dst.t6_ipaddr32[0]= 0xff020000;
        ip6hdr->t6_dst.t6_ipaddr32[1]= 0; 
        ip6hdr->t6_dst.t6_ipaddr32[2]= 0; 
        ip6hdr->t6_dst.t6_ipaddr32[3]= 1; 
        ip6hdr->t6_src = call Ipv6Address.linklocal();

        icmp6hdr->t6_icmptype = ICMP_NDP_NEIGHBOR_SOLICITATION;
        icmp6hdr->t6_icmpcode = 0;
        nsm->target = target;
        nsm->option.type = NDP_OPTION_SOURCE_LINK_LAYER_ADDRESS;
        nsm->option.length = 1;
        nsm->option.un_addr.amaddr = TOS_NODE_ID;

        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }

    command void Icmpv6.ndpTxNeighborAdvertisement(nx_struct t6_addr dst, nx_struct t6_addr target, uint8_t flags)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);
        nx_struct ndp_na_msg *nam;

        memset(ip6_buf, 0, sizeof(ip6_buf));
        nam = (nx_struct ndp_na_msg*)icmp6hdr->t6_icmpdata8;
        ip6hdr->t6_plen = sizeof(*icmp6hdr)+sizeof(*nam);
        ip6hdr->t6_nxt = ICMP;
        ip6hdr->t6_dst = dst;
        ip6hdr->t6_src = call Ipv6Address.linklocal();

        icmp6hdr->t6_icmptype = ICMP_NDP_NEIGHBOR_ADVERTISEMENT;
        icmp6hdr->t6_icmpcode = 0;

        nam->un_fr.reserved = 0;
        nam->un_fr.flags = flags;
        nam->target = target;
        nam->option.type = NDP_OPTION_TARGET_LINK_LAYER_ADDRESS;
        nam->option.length = 1;
        nam->option.un_addr.amaddr = TOS_NODE_ID;

        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }

    command void Icmpv6.ndpTxRedirect(nx_struct t6_addr dst,
            nx_struct t6_addr target, nx_struct t6_addr redirect_dst)
    {
        ip6_t *ip6 = &ip6_pkt;
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        nx_struct t6_icmphdr *icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);
        nx_struct ndp_redirect_msg *nrm;

        memset(ip6_buf, 0, sizeof(ip6_buf));
        nrm = (nx_struct ndp_redirect_msg*)icmp6hdr->t6_icmpdata8;
        ip6hdr->t6_plen = sizeof(*icmp6hdr)+sizeof(*nrm);
        ip6hdr->t6_nxt = ICMP;
        ip6hdr->t6_dst = dst;
        ip6hdr->t6_src = call Ipv6Address.global();

        icmp6hdr->t6_icmptype = ICMP_NDP_REDIRECT;
        icmp6hdr->t6_icmpcode = 0;
        icmp6hdr->t6_icmpdata32[0]= 0;

        nrm->target = target;
        nrm->dst = redirect_dst;

        icmp6hdr->t6_icmpcksum = 0;
        icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
        call Ipv6.send(ip6);
    }

    event void Ipv6.recv(ip6_t *ip6)
    {
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);

        if (ip6hdr->t6_nxt == ICMP) {
            nx_struct t6_icmphdr *icmp6hdr;
            uint16_t orig_checksum;

            icmp_printf("rx icmp pkt\n");

            icmp6hdr = call Ipv6Packet.icmp6hdr(ip6);
            // check for checksum
            orig_checksum = icmp6hdr->t6_icmpcksum;
            icmp6hdr->t6_icmpcksum = 0;
            if (call Ipv6Packet.checksum(ip6) != orig_checksum) {
                icmp_printf("mine=0x%04x, t6_icmpcksum=0x%04x\n", 
                        call Ipv6Packet.checksum(ip6), orig_checksum);
                return;
            }
            icmp_printf("cksum ok\n");

            switch(icmp6hdr->t6_icmptype) {
                case ICMP_ECHO_REQUEST:
                    // send back Icmp Echo Reply
                    icmp_printf("ICMP_ECHO_REQUEST\n");
                    ip6hdr->t6_dst = ip6hdr->t6_src;
                    if (call Ipv6Address.type(ip6hdr->t6_src) == IPV6_ADDR_TYPE_LINKLOCAL) {
                        ip6hdr->t6_src = call Ipv6Address.linklocal();
                    } else {
                        ip6hdr->t6_src = call Ipv6Address.global();
                    }
                    icmp6hdr->t6_icmptype = ICMP_ECHO_REPLY;
                    icmp6hdr->t6_icmpcksum = 0;
                    icmp6hdr->t6_icmpcksum = call Ipv6Packet.checksum(ip6);
                    call Ipv6.send(ip6);
                    icmp_printf("send ICMP_ECHO_REPLY with cksum 0x%04x\n", icmp6hdr->t6_icmpcksum);
                    break;
                case ICMP_ECHO_REPLY:
                    icmp_printf("ICMP_ECHO_REPLY\n");
                    signal Icmpv6.echoReply(ip6hdr->t6_src, icmp6hdr->t6_icmpid);
                    break;
                case ICMP_NDP_ROUTER_SOLICITATION:
                    icmp_printf("ICMP_NDP_ROUTER_SOLICITATION\n");
                    signal Icmpv6.ndpRxRouterSolicitation(ip6);
                    break;
                case ICMP_NDP_ROUTER_ADVERTISEMENT:
                    icmp_printf("ICMP_NDP_ROUTER_ADVERTISEMENT\n");
                    signal Icmpv6.ndpRxRouterAdvertisement(ip6);
                    break;
                case ICMP_NDP_NEIGHBOR_SOLICITATION:
                    icmp_printf("ICMP_NDP_NEIGHBOR_SOLICITATION\n");
                    signal Icmpv6.ndpRxNeighborSolicitation(ip6);
                    break;
                case ICMP_NDP_NEIGHBOR_ADVERTISEMENT:
                    icmp_printf("ICMP_NDP_NEIGHBOR_ADVERTISEMENT\n");
                    signal Icmpv6.ndpRxNeighborAdvertisement(ip6);
                    break;
                case ICMP_NDP_REDIRECT:
                    icmp_printf("ICMP_NDP_REDIRECT\n");
                    signal Icmpv6.ndpRxRedirect(ip6);
                    break;
                default: 
                    icmp_printf("unknow icmp6 type=0x%02X\n", icmp6hdr->t6_icmptype);
                    break;
            }
        }
    }

    event void Ipv6.sendDone(ip6_t *ip6)
    {
    }
}
