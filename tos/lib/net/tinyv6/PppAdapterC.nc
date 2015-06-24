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
 * PppAdapterC
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2012/11/15
 * @description
 */

#include "ppp.h"

configuration PppAdapterC {
    provides interface PppAdapter;
}
implementation {
    components PppAdapterP;
    PppAdapter = PppAdapterP;

	/* The basic daemon,  No network control protocols. */
	components MainC;
	PppAdapterP.Boot -> MainC;
	components PppDaemonC;
	PppAdapterP.Ppp -> PppDaemonC;

	/* Hook up the serial infrastructure. */
	components DefaultHdlcUartC;
	PppDaemonC.HdlcUart -> DefaultHdlcUartC;
	PppDaemonC.UartControl -> DefaultHdlcUartC;

	/* Link in RFC5072 support for both the control and network protocols */
	components PppIpv6C;
	PppDaemonC.PppProtocol[PppIpv6C.ControlProtocol] -> PppIpv6C.PppControlProtocol;
	PppDaemonC.PppProtocol[PppIpv6C.Protocol] -> PppIpv6C.PppProtocol;
	PppIpv6C.Ppp -> PppDaemonC;
	PppIpv6C.LowerLcpAutomaton -> PppDaemonC;
	PppAdapterP.Ipv6LcpAutomaton -> PppIpv6C;
	PppAdapterP.PppIpv6 -> PppIpv6C;

    components Ipv6PacketC;
    PppAdapterP.Ipv6Packet -> Ipv6PacketC;
}
