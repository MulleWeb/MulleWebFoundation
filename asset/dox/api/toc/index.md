# MulleWebFoundation Library Documentation for AI
<!-- Keywords: amalgamation, web, HTTP, JSON, URL, XML, compression -->

## 1. Introduction & Purpose

- **MulleWebFoundation** is an *amalgamation* library: the sources of eight
  Web-oriented Objective-C projects are copied (`clibmode=copy`) into `src/`
  and built as a single linkable library on top of the Foundation. One public
  include (`<MulleWebFoundation/MulleWebFoundation.h>`), one link target.
- It aggregates:
  - `MulleCurl` — synchronous libcurl-based HTTP/HTTPS client engine.
  - `MulleWebClient` — high-level `MulleCurl` categories (URL/JSON convenience).
  - `MulleObjCInetFoundation` — `NSURL`, `NSHost`, URL character sets,
    percent-escape helpers, `NSData (NSURL)`.
  - `MulleObjCHTTPFoundation` — HTTP header constants/parser, HTML
    escaping, HTTP date formatting, list components.
  - `MulleObjCJSMNFoundation` — incremental JSON parser (`MulleJSMNParser`).
  - `MulleObjCExpatFoundation` — generic XML (SAX) parser plus XML property
    list reader/writer.
  - `MulleBase64` — RFC 4648 Base64 C codec and `NSData (Base64)` category.
  - `MulleZlib` — zlib DEFLATE compression via `NSData (MulleZlib)`.
- It solves the problem of pulling, building and linking eight small libraries
  for a web client/server: one include, one link, faster builds. It is the
  basis for `MulleWebClient`, `MulleWebServer` and is part of the Foundation.
- **Not a reimplementation.** Each constituent remains the canonical upstream
  project; this repository gathers versioned snapshots. Fixes are made upstream
  and brought in by the next amalgamation.
- The umbrella header also imports `MulleFoundation`, a *dependency* (not part
  of this project) that supplies the value/container/standard classes
  (`NSString`, `NSArray`, `NSDictionary`, `NSData`, `NSDate`, `NSError`, …).
- **Per-constituent deep dives** live next to the sources and contain the full
  symbol-by-symbol reference (installed to
  `share/<Name>/dox/api/toc/index.md`):
  `src/MulleCurl/index.md`, `src/MulleWebClient/index.md`,
  `src/MulleObjCInetFoundation/index.md`, `src/MulleObjCHTTPFoundation/index.md`,
  `src/MulleObjCJSMNFoundation/index.md`,
  `src/MulleObjCExpatFoundation/index.md`, `src/MulleBase64/index.md`,
  `src/MulleZlib/index.md`.

## 2. Key Concepts & Design Philosophy

- **Amalgamation, not composition.** Each constituent still lives in its own
  `src/<Name>/` directory with its own umbrella header and generated
  `_<Name>-export.h`. There is one build target. The public umbrella
  `src/MulleWebFoundation/MulleWebFoundation.h` imports `MulleFoundation` and
  all eight constituent umbrellas.
- **Layering.** Lower layers are built first:
  `MulleBase64`, `MulleZlib`, `MulleObjCInetFoundation` (URL) and
  `MulleObjCJSMNFoundation` (JSON) are leaf libraries;
  `MulleObjCHTTPFoundation` builds on the inet layer;
  `MulleCurl` is the HTTP engine; `MulleWebClient` glues curl to the parsers.
  `MulleObjCExpatFoundation` is an independent XML/plist layer.
- **Categories over subclasses.** Most constituents extend existing Foundation
  classes by category (`NSData (Base64)`, `NSData (MulleZlib)`,
  `NSString (MulleHTMLEscaping)`, `NSDate (MulleHTTP)`, `MulleCurl (NSURL)`).
  Adding the library changes nothing until you call its selectors.
- **Parser plug-in protocol.** `MulleCurl` streams response bytes into an object
  conforming to `MulleCurlParser`; `MulleWebClient` supplies adapters that make
  `MulleJSMNParser` and `MulleHTTPHeaderParser` conform, enabling
  low-latency incremental parsing.
- **String-based HTTP core.** `MulleCurl` deliberately takes `NSString` URLs
  ("don't taint MulleCurl with NSURL"); `MulleWebClient` adds the `NSURL`
  interface on top.
- **mulle-objc coding conventions** (apply to all code written against this
  library): 3-space indent, Allman braces, aligned/columnar declarations,
  C89 variable rules, one variable per line, `return( expr);`, **no
  dot-syntax** (use `[obj method]` / `[obj setMethod:value]`), **no blocks**
  (`^`), no `+alloc`/`-init`/`-autorelease` in application code (use factory
  methods such as `+object`/`+instance`), and never call `-release` outside
  `-dealloc`.

## 3. Core API & Data Structures

All signatures below are copied verbatim from the public headers. Because this
is an amalgamation, every constituent's member functions are reachable from
the umbrella header. Full per-constituent detail is in the deep dives listed
in section 1.

### 3.1. Umbrella header and version

```objc
#import <MulleWebFoundation/MulleWebFoundation.h>
```

```c
#define MULLE_WEB_FOUNDATION_VERSION ((0UL << 20) | (31 << 8) | 0)
```

- The umbrella header defines only the version macro (0.31.0); it imports
  `MulleFoundation` and the eight constituent umbrellas. There are no
  `MulleWebFoundation_get_version_*` functions.
- Per-constituent versions (`(major << 20) | (minor << 8) | patch`) are exposed
  as macros. Only five constituents additionally provide inline
  `*_get_version_major/minor/patch()` functions and a `*_get_version()` defined
  in a `.m`; `MulleObjCInetFoundation`, `MulleObjCHTTPFoundation` and
  `MulleObjCExpatFoundation` define the macro only:
  - `MULLE_CURL_VERSION` — 0.19.3 (`MulleCurl_get_version*`)
  - `MULLE_WEB_CLIENT_VERSION` — 0.1.1 (`MulleWebClient_get_version*`)
  - `MULLE_OBJC_INET_FOUNDATION_VERSION` — 0.20.0 (macro only)
  - `MULLE_OBJC_HTTP_FOUNDATION_VERSION` — 0.20.0 (macro only)
  - `MULLE_OBJC_JSMN_FOUNDATION_VERSION` — 0.18.13 (`MulleObjCJSMNFoundation_get_version*`)
  - `MULLE_OBJC_EXPAT_FOUNDATION_VERSION` — 0.21.0 (macro only)
  - `MULLE_BASE64_VERSION` — 0.1.3 (`MulleBase64_get_version*`)
  - `MULLE_ZLIB_VERSION` — 0.15.17 (`MulleZlib_get_version*`)

### 3.2. `MulleCurl` — HTTP/HTTPS client engine (`src/MulleCurl/MulleCurl.h`)

```objc
@interface MulleCurl : NSObject

@property( assign) void        *connection;         // CURL *
@property( assign) NSUInteger  validResponseCode;   // 0 : don't care, 200 = http OK (default)
@property( retain) NSObject <MulleCurlParser>  *parser;
@property( retain) NSObject <MulleCurlParser>  *headerParser;
@property( assign) SEL   headerValueDescriptionMethod;
@property( retain) id   userInfo;

- (void) setRequestHeaders:(NSDictionary *) headers;
- (void) setOptions:(NSDictionary *) options;
- (void) setNoBodyOptions;
- (void) setDesktopTimeoutOptions;
- (void) setMobileTimeoutOptions;
- (void) setConnectTimeout:(NSTimeInterval) interval;
- (void) setLowSpeedTimeOut:(NSTimeInterval) interval
           minBitsPerSecond:(NSUInteger) speedLimit;
- (void) setDefaultOptions;
- (void) setDebugOptions;
- (void) reset;

- (NSData *) dataWithContentsOfURLWithString:(NSString *) url;
- (NSData *) dataWithContentsOfURLWithString:(NSString *) url
                               byPostingData:(NSData *) data;
- (id) parseContentsOfURLWithString:(NSString *) url;
- (id) parseContentsOfURLWithString:(NSString *) url
                      byPostingData:(NSData *) data;
- (NSUInteger) lastResponseCode;
@end

@interface MulleCurl( ClassMethods)
+ (void) setDefaultUserAgent:(NSString *) agent;
+ (NSString *) defaultUserAgent;
@end

extern NSString   *MulleCurlErrorDomain; // = @"MulleCurlError";
```

- **Lifecycle:** no public construction methods; use `[MulleCurl object]` /
  `[MulleCurl instance]`. `-init` calls `curl_easy_init()` and returns nil on
  failure; `-finalize` calls `curl_easy_cleanup()`.
- **Errors:** convenience/parse methods return nil; retrieve the error with
  `MulleObjCExtractError()` or `+[NSError mulleExtract]`.
- **Not thread-safe / not thread-local:** use one instance per thread.
- `-reset` returns to curl standard options + `setDefaultOptions` (as if
  `-init` ran again) and removes parser, headerParser and userInfo.

#### `@protocol MulleCurlParser` (`src/MulleCurl/MulleCurlParser.h`)

```objc
@protocol MulleCurlParser

- (BOOL) curl:(MulleCurl *) curl
   parseBytes:(void *) bytes
       length:(NSUInteger) length;

- (id) parsedObjectWithCurl:(MulleCurl *) curl;

@end
```

#### `@interface NSMutableData( MulleCurlParser) <MulleCurlParser>` (`src/MulleCurl/NSMutableData+MulleCurlParser.h`)

`NSMutableData` natively conforms to `MulleCurlParser`: `parseBytes:length:`
appends and returns `YES`; `parsedObjectWithCurl:` returns `self`. This is what
makes `dataWithContentsOfURLWithString:` work, and makes an `NSMutableData`
usable as a `headerParser`.

### 3.3. `MulleWebClient` — high-level web client categories (`src/MulleWebClient/`)

No classes of its own; categories on `MulleCurl`. All methods are synchronous
and return nil on error (`[NSError mulleExtract]`).

```objc
// MulleCurl+NSURL.h
@interface MulleCurl( NSURL)

+ (NSData *) dataWithContentsOfURL:(NSURL *) url;
+ (id) propertyListWithJSONContentsOfURL:(NSURL *) url;

- (NSData *) dataWithContentsOfURL:(NSURL *) url;
- (NSData *) dataWithContentsOfURL:(NSURL *) url
                     byPostingData:(NSData *) data;
- (id) parseContentsOfURL:(NSURL *) url;
- (id) parseContentsOfURL:(NSURL *) url
            byPostingData:(NSData *) data;
@end

// MulleCurl+JSON.h
@interface MulleCurl( JSON)
+ (id) JSONContentsOfURL:(NSURL *) url;
+ (id) JSONContentsOfURLWithString:(NSString *) urlString;
@end

// parser adapters
@interface MulleHTTPHeaderParser( MulleCurlParser) <MulleCurlParser>
@end
@interface MulleJSMNParser( MulleCurlParser) < MulleCurlParser>
@end
```

- The `+` convenience methods use a shared instance and are not safe for
  concurrent use; create a dedicated `MulleCurl` per thread/request.
- POSTed data is sent "As Is"; set the `Content-Type` header yourself (the
  `JSON` category sets `MulleHTTPContentTypeKey` to `@"application/json"`).
- `+JSONContentsOfURL:` / `+JSONContentsOfURLWithString:` install a
  `MulleJSMNParser` and return a parsed object (typically `NSDictionary` /
  `NSArray`), or nil.

### 3.4. `MulleObjCInetFoundation` — URL and host (`src/MulleObjCInetFoundation/`)

```objc
// NSURL.h
struct MulleEscapedURLPartsUTF8
{
   struct MulleCharData   scheme;
   struct MulleCharData   escaped_user;
   struct MulleCharData   escaped_password;
   struct MulleCharData   escaped_host;
   NSUInteger             port;
   struct MulleCharData   escaped_path;
   struct MulleCharData   escaped_parameter;
   struct MulleCharData   escaped_query;
   struct MulleCharData   escaped_fragment;
   int                    validated;
};

struct MulleURLSchemeHandler
{
   SEL   initURL;
   SEL   printURL;
   SEL   printResourceSpecifier;
};

struct MulleURLSchemeInitArguments
{
   struct MulleCharData   scheme;
   struct MulleCharData   uri;
};

MULLE_OBJC_INET_FOUNDATION_EXTERN_GLOBAL
NSString   *NSURLFileScheme;

@interface NSURL : NSObject < NSCopying, MulleObjCImmutable>

// incoming strings must already be percent escaped for all these methods
+ (instancetype) URLWithString:(NSString *) s;
+ (instancetype) URLWithString:(NSString *) s
                 relativeToURL:(NSURL *) url;
- (instancetype) initWithString:(NSString *) URLString;
- (instancetype) initWithString:(NSString *) URLString
                  relativeToURL:(NSURL *) baseURL;
- (id) mulleInitWithUTF8Characters:(char *) c_string
                            length:(NSUInteger) c_string_len;

// This method automatically uses percent encoding to escape the path
// and host parameters.
- (instancetype) initWithScheme:(NSString *) scheme
                           host:(NSString *) host
                           path:(NSString *) path;

// these return unescaped values
- (NSString *) scheme;
- (NSString *) user;
- (NSString *) password;
- (NSString *) host;
- (NSNumber *) port;       // just unescaped, no special file: handling
- (NSString *) path;
- (NSString *) parameterString;
- (NSString *) query;
- (NSString *) fragment;
- (NSString *) resourceSpecifier;

- (NSString *) stringValue;   // transform into a string
- (NSString *) description;   // URL with percent escapes (calls stringValue)

- (NSURL *) URLByAppendingPathComponent:(NSString *) component;

// mulle extensions
- (instancetype) mulleInitWithEscapedURLPartsUTF8:(struct MulleEscapedURLPartsUTF8 *) parts
                           allowedURICharacterSet:(NSCharacterSet *) characterSet;
- (instancetype) mulleInitResourceSpecifierWithUTF8Characters:(char *) utf
                                                       length:(NSUInteger) length;
- (instancetype) mulleInitWithSchemeUTF8Characters:(char *) scheme
                                            length:(NSUInteger) scheme_len
                   resourceSpecifierUTF8Characters:(char *)uri
                                            length:(NSUInteger) uri_len;

+ (void) mulleRegisterHandler:(struct MulleURLSchemeHandler *) handler
                    forScheme:(NSString *) scheme;
- (NSString *) mulleGenericResourceSpecifierDescription;
- (NSString *) mulleGenericURLDescription;
- (BOOL) mulleIsAbsolutePath;
- (NSString *) mulleEscapedResourceSpecifier;
+ (NSCharacterSet *) mulleURLEscapedAllowedCharacterSet;

// filesystem (file:) URL support
- (char *) fileSystemRepresentation;
- (BOOL) getFileSystemRepresentation:(char *) buf
                           maxLength:(NSUInteger) max;
- (instancetype) initFileURLWithPath:(NSString *) path;
+ (instancetype) fileURLWithPath:(NSString *) path;
- (instancetype) initFileURLWithPath:(NSString *) path
                         isDirectory:(BOOL) isDirectory;
+ (instancetype) fileURLWithPath:(NSString *) path
                     isDirectory:(BOOL) isDirectory;
+ (instancetype) fileURLWithPathComponents:(NSArray *) components;
@end

@interface NSURL( Legacy)
- (BOOL) isFileURL;
- (NSURL *) standardizedURL;
- (NSString *) absoluteString;      // use description as string conversion
- (NSString *) relativePath;
- (NSString *) relativeString;
- (NSURL *) baseURL;          // this is always nil
- (NSURL *) absoluteURL;     // returns self
- (NSArray *) pathComponents;
- (NSString *) lastPathComponent;
- (NSString *) pathExtension;
@end

char  *mulle_strnstr( char *s, size_t len, char *search);
```

- Accessors return **unescaped** `NSString`s; `-description`/`-stringValue`
  return the percent-escaped form. Incoming strings to the `+URLWithString:`
  / `-initWithString:` initializers must already be percent escaped; malformed
  input yields nil. The Apple "base URL marriage" was not adopted: a new URL is
  created instead. Do not use `NSURL` for file access (use `NSFileManager`).
- `NSHost` (`NSHost.h`) is a lazy host record: `@property(nonatomic,readonly,copy) NSArray *names;`
  `@property(nonatomic,readonly,copy) NSArray *addresses;`,
  `- (id) initWithNames:(NSString **) names count:(NSUInteger) count addresses:(NSString **) addresses count:(NSUInteger) nAddresses;`,
  `+ (instancetype) hostWithName:(NSString *) name;`,
  `+ (instancetype) hostWithAddress:(NSString *) address;`,
  `- (BOOL) isEqualToHost:(NSHost *) other;`, `- (NSString *) name;`,
  `- (NSString *) address;`. `NSHost (Future) <MulleObjCFuture>` adds
  `+ (instancetype) currentHost;` and `- (NSString *) localizedName;`.
- `NSString (MulleURL)`: `- (NSString *) stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding) encoding;`,
  `- (NSString *) stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding) encoding;`.
- `NSCharacterSet (MulleURL)` provides `+URLFragmentAllowedCharacterSet`,
  `+URLHostAllowedCharacterSet`, `+URLPasswordAllowedCharacterSet`,
  `+URLPathAllowedCharacterSet`, `+URLQueryAllowedCharacterSet`,
  `+URLUserAllowedCharacterSet`, `+mulleURLAllowedCharacterSet`,
  `+mulleURLSchemeAllowedCharacterSet`, `+mulleNonPercentEscapeCharacterSet`.
- `NSData (NSURL)`: `+dataWithContentsOfURL:options:error:`,
  `+dataWithContentsOfURL:`, `-initWithContentsOfURL:`, `-writeToURL:atomically:`.

### 3.5. `MulleObjCHTTPFoundation` — HTTP/HTML helpers (`src/MulleObjCHTTPFoundation/`)

- `MulleHTTP.h`: `enum MulleHTTPRequestMethod` (`MulleHTTPOther = -1`,
  `MulleHTTPGet = 0`, `MulleHTTPPost = 1`, `MulleHTTPPut`, `MulleHTTPDelete`,
  `MulleHTTPHead`); `#define`d RFC 2616 header-name constants
  (`MulleHTTPAcceptKey`, `MulleHTTPAuthorizationKey`, `MulleHTTPContentTypeKey`,
  `MulleHTTPHostKey`, `MulleHTTPUserAgentKey`, `MulleHTTPLocationKey`, …)
  and transfer-encoding constants (`MulleHTTPTransferEncodingChunked` = @"chunked",
  `MulleHTTPTransferEncodingCompressed` = @"compress",
  `MulleHTTPTransferEncodingDeflate` = @"deflate",
  `MulleHTTPTransferEncodingGzip` = @"gzip",
  `MulleHTTPTransferEncodingIdentity` = @"identity").
- `MulleHTTPHeaderParser.h`:

  ```objc
  @interface MulleHTTPHeaderParser : NSObject
  @property BOOL   recordsOrder;
  - (BOOL) isIncomplete;
  - (NSArray *) order;
  - (NSDictionary *) headers;
  - (NSString *) response;
  - (NSMutableArray *) extractOrder;
  - (NSMutableDictionary *) extractHeaders;
  - (void) parse;
  @end
  ```

  Splits lines into key/value pairs into an `NSDictionary`, trimming leading
  and trailing whitespace. `extract*` return the internal state destructively.
- `NSDate (MulleHTTP)`: `- (NSString *) mulleHTTPDescription;`,
  `+ (instancetype) mulleDateWithHTTPDateString:(NSString *) string;`,
  `+ (instancetype) mulleDateWithISO8601String:(NSString *) string;`,
  `+ (instancetype) mulleDateWithString:(NSString *) string;` (tries HTTP or
  ISO 8601; for syndication feeds).
- `NSString (MulleHTMLEscaping)`: `- (NSString *) mulleStringByEscapingHTML;`,
  `- (NSString *) mulleStringByEscapingHTMLForASCII;`,
  `- (NSString *) mulleStringByUnescapingHTML;` (escape calls are safe once only).
- `NSString (ListComponents)`: `- (NSRange) mulleRangeOfListComponent:(NSString *) component separator:(NSString *) separator;`,
  `- (NSString *) mulleStringByAddingListComponent:(NSString *) component separator:(NSString *) separator;`,
  `- (NSString *) mulleStringByRemovingListComponent:(NSString *) component separator:(NSString *) separator;`.
  A list is like `@"a,b,c"`; components are unique.

### 3.6. `MulleObjCJSMNFoundation` — incremental JSON (`src/MulleObjCJSMNFoundation/`)

```objc
@interface MulleJSMNParser : NSObject

@property( getter=isIncomplete) BOOL  incomplete;
@property BOOL  trueFalseAsStrings;

// userInfo and object properties will be cleared on -reset
@property( retain) id   userInfo;
@property( retain) id   object;

- (id) parseData:(NSData *) data;
- (id) parseBytes:(void *) bytes
           length:(NSUInteger) length;
- (void) reset;
- (NSError *) errorWithName:(NSString *) name
                      bytes:(void *) bytes
                     length:(NSUInteger) length
                      range:(NSRange) range;
@end

@interface NSString( MulleJSMNParser)
- (id) mulleJSON;
@end
```

- `parseData:`/`parseBytes:` return `NSDictionary`/`NSArray`/`NSString`/
  `NSNumber` (or nil). If nil, check `-isIncomplete`: if YES append more data
  and retry (already-parsed bytes are not re-parsed). Call `-reset` between
  distinct JSON documents. UTF-8 only.
- When parsing incrementally, do not split a token across calls: send
  `parseBytes:"[" length:1` then `parseBytes:"[]" length:2`.

### 3.7. `MulleObjCExpatFoundation` — XML and XML plists (`src/MulleObjCExpatFoundation/`)

```objc
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

@interface MulleObjCXMLParser : NSObject

@property( assign) id <MulleObjCXMLParserDelegate> delegate;

+ (instancetype) parserWithDelegate:(id <MulleObjCXMLParserDelegate>) delegate;
- (instancetype) initWithDelegate:(id <MulleObjCXMLParserDelegate>) delegate;

- (BOOL) parseData:(NSData *) data;
- (BOOL) parseBytes:(void *) bytes
             length:(NSUInteger) length
            isFinal:(BOOL) isFinal;

- (void) abortParsing;
@end

@interface MulleObjCExpatParser : NSObject <MulleObjCXMLParserDelegate>
@end

@interface NSObject( MulleObjCPropertyListPrinting_XML)
- (void) mullePrintXMLToStream:(id <MulleObjCOutputStream>) handle;
- (NSString *) mulleXMLDescription;
@end

@interface NSObject( MulleObjCPropertyListPrinting_XMLFuture) < MulleObjCFuture>
- (void) mullePrintXML:(struct MulleObjCPrintPlistContext *) ctxt;
@end
```

- `MulleObjCXMLParser` is a generic incremental SAX-style parser (libexpat).
  The delegate is **not retained**. `-parseData:` / `-parseBytes:length:isFinal:`
  return `YES` on success; on failure the delegate is told via
  `-parser:parseErrorOccurred:` and `NO` is returned.
- `MulleObjCExpatParser : NSObject <MulleObjCXMLParserDelegate>` builds an XML
  property list; it is normally reached through `NSPropertyListSerialization`
  (category `MulleObjCExpatParser`, implementation only) using
  `NSPropertyListXMLFormat`. Standard plist elements (`<dict>`, `<array>`,
  `<string>`, `<data>` base64, `<integer>`, `<real>`, `<true/>`, `<false/>`,
  `<date>`) are supported.
- `NSObject (MulleObjCPropertyListPrinting_XML)`: `-mullePrintXMLToStream:`,
  `-mulleXMLDescription`.

### 3.8. `MulleBase64` — Base64 codec (`src/MulleBase64/`)

```c
void     base64_encode( const unsigned char *_src,
                       size_t _srcLen,
                       unsigned char *_dest,
                       size_t *_destLen,
                       int _maxLineWidth);
int      base64_decode( const unsigned char *_src,
                       size_t _srcLen,
                       unsigned char *_dest,
                       size_t *_destLen);
size_t   base64_encoded_size( size_t _srcLen, int _maxLineWidth);
size_t   base64_decoded_maximum_size( size_t dstLen);
```

```objc
@interface NSData (Base64)
- (NSData *) base64EncodedDataWithMaxLineWidth:(NSUInteger) size;
- (NSData *) base64EncodedData;
- (NSData *) base64DecodedData;
- (NSString *) base64EncodedDescription;
- (NSString *) base64EncodedUnformattedDescription;
@end
```

- The C codec has **no bounds checking** and writes a terminating `0`; always
  size the destination with `base64_encoded_size()` (encode) or
  `base64_decoded_maximum_size()` (decode). `_maxLineWidth` must be divisible
  by 4; `0` disables wrapping. `base64_decode` returns `-1` on invalid input.
- Category defaults: `base64EncodedData` wraps at 72 chars;
  `base64DecodedData` returns nil on invalid input;
  `base64EncodedDataWithMaxLineWidth:` with `size = 0` crams the output into
  one line.

### 3.9. `MulleZlib` — DEFLATE compression (`src/MulleZlib/`)

```objc
@interface NSData( MulleZlib)
- (NSData *) mulleZlibCompressedDataWithCompressionLevel:(int) level;
- (NSData *) mulleZlibCompressedData;
- (NSData *) mulleZlibDecompressedData;
@end
```

- Output is RFC 1950 zlib-wrapped DEFLATE; `mulleZlibDecompressedData` accepts
  zlib or gzip headers and returns nil on corrupted input. Levels 0–9
  (default 6). Already-compressed data may expand.

## 4. Performance Characteristics

- **`MulleCurl` / `MulleWebClient`:** synchronous and blocking
  (`curl_easy_perform`); one request per instance at a time. O(n) in response
  size. Reuse one instance for sequential requests to benefit from keep-alive;
  no cross-instance pool. Streaming parsers keep memory near the current chunk
  size; otherwise the whole body is buffered in an `NSMutableData`.
- **`MulleJSMNParser`:** O(n) parse, O(m) memory in token count, incremental
  (can parse large documents with small fixed memory).
- **`MulleObjCXMLParser`:** streaming expat parse, O(n) time and memory
  proportional to document size. `NSPropertyListSerialization` is thread-safe;
  parser instances are not reentrant.
- **`NSURL`:** parsing is O(n) and produces "fat" objects (one `NSString` per
  component); accessors are O(1) afterwards.
- **`MulleHTTPHeaderParser`:** single pass with remembered position; not
  thread-safe. HTML escaping is linear with `bsearch` over the entity table;
  date formatting caches one `NSDateFormatter` behind an atomic CAS.
- **`MulleBase64` / `MulleZlib`:** O(n) single pass. The Base64 C layer does
  no allocation; the zlib layer uses a ~32 KB window. Base64 codecs are
  stateless/thread-safe; zlib methods allocate per call.
- **Thread-safety summary:** all networking paths are not thread-safe (one
  instance per thread). Base64 is thread-safe. `NSURL`/`NSDate`/`NSString`
  helpers are effectively stateless; `NSHost` uses internal locking (`NSLock`).

## 5. AI Usage Recommendations & Patterns

- **Best Practices**
  - Import the umbrella `<MulleWebFoundation/MulleWebFoundation.h>` (or the
    specific constituent umbrella for tighter dependencies).
  - Create objects with factory methods (`[MulleCurl object]`,
    `[MulleJSMNParser object]`, `[NSURL URLWithString:]`) — never manual
    `alloc`/`init`/`retain`/`release` in application code.
  - Always set a timeout (`[curl setDesktopTimeoutOptions]` or
    `[curl setMobileTimeoutOptions]`) so a dead server cannot hang the program.
  - Check nil returns and fetch the error via `MulleObjCExtractError()` /
    `+[NSError mulleExtract]`.
  - Install a parser with `-setParser:` before `-parseContentsOfURL...`, and
    call `-reset` on `MulleJSMNParser` between documents.
  - Pre-size Base64 buffers with the sizing helpers; the C encoder does no
    bounds checking.
- **Common Pitfalls**
  - `parseContentsOfURLWithString:` raises `NSInternalInconsistencyException`
    if no parser is set; an empty URL raises `NSInvalidArgumentException`.
  - `setOptions:` raises `NSInvalidArgumentException` for unknown `CURLOPT_*`
    names or unsupported option types — set those on `-connection` directly.
  - POST bodies go out verbatim: set `Content-Type` yourself.
  - Header keys in `setRequestHeaders:` must not contain `:`.
  - `NSURL` accessors return unescaped strings; provide already-escaped input
    to the low-level initializers or you may get nil.
  - Do not use `NSURL` for file I/O; use `NSFileManager`.
  - HTML escaping is "safe once" — do not re-escape an already-escaped string.
  - The shared `+` convenience methods on `MulleCurl` are not concurrency-safe.
- **Idiomatic Usage**
  - Raw body: `-dataWithContentsOfURLWithString:` / `+dataWithContentsOfURL:`.
  - Typed body: install `MulleJSMNParser` (JSON), `MulleHTTPHeaderParser`
    (headers) or a custom `MulleCurlParser`, then `-parseContentsOfURL...`.
  - XML plists: go through `NSPropertyListSerialization` with
    `NSPropertyListXMLFormat`, not the parser class directly.

## 6. Integration Examples

Coding style: 3-space indent, Allman braces, aligned/columnar declarations,
one variable per line, `return( expr);`, no dot-syntax, and no
`alloc`/`init`/`retain`/`release` outside `-init`/`-dealloc`.

### Example 1: One-line JSON GET via MulleWebClient

```objc
#import <MulleWebFoundation/MulleWebFoundation.h>
#include <stdio.h>

int   main( void)
{
   id        result;
   NSError   *error;

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

### Example 2: Dedicated client with incremental JSON parser

```objc
#import <MulleWebFoundation/MulleWebFoundation.h>
#include <stdio.h>

static NSString   *URL = @"https://api.github.com/users/mulle-nat/orgs";

int   main( void)
{
   MulleCurl         *curl;
   MulleJSMNParser   *parser;
   id                plist;
   NSError           *error;

   curl   = [MulleCurl object];
   parser = [MulleJSMNParser object];
   [curl setParser:parser];
   [curl setDesktopTimeoutOptions];
   [curl setRequestHeaders:@{ @"Accept": @"application/vnd.github.v3+json" }];

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

### Example 3: Base64 and zlib round-trip

```objc
#import <MulleWebFoundation/MulleWebFoundation.h>
#include <stdio.h>

int   main( void)
{
   NSData     *data;
   NSString   *base64;
   NSData     *compressed;
   NSData     *decompressed;

   data         = [NSData dataWithBytes:"The quick brown fox"
                                 length:19];
   base64       = [data base64EncodedUnformattedDescription];
   compressed   = [data mulleZlibCompressedData];
   decompressed = [compressed mulleZlibDecompressedData];

   printf( "base64: %s\n", [base64 UTF8String]);
   printf( "roundtrip: %s\n", [data isEqualToData:decompressed] ? "ok" : "FAIL");
   return( 0);
}
```

### Example 4: Parsing a URL and an XML property list

```objc
#import <MulleWebFoundation/MulleWebFoundation.h>
#include <stdio.h>

int   main( void)
{
   NSURL      *url;
   NSString   *xml;
   NSData     *xmlData;
   id         plist;
   NSError    *error;

   url = [NSURL URLWithString:@"https://user:pass@host:8080/path?query#frag"];
   if( url)
      printf( "host: %s\n", [[url host] UTF8String]);

   xml     = @"<plist version=\"1.0\"><dict><key>name</key>"
             "<string>Alice</string></dict></plist>";
   xmlData = [xml dataUsingEncoding:NSUTF8StringEncoding];
   error   = nil;
   plist   = [NSPropertyListSerialization propertyListWithData:xmlData
                                                       options:NSPropertyListImmutable
                                                        format:NULL
                                                         error:&error];
   if( error)
   {
      fprintf( stderr, "%s\n", [[error description] UTF8String]);
      return( 1);
   }

   printf( "%s\n", [[plist description] UTF8String]);
   return( 0);
}
```

## 7. Dependencies

Direct `mulle-sde` dependencies (from `.mulle/etc/sourcetree/config`):

- `MulleFoundation` — amalgamated Foundation classes used by every constituent
  (`NSString`, `NSData`, `NSDictionary`, `NSDate`, `NSError`, `NSURL`
  machinery, `NSPropertyListSerialization`, …).
- `openssl` / `ssl` / `crypto` — TLS backend for HTTPS (system OpenSSL on
  Linux, built from source 1.1.1w on Darwin).
- `curl` — external libcurl (HTTP(S) easy interface), pinned to 8.17.0.
- `expat` — XML parser used by `MulleObjCExpatFoundation`, pinned to R_2_7_1.
- `zlib` (and Darwin system `z`) — compression backend for `MulleZlib`,
  pinned to v1.3.1.2.
- Darwin-only frameworks: `CoreFoundation`, `SystemConfiguration`.

`mulle-objc-list` (renamed `mulle-objc-tools`) is a build/reflection *tool*
dependency contributed transitively by the Foundation; it is declared
`no-header, no-import, no-link` and is **not** linked into the library.

The eight constituent projects are *vendored sources of this amalgamation*,
not separate link dependencies; their public API is compiled directly into
`libMulleWebFoundation`.