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
 * PppAdapterP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2012/11/15
 * @description
 */

#include "tinyv6.h"

module PppAdapterP {
    provides interface PppAdapter;

	uses interface Boot;
	uses interface SplitControl as Ppp;
	uses interface LcpAutomaton as Ipv6LcpAutomaton;
	uses interface PppIpv6;
    uses interface Ipv6Packet;
}
implementation {
    ip6_t *txip6;

    task void signalDone()
    {
        signal PppAdapter.sendDone(txip6);
    }
	event void Boot.booted()
	{
		call Ipv6LcpAutomaton.open();
		call Ppp.start();
	}

    command error_t PppAdapter.send(ip6_t *ip6)
    {
        error_t e;
        txip6 = ip6;
        e = call PppIpv6.transmit(call Ipv6Packet.raw(ip6), call Ipv6Packet.length(ip6));
        post signalDone();
        return e;
    }

	event error_t PppIpv6.receive (const uint8_t *msg, unsigned int len)
	{
        return signal PppAdapter.recv(msg, len);
	}
	event void PppIpv6.linkDown () {}
	event void PppIpv6.linkUp () {}

	event void Ipv6LcpAutomaton.transitionCompleted (LcpAutomatonState_e las) {}
	event void Ipv6LcpAutomaton.thisLayerUp () {}
	event void Ipv6LcpAutomaton.thisLayerDown () {}
	event void Ipv6LcpAutomaton.thisLayerStarted () {}
	event void Ipv6LcpAutomaton.thisLayerFinished () {}

	event void Ppp.startDone (error_t error) {}
	event void Ppp.stopDone (error_t error) {}
}
