# MulleCurl Library Documentation for AI
<!-- Keywords: curl, http, https, client, parser, networking -->

## 1. Introduction & Purpose

**MulleCurl** is a high-level Objective-C wrapper around the **easy** interface of
libcurl for [mulle-objc](//mulle-objc.github.io). It provides convenient, string-based
HTTP/HTTPS client methods that `GET` and `POST` `NSData` from URLs, while still
exposing the raw `CURL *` handle and a generic `setOptions:` dictionary for advanced
libcurl configuration.

It solves the problem of talking to HTTP/HTTPS servers from mulle-objc programs
without dealing with the low-level libcurl C API. Key features:

- Synchronous `GET`/`POST` returning `NSData` (or nil on error, with `NSError` retrieval).
- Pluggable incremental response/header parsers via the `MulleCurlParser` protocol
  (used e.g. with a JSON parser for low-latency streaming).
- Arbitrary libcurl options set by `CURLOPT_*` name strings.
- Custom request headers, timeout presets (desktop/mobile), HEAD support, response-code validation.
- libcurl is compiled for HTTP(S) only.

It deliberately does **not** use `NSURL` ("don't taint MulleCurl with NSURL") — the
API takes URL strings. [MulleWebClient](//github.com/MulleWeb/MulleWebClient) adds a
`NSURL` interface on top for convenience.

## 2. Key Concepts & Design Philosophy

- **String-based interface**: Methods take `NSString *` URLs and return `NSData *`,
  keeping the public API minimal and Foundation-free of `NSURL`.
- **Easy libcurl interface**: A single `CURL *` easy handle (`connection`) is owned
  per instance. All requests are synchronous (`curl_easy_perform`) on that handle.
- **Parser protocol for streaming**: Instead of only returning whole `NSData`, a
  `MulleCurlParser` object can be plugged in. It receives body (or header) bytes
  incrementally via `curl:parseBytes:length:` and yields the final result via
  `parsedObjectWithCurl:`. The bundled `NSMutableData` category makes `NSMutableData`
  conform, so the parser is also the "buffer" by default.
- **Options via string keys**: `setOptions:` maps `CURLOPT_*` option *names*
  (`@"CURLOPT_VERBOSE"`) to their libcurl value through a lookup table, converting
  `NSString`/`NSNumber` values. Only `LONG`, `OFF_T` and `STRINGPOINT` typed options
  are supported this way.
- **Error handling**: `MulleCurlErrorDomain` (`@"MulleCurlError"`) is registered with
  `+[NSError registerErrorDomain:errorStringFunction:]`; curl `CURLcode` values are
  translated with `curl_easy_strerror`. Errors are retrieved via `MulleObjCExtractError()`
  or `+[NSError mulleExtract]`.
- **Global defaults**: `curl_global_init` happens in class `+initialize`, and a default
  User-Agent of `"MulleCurl vX.Y.Z"` is set on every connection. Class methods are
  explicitly documented as *not thread safe, not thread local*.

## 3. Core API & Data Structures

### 3.1. `src/MulleCurl.h`

#### `@interface MulleCurl : NSObject`

The main HTTP client class. It has one internal ivar `void *_chunk;` used as the
`curl_slist` backing for custom request headers (do not touch directly).

##### Properties (verbatim)

```objc
@property( assign) void        *connection;         // CURL *
@property( assign) NSUInteger  validResponseCode;   // 0 : don't care, 200 = http OK (default)
@property( retain) NSObject <MulleCurlParser>  *parser;
@property( retain) NSObject <MulleCurlParser>  *headerParser;
@property( assign) SEL   headerValueDescriptionMethod;
@property( retain) id   userInfo;
```

- **`connection`**: The underlying `CURL *` easy handle. Can be used directly with
  `curl_easy_setopt` etc. It is created in `-init` and cleaned up in `-finalize`.
- **`validResponseCode`**: When non-zero, the convenience/parse methods require the
  HTTP response code to equal this value and return nil otherwise. `0` = don't care
  (the initial value). The header comment suggests `200` (http OK) as the "default".
- **`parser`**: Body parser; receives downloaded body bytes incrementally.
- **`headerParser`**: Optional separate parser for HTTP response headers. The simplest
  case is an `NSMutableData`, retrieved later.
- **`headerValueDescriptionMethod`**: Selector used to convert header values to
  strings (initialized to `@selector( description)`).
- **`userInfo`**: Arbitrary object for the parser's intermediate state.

##### Lifecycle

MulleCurl declares no public construction methods; use the standard mulle-objc
factory/class methods (e.g. `[MulleCurl object]` or `[[MulleCurl new] autorelease]`).
Behavior of the standard `-init`/`-finalize`:

- `-init` calls `curl_easy_init()`. If it returns NULL, `-init` releases self and
  returns nil. Otherwise it installs the default options (see `setDefaultOptions`)
  and sets `_headerValueDescriptionMethod = @selector( description)`.
- `-finalize` frees the request-header `curl_slist` (`_chunk`) and calls
  `curl_easy_cleanup( _connection)`.

##### Request Configuration

```objc
- (void) setRequestHeaders:(NSDictionary *) headers;
```

Builds a `curl_slist` of `"Key: value"` lines set via `CURLOPT_HTTPHEADER`.
Overwrites previous headers. Keys must **not** contain `:` and must be proper HTTP
header keys (asserted with `NSParameterAssert`). Each value is converted to a string
using `headerValueDescriptionMethod` (so e.g. `NSDate` values can be formatted).

```objc
- (void) setOptions:(NSDictionary *) options;
```

Sets arbitrary libcurl options by name. Keys are the `CURLOPT_*` names
(e.g. `@"CURLOPT_VERBOSE"`); values are `NSNumber` for `LONG`/`OFF_T` options and
`NSString` for `STRINGPOINT` options. Raises `NSInvalidArgumentException` for unknown
option names or unsupported option types (function/object/slist pointers). See
https://curl.haxx.se/libcurl/c/curl_easy_setopt.html for the option list.

```objc
- (void) setNoBodyOptions;
```
Sets `CURLOPT_NOBODY` (useful for `HEAD` requests — headers only, no body).

```objc
- (void) setDesktopTimeoutOptions;
- (void) setMobileTimeoutOptions;
```
Preset convenience timeout profiles ("choose either one for a somewhat better
experience, the default is neither!"):
- Desktop: connect timeout 2000 ms, low-speed time 60 s, low-speed limit 32 kbit/s.
- Mobile: connect timeout 5000 ms, low-speed time 120 s, low-speed limit 2400 bit/s.

```objc
- (void) setConnectTimeout:(NSTimeInterval) interval;
```
Sets `CURLOPT_CONNECTTIMEOUT_MS` (`interval * 1e6 + 0.5`, `assert(interval >= 0)`).

```objc
- (void) setLowSpeedTimeOut:(NSTimeInterval) interval
           minBitsPerSecond:(NSUInteger) speedLimit;
```
Sets `CURLOPT_LOW_SPEED_TIME` (seconds, `interval + 0.5`) and
`CURLOPT_LOW_SPEED_LIMIT` (`speedLimit / 8` bytes/sec).

```objc
- (void) setDefaultOptions;
```
Always set on init/reset. Enables `-L` (`CURLOPT_FOLLOWLOCATION`), turns off
signaling (`CURLOPT_NOSIGNAL`), disables verbose and progress, wires the internal
body write callback, and sets the default User-Agent.

```objc
- (void) setDebugOptions;
```
Re-enables verbose output and the progress meter (`CURLOPT_VERBOSE` YES,
`CURLOPT_NOPROGRESS` NO).

```objc
- (void) reset;
```
Returns the instance to its post-`-init` state: resets `headerValueDescriptionMethod`,
removes parser/headerParser/userInfo, frees `_chunk`, calls `curl_easy_reset` and
`setDefaultOptions`.

##### Response Data Retrieval (Convenience)

```objc
- (NSData *) dataWithContentsOfURLWithString:(NSString *) url;
- (NSData *) dataWithContentsOfURLWithString:(NSString *) url
                               byPostingData:(NSData *) data;
```
Synchronous GET (or POST when `data` is non-nil) that returns the response body as
`NSData *`. Internally they use an `NSMutableData` as the body parser and return it if
the transfer succeeded. Return nil on error; retrieve the error with
`MulleObjCExtractError()` or `+[NSError mulleExtract]`. They reset (replace) the body
parser but do **not** touch the header parser. For POSTs, set the correct `Content-Type`
header beforehand; the data is sent "as is".

##### Parsing Response Data

```objc
- (id) parseContentsOfURLWithString:(NSString *) url;
- (id) parseContentsOfURLWithString:(NSString *) url
                       byPostingData:(NSData *) data;
```
Like the above but return whatever `[parser parsedObjectWithCurl:]` produces (e.g. a
`NSDictionary` for JSON). The parser **must be set** before calling (raises
`NSInternalInconsistencyException` otherwise); an empty URL raises
`NSInvalidArgumentException`. When `validResponseCode` is non-zero, these check the
actual response code and return nil (and the transfer result is discarded) if it does
not match. Depending on `data`, sets `CURLOPT_POST`/`CURLOPT_POSTFIELDS` and
`CURLOPT_POSTFIELDSIZE_LARGE`. On curl failure, sets `errno` to the `CURLcode` and
returns nil.

##### Inspection

```objc
- (NSUInteger) lastResponseCode;
```
The HTTP response code of the last request (e.g. 200, 404), or `NSNotFound` if
`curl_easy_getinfo( CURLINFO_RESPONSE_CODE)` fails.

##### Class Methods

```objc
+ (void) setDefaultUserAgent:(NSString *) agent;
+ (NSString *) defaultUserAgent;
```
Get/set the global default User-Agent used by all connections (initially
`"MulleCurl vX.Y.Z"`). `setDefaultUserAgent:nil` clears it.

##### Error Domain

```objc
extern NSString   *MulleCurlErrorDomain; // = @"MulleCurlError";
```
The error domain for curl-related errors. Registered with `NSError` on class
initialization; curl error codes are translated via `curl_easy_strerror`.

##### Version Macros & Functions (verbatim)

```c
#define MULLE_CURL_VERSION  ((0UL << 20) | (19 << 8) | 2)

static inline unsigned int   MulleCurl_get_version_major( void)
static inline unsigned int   MulleCurl_get_version_minor( void)
static inline unsigned int   MulleCurl_get_version_patch( void)

extern uint32_t   MulleCurl_get_version( void);
```
Current version is **0.19.2** (`(major << 20) | (minor << 8) | patch`).

### 3.2. `src/MulleCurlParser.h`

#### `@protocol MulleCurlParser`

Implemented by parsers that consume response (body or header) data incrementally:

```objc
@protocol MulleCurlParser

- (BOOL) curl:(MulleCurl *) curl
   parseBytes:(void *) bytes
       length:(NSUInteger) length;

// the parsed result
- (id) parsedObjectWithCurl:(MulleCurl *) curl;

@end
```

- `curl:parseBytes:length:` is called repeatedly with chunks of received bytes.
  Return `YES` to continue; return `NO` to abort the transfer (the internal receive
  callback returns 0, which libcurl treats as an error).
- `parsedObjectWithCurl:` is called after a successful transfer to get the final
  parsed result.

### 3.3. `src/NSMutableData+MulleCurlParser.h`

#### `@interface NSMutableData( MulleCurlParser) <MulleCurlParser>`

A built-in conformance giving `NSMutableData` a parser implementation:

```objc
- (BOOL) curl:(MulleCurl *) curl
   parseBytes:(void *) bytes
       length:(NSUInteger) length;
- (id) parsedObjectWithCurl:(MulleCurl *) curl;
```

`curl:parseBytes:length:` appends the bytes and always returns `YES`;
`parsedObjectWithCurl:` returns `self`. This is what makes `dataWithContentsOfURLWithString:`
work, and it is also convenient as a body/header grab-bag (e.g. as a `headerParser`).

### 3.4. `src/MulleObjCDeps+MulleCurl.h`

#### `@interface MulleObjCDeps( MulleCurl)`

```objc
+ (struct _mulle_objc_dependency *) dependencies;
```
Public category used by other libraries that depend on MulleCurl to declare their
load in their `MulleObjcLoader` class. Only compiled under `__MULLE_OBJC__`.

## 4. Performance Characteristics

- **Synchronous & blocking**: each request runs `curl_easy_perform` and does not
  return until transfer completes. One request per instance at a time.
- **Time**: O(n) in the response size for body retrieval. Data flows through the
  parser incrementally, so `parseContents...` has lower latency than
  `dataWithContents...` followed by a separate parse (memory is not proportional to
  the full response for streaming parsers).
- **Memory**: `dataWithContentsOfURLWithString:` buffers the entire body in an
  `NSMutableData`. Streaming parsers limit memory to current chunk size.
- **Connection reuse**: each instance keeps its `CURL *`, so sequentially reusing one
  instance benefits from libcurl's keep-alive. No pool across instances.
- **Thread safety**: *not thread-safe*. The class-method comment states "not thread
  safe, not thread local". The `optionLookupTable` is built lazily with an atomic CAS,
  but sharing instances (or global state) across threads requires external locking.
  Use one MulleCurl instance per thread.
- **Header building** (`setRequestHeaders:`): O(h) where h is the number of headers,
  with a 256-byte stack buffer for formatting each line.

## 5. AI Usage Recommendations & Patterns

### Best Practices

- Create instances with factory/class methods — e.g. `[MulleCurl object]` — and avoid
  manual `alloc/init`/`retain`/`release` outside `-init`/`-dealloc`.
- Check the `nil` return of `dataWith...`/`parseContents...`, then fetch the error via
  `MulleObjCExtractError()` or `+[NSError mulleExtract]` (the error domain is
  `MulleCurlErrorDomain`).
- Set `validResponseCode` (e.g. `200`) when you only accept a specific status; the
  methods then return nil for a mismatch automatically.
- For POSTs, set `Content-Type` (and `Accept`) up front with `setRequestHeaders:` — the
  payload is sent verbatim.
- Reuse a single instance for sequential requests to keep connections alive; use one
  instance per thread for concurrency.
- Always call `setDesktopTimeoutOptions`/`setMobileTimeoutOptions` (or explicit
  timeouts) so a dead server cannot hang your program forever.
- Use the `MulleCurlParser` protocol (e.g. via a JSON parser) for large responses to
  avoid buffering the whole body.

### Common Pitfalls

- Calling `parseContents...` without `setParser:` first raises
  `NSInternalInconsistencyException`.
- `setOptions:` raises `NSInvalidArgumentException` for an unknown `CURLOPT_*` name or
  for unsupported option types (function/object/slist pointer types). These must be
  applied directly on the `connection` handle instead.
- Header keys in `setRequestHeaders:` must not contain `:`.
- Returning `NO` from `curl:parseBytes:length:` aborts the whole transfer — only do
  that when you want to cancel.
- `connection` is a borrowed/bare `CURL *` owned by the instance — do not free it
  yourself; `-finalize` cleans it up.
- `dataWithContents...` replaces the body parser (the returned `NSData`); the header
  parser is preserved.
- Do not use the same instance from multiple threads simultaneously (not thread-safe).

### Idiomatic Usage

- Prefer the string-URL API; for `NSURL`-based code look at `MulleWebClient`.
- `[curl setOptions:]` with `@"CURLOPT_SSL_VERIFYPEER": @(NO)` and
  `@"CURLOPT_SSL_VERIFYHOST": @(NO)` is the standard way to disable certificate checks
  in tests.

## 6. Integration Examples

Code follows the project style: 3-space indent, Allman braces, aligned/columnar
declarations, one variable per line, `return( expr);`, no dot-syntax, and no
alloc/init outside of init/dealloc.

### Example 1: Simple HTTPS GET

```objc
#import <MulleCurl/MulleCurl.h>
#import <MulleObjCInetFoundation/MulleObjCInetFoundation.h>

#include <stdio.h>

static NSString   *URL = @"https://www.mulle-kybernetik.com/weblog/2019/mulle_objc_0_16_release.html";


int  main( void)
{
   MulleCurl   *curl;
   NSData      *data;
   NSError     *error;

   curl = [MulleCurl object];

   // for testing turn off https cert checks
   [curl setOptions:@{
                       @"CURLOPT_SSL_VERIFYPEER": @(NO),
                       @"CURLOPT_SSL_VERIFYHOST": @(NO)
                     }];
   [curl setDesktopTimeoutOptions];

   data = [curl dataWithContentsOfURLWithString:URL];
   if( ! data)
   {
      error = MulleObjCExtractError();
      fprintf( stderr, "%s\n", [[error description] UTF8String]);
      return( 1);
   }

   printf( "%.*s", (int) [data length], (char *) [data bytes]);
   return( 0);
}
```

### Example 2: POST with an incremental JSON parser

```objc
#import <MulleCurl/MulleCurl.h>
#import <MulleObjCJSMNFoundation/MulleObjCJSMNFoundation.h>

#include <stdio.h>


@interface MulleJSMNParser( MulleCurlParser) <MulleCurlParser>
@end


@implementation MulleJSMNParser( MulleCurlParser)

- (BOOL) curl:(MulleCurl *) curl
   parseBytes:(void *) bytes
       length:(NSUInteger) length
{
   MULLE_C_UNUSED( curl);

   [self parseBytes:bytes
             length:length];

   return( YES);
}


// the parsed result
- (id) parsedObjectWithCurl:(MulleCurl *) curl
{
   MULLE_C_UNUSED( curl);

   return( [self object]);
}

@end


int  main( void)
{
   MulleCurl        *curl;
   NSData           *postData;
   NSError          *error;
   NSDictionary     *dictionary;

   curl = [MulleCurl object];
   [curl setConnectTimeout:8.0];
   [curl setParser:[MulleJSMNParser object]];

   postData = [NSData dataWithBytes:"VfL Bochum 1848"
                             length:15];

   dictionary = [curl parseContentsOfURLWithString:@"https://httpbin.org/post"
                                      byPostingData:postData];
   if( ! dictionary)
   {
      error = [NSError mulleExtract];
      fprintf( stderr, "%s\n", [[error description] UTF8String]);
      return( 1);
   }

   printf( "%s\n", [[dictionary description] UTF8String]);
   return( 0);
}
```

### Example 3: Collecting response headers with an NSMutableData header parser

`NSMutableData` natively conforms to `MulleCurlParser` (see section 3.3), so it can
directly be installed as the header parser and inspected afterwards:

```objc
#import <MulleCurl/MulleCurl.h>
#import <MulleObjCInetFoundation/MulleObjCInetFoundation.h>

#include <stdio.h>

static NSString   *URL = @"http://www.mulle-kybernetik.com/jagdox/dehtmlify.sh";


int  main( void)
{
   MulleCurl        *curl;
   NSMutableData    *headerData;
   NSData           *body;
   NSError          *error;

   curl       = [MulleCurl object];
   headerData = [NSMutableData object];

   // compiler needs the cast for the protocol-qualified property setter
   [curl setHeaderParser:(NSObject <MulleCurlParser> *) headerData];
   [curl setDesktopTimeoutOptions];

   body = [curl dataWithContentsOfURLWithString:URL];
   if( ! body)
   {
      error = MulleObjCExtractError();
      fprintf( stderr, "%s\n", [[error description] UTF8String]);
      return( 1);
   }

   printf( "%td bytes of raw headers\n", [headerData length]);
   printf( "%.*s", (int) [headerData length], (char *) [headerData bytes]);
   return( 0);
}
```

### Example 4: Validated response code + custom request headers

```objc
#import <MulleCurl/MulleCurl.h>
#import <MulleObjCInetFoundation/MulleObjCInetFoundation.h>

#include <stdio.h>


int  main( void)
{
   MulleCurl   *curl;
   NSData      *data;
   NSError     *error;

   curl = [MulleCurl object];
   [curl setRequestHeaders:@{
                              @"Accept": @"application/json",
                              @"Content-Type": @"application/json"
                            }];
   [curl setValidResponseCode:200];

   data = [curl dataWithContentsOfURLWithString:@"https://httpbin.org/get"];
   if( ! data)
   {
      error = MulleObjCExtractError();
      fprintf( stderr, "%s (%lu)\n",
               [[error description] UTF8String],
               (unsigned long) [curl lastResponseCode]);
      return( 1);
   }

   printf( "received %td bytes\n", [data length]);
   return( 0);
}
```

## 7. Dependencies

Direct `mulle-sde` dependencies (from `.mulle/etc/sourcetree/config`):

- `MulleFoundationBase` — amalgamates the Foundation projects (`NSString`, `NSData`,
  `NSDictionary`, `NSError`, `NSMapTable`, `NSMutableData`, etc.).
- `curl` — external libcurl (HTTP(S) easy interface), pinned to curl 8.17.0.
- `MulleZlib` — zlib compression support for mulle-objc.
- `openssl` / `ssl` / `crypto` — TLS backend for HTTPS (built from source on Darwin,
  system OpenSSL on Linux; the README notes `sudo apt-get install libssl-dev` on
  Debian/Ubuntu).
- Runtime/library derives: `MulleObjCStandardFoundation` (declared via
  `MULLE_OBJC_DEPENDS_ON_LIBRARY`) and the mulle-objc runtime.
- Darwin-only frameworks: `CoreFoundation`, `SystemConfiguration`.