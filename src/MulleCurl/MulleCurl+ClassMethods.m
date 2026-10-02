//
//  MulleCurl+ClassMethods.m
//  MulleCurl
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
//  Copyright (c) 2019 Codeon GmbH.
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
#import "MulleCurl.h"

#import "import-private.h"

#import "MulleCurl+Private.h"


extern NSString   *MulleCurlErrorDomain;


// put in a separate file for readability

@implementation MulleCurl( ClassMethods)

static struct
{
   char                     *_defaultUserAgent;
   mulle_atomic_pointer_t   _optionLookupTable;
} Self;



+ (NSMapTable *) optionLookupTable
{
   NSMapTable   *table;

   for(;;)
   {
      table = _mulle_atomic_pointer_read( &Self._optionLookupTable);
      if( table)
         return( table);

      table = MulleCurlOptionLookupTable();
      if( _mulle_atomic_pointer_cas( &Self._optionLookupTable, table, NULL))
         return( table);
      NSFreeMapTable( table);
   }

   return( Self._optionLookupTable);
}

/*
 * Interface MulleCurlErrorDomain with NSError
 */
static NSString *  translate_curl_errno( NSInteger code)
{
   char  *s;

   s = (char *) curl_easy_strerror( code);
   if( ! s)
      return( nil);
   return( [NSString stringWithUTF8String:s]);
}


static void   MulleCurlInitDefaultUserAgent( Class self)
{
   assert( ! Self._defaultUserAgent);

   mulle_buffer_do( buffer)
   {
      mulle_buffer_sprintf( buffer, "MulleCurl v%u.%u.%u",
                                     MulleCurl_get_version_major(),
                                     MulleCurl_get_version_minor(),
                                     MulleCurl_get_version_patch());
      Self._defaultUserAgent = mulle_buffer_extract_string( buffer);
   }
}


char   *MulleCurlDefaultUserAgent( void)
{
   return( Self._defaultUserAgent);
}


MULLE_OBJC_DEPENDS_ON_LIBRARY( MulleObjCStandardFoundation);


+ (void) initialize
{
   curl_global_init( CURL_GLOBAL_DEFAULT);
   MulleCurlInitDefaultUserAgent( self);

   // crazy clang cast
   [NSError registerErrorDomain:MulleCurlErrorDomain
            errorStringFunction:(NSString *(*)(NSInteger)) translate_curl_errno];
}


+ (void) unload
{
   struct mulle_allocator   *allocator;

   allocator = MulleObjCClassGetAllocator( self);
   mulle_allocator_free( allocator, Self._defaultUserAgent);

   curl_global_cleanup();

   if( Self._optionLookupTable)
      NSFreeMapTable( Self._optionLookupTable);
   //Self._optionLookupTable = NULL;
}



+ (void) setDefaultUserAgent:(NSString *) agent
{
   struct mulle_allocator   *allocator;

   allocator = MulleObjCClassGetAllocator( self);
   mulle_allocator_free( allocator, Self._defaultUserAgent);
   if( ! agent)
   {
      Self._defaultUserAgent = NULL;
      return;
   }
   Self._defaultUserAgent = mulle_allocator_strdup( allocator, [agent UTF8String]);
   return;
}


+ (NSString *) defaultUserAgent
{
   return( [NSString stringWithUTF8String:Self._defaultUserAgent]);
}

@end
