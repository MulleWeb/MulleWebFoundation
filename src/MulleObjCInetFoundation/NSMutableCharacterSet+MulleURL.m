//
//  NSMutableCharacterSet+MulleURL.m
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
#import "NSMutableCharacterSet+MulleURL.h"

#import "import-private.h"



@implementation NSMutableCharacterSet ( MulleURL)


static id   construct( SEL _cmd)
{
   NSCharacterSet          *tmp;
   NSData                  *data;
   NSMutableCharacterSet   *set;

   tmp  = [NSCharacterSet performSelector:_cmd];
   data = [tmp bitmapRepresentation];
   set  = [[[NSMutableCharacterSet alloc] initWithBitmapRepresentation:data] autorelease];
   return( set);
}


+ (instancetype) URLFragmentAllowedCharacterSet
{
   return( construct( _cmd));
}


+ (instancetype) URLHostAllowedCharacterSet
{
   return( construct( _cmd));
}


+ (instancetype) URLPasswordAllowedCharacterSet
{
   return( construct( _cmd));
}


+ (instancetype) URLPathAllowedCharacterSet
{
   return( construct( _cmd));
}


+ (instancetype) URLQueryAllowedCharacterSet
{
   return( construct( _cmd));
}


+ (instancetype) URLUserAllowedCharacterSet
{
   return( construct( _cmd));
}


+ (instancetype) mulleNonPercentEscapeCharacterSet
{
   return( construct( _cmd));
}


+ (instancetype) mulleURLAllowedCharacterSet
{
   return( construct( _cmd));
}


+ (instancetype) mulleURLSchemeAllowedCharacterSet
{
   return( construct( _cmd));
}

@end
