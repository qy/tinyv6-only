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
 * Ipv6Packet
 *
 * @author qiuying@mail.nwpu.edu.cn
 * @author Wu Qian
 * @date 2011/04/18
 * @description
 */
#include "tinyv6.h"

interface Ipv6Packet {
	command uint8_t *raw(ip6_t *ip6);
	command nx_struct t6_iphdr *ip6hdr(ip6_t *ip6);
	command uint8_t *ip6Payload(ip6_t *ip6);
	command nx_struct t6_udphdr *udphdr(ip6_t *ip6);
	command nx_struct t6_icmphdr *icmp6hdr(ip6_t *ip6);
	command uint16_t length(ip6_t *ip6);
	command uint8_t *udpPayload(ip6_t *ip6);
	command uint16_t checksum(ip6_t *ip6);
	command uint16_t udpPayloadLength(ip6_t *ip6);
	command nx_struct t6_tcphdr *tcphdr(ip6_t *ip6);
	command uint8_t *tcpPayload(ip6_t *ip6);
	command uint16_t tcpPayloadLength(ip6_t *ip6);
}
