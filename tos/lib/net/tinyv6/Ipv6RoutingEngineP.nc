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
 * Ipv6RoutingEngineP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/16
 * @description
 */
#include <AM.h>
#include "tinyv6.h"

module Ipv6RoutingEngineP {
	provides interface Ipv6RoutingEngine;
	uses interface Boot;
	uses interface StdControl as CtpControl;
	uses interface CtpInfo;
	uses interface RootControl;
	uses interface ExpTimer as UpdateRouteTimer;
	uses interface Send;
	uses interface Receive;
	uses interface Intercept;
	uses interface NeighborDiscovery;
	uses interface Ipv6Address;
	uses interface AMPacket;
}
implementation {
	struct routing_table_entry {
		nx_struct t6_addr dst;
		nx_struct t6_addr nexthop;
		uint8_t intf;
		uint8_t flags;
	};

	enum {
		ROUTING_TABLE_MAX = 10,

		FLAG_DEFAULT_ROUTE = 0x01,
		FLAG_ENTRY_VALID = 0x02,
	};

	struct routing_table_entry routing_table[ROUTING_TABLE_MAX];
	message_t pkt;
	nx_struct t6_addr in6addr_unspec;

	error_t routing_table_add(nx_struct t6_addr dst, nx_struct t6_addr nexthop, uint8_t intf, uint8_t flags)
	{
		uint8_t i;

        route_printf("routing table add\n");
        route_printf("dst=[%s]\n", ip6str(dst));
        route_printf("nexthop=[%s]\n", ip6str(nexthop));
        route_printf("intf=%u,flags=%u\n", intf, flags);

		// search whether dst already exists, if so, update it.
		for (i = 0; i < ROUTING_TABLE_MAX; i++) {
			if ((routing_table[i].flags&FLAG_ENTRY_VALID) && 
					call Ipv6Address.equal(routing_table[i].dst, dst)) {
				routing_table[i].nexthop = nexthop;
				routing_table[i].intf = intf;
				routing_table[i].flags = flags|FLAG_ENTRY_VALID;

                route_printf("update success\n");
				return SUCCESS;
			}
		}

		// find a blank entry to fill in
		for (i = 0; i < ROUTING_TABLE_MAX; i++) {
			if (!(routing_table[i].flags&FLAG_ENTRY_VALID)) {
				routing_table[i].dst = dst;
				routing_table[i].nexthop = nexthop;
				routing_table[i].intf = intf;
				routing_table[i].flags = flags|FLAG_ENTRY_VALID;

                route_printf("insert success\n");
				return SUCCESS;
			}
		}
        route_printf("add fail: full\n");
		return FAIL;
	}

	event void Boot.booted()
	{
		uint8_t i;
        nx_struct t6_addr in6addr_serial;

		for (i = 0; i < ROUTING_TABLE_MAX; i++) {
			routing_table[i].flags = 0;
		}
		call CtpControl.start();

		/* IPv6 unspecified address :: */
		in6addr_unspec.t6_ipaddr32[0] = 0;
		in6addr_unspec.t6_ipaddr32[1] = 0;
		in6addr_unspec.t6_ipaddr32[2] = 0;
		in6addr_unspec.t6_ipaddr32[3] = 0;

#ifdef TOSSIM
        if (TOS_NODE_ID == 1) {
            call RootControl.setRoot();
            routing_table_add(in6addr_unspec, in6addr_unspec, INTF_PPP, FLAG_DEFAULT_ROUTE);
        } else {
            call UpdateRouteTimer.start();
        }
#else
  #if defined(PPP) 
        call RootControl.setRoot();
        // TODO: what is the next hop address of a PPP link?
        routing_table_add(in6addr_unspec, in6addr_unspec, INTF_PPP, FLAG_DEFAULT_ROUTE);
  #else
        call UpdateRouteTimer.start();
  #endif
#endif

		in6addr_serial.t6_ipaddr32[0] = 0xfe800000;
		in6addr_serial.t6_ipaddr32[1] = 0;
		in6addr_serial.t6_ipaddr32[2] = 0;
		in6addr_serial.t6_ipaddr32[3] = 0x23;
        routing_table_add(in6addr_serial, in6addr_unspec, INTF_PPP, FLAG_DEFAULT_ROUTE);
	}
	event void UpdateRouteTimer.fired()
	{
		am_addr_t parent;

        route_printf("update route timer fired\n");

		if (call CtpInfo.getParent(&parent) == SUCCESS) {
			nx_struct t6_addr ip6parent, *p;

			route_printf("parent=0x%04x\n", parent);
			if (call NeighborDiscovery.getIp6Address(parent, &ip6parent) == SUCCESS) {
				route_printf("parent ip=%s\n", ip6str(ip6parent));
				routing_table_add(in6addr_unspec, ip6parent, INTF_LOWPAN, FLAG_DEFAULT_ROUTE);
				p = (nx_struct t6_addr *) call Send.getPayload(&pkt, sizeof(*p));
				*p = call Ipv6Address.global();
				call Send.send(&pkt, sizeof(*p));
			}
		}
	}
	event void Send.sendDone(message_t *msg, error_t err) {}

	void recv(message_t* msg, void* payload, uint8_t len)
	{
		am_addr_t amprev;
		nx_struct t6_addr in6src;
		nx_struct t6_addr in6prev;
		if (len == sizeof(nx_struct t6_addr)) {
			in6src = *((nx_struct t6_addr *)payload);
			amprev = call AMPacket.source(msg);
			route_printf("src=[%s], prev=0x%04x\n", ip6str(in6src), amprev);
			if (call NeighborDiscovery.getIp6Address(amprev, &in6prev) == SUCCESS) {
				routing_table_add(in6src, in6prev, INTF_LOWPAN, 0);
			}
		}
	}
	event bool Intercept.forward(message_t* msg, void* payload, uint8_t len)
	{
		route_printf("intercept\n");
		recv(msg, payload, len);
		return TRUE;
	}
	event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len)
	{
		route_printf("root recv\n");
		recv(msg, payload, len);
		return msg;
	}

	command error_t Ipv6RoutingEngine.nextHop(nx_struct t6_addr dst, struct forward_info *pfi)
	{
		uint8_t i;

		/*
		 * fe80::/64 to LOWPAN interface
		 * TODO: should be a entry of route table,
		 *       but now scoped address is not supported
		 */
		if (call Ipv6Address.type(dst) == IPV6_ADDR_TYPE_LINKLOCAL) {
			pfi->intf = INTF_LOWPAN;
			pfi->nexthop = dst;
			return SUCCESS;
		}

		// search route for dst
		for (i = 0; i < ROUTING_TABLE_MAX; i++) {
			if ((routing_table[i].flags&FLAG_ENTRY_VALID) && 
					call Ipv6Address.equal(routing_table[i].dst, dst)) {
				pfi->intf = routing_table[i].intf;
				pfi->nexthop = routing_table[i].nexthop;
				return SUCCESS;
			}
		}

		// search for deault route
		for (i = 0; i < ROUTING_TABLE_MAX; i++) {
			if ((routing_table[i].flags&FLAG_ENTRY_VALID) && 
					(routing_table[i].flags&FLAG_DEFAULT_ROUTE)){
				pfi->intf = routing_table[i].intf;
				pfi->nexthop = routing_table[i].nexthop;
				return SUCCESS;
			}
		}
		return FAIL;
	}
}
