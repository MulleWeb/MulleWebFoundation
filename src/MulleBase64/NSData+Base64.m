//
//  NSData+Base64.m
//  MulleBase64
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
//  Copyright (c) 2014 Codeon GmbH. All rights reserved.
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
#import "NSData+Base64.h"

#include "base64.h"

#import "import-private.h"
#include <assert.h>  // ValueFoundation does not have NSParameterAssert

@implementation NSData (Base64)

- (NSData *) base64EncodedDataWithMaxLineWidth:(NSUInteger) size
{
   NSMutableData   *data;
   size_t          srcLen;
   size_t          dstLen;
   size_t          finalLen;
   
   srcLen = [self length];
   dstLen = base64_encoded_size( srcLen, (int) size);
   data   = [NSMutableData dataWithLength:dstLen];
   base64_encode( [self bytes], srcLen,
                  [data mutableBytes],
                  &finalLen,
                  (int) size);

   if( finalLen > dstLen)
      abort();
   
   [data setLength:finalLen];
   return( data);
}


- (NSData *) base64EncodedData
{
   return( [self base64EncodedDataWithMaxLineWidth:72]);  // seems to be standard
}


- (NSString *) base64EncodedDescription
{
   NSData   *data;
   
   data = [self base64EncodedData];
   if( ! data)
      return( nil);
   
   return( [[[NSString alloc] initWithData:data
                                  encoding:NSASCIIStringEncoding] autorelease]);
}


- (NSString *) base64EncodedUnformattedDescription
{
   NSData   *data;
   
   data = [self base64EncodedDataWithMaxLineWidth:0];
   if( ! data)
      return( nil);
   
   return( [[[NSString alloc] initWithData:data
                                  encoding:NSASCIIStringEncoding] autorelease]);
}


- (NSData *) base64DecodedData
{
   NSMutableData   *data;
   size_t          srcLen;
   size_t          dstLen;
   size_t          finalLen;
   
   srcLen = [self length];
   dstLen = base64_decoded_maximum_size( srcLen);
   
   data = [NSMutableData dataWithLength:dstLen];
   if( base64_decode( [self bytes], srcLen,
                      [data mutableBytes],
                      &finalLen))
      return( nil);

   assert( finalLen <= dstLen);
   [data setLength:finalLen];
   return( data);
}

@end
