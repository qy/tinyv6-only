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
 * Ipv6AddressP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/17
 * @description
 */

#include <AM.h>
#include "tinyv6.h"

module Ipv6AddressP {
	provides interface Ipv6Address;
	uses interface Boot;
}
implementation {
	nx_struct t6_addr ip6_ll_addr;
	nx_struct t6_addr ip6_global_addr;

	event void Boot.booted()
	{
#ifndef IPV6_ADDR_PREFIX_0
  #error "IPV6_ADDR_PREFIX_0 not defined"
#endif
#ifndef IPV6_ADDR_PREFIX_1
  #error "IPV6_ADDR_PREFIX_1 not defined"
#endif
#ifndef IPV6_ADDR_PREFIX_2
  #error "IPV6_ADDR_PREFIX_2 not defined"
#endif
#ifndef IPV6_ADDR_PREFIX_3
  #error "IPV6_ADDR_PREFIX_3 not defined"
#endif
		// RFC4944 section 6, stateless address autoconfigure
		ip6_ll_addr.t6_ipaddr16[0] = 0xfe80;
		ip6_ll_addr.t6_ipaddr16[4] = TOS_AM_GROUP;
		ip6_ll_addr.t6_ipaddr16[5] = 0x00ff;
		ip6_ll_addr.t6_ipaddr16[6] = 0xfe00;
		ip6_ll_addr.t6_ipaddr16[7] = TOS_NODE_ID;

		ip6_global_addr.t6_ipaddr16[0] = IPV6_ADDR_PREFIX_0 ;
		ip6_global_addr.t6_ipaddr16[1] = IPV6_ADDR_PREFIX_1 ;
		ip6_global_addr.t6_ipaddr16[2] = IPV6_ADDR_PREFIX_2 ;
		ip6_global_addr.t6_ipaddr16[3] = IPV6_ADDR_PREFIX_3 ;
		ip6_global_addr.t6_ipaddr16[4] = TOS_AM_GROUP;
		ip6_global_addr.t6_ipaddr16[5] = 0x00ff;
		ip6_global_addr.t6_ipaddr16[6] = 0xfe00;
		ip6_global_addr.t6_ipaddr16[7] = TOS_NODE_ID;
	}
	command nx_struct t6_addr Ipv6Address.linklocal()
	{
		return ip6_ll_addr;
	}
	command nx_struct t6_addr Ipv6Address.global()
	{
		return ip6_global_addr;
	}
	command int Ipv6Address.equal(nx_struct t6_addr addr1, nx_struct t6_addr addr2)
	{
		return (memcmp(&addr1, &addr2, sizeof(nx_struct t6_addr)) == 0);
	}
	command int Ipv6Address.type(nx_struct t6_addr addr)
	{
		if (addr.t6_ipaddr[0] == 0xff) {
			return IPV6_ADDR_TYPE_MULTICAST;
		} else if (addr.t6_ipaddr16[0] == 0xfe80) {
			return IPV6_ADDR_TYPE_LINKLOCAL;
		} else {
			return IPV6_ADDR_TYPE_GLOBAL;
		}
	}
}
