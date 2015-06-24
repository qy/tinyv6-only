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
 * HttpServerP - A Tiny Web Server
 * 
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2013/10/31
 * @description
 */

module HttpServerP {
    provides interface HttpServer;
    provides interface StdControl;
    uses interface TcpSocket;
}
implementation {

    struct sockaddr_t6 clisaddr;

    command error_t StdControl.start()
    {
        call TcpSocket.bind(80);
        return SUCCESS;
    }
    command error_t StdControl.stop()
    {
        call TcpSocket.close();
        return SUCCESS;
    }

    event void TcpSocket.accept(struct sockaddr_t6 addr)
    {
        clisaddr = addr;
    }

    event void TcpSocket.recv(uint8_t *buf, uint16_t size)
    {
        const char *s_get  = "GET ";
        const char *s_http  = " HTTP/1.1";
        char *url, *urlend;
        char *p = (char*)buf;

        /* extract the request URL in HTTP header */
        if (memcmp(p, s_get, strlen(s_get)) == 0) {
            url = p + strlen(s_get);
            if ((urlend = strstr(url, s_http)) != NULL) {
                signal HttpServer.get(url,  urlend - url);
            }
        }
        // TODO: should consider security

        return;
    }

    command void HttpServer.response(char *buf, uint16_t size, error_t err)
    {
        char httpbuf[256];
        char *p;

        p = httpbuf;

        if (err == SUCCESS) {
            p += sprintf(p, "HTTP/1.1 200 OK\n"
                    "Content-Length: %u\n"
                    "Connection: close\n"
                    "Content-Type: application/json\n\n", size);
            memcpy(p, buf, size);
            call TcpSocket.send((uint8_t*)httpbuf, (p - httpbuf) + size);
        } else {
            char *errhtml = "<html><body><h1>404 Not Found</h1></body></html>";
            p += sprintf(p, "HTTP/1.1 404 Not Found\n");
            p += sprintf(p, "Content-Length: %u\n", strlen(errhtml));
            p += sprintf(p, "Connection: close\n");
            p += sprintf(p, "Content-Type: text/html\n\n");
            memcpy(p, errhtml, strlen(errhtml));
            call TcpSocket.send((uint8_t*)httpbuf, p - httpbuf + strlen(errhtml));
        }
        return;
    }

    event void TcpSocket.eof()
    {
        call TcpSocket.close();
    }
    event void TcpSocket.closed()
    {
        call TcpSocket.bind(80);
    }
}
