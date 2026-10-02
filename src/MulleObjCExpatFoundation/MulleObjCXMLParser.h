//
//  MulleObjCXMLParser.h
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
#import "import.h"

@class MulleObjCXMLParser;


//
// A SAX-style parser delegate. The parser is generic: it knows nothing about
// the document it reads, it only reports elements, attributes and character
// data. This is what a feed (RSS/Atom), an HTML or an arbitrary XML consumer
// builds on. `MulleObjCExpatParser` (the property list parser) is one such
// consumer.
//
// All methods are optional.
//
@protocol MulleObjCXMLParserDelegate <NSObject>

@optional

- (void) parser:(MulleObjCXMLParser *) parser
  didStartElement:(NSString *) elementName
     attributes:(NSDictionary *) attributes;

- (void) parser:(MulleObjCXMLParser *) parser
  foundCharacters:(NSString *) string;

- (void) parser:(MulleObjCXMLParser *) parser
    didEndElement:(NSString *) elementName;

- (void) parser:(MulleObjCXMLParser *) parser
  parseErrorOccurred:(NSString *) error;

@end


//
// A generic, incremental XML parser (expat underneath). Feed it a whole
// document with -parseData: or stream it in chunks with
// -parseBytes:length:isFinal:. The delegate is not retained.
//
@interface MulleObjCXMLParser : NSObject
{
   id       _delegate;      // assign, not retained
   void    *_parser;        // XML_Parser (opaque here)
   BOOL     _didAbort;
}

@property( assign) id <MulleObjCXMLParserDelegate> delegate;

+ (instancetype) parserWithDelegate:(id <MulleObjCXMLParserDelegate>) delegate;
- (instancetype) initWithDelegate:(id <MulleObjCXMLParserDelegate>) delegate;

// Returns YES on success. On failure the delegate is told via
// -parser:parseErrorOccurred: and NO is returned.
- (BOOL) parseData:(NSData *) data;
- (BOOL) parseBytes:(void *) bytes
             length:(NSUInteger) length
            isFinal:(BOOL) isFinal;

- (void) abortParsing;

@end
