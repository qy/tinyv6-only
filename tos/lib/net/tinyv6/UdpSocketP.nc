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
 * UdpSocketP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/13
 * @description
 */

#include "tinyv6.h"

module UdpSocketP {
	provides interface UdpSocket;
	uses interface Udp;
	uses interface Ipv6Packet;
	uses interface Leds;
}
implementation {

	uint16_t binded_port;
	nx_struct t6_addr binded_addr;

	uint8_t ip6_buf[IPV6_MIN_MTU];
	ip6_t ip6_pkt = {
		.data = ip6_buf,
	};
	ip6_t *ip6_tx = &ip6_pkt;

	command void UdpSocket.bind(struct sockaddr_t6 saddr)
	{
		binded_port = saddr.st6_port;
		binded_addr = saddr.st6_addr;
	}

	command void UdpSocket.sendto(void *buf, uint16_t len, struct sockaddr_t6 saddr)
	{
		nx_struct t6_udphdr *udphdr = call Ipv6Packet.udphdr(ip6_tx);
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6_tx);

		udp_socket_printf("udp sendto: len=%u\n", len);

		udphdr->src_port = binded_port;
		udphdr->dst_port = saddr.st6_port;
		udphdr->length = len + sizeof(nx_struct t6_udphdr);
		ip6hdr->t6_dst = saddr.st6_addr;

		if (len <= IPV6_MIN_MTU) {
			memcpy(call Ipv6Packet.udpPayload(ip6_tx), buf, len);
			call Udp.send(ip6_tx);
		} else {
			/* no ip fragmentation, can't send udp packet bigger than MTU */
			udp_socket_printf("udp sendto: len=%u to large to send\n", len);
		}
	}

	event void Udp.recv(ip6_t *ip6)
	{
		struct sockaddr_t6 saddr;
		nx_struct t6_udphdr *udphdr = call Ipv6Packet.udphdr(ip6);
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);

		udp_socket_printf("recv: len=%u,dst_port=%u,binded_port=%u\n", call Ipv6Packet.udpPayloadLength(ip6), udphdr->dst_port, binded_port);
		if (udphdr->dst_port == binded_port) {
			uint8_t *payload;
			uint16_t len;

			saddr.st6_addr = ip6hdr->t6_src;
			saddr.st6_port = udphdr->src_port;
			payload = call Ipv6Packet.udpPayload(ip6) ;
			len = call Ipv6Packet.udpPayloadLength(ip6);
			signal UdpSocket.recvfrom(payload, len, saddr);
					
		}
	}
}
