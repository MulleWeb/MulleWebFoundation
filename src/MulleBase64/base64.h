//
//  base64.h
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
#ifndef BASE64_H__
#define BASE64_H__


#include <stddef.h>

// this is code originally from Helge Hess, given by his kind permission
// make pretend _destSize parameter removed, as there is no bounds checking!
void   base64_encode( const unsigned char *_src,
                     size_t _srcLen, 
                     unsigned char *_dest,
                     size_t *_destLen,
                     int _maxLineWidth);
int   base64_decode( const unsigned char *_src, 
                     size_t _srcLen, 
                     unsigned char *_dest,
                     size_t *_destLen);

size_t   base64_encoded_size( size_t _srcLen,
                             int _maxLineWidth);
size_t   base64_decoded_maximum_size( size_t dstLen);

#endif

