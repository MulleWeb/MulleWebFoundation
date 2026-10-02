//
//  NSString+MulleURL.m
//  MulleObjCInetFoundation
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
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
#import "NSString+MulleURL.h"

#import "NSCharacterSet+MulleURL.h"

#import "import-private.h"



@implementation NSString ( MulleURL)


- (NSString *) stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding) encoding
{
   NSCharacterSet   *characterSet;

   NSAssert( encoding == NSUTF8StringEncoding, @"only suppports NSUTF8StringEncoding");
   characterSet = [NSCharacterSet mulleNonPercentEscapeCharacterSet];
   return( [self stringByAddingPercentEncodingWithAllowedCharacters:characterSet]);
}


- (NSString *) stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding) encoding
{
   NSCharacterSet   *characterSet;

   NSAssert( encoding == NSUTF8StringEncoding, @"only suppports NSUTF8StringEncoding");
   characterSet = [NSCharacterSet mulleNonPercentEscapeCharacterSet];
   return( [self mulleStringByReplacingPercentEscapesWithDisallowedCharacters:characterSet]);
}

@end
