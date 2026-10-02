//
//  MulleObjCPropertyListPrinting+XML.m
//  MulleObjCExpatFoundation
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  Copyright (c) 2021 Codeon GmbH.
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
#import "MulleObjCPropertyListPrinting+XML.h"

#import "import-private.h"

// private classes of MulleObjCValueFoundation
#import <MulleObjCValueFoundation/_MulleObjCConcreteNumber.h>
#import <MulleObjCValueFoundation/_MulleObjCValueTaggedPointer.h>
#import <MulleObjCValueFoundation/_MulleObjCTaggedPointerIntegerNumber.h>
#import <MulleObjCValueFoundation/NSNumber-Private.h>


@implementation NSObject( MulleObjCPropertyListPrinting_XML)

- (void) mullePrintXMLToStream:(id <MulleObjCOutputStream>) handle;
{
   struct MulleObjCPrintPlistContext  ctxt;

   MulleObjCPrintPlistContextInit( &ctxt, handle);
   ctxt.dateFormatter  = [[[NSDateFormatter alloc] initWithDateFormat:MulleDateFormatISO
                                                 allowNaturalLanguage:NO] autorelease];
   [ctxt.dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
   ctxt.sortsDictionary = NO;

   MulleObjCPrintPlistContextWriteUTF8String( &ctxt,
   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
   "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "
      "\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
   "<plist version=\"1.0\">\n");

   [self mullePrintXML:&ctxt];
   MulleObjCPrintPlistContextWriteUTF8String( &ctxt, "</plist>\n");
}


- (NSString *) mulleXMLDescription
{
   NSMutableData  *data;
   NSString       *s;

   data = [NSMutableData data];
   [self mullePrintXMLToStream:data];

   s = [[[NSString alloc] initWithData:data
                              encoding:NSUTF8StringEncoding] autorelease];
   return( s);
}

@end


@implementation NSDictionary( MulleObjCPropertyListPrinting_XML)

- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt
{
   NSUInteger   n;
   id           value;
   id           key;
   id           keySource;

   n = [self count];
   if( ! n)
   {
      MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<dict/>\n");
      return;
   }

   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<dict>\n");
   ctxt->indent++;
   keySource = self;
   if( ctxt->sortsDictionary)
      keySource = [[self allKeys] sortedArrayUsingSelector:@selector( compare:)];

   for( key in keySource)
   {
      value = [self objectForKey:key];
      MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<key>");
      [[key description] mullePrintXMLToStream:ctxt->handle];
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "</key>\n");
      [value mullePrintXML:ctxt];
   }
   ctxt->indent--;

   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "</dict>\n");
}

@end


@implementation NSArray( MulleObjCPropertyListPrinting_XML)

- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt
{
   NSUInteger   n;
   id           value;

   n = [self count];
   if( ! n)
   {
      MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<array/>\n");
      return;
   }

   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<array>\n");
   ctxt->indent++;
   for( value in self)
   {
      [value mullePrintXML:ctxt];
   }
   ctxt->indent--;

   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "</array>\n");
}

@end



@implementation NSString( MulleObjCPropertyListPrinting_XML)


char   *MulleXMLEscapeUTF8Character( char c, char buf[ 6])
{
   char   *s;

   s = buf;
   switch( c)
   {
   case '\r' :
   case '\n' :
   case '\t' : *s++ = c; break;

   case 0x7F : *s++ = '&'; *s++ = '#'; *s++ = '1'; *s++ = '2'; *s++ = '7'; *s++ = ';';  break;
   case '<'  : *s++ = '&'; *s++ = 'l'; *s++ = 't'; *s++ = ';'; break;
   case '>'  : *s++ = '&'; *s++ = 'g'; *s++ = 't'; *s++ = ';'; break;
   case '&'  : *s++ = '&'; *s++ = 'a'; *s++ = 'm'; *s++ = 'p'; *s++ = ';'; break;
   case '\'' : *s++ = '&'; *s++ = 'a'; *s++ = 'p'; *s++ = 'o'; *s++ = 's'; *s++ = ';';  break;
   case '\"' : *s++ = '&'; *s++ = 'q'; *s++ = 'u'; *s++ = 'o'; *s++ = 't'; *s++ = ';'; break;
#ifdef ESCAPED_ZERO_IN_UTF8_STRING_IS_A_GOOD_THING
   case 0    : *s++ = '&'; *s++ = '&'; *s++ = '#'; *s++ = '0'; *s++ = ';'; break;
#endif
   default   :
               if( (unsigned char) c < 0x20)
               {
                  *s++ = '&';
                  *s++ = '#';
                  *s++ = '0' + (c / 10);
                  *s++ = '0' + (c % 10);
                  *s++ = ';';
               }
               else
                  *s++ = c;
               break;
   }
   return( s);
}

//
// always in double quotes, different kind of escapes
//
- (void) mullePrintXMLToStream:(id <MulleObjCOutputStream>) handle
{
   char                     *s;
   char                     *q, *sentinel;
   size_t                   len;
   struct mulle_utf8data    data;
   char                     tmp1[ 16];
   char                     tmp2[ 16 * 6];
   IMP                      imp;

   // tmp1 maybe used, maybe not used. data contains always everything
   data = MulleStringUTF8Data( self, mulle_utf8data_make( tmp1,
                                                             sizeof( tmp1)));

   // do proper quoting and escaping
   len      = data.length;
   q        = data.characters;
   sentinel = &q[ len];

   //
   // as we are writing to a handle, it makes not that much sense to
   // store everything so we cache 16 escaped characters and then write them
   // out
   //
   imp = [(id) handle methodForSelector:@selector( mulleWriteBytes:length:)];
   s   = tmp2;
   while( q < sentinel)
   {
      s = MulleXMLEscapeUTF8Character( *q++, s);
      if( s > &tmp2[ 15 * 6])
      {
         MulleObjCIMPCall2( imp,
                            handle,
                            @selector( mulleWriteBytes:length:),
                            (id) tmp2,
                            (id) (s - tmp2));
         s = tmp2;
      }
   }
   MulleObjCIMPCall2( imp,
                      handle,
                      @selector( mulleWriteBytes:length:),
                      (id) tmp2,
                      (id) (s - tmp2));
}


- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt
{
   if( ! [self length])
   {
      MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<string/>\n");
      return;
   }

   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<string>");
   [self mullePrintXMLToStream:ctxt->handle];
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "</string>\n");
}

@end



@implementation NSNull( MulleObjCPropertyListPrinting_XML)

- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt
{
   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<null/>\n"); // ???
}

@end


@implementation NSNumber( MulleObjCPropertyListPrinting_XML)

- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt
{
   char   *type;

   type = [self objCType];
   switch( *type)
   {
   case _C_FLT :
   case _C_DBL :
#ifdef _C_LNG_DBL
   case _C_LNG_DBL :
#endif
      MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<real>");
      [self mullePrintPlist:ctxt];
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "</real>\n");
      return;
   }

   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<integer>");
   [self mullePrintPlist:ctxt];
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "</integer>\n");
}

@end


@implementation _MulleObjCBoolNumber( MulleObjCPropertyListPrinting_XML)

- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt
{
   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   if( [self boolValue])
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<true/>\n");
   else
      MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<false/>\n");
}

@end


@implementation NSDate( MulleObjCPropertyListPrinting_XML)

- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt
{
   NSString   *s;

   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<date>");
   s = [ctxt->dateFormatter stringForObjectValue:self];
   [s mulleWriteToStream:ctxt->handle
           usingEncoding:NSUTF8StringEncoding];
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "</date>\n");
}

@end


@implementation NSData( MulleObjCPropertyListPrinting_XML)

- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt
{
   NSData   *data;

   MulleObjCPrintPlistContextWriteUTF8Indentation( ctxt);
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "<data>");
   data = [self base64EncodedData];
   [ctxt->handle writeData:data];
   MulleObjCPrintPlistContextWriteUTF8String( ctxt, "</data>\n");
}

@end

