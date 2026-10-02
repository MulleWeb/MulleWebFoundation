//
//  MulleJSMNParser.h
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
#import "import.h"


//
// Parser base on JSMN, this can do incremental parsing
// 
//TODO: rename to MulleObjCJSMNPlistParser

@interface MulleJSMNParser : NSObject
{
   void      *_parser;
   void      *_tok;
   size_t    _tokcount;
   int       _error;
   // space _parser will be saved in (if it fits)
   void     *_space[ 4];
}

@property( getter=isIncomplete) BOOL  incomplete;
@property BOOL  trueFalseAsStrings;

// userInfo and object properties will be cleared on -reset
@property( retain) id   userInfo;
@property( retain) id   object;

//
// you can call this incrementally.. if you get
// nil back, check for -isIncomplete, if yes you can *append* stuff to
// the NSData and try again. The already parsed part of the NSData will
// not be parsed again.
// Otherwise you get the parsed object back. It will also be available
// via -object until the next parseData completes.

- (id) parseData:(NSData *) data;

//
// This is the same as above, but you don't wrap it in an NSData
// if you use it incrementally DONT send -parseBytes:"[" length:1
// and then -parseBytes:"]" length:1
// send parseBytes:"[" length:1 and then parseBytes:"[]" length:2
//
- (id) parseBytes:(void *) bytes
           length:(NSUInteger) length;

- (void) reset;

// internal error report generator
- (NSError *) errorWithName:(NSString *) name
                      bytes:(void *) bytes
                     length:(NSUInteger) length
                      range:(NSRange) range;
@end


@interface NSString( MulleJSMNParser)

- (id) mulleJSON;

@end



