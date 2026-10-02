//
//  NSURL+File.m
//  MulleObjCInetFoundation
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
//  Copyright (c) 2020 Codeon GmbH.
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
#import "NSURL.h"

// other files in this library

// other libraries of MulleObjCStandardFoundation

// std-c and dependencies
#include <string.h>



@implementation NSURL( File)

static struct MulleURLSchemeHandler   MulleURLFileSchemeHandler =
{
   @selector( mulleInitFileURLWithArguments:),
   @selector( mulleGenericURLDescription),
   @selector( mulleGenericResourceSpecifierDescription)
};


MULLE_OBJC_DEPENDS_ON_LIBRARY( MulleObjCValueFoundation);

+ (void) load
{
   @autoreleasepool
   {
      [self mulleRegisterHandler:&MulleURLFileSchemeHandler
                       forScheme:@"file"];
   }
}


//
// https://tools.ietf.org/html/rfc1738#section-3.10
//
- (instancetype) mulleInitFileURLWithArguments:(struct MulleURLSchemeInitArguments *) args
{
   struct MulleEscapedURLPartsUTF8   parts;
   char                              *tmp;
   char                              *utf;
   NSUInteger                        length;

   memset( &parts, 0, sizeof( parts));

   utf    = args->uri.characters;
   length = args->uri.length;

   if( length >= 2 && utf[ 0] == utf[ 1] && utf[ 0] == '/')
   {
      // host
      utf    += 2;
      length -= 2;

      tmp = (char *) mulle_utf8_strnchr( utf, length, '/');
      if( tmp == utf)
      {
         // needs this for '///'
         parts.escaped_host.characters = "";
         // parts._escaped_host.length = 0;
      }
      else
      {
         parts.escaped_host.characters = utf;
         parts.escaped_host.length     = tmp - utf;

         utf     = tmp;
         length -= parts.escaped_host.length;
      }
   }

   parts.escaped_path.characters = utf;
   parts.escaped_path.length     = length;

   return( [self mulleInitWithEscapedURLPartsUTF8:&parts
                           allowedURICharacterSet:[NSURL mulleURLEscapedAllowedCharacterSet]]);
}

@end

