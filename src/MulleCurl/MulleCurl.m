//
//  MulleCurl.m
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
#import "NSMutableData+MulleCurlParser.h"


@implementation MulleCurl


NSString   *MulleCurlErrorDomain = @"MulleCurlError";


void   MulleCurlSetErrorDomain( void)
{
   [NSError mulleSetErrorDomain:MulleCurlErrorDomain];
}


static NSString  *translator( NSInteger code)
{
   char  *s;

   s = (char *) curl_easy_strerror( code);
   if( ! s)
      return( @"???");
   return( [NSString stringWithUTF8String:s]);
}


+ (void) initialize
{
   if( curl_global_init( CURL_GLOBAL_DEFAULT))
      MulleObjCThrowInternalInconsistencyException( @"could not init libcurl");

   [NSError registerErrorDomain:MulleCurlErrorDomain
            errorStringFunction:translator];
}


+ (void) deinitialize
{
   [NSError removeErrorDomain:MulleCurlErrorDomain];
}


- (id) init
{
   _connection = curl_easy_init();
   if( ! _connection)
   {
      [self release];
      return( nil);
   }

   [self setDefaultOptions];

   _headerValueDescriptionMethod = @selector( description);

   return( self);
}


- (void) finalize
{
   if( _chunk)
   {
      curl_slist_free_all( _chunk);
      _chunk = NULL;
   }

   if( _connection)
   {
      curl_easy_cleanup( _connection);
      _connection = NULL;
   }

   [super finalize];
}


- (void) reset
{
   _headerValueDescriptionMethod = @selector( description);

   [self setParser:nil];
   [self setHeaderParser:nil];
   [self setUserInfo:nil];

   if( _chunk)
   {
      curl_slist_free_all( _chunk);
      _chunk = NULL;
   }

   // this wipes all the options!
   curl_easy_reset( _connection);
   // this gets out defaults back
   [self setDefaultOptions];
}


/*
 * Headers like "Accept:"
 */

// these overwrite previous headers
- (void) setRequestHeaders:(NSDictionary *) headers
{
   struct mulle_buffer   buffer;
   auto char             space[ 256];
   NSString              *key;
   id                    value;

   if( _chunk)
      curl_slist_free_all( _chunk);
   _chunk = NULL;

   mulle_buffer_init_with_static_bytes( &buffer, space, sizeof( space), NULL);
   {
      for( key in headers)
      {
         NSParameterAssert( ! [key hasSuffix:@":"]);

         value = [headers :key];
         // transform value to string (should format NSDate) properly
         // for the intended recipient
         value = [value performSelector:_headerValueDescriptionMethod];

         mulle_buffer_remove_all( &buffer);
         mulle_buffer_sprintf( &buffer,
                               "%s: %s",
                               [key UTF8String],
                               [value UTF8String]);
         mulle_buffer_add_byte( &buffer, 0);

         _chunk = curl_slist_append( _chunk, mulle_buffer_get_bytes( &buffer));
      }
   }
   mulle_buffer_done( &buffer);

   curl_easy_setopt( _connection, CURLOPT_HTTPHEADER, _chunk);
}


/*
 * Options and internal mechanix
 */
static size_t  receive_curl_bytes( MulleCurl *self,
                                   void *contents,
                                   size_t sz,
                                   size_t nmemb,
                                   id <MulleCurlParser>  parser)
{
   unsigned long long   size;

   size = (unsigned long long ) sz * nmemb;
   if( (NSUInteger) size != size)
      [NSException raise:NSInternalInconsistencyException
                  format:@"Size %ld*%ld is excessive", sz, nmemb];

   if( ! [parser curl:self
           parseBytes:contents
               length:(NSUInteger) size])
   {
      return( 0);  // indicate an error, assume CURL aborts ?
   }
   return( (size_t) size);
}


static size_t   receive_curl_header_bytes( char *buffer,
                                           size_t size,
                                           size_t nitems,
                                           void *ctx)
{
   MulleCurl   *self = ctx;

   return( receive_curl_bytes( self, buffer, size, nitems, [self headerParser]));
}


static size_t   receive_curl_body_bytes( void *contents,
                                         size_t sz,
                                         size_t nmemb,
                                         void *ctx)
{
   MulleCurl   *self = ctx;

   return( receive_curl_bytes( self, contents, sz, nmemb, [self parser]));
}


- (void) setDebugOptions
{
   // only display curl output in debug mode
   curl_easy_setopt( _connection, CURLOPT_VERBOSE, (long) YES);
   curl_easy_setopt( _connection, CURLOPT_NOPROGRESS, (long) NO);
}


- (void) setDefaultOptions
{
   // only display curl output in debug mode
   curl_easy_setopt( _connection, CURLOPT_VERBOSE, (long) NO);
   curl_easy_setopt( _connection, CURLOPT_NOPROGRESS, (long) YES);

   // settings for programmatic I/O
   curl_easy_setopt( _connection, CURLOPT_NOSIGNAL, (long) YES);
   curl_easy_setopt( _connection, CURLOPT_FOLLOWLOCATION, (long) YES);

   curl_easy_setopt( _connection, CURLOPT_WRITEFUNCTION, receive_curl_body_bytes);
   curl_easy_setopt( _connection, CURLOPT_WRITEDATA, self);

   curl_easy_setopt( _connection, CURLOPT_USERAGENT, MulleCurlDefaultUserAgent());
}


- (void) setConnectTimeout:(NSTimeInterval) interval
{
   NSUInteger   ms;

   assert( interval >= 0);
   ms = (NSUInteger) (interval * 1000 * 1000 + 0.5);
   curl_easy_setopt( _connection, CURLOPT_CONNECTTIMEOUT_MS, (long) ms);
}


- (void) setLowSpeedTimeOut:(NSTimeInterval) interval
           minBitsPerSecond:(NSUInteger) speedLimit
{
   NSUInteger   secs;

   assert( interval >= 0);
   secs = (NSUInteger) (interval + 0.5);
   curl_easy_setopt( _connection, CURLOPT_LOW_SPEED_TIME, (long) secs);
   curl_easy_setopt( _connection, CURLOPT_LOW_SPEED_LIMIT, (long) (speedLimit / 8));
}



- (void) setDesktopTimeoutOptions
{
   // some default timeout settings
   // could tweak this for mobile or so
   curl_easy_setopt( _connection, CURLOPT_CONNECTTIMEOUT_MS, 2000L);  // rather retry  (IMO)
   curl_easy_setopt( _connection, CURLOPT_LOW_SPEED_TIME, 60L);      // 30s @
   curl_easy_setopt( _connection, CURLOPT_LOW_SPEED_LIMIT, 32000L/8); // 32 kbps min
}


- (void) setMobileTimeoutOptions
{
   // some default timeout settings
   // could tweak this for mobile or so
   curl_easy_setopt( _connection, CURLOPT_CONNECTTIMEOUT_MS, 5000L);  //
   curl_easy_setopt( _connection, CURLOPT_LOW_SPEED_TIME, 120L);     // 30s @
   curl_easy_setopt( _connection, CURLOPT_LOW_SPEED_LIMIT, 2400L/8); // 2400 bps min
}


- (void) setNoBodyOptions
{
   curl_easy_setopt( _connection, CURLOPT_NOBODY, 1L);  // useful for header only
}


- (void) setOptions:(NSDictionary *) options
{
   CURLcode     rval;
   id           value;
   int          type;
   intptr_t     option;
   NSMapTable   *optionLookupTable;
   NSString     *key;

   optionLookupTable = [MulleCurl optionLookupTable];

   for( key in options)
   {
      value  = [options :key];
      option = (intptr_t) NSMapGet( optionLookupTable, key);
      if( ! option)
         [NSException raise:NSInvalidArgumentException
                     format:@"unknown curl option %@", key];

      type     = option & 0xF;
      option >>= 4;
      switch( type)
      {
      case MULLE_CURL_LONG  :
         rval = curl_easy_setopt( _connection, option, [value longValue]);
         break;

      case MULLE_CURL_OFF_T  :
         rval = curl_easy_setopt( _connection, option, (curl_off_t) [value longLongValue]);
         break;

      case MULLE_CURL_STRINGPOINT  :
         rval = curl_easy_setopt( _connection, option, [value UTF8String]);
         break;

      default :
         [NSException raise:NSInvalidArgumentException
                     format:@"curl option type for %@ is unsupported", key];
      }

      if( rval)
         [NSException raise:NSInvalidArgumentException
                     format:@"curl option %@ could not be set: \"%s\"",
                              curl_easy_strerror( rval)];
   }
}


- (void) setHeaderParser:(NSObject <MulleCurlParser> *) parser
{
   if( _headerParser && ! parser)
   {
      curl_easy_setopt( _connection, CURLOPT_HEADERFUNCTION, NULL);
      curl_easy_setopt( _connection, CURLOPT_HEADERDATA, NULL);
   }

   [_headerParser autorelease];
   _headerParser = [parser retain];

   if( parser)
   {
      curl_easy_setopt( _connection, CURLOPT_HEADERFUNCTION, receive_curl_header_bytes);
      curl_easy_setopt( _connection, CURLOPT_HEADERDATA, self);
   }
}


- (NSUInteger) lastResponseCode
{
   long   code;

   if( curl_easy_getinfo(_connection, CURLINFO_RESPONSE_CODE, &code) != CURLE_OK)
      return( NSNotFound);
   return( code);
}

/*
 * The actual response/request
 */
- (id) _parseContentsOfURLWithString:(NSString *) url
                       byPostingData:(NSData *) data
{
   CURLcode     res;
   NSUInteger   length;
   NSUInteger   code;

   NSParameterAssert( [url isKindOfClass:[NSString class]]);

   if( ! _parser)
      [NSException raise:NSInternalInconsistencyException
                  format:@"You must have set the parser before calling %s", __FUNCTION__];
   if( ! [url length])
      [NSException raise:NSInvalidArgumentException
                  format:@"empty URL"];

   MulleCurlSetErrorDomain();

   curl_easy_setopt( _connection, CURLOPT_URL, [url UTF8String]);
   if( data)
   {
      length = [data length];
      curl_easy_setopt( _connection, CURLOPT_POSTFIELDSIZE_LARGE, (curl_off_t) length);
      curl_easy_setopt( _connection, CURLOPT_POSTFIELDS, [data bytes]);
   }
   else
      curl_easy_setopt( _connection, CURLOPT_POST, 0L);

   res = curl_easy_perform( _connection);
   if( res != CURLE_OK)
   {
      //
      // Parser can use his own errors, but will need to set NSError
      // directly
      //
      errno = res;
      return( nil);
   }

   if( _validResponseCode)
   {
      code = [self lastResponseCode];
      if( code == NSNotFound)
         return( nil);

      if( code != _validResponseCode)
         return( nil);
   }

   return( [_parser parsedObjectWithCurl:self]);
}



- (id) parseContentsOfURLWithString:(NSString *) url
{
   return( [self _parseContentsOfURLWithString:url
                                 byPostingData:nil]);
}


- (id) parseContentsOfURLWithString:(NSString *) url
                      byPostingData:(NSData *) data
{
   NSParameterAssert( ! data || [data isKindOfClass:[NSData class]]);

   return( [self _parseContentsOfURLWithString:url
                                 byPostingData:data]);
}



- (NSData *) dataWithContentsOfURLWithString:(NSString *) url
{
   id   plist;

   [self setParser:[NSMutableData object]];
   {
      plist = [self _parseContentsOfURLWithString:url
                                    byPostingData:nil];
   }
   [self setParser:nil];

   return( plist);
}


- (NSData *) dataWithContentsOfURLWithString:(NSString *) url
                               byPostingData:(NSData *) data
{
   id   plist;

   [self setParser:[NSMutableData object]];
   {
      plist = [self _parseContentsOfURLWithString:url
                                    byPostingData:data];
   }
   [self setParser:nil];

   return( plist);
}


@end



int   __MULLE_CURL_ranlib__;


uint32_t   MulleCurl_get_version( void)
{
   return( MULLE_CURL_VERSION);
}

