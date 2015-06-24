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
 * lowpan.h
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Wen <wuwen21999@126.com>
 * @date 2011/11/14
 * @description
 *    structures and constants for LOWPAN
 */
#ifndef _LOWPAN_H
#define _LOWPAN_H

/* HC1 Header structure*/
enum {
    SHIFT_HC1_SPREFIX = 0,
    SHIFT_HC1_SIDEN = 1,
    SHIFT_HC1_DPREFIX = 2,
    SHIFT_HC1_DIDEN = 3,
    SHIFT_HC1_TCFL = 4,
    SHIFT_HC1_NXTHDR = 5,
    SHIFT_HC1_IFHC2 = 7,

    MASK_HC1_SPREFIX = 0x01,
    MASK_HC1_SIDEN = 0x02,
    MASK_HC1_DPREFIX = 0x04,
    MASK_HC1_DIDEN = 0x08,
    MASK_HC1_TCFL = 0x10,
    MASK_HC1_NXTHDR = 0x60,
    MASK_HC1_IFHC2 = 0x80,
};

enum {
    SHIFT_HC2_SPORT = 0,
    SHIFT_HC2_DPORT = 1,
    SHIFT_HC2_LENGTH = 2,

    MASK_HC2_SPORT = 0x01,
    MASK_HC2_DPORT = 0x02,
    MASK_HC2_LENGTH = 0x04,
};

/*Constant for HC1*/
enum{
    NON_COMPRESSED_HEADER = 0,
	UDP_HEADER = 1,
	ICMP_HEADER = 2,
	TCP_HEADER = 3,
};


/* Lowpan first fragment with dispatch LOWPAN_DISPATCH_FRAG1 */
nx_struct lowpan_frag1_hdr {
	nx_union {
		nx_uint8_t  lowpan_frag_un_dispatch;
		nx_uint16_t lowpan_frag_un_datagram_size;
	} lowpan_frag_un;
	nx_uint16_t lowpan_frag_datagram_tag;
	nx_uint8_t lowpan_frag_data[0];
};

/* Lowpan subsequent fragment with LOWPAN_DISPATCH_FRAGN */
nx_struct lowpan_fragn_hdr {
	nx_union {
		nx_uint8_t  lowpan_frag_un_dispatch;
		nx_uint16_t lowpan_frag_un_datagram_size;
	} lowpan_frag_un;
	nx_uint16_t lowpan_frag_datagram_tag;
	nx_uint8_t lowpan_frag_datagram_offset;
	nx_uint8_t lowpan_frag_data[0];
};
#define lowpan_frag_dispatch		lowpan_frag_un.lowpan_frag_un_dispatch
#define lowpan_frag_datagram_size	lowpan_frag_un.lowpan_frag_un_datagram_size

enum {
	LOWPAN_DISPATCH_NALP = 0x00, /* 00xxxxxx, should mask with 0xc0 */
	LOWPAN_DISPATCH_IPV6 = 0x41,
	LOWPAN_DISPATCH_HC1 = 0x42,
	LOWPAN_DISPATCH_BC0 = 0x50,
	LOWPAN_DISPATCH_ESC = 0x7f,
	LOWPAN_DISPATCH_MESH = 0x80, /* 10xxxxxx, should mask with 0xc0 */
	LOWPAN_DISPATCH_IPHC = 0x60, /* 011xxxxx, should mask with 0xe0, RFC6282*/
	LOWPAN_DISPATCH_FRAG1 = 0xc0, /* 11000xxx. should mask with 0xf8 */
	LOWPAN_DISPATCH_FRAGN = 0xe0, /* 11100xxx, should mask with 0xf8 */
};
#endif /* _LOWPAN_H */
