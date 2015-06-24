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
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/16
 * @description
 */

module Ipv6P {
	provides interface Ipv6[uint8_t nxt];

	uses interface Lowpan;
	uses interface Ipv6RoutingEngine;
	uses interface Ipv6Packet;
	uses interface Ipv6Address;
	uses interface Leds;
	uses interface NeighborDiscovery;
#if defined(PPP) || defined(TOSSIM)
	uses interface PppAdapter;
#endif
}
implementation {

	ip6_t ppp_ip6;
	struct forward_info forwarding_fi;

	void forward(ip6_t *ip6)
	{
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
		struct forward_info fi;

		ip6_printf("forward\n");

		/* find the next hop from routing engine */
		if (call Ipv6RoutingEngine.nextHop(ip6hdr->t6_dst, &fi) == SUCCESS) {
			ip6_printf("intf=%u, nexthop=[%s]\n", fi.intf, ip6str(fi.nexthop));
			if (fi.intf == INTF_PPP) { // to PPP
				ip6_printf("send to ppp\n");
#if defined(PPP) || defined(TOSSIM)
                call PppAdapter.send(ip6);
#endif
				return;
			}
			/* forward the packet to lowpan interface */
			if (fi.intf == INTF_LOWPAN) {
				am_addr_t amaddr;

				ip6_printf("dst=%s\n", ip6str(ip6hdr->t6_dst));
				if (call NeighborDiscovery.getLinkLayerAddress(fi.nexthop, &amaddr) == SUCCESS) {
					ip6_printf("getLinkLayerAddress=<%u>\n", amaddr);
					call Lowpan.send(ip6, amaddr);
				} else {
					ip6_printf("getLinkLayerAddress FAIL\n");
                }
			}
		} else {
			ip6_printf("can't find route for %s\n", ip6str(ip6hdr->t6_dst));
		}
	}

	/*
	 * packets received from lower layer(LOWPAN/PPP)
	 *
	 */
	void ip6_recv(ip6_t *ip6)
	{
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);

	//	call Leds.led2Toggle();
		ip6_printf("ip6_recv\n");
		// ip6_dump(call Ipv6Packet.raw(ip6), call Ipv6Packet.length(ip6));
		ip6_printf("dst=%s\n", ip6str(ip6hdr->t6_dst));
		ip6_printf("src=%s\n", ip6str(ip6hdr->t6_src));

		if (call Ipv6Address.equal(ip6hdr->t6_dst, call Ipv6Address.linklocal()) || 
			call Ipv6Address.equal(ip6hdr->t6_dst, call Ipv6Address.global()) ||
			call Ipv6Address.type(ip6hdr->t6_dst) == IPV6_ADDR_TYPE_MULTICAST) {
			ip6_printf("ip6_recv: for me, nxt=%hhu\n", ip6hdr->t6_nxt);
			signal Ipv6.recv[ip6hdr->t6_nxt](ip6);
		} else if (call Ipv6Address.type(ip6hdr->t6_dst) == IPV6_ADDR_TYPE_GLOBAL) {
			ip6_printf("ip6_recv: forward\n");
			ip6hdr->t6_hlim--;
			forward(ip6);
		} else {
			// TODO: discard packets reach here
		}
	}

	/* 
	 * Send a ip6 packet to Lowpan/PPP interface.
	 * NOTE: It assumes plen/next/src/dst has already been filled.
	 */
	command void Ipv6.send[uint8_t nxt](ip6_t *ip6)
	{
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);

		/* fill in ip6 fields */
		ip6hdr->t6_vfc |= 0x60; /* fill IP version to 6 */
		ip6hdr->t6_flow &= 0xf0000000; /* fill TC&FL with 0 */
		ip6hdr->t6_hlim = 64;
        ip6hdr->t6_nxt = nxt; /* TODO: already set in upper layer for checksum */
		if (call Ipv6Address.type(ip6hdr->t6_dst) == IPV6_ADDR_TYPE_MULTICAST) {
			ip6_printf("multicast\n");
			call Lowpan.send(ip6, AM_BROADCAST_ADDR);
		} else {
			forward(ip6);
		}
	}

	event void Lowpan.sendDone(ip6_t *ip6)
	{
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);

        ip6_printf("Lowpan.sendDone: nxt=%hhu\n", ip6hdr->t6_nxt);
		signal Ipv6.sendDone[ip6hdr->t6_nxt](ip6);
	}

	event void Lowpan.recv(ip6_t *ip6)
	{
		ip6_recv(ip6);
	}

    default event void Ipv6.sendDone[uint8_t nxt](ip6_t *ip6)
    {
        ip6_printf("sendDone:unknown nxt=%hhu\n", nxt);
    }
    default event void Ipv6.recv[uint8_t nxt](ip6_t *ip6)
    {
        ip6_printf("recv:unknown nxt=%hhu\n", nxt);
    }

#if defined(PPP) || defined(TOSSIM)
    event error_t PppAdapter.recv(const uint8_t *msg, unsigned int len) {
		// assert(((nx_struct t6_iphdr*)msg)->plen == len + sizeof(nx_struct ip6_hdr));
		ppp_ip6.data = (uint8_t*)msg;
		ip6_recv(&ppp_ip6);
        return SUCCESS;
    }

    event void PppAdapter.sendDone(ip6_t *ip6) {
		nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
		signal Ipv6.sendDone[ip6hdr->t6_nxt](ip6);
    }
#endif

}
