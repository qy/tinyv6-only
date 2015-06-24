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
 * Icmpv6
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/05/14
 * @description
 */
interface Icmpv6 {
	/*
	 * ICMPv6 error messages
	 */
	command void destinationUnreachable(nx_struct t6_addr dst, uint8_t code);
	command void packetTooBig(nx_struct t6_addr dst, uint32_t mtu);
	command void timeExceeded(nx_struct t6_addr dst);
	command void parameterProblem(nx_struct t6_addr dst, uint8_t code); 

	/*
	 * ICMPv6 informational messages
	 */
	command void echoRequest(nx_struct t6_addr dst, uint16_t id);
	event void echoReply(nx_struct t6_addr src, uint16_t id);

	/*
	 * for NDP messages
	 */
	command void ndpTxRouterSolicitation();
	command void ndpTxRouterAdvertisement(uint8_t cur_hop_limit, uint8_t flags, uint16_t router_lifetime, uint32_t reachable_time, uint32_t retx_timer); 
	command void ndpTxNeighborSolicitation(nx_struct t6_addr target); 
	command void ndpTxNeighborAdvertisement(nx_struct t6_addr dst, nx_struct t6_addr target, uint8_t flags);
	command void ndpTxRedirect(nx_struct t6_addr dst, nx_struct t6_addr target, nx_struct t6_addr redirect_dst);

	event void ndpRxRouterSolicitation(ip6_t *ip6);
	event void ndpRxRouterAdvertisement(ip6_t *ip6);
	event void ndpRxNeighborSolicitation(ip6_t *ip6);
	event void ndpRxNeighborAdvertisement(ip6_t *ip6);
	event void ndpRxRedirect(ip6_t *ip6);
}
