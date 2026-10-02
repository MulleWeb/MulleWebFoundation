//
//  base64.c
//  MulleBase64
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
//  Copyright (c) 2003 Codon GmbH. All rights reserved.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#include "base64.h"


static inline char   isbase64( char a) 
{
   if( ('A' <= a) && (a <= 'Z'))
      return 1;
   if( ('a' <= a) && (a <= 'z'))
      return 1;
   if( ('0' <= a) && (a <= '9'))
      return 1;
   if( (a == '+') || (a == '/'))
      return 1;
   return 0;
}



// functions
// private implementation

static char base64tab[ ] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
"abcdefghijklmnopqrstuvwxyz0123456789+/";

static char base64idx[ 128] = {
   '\377','\377','\377','\377','\377','\377','\377','\377',
   '\377','\377','\377','\377','\377','\377','\377','\377',
   '\377','\377','\377','\377','\377','\377','\377','\377',
   '\377','\377','\377','\377','\377','\377','\377','\377',
   '\377','\377','\377','\377','\377','\377','\377','\377',
   '\377','\377','\377',    62,'\377','\377','\377',    63,
   52,    53,    54,    55,    56,    57,    58,    59,
   60,    61,'\377','\377','\377','\377','\377','\377',
   '\377',     0,     1,     2,     3,     4,     5,     6,
   7,     8,     9,    10,    11,    12,    13,    14,
   15,    16,    17,    18,    19,    20,    21,    22,
   23,    24,    25,'\377','\377','\377','\377','\377',
   '\377',    26,    27,    28,    29,    30,    31,    32,
   33,    34,    35,    36,    37,    38,    39,    40,
   41,    42,    43,    44,    45,    46,    47,    48,
   49,    50,    51,'\377','\377','\377','\377','\377'
};


size_t   base64_encoded_size( size_t _srcLen,
                              int _maxLineWidth)
{
   size_t   outs;
   size_t   extra;
   
   extra = 1;  // term 0
   outs  = (_srcLen / 3);            // combined chars
   
   if( _maxLineWidth)
      extra += (outs * 4) / _maxLineWidth;  // linefeeds

   outs  += (_srcLen % 3) ? 1 : 0;    // trailing chars
   
   return( outs * 4 + extra);
}


void   base64_encode( const unsigned char *_src,
                     size_t _srcLen, 
                     unsigned char *_dest,
                     size_t *_destLen,
                     int _maxLineWidth) 
{
   size_t          inLen  = _srcLen;
   size_t          inPos  = 0;
   size_t          outPos = 0;
   size_t          breakPos = 0;
   unsigned char   *out   = _dest;
   unsigned int    c1, c2, c3;
   size_t          i;
   size_t          n;
   
   // Get three characters at a time and encode them.

   breakPos = _maxLineWidth;
   
   n = inLen / 3;
   for( i = 0; i < n; ++i)
   {
      c1 = _src[ inPos++];
      c2 = _src[ inPos++];
      c3 = _src[ inPos++];

      out[ outPos++] = base64tab[ c1 >> 2];
      out[ outPos++] = base64tab[ ((c1 & 0x03) << 4) | (c2 >> 4)];
      out[ outPos++] = base64tab[ ((c2 & 0x0F) << 2) | ((c3 & 0xC0) >> 6)];
      out[ outPos++] = base64tab[ c3 & 0x3F];

      // _maxLineWidth must be divisible by 4
      if( _maxLineWidth)
      {
         if( outPos >= breakPos)
         {
            out[ outPos++] = '\n';
            breakPos       = outPos + _maxLineWidth;
         }
      }
   }

   // Encode the remaining one or two characters.
   switch( inLen % 3)
   {
      case 0:
         //out[ outPos++] = '\n';
         break;
      case 1:
         c1 = _src[ inPos] & 0xFF;
         out[ outPos++] = base64tab[ (c1 & 0xFC) >> 2];
         out[ outPos++] = base64tab[ ((c1 & 0x03) << 4)];
         out[ outPos++] = '=';
         out[ outPos++] = '=';
         //out[ outPos++] = '\n';
         break;
      case 2:
         c1 = _src[ inPos++] & 0xFF;
         c2 = _src[ inPos] & 0xFF;
         out[ outPos++] = base64tab[ (c1 & 0xFC) >> 2];
         out[ outPos++] = base64tab[ ((c1 & 0x03) << 4) | ((c2 & 0xF0) >> 4)];
         out[ outPos++] = base64tab[ ((c2 & 0x0F) << 2)];
         out[ outPos++] = '=';
         //out[ outPos++] = '\n';
         break;
   }
   out[ outPos] = 0;
   
   *_destLen = outPos;
}



size_t   base64_decoded_maximum_size( size_t inLen)
{
   //
   // "worst" case is a line of encoded characters without
   // linefeeds or extra space, producing the maximum output
   //
   return( (inLen + 3) / 4 * 3);
}


int    base64_decode( const unsigned char *_src,
                      size_t inLen, 
                      unsigned char *out,
                      size_t *_destLen)
{
   char   isErr     = 0;
   char   isEndSeen = 0;
   register int    b1, b2, b3;
   register int    a1, a2, a3, a4;
   register size_t inPos  = 0;
   register size_t outPos = 0;

   /* Get four input chars at a time and decode them. Ignore white space
      * chars (CR, LF, SP, HT). If '=' is encountered, terminate input. If
      * a char other than white space, base64 char, or '=' is encountered,
      * flag an input error, but otherwise ignore the char.
      */
   while (inPos < inLen) {
      a1 = a2 = a3 = a4 = 0;

      // get byte 1
      while (inPos < inLen) {
         a1 = _src[ inPos++] & 0xFF;

         if( isbase64(a1))
            break;
         else if( a1 == '=') {
            isEndSeen = 1;
            break;
         }
         else if( a1 != '\r' && a1 != '\n' && a1 != ' ' && a1 != '\t') {
            isErr = 1;
         }
      }

      // get byte 2
      while (inPos < inLen) {
         a2 = _src[ inPos++] & 0xFF;

         if( isbase64(a2))
            break;
         else if( a2 == '=') {
            isEndSeen = 1;
            break;
         }
         else if( a2 != '\r' && a2 != '\n' && a2 != ' ' && a2 != '\t') {
            isErr = 1;
         }
      }

      // get byte 3
      while (inPos < inLen) {
         a3 = _src[ inPos++] & 0xFF;

         if( isbase64(a3))
            break;
         else if( a3 == '=') {
            isEndSeen = 1;
            break;
         }
         else if( a3 != '\r' && a3 != '\n' && a3 != ' ' && a3 != '\t') {
            isErr = 1;
         }
      }

      // get byte 4
      while (inPos < inLen) {
         a4 = _src[ inPos++] & 0xFF;

         if( isbase64(a4))
            break;
         else if( a4 == '=') {
            isEndSeen = 1;
            break;
         }
         else if( a4 != '\r' && a4 != '\n' && a4 != ' ' && a4 != '\t') {
            isErr = 1;
         }
      }

      // complete chunk
      if( isbase64(a1) && isbase64(a2) && isbase64(a3) && isbase64(a4)) {
         a1 = base64idx[ a1] & 0xFF;
         a2 = base64idx[ a2] & 0xFF;
         a3 = base64idx[ a3] & 0xFF;
         a4 = base64idx[ a4] & 0xFF;
         b1 = ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03);
         b2 = ((a2 << 4) & 0xF0) | ((a3 >> 2) & 0x0F);
         b3 = ((a3 << 6) & 0xC0) | ( a4       & 0x3F);
         out[ outPos++] = (char)b1;
         out[ outPos++] = (char)b2;
         out[ outPos++] = (char)b3;
      }
      // 3-chunk
      else if( isbase64(a1) && isbase64(a2) && isbase64(a3) && a4 == '=') {
         a1 = base64idx[ a1] & 0xFF;
         a2 = base64idx[ a2] & 0xFF;
         a3 = base64idx[ a3] & 0xFF;
         b1 = ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03);
         b2 = ((a2 << 4) & 0xF0) | ((a3 >> 2) & 0x0F);
         out[ outPos++] = (char)b1;
         out[ outPos++] = (char)b2;
         break;
      }
      // 2-chunk
      else if( isbase64(a1) && isbase64(a2) && a3 == '=' && a4 == '=') {
         a1 = base64idx[ a1] & 0xFF;
         a2 = base64idx[ a2] & 0xFF;
         b1 = ((a1 << 2) & 0xFC) | ((a2 >> 4) & 0x03);
         out[ outPos++] = (char)b1;
         break;
      }
      // invalid state
      else {
         break;
      }

      if( isEndSeen)
         break;
   }
   *_destLen = outPos;
   return (isErr) ? -1 : 0;
}
