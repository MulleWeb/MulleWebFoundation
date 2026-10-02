//
//  MulleObjCXMLParser.m
//  MulleObjCExpatFoundation
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
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
#import "MulleObjCXMLParser.h"

#import "import-private.h"

// other files in this library

// std-c and dependencies
#include <expat.h>


// expat delivers element and attribute names as UTF-8, NUL-terminated C
// strings. Attribute names and values come as a NULL-terminated array of
// name/value pairs.

static void   start_element( void *userData, const XML_Char *name, const XML_Char **atts)
{
   MulleObjCXMLParser               *self;
   id <MulleObjCXMLParserDelegate>   delegate;
   NSMutableDictionary              *attributes;
   NSString                         *key;
   NSString                         *value;
   NSUInteger                        i;

   self     = (MulleObjCXMLParser *) userData;
   delegate = [self delegate];

   if( ! [delegate respondsToSelector:@selector( parser:didStartElement:attributes:)])
      return;

   attributes = nil;
   if( atts)
   {
      attributes = [NSMutableDictionary dictionary];
      for( i = 0; atts[ i] && atts[ i + 1]; i += 2)
      {
         key   = [NSString stringWithUTF8String:(char *) atts[ i]];
         value = [NSString stringWithUTF8String:(char *) atts[ i + 1]];
         if( key && value)
            [attributes setObject:value
                           forKey:key];
      }
   }

   [delegate parser:self
     didStartElement:[NSString stringWithUTF8String:(char *) name]
        attributes:attributes];
}


static void   character_data( void *userData, const XML_Char *s, int len)
{
   MulleObjCXMLParser               *self;
   id <MulleObjCXMLParserDelegate>   delegate;
   NSString                         *string;

   self     = (MulleObjCXMLParser *) userData;
   delegate = [self delegate];

   if( ! [delegate respondsToSelector:@selector( parser:foundCharacters:)])
      return;

   string = [[[NSString alloc] mulleInitWithUTF8Characters:(void *) s
                                                    length:(NSUInteger) len] autorelease];
   [delegate parser:self
     foundCharacters:string];
}


static void   end_element( void *userData, const XML_Char *name)
{
   MulleObjCXMLParser               *self;
   id <MulleObjCXMLParserDelegate>   delegate;

   self     = (MulleObjCXMLParser *) userData;
   delegate = [self delegate];

   if( ! [delegate respondsToSelector:@selector( parser:didEndElement:)])
      return;

   [delegate parser:self
       didEndElement:[NSString stringWithUTF8String:(char *) name]];
}


@implementation MulleObjCXMLParser

- (instancetype) initWithDelegate:(id <MulleObjCXMLParserDelegate>) delegate
{
   self = [super init];
   if( ! self)
      return( nil);

   _delegate = delegate;
   _parser   = XML_ParserCreate( NULL);
   if( ! _parser)
   {
      [self release];
      return( nil);
   }

   XML_SetUserData( _parser, self);
   XML_SetStartElementHandler( _parser, start_element);
   XML_SetEndElementHandler( _parser, end_element);
   XML_SetCharacterDataHandler( _parser, character_data);

   return( self);
}


+ (instancetype) parserWithDelegate:(id <MulleObjCXMLParserDelegate>) delegate
{
   return( [[[self alloc] initWithDelegate:delegate] autorelease]);
}


- (void) dealloc
{
   if( _parser)
      XML_ParserFree( _parser);

   [super dealloc];
}


- (void) setDelegate:(id <MulleObjCXMLParserDelegate>) delegate
{
   _delegate = delegate;
}


- (id <MulleObjCXMLParserDelegate>) delegate
{
   return( _delegate);
}


- (NSString *) _errorDescription
{
   enum XML_Error   code;
   XML_LChar       *error;
   XML_Size         line;
   XML_Size         column;

   code   = XML_GetErrorCode( _parser);
   error  = (XML_LChar *) XML_ErrorString( code);
   line   = XML_GetCurrentLineNumber( _parser);
   column = XML_GetCurrentColumnNumber( _parser);

   return( [NSString stringWithFormat:@"XML error at line %ld, column %ld: %s",
                     (long) line,
                     (long) column,
                     error ? (char *) error : "unknown"]);
}


- (BOOL) parseBytes:(void *) bytes
             length:(NSUInteger) length
            isFinal:(BOOL) isFinal
{
   int   rval;

   if( ! _parser)
      return( NO);

   rval = XML_Parse( _parser, (char *) bytes, (int) length, (int) isFinal);
   if( ! rval)
   {
      if( ! _didAbort
          && [self->_delegate respondsToSelector:@selector( parser:parseErrorOccurred:)])
         [self->_delegate parser:self
              parseErrorOccurred:[self _errorDescription]];
      return( NO);
   }

   return( YES);
}


- (BOOL) parseData:(NSData *) data
{
   char     *bytes;
   size_t    length;

   bytes  = [data bytes];
   length = [data length];

   // tolerate a trailing NUL (a C string handed in as NSData)
   while( length && ! bytes[ length - 1])
      --length;

   return( [self parseBytes:bytes
                     length:length
                    isFinal:YES]);
}


- (void) abortParsing
{
   _didAbort = YES;
   if( _parser)
      XML_StopParser( _parser, XML_FALSE);
}

@end
