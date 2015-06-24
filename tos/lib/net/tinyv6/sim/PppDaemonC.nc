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
 * PppDaemonC
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2012/11/15
 * @description
 */
#include "ppp.h"
#include "HdlcFraming.h"

module PppDaemonC {
    uses {
        interface PppProtocol[ uint16_t protocol ];
        interface HdlcUart;
        interface StdControl as UartControl;
    }
    provides {
        interface SplitControl;
        interface LcpAutomaton;
        interface Ppp;
        interface GetSetOptions<PppOptions_t> as PppOptions;
        interface GetSetOptions<HdlcFramingOptions_t> as HdlcFramingOptions;
    }
} implementation {

    
    command error_t LcpAutomaton.up ()
    {
        return SUCCESS;
    }
    command error_t LcpAutomaton.down ()
    {
        return SUCCESS;
    }
    command error_t LcpAutomaton.open ()
    {
        return SUCCESS;
    }
    command error_t LcpAutomaton.close ()
    {
        return SUCCESS;
    }

    command LcpAutomatonState_e LcpAutomaton.getState () { return 0; }

    command error_t LcpAutomaton.signalEvent (LcpAutomatonEvent_e evt, void* params)
    {
        return SUCCESS;
    }
}
