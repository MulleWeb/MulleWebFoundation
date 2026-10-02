//
//  NSData+MulleZlib.m
//  MulleZlib
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
#import "NSData+MulleZlib.h"

#import "import-private.h"


@implementation NSData( MulleZlib)

- (NSData *) mulleZlibCompressedDataWithCompressionLevel:(int) level
{
   NSMutableData            *data;
   NSUInteger               size;
   struct mulle_allocator   *allocator;
   z_stream                 strm;
   int                      ret;

   /* allocate deflate state */
   memset( &strm, 0, sizeof( z_stream));

   /*
    * by "chance" zlib allocators are the same as mulle_allocators
    * we use mulle_allocators to catch leaks
    */
   allocator   = MulleObjCInstanceGetAllocator( self);
   strm.zalloc = (alloc_func) mulle_allocator_calloc;
   strm.zfree  = (free_func) mulle_allocator_free;
   strm.opaque = allocator;

   ret = deflateInit( &strm, level);
   if (ret != Z_OK)
   {
      // TODO: push NSError
      (void) deflateEnd( &strm);
      return( nil);
   }

   data = [NSMutableData object];
   size = 0;

   strm.avail_in = [self length];
   strm.next_in  = [self bytes];

   for(;;)
   {
      if( size >= strm.total_out)
      {
         [data increaseLengthBy:strm.total_out < 1024 ? 1024 : strm.total_out];
         size = [data length];
      }
      strm.next_out  = (Bytef *) [data mutableBytes] + strm.total_out;
      strm.avail_out = size - strm.total_out;
      ret = deflate(&strm, Z_FINISH);    /* no bad return value */
      switch( ret)
      {
      case Z_OK :
         break;

      case Z_BUF_ERROR :
         [data increaseLengthBy:strm.total_out < 1024 ? 1024 : strm.total_out];
         size = [data length];
         break;

      case Z_STREAM_END:
         [data setLength:strm.total_out];
         (void) deflateEnd( &strm);
         return( data);

      default:
         (void) deflateEnd( &strm);
         return( nil);
      }
   }
}


- (NSData *) mulleZlibCompressedData;
{
   return( [self mulleZlibCompressedDataWithCompressionLevel:6]);
}


- (NSData *) mulleZlibDecompressedData
{
   NSMutableData            *data;
   NSUInteger               size;
   struct mulle_allocator   *allocator;
   z_stream                 strm;
   int                      ret;

   /* allocate inflate state */
   memset( &strm, 0, sizeof( z_stream));

   /*
    * by "chance" zlib allocators are the same as mulle_allocators
    * we use mulle_allocators to catch leaks
    */
   allocator   = MulleObjCInstanceGetAllocator( self);
   strm.zalloc = (alloc_func) mulle_allocator_calloc;
   strm.zfree  = (free_func) mulle_allocator_free;
   strm.opaque = allocator;

   ret = inflateInit2( &strm, 15 + 32);
   if (ret != Z_OK)
   {
      // TODO: push NSError
      (void) inflateEnd( &strm);
      return( nil);
   }

   data = [NSMutableData object];
   size = 0;

   strm.avail_in = [self length];
   strm.next_in  = [self bytes];

   for(;;)
   {
      if( size >= strm.total_out)
      {
         [data increaseLengthBy:strm.total_out < 1024 ? 1024 : strm.total_out];
         size = [data length];
      }
      strm.next_out  = (Bytef *) [data mutableBytes] + strm.total_out;
      strm.avail_out = size - strm.total_out;
      ret = inflate( &strm, Z_BLOCK);    /* no bad return value */
      switch( ret)
      {
      case Z_OK :
         break;

      case Z_BUF_ERROR :
         [data increaseLengthBy:strm.total_out < 1024 ? 1024 : strm.total_out];
         size = [data length];
         break;

      case Z_STREAM_END:
         [data setLength:strm.total_out];
         (void) inflateEnd( &strm);
         return( data);

      default:
         (void) inflateEnd( &strm);
         return( nil);
      }
   }
}

@end
