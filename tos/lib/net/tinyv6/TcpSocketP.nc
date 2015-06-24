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
 * TcpSocketP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/05/02
 * @description
 */

#include "tinyv6.h"

module TcpSocketP {
	provides interface TcpSocket;
	uses interface Tcp;
	uses interface Ipv6Packet;
}
implementation {

	enum {
		ACTIVE_OPEN_SOURCE_PORT = 0x1111,
	};

	command void TcpSocket.bind(uint16_t port)
	{
		call Tcp.bind(port);
	}
	command void TcpSocket.connect(struct sockaddr_t6 saddr)
	{
		call Tcp.connect(saddr.st6_addr, ACTIVE_OPEN_SOURCE_PORT, saddr.st6_port);
	}
	command void TcpSocket.send(uint8_t *buf, uint16_t size)
	{
		call Tcp.send(buf, size);
	}
	event void Tcp.recv(ip6_t *ip6)
	{
		tcp_socket_printf("len=%u\n", call Ipv6Packet.tcpPayloadLength(ip6));
		signal TcpSocket.recv(call Ipv6Packet.tcpPayload(ip6),
			call Ipv6Packet.tcpPayloadLength(ip6));
	}
	event void Tcp.accept(nx_struct t6_addr src, uint16_t sport)
	{
		struct sockaddr_t6 saddr;

		saddr.st6_addr = src;
		saddr.st6_port = sport;
		signal TcpSocket.accept(saddr);
	}
	event void Tcp.eof()
	{
		signal TcpSocket.eof();
	}
	command void TcpSocket.close()
	{
		call Tcp.close();
	}
	event void Tcp.closed()
	{
		signal TcpSocket.closed();
	}
}
