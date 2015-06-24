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
 * PppAdapterP for TOSSIM
 *
 * @author Qiu Ying <qiuying@mail.nwpu.edu.cn>
 * @date 2012/11/15
 * @description
 */

#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <pthread.h>
#include <sys/socket.h>
#include <arpa/inet.h>

module PppAdapterP {
    uses interface Boot;
    uses interface Ipv6Packet;
    provides interface PppAdapter;
}
implementation {

    int fd;

    typedef struct {
        uint8_t *msg;
        uint16_t len;
    } ppp_t;

    void ppp_message_deliver_handle(sim_event_t* evt) {
        ppp_t *ppp = (ppp_t *)evt->data;
        dbg("PPP", "PppAdapter.recv, len=%u\n", ppp->len);
        signal PppAdapter.recv(ppp->msg, ppp->len);
        free(ppp->msg);
        free(evt->data);
    }

    sim_event_t* allocate_deliver_event(int node, uint8_t* msg, uint16_t len, sim_time_t t) {
        sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
        ppp_t *ppp;

        evt->mote = node;
        evt->time = t;
        evt->handle = ppp_message_deliver_handle;
        evt->cleanup = sim_queue_cleanup_event;
        evt->cancelled = 0;
        evt->force = 0;
        evt->data = (ppp_t *) malloc(sizeof(ppp_t));
        ppp = (ppp_t*)evt->data;
        ppp->msg = msg;
        ppp->len = len;
        return evt;
    }

    void ppp_message_deliver(int node, uint8_t* msg, uint16_t len, sim_time_t t) @C() @spontaneous() {
        sim_event_t* evt = allocate_deliver_event(node, msg, len, t);
        sim_queue_insert(evt);
    }
    void pppsend(const uint8_t *msg, unsigned len)
    {
        struct sockaddr_in addr;
        fd_set ws;

        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(9999);
        inet_pton(AF_INET, "localhost", &addr.sin_addr);

        FD_ZERO(&ws);
        FD_SET(fd, &ws);
        select(fd+1, NULL, &ws, NULL, NULL);
        if (FD_ISSET(fd, &ws)) {
            sendto(fd, msg, len, 0, (struct sockaddr*)&addr, sizeof(addr));
            //perror("sendto");
        }
    }

    void *rxthread(void *start_routine)
    {
        uint8_t *msg;
        uint16_t len;
        struct sockaddr_in saddr;
        int sockfd;

        sockfd = socket(AF_INET, SOCK_DGRAM, 0);
        memset(&saddr, 0, sizeof(saddr));
        saddr.sin_family = AF_INET;
        saddr.sin_port = htons(8888);
        saddr.sin_addr.s_addr = htonl(INADDR_ANY);
        bind(sockfd, (struct sockaddr *)&saddr, sizeof(saddr));

        while(1) {
            fd_set rs;
            FD_ZERO(&rs);
            FD_SET(sockfd, &rs);
            select(sockfd+1, &rs, NULL, NULL, NULL);
            if (FD_ISSET(sockfd, &rs)) {
                struct sockaddr addr;
                socklen_t addrlen = sizeof(addr);
                memset(&addr, 0, sizeof(addr));
                msg = (uint8_t *)malloc(4096);
                len = recvfrom(sockfd, msg, 4096, 0, (struct sockaddr *)&addr, &addrlen);
                dbg("PPP", "rxthread recv, len=%u\n", len);
                ppp_message_deliver(1, msg, len, sim_time());
            }
        }
        return NULL;
    }

    event void Boot.booted()
    {
        pthread_t thread;
        if (TOS_NODE_ID == 1) {
            fd = socket(AF_INET, SOCK_DGRAM, 0);
            pthread_create(&thread, NULL, rxthread, NULL);
        }
    }

    ip6_t* txip6;

    task void signalDone()
    {
        signal PppAdapter.sendDone(txip6);
    }
    command error_t PppAdapter.send(ip6_t *ip6)
    {
        dbg("PPP", "[PPP] send\n");

        txip6 = ip6;
        pppsend(call Ipv6Packet.raw(ip6), call Ipv6Packet.length(ip6));
        post signalDone();

        return SUCCESS;
    }
}
