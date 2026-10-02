//
//  NSURL.m
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
#import "NSURL.h"

// other libraries of MulleObjCStandardFoundation
#import "NSCharacterSet+MulleURL.h"

// std-c and dependencies
#include <string.h>
#include <ctype.h>


// could ifdef for TPS here :)
#define MulleURLPathComponentSeparator   @"/"
#define MulleURLPathExtensionSeparator   @"."
#define MulleURLPathParent               @".."


static id   assign_checked_utf8_to_ivar( id self,
                                         NSString **ivar,
                                         char *utf8,
                                         NSUInteger utf8_length,
                                         NSCharacterSet *characterSet)
{
   NSUInteger   length;

   if( ! self)
      return( self);

   assert( utf8);

   if( utf8_length == (NSUInteger) -1)
      utf8_length = mulle_utf8_strlen( utf8) + 1;

   *ivar = [[NSString alloc] mulleInitWithUTF8Characters:utf8
                                                  length:utf8_length];
   if( ! *ivar)
   {
#ifdef DEBUG
      fprintf( stderr, "%.*s of URL has invalid UTF8\n", (int) utf8_length, utf8);
#endif
      [self release];
      return( nil);
   }

   // if utf8 contained emojis or stuff, length is now different
   length = [*ivar length];
   if( characterSet && [*ivar mulleRangeOfCharactersFromSet:characterSet
                                                    options:NSLiteralSearch
                                                      range:NSMakeRange( 0, length)].length != length)
   {
#ifdef DEBUG
      fprintf( stderr, "%.*s of URL has invalid characters\n", (int) utf8_length, utf8);
#endif
      [self release]; // will release ivar
      return( nil);
   }

   return( self);
}


enum URLCharacterSetCode
{
   URLSchemeAllowedCharacterSet,

   URLEscapedUserAllowedCharacterSet,
   URLEscapedPasswordAllowedCharacterSet,
   URLEscapedHostAllowedCharacterSet,
   URLEscapedPathAllowedCharacterSet,
   URLEscapedParameterStringAllowedCharacterSet,
   URLEscapedQueryAllowedCharacterSet,
   URLEscapedFragmentAllowedCharacterSet,

   URLEscapedAllowedCharacterSet
};


NSString   *NSURLFileScheme = @"file";


@implementation NSURL

@dependency MulleObjCDeps( MulleObjCStandardFoundation);

static struct
{
   mulle_thread_mutex_t   _lock;
   NSMapTable             *_schemes;
   NSMapTable             *_charsets;
} Self;




+ (void) load
{
   mulle_thread_mutex_init( &Self._lock);
}


+ (void) unload
{
   if( Self._schemes)
      NSFreeMapTable( Self._schemes);
   if( Self._charsets)
      NSFreeMapTable( Self._charsets);
   mulle_thread_mutex_done( &Self._lock);
}


//
// we need specialized character sets, because we are checking percent escaped
// strings... If these turn out too big, then create custom ones...
// in NSCharacterSet
//

static void  lazyInitializeCharsets( void)
{
   NSMutableCharacterSet   *characterSet;

   Self._charsets = NSCreateMapTable( NSIntegerMapKeyCallBacks,
                                      NSObjectMapValueCallBacks,
                                      8);

   characterSet = (id) [NSCharacterSet mulleURLSchemeAllowedCharacterSet];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLSchemeAllowedCharacterSet, characterSet);

   characterSet = [NSMutableCharacterSet URLUserAllowedCharacterSet];
   [characterSet addCharactersInString:@"%"];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLEscapedUserAllowedCharacterSet, characterSet);

   characterSet = [NSMutableCharacterSet URLPasswordAllowedCharacterSet];
   [characterSet addCharactersInString:@"%"];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLEscapedPasswordAllowedCharacterSet, characterSet);

   characterSet = [NSMutableCharacterSet URLHostAllowedCharacterSet];
   [characterSet addCharactersInString:@"%"];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLEscapedHostAllowedCharacterSet, characterSet);

   characterSet = [NSMutableCharacterSet URLPathAllowedCharacterSet];
   [characterSet addCharactersInString:@"%"];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLEscapedPathAllowedCharacterSet, characterSet);

   characterSet = [NSMutableCharacterSet URLPathAllowedCharacterSet];
   [characterSet addCharactersInString:@"%;"];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLEscapedParameterStringAllowedCharacterSet, characterSet);

   characterSet = [NSMutableCharacterSet URLQueryAllowedCharacterSet];
   [characterSet addCharactersInString:@"%"];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLEscapedQueryAllowedCharacterSet, characterSet);

   characterSet = [NSMutableCharacterSet URLFragmentAllowedCharacterSet];
   [characterSet addCharactersInString:@"%"];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLEscapedFragmentAllowedCharacterSet, characterSet);

   characterSet = [NSMutableCharacterSet mulleURLAllowedCharacterSet];
   [characterSet addCharactersInString:@"%"];
   NSMapInsertKnownAbsent( Self._charsets, (void *) URLEscapedAllowedCharacterSet, characterSet);
}



static NSCharacterSet  *characterSetWithCode( enum URLCharacterSetCode code)
{
   NSCharacterSet   *characterSet;

   mulle_thread_mutex_init( &Self._lock);
   {
      if( ! Self._charsets)
         lazyInitializeCharsets();

      characterSet = NSMapGet( Self._charsets, (void  *) code);
      characterSet = [[characterSet retain] autorelease];
   }
   mulle_thread_mutex_done( &Self._lock);

   return( characterSet);
}


// handler must be a static or global struct, not allocated or autoreleased
//
+ (void) mulleRegisterHandler:(struct MulleURLSchemeHandler *) handler
                    forScheme:(NSString *) scheme
{
   mulle_thread_mutex_init( &Self._lock);
   {
      if( ! Self._schemes)
         Self._schemes = NSCreateMapTable( NSObjectMapKeyCallBacks,
                                           MulleSELMapValueCallBacks,
                                           8);

      NSMapInsert( Self._schemes, scheme, handler);
   }
   mulle_thread_mutex_done( &Self._lock);
}




static struct MulleURLSchemeHandler  *
   lookupHandlerForScheme( NSString *scheme,
                           struct MulleURLSchemeHandler *space)
{
   struct MulleURLSchemeHandler    *p_handler;

   scheme = [scheme lowercaseString];
   mulle_thread_mutex_init( &Self._lock);
   {
      p_handler = NSMapGet( Self._schemes, scheme);
      if( p_handler)
      {
         *space    = *p_handler;
         p_handler = space;
      }
   }
   mulle_thread_mutex_done( &Self._lock);

   return( p_handler);
}



+ (instancetype) URLWithString:(NSString *) string
{
   return( [[[self alloc] initWithString:string] autorelease]);
}


+ (instancetype) URLWithString:(NSString *) string
                 relativeToURL:(NSURL *) baseURL
{
   return( [[[self alloc] initWithString:string
                           relativeToURL:baseURL] autorelease]);
}


+ (NSCharacterSet *) mulleURLEscapedAllowedCharacterSet
{
   return( characterSetWithCode( URLEscapedAllowedCharacterSet));
}

/*
 *  init
 */

- (instancetype) initWithScheme:(NSString *) scheme
                           host:(NSString *) host
                           path:(NSString *) path
{
   NSCharacterSet                    *set;
   struct MulleEscapedURLPartsUTF8   parts;

   memset( &parts, 0, sizeof( parts));

   // scheme = alpha *( alpha | digit | "+" | "-" | "." )

   // here use characterset w/o percent escaping
   set  = [NSCharacterSet URLHostAllowedCharacterSet];
   host = [host stringByAddingPercentEncodingWithAllowedCharacters:set];
   set  = [NSCharacterSet URLPathAllowedCharacterSet];
   path = [path stringByAddingPercentEncodingWithAllowedCharacters:set];

   parts.scheme.characters       = [scheme UTF8String];
   parts.scheme.length           = [scheme mulleUTF8StringLength];

   parts.escaped_host.characters = [host UTF8String];
   parts.escaped_host.length     = [host mulleUTF8StringLength];

   parts.escaped_path.characters = [path UTF8String];
   parts.escaped_path.length     = [path mulleUTF8StringLength];

   parts.validated               = YES;

   set = [NSURL mulleURLEscapedAllowedCharacterSet];
   return( [self mulleInitWithEscapedURLPartsUTF8:&parts
                           allowedURICharacterSet:set]);
}


//
- (instancetype)
   mulleInitWithEscapedURLPartsUTF8:(struct MulleEscapedURLPartsUTF8 *) parts
             allowedURICharacterSet:(NSCharacterSet *) allowedCharacterSet
{
   // do this first before self can become nil
   if( parts->port >= 0x10000)
   {
#ifdef DEBUG
      fprintf( stderr, "port of URL is invalid\n");
#endif

      [self release];
      return( nil);
   }

   if( parts->port)
      _port = [[NSNumber alloc] initWithUnsignedInteger:parts->port];

   // scheme (has not percent escapes)
   if( parts->scheme.characters)
   {
      self = assign_checked_utf8_to_ivar( self,
                                          &_scheme,
                                          parts->scheme.characters,
                                          parts->scheme.length,
                                          parts->validated
                                             ? NULL
                                             : characterSetWithCode( URLSchemeAllowedCharacterSet));
   }
   // authority
   if( parts->escaped_user.characters)
      self = assign_checked_utf8_to_ivar( self,
                                          &_escapedUser,
                                          parts->escaped_user.characters,
                                          parts->escaped_user.length,
                                          parts->validated
                                             ? NULL
                                             : characterSetWithCode( URLEscapedUserAllowedCharacterSet));
   if( parts->escaped_password.characters)
      self = assign_checked_utf8_to_ivar( self,
                                          &_escapedPassword,
                                          parts->escaped_password.characters,
                                          parts->escaped_password.length,
                                          parts->validated
                                             ? NULL
                                             : characterSetWithCode( URLEscapedPasswordAllowedCharacterSet));
   if( parts->escaped_host.characters)
      self = assign_checked_utf8_to_ivar( self,
                                          &_escapedHost,
                                          parts->escaped_host.characters,
                                          parts->escaped_host.length,
                                          parts->validated
                                             ? NULL
                                             : characterSetWithCode( URLEscapedHostAllowedCharacterSet));

   // Use allowedCharacterSet as mulleURLAllowedCharacterSet if we don't want to
   // inconvience a possibly incorrect split up URI of an unknown scheme

   if( parts->escaped_path.characters)
      self = assign_checked_utf8_to_ivar( self,
                                          &_escapedPath,
                                          parts->escaped_path.characters,
                                          parts->escaped_path.length,
                                          parts->validated
                                             ? NULL
                                             : allowedCharacterSet
                                                ? allowedCharacterSet
                                                : characterSetWithCode( URLEscapedPathAllowedCharacterSet));
   // part of path really
   if( parts->escaped_parameter.characters)
      self = assign_checked_utf8_to_ivar( self,
                                          &_escapedParameterString,
                                          parts->escaped_parameter.characters,
                                          parts->escaped_parameter.length,
                                          parts->validated
                                             ? NULL
                                             : allowedCharacterSet
                                                ? allowedCharacterSet
                                                : characterSetWithCode( URLEscapedParameterStringAllowedCharacterSet));
   // query
   if( parts->escaped_query.characters)
      self = assign_checked_utf8_to_ivar( self,
                                          &_escapedQuery,
                                          parts->escaped_query.characters,
                                          parts->escaped_query.length,
                                          parts->validated
                                             ? NULL
                                             : allowedCharacterSet
                                                ? allowedCharacterSet
                                                : characterSetWithCode( URLEscapedQueryAllowedCharacterSet));
   // fragment
   if( parts->escaped_fragment.characters)
      self = assign_checked_utf8_to_ivar( self,
                                          &_escapedFragment,
                                          parts->escaped_fragment.characters,
                                          parts->escaped_fragment.length,
                                          parts->validated
                                             ? NULL
                                             : allowedCharacterSet
                                                ? allowedCharacterSet
                                                : characterSetWithCode( URLEscapedFragmentAllowedCharacterSet));
   return( self);
}


- (instancetype) mulleInitWithSchemeUTF8Characters:(char *) scheme
                                            length:(NSUInteger) scheme_len
                   resourceSpecifierUTF8Characters:(char *) uri
                                            length:(NSUInteger) uri_len
{
   struct MulleURLSchemeHandler         *handler;
   struct MulleURLSchemeHandler         space;
   struct MulleURLSchemeInitArguments   args;

   if( scheme)
   {
      _scheme = [[NSString alloc] mulleInitWithUTF8Characters:scheme
                                                       length:scheme_len];
      handler = lookupHandlerForScheme( _scheme, &space);
      if( handler)
      {
         args.scheme.characters = scheme;
         args.scheme.length     = scheme_len;
         args.uri.characters    = uri;
         args.uri.length        = uri_len;

         return( [self performSelector:handler->initURL
                            withObject:(id) &args]);
      }
      //
      // known scheme but no handler ? handle URI generically
      //
   }

   return( [self mulleInitResourceSpecifierWithUTF8Characters:uri
                                                       length:uri_len]);
}


// scheme = alpha *( alpha | digit | "+" | "-" | "." )
static int   is_scheme_char( int c)
{
   if( c >= '0' && c <= '9')
      return( 1);
   if( c >= 'A' && c <= 'Z')
      return( 1);
   if( c >= 'a' && c <= 'z')
      return( 1);
   if( c == '+' || c == '-' || c == '.')
      return( 1);
   return( 0);
}


// returns location of ':'
static char   *parse_url_scheme( char *s, size_t length)
{
   char   *sentinel;
   char   c;

   sentinel = &s[ length];
   while( s < sentinel)
   {
      c = *s++;
      if( is_scheme_char( c))
         continue;
      if( c != ':')
         break;

      return( s - 1);
   }
   return( NULL);
}


- (instancetype) mulleInitWithUTF8Characters:(char *) utf8
                                      length:(NSUInteger) length
{
   struct MulleCharData   scheme;
   char                    *scheme_end;

   if( ! utf8)
   {
      [self release];
      return( nil);
   }

   // we want to differentiate between URLS w/o a scheme
   // URLs with a known scheme and URLs with an unknown scheme

   scheme.characters = NULL;
   scheme.length     = 0;
   scheme_end        = parse_url_scheme( utf8, length);

   if( scheme_end)
   {
      scheme.characters = utf8;
      scheme.length     = scheme_end - utf8;
      utf8              = &utf8[ scheme.length + 1];
      length            = length - (scheme.length + 1);
   }

   return( [self mulleInitWithSchemeUTF8Characters:scheme.characters
                                            length:scheme.length
                   resourceSpecifierUTF8Characters:utf8
                                            length:length]);
}


- (instancetype) mulleInitResourceSpecifierWithUTF8Characters:(char *) utf
                                                       length:(NSUInteger) length
{
   struct MulleEscapedURLPartsUTF8   parts;
   char                              *expect;
   size_t                            len;
   struct MulleCharData             *p;
   struct MulleCharData             *q;
   NSCharacterSet                    *set;

   // now do it all manually :(
   memset( &parts, 0, sizeof( parts));

   p = &parts.escaped_path;

   // empty path is not desirable
   if( length)
   {
      p->characters = utf;
      p->length     = length;

      // path parameter query fragment
      expect = ";?#";
      for(;expect;)
      {
         len = mulle_utf8_strncspn( p->characters, p->length, expect);
         if( len == p->length)
            break;  // done

         switch( p->characters[ len])
         {
         case ';' : q = &parts.escaped_parameter; expect = "?#" ; break;
         case '?' : q = &parts.escaped_query;     expect = "#"; break;
         case '#' : q = &parts.escaped_fragment;  expect = NULL; break;
         }

         q->characters = &p->characters[ len + 1];
         q->length     = p->length - (len + 1);

         p->length = len;
         if( ! len)
            p->characters = NULL;

         p = q;
      }
   }

   set = [NSURL mulleURLEscapedAllowedCharacterSet];
   return( [self mulleInitWithEscapedURLPartsUTF8:&parts
                           allowedURICharacterSet:set]);
}


- (instancetype) initWithString:(NSString *) s
{
   NSUInteger     length;
   char           *utf8;

   NSParameterAssert( ! s || [s isKindOfClass:[NSString class]]);

   length = [s mulleUTF8StringLength];
   utf8   = [s UTF8String];

   return( [self mulleInitWithUTF8Characters:utf8
                                      length:length]);
}


- (instancetype) initWithString:(NSString *) string
                  relativeToURL:(NSURL *) baseURL
{
   NSArray          *array;
   NSMutableArray   *components;

   NSParameterAssert( ! baseURL || [baseURL isKindOfClass:[NSURL class]]);

   self = [self initWithString:string];
   if( ! self || ! baseURL)
      return( self);

   if( _scheme)
      return( self);

   _scheme = [baseURL->_scheme copy];

   if( ! _escapedHost)
   {
      assert( ! _escapedUser);
      assert( ! _escapedPassword);

      _escapedUser     = [baseURL->_escapedUser copy];
      _escapedPassword = [baseURL->_escapedPassword copy];
      _escapedHost     = [baseURL->_escapedHost copy];
      _port            = [baseURL->_port copy];
   }

   //
   // if path is empty we only merge from baseURL until we have something
   //
   if( ! _escapedPath)
   {
      _escapedPath = [baseURL->_escapedPath copy];
      if( ! _escapedParameterString)
      {
         _escapedParameterString = [baseURL->_escapedParameterString copy];
         if( ! _escapedQuery)
         {
            _escapedQuery = [baseURL->_escapedQuery copy];
            if( ! _escapedFragment)
               _escapedFragment = [baseURL->_escapedFragment copy];
         }
      }
      return( self);
   }

   // otherwise merge paths, if relative
   if( [_escapedPath hasPrefix:@"/"]) // don't concat if absolute
      return( self);

   array      = [baseURL->_escapedPath componentsSeparatedByString:MulleURLPathComponentSeparator];
   components = [NSMutableArray arrayWithArray:array];

   // get rid of '/' or overwritten last component, except if only entry (/)
   if( [components count] > 1)
      [components removeLastObject];

   array      = [_escapedPath componentsSeparatedByString:MulleURLPathComponentSeparator];
   [components addObjectsFromArray:array];

   [_escapedPath autorelease];
   _escapedPath = [[components componentsJoinedByString:MulleURLPathComponentSeparator] copy];

   return( self);
}



- (void) dealloc
{
   [_scheme release];
   [_escapedUser release];
   [_escapedPassword release];
   [_escapedHost release];
   [_port release];
   [_escapedPath release];
   [_escapedParameterString release];
   [_escapedQuery release];
   [_escapedFragment release];

   [super dealloc];
}



// we are immutable...
- (id) copy
{
   return( [self retain]);
}


/*
 * Convert to string
 */

- (NSString *) mulleGenericResourceSpecifierDescription
{
   NSMutableString   *result;

   //
   // not sure what to do if baseURL has a resourceSpecifier
   //
   result = [NSMutableString object];

   if( _escapedPath)
      [result appendString:_escapedPath];

   if( _escapedParameterString)
   {
      [result appendString:@";"];
      [result appendString:_escapedParameterString];
   }

   if( _escapedQuery)
   {
      [result appendString:@"?"];
      [result appendString:_escapedQuery];
   }

   if( _escapedFragment)
   {
      [result appendString:@"#"];
      [result appendString:_escapedFragment];
   }
   return( result);
}


//
// <image url="https://en.wikipedia.org/wiki/File:URI_syntax_diagram.svg">
//
- (NSString *) mulleGenericURLDescription
{
   NSMutableString   *result;
   NSString          *uri;

   result = [NSMutableString object];

   if( _scheme)
   {
      [result appendString:_scheme];
      [result appendString:@":"];
   }

   // The URL syntax is dependent upon the scheme.!
   // If the "//" are printed or not
   // e.g. file:///etc/passwd has always a host component, even if empty
   // but mailto:user@foo.com doesn't.
   //
   // It's easier for printing if we allow "host" as nil and @"", which in
   // turn will print either http:/foo.com/x.html or http://foo.com/x.html
   // authority
   //

   if( _escapedHost)
   {
      [result appendString:@"//"];

      if( _escapedUser)
      {
         [result appendString:_escapedUser];

         if( _escapedPassword)
         {
            [result appendString:@":"];
            [result appendString:_escapedPassword];
         }

         [result appendString:@"@"];
      }

      [result appendString:_escapedHost];

      if( _port)
      {
         [result appendString:@":"];
         [result appendString:[_port description]];
      }
   }

   uri = [self mulleEscapedResourceSpecifier];
   [result appendString:uri];

   return( result);
}


- (NSString *) stringValue
{
   SEL                            print;
   NSString                       *s;
   struct MulleURLSchemeHandler   *handler;
   struct MulleURLSchemeHandler   space;

   handler = lookupHandlerForScheme( _scheme, &space);
   print   = handler ? handler->printURL : @selector( mulleGenericURLDescription);
   s       = [self performSelector:print];
   return( s);
}


- (NSString *) description
{
   return( [self stringValue]);
}


- (NSString *) mulleEscapedResourceSpecifier
{
   SEL                            print;
   NSString                       *s;
   struct MulleURLSchemeHandler   *handler;
   struct MulleURLSchemeHandler   space;

   handler = lookupHandlerForScheme( _scheme, &space);
   print   = handler ? handler->printResourceSpecifier
                     : @selector( mulleGenericResourceSpecifierDescription);
   s       = [self performSelector:print];
   return( s);
}


//
// we aren't doing just file URLs. We do assume that the separator is '/'
//
- (NSURL *) URLByAppendingPathComponent:(NSString *) component
{
   NSURL            *url;
   NSString         *s;
   NSCharacterSet   *set;

   url = [[NSURL new] autorelease];

   url->_scheme                 = [_scheme copy];
   url->_escapedUser            = [_escapedUser copy];
   url->_escapedPassword        = [_escapedPassword copy];
   url->_escapedHost            = [_escapedHost copy];  // percent escaping in http seems not possible ?
   url->_port                   = [_port copy];
   url->_escapedParameterString = [_escapedParameterString copy];
   url->_escapedQuery           = [_escapedQuery copy];
   url->_escapedFragment        = [_escapedFragment copy];

   s    = [[self path] mulleStringByAppendingComponent:component
                               separatedByString:@"/"];
   set  = [NSCharacterSet URLPathAllowedCharacterSet];

   url->_escapedPath = [[s stringByAddingPercentEncodingWithAllowedCharacters:set] copy];

   return( url);
}



#pragma mark - unescaping accessors

//
// This property contains the path, unescaped using the
// stringByReplacingPercentEscapesUsingEncoding: method. If the receiver does
// not conform to RFC 1808, this property contains nil.
//
- (NSString *) scheme
{
   return( _scheme);
}


- (NSNumber *) port
{
   return( _port);
}


- (NSString *) user
{
   return( [_escapedUser stringByRemovingPercentEncoding]);
}


- (NSString *) password
{
   return( [_escapedPassword stringByRemovingPercentEncoding]);
}


- (NSString *) host
{
   return( [_escapedHost stringByRemovingPercentEncoding]);
}


- (NSString *) path
{
   return( [_escapedPath stringByRemovingPercentEncoding]);
}


- (NSString *) parameterString
{
   return( [_escapedParameterString stringByRemovingPercentEncoding]);
}


- (NSString *) query
{
   return( [_escapedQuery stringByRemovingPercentEncoding]);
}


- (NSString *) fragment
{
   return( [_escapedFragment stringByRemovingPercentEncoding]);
}


- (NSString *) resourceSpecifier
{
   return( [[self mulleEscapedResourceSpecifier] stringByRemovingPercentEncoding]);
}


/*
 * For compatibility some methods operating on path
 */

//
// can't reuse NSString code, because it might have different separator
// characters
//
static NSRange  getLastPathComponentRange( NSString *self)
{
   return( [self rangeOfString:MulleURLPathComponentSeparator
                       options:NSBackwardsSearch]);
}


static NSRange  getPathExtensionRange( NSString *self)
{
   NSRange   range1;
   NSRange   range2;

   range1 = getLastPathComponentRange( self);
   if( range1.length == 0)
      return( range1);

   range2 = [self rangeOfString:MulleURLPathExtensionSeparator
                        options:NSBackwardsSearch];
   if( range2.length && range1.location < range2.location)
      return( NSMakeRange( NSNotFound, 0));

   return( range1);
}


- (NSArray *) pathComponents
{
   return( [[self path] componentsSeparatedByString:MulleURLPathComponentSeparator]);
}


- (NSString *) lastPathComponent
{
   NSRange   range;
   NSString  *path;

   path  = [self path];
   range = getLastPathComponentRange( path);
   if( ! range.length)
      return( path);

   return( [path substringFromIndex:range.location + 1]);
}


- (NSString *) pathExtension
{
   NSRange    range;
   NSString   *path;

   path  = [self path];
   range = getPathExtensionRange( path);
   if( ! range.length)
      return( nil);
   return( [path substringFromIndex:range.location + 1]);
}



#pragma mark - obsolete stuff

- (NSURL *) standardizedURL
{
   return( self);
}


- (NSString *) absoluteString
{
   return( [self stringValue]);
}


- (NSURL *) absoluteURL
{
   return( self);
}


- (NSString *) relativePath
{
   return( [self path]);
}


- (NSString *) relativeString
{
   if( [self mulleIsAbsolutePath])
      return( [self absoluteString]);
   return( [self mulleEscapedResourceSpecifier]);
}


- (NSURL *) baseURL
{
   return( nil);
}



#pragma mark - queries

- (BOOL) isFileURL
{
   return( [_scheme isEqualToString:@"file"]);
}


- (BOOL) mulleIsAbsolutePath
{
   return( [_escapedPath hasPrefix:MulleURLPathComponentSeparator]);
}


#if DEBUG
- (void) mulleDump
{
   char  *s;

   fprintf( stderr, "Scheme    : %p %s\n",  _scheme,          (s = [_scheme UTF8String]) ? s : "*nil*");
   fprintf( stderr, "User      : %p %s\n",  _escapedUser,     (s = [_escapedUser UTF8String]) ? s : "*nil*");
   fprintf( stderr, "Password  : %p %s\n",  _escapedPassword, (s = [_escapedPassword UTF8String]) ? s : "*nil*");
   fprintf( stderr, "Host      : %p %s\n",  _escapedHost,     (s = [_escapedHost UTF8String]) ? s : "*nil*");
   fprintf( stderr, "Port      : %p %ld\n", _port,            [_port longValue]);
   fprintf( stderr, "Path      : %p %s\n",  _escapedPath,     (s = [_escapedPath UTF8String]) ? s : "*nil*");
   fprintf( stderr, "Parameter : %p %s\n",  _escapedParameterString,  (s = [_escapedParameterString UTF8String]) ? s : "*nil*");
   fprintf( stderr, "Query     : %p %s\n",  _escapedQuery,    (s = [_escapedQuery UTF8String]) ? s : "*nil*");
   fprintf( stderr, "Fragment  : %p %s\n",  _escapedFragment, (s = [_escapedFragment UTF8String]) ? s : "*nil*");
}
#endif


#pragma mark - filesystem (file:) URLs

- (char *) fileSystemRepresentation
{
   return( [[self path] fileSystemRepresentation]);
}


- (BOOL) getFileSystemRepresentation:(char *) buf
                           maxLength:(NSUInteger) max
{
   return( [[self path] getFileSystemRepresentation:buf
                                          maxLength:max]);
}


//
// We don't convenience, if path is a directory and append '/'.
// It's not really foolproof either:
//  touch foo/a ;  initFile... ; rm foo/a ; mkdir foo/a
//
- (instancetype) initFileURLWithPath:(NSString *) path
{
   return( [self initWithScheme:NSURLFileScheme
                           host:nil
                           path:path]);
}


+ (instancetype) fileURLWithPath:(NSString *) path
{
   return( [[[self alloc] initFileURLWithPath:path] autorelease]);
}


- (instancetype) initFileURLWithPath:(NSString *) path
                         isDirectory:(BOOL) isDirectory
{
   MULLE_C_UNUSED( isDirectory );
   return( [self initWithScheme:NSURLFileScheme
                           host:nil
                           path:path]);
}


+ (instancetype) fileURLWithPath:(NSString *) path
                     isDirectory:(BOOL) isDirectory
{
   return( [[[self alloc] initFileURLWithPath:path
                                  isDirectory:isDirectory] autorelease]);
}


+ (instancetype) fileURLWithPathComponents:(NSArray *) components
{
   return( [self fileURLWithPath:[NSString pathWithComponents:components]]);
}

@end
