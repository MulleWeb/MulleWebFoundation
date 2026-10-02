//
//  NSCharacterSet+MulleURL.m
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
#import "NSCharacterSet+MulleURL.h"

#import "import-private.h"

#import <MulleObjCStandardFoundation/_MulleObjCConcreteCharacterSet.h>


@implementation NSCharacterSet ( MulleURL)

+ (instancetype) URLFragmentAllowedCharacterSet
{
   return( [[_MulleObjCConcreteCharacterSet newWithMemberFunction:mulle_unicode_is_validurlfragment
                                                    planeFunction:mulle_unicode_is_validurlfragmentplane
                                                           invert:NO] autorelease]);
}


+ (instancetype) URLHostAllowedCharacterSet
{
   return( [[_MulleObjCConcreteCharacterSet newWithMemberFunction:mulle_unicode_is_validurlhost
                                                    planeFunction:mulle_unicode_is_validurlhostplane
                                                           invert:NO] autorelease]);
}


+ (instancetype) URLPasswordAllowedCharacterSet
{
   return( [[_MulleObjCConcreteCharacterSet newWithMemberFunction:mulle_unicode_is_validurlpassword
                                                    planeFunction:mulle_unicode_is_validurlpasswordplane
                                                           invert:NO] autorelease]);
}


+ (instancetype) URLPathAllowedCharacterSet
{
   return( [[_MulleObjCConcreteCharacterSet newWithMemberFunction:mulle_unicode_is_validurlpath
                                                    planeFunction:mulle_unicode_is_validurlpathplane
                                                           invert:NO] autorelease]);
}


+ (instancetype) URLQueryAllowedCharacterSet
{
   return( [[_MulleObjCConcreteCharacterSet newWithMemberFunction:mulle_unicode_is_validurlquery
                                                    planeFunction:mulle_unicode_is_validurlqueryplane
                                                           invert:NO] autorelease]);
}


+ (instancetype) URLUserAllowedCharacterSet
{
   return( [[_MulleObjCConcreteCharacterSet newWithMemberFunction:mulle_unicode_is_validurluser
                                                    planeFunction:mulle_unicode_is_validurluserplane
                                                           invert:NO] autorelease]);
}

// be sure to duplicate these in NSMutableCharacterSet

+ (instancetype) mulleURLAllowedCharacterSet
{
   // https://en.wikipedia.org/wiki/Percent-encoding#Types_of_URI_characters
   return( [self characterSetWithCharactersInString:@"!*'();:@&=+$,/?#[]"
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      "abcdefghijklmnopqrstuvwxyz"
      "0123456789-_.~" ]);
}



+ (instancetype) mulleURLSchemeAllowedCharacterSet
{
   return( [[_MulleObjCConcreteCharacterSet newWithMemberFunction:mulle_unicode_is_validurlscheme
                                                    planeFunction:mulle_unicode_is_validurlschemeplane
                                                           invert:NO] autorelease]);
}


+ (instancetype) mulleNonPercentEscapeCharacterSet
{
   return( [[_MulleObjCConcreteCharacterSet newWithMemberFunction:mulle_unicode_is_nonpercentescape
                                                    planeFunction:mulle_unicode_is_nonpercentescapeplane
                                                           invert:NO] autorelease]);
}

@end
