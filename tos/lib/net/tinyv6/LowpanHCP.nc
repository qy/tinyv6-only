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
 * LowpanHCP
 *
 * @author Wu Wen <wuwen21999@126.com>
 * @author Yao Gaoxue <florasnow@live.cn>
 * @date 2011-11-12 00:25
 * @description: 
 *   Header compress & decompress according to RFC4944
 */

#include<tinyv6.h>
#include<lowpan.h>

module LowpanHCP {
    provides interface Lowpan;

    uses interface Ipv6Address;
    uses interface Ipv6Packet;
    uses interface LowpanFrag;
    uses interface Leds;
}
implementation{
    //------------------------------------Constant Definition----------------------------------
    enum{
        COMPRESSED = 1,//indicate the field need to be compressed
        INLINE = 0,    //indicate the field need to be carried inline
    };

    enum{
        LOCAL_PREFIX = 0xFE80,//the first two octets of the prefix of the local link address
    };

    enum{
        HC2_ENCODING = 1,//indicate that there are more header compression follow HC1
        COMPRESSED_UDP_PORT_BASE = 0xF0B0,//used for UDP port compression
    };

    enum{
        PREFIX_LEN = 64,          //the length of prefix of ipv6 address
        IDEN_LEN = 64,            //the length of interface identifier for ipv6 address
        TCFL_LEN = 28,            //the length of TCFL field in Ipv6 Packet
        UDP_HEADER_LEN = 64,      //the length of UDP header
        SHORT_UDP_PORT_LEN = 4,   //the length of compressed UDP port
        IPV6_VERSION_LEN = 4,	  //the length of Version field in Ipv6 packet
        NXT_HEADER = 8,			  //the length of Next Protocal Header
        IP6_HEADER_LEN = 40,	  //the length of Ipv6 Header
        UDP_PORT_LEN = 16, 		  //the length of UDP port
    };

    ip6_t *sending_ip6;
    ip6_t rxip6;

    error_t restore_packet(ip6_t *ip6, uint8_t *buf, uint16_t len, am_addr_t src);

    //--------------------------------------Send Function---------------------------------------------------

    /*
     * Determine whether the prefix of Ipv6 Address need to be compressed 
     *
     * @param addr  Ipv6 address
     *
     * @retrun  COMPRESSED if the Ipv6 Address is local link.Otherwise,return INLINE.
     */
    int isPreCompress(nx_struct t6_addr addr){
        uint8_t i;
        nx_struct t6_addr local=call Ipv6Address.linklocal();
        for(i=0;i<2;i++){
            if(addr.t6_ipaddr32[i]!=local.t6_ipaddr32[i]){
                return INLINE;
            }
        }
        return COMPRESSED;
    }


    /*
     * Determine whether the Interface Identifier for Ipv6 Address need to be compressed 
     *
     * @param addr1  the Ipv6 address that need to be determine
     * @param addr2  the Ipv6 address used for reference
     *
     * @return   COMPRESSED if the Interface Identifier for addr1 is equal to that for reference
     *           address named addr2.Otherwise,return INLINE.
     */
    int isIdenCompress(nx_struct t6_addr addr1,nx_struct t6_addr addr2){
        uint8_t i;
        for(i=2;i<4;i++){
            if(addr1.t6_ipaddr32[i]!=addr2.t6_ipaddr32[i]){
                return INLINE;
            }
        }
        return COMPRESSED;
    }

    /*
     * Fill the destination field with the specified-length source field by bit
     *
     * @param dst      point to the beginning of the destination field
     * @param offset   bits that have been filled in destination
     * @param src      point to the beginning of the source field that used for filling
     * @param len      the length that need to be filled 
     * @param buflen   the length of the buffer for the source field
     *
     *
     * NOTE: all the length in this function is in bit
     *
     */

    void fill_by_bit(uint8_t * dst,uint16_t offset,uint8_t *src,uint16_t len,uint16_t buflen){
        uint8_t *bp = src +((buflen-len)>>3) ;
        uint16_t bi = (buflen-len) & 0x07;
        uint16_t i;
        for(i=0;i<len;i++){
            uint16_t x;
            x = i+offset;
            if( (*(bp+(bi>>3))) & (1<<(7-(bi&0x07))) ){
                *(dst+(x>>3)) |= 1<<(7-(x&0x07));
            }else{
                *(dst+(x>>3)) &= ~(1<<(7-(x&0x07)));
            }
            bi++;
        }
    }

    command void Lowpan.send(ip6_t *ip6 , am_addr_t amaddr)
    {
        uint16_t lowpan_plen;//the length of lowpan packet after compression ,but before fragmentation

        uint8_t *pdispatch=call Ipv6Packet.raw(ip6),*src,*dst;
        /*     start to compress*/
#ifdef HC1_COMPRESS
        nx_struct t6_udphdr *udphdr = call Ipv6Packet.udphdr(ip6);
        nx_struct t6_addr dstlocal = call Ipv6Address.linklocal();
        nx_struct t6_iphdr *ip6hdr = call Ipv6Packet.ip6hdr(ip6);
        uint16_t udplen = call Ipv6Packet.udpPayloadLength(ip6);
        nx_uint32_t tcfl; 
        uint8_t *hc1 = NULL;
        uint8_t *hc2 = NULL;
        uint8_t *msg = pdispatch;  //point to field that need to be compressed currently
        uint8_t padding = 0;       //used for fill in the compressed header 
        uint16_t ip6len = ip6hdr->t6_plen;
        uint16_t offset_bit=0;

        tcfl = ip6hdr->t6_flow & 0x0fffffff;
        *pdispatch = LOWPAN_DISPATCH_HC1;
        msg++;
        hc1 = (uint8_t*)msg;
        msg++;

        /*    HC1 Encoding*/
        *hc1 = 0;
        *hc1 |= isPreCompress(ip6hdr->t6_src) << SHIFT_HC1_SPREFIX;
        *hc1 |= isIdenCompress(ip6hdr->t6_src,call Ipv6Address.linklocal()) << SHIFT_HC1_SIDEN;
        *hc1 |= isPreCompress(ip6hdr->t6_dst) << SHIFT_HC1_DPREFIX;
        dstlocal.t6_ipaddr16[7]=amaddr;
        *hc1 |= isIdenCompress(ip6hdr->t6_dst,dstlocal) << SHIFT_HC1_DIDEN;
        if(tcfl == 0){
            *hc1 |= COMPRESSED << SHIFT_HC1_TCFL;
        }else{
            *hc1 |= INLINE << SHIFT_HC1_TCFL;
        }
        switch(ip6hdr->t6_nxt){
            case TCP : 
                *hc1 |= TCP_HEADER << SHIFT_HC1_NXTHDR;
                break;
            case UDP :
                *hc1 |= UDP_HEADER << SHIFT_HC1_NXTHDR;
                break;
            case ICMP :
                *hc1 |= ICMP_HEADER << SHIFT_HC1_NXTHDR;
                break;
            default : 
                break;
        }
        offset_bit += (sizeof(*hc1)<<3)+(sizeof(*pdispatch)<<3);
#ifdef HC2_COMPRESS
        /*   HC2 Encoding */
        if((*hc1&MASK_HC1_NXTHDR)>>SHIFT_HC1_NXTHDR == UDP_HEADER){
            *hc1 |= HC2_ENCODING << SHIFT_HC1_IFHC2;
            hc2 = (uint8_t*)msg;
            msg++;

            *hc2 = 0;
            /* compress udp port if the range of its value is from 0xF0B0 to 0xF0BF  */
            if(udphdr->src_port-COMPRESSED_UDP_PORT_BASE >=0 && udphdr->src_port-COMPRESSED_UDP_PORT_BASE <= 15){
                *hc2 |= COMPRESSED << SHIFT_HC2_SPORT;
            }else{
                *hc2 |= INLINE << SHIFT_HC2_SPORT;
            }
            if(udphdr->dst_port-COMPRESSED_UDP_PORT_BASE >=0 && udphdr->dst_port-COMPRESSED_UDP_PORT_BASE <=15){
                *hc2 |= COMPRESSED<<SHIFT_HC2_DPORT;
            }else{
                *hc2 |= INLINE<<SHIFT_HC2_DPORT;
            }
            *hc2 |= COMPRESSED<<SHIFT_HC2_LENGTH;
            offset_bit += sizeof(*hc2)<<3;
        }
#endif
        /* carried Hop Limit inline */
        (*msg)=ip6hdr->t6_hlim;
        msg++;
        offset_bit+=sizeof(ip6hdr->t6_hlim)<<3;

        /*if Ipv6 source address prefix is not compressed*/
        if((*hc1&MASK_HC1_SPREFIX)>>SHIFT_HC1_SPREFIX == INLINE){
            fill_by_bit(pdispatch,offset_bit,(uint8_t *)&ip6hdr->t6_src.t6_ipaddr16[0],PREFIX_LEN,PREFIX_LEN);    			
            offset_bit += PREFIX_LEN;
        }

        /*if Ipv6 source address IID is not compressed*/
        if((*hc1&MASK_HC1_SIDEN)>>SHIFT_HC1_SIDEN == INLINE){
            fill_by_bit(pdispatch,offset_bit,(uint8_t *)&ip6hdr->t6_src.t6_ipaddr16[4],IDEN_LEN,IDEN_LEN);      
            offset_bit += IDEN_LEN;
        }

        /*if Ipv6 destination address prefix is not compressed*/
        if((*hc1&MASK_HC1_DPREFIX)>>SHIFT_HC1_DPREFIX == INLINE){
            fill_by_bit(pdispatch,offset_bit,(uint8_t *)&ip6hdr->t6_dst.t6_ipaddr16[0],PREFIX_LEN,PREFIX_LEN);    
            offset_bit += PREFIX_LEN;
        }	

        /*if Ipv6 destination address IID is not compressed*/
        if((*hc1&MASK_HC1_DIDEN)>>SHIFT_HC1_DIDEN == INLINE){
            fill_by_bit(pdispatch,offset_bit,(uint8_t *)&ip6hdr->t6_dst.t6_ipaddr16[4],IDEN_LEN,IDEN_LEN);      
            offset_bit += IDEN_LEN;
        }

        /*if TCFL field is not compressed*/
        if((*hc1&MASK_HC1_TCFL)>>SHIFT_HC1_TCFL == INLINE){
            fill_by_bit(pdispatch,offset_bit,(uint8_t *)&tcfl,TCFL_LEN,sizeof(tcfl)<<3);
            offset_bit += TCFL_LEN;
        }

        /*if there are more header need to be compressed */
        if((*hc1&MASK_HC1_IFHC2)>>SHIFT_HC1_IFHC2 == COMPRESSED ){
            /*if udp port is compressd,use 4 bits to indicate it,else use 16 bits*/
            if((*hc2&MASK_HC2_SPORT) >> SHIFT_HC2_SPORT == COMPRESSED){
                uint8_t sh_sport;
                sh_sport= udphdr->src_port-COMPRESSED_UDP_PORT_BASE;
                fill_by_bit(pdispatch,offset_bit,(uint8_t *)&sh_sport,SHORT_UDP_PORT_LEN,sizeof(sh_sport)<<3);
                offset_bit += SHORT_UDP_PORT_LEN;
            }else{
                fill_by_bit(pdispatch,offset_bit,(uint8_t *)&udphdr->src_port,UDP_PORT_LEN,UDP_PORT_LEN);
                offset_bit += UDP_PORT_LEN;
            }
            if((*hc2&MASK_HC2_DPORT)>>SHIFT_HC2_DPORT == COMPRESSED){
                uint8_t sh_dport;
                sh_dport= udphdr->dst_port-COMPRESSED_UDP_PORT_BASE;
                fill_by_bit(pdispatch,offset_bit,(uint8_t *)&sh_dport,SHORT_UDP_PORT_LEN,sizeof(sh_dport)<<3);
                offset_bit += SHORT_UDP_PORT_LEN;
            }else{
                fill_by_bit(pdispatch,offset_bit,(uint8_t *)&udphdr->dst_port,UDP_PORT_LEN,UDP_PORT_LEN);
                offset_bit += UDP_PORT_LEN;
            }

            /*fill with the checksum field in udp header*/
            fill_by_bit(pdispatch,offset_bit,(uint8_t *)&udphdr->chksum,sizeof(udphdr->chksum)<<3,sizeof(udphdr->chksum)<<3);
            offset_bit += sizeof(udphdr->chksum)<<3;
        }

        /*if the length of compressed header is not multiples of 1B,then fill it with zero*/
        if(offset_bit & 0x07){
            fill_by_bit(pdispatch,offset_bit,(uint8_t *)&padding,8-(offset_bit & 0x07),sizeof(padding)<<3);
            offset_bit += 8-(offset_bit & 0x07);
        }

        /*move the other non-compressed field to the end of compressed header*/
        dst = call Ipv6Packet.raw(ip6) + (offset_bit>>3);
        if ( (*hc1&MASK_HC1_IFHC2)>>SHIFT_HC1_IFHC2 == COMPRESSED) {
            /*if hc2 encoding ,the other non-compressed field begin from udp header*/
            src = call Ipv6Packet.udpPayload(ip6);
            lowpan_plen=(offset_bit>>3)+udplen;
            memmove(dst,src,udplen);
        } else {
            /*if hc2 not encoding ,the other non-compressed field begin from udp payload*/
            lowpan_plen =(offset_bit>>3) + ip6len;
            src = call Ipv6Packet.ip6Payload(ip6);
            memmove(dst, src, ip6len);
        }

#else 
        /*if hc1 not encoding,just add the dispatch field before Ipv6 Header*/
        src = call Ipv6Packet.raw(ip6);
        lowpan_plen = call Ipv6Packet.length(ip6)+1;
        dst = src + 1;
        memmove(dst, src, call Ipv6Packet.length(ip6));
        (*pdispatch)=LOWPAN_DISPATCH_IPV6;
#endif
        sending_ip6 = ip6;
        call LowpanFrag.send(pdispatch,lowpan_plen,amaddr);
    }

    event void LowpanFrag.sendDone(uint8_t *buf, uint16_t length)
    {
        lowpanhc_printf("sendDone\n");
        restore_packet(sending_ip6, buf, length, TOS_NODE_ID);
        signal Lowpan.sendDone(sending_ip6);
    }


    //----------------------------------------------Receive Function--------------------------------------------

    /*
     * Return the value of lth bit of specified field 
     * 
     * @param p   point to the beginning of the value field
     * @param l   indicate the lth bit of the specified value 
     *
     */
    uint8_t get(uint8_t *p,uint16_t l){
        uint8_t ret = *(p+(l>>3)) & 1<<(7-(l&0x07));
        if(ret != 0 )
            return 1;
        else 
            return 0;
    }

    /*
     * Pick out the source field with specified length and store it to the destination field by bit
     *
     * @param src      point to the beginning of the source field
     * @param offset   indicate how many bits that have been picked out
     * @param len      the length wanted to picked out from the source field
     * @param buflen   the length of the buffer for dst field
     * @param dst      point to the beginning of the destination field
     *
     * NOTE:  all the length in this function is in bit
     */
    void pickout_by_bit(uint8_t *s,uint16_t offset,uint16_t len,uint16_t buflen,uint8_t *buf){
        uint8_t i;
        for(i = 0;i < len ; i++){
            uint8_t b = get(s,offset+i);
            uint16_t x = buflen-len+i;
            if(b == 0){
                *(buf+(x>>3)) &= ~(1<<(7-(x&0x07)));
            }else{
                *(buf+(x>>3)) |= 1<<(7-(x&0x07));
            }
        }						
    }
    /*
     * Extract a compressed packet to IPv6 packet IN PLACE
     *
     * @param pkt  the buffer for the packet (the first byte MUST be HC1 Enc)
     * @param len  the length of the compressed packet
     * @param amsrc  AM source of the packet
     *
     * NOTE: extract IPv6 packet length is implied in the t6_plen field
     *
     */
    void decompress(uint8_t *pkt, uint16_t len, am_addr_t amsrc)
    {
        uint8_t hc1 = 0;
        uint8_t hc2 = 0;

        uint16_t hc_hdrlen_bit; /* compressed header length, in bit */
        uint16_t hc_hdrlen; /* HC1+HC2 header length, in byte */
        nx_uint16_t hc_plen; /* payload length of the compressed packet, excluding the compressed header */

        nx_struct t6_iphdr *ip6hdr;
        nx_uint32_t tcfl;
        uint8_t nxth;
        uint8_t hlim;
        nx_struct t6_addr ip6src, ip6dst;
        nx_uint16_t udp_sport,udp_dport, udp_len, udp_cksum;

        uint8_t *src, *dst; 
        /*
         * get out fields in compressed header
         *
         */

        hc_hdrlen_bit = 0;

        /* HC1 Enc */
        hc1 = *((uint8_t*)&pkt[hc_hdrlen_bit/8]);
        hc_hdrlen_bit += sizeof(hc1)*8;

        /* HC2 Enc if present */
        if((hc1&MASK_HC1_IFHC2)>>SHIFT_HC1_IFHC2 == HC2_ENCODING ) {
            hc2 = *((uint8_t*)&pkt[hc_hdrlen_bit/8]);
            hc_hdrlen_bit += sizeof(hc2)*8;
        }

        /* Hop Limit */
        hlim = pkt[hc_hdrlen_bit/8];
        hc_hdrlen_bit += sizeof(hlim)*8;

        /* extract IPv6 source address */
        memset(&ip6src, 0, sizeof(ip6src));
        /* IPv6 source address prefix, if not compressed */
        if ((hc1&MASK_HC1_SPREFIX)>>SHIFT_HC1_SPREFIX == INLINE) {
            pickout_by_bit(pkt,hc_hdrlen_bit,PREFIX_LEN,PREFIX_LEN,(uint8_t*)&ip6src.t6_ipaddr[0]);
            hc_hdrlen_bit += PREFIX_LEN;
        } else {
            ip6src.t6_ipaddr32[0] = 0xfe800000;
            ip6src.t6_ipaddr32[1] = 0;
        }

        /* IPv6 source address IID, if not compressed */
        if((hc1&MASK_HC1_SIDEN)>>SHIFT_HC1_SIDEN == INLINE){
            pickout_by_bit(pkt,hc_hdrlen_bit,IDEN_LEN,IDEN_LEN,(uint8_t*)&ip6src.t6_ipaddr[8]);
            hc_hdrlen_bit += IDEN_LEN;
        } else {
            ip6src.t6_ipaddr16[4] = TOS_AM_GROUP;
            ip6src.t6_ipaddr16[5] = 0x00ff;
            ip6src.t6_ipaddr16[6] = 0xfe00;
            ip6src.t6_ipaddr16[7] = amsrc;
        }

        /* extract IPv6 destination address */
        memset(&ip6dst, 0, sizeof(ip6dst));
        /* IPv6 destination address prefix, if not compressed */
        if((hc1&MASK_HC1_DPREFIX)>>SHIFT_HC1_DPREFIX == INLINE){
            pickout_by_bit(pkt,hc_hdrlen_bit,PREFIX_LEN,PREFIX_LEN,(uint8_t*)&ip6dst.t6_ipaddr[0]);
            hc_hdrlen_bit += PREFIX_LEN;
        } else {
            ip6dst.t6_ipaddr32[0] = 0xfe800000;
            ip6dst.t6_ipaddr32[1] = 0;
        }

        /* IPv6 destination address IID, if not compressed */
        if ((hc1&MASK_HC1_DIDEN)>>SHIFT_HC1_DIDEN == INLINE){
            pickout_by_bit(pkt,hc_hdrlen_bit,IDEN_LEN,IDEN_LEN,(uint8_t*)&ip6dst.t6_ipaddr[8]);
            hc_hdrlen_bit += IDEN_LEN;
        } else {
            ip6dst.t6_ipaddr16[4] = TOS_AM_GROUP;
            ip6dst.t6_ipaddr16[5] = 0x00ff;
            ip6dst.t6_ipaddr16[6] = 0xfe00;
            ip6dst.t6_ipaddr16[7] = TOS_NODE_ID;
        }

        /* Traffic class and Flow label, if not compressed */
        if((hc1&MASK_HC1_TCFL)>>SHIFT_HC1_TCFL == INLINE){
            pickout_by_bit(pkt,hc_hdrlen_bit,TCFL_LEN,sizeof(tcfl)*8,(uint8_t *)&tcfl);
            hc_hdrlen_bit += TCFL_LEN;
        } else {
            tcfl = 0;
        }

        /* next header */
        switch ((hc1&MASK_HC1_NXTHDR)>>SHIFT_HC1_NXTHDR) {
            case NON_COMPRESSED_HEADER:
                /* next header carried in line */
                pickout_by_bit(pkt,hc_hdrlen_bit,NXT_HEADER,NXT_HEADER,(uint8_t *)&nxth);
                hc_hdrlen_bit += NXT_HEADER;
                break;
            case UDP_HEADER: nxth = UDP; break;
            case ICMP_HEADER: nxth = ICMP; break;
            case TCP_HEADER: nxth = TCP; break;
            default: break;
        }
        lowpanhc_printf("hc1=0x%02x,hc2=0x%02x,hlim=0x%02x\nip6src=%s,ip6dst=%s\ntcfl=0x%08x,next hdr=0x%02x\n",
                hc1, hc2, hlim, ip6str(ip6src), ip6str(ip6dst), tcfl, nxth);

        /* get out HC2 filed */
        if ((hc1&MASK_HC1_IFHC2)>>SHIFT_HC1_IFHC2 == HC2_ENCODING) {
            /* UDP source port */
            if ((hc2&MASK_HC2_SPORT)>>SHIFT_HC2_SPORT == COMPRESSED) {
                pickout_by_bit(pkt,hc_hdrlen_bit,SHORT_UDP_PORT_LEN,sizeof(udp_sport)*8,(uint8_t *)&udp_sport);
                hc_hdrlen_bit += SHORT_UDP_PORT_LEN;
                udp_sport = udp_sport + COMPRESSED_UDP_PORT_BASE;
            } else {
                pickout_by_bit(pkt,hc_hdrlen_bit,UDP_PORT_LEN,sizeof(udp_sport)*8,(uint8_t *)&udp_sport);
                hc_hdrlen_bit += UDP_PORT_LEN;
            }

            /* UDP destination port */
            if ((hc2&MASK_HC2_DPORT)>>SHIFT_HC2_DPORT == COMPRESSED) {
                pickout_by_bit(pkt,hc_hdrlen_bit,SHORT_UDP_PORT_LEN,sizeof(udp_dport)*8,(uint8_t *)&udp_dport);
                udp_dport = udp_dport + COMPRESSED_UDP_PORT_BASE;
                hc_hdrlen_bit += SHORT_UDP_PORT_LEN;
            }else{
                pickout_by_bit(pkt,hc_hdrlen_bit,UDP_PORT_LEN,sizeof(udp_dport)*8,(uint8_t *)&udp_dport);
                hc_hdrlen_bit += UDP_PORT_LEN;
            }

            /* UDP length field */
            if ((hc2&MASK_HC2_LENGTH)>>SHIFT_HC2_LENGTH == COMPRESSED) {
                /* should be calculated after HC header processed */
            } else {
                pickout_by_bit(pkt, hc_hdrlen_bit, sizeof(udp_len)*8, sizeof(udp_len)*8, (uint8_t*)&udp_len);
                hc_hdrlen_bit += sizeof(udp_len)*8;
            }
            /* UDP checksum */
            pickout_by_bit(pkt,hc_hdrlen_bit,sizeof(udp_cksum)*8,sizeof(udp_cksum)*8,(uint8_t *)&udp_cksum);
            hc_hdrlen_bit += sizeof(udp_cksum)*8;

            lowpanhc_printf("udp src_port=%u,dst_port=%u,chksum=%u\n",udp_dport, udp_sport, udp_cksum);
        }

        /*
         * move payload to the proper position
         *
         */

        /* HC1+HC2 header length, in byte */
        hc_hdrlen = (hc_hdrlen_bit +7)/8;
        /* payload length, in byte, excluding HC1+HC2 header */
        hc_plen = len - hc_hdrlen;
        lowpanhc_printf("hc_hdrlen=%u,hc_plen=%u\n", hc_hdrlen, hc_plen);

        /* payload of the original compressed packet */
        src = pkt + hc_hdrlen;

        /* payload of the new IPv6 packet, plus the UDP header if HC2 */
        dst = pkt + sizeof(nx_struct t6_iphdr) + ((hc1&MASK_HC1_IFHC2)>>SHIFT_HC1_IFHC2 == HC2_ENCODING)*sizeof(nx_struct t6_udphdr);
        memmove(dst,src,hc_plen);

        /*
         * fill in the new IPv6 packet's header in place
         *
         */

        ip6hdr = (nx_struct t6_iphdr*) pkt;
        memset(ip6hdr, 0, sizeof(*ip6hdr));

        ip6hdr->t6_vfc = 0x60;
        ip6hdr->t6_flow |= tcfl & 0x0fffffff;
        /* plus the udp header length if HC2 */
        ip6hdr->t6_plen = hc_plen + ((hc1&MASK_HC1_IFHC2)>>SHIFT_HC1_IFHC2 == HC2_ENCODING)*sizeof(nx_struct t6_udphdr);
        ip6hdr->t6_nxt = nxth;
        ip6hdr->t6_hlim = hlim;
        ip6hdr->t6_src = ip6src;
        ip6hdr->t6_dst = ip6dst;

        if ((hc1&MASK_HC1_IFHC2)>>SHIFT_HC1_IFHC2 == HC2_ENCODING) {
            nx_struct t6_udphdr* udphdr;

            udphdr = (nx_struct t6_udphdr*) (pkt+sizeof(*ip6hdr));
            udphdr->src_port = udp_sport;
            udphdr->dst_port = udp_dport;
            if ((hc2&MASK_HC2_LENGTH)>>SHIFT_HC2_LENGTH == COMPRESSED) {
                /* udp length filed including the size of udp header */
                udphdr->length = hc_plen + sizeof(*udphdr);
            } else {
                udphdr->length = udp_len;
            }
            udphdr->chksum = udp_cksum;
        }
    }

    /* restore packet in place */
    error_t restore_packet(ip6_t *ip6, uint8_t *buf, uint16_t len, am_addr_t src)
    {
        uint8_t dispatch;
        uint8_t *packet;
        uint16_t packetlen;

        dispatch = buf[0];
        /* skip the dispatch byte */
        packet = buf + 1;
        packetlen = len - 1;

        if (dispatch == LOWPAN_DISPATCH_HC1) {
            /* extract compressed packet in place */
            decompress(packet, packetlen, src); 
            ip6->data = packet;
            return SUCCESS;
        } else if (dispatch == LOWPAN_DISPATCH_IPV6) {
            ip6->data = packet;
            return SUCCESS;
        } else{
            lowpanhc_printf("restore packet fail, unkown dispatch=0x%02x\n", dispatch);
            return FAIL;
        }
    }

    event void LowpanFrag.recv(uint8_t *buf, uint16_t len, am_addr_t src)
    {
        error_t e;
        e = restore_packet(&rxip6, buf, len, src);
        if (e == SUCCESS) {
            signal Lowpan.recv(&rxip6);
        }
    }
}	
