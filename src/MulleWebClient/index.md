# MulleWebClient Library Documentation for AI
<!-- Keywords: HTTP, client, curl, JSON, network, web, parser -->
## 1. Introduction & Purpose

**MulleWebClient** is a small, experimental Web client library for the
MulleFoundation / mulle-objc ecosystem. It builds directly on top of
`MulleCurl` and provides a collection of Objective-C **categories** that
extend `MulleCurl` (the underlying HTTP engine) with convenient, high-level
methods for common web tasks:

- Fetching URL contents as `NSData` (raw bytes) or as parsed object graphs.
- Fetching and emitting JSON (`id` / property-list style objects).
- Incrementally parsing HTTP response bodies via a pluggable parser
  (`MulleCurlParser` protocol), notably JSON via `MulleJSMNParser` and HTTP
  headers via `MulleHTTPHeaderParser`.
- Simple HTTP requests with minimal boilerplate (GET and POST-by-`NSData`).

It does **not** define its own classes; instead it attaches categories to
classes owned by dependency libraries (primarily `MulleCurl`). This project's
contribution is the concrete glue between curl and the parser classes.

## 2. Key Concepts & Design Philosophy

- **Convenience layer over MulleCurl:** The public API is a set of Objective-C
  categories (`MulleCurl( NSURL)`, `MulleCurl( JSON)`) that wrap the lower-level
  `MulleCurl` methods.
- **Parser plug-in concept:** `MulleCurl` can be handed a parser conforming to
  the `MulleCurlParser` protocol. This library supplies two such adapters that
  retrofit existing parser classes (`MulleJSMNParser`, `MulleHTTPHeaderParser`)
  into that protocol via categories.
- **Incremental parsing:** Parsing happens as chunks of the response body
  arrive (`-curl:parseBytes:length:` is fed incrementally), which is designed to
  have lower latency than downloading the whole body and parsing afterwards,
  especially for large contents.
- **Error reporting via `NSError`:** Methods return `nil` on failure; the error
  is extracted with `[NSError mulleExtract]` (per the comments in
  `MulleCurl+JSON.h`).
- **Shared-instance idiom:** The `+object` factory (mulle-objc) returns a shared
  autoreleased instance, so every one-line convenience method can create no
  management overhead.
- **Raw-vs-parsed split:** Get raw `NSData` with `dataWithContentsOf...`,
  or hand the job to a parser with `parseContentsOf...`.

## 3. Core API & Data Structures

All symbols below are copied verbatim from the public headers.

### 3.1. `MulleWebClient.h` (umbrella header)

The public umbrella header. It defines the version macro and functions and then
imports all four category headers:

- `MulleHTTPHeaderParser+MulleCurlParser.h`
- `MulleJSMNParser+MulleCurlParser.h`
- `MulleCurl+NSURL.h`
- `MulleCurl+JSON.h`

#### Version

```c
#define MULLE_WEB_CLIENT_VERSION  ((0UL << 20) | (1 << 8) | 0)
```

```c
static inline unsigned int   MulleWebClient_get_version_major( void)
```

```c
static inline unsigned int   MulleWebClient_get_version_minor( void)
```

```c
static inline unsigned int   MulleWebClient_get_version_patch( void)
```

```c
extern uint32_t   MulleWebClient_get_version( void);
```

- **Purpose:** Version identification for the library. The static inline
  functions split `MULLE_WEB_CLIENT_VERSION` into `major`, `minor`, `patch`;
  `MulleWebClient_get_version()` returns the full 32-bit version integer.

### 3.2. `MulleCurl+NSURL.h` — `MulleCurl( NSURL)` category

Adds URL-centric convenience by wrapping the `...WithString:` variants of
`MulleCurl` (which takes `NSString` URLs) around `NSURL`.

#### Class methods

```objc
+ (NSData *) dataWithContentsOfURL:(NSURL *) url;
```
- **Purpose:** GET the URL and return the raw response body as `NSData`.
  Returns `nil` on error. Uses a shared `MulleCurl` instance.

```objc
+ (id) propertyListWithJSONContentsOfURL:(NSURL *) url;
```
- **Purpose:** GET the URL and parse the JSON response body directly into an
  object-graph property list (usually an `NSDictionary`). Implemented by
  installing a `MulleJSMNParser` on a shared `MulleCurl` and calling
  `-parseContentsOfURL:`. Returns `nil` on error.

#### Instance methods

```objc
- (NSData *) dataWithContentsOfURL:(NSURL *) url;
```
- **Purpose:** GET the URL, return raw response body as `NSData`.

```objc
- (NSData *) dataWithContentsOfURL:(NSURL *) url
                     byPostingData:(NSData *) data;
```
- **Purpose:** POST `data` as the request body and return the raw response
  body as `NSData`. **Important:** The data is sent "As Is"; the caller must
  set the correct `Content-Type` request header beforehand (see
  `-setRequestHeaders:` on `MulleCurl`).

```objc
- (id) parseContentsOfURL:(NSURL *) url;
```
- **Purpose:** GET the URL and run the response body through the installed
  parser (see `-setParser:` on `MulleCurl`, e.g. a `MulleJSMNParser`), returning
  the parsed result. Returns `nil` on error.

```objc
- (id) parseContentsOfURL:(NSURL *) url
            byPostingData:(NSData *) data;
```
- **Purpose:** POST `data` as the request body and run the response body
  through the installed parser, returning the parsed result.

### 3.3. `MulleCurl+JSON.h` — `MulleCurl( JSON)` category

Convenience for raw JSON interactions. These install a `MulleJSMNParser` on a
shared `MulleCurl`, set the `MulleHTTPContentTypeKey` request header to
`@"application/json"`, then parse.

```objc
// returns nil if something fails, check NSError for clues
// [NSError mulleCurrentError]
+ (id) JSONContentsOfURL:(NSURL *) url;
```
- **Purpose:** GET the URL and parse the JSON response into an object-graph
  property list.

```objc
+ (id) JSONContentsOfURLWithString:(NSString *) urlString;
```
- **Purpose:** Same as `JSONContentsOfURL:` but takes a URL as an `NSString`.
  This is the base implementation; `JSONContentsOfURL:` forwards to it via
  `[url stringValue]`.

### 3.4. `MulleHTTPHeaderParser+MulleCurlParser.h` — `MulleHTTPHeaderParser( MulleCurlParser)`

```objc
@protocol MulleCurlParser;

@interface MulleHTTPHeaderParser( MulleCurlParser) <MulleCurlParser>
@end
```

- **Purpose:** Retrofit `MulleHTTPHeaderParser` (from `MulleObjCHTTPFoundation`)
  to conform to `MulleCurl`'s `MulleCurlParser` protocol, so it can be installed
  via `-setHeaderParser:` / `-setParser:` on `MulleCurl`. It accumulates the
  header chunk via a private `_data` buffer and re-parses; the parsed result
  (the headers) is returned by `-parsedObjectWithCurl:`. Note that per its
  implementation, headers that cannot be parsed yield `nil` entries rather than
  aborting the transfer.

### 3.5. `MulleJSMNParser+MulleCurlParser.h` — `MulleJSMNParser( MulleCurlParser)`

```objc
@interface MulleJSMNParser( MulleCurlParser) < MulleCurlParser>
@end
```

- **Purpose:** Retrofit `MulleJSMNParser` (from `MulleObjCJSMNFoundation`) to
  conform to `MulleCurlParser`. Each incoming chunk is appended to an
  `NSMutableData` accumulator stored in the curl's `userInfo`, then fed to
  `-parseData:`; the fully parsed object graph is returned by
  `-parsedObjectWithCurl:` via `-object`.

### 3.6. `MulleObjCDeps+MulleWebClient.h` — `MulleObjCDeps( MulleWebClient)`

```objc
@class MulleObjCDeps;

@interface MulleObjCDeps( MulleWebClient)

+ (struct _mulle_objc_dependency *) dependencies;

@end
```

- **Purpose:** ObjC dependency-declaration hook used by the mulle-objc runtime
  to register this library's categories with the loading machinery. The method
  returns a static array generated from `objc-deps.inc`. This header must be
  public so that libraries depending on `MulleWebClient` can declare their load
  in their own load/class-registration code. Guarded by `__MULLE_OBJC__`.

## 4. Performance Characteristics

- **Synchronous, blocking:** Every method performs a blocking network request
  and returns only when the response has been received.
- **Incremental parsing:** With a parser installed, chunks are parsed as they
  arrive rather than after the full body download, which reduces time-to-result
  for large payloads (the parser is the stated design motivation in
  `MulleCurl+NSURL.h`).
- **Memory:** The full raw body is accumulated in an `NSData` when no parser is
  used; parser-based paths accumulate in an internal `NSMutableData` buffer plus
  the parser's internal state. Peak memory is on the order of the response size.
- **Thread-safety:** The shared facets are not guaranteed thread-safe. The
  class-level convenience methods use the shared `+object` instance, so they
  should not be called concurrently from multiple threads. For concurrent or
  parallel requests, create a dedicated instance per thread/request.
- Network latency dominates; there is no in-process caching.

## 5. AI Usage Recommendations & Patterns

- **Best Practices:**
  - Use the factory/`+object` idiom (mulle-objc) rather than manual
    `alloc`/`init`. The tests show `[MulleCurl object]`, `[MulleCurl instance]`,
    and `[MulleJSMNParser object]`. If you must create a fresh `MulleCurl`,
    use `[[MulleCurl new] autorelease]`.
  - Install the parser before requesting a parse: `[curl setParser:parser]`
    then `[curl parseContentsOfURLWithString:URL]`.
  - Always check the return value; on `nil`, do `[NSError mulleExtract]` to get
    the error object (per header comment, `[NSError mulleCurrentError]`).
  - Use `[curl setDesktopTimeoutOptions]` to apply sensible desktop timeouts,
    as every test does.
  - For HTTPS against non-production hosts, tests disable cert verification via
    `setOptions:` with `CURLOPT_SSL_VERIFYPEER` / `CURLOPT_SSL_VERIFYHOST`
    set to `@(NO)`.
  - When posting data, the bytes go out "As Is" — set the correct content type
    explicitly via `[curl setRequestHeaders:...]` (the JSON category sets
    `MulleHTTPContentTypeKey` to `@"application/json"` itself).

- **Common Pitfalls:**
  - Do **not** call `[MulleWebClient ...]` — there is no class named
    `MulleWebClient` and no documented convenience methods hanging off it. All
    convenience APIs live on `MulleCurl` categories (see section 3).
  - Class-level convenience methods (e.g. `+JSONContentsOfURL:`,
    `+dataWithContentsOfURL:`) use a shared instance; do not use them
    concurrently from multiple threads.
  - `+propertyListWithJSONContentsOfURL:` / `+JSONContentsOfURL:` return `id`;
    the concrete runtime type is whatever the JSON parses to (commonly
    `NSDictionary`, `NSArray`, `NSString`, `NSNumber`) — check
    `[result isKindOfClass:]` before assuming.
  - Methods like `dataWithContentsOfURLWithString:`,
    `parseContentsOfURLWithString:`, `-setParser:`, `-setHeaderParser:`,
    `-setRequestHeaders:`, `-setOptions:`, `-setDesktopTimeoutOptions:`,
    `-userInfo`/`-setUserInfo:` are part of the **MulleCurl** dependency API,
    not defined by this library.
  - The parser adapter methods (`-curl:parseBytes:length:`,
    `-parsedObjectWithCurl:`) communicate with `MulleCurl`; do not call them
    directly — install the parser and use the public fetch/parse methods.

## 6. Integration Examples

The examples below follow the library coding style: 3-space indent, Allman
braces, aligned declarations, one variable per line, `return( expr);`, no
dot-syntax. They import the public umbrella header.

### Example 1: Simple JSON GET (one-liner)

```objc
#import <MulleWebClient/MulleWebClient.h>
#include <stdio.h>

int   main( int argc, const char * argv[])
{
   id          result;
   NSError     *error;

   result = [MulleCurl JSONContentsOfURLWithString:@"https://api.github.com/users/mulle-nat/orgs"];
   if( ! result)
   {
      error = [NSError mulleExtract];
      fprintf( stderr, "Error: %s\n", [[error description] UTF8String]);
      return( 1);
   }

   printf( "%s\n", [[result description] UTF8String]);
   return( 0);
}
```

### Example 2: Raw GET with a dedicated instance

```objc
#import <MulleWebClient/MulleWebClient.h>
#include <stdio.h>

static NSString   *URL = @"http://www.mulle-kybernetik.com/jagdox/dehtmlify.sh";

int   main( int argc, const char * argv[])
{
   MulleCurl   *curl;
   NSData      *data;
   NSError     *error;

   curl = [[MulleCurl new] autorelease];
   [curl setDesktopTimeoutOptions];

   data = [curl dataWithContentsOfURLWithString:URL];
   if( ! data)
   {
      error = [NSError mulleExtract];
      fprintf( stderr, "%s\n", [[error description] UTF8String]);
      return( 1);
   }

   printf( "%.*s", (int) [data length], (char *) [data bytes]);
   return( 0);
}
```

### Example 3: Incremental JSON parsing with request headers

```objc
#import <MulleWebClient/MulleWebClient.h>
#include <stdio.h>

static NSString   *URL = @"https://api.github.com/users/mulle-nat/orgs";

int   main( int argc, const char * argv[])
{
   MulleCurl         *curl;
   MulleJSMNParser   *parser;
   id                plist;
   NSError           *error;

   curl   = [MulleCurl object];
   parser = [MulleJSMNParser object];
   [curl setParser:parser];

   [curl setRequestHeaders:@{
                              @"Accept" : @"application/vnd.github.v3+json",
                              @"User-Agent": @"Awesome-Octocat-App"
                            }];
   plist = [curl parseContentsOfURLWithString:URL];
   if( ! plist)
   {
      error = [NSError mulleExtract];
      fprintf( stderr, "Error: %s\n", [[error description] UTF8String]);
      return( 1);
   }

   printf( "%s\n", [[plist description] UTF8String]);
   return( 0);
}
```

### Example 4: HTTP header parsing

```objc
#import <MulleWebClient/MulleWebClient.h>
#include <stdio.h>

static NSString   *URL = @"http://www.mulle-kybernetik.com/jagdox/dehtmlify.sh";

int   main( int argc, const char * argv[])
{
   MulleCurl               *curl;
   MulleHTTPHeaderParser   *headerParser;
   NSData                  *data;
   NSDictionary            *headers;
   NSError                 *error;

   curl         = [MulleCurl instance];
   headerParser = [MulleHTTPHeaderParser instance];
   [headerParser setRecordsOrder:YES];
   [curl setDesktopTimeoutOptions];
   [curl setHeaderParser:headerParser];

   data = [curl dataWithContentsOfURLWithString:URL];
   if( ! data)
   {
      error = [NSError mulleExtract];
      fprintf( stderr, "%s\n", [[error description] UTF8String]);
      return( 1);
   }

   headers = [headerParser headers];
   printf( "%td headers, %td bytes in body\n", [headers count], [data length]);
   return( 0);
}
```

### Example 5: POST data and parse the JSON reply

```objc
#import <MulleWebClient/MulleWebClient.h>

int   main( int argc, const char * argv[])
{
   MulleCurl      *curl;
   NSData         *postData;
   id             reply;
   NSError        *error;

   curl     = [MulleCurl object];
   postData = [@"{\"name\":\"Alice\"}" dataUsingEncoding:NSUTF8StringEncoding];

   // The POST body is sent "As Is" -> set the Content-Type explicitly.
   [curl setRequestHeaders:@{
                              MulleHTTPContentTypeKey : @"application/json"
                            }];
   [curl setParser:[MulleJSMNParser object]];

   reply = [curl parseContentsOfURLWithString:@"https://example.com/endpoint"
                                byPostingData:postData];
   if( ! reply)
   {
      error = [NSError mulleExtract];
      fprintf( stderr, "Error: %s\n", [[error description] UTF8String]);
      return( 1);
   }

   printf( "%s\n", [[reply description] UTF8String]);
   return( 0);
}
```

## 7. Dependencies

Direct `mulle-sde` dependencies (from `.mulle/etc/sourcetree/config`):

- `MulleCurl` — the underlying HTTP client engine whose categories make up most
  of the public API. Core runtime dependency.
- `MulleObjCInetFoundation` — Internet classes (e.g. `NSURL`) for mulle-objc.
- `MulleObjCJSMNFoundation` — JSON support (provides `MulleJSMNParser`).
- `MulleObjCHTTPFoundation` — HTTP/HTML utility classes (provides
  `MulleHTTPHeaderParser` and `MulleHTTPContentTypeKey`).
- `mulle-objc-list` — build tool (no-link, no-header, no-import); used in the
  tooling chain, not linked into consumers.

Transitively this also assumes the MulleFoundation stack (`NSData`, `NSString`,
`NSDictionary`, `NSURL`, `NSError`) and the mulle-objc runtime.