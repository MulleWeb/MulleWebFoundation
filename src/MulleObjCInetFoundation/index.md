# MulleObjCInetFoundation Library Documentation for AI
<!-- Keywords: NSURL, NSHost, URL, percent-escape, charset, scheme, ObjectiveC -->

## 1. Introduction & Purpose

- MulleObjCInetFoundation provides Internet-related Objective‑C classes for mulle-objc: primarily NSURL and NSHost plus URL-related character-set helpers and scheme handler support.
- Solves URL parsing, percent-escape handling, and exposes convenient accessors (scheme, user, host, port, path, query, fragment, resourceSpecifier).
- Key features: percent-escaped internal storage, UTF8-based init helpers, pluggable scheme handlers, and URL character-set helpers for encoding/decoding.
- Relationship: builds on Mulle Foundation pieces (MulleFoundationBase) and integrates with the mulle-objc ecosystem.

## 2. Key Concepts & Design Philosophy

- URLs are stored internally as percent-escaped strings for correctness; accessors return unescaped NSStrings unless documented otherwise.
- Emphasis on validation and conservative parsing: malformed input can produce nil objects.
- Not intended as a thin string wrapper for file I/O; NSFileManager is recommended for file operations.
- Extensible scheme handlers: callers can register handlers for custom schemes (init/print hooks).
- Character-set oriented API: provides reusable character sets for allowed URL fragments, hosts, queries, etc., to centralize percent-encoding logic.

## 3. Core API & Data Structures

### 3.1. [NSURL.h]

#### struct MulleEscapedURLPartsUTF8
- Purpose: hold percent-escaped UTF8 parts for low-level initialization.
- Key Fields: scheme, escaped_user, escaped_password, escaped_host, port, escaped_path, escaped_parameter, escaped_query, escaped_fragment, validated.
- Usage: passed into `-mulleInitWithEscapedURLPartsUTF8:allowedURICharacterSet:` when parts are already escaped.

#### struct MulleURLSchemeHandler
- Purpose: Register custom scheme behavior.
- Key Fields: SEL initURL; SEL printURL; SEL printResourceSpecifier;
- Use: pass handler plus scheme string to `+mulleRegisterHandler:forScheme:`.

#### struct MulleURLSchemeInitArguments
- Purpose: argument bundle handed to a scheme handler's `initURL` selector.
- Key Fields: scheme (`struct MulleCharData`); uri (`struct MulleCharData`).
- Use: e.g. consumed by the file-scheme handler (`mulleInitFileURLWithArguments:`) in NSURL+File.m.

#### NSURL (class)
- Purpose: Represent and parse URL strings; provide component accessors.
- Lifecycle Functions:
  - +URLWithString:(NSString *)s
   - -initWithString:(NSString *)URLString
   - +URLWithString:relativeToURL:
   - -initWithString:relativeToURL:
   - -initWithScheme:host:path:  (percent-encodes host/path automatically)
   - -mulleInitWithUTF8Characters:length:
   - -mulleInitWithEscapedURLPartsUTF8:allowedURICharacterSet:
   - -mulleInitResourceSpecifierWithUTF8Characters:length:
   - -mulleInitWithSchemeUTF8Characters:length:resourceSpecifierUTF8Characters:length: (for civetweb)
   - +mulleURLEscapedAllowedCharacterSet (non-restrictive charset for ResourceSpecifier)
- Core Operations / Accessors:
  - -scheme -> NSString * (unescaped)
  - -user -> NSString *
  - -password -> NSString *
  - -host -> NSString *
  - -port -> NSNumber *
  - -path -> NSString *
  - -parameterString -> NSString *
  - -query -> NSString *
  - -fragment -> NSString *
  - -resourceSpecifier -> NSString *
  - -stringValue / -description -> NSString * (description includes percent escapes)
  - -URLByAppendingPathComponent:(NSString *)component
- Scheme handler support:
  - +mulleRegisterHandler:forScheme:
  - Default helpers: -mulleGenericResourceSpecifierDescription, -mulleGenericURLDescription, -mulleIsAbsolutePath, -mulleEscapedResourceSpecifier
- Legacy API (present but not preferred): -isFileURL, -standardizedURL, -absoluteString, -relativePath, -pathComponents, -lastPathComponent, -pathExtension, etc.

### 3.2. [NSHost.h]
- Purpose: Represent host information (names and addresses); lookup is lazy and needs a resolver library to be useful.
- Key Fields: internal lock; properties: names (NSArray, copy), addresses (NSArray, copy), _IP6 (BOOL), _isCurrentHost (BOOL).
- Lifecycle:
  - -initWithNames:count:addresses:count:
  - +hostWithName:, +hostWithAddress:
- Operations:
  - -isEqualToHost:
  - -name
  - -address
  - +currentHost and -localizedName (future extension)

### 3.3. [NSString+MulleURL.h]
- Helpers for percent-encoding/decoding:
  - -stringByAddingPercentEscapesUsingEncoding:
  - -stringByReplacingPercentEscapesUsingEncoding:
- Purpose: compatibility helpers commonly used before constructing NSURL objects.

### 3.4. [NSCharacterSet+MulleURL.h] and NSMutableCharacterSet category
- Purpose: Provide standard character sets used in URL encoding/decoding.
- Key Class Methods:
  - +URLFragmentAllowedCharacterSet
  - +URLHostAllowedCharacterSet
  - +URLPasswordAllowedCharacterSet
  - +URLPathAllowedCharacterSet
  - +URLQueryAllowedCharacterSet
  - +URLUserAllowedCharacterSet
  - +mulleURLAllowedCharacterSet
  - +mulleURLSchemeAllowedCharacterSet
  - +mulleNonPercentEscapeCharacterSet
- Use: pass the appropriate allowed character set into low-level init APIs that accept allowedURICharacterSet.

### 3.5. Other headers
- MulleObjCInetFoundation.h: version macro and exports; include this to import the public surface.
- Misc reflect/generic headers: build-time include wrappers (not part of runtime API surface).

## 4. Performance Characteristics

- NSURL objects are "fat": parsing creates separate NSStrings for many components (scheme/user/password/host/path/etc.). Memory > thin NSString-based representations.
- Typical operations (accessors) are effectively O(1) after parse; parsing on creation is O(n) in URL length.
- URLByAppendingPathComponent performs a copy and simple concatenation (O(len(component))).
- Thread-safety:
  - Instances are not documented as fully thread-safe; NSHost uses internal locking for lazy behavior but general safety requires external synchronization for concurrent mutation.
- Trade-offs: correctness and convenience (unescaped accessors) favored over minimal memory footprint.

## 5. AI Usage Recommendations & Patterns

- Best Practices:
  - Prefer +URLWithString: / -initWithString: for typical use. Provide already percent-escaped strings to low-level initializers when available.
  - Use NSCharacterSet+MulleURL helpers to determine which characters need escaping.
  - Use -description or -stringValue for a percent-escaped textual URL representation.
  - For file access, prefer NSFileManager over NSURL-specific file methods in this library.
- Common Pitfalls:
  - Passing unescaped strings to methods that expect escaped input can yield nil or malformed results.
  - Do not assume baseURL merging semantics like Apple's NSURL; this implementation may create a single new URL rather than marry base/self.
  - Be aware that accessors return unescaped NSStrings; if you need escaped forms call -description or use escaped-specific APIs.
- Idiomatic usage in mulle-sde environment: construct URLs with +URLWithString:, validate result, then inspect components. Use mulleInit... UTF8 variants when interoperating with C/UTF8 buffers.

## 6. Integration Examples

### Example 1: Creating and Inspecting a URL

```c
// Objective-C, compile as a simple test program
#import <MulleObjCInetFoundation/MulleObjCInetFoundation.h>

static void
print_url( NSURL  *url)
{
   char  *s;

   printf( "Scheme: %s\n", (s = [[url scheme] UTF8String]) ? s : "*nil*");
   printf( "Host  : %s\n", (s = [[url host] UTF8String]) ? s : "*nil*");
   printf( "Path  : %s\n", (s = [[url path] UTF8String]) ? s : "*nil*");
}

int
main( void)
{
   NSURL   *url;

   url = [NSURL URLWithString:@"https://user:pass@host:8080/path?query#frag"];
   if( url)
   {
      print_url( url);
      printf( "Full: %s\n", [[url description] UTF8String]);
   }
   return( 0);
}
```

### Example 2: Using Allowed Character Sets

```c
#import <MulleObjCInetFoundation/MulleObjCInetFoundation.h>

int
main( void)
{
   NSCharacterSet  *set;
   NSString        *escaped;

   set     = [NSCharacterSet URLPathAllowedCharacterSet];
   escaped = [[@"/foo bar/baz" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                 stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
   // Use escaped /path in low-level init when appropriate
   return( 0);
}
```

## 7. Dependencies

- MulleFoundationBase (amalgamated Mulle Foundation pieces)
- mulle-objc-list (runtime introspection helpers)
- mulle-c11 (platform C support)


---

Notes for AIs:
- Primary API surfaces are in src/NSURL.h and src/NSHost.h; tests under test/NSURL demonstrate common usage. Use the character-set helpers when performing percent-encoding. When in doubt, parse a URL using +URLWithString: and inspect components via provided accessors.
