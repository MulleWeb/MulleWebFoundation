//
//  NSURL.h
//  MulleObjCInetFoundation
//
//  Copyright (c) 2017 Nat! - Mulle kybernetiK.
//  Copyright (c) 2011 Codeon GmbH.
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


@class NSString;
@class NSNumber;
@class NSArray;


struct MulleEscapedURLPartsUTF8
{
   // scheme
   struct MulleCharData   scheme;

   // authority
   struct MulleCharData   escaped_user;
   struct MulleCharData   escaped_password;
   struct MulleCharData   escaped_host;
   NSUInteger             port;

   // path
   struct MulleCharData   escaped_path;
   struct MulleCharData   escaped_parameter;

   // query
   struct MulleCharData   escaped_query;

   // fragment
   struct MulleCharData   escaped_fragment;

   int                    validated;  // set to YES, if you validated the contents yourself
};


struct MulleURLSchemeHandler
{
   SEL   initURL;
   SEL   printURL;
   SEL   printResourceSpecifier;
};


struct MulleURLSchemeInitArguments
{
   struct MulleCharData   scheme;
   struct MulleCharData   uri;
};


MULLE_OBJC_INET_FOUNDATION_EXTERN_GLOBAL
NSString   *NSURLFileScheme;


// Dont't use NSURL for file access! Use NSFileManager!
// NSURL is not an efficient storage mechanism for URLS, use NSString!
//
// NSURL will parse the urlString into constituent NSStrings. This makes
// URL objects fairly "fat". NSURL does a decent amount of sanity checking
// incoming strings. If you get nil back on init, then your URL is likely
// malformed.
//
// The Apple NSURL has this concept of marrying two NSURLs
// as baseURL and self with initWithString:baseURL:
// MulleFoundation doesn't do this, but creates a single new URL.
// I assume it's an outgrowth of the desire to replace strings for
// file operations, but that's IMO not a good idea. This NSURL also doesn't
// support these file operation methods, like changing attributes on files.
//
// Internally everything is stored as percentEscaped strings. But accessors
// will return unescaped strings for convenience, unless noted otherwise.
//
@interface NSURL : NSObject < NSCopying, MulleObjCImmutable>
{
   NSString   *_scheme;
   NSString   *_escapedUser;
   NSString   *_escapedPassword;
   NSString   *_escapedHost;  // percent escaping in http seems not possible ?
   NSNumber   *_port;
   NSString   *_escapedPath;
   NSString   *_escapedParameterString;
   NSString   *_escapedQuery;
   NSString   *_escapedFragment;
}


// incoming strings must already be percent escaped for all these methods
+ (instancetype) URLWithString:(NSString *) s;
+ (instancetype) URLWithString:(NSString *) s
                 relativeToURL:(NSURL *) url;
- (instancetype) initWithString:(NSString *) URLString;
- (instancetype) initWithString:(NSString *) URLString
                  relativeToURL:(NSURL *) baseURL;
- (id) mulleInitWithUTF8Characters:(char *) c_string
                            length:(NSUInteger) c_string_len;

// This method automatically uses percent encoding to escape the path
// and host parameters.
- (instancetype) initWithScheme:(NSString *) scheme
                           host:(NSString *) host
                           path:(NSString *) path;

// these return unescaped values

- (NSString *) scheme;
- (NSString *) user;
- (NSString *) password;
- (NSString *) host;
- (NSNumber *) port;       // just unescaped, no special file: handling
- (NSString *) path;
- (NSString *) parameterString;
- (NSString *) query;
- (NSString *) fragment;
- (NSString *) resourceSpecifier;

- (NSString *) stringValue;   // transform into a string
- (NSString *) description;   // URL with percent escapes (calls stringValue)


- (NSURL *) URLByAppendingPathComponent:(NSString *) component;

// mulle extensions

//
// incoming strings must be percent escaped already
//
- (instancetype) mulleInitWithEscapedURLPartsUTF8:(struct MulleEscapedURLPartsUTF8 *) parts
                           allowedURICharacterSet:(NSCharacterSet *) characterSet;


// parses just path;parameterString?query#fragment
// incoming strings must be percent escaped already
- (instancetype) mulleInitResourceSpecifierWithUTF8Characters:(char *) utf
                                                       length:(NSUInteger) length;

// for civetweb (unused)
- (instancetype) mulleInitWithSchemeUTF8Characters:(char *) scheme
                                             length:(NSUInteger) scheme_len
                    resourceSpecifierUTF8Characters:(char *)uri
                                             length:(NSUInteger) uri_len;

/*
 * Support for different schemes
 */
+ (void) mulleRegisterHandler:(struct MulleURLSchemeHandler *) handler
                    forScheme:(NSString *) scheme;

// default scheme handler methods
- (NSString *) mulleGenericResourceSpecifierDescription;
- (NSString *) mulleGenericURLDescription;
- (BOOL) mulleIsAbsolutePath;

// this is where mailto: keeps the part after scheme:
// user-fragment will be nil then
- (NSString *) mulleEscapedResourceSpecifier;

// non-restrictive charset for ResourceSpecifier
+ (NSCharacterSet *) mulleURLEscapedAllowedCharacterSet;


// filesystem (file:) URL support

- (char *) fileSystemRepresentation;
- (BOOL) getFileSystemRepresentation:(char *) buf
                           maxLength:(NSUInteger) max;

- (instancetype) initFileURLWithPath:(NSString *) path;
+ (instancetype) fileURLWithPath:(NSString *) path;
- (instancetype) initFileURLWithPath:(NSString *) path
                         isDirectory:(BOOL) isDirectory;
+ (instancetype) fileURLWithPath:(NSString *) path
                     isDirectory:(BOOL) isDirectory;

+ (instancetype) fileURLWithPathComponents:(NSArray *) components;


@end


@interface NSURL( Legacy)

// legacy stuff, that probably doesn't do anything interesting anymore
- (BOOL) isFileURL;

- (NSURL *) standardizedURL;
- (NSString *) absoluteString;      // use description as string conversion
- (NSString *) relativePath;
- (NSString *) relativeString;
- (NSURL *) baseURL;          // this is always nil
- (NSURL *) absoluteURL;     // returns self

// these return unescaped values

- (NSArray *) pathComponents;
- (NSString *) lastPathComponent;
- (NSString *) pathExtension;


@end


char  *mulle_strnstr( char *s, size_t len, char *search);
