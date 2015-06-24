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
 * TcpP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/20
 * @description
 */

module TcpP {
	provides interface Tcp;
	uses interface Ipv6;
	uses interface Timer<TMilli> as MSLTimer;
	uses interface Timer<TMilli> as DelayedAckTimer;
	uses interface Timer<TMilli> as TimeoutTimer;
	uses interface Ipv6Packet;
	uses interface Ipv6Address;
	uses interface Random;
}
implementation {
	enum {
		CLOSED,
		LISTEN,
		SYN_SENT,
		SYN_RCVD,
		ESTABLISHED,
		CLOSE_WAIT,
		LAST_ACK,
		FIN_WAIT_1,
		FIN_WAIT_2,
		CLOSING,
		TIME_WAIT,
	};

	enum {
		FIN = 0x01,
		SYN = 0x02,
		RST = 0x04,
		PSH = 0x08,
		ACK = 0x10,
		URG = 0x20,
	};
	enum {
		MSL_TIMEOUT = 1024UL,
		DELAYED_ACK_TIMEOUT = 20UL,
		TIMEOUT = 600*1024UL, //TODO
	};

	uint8_t state = CLOSED;
	uint16_t g_src_port, g_dst_port;
	nx_struct t6_addr g_dst;
	uint32_t g_seq;
	uint32_t g_ack;
	uint32_t g_bind_port;

	uint8_t ip6_small_buf[sizeof(nx_struct t6_iphdr)+sizeof(nx_struct t6_tcphdr)+20];
	ip6_t ip6_small_pkt = {
		.data = ip6_small_buf,
	};

	uint8_t is_ack(nx_struct t6_tcphdr *tcphdr)
	{
		return tcphdr->tcp_flags&ACK;
	}
	uint8_t is_syn(nx_struct t6_tcphdr *tcphdr)
	{
		return tcphdr->tcp_flags&SYN;
	}
	uint8_t is_fin(nx_struct t6_tcphdr *tcphdr)
	{
		return tcphdr->tcp_flags&FIN;
	}
	uint8_t is_rst(nx_struct t6_tcphdr *tcphdr)
	{
		return tcphdr->tcp_flags&RST;
	}

	/*
	 * suppose the t6_plen is filled
     * 
     * fmt: 
     * 
     *  l - ip payload length
     *  s - tcp source port
     *  d - tcp dest port
     *  q - tcp seq number
	 *  a - tcp ack number
     *  h - tcp header length
     *  f - tcp flags
     *  w - tcp window size
     *  u - tcp urgent pointer
     *
	 */
	void send(ip6_t *ip6, char *fmt, ...)
	{
        va_list ap;
        char *p;
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
		nx_struct t6_tcphdr *tcphdr = call Ipv6Packet.tcphdr(ip6);

		if (call DelayedAckTimer.isRunning()) {
			call DelayedAckTimer.stop();
			tcp_printf("cancel delayed ack\n");
		}

        /* default values */
		tcphdr->tcp_sport = g_src_port;
		tcphdr->tcp_dport = g_dst_port;
		tcphdr->tcp_seq = g_seq;
		tcphdr->tcp_ack = g_ack;
		tcphdr->tcp_hdrlen = ((sizeof(nx_struct t6_tcphdr))/4)<<4;
		tcphdr->tcp_flags = 0;
		tcphdr->tcp_win = IPV6_MIN_MTU-sizeof(nx_struct t6_iphdr)-sizeof(nx_struct t6_tcphdr); //TODO: set to how much?
		tcphdr->tcp_cksum = 0;
		tcphdr->tcp_urp = 0;

		ip6hdr->t6_src = call Ipv6Address.global();
		ip6hdr->t6_dst = g_dst;
        ip6hdr->t6_nxt = TCP;
		ip6hdr->t6_plen = ((tcphdr->tcp_hdrlen)>>4)*4;

        /* set specific fields according to 'fmt' */
        va_start(ap, fmt);
        for (p = fmt; *p; p++) {
            switch(*p) {
                case 'l':
                    ip6hdr->t6_plen = va_arg(ap,unsigned);
                    break;
                case 's':
                    tcphdr->tcp_sport = va_arg(ap, unsigned);
                    break;
                case 'd':
                    tcphdr->tcp_dport = va_arg(ap, unsigned);
                    break;
                case 'q':
                    tcphdr->tcp_seq= va_arg(ap, unsigned);
                    break;
                case 'a':
                    tcphdr->tcp_ack = va_arg(ap, unsigned);
                    break;
                case 'h':
                    tcphdr->tcp_hdrlen = va_arg(ap, unsigned);
                    break;
                case 'f':
                    tcphdr->tcp_flags = va_arg(ap, unsigned);
                    break;
                case 'w':
                    tcphdr->tcp_win = va_arg(ap, unsigned);
                    break;
                case 'u':
                    tcphdr->tcp_urp = va_arg(ap, unsigned);
                    break;
                default:
                    tcp_printf("send: fmt '%c' not recognized\n", *p);
                    break;
            }
        }
        va_end(ap);

        /* checksum after all fileds are filled */
		tcphdr->tcp_cksum = call Ipv6Packet.checksum(ip6);

		call Ipv6.send(ip6);
	}

	void send_syn()
	{
		ip6_t *ip6 = &ip6_small_pkt;

		tcp_printf("send syn\n");
		send(ip6,"f", SYN);
	}
	void send_ack()
	{
		ip6_t *ip6 = &ip6_small_pkt;

		tcp_printf("send ack\n");
		send(ip6, "f", ACK);
	}
	void send_syn_ack()
	{
		ip6_t *ip6 = &ip6_small_pkt;

		tcp_printf("send syn_ack\n");
		send(ip6, "f", SYN|ACK);
	}
	void send_fin()
	{
		ip6_t *ip6 = &ip6_small_pkt;
		tcp_printf("send fin\n");

		send(ip6, "f", FIN|ACK);
		g_seq++; // FIN consumes seq
	}
	void send_rst(uint16_t sport, uint16_t dport)
	{
		ip6_t *ip6 = &ip6_small_pkt;
		tcp_printf("send rst\n");

		send(ip6, "fsdaw", RST, sport, dport, 0, 0);
	}

	void delay_ack()
	{
		if (call DelayedAckTimer.isRunning()) {
			call DelayedAckTimer.stop();
		}
		call DelayedAckTimer.startOneShot(DELAYED_ACK_TIMEOUT);
	}

	command void Tcp.bind(uint16_t port)
	{
		tcp_printf("bind port=%u\n", port);
		g_bind_port = port;
		if (state == CLOSED) {
			state = LISTEN;
		}
	}

	command void Tcp.connect(nx_struct t6_addr dst, uint16_t sport, uint16_t dport)
	{
		tcp_printf("connect\n");
		if (state == CLOSED) {
		//	src_port = sport;
		//	dst_port = dport;
			g_dst = dst;
			send_syn();
			state = SYN_SENT;
		}
	}

	command void Tcp.close()
	{
		tcp_printf("close\n");
		if (state == ESTABLISHED || state == SYN_RCVD) {
			send_fin();
			state = FIN_WAIT_1;tcp_printf("FIN_WAIT_1\n");
		} else if (state == SYN_SENT) {
			state = CLOSED;tcp_printf("4-CLOSED\n");
			signal Tcp.closed();
		} else if (state == CLOSE_WAIT) {
			send_fin();
			state = LAST_ACK;tcp_printf("LAST_ACK\n");
		}
	}

	/*
	 * @param len: then length of tcp payload
	 *
	 */

	uint8_t ip6_buf[IPV6_MIN_MTU];
	ip6_t ip6_pkt = {
		.data = ip6_buf,
	};

	command void Tcp.send(uint8_t *buf, uint16_t len)
	{
		ip6_t* ip6 = &ip6_pkt;
		nx_struct t6_tcphdr *tcphdr = call Ipv6Packet.tcphdr(ip6);

		tcp_printf("Tcp.send, len=%u\n", len);

		if (state == ESTABLISHED) {
            tcphdr->tcp_hdrlen = ((sizeof(nx_struct t6_tcphdr))/4)<<4; // tcpPayload uses this
			memcpy(call Ipv6Packet.tcpPayload(ip6), buf, len);
			tcp_printf("Tcp send, len=%u\n", len);
			send(ip6,"lf",  len + sizeof(*tcphdr), ACK);
			g_seq += len;
		}
	}

	event void Ipv6.sendDone(ip6_t *ip6)
	{
		tcp_printf("sendDone\n");
	}

    task void signalEof()
    {
			tcp_printf("signal eof\n");
			signal Tcp.eof();
    }

	event void Ipv6.recv(ip6_t *ip6)
	{
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
		nx_struct t6_tcphdr *tcphdr = call Ipv6Packet.tcphdr(ip6);

		if (state == CLOSED) {
			tcp_printf("CLOSED, discard\n");
			return;
		}

		tcp_printf("Ipv6.recv: src=%s,plen=%u\n", ip6str(ip6hdr->t6_src), ip6hdr->t6_plen);
		tcp_printf("syn=%hhu,fin=%hhu,ack=%hhu\n", is_syn(tcphdr), is_fin(tcphdr), is_ack(tcphdr));
        tcp_printf("port: remote[s=%u,d=%u],local[s=%u,d=%u]\n", tcphdr->tcp_sport, tcphdr->tcp_dport, g_src_port, g_dst_port);

		if (state != LISTEN) {
			if (tcphdr->tcp_dport != g_src_port || 
				tcphdr->tcp_sport != g_dst_port) {
				tcp_printf("port mismatch: remote[s=%u,d=%u],local[s=%u,d=%u]\n", tcphdr->tcp_sport, tcphdr->tcp_dport, g_src_port, g_dst_port);
                //send_rst(tcphdr->tcp_dport, tcphdr->tcp_sport); // swap the src/dst port
				return;
			}
		}

		switch (state) {
			case LISTEN:
				// 3-way handshake passive open
				if (is_syn(tcphdr)) {
					if (tcphdr->tcp_dport == g_bind_port) {
						state = SYN_RCVD; tcp_printf("1-SYN_RCVD\n");
						//reverse ip & port
						g_dst = ip6hdr->t6_src;
						g_src_port = tcphdr->tcp_dport;
						g_dst_port = tcphdr->tcp_sport;
						g_seq = call Random.rand32();
						g_ack = tcphdr->tcp_seq;
						g_ack++; // SYN consumes a sequence number
						send_syn_ack();
					}
				} else {
					tcp_printf("L%d:discard\n", __LINE__);
				}
				break;
			case SYN_SENT:
				if (is_ack(tcphdr) && is_syn(tcphdr)) {
                    g_seq++; // SYN consumes seq
					// g_ack = tcphdr->tcp_seq;
					delay_ack();
					tcp_printf("L%d:set delay ack\n", __LINE__);
					state = ESTABLISHED; tcp_printf("1-ESTABLISHED\n");
				} else if (is_syn(tcphdr)) {
					state = SYN_RCVD; tcp_printf("2-SYN_RCVD\n");
					g_ack++; // SYN consumes a sequence number
					send_syn_ack();
				} else {
					tcp_printf("L%d:discard\n", __LINE__);
				}
				call TimeoutTimer.startOneShot(TIMEOUT);
				//TODO: here's a timeout
				break;
			case SYN_RCVD:
				if (is_rst(tcphdr)) {
					state = LISTEN;tcp_printf("LISTEN\n");
				} else if (is_syn(tcphdr)) {
					tcp_printf("rx SYN in SYN_RCVD state\n");
					//reverse ip & port
					g_dst = ip6hdr->t6_src;
					g_src_port = tcphdr->tcp_dport;
					g_dst_port = tcphdr->tcp_sport;
					//g_seq = call Random.rand32();
					g_ack = tcphdr->tcp_seq;
					g_ack++; // SYN consumes a sequence number
					send_syn_ack();
				} else if (is_ack(tcphdr)) {
                    g_seq++; // SYN consumes seq
					state = ESTABLISHED; tcp_printf("2-ESTABLISHED\n");
					signal Tcp.accept((call Ipv6Packet.ip6hdr(ip6))->t6_src,
						(call Ipv6Packet.tcphdr(ip6))->tcp_sport);
				} else {
					tcp_printf("L%d:discard\n", __LINE__);
				}
				call TimeoutTimer.startOneShot(TIMEOUT);
				break;
			case ESTABLISHED:
				//assert(g_ack == tcphdr->tcp_seq);
				tcp_printf("len=%u\n", call Ipv6Packet.tcpPayloadLength(ip6));
				if (is_fin(tcphdr)) {
					state = CLOSE_WAIT; tcp_printf("CLOSE_WAIT\n");
					g_ack++; // FIN consumes a seq
					delay_ack();
					post signalEof();
				}
				if (call Ipv6Packet.tcpPayloadLength(ip6) > 0) {
					g_ack += call Ipv6Packet.tcpPayloadLength(ip6);
					delay_ack();
					tcp_printf("L%d:set delay ack\n", __LINE__);
					signal Tcp.recv(ip6);
				}
				break;
			case LAST_ACK:
				if (is_ack(tcphdr)) {
					state = CLOSED;tcp_printf("1-CLOSED\n");
					signal Tcp.closed();
				} else {
					tcp_printf("L%d:discard\n", __LINE__);
				}
				call TimeoutTimer.startOneShot(TIMEOUT);
				break;
			case FIN_WAIT_1:
				if (is_fin(tcphdr) && is_ack(tcphdr)) {
					state = TIME_WAIT;tcp_printf("1-TIME_WAIT\n");
					call MSLTimer.startOneShot(2*MSL_TIMEOUT);
					g_ack++; // FIN consumes a sequence number
					delay_ack();
					tcp_printf("L%d:set delay ack\n", __LINE__);
				} else if (is_fin(tcphdr)) {
					state = CLOSING;tcp_printf("CLOSING\n");
					g_ack++; // FIN consumes a sequence number
					delay_ack();
					tcp_printf("L%d:set delay ack\n", __LINE__);
				} else if (is_ack(tcphdr)) {
					state = FIN_WAIT_2;tcp_printf("FIN_WAIT_2\n");
				} else {
					tcp_printf("L%d:discard\n", __LINE__);
				}
				call TimeoutTimer.startOneShot(TIMEOUT);
				break;
			case CLOSING:
				if (is_ack(tcphdr)) {
					state = TIME_WAIT;tcp_printf("2-TIME_WAIT\n");
					call MSLTimer.startOneShot(2*MSL_TIMEOUT);
				} else {
					tcp_printf("L%d:discard\n", __LINE__);
				}
				call TimeoutTimer.startOneShot(TIMEOUT);
				break;
			case FIN_WAIT_2:
				if (is_fin(tcphdr)) {
					g_ack++; // FIN consumes a sequence number
					delay_ack();
					tcp_printf("L%d:set delay ack\n", __LINE__);
					state = TIME_WAIT;tcp_printf("3-TIME_WAIT\n");
					call MSLTimer.startOneShot(2*MSL_TIMEOUT);
				} else {
					tcp_printf("L%d:discard\n", __LINE__);
				}
				call TimeoutTimer.startOneShot(TIMEOUT);
				break;
			default:
				tcp_printf("state=%u\n", state);
				tcp_printf("L%d:discard\n", __LINE__);
				break;
		}
	}

	event void MSLTimer.fired()
	{
		if (state == TIME_WAIT || state == SYN_SENT) {
			state = CLOSED;tcp_printf("2-CLOSED\n");
			signal Tcp.closed();
		}
	}
	
	event void DelayedAckTimer.fired()
	{
		tcp_printf("delayed timer fired\n");
		send_ack();
	}
	event void TimeoutTimer.fired()
	{
		tcp_printf("timeout timer fired\n");
		state = CLOSED;
		signal Tcp.closed();
	}
}
