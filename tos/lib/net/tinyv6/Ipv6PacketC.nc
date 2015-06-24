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
 * Ipv6PacketP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/18
 * @description
 */
#include "tinyv6.h"

module Ipv6PacketC {
	provides interface Ipv6Packet;
}
implementation {
	command uint8_t *Ipv6Packet.raw(ip6_t *ip6)
	{
		return ip6->data;
	}
	command nx_struct t6_iphdr *Ipv6Packet.ip6hdr(ip6_t *ip6)
	{
		return (nx_struct t6_iphdr*) ip6->data;
	}
	command uint8_t *Ipv6Packet.ip6Payload(ip6_t *ip6)
	{
		return ip6->data + sizeof(nx_struct t6_iphdr);
	}
	command nx_struct t6_udphdr *Ipv6Packet.udphdr(ip6_t *ip6)
	{
		return (nx_struct t6_udphdr*) call Ipv6Packet.ip6Payload(ip6);
	}
	command nx_struct t6_icmphdr *Ipv6Packet.icmp6hdr(ip6_t *ip6)
	{
		return (nx_struct t6_icmphdr*) call Ipv6Packet.ip6Payload(ip6);
	}
	command uint16_t Ipv6Packet.length(ip6_t *ip6)
	{
		return (call Ipv6Packet.ip6hdr(ip6))->t6_plen + sizeof(nx_struct t6_iphdr);
	}
	command uint8_t *Ipv6Packet.udpPayload(ip6_t *ip6)
	{
		return (call Ipv6Packet.ip6Payload(ip6)) + sizeof(nx_struct t6_udphdr);
	}
	command uint16_t Ipv6Packet.udpPayloadLength(ip6_t *ip6)
	{
		/* udp length field including the udp header */
		return (call Ipv6Packet.udphdr(ip6))->length - sizeof(nx_struct t6_udphdr);
	}

	command nx_struct t6_tcphdr *Ipv6Packet.tcphdr(ip6_t *ip6)
	{
		return (nx_struct t6_tcphdr*) call Ipv6Packet.ip6Payload(ip6);
	}
	command uint8_t *Ipv6Packet.tcpPayload(ip6_t *ip6)
	{
		nx_struct t6_tcphdr *tcphdr = call Ipv6Packet.tcphdr(ip6);

		return (call Ipv6Packet.ip6Payload(ip6)) + ((tcphdr->tcp_hdrlen>>4) * 4);
	}
	command uint16_t Ipv6Packet.tcpPayloadLength(ip6_t *ip6)
	{
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
		nx_struct t6_tcphdr *tcphdr = call Ipv6Packet.tcphdr(ip6);
		uint16_t len;

		len = ip6hdr->t6_plen - ((tcphdr->tcp_hdrlen>>4) * 4);
		return len;
	}

	command uint16_t Ipv6Packet.checksum(ip6_t *ip6)
	{
		uint32_t cksum = 0;
		uint16_t i;
		nx_struct t6_iphdr *ip6hdr;

		ip6hdr = call Ipv6Packet.ip6hdr(ip6);

		for (i = 0; i < sizeof(nx_struct t6_addr); i++) {
			if (i % 2) {
				cksum += ((uint8_t *)&ip6hdr->t6_src)[i];
			} else {
				cksum += (((uint8_t *)&ip6hdr->t6_src)[i] << 8) & 0xff00;
			}
		}
		for (i = 0; i < sizeof(nx_struct t6_addr); i++) {
			if (i % 2) {
				cksum += ((uint8_t *)&ip6hdr->t6_dst)[i];
			} else {
				cksum += (((uint8_t *)&ip6hdr->t6_dst)[i] << 8) & 0xff00;
			}
		}
		cksum += ip6hdr->t6_plen;
		cksum += ip6hdr->t6_nxt;
		for (i = 0; i < ip6hdr->t6_plen; i++) {
			uint8_t *p = call Ipv6Packet.ip6Payload(ip6);
			if (i % 2) {
				cksum += p[i];
			} else {
				cksum += (p[i] << 8) & 0xff00;
			}
		}
		cksum = (cksum >> 16) + (cksum & 0xffff);
		cksum += (cksum >>16);
		return (~cksum)&0xffff;
	}
}
