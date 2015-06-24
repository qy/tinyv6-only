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
 * common defines and strcts for tinyv6
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2012/11/22
 * @description
 */

#ifndef _TINYV6_H
#define _TINYV6_H

#include <stdio.h>
#include <AM.h>

#include "dbg.h"

/* IPv6 128bit address */
nx_struct t6_addr {
	nx_union {
		nx_uint8_t  __t6_addr8[16];
		nx_uint16_t __t6_addr16[8];
		nx_uint32_t __t6_addr32[4];
	} __t6_addr;
};
#define t6_ipaddr __t6_addr.__t6_addr8
#define t6_ipaddr16 __t6_addr.__t6_addr16
#define t6_ipaddr32 __t6_addr.__t6_addr32

/* IPv6 packet header */
nx_struct t6_iphdr {
	nx_union {
		nx_struct t6_hdrctl {
			nx_uint32_t t6_un1_flow;
			nx_uint16_t t6_un1_plen;
			nx_uint8_t  t6_un1_nxt;
			nx_uint8_t  t6_un1_hlim;
		} t6_un1;
		nx_uint8_t t6_un2_vfc;
	} t6_ctlun;
	nx_struct t6_addr t6_src;
	nx_struct t6_addr t6_dst;
} __attribute__((__packed__));
#define t6_vfc  t6_ctlun.t6_un2_vfc
#define t6_flow	t6_ctlun.t6_un1.t6_un1_flow
#define t6_plen	t6_ctlun.t6_un1.t6_un1_plen
#define t6_nxt	t6_ctlun.t6_un1.t6_un1_nxt
#define t6_hlim	t6_ctlun.t6_un1.t6_un1_hlim
#define t6_hops	t6_ctlun.t6_un1.t6_un1_hlim

nx_struct t6_icmphdr {
	nx_uint8_t t6_icmptype;
	nx_uint8_t t6_icmpcode;
	nx_uint16_t t6_icmpcksum;
	nx_union {
		nx_uint32_t t6_icmpun_data32[1];
		nx_uint16_t t6_icmpun_data16[1];
		nx_uint8_t  t6_icmpun_data8[1];
	} t6_icmpdataun;
} __attribute__((__packed__));
#define t6_icmpdata32	t6_icmpdataun.t6_icmpun_data32
#define t6_icmpdata16	t6_icmpdataun.t6_icmpun_data16
#define t6_icmpdata8	t6_icmpdataun.t6_icmpun_data8
#define t6_icmppptr	t6_icmpdata32[0]
#define t6_icmpmtu	t6_icmpdata32[0]
#define t6_icmpid	t6_icmpdata16[0]
#define t6_icmpseq	t6_icmpdata16[1]

/* IPv6 constants */
enum {
	ICMP = 0x3a,
	UDP = 0x11,
	TCP = 0x06,
};

nx_struct t6_udphdr {
	nx_uint16_t src_port;
	nx_uint16_t dst_port;
	nx_uint16_t length;
	nx_uint16_t chksum;
};

nx_struct t6_tcphdr {
	nx_uint16_t tcp_sport;
	nx_uint16_t tcp_dport;
	nx_uint32_t tcp_seq;
	nx_uint32_t tcp_ack;
	nx_uint8_t tcp_hdrlen; // higher 4 bits, x4 to get actual length
	nx_uint8_t  tcp_flags; // lower 6bits, should mask with 0x3f
	nx_uint16_t tcp_win;
	nx_uint16_t tcp_cksum;
	nx_uint16_t tcp_urp;
};

struct sockaddr_t6 {
	uint16_t st6_port;
	nx_struct t6_addr st6_addr;
};

#ifndef IPV6_MIN_MTU
  #define IPV6_MIN_MTU 1281  // 1B for LOWPAN_DISPATCH_IPV6
#endif

typedef struct {
	uint8_t *data;
} ip6_t;

#define AM_INVALID_ADDR 0

enum {
	INTF_LOWPAN,
	INTF_PPP,
};

struct forward_info {
	uint8_t intf;
	nx_struct t6_addr nexthop;
};


nx_struct ndp_ra_msg {
	nx_uint8_t cur_hop_limit;
	nx_uint8_t flags;
	nx_uint16_t router_lifetime;
	nx_uint32_t reachable_time;
	nx_uint32_t retx_timer;
	nx_uint8_t options[0];
};

enum {
	NDP_OPTION_SOURCE_LINK_LAYER_ADDRESS = 1,
	NDP_OPTION_TARGET_LINK_LAYER_ADDRESS = 2,
};

nx_struct ndp_option_link_layer_addr {
	nx_uint8_t type;
	nx_uint8_t length;
	nx_union {
		nx_uint8_t addr[8]; // TODO: only for 16bit short addr, EUI64 not supported yet
		nx_am_addr_t amaddr;
	} un_addr;
};

nx_struct ndp_ns_msg {
	nx_uint32_t reserved;
	nx_struct t6_addr target;
	nx_struct ndp_option_link_layer_addr option; // source Link-Layer Address
};

enum {
	NDP_NA_FLAGS_R = 0x80,
	NDP_NA_FLAGS_S = 0x40,
	NDP_NA_FLAGS_0 = 0x20,
};

nx_struct ndp_na_msg {
	nx_union {
		nx_uint8_t flags; // first 3bits: R S O
		nx_uint32_t reserved;
	} un_fr; // flags & reserved;
	nx_struct t6_addr target;
	nx_struct ndp_option_link_layer_addr option; // target Link-Layer Address
};

nx_struct ndp_redirect_msg {
	nx_uint32_t reserved;
	nx_struct t6_addr target;
	nx_struct t6_addr dst;
};

/*
 * print IPv6 addr with proper format
 *
 */
char *ip6str(nx_struct t6_addr addr)
{
	static char ip6_str[64];
	uint8_t i;
	char *p = ip6_str;

	// for link-local addr: fe80::xxxx:xxxx:xxxx:xxxx
	if (addr.t6_ipaddr16[0] == 0xfe80) {
		p += sprintf(p, "fe80::");
		for (i = 4; i < 8; i++) {
			p += sprintf(p, "%x:", addr.t6_ipaddr16[i]);
		}
	} else if (addr.t6_ipaddr[0] == 0xff) { // for multicast addr: ffxx::xxxx
		p += sprintf(p, "%x::", addr.t6_ipaddr16[0]);
		p += sprintf(p, "%x:", addr.t6_ipaddr16[7]);
	} else { // for global addr
		for (i = 0; i < sizeof(nx_struct t6_addr)/sizeof(nx_uint16_t); i++) {
			p += sprintf(p, "%x:", ((nx_uint16_t*)(&addr))[i]);
		}
	}
	*(p-1) = '\0';
	return ip6_str;
}

enum {
	IPV6_ADDR_TYPE_LINKLOCAL,
	IPV6_ADDR_TYPE_GLOBAL,
	IPV6_ADDR_TYPE_MULTICAST,
};
#endif
