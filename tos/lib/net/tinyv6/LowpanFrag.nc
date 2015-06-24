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
 * LowpanFrag
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @author Wu Wen <wuwen21999@126.com>
 * @date 2011/11/14
 * @description
 *   interface used between LowpanFragP and LowpanHCP
 */
interface LowpanFrag {
	/*
	 * Pass a compressed LOWPAN packet to the fragment layer.
	 *
	 * NOTE:the IPv6 Dispatch is included if packet is not compressed
	 *
	 * @param buf   filled with compressed LOWPAN packet
	 * @param len   the length of packet in byte
	 * @param dst   the AM address of the destination
	 *
	 */
	command error_t send(uint8_t *buf, uint16_t len, am_addr_t dst);


	event void sendDone(uint8_t *buf, uint16_t len);

	/*
	 * Receive a reassembled&compressed LOWPAN packet from the fragment layer.
	 *
	 * @param buf   the received reassembled&compressed LOWPAN packet
	 * @param len   the length of packet in byte
	 * @param dst   the AM address of the source
	 *
	 */
	event void recv(uint8_t *buf, uint16_t len, am_addr_t src);
}
