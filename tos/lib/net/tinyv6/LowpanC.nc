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
 * LowpanC
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Wen <wuwen21999@126.com>
 * @author Wu Qian
 * @date 2011/04/17
 * @description
 *    The LoWPAN layer defined by RFC4944
 */
configuration LowpanC {
	provides interface Lowpan;
}
implementation {
	components MainC, LedsC;
	components LowpanHCP, LowpanFragP;
	components ActiveMessageC;
	components new AMSenderC(0x66);
	components new AMReceiverC(0x66);
	components Ipv6PacketC, Ipv6AddressC;

	Lowpan = LowpanHCP;
	LowpanHCP.LowpanFrag-> LowpanFragP;
	LowpanHCP.Ipv6Packet -> Ipv6PacketC;
	LowpanHCP.Ipv6Address -> Ipv6AddressC;
	LowpanHCP.Leds->LedsC;

	LowpanFragP.Boot -> MainC;
	LowpanFragP.Leds -> LedsC;
	LowpanFragP.RadioControl -> ActiveMessageC;
	LowpanFragP.AMSend -> AMSenderC;
	LowpanFragP.Receive -> AMReceiverC;
	LowpanFragP.Ipv6Packet -> Ipv6PacketC;
	LowpanFragP.AMPacket -> ActiveMessageC;
	LowpanFragP.Acks->AMSenderC;
}
