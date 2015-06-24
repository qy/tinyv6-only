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
 * Ipv6RoutingEngineC
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Qian
 * @date 2011/04/16
 * @description
 */
configuration Ipv6RoutingEngineC {
	provides interface Ipv6RoutingEngine;
}
implementation {
	enum {
		IPV6_ROUTE_ID = 0xea,
        EXPTIMER_LOWER_BOUND = 500UL,
        EXPTIMER_UPPER_BOUND = 32*1024UL,
	};
	components Ipv6RoutingEngineP;
	components MainC;
	components CollectionC;
	components new CollectionSenderC(IPV6_ROUTE_ID);
    components new ExpTimerC(EXPTIMER_LOWER_BOUND,EXPTIMER_UPPER_BOUND) as UpdateRouteTimerC;;
	components Ipv6AddressC;
	components NeighborDiscoveryC;
	components ActiveMessageC;

	Ipv6RoutingEngine = Ipv6RoutingEngineP.Ipv6RoutingEngine;
	Ipv6RoutingEngineP.Boot -> MainC;
	Ipv6RoutingEngineP.CtpControl -> CollectionC;
	Ipv6RoutingEngineP.CtpInfo -> CollectionC;
	Ipv6RoutingEngineP.RootControl -> CollectionC;
	Ipv6RoutingEngineP.Intercept -> CollectionC.Intercept[IPV6_ROUTE_ID];
	Ipv6RoutingEngineP.Send -> CollectionSenderC;
	Ipv6RoutingEngineP.UpdateRouteTimer -> UpdateRouteTimerC;
	Ipv6RoutingEngineP.Ipv6Address -> Ipv6AddressC;
	Ipv6RoutingEngineP.NeighborDiscovery -> NeighborDiscoveryC;
	Ipv6RoutingEngineP.AMPacket -> ActiveMessageC;
	Ipv6RoutingEngineP.Receive -> CollectionC.Receive[IPV6_ROUTE_ID];
}
