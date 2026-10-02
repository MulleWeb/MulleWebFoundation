//
//  MulleCurl.h
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
#import "import.h"

#import "MulleCurlParser.h"


// MEMO: don't taint MulleCurl with NSURL

@interface MulleCurl : NSObject
{
   void   *_chunk;
}

@property( assign) void        *connection;         // CURL *
@property( assign) NSUInteger  validResponseCode;   // 0 : don't care, 200 = http OK (default)

// set these if you use the parser interface
@property( retain) NSObject <MulleCurlParser>  *parser;
// you can optionally also specify a header parser. In the simplest case
// you plop in a NSMutableData and retrieve it later.
@property( retain) NSObject <MulleCurlParser>  *headerParser;

//
// instead of @selector( description) you can place your own method
// here, which may or may not be smarter about formatting dates and other stuff
//
@property( assign) SEL   headerValueDescriptionMethod;

//
// properties for use by the parser itself
// userInfo could be used for storing intermediate results or so
//
@property( retain) id   userInfo;

//
// Key must not contain ':' and must be the proper HTTP Header key.
// The Value -mulleCurlRequestHeaderValueDescription will be used, what ever that
// might be (usually -description)
// e.g.  @{ @"Accept": @"*/*"}
// Overwrites previous headers
//
- (void) setRequestHeaders:(NSDictionary *) headers;

//
// Objc interface to curl options, you could also just get
// the connection and do curl_easy_setopt yourself though.
// Use the name of the curl option like @"CURLOPT_VERBOSE"
// as the key and an appropriate NSString or NSNumber for value.
// See. https://curl.haxx.se/libcurl/c/curl_easy_setopt.html
// for a list of options.
//
- (void) setOptions:(NSDictionary *) options;

// useful for HEAD ?
- (void) setNoBodyOptions;

// choose either one for a somewhat better experience, the
// default is neither!
- (void) setDesktopTimeoutOptions;
- (void) setMobileTimeoutOptions;

// or set options indiviauylly like this...
- (void) setConnectTimeout:(NSTimeInterval) interval;
- (void) setLowSpeedTimeOut:(NSTimeInterval) interval
           minBitsPerSecond:(NSUInteger) speedLimit;

// these are always set on init and reset
// they enable -L , turn off signaling (!) and disable verbose and progress
- (void) setDefaultOptions;

// re-enables progress and verbose
- (void) setDebugOptions;

//
// call this if you want to to return to curl standard options +
// setDefaultOptions (as if you ran -init again)
// Also removes the parser, headerParser and userInfo
//
- (void) reset;

//
// Convenience: (See MulleWebClient for more conveniences)
//
// If these return NULL, and error occurred. You can retrieve the
// appropriate NSError with:
//
//    MulleObjCExtractError()
// or
//    +[NSError mulleExtract]
//
// These routines will reset the parser as they actually use the
// -parseContentsOfURLWithString: variants for the actual work. The header
// parser is unaffected though.
//
- (NSData *) dataWithContentsOfURLWithString:(NSString *) url;

//
// If posting Data make sure that the Content-Type is set correctly.
// the data is send "As Is".
//
// https://stackoverflow.com/questions/4007969/application-x-www-form-urlencoded-or-multipart-form-data
// https://dev.to/sidthesloth92/understanding-html-form-encoding-url-encoded-and-multipart-forms-3lpa

- (NSData *) dataWithContentsOfURLWithString:(NSString *) url
                               byPostingData:(NSData *) data;

//
// You can not just get NSData but you can also plug in a parser like
// f.e. MulleJSMNParser and translate JSON content directly into whatever
// it is (usually a NSDictionary *) in the JSON case. Since the parsing
// is done incremental, this should have less latency then doing
// -dataWithContentsOfURLWithString: and then doing the parse afterwards (for
// large contents)
// -setParser: beforehand.
//
// If _validResponseCode is set, these routines will check that the response
// is a valid response (like 200) and return nil, if not. This simplifies
// calling code, that just wants to get some NSData from the URL or not
//
- (id) parseContentsOfURLWithString:(NSString *) url;
- (id) parseContentsOfURLWithString:(NSString *) url
                      byPostingData:(NSData *) data;

// like 404 (not found) or 200 (fine)
- (NSUInteger) lastResponseCode;

@end


// not thread safe, not thread local
@interface MulleCurl( ClassMethods)

+ (void) setDefaultUserAgent:(NSString *) agent;
+ (NSString *) defaultUserAgent;

@end

extern NSString   *MulleCurlErrorDomain; // = @"MulleCurlError";


#define MULLE_CURL_VERSION  ((0UL << 20) | (19 << 8) | 3)


static inline unsigned int   MulleCurl_get_version_major( void)
{
   return( MULLE_CURL_VERSION >> 20);
}


static inline unsigned int   MulleCurl_get_version_minor( void)
{
   return( (MULLE_CURL_VERSION >> 8) & 0xFFF);
}


static inline unsigned int   MulleCurl_get_version_patch( void)
{
   return( MULLE_CURL_VERSION & 0xFF);
}


extern uint32_t   MulleCurl_get_version( void);


#import "MulleObjCDeps+MulleCurl.h"


#ifdef __has_include
# if __has_include( "_MulleCurl-versioncheck.h")
#  include "_MulleCurl-versioncheck.h"
# endif
#endif
