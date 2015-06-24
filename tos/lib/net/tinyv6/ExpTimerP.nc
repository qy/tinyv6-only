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
 * ExpTimerP
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2012/10/10
 * @description
 */

generic module ExpTimerP(uint32_t lower, uint32_t upper) {
    provides interface ExpTimer;
    uses interface Random;
    uses interface Timer<TMilli>;
} implementation {

    uint32_t interval;

    uint32_t random(uint32_t val)
    {
        /* random value vary from 0.75val ~ 1.25val */
        val = (val>>2)*3 + call Random.rand32()%(val>>1);
        return val;
    }

    command error_t ExpTimer.start()
    {
        interval = lower;
        call Timer.startOneShot(random(interval));

        return SUCCESS;
    }
    command error_t ExpTimer.stop()
    {
        call Timer.stop();
        return SUCCESS;
    }
    command error_t ExpTimer.reset()
    {
        interval = lower;
        call Timer.stop();
        call Timer.startOneShot(random(interval));
        return SUCCESS;
    }

    event void Timer.fired()
    {
        interval *= 2;
        if (interval > upper) {
            interval = upper;
        }
        call Timer.startOneShot(random(interval));
        signal ExpTimer.fired();
    }
}
