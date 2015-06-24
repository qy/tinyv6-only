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
 * Implementation of UDP protocol
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/16
 * @description
 */

module UdpP {
	provides interface Udp;
	uses interface Ipv6;
	uses interface Ipv6Packet;
	uses interface Ipv6Address;
	uses interface Leds;
}
implementation {
	/*
	 * must have src_port&dst_port&length filled
	 */
	command void Udp.send(ip6_t *ip6)
	{
		nx_struct t6_udphdr *udphdr = call Ipv6Packet.udphdr(ip6);
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);

		ip6hdr->t6_plen = udphdr->length;
        ip6hdr->t6_nxt = UDP;

		ip6hdr->t6_src = call Ipv6Address.global();

		udphdr->chksum = 0;
		udphdr->chksum = call Ipv6Packet.checksum(ip6);
		udp_printf("send:t6_plen=%u\n", ip6hdr->t6_plen);
		call Ipv6.send(ip6);
	}

	event void Ipv6.recv(ip6_t *ip6)
	{
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
		
        // assert(len == udphdr->length);
        udp_printf("recv:t6_plen=%u\n", ip6hdr->t6_plen);
        signal Udp.recv(ip6);
	}

	event void Ipv6.sendDone(ip6_t *ip6)
	{
	}
}

