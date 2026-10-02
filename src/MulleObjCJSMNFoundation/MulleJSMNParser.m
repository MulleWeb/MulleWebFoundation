//
//  MulleJSMNParser.m
//  MulleObjCJSMNFoundation
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
#import "MulleJSMNParser.h"


#import "import-private.h"

// other files in this library


// other libraries of MulleObjCStandardFoundation

// std-c and dependencies
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// strict parsing doesn't buy me a lot, we fix it later as the
// parser is too simple
//#define JSMN_STRICT
#define JSMN_STATIC         // don't expose JSMN functions
#define JSMN_PARENT_LINKS   // otherwise large JSMN don't parse in finite time
#include "jsmn.h"


NSString  *MulleJSMNErrorDomain = @"MulleJSMNError";


@implementation MulleJSMNParser

struct process_result
{
   id   obj;
   int  consumed_tokens;
};


static inline struct process_result   *process_result_make( id obj,
                                                            int n,
                                                            struct process_result *space)
{
   space->obj             = obj;
   space->consumed_tokens = n;
   return( space);
}


static inline struct process_result   *process_result_simple( id obj,
                                                              struct process_result *space)
{
   return( process_result_make( obj, 1, space));
}


struct process_context
{
   char                   *js;
   char                   *sentinel;
   struct process_result  space;
   id                     yes;
   id                     no;
   NSNull                 *null;
   jsmntok_t              *problem;

//
// Objective-C stuff:
//
// this works since NSString alloc and NSNumber as classclusters return
// a placeholder, where the actual new method is executed upon. The
// placeholder will not be released
//
   id                     stringFactory;
   IMP                    newString;

   id                     numberFactory;
   IMP                    newLongLongNumber;
   IMP                    newUnsignedLongLongNumber;
   IMP                    newDoubleNumber;
};


MULLE_C_NEVER_INLINE
static struct process_result  *process_tokens( struct process_context *p,
                                               jsmntok_t *t,
                                               size_t count)
{
   char                    *endptr;
   char                    *start;
   double                  dvalue;
   id                      key;
   id                      obj;
   id                      value;
   int                     i, j;
   int                     rval;
   jsmntok_t               *key_token;
   jsmntok_t               *value_token;
   long long               nr;
   char                    *s;
   size_t                  len;
   struct process_result   *result;

   if( count == 0)
      return( NULL);

   switch( t->type)
   {
   case JSMN_UNDEFINED :
      p->problem = t;
      return( NULL);

   case JSMN_PRIMITIVE :
      len   = (size_t) (t->end - t->start);
      start = p->js + t->start;
      switch( *start)
      {
      case 'n' :
         if( len == 4 && ! strncmp( start, "null", len))
            return( process_result_simple( [p->null retain], &p->space));
         break;

      case 't' :
         if( len == 4 && ! strncmp( start, "true", len))
            return( process_result_simple( [p->yes retain], &p->space));
         break;

      case 'f' :
         if( len == 5 && ! strncmp( start, "false", len))
            return( process_result_simple( [p->no retain], &p->space));
         break;

      case '0' :
      case '1' :
      case '2' :
      case '3' :
      case '4' :
      case '5' :
      case '6' :
      case '7' :
      case '8' :
      case '9' :
      case '-' :
         s    = start;
         rval = _mulle_utf8_scan_longlong_decimal( &s, len, &nr);
         if( rval < 0)
            return( NULL);

         // consumed all, than its integer
         if( s == &start[ len])
         {
            if( rval == mulle_utf_is_too_large_for_signed)
            {
               obj = MulleObjCIMPCallWithUnsignedLongLong( p->newUnsignedLongLongNumber,
                                                           p->numberFactory,
                                                           @selector( initWithUnsignedLongLong:),
                                                           (unsigned long long) nr);
               return( process_result_simple( obj, &p->space));
            }

            assert( rval == mulle_utf_is_valid);
            {
               obj = MulleObjCIMPCallWithLongLong( p->newLongLongNumber,
                                                   p->numberFactory,
                                                   @selector( initWithLongLong:),
                                                   (long long) nr);
               return( process_result_simple( obj, &p->space));
            }
         }

         // could be a float though, but only if we can convert all
         dvalue = strtod( start, &endptr);
         if( endptr == &start[ len])
         {
            obj = MulleObjCIMPCallWithDouble( p->newDoubleNumber,
                                              p->numberFactory,
                                              @selector( initWithDouble:),
                                              dvalue);
            return( process_result_simple( obj, &p->space));
         }
      }

      p->problem = t;
      return( NULL);

   case JSMN_STRING :
      len   = t->end - t->start;
      start = p->js + t->start;
      s     = start;
      {
         mulle_metaabi_union_voidptr_return( struct { char *characters;
                                                       NSUInteger length; }) param;

         param.p.characters = s;
         param.p.length     = len;

         obj = (id) (*p->newString)( p->stringFactory,
                                     (mulle_objc_methodid_t) @selector( mulleInitWithUTF8Characters:length:),
                                     &param);
      }
      return( process_result_simple( obj, &p->space));

   case JSMN_OBJECT :
      j   = 0;
      obj = [NSMutableDictionary new];

      for( i = 0; i < t->size; i++)
      {
         key_token  = &t[ 1 + j];
         // a possibly previous result will be invalid now as space is reused
         result = process_tokens( p, key_token, count - j);
         if( ! result)
         {
            [obj autorelease];
            return( NULL);
         }

         key    = result->obj;
         j     += result->consumed_tokens;
         value  = @"";
         if( key_token->size > 0)
         {
            value_token  = &t[ 1 + j];

            // a previous result will be invalid now as space is reused
            result = process_tokens( p, value_token, count - j);
            if( ! result)
            {
               [obj autorelease];
               [key autorelease];
               return( NULL);
            }

            value = result->obj;
            j    += result->consumed_tokens;
         }
         [obj mulleSetRetainedObject:value
                        forCopiedKey:key];
      }
      return( process_result_make( obj, j + 1, &p->space));

   case JSMN_ARRAY     :
       j   = 0;
       obj = [NSMutableArray new];

       for( i = 0; i < t->size; i++)
       {
         value_token = &t[ 1 + j];
         result      = process_tokens( p, value_token, count - j);
         if( ! result)
         {
            [obj autorelease];
            return( NULL);
         }

         value  = result->obj;
         j     += result->consumed_tokens;
         [obj mulleAddRetainedObject:value];
       }
       return( process_result_make( obj, j + 1, &p->space));
   }

   p->problem = t;
   return( NULL);
}


- (id) init
{
   assert( sizeof( jsmn_parser) <= sizeof( self->_space));
   assert( alignof( jsmn_parser) <= alignof( void *[4]));

   _parser = _space;
   [self reset];

   return( self);
}


- (void) reset
{
   [self setUserInfo:nil];
   [self setObject:nil];

   jsmn_init( _parser);

   _tokcount   = 512;
   _tok        = mulle_allocator_realloc( MulleObjCInstanceGetAllocator( self),
                                          _tok,
                                          sizeof( jsmntok_t) * _tokcount);
   _incomplete = NO;
}


- (void) dealloc
{
   mulle_allocator_free( MulleObjCInstanceGetAllocator( self), _tok);
   [super dealloc];
}


- (id) parseBytes:(void *) bytes
           length:(NSUInteger) length
{
   int                      rval;
   struct process_result    *result;
   struct process_context   ctxt;
   NSError                  *error;

  /* Allocate some tokens as a start */
again:
   rval = jsmn_parse( _parser, bytes, length, _tok, _tokcount);
   if( rval < 0)
   {
      if( rval == JSMN_ERROR_NOMEM)
      {
         assert( _tokcount);
         _tokcount = _tokcount * 2;
         _tok      = mulle_allocator_realloc( MulleObjCInstanceGetAllocator( self),
                                              _tok,
                                              sizeof( jsmntok_t) * _tokcount);
         goto again;
      }

      if( rval == JSMN_ERROR_PART)
         _incomplete = YES;
      // not a true error
      return( nil);
   }

   ctxt.js       = bytes;
   ctxt.sentinel = &((char *) bytes)[ length];
   ctxt.null     = [NSNull null];
   ctxt.problem  = 0;
   if( _trueFalseAsStrings)
   {
      ctxt.yes  = @"true";
      ctxt.no   = @"false";
   }
   else
   {
      ctxt.yes  = @(YES);  // can be tricky to output as true/false again
      ctxt.no   = @(NO);
   }


   assert( [NSNumber mulleContainsProtocol:@protocol( MulleObjCClassCluster)]);
   ctxt.numberFactory             = [NSNumber alloc];
   ctxt.newLongLongNumber         = [ctxt.numberFactory methodForSelector:@selector( initWithLongLong:)];
   ctxt.newUnsignedLongLongNumber = [ctxt.numberFactory methodForSelector:@selector( initWithUnsignedLongLong:)];
   ctxt.newDoubleNumber           = [ctxt.numberFactory methodForSelector:@selector( initWithDouble:)];

   assert( [NSString mulleContainsProtocol:@protocol( MulleObjCClassCluster)]);
   ctxt.stringFactory             = [NSString alloc];
   ctxt.newString                 = [ctxt.stringFactory methodForSelector:@selector( mulleInitWithUTF8Characters:length:)];

   result = process_tokens( &ctxt, _tok, rval);
   if( ! result)
   {
      error = [self errorWithName:@"syntax"
                            bytes:bytes
                           length:length
                            range:NSMakeRange( ctxt.problem->start,
                                               ctxt.problem->start- ctxt.problem->end)];
      [NSError mulleSetError:error];
      return( nil);
   }

   NSParameterAssert( result->obj);
   _object = result->obj;

   return( _object);
}



- (id) parseData:(NSData *) data
{
   return( [self parseBytes:[data bytes]
                     length:[data length]]);
}



- (NSError *) errorWithName:(NSString *) name
                      bytes:(void *) bytes
                     length:(NSUInteger) length
                      range:(NSRange) range
{
   char              *start;
   char              *sentinel;
   char              *line_end;
   char              *line_start;
   char              *s;
   int               next;
   NSMutableString   *reason;
   unsigned long     lineno;

   start    = bytes;
   sentinel = &start[ length];

   // figure out start of line and line number
   for( s = &start[ range.location]; --s >= start;)
      if( *s == '\r' || *s == '\n')
         break;
   line_start = s + 1;

   for( s = &start[ range.location]; s < sentinel; s++)
      if( *s == '\r' || *s == '\n')
         break;
   line_end = s;

   // get linecount
   lineno = length ? 1 : 0;
   next   = 0;
   for( s = line_start; --s >= start;)
   {
      if( *s == '\n' || (*s == '\r' && next != '\n'))
         ++lineno;
      next = *s;
   }

   reason = [NSMutableString stringWithFormat:@"JSON %@ error ", name];
   if( range.length)
      [reason appendFormat:@"at characters %ld \"%.*s\" ",
                           (long) (&start[ range.location] - line_start),
                           (int) range.length, &start[ range.location]];

   [reason appendFormat:@"in line %ld \"%.*s\"",
                        lineno,
                        (int) (line_end - line_start), line_start];

   return( [NSError errorWithDomain:MulleJSMNErrorDomain
                               code:-1
                           userInfo:@{ NSLocalizedFailureReasonErrorKey : reason}]);
}

@end



@implementation NSString( MulleJSMNParser)

- (id) mulleJSON
{
   MulleJSMNParser   *parser;
   NSData                *data;
   id                    obj;

   data   = [self dataUsingEncoding:NSUTF8StringEncoding];
   parser = [MulleJSMNParser object];
   obj    = [parser parseData:data];
   return( obj);
}

@end



