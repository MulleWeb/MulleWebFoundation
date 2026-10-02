//
//  MulleObjCExpatParser.m
//  MulleObjCExpatFoundation
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
#import "MulleObjCExpatParser.h"

#import "MulleObjCXMLParser.h"
#import "import-private.h"

// other files in this library

// other libraries of MulleObjCStandardFoundation

// std-c and dependencies
#include <ctype.h>
#include <string.h>

#ifndef DEBUG
# define STACK_DEBUG   0
#else
# define STACK_DEBUG   0
#endif


/*
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>New item</key>
   <array>
      <string>VfL Bochum</string>
      <integer>1848</integer>
      <real>18.48</real>
      <date>2011-10-14T11:40:15Z</date>
      <real>1.4e+184</real>
      <data>AQgECA==</data>
      <true/>
      <false/>
   </array>
</dict>
</plist>
*/


@implementation MulleObjCExpatParser

//
// why no autorelease here ?
// reasoning:
//    there are no "callbacks" to outside code
//    all objects are maintained in the inside until _parseXMLData finishes
//    code is wrapped in exception try/catch
//
// keys are all static anyway
//
static void   pushKeyObj( MulleObjCExpatParser *self,
                          NSString *key,
                          id value)
{
   struct mulle_pointerpair   pair;

   pair.key   = key;
   pair.value = value;
   _mulle_pointerpairarray_add( &self->_stack, pair);
#if STACK_DEBUG
   mulle_fprintf( stderr, "+key : %s %s\n", [key UTF8String], [[value description] UTF8String]);
#endif
}


#if 0 // UNUSED
static NSString  *peekKey( MulleObjCExpatParser *self)
{
   struct mulle_pointerpair   pair;

   pair = mulle_pointerpairarray_get_last( &self->_stack);
   return( pair.value);
}
#endif


static void   *popKeyObj( MulleObjCExpatParser *self, id *value)
{
   struct mulle_pointerpair   pair;

   pair = mulle_pointerpairarray_pop( &self->_stack);
   if( value)
      *value = pair.value;

#if STACK_DEBUG
   mulle_fprintf( stderr, "-key : %s %s\n", [(id) pair.key UTF8String], [[(id) pair.value description] UTF8String]);
#endif
   return( pair.key == mulle_not_a_pointer ? NULL : pair.key);
}


static void   emptyObjects( MulleObjCExpatParser *self)
{
   id   value;

   while( popKeyObj( self, &value))
      [value autorelease];
}


static NSString  *_ArrayKey      = @"array";
static NSString  *_DataKey       = @"data";
static NSString  *_DateKey       = @"date";
static NSString  *_DictionaryKey = @"dict";
static NSString  *_FalseKey      = @"false";
static NSString  *_IntegerKey    = @"integer";
static NSString  *_KeyKey        = @"key";
static NSString  *_PlistKey      = @"plist";
static NSString  *_RealKey       = @"real";
static NSString  *_StringKey     = @"string";
static NSString  *_TrueKey       = @"true";


static NSString  *_keyForUTF8String( char *string)
{
   char   *s;

   s = string;
   switch( *s++)
   {
   case 'a' :
      if( ! strcmp( s, "rray"))
         return( _ArrayKey);
      break;

   case 'd' :
      if( ! strcmp( s, "ict"))
         return( _DictionaryKey);
      if( ! strcmp( s, "ate"))
         return( _DateKey);
      if( ! strcmp( s, "ata"))
         return( _DataKey);
      break;

   case 'f' :
      if( ! strcmp( s, "alse"))
         return( _FalseKey);
      break;

   case 'i' :
      if( ! strcmp( s, "nteger"))
         return( _IntegerKey);
      break;

   case 'k' :
      if( ! strcmp( s, "ey"))
         return( _KeyKey);
      break;

   case 'p' :
      if( ! strcmp( s, "list"))
         return( _PlistKey);
      break;

   case 'r' :
      if( ! strcmp( s, "eal"))
         return( _RealKey);
      break;

   case 's' :
      if( ! strcmp( s, "tring"))
         return( _StringKey);
      break;

   case 't' :
      if( ! strcmp( s, "rue"))
         return( _TrueKey);
      break;
   }

   MulleObjCThrowInvalidArgumentException( @"unknown XML key \"%s\", input is probably not a property list", string);
}


- (NSDateFormatter *) _XMLDateFormatter
{
   // ephemeral, only valid during one run
   if( ! _dateFormatter)
      _dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%dT%H:%M:%SZ"
                                               allowNaturalLanguage:NO] autorelease];  // proper handling later
   return( _dateFormatter);
}


//
// MulleObjCXMLParserDelegate. expat call backs, we iz lucky, coz the actual
// text is only in the leafs
//
- (void) parser:(MulleObjCXMLParser *) parser
  didStartElement:(NSString *) elementName
     attributes:(NSDictionary *) attributes
{
   NSString   *key;

   key = _keyForUTF8String( (char *) [elementName UTF8String]);
   pushKeyObj( self, key, nil);

   [self->_textStorage setString:nil]; // jettison trash
}


- (void) parser:(MulleObjCXMLParser *) parser
  foundCharacters:(NSString *) string
{
   assert( self->_textStorage);

   [self->_textStorage appendString:string];
}


- (void) parser:(MulleObjCXMLParser *) parser
    didEndElement:(NSString *) elementName
{
   NSString   *key;
   NSString   *match;
   NSString   *text;
   id          obj;
   id          child;
   NSData     *data;

   key  = _keyForUTF8String( (char *) [elementName UTF8String]);
   text = [self->_textStorage copy];
   [self->_textStorage setString:nil];

   match = popKeyObj( self, &child);
   obj   = nil;

   do
   {
      if( key == _KeyKey)
      {
         NSCParameterAssert( match == _KeyKey);
         obj = text;
         break;
      }

      if( key == _StringKey)
      {
         NSCParameterAssert( match == _StringKey);
         obj = text;
         break;
      }

      if( key == _IntegerKey)
      {
         NSCParameterAssert( match == _IntegerKey);
         obj = [[NSNumber alloc] initWithInteger:[text integerValue]];
         break;
      }

      if( key == _RealKey)
      {
         NSCParameterAssert( match == _RealKey);
         obj = [[NSNumber alloc] initWithDouble:[text doubleValue]];
         break;
      }

      if( key == _DateKey)
      {
         NSCParameterAssert( match == _DateKey);
         obj = [[[self _XMLDateFormatter] dateFromString:text] retain];
         break;
      }

      if( key == _DataKey)
      {
         NSCParameterAssert( match == _DataKey);

         data = [text dataUsingEncoding:NSUTF8StringEncoding];
         obj  = [data base64DecodedData];
//         obj  = [NSPropertyListSerialization propertyListFromData:data
//                                                 mutabilityOption:NSPropertyListImmutable
//                                                           format:NULL
//                                                 errorDescription:NULL];
         [obj retain];
         break;
      }

      if( key == _TrueKey)
      {
         NSCParameterAssert( match == _TrueKey);
         obj = [[NSNumber alloc] initWithBool:YES];
         break;
      }

      if( key == _FalseKey)
      {
         NSCParameterAssert( match == _FalseKey);
         obj = [[NSNumber alloc] initWithBool:NO];
         break;
      }

      if( key == _ArrayKey)
      {
         obj = [NSMutableArray new];
         for(;;)
         {
            if( match == _ArrayKey && ! child)
               break;

            [obj insertObject:child
                      atIndex:0];
            [child release];

            match = popKeyObj( self, &child);
         }
         break;
      }

      if( key == _DictionaryKey)
      {
         obj = [NSMutableDictionary new];
         for(;;)
         {
            if( match == _DictionaryKey && ! child)
               break;

            match = popKeyObj( self, &key);
            if( match != _KeyKey)
               MulleObjCThrowInvalidArgumentException( @"invalid %@", match);

            [obj setObject:child
                    forKey:key];
            [child release];
            [key release];

            match = popKeyObj( self, &child);
         }
         break;
      }

      if( key == _PlistKey)
      {
         match = popKeyObj( self, NULL); // pop off plist
         NSCParameterAssert( match == _PlistKey);

         obj = child;
         break;
      }

#if DEBUG
      abort();
#endif
   }
   while( 0);

   if( ! obj)
      MulleObjCThrowInvalidArgumentException( @"Plist unparsable at <%@ %@>", elementName, text);

   // if obj != text, it can be discarded
   if( obj != text)
      [text release];
   pushKeyObj( self, match, obj);
}


- (void) parser:(MulleObjCXMLParser *) parser
  parseErrorOccurred:(NSString *) error
{
   [_error autorelease];
   _error = [error retain];
}


- (id) parseXMLData:(NSData *) data
{
   MulleObjCXMLParser        *xmlParser;
   id                         plist;
   NSAutoreleasePool         *pool;
   NSException               *exception;
   struct mulle_allocator    *allocator;

   NSParameterAssert( [data length]); // should have been checked already

   pool = [NSAutoreleasePool new];
   {
      NSCParameterAssert( ! self->_textStorage);

      allocator = MulleObjCInstanceGetAllocator( self);

      _mulle_pointerpairarray_init( &self->_stack, 128, allocator);
      _textStorage = [NSMutableString string];
      _dateFormatter = nil;
      _error       = nil;
      exception    = nil;
      plist        = nil;

      xmlParser = [[MulleObjCXMLParser alloc] initWithDelegate:self];

   NS_DURING
      if( ! [xmlParser parseData:data])
         MulleObjCThrowInvalidArgumentException( @"%@", _error ? _error : @"XML parse failed");

      NSCParameterAssert( mulle_pointerpairarray_get_count( &self->_stack) == 1);
      {
         NSString   *key;

         key = popKeyObj( self, &plist);
         NSParameterAssert( key == _PlistKey);
         MULLE_C_UNUSED( key);
      }

   NS_HANDLER
      exception = localException;
   NS_ENDHANDLER
      [xmlParser release];

      emptyObjects( self);

      _mulle_pointerpairarray_done( &self->_stack);
      _textStorage = 0;
      [_error autorelease];
      _error = nil;
      [exception raise];
   }
   [pool release];

   return( [plist autorelease]);
}

@end
