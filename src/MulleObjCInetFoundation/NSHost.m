//
//  NSHost.m
//  MulleObjCInetFoundation
//
//  Copyright (c) 2017 Nat! - Mulle kybernetiK.
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
#import "NSHost.h"

//
// provided by c-ares or gethostbyname
//
@interface NSHost (ExternalResolver)

- (void) _resolveAddress:(NSString *) address;
- (void) _resolveName:(NSString *) name;

- (void) _didResolveName:(NSString *) name;
- (void) _didResolveHostAddress:(NSString *) address;

@end


@implementation NSString( NSHost)

- (NSComparisonResult) _compareHostName:(NSString *) name
{
   return( [self compare:name]);
}


- (NSComparisonResult) _compareHostAddress:(NSString *) address
{
   return( [self compare:address]);
}

@end


@implementation NSHost

@synthesize names     = _names;
@synthesize addresses = _addresses;

- (id) initWithNames:(NSString **) names
               count:(NSUInteger) count
           addresses:(NSString **) addresses
               count:(NSUInteger) nAddresses
{
   NSMutableArray   *array;

   array = [[[NSMutableArray alloc] initWithObjects:names
                                              count:count] autorelease];
   [array sortUsingSelector:@selector( _compareHostName:)];
   _names = [array copy];

   array = [[[NSMutableArray alloc] initWithObjects:addresses
                                              count:nAddresses] autorelease];
   [array sortUsingSelector:@selector( _compareHostAddress:)];
   _addresses = [array copy];

   _lock  = [NSLock new];

   return( self);
}


- (id) initWithNames:(NSString **) names
               count:(NSUInteger) count
{
   return( [self initWithNames:names
                         count:count
                     addresses:NULL
                         count:0]);
}


- (id) initWithAddresses:(NSString **) addresses
                   count:(NSUInteger) count
{
   return( [self initWithNames:NULL
                         count:0
                     addresses:addresses
                         count:count]);
}

- (void) dealloc
{
   // properties will not be gone during finalize
   [_addresses release];
   [_names release];
   [_lock release];
   [super dealloc];
}


+ (instancetype) hostWithName:(NSString *) name
{
   NSParameterAssert( [name isKindOfClass:[NSString class]]);

   if( ! [name length])
      return( nil);

   return( [[[NSHost alloc] initWithNames:&name
                                    count:1] autorelease]);
}


+ (instancetype) hostWithAddress:(NSString *) address
{
   NSParameterAssert( [address isKindOfClass:[NSString class]]);

   if( ! [address length])
      return( nil);

   return( [[[NSHost alloc] initWithAddresses:&address
                                        count:1] autorelease]);
}


- (void) _resolveIfNeeded
{
   if( ! [_names count])
   {
      [self _resolveAddress:[self address]];
      return;
   }

   if( ! [_addresses count])
   {
      [self _resolveName:[self name]];
      return;
   }
}


- (BOOL) isEqualToHost:(NSHost *) other
{
   NSString  *address;
   NSArray   *otherAddresses;

   [self _resolveIfNeeded];
   [other _resolveIfNeeded];

   otherAddresses = [other addresses];
   for( address in [self addresses])
      if( [otherAddresses containsObject:address])
         return( YES);

   return( NO);
}


- (NSArray *) names
{
   NSArray  *names;

   names = _names;
   if( names)
   {
      [_lock lock];
      names = [[_names retain] autorelease];
      [_lock unlock];
   }
   return( names);
}


- (BOOL) _exchangeNames:(NSArray *) old
              withNames:(NSArray *) names
{
   BOOL   flag;

   flag = YES;
   if( old != names)
   {
      [_lock lock];
      {
         flag = _names == old;
         if( flag)
         {
            [_names autorelease];
            _names = names;
         }
      }
      [_lock unlock];
   }
   return( flag);
}


- (NSArray *) addresses
{
   NSArray  *addresses;

   addresses = _addresses;
   if( addresses)
   {
      [_lock lock];
      {
         addresses = [[_addresses retain] autorelease];
      }
      [_lock unlock];
   }
   return( addresses);
}


- (BOOL) _exchangeAddresses:(NSArray *) old
              withAddresses:(NSArray *) addresses
{
   BOOL   flag;

   flag = YES;
   if( old != addresses)
   {
      [_lock lock];
      {
         flag = _addresses == old;
         if( flag)
         {
            [_addresses autorelease];
            _addresses = addresses;
         }
      }
      [_lock unlock];
   }
   return( flag);
}


- (NSString *) name
{
   [self _resolveIfNeeded];

   return( [[self names] lastObject]);
}


- (NSString *) address
{
   [self _resolveIfNeeded];

   return( [[self addresses] lastObject]);
}

//
// these routines check, that competing threads don't "drop" other adds
//
- (void) _addName:(NSString *) name
{
   NSMutableArray   *array;
   NSArray          *names;

   if( [_names containsObject:name])
      return;

   do
   {
      names = [self names];
      array = [[[NSMutableArray alloc] initWithArray:names] autorelease];
      [array sortUsingSelector:@selector( _compareHostName:)];
   }
   while( ! [self _exchangeNames:names
                       withNames:array]);
}


- (void) _addAddress:(NSString *) address
{
   NSMutableArray   *array;
   NSArray          *addresses;

   if( [_names containsObject:address])
      return;

   do
   {
      addresses = [self addresses];
      array = [[[NSMutableArray alloc] initWithArray:addresses] autorelease];
      [array sortUsingSelector:@selector( _compareHostAddress:)];
   }
   while( ! [self _exchangeAddresses:addresses
                       withAddresses:array]);
}


+ (instancetype) currentHost
{
   NSString   *names[ 1];
   NSString   *addresses[ 2];

   names[ 0]     = @"localhost";
   addresses[ 0] = @"127.0.0.1";
   addresses[ 1] = @"::1";
   return( [[[NSHost alloc] initWithNames:names
                                    count:1
                                addresses:addresses
                                    count:2] autorelease]);
}

@end


