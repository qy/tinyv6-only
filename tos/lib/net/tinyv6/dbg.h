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
 * dbg.h
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2012/11/20
 * @description
 *
 * TODO: too many duplicates, how to simplify?
 *
 */
#ifndef _DBG_H

#ifdef TCP_DEBUG
  #ifdef TOSSIM
	char *state_name[] = {
		"CLOSED",
		"LISTEN",
		"SYN_SENT",
		"SYN_RCVD",
		"ESTABLISHED",
		"CLOSE_WAIT",
		"LAST_ACK",
		"FIN_WAIT_1",
		"FIN_WAIT_2",
		"CLOSING",
		"TIME_WAIT",
	};
    #define tcp_printf(x, args...) dbg("TCP", "[TCP] %-14s"x, state_name[state],##args)
  #else
	char *state_name[] = {
		"CLOSED",
		"LISTEN",
		"SYN_SENT",
		"SYN_RCVD",
		"ESTABLISHED",
		"CLOSE_WAIT",
		"LAST_ACK",
		"FIN_WAIT_1",
		"FIN_WAIT_2",
		"CLOSING",
		"TIME_WAIT",
	};
    #define tcp_printf(x,args...) do{printf_P(PSTR("[TCP] %-14s"x),state_name[state],##args);printfflush();}while(0)
  #endif
#else
  #define tcp_printf(x,args...) do{} while(0)
#endif

#ifdef ICMPV6_DEBUG
  #ifdef TOSSIM
    #define icmp_printf(x, args...) dbg("ICMP", "[ICMP] "x, ##args)
  #else
    #define icmp_printf(x,args...) do{printf_P(PSTR("[ICMP] "x),##args);printfflush();} while(0)
  #endif
#else
  #define icmp_printf(x,args...) do{} while(0)
#endif

#ifdef IPV6_DEBUG
  #ifdef TOSSIM
    #define ip6_printf(x, args...) dbg("IPv6", "[IPv6] "x, ##args)
    static char str_buf[1024];
    static void ip6_dump(uint8_t *buf, uint8_t len)
    {
        uint8_t i;
        char *p = str_buf;

        p += sprintf(p, "(%d) ", len);
        for (i = 0; i < len; i++) {
            p+=sprintf(p, "%02x ", buf[i]);
        }
        p += sprintf(p, "\n");
        *p = 0;
        ip6_printf("%s", p);
    }
  #else
    #define ip6_printf(x,args...) do{printf_P(PSTR("[IPv6] "x),##args);printfflush();} while(0)
    static void ip6_dump(uint8_t *buf, uint8_t len)
    {
        uint8_t i;

        printf_P(PSTR("(%d) "), len);
        for (i = 0; i < len; i++) {
            printf_P(PSTR("%02x "), buf[i]);
        }
        printf_P(PSTR("\n"));
        printfflush();
    }
  #endif
#else
  #define ip6_printf(x,args...) do{} while(0)
  #define ip6_dump(x,y) do{} while(0)
#endif

#ifdef ROUTE_DEBUG
  #ifdef TOSSIM
    #define route_printf(x, args...) dbg("ROUTE", "[ROUTE] "x, ##args)
  #else
    #define route_printf(x,args...) do{printf_P(PSTR("[ROUTE] "x),##args);printfflush();} while(0)
  #endif
#else
  #define route_printf(x,args...) do{} while(0)
#endif

#ifdef LOWPANFRAG_DEBUG
  #ifdef TOSSIM
    #define lowpanfrag_printf(x, args...) dbg("LoWPANFRAG", "[LoWPANFRAG] "x, ##args)
  #else
    #define lowpanfrag_printf(x,args...) do{printf_P(PSTR("[LoWPANFRAG] "x),##args);printfflush();} while(0)
  #endif
#else
  #define lowpanfrag_printf(x,args...) do{} while(0)
#endif

#ifdef LOWPANHC_DEBUG
  #ifdef TOSSIM
    #define lowpanhc_printf(x, args...) dbg("LoWPANHC", "[LoWPANHC] "x, ##args)
  #else
    #define lowpanhc_printf(x,args...) do{printf_P(PSTR("[LoWPANHC] "x),##args);printfflush();} while(0)
  #endif
#else
  #define lowpanhc_printf(x,args...) do{} while(0)
#endif

#ifdef ND_DEBUG
  #ifdef TOSSIM
    #define nd_printf(x, args...) dbg("ND", "[ND] "x, ##args)
  #else
    #define nd_printf(x,args...) do{printf_P(PSTR("[ND] "x),##args);printfflush();} while(0)
  #endif
#else
  #define nd_printf(x,args...) do{} while(0)
#endif

#ifdef TCP_SOCKET_DEBUG
  #ifdef TOSSIM
    #define tcp_socket_printf(x, args...) dbg("TCP_SOCKET", "[TCP_SOCKET] "x, ##args)
  #else
    #define tcp_socket_printf(x,args...) do{printf_P(PSTR("[TCP_SOCKET] "x),##args);printfflush();}while(0)
  #endif
#else
  #define tcp_socket_printf(x,args...) do{} while(0)
#endif

#ifdef UDP_DEBUG
  #ifdef TOSSIM
    #define udp_printf(x, args...) dbg("UDP", "[UDP] "x, ##args)
  #else
    #define udp_printf(x,args...) do{printf_P(PSTR("[UDP] "x),##args);printfflush();}while(0)
  #endif
#else
  #define udp_printf(x,args...) do{} while(0)
#endif

#ifdef UDP_SOCKET_DEBUG
  #ifdef TOSSIM
    #define udp_socket_printf(x, args...) dbg("UDP_SOCKET", "[UDP_SOCKET] "x, ##args)
  #else
    #define udp_socket_printf(x,args...) do{printf_P(PSTR("[UDP_SOCKET] "x),##args);printfflush();}while(0)
  #endif
#else
  #define udp_socket_printf(x,args...) do{} while(0)
#endif

#endif _DBG_H
