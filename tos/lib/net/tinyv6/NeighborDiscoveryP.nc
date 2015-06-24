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
 * NeighborDiscoveryP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2012/10/06
 * @description
 */

module NeighborDiscoveryP {
    provides interface NeighborDiscovery;

	uses interface Boot;
	uses interface Icmpv6;
	uses interface ExpTimer;
	uses interface Ipv6Address;
	uses interface Ipv6Packet;
	uses interface Random;
} implementation {
    enum {
        ND_TABLE_SIZE = 10,
        FLAG_ENTRY_VALID = 0x01,
    };

    struct neighbor_table_item {
		uint8_t flag;
        nx_struct t6_addr in6addr;
        am_addr_t amaddr;
    };

    struct neighbor_table_item neighbor_table[ND_TABLE_SIZE];
    
    event void Boot.booted()
    {
        call ExpTimer.start();
    }

    /*
     * in6addr: neighor's link local address
     * pamaddr: pointer to neighbor's AM address
     * return: SUCCESS or FAIL
     */
	command error_t NeighborDiscovery.getLinkLayerAddress(nx_struct t6_addr in6addr, am_addr_t *pamaddr)
    {
        uint8_t i;
        for (i = 0; i < ND_TABLE_SIZE; i++) {
            if (neighbor_table[i].flag&FLAG_ENTRY_VALID &&
                    call Ipv6Address.equal(neighbor_table[i].in6addr, in6addr)) {
                *pamaddr = neighbor_table[i].amaddr;
                return SUCCESS;
            }
        }
        nd_printf("%s's AM addr not find\n", ip6str(in6addr));
        return FAIL; 
    }

    /*
     * amaddr: neighbor's AM address, if not find, return 0
     * pin6addr: pointer to neighor's link local address
     * return: SUCCESS or FAIL
     */
	command error_t NeighborDiscovery.getIp6Address(am_addr_t amaddr, nx_struct t6_addr *pin6addr)
    {
        uint8_t i;
        for (i = 0; i < ND_TABLE_SIZE; i++) {
            if ((neighbor_table[i].flag&FLAG_ENTRY_VALID) && neighbor_table[i].amaddr == amaddr) {
                *pin6addr = neighbor_table[i].in6addr;
                return SUCCESS;
            }
        }
        nd_printf("%u's ip addr not find\n", amaddr);
        return FAIL; 
    }

    /*
     * Add item to neighbor table
     *
     * amaddr: neighbor's AM address
     * pin6addr: neighor's link local address
     * return: SUCCESS or FAIL
     */
	command error_t NeighborDiscovery.addNeighbor(am_addr_t amaddr, nx_struct t6_addr in6addr)
	{
		uint8_t i;

		// check if entry already in neighbor table
		for (i = 0; i < ND_TABLE_SIZE; i++) {
			if (neighbor_table[i].flag & FLAG_ENTRY_VALID  && 
				call Ipv6Address.equal(neighbor_table[i].in6addr, in6addr) &&
				neighbor_table[i].amaddr == amaddr ) {
				nd_printf("<%u> [%s] already in neighbor table\n", amaddr, ip6str(in6addr));
				return SUCCESS;
			}
		}

		// find a empty entry to fill in
		for (i = 0; i < ND_TABLE_SIZE; i++) {
			if ((neighbor_table[i].flag & FLAG_ENTRY_VALID) == 0) {
				break;
			}
		}
		
		if (i == ND_TABLE_SIZE) {
			// randomly kickout an entry when neighbor table is full
			i = call Random.rand16() % ND_TABLE_SIZE;
		}

		// fill the chosen entry
		neighbor_table[i].in6addr = in6addr;
		neighbor_table[i].amaddr = amaddr;
		neighbor_table[i].flag |= FLAG_ENTRY_VALID;

        nd_printf("<%u> [%s] add to neighbor table\n", amaddr, ip6str(in6addr));

		return SUCCESS;
	}

    event void ExpTimer.fired()
    {
        nx_struct t6_addr multicastaddr;

        /* all node multicast address ff02::1 */
        multicastaddr.t6_ipaddr32[0] = 0xff020000;
        multicastaddr.t6_ipaddr32[1] = 0;
        multicastaddr.t6_ipaddr32[2] = 0;
        multicastaddr.t6_ipaddr32[3] = 1;
        nd_printf("tx NA\n");
		call Icmpv6.ndpTxNeighborAdvertisement(multicastaddr, call Ipv6Address.linklocal(), NDP_NA_FLAGS_R);
    }


	/*
	 * Receive NA
	 *
	 */
	event void Icmpv6.ndpRxNeighborAdvertisement(ip6_t *ip6)
	{
		// nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
		nx_struct t6_icmphdr *icmp6hdr = (nx_struct t6_icmphdr *)call Ipv6Packet.icmp6hdr(ip6);
		nx_struct ndp_na_msg *nam = (nx_struct ndp_na_msg*) icmp6hdr->t6_icmpdata8;

		nd_printf("rx NA,target=%s, am=%04x\n", ip6str(nam->target), nam->option.un_addr.amaddr);
		call NeighborDiscovery.addNeighbor(nam->option.un_addr.amaddr, nam->target);
	}

	event void Icmpv6.ndpRxNeighborSolicitation(ip6_t *ip6) {}
	event void Icmpv6.ndpRxRedirect(ip6_t *ip6) {}
	event void Icmpv6.echoReply(nx_struct t6_addr src, uint16_t id) {}
    event void Icmpv6.ndpRxRouterAdvertisement(ip6_t *ip6) {}
    event void Icmpv6.ndpRxRouterSolicitation(ip6_t *ip6) {}
}
