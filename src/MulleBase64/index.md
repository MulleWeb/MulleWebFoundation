# MulleBase64 Library Documentation for AI
<!-- Keywords: base64, encode, decode, NSData, NSString, data, RFC4648 -->
## 1. Introduction & Purpose

**MulleBase64** adds [Base64](https://en.wikipedia.org/wiki/Base64) encoding and decoding to binary data handled as **NSData**. It provides two layers:

1. A small, allocation-free C codec (`base64.h`) implementing RFC 4648 Base64 with optional MIME-style line wrapping.
2. An Objective-C category `NSData (Base64)` that adapts the C codec to `NSData`/`NSString`, adding formatted and unformatted encodings plus a lenient decoder.

It solves the problem of safely representing arbitrary binary data (images, tokens, API payloads, email attachments) using 64 printable ASCII characters for transport over text-based protocols and inclusion in JSON, XML, HTTP headers, and data URLs. The C layer has **no memory allocation and no bounds checking**; the caller is responsible for providing a correctly sized destination buffer. The category layer performs that sizing automatically for you.

A foundational part of the `MulleWeb` project family; the Objective-C layer depends on `MulleFoundationBase` (NSData, NSString, NSMutableData).

## 2. Key Concepts & Design Philosophy

- **Two-layer design:** The verbatim public C codec (`base64.h`) is the source of truth; the `NSData (Base64)` category is a thin adapter that sizes buffers via the size helper functions and converts the ASCII result to `NSData`/`NSString`.
- **Caller-managed buffers:** `base64_encode` writes into a caller-supplied `unsigned char *_dest` and terminates the output with a `0` byte. There is deliberately **no bounds checking** (the `_destSize` parameter was removed for speed). Always pre-size with `base64_encoded_size()`.
- **Line wrapping:** `_maxLineWidth` inserts `'\n'` linefeeds every N output characters. It **must be divisible by 4** (the code does not enforce this). `0` means "no line breaks". The default MIME wrapping used by the category is 72 characters (RFC 2045).
- **Lenient decoding:** `base64_decode` ignores whitespace characters (CR, LF, SP, HT), terminates input at an `'='` padding character, and flags (but skips) any non-alphabet, non-whitespace character by returning `-1`. It never throws.
- **Standard alphabet:** Standard RFC 4648 alphabet `A-Z a-z 0-9 + /` with `=` padding for the final 1- or 2-byte chunk.

## 3. Core API & Data Structures

### 3.1. `src/base64.h` — C codec (original code by Helge Hess, used with permission)

Standalone functions, no structs. All operate on caller-provided buffers.

#### Sizing helpers (O(1))

```c
size_t   base64_encoded_size( size_t _srcLen,
                             int _maxLineWidth);
```
- **Purpose:** Exact size in bytes of the destination buffer needed for encoding `_srcLen` bytes. Includes the terminating `0` and the `'\n'` linefeeds introduced by a non-zero `_maxLineWidth`.
- **Return:** `outs * 4 + extra` bytes, where `outs = (_srcLen / 3) + ((_srcLen % 3) ? 1 : 0)` and `extra = 1 + ((_maxLineWidth) ? (_srcLen/3*4)/_maxLineWidth : 0)`.

```c
size_t   base64_decoded_maximum_size( size_t dstLen);
```
- **Purpose:** Upper bound on decoded output bytes for an input of `dstLen` encoded bytes (worst case: a line of encoded chars with no linefeeds/whitespace).
- **Return:** `(inLen + 3) / 4 * 3`.

#### Encoding

```c
void   base64_encode( const unsigned char *_src,
                     size_t _srcLen, 
                     unsigned char *_dest,
                     size_t *_destLen,
                     int _maxLineWidth);
```
- **Purpose:** Encodes `_srcLen` bytes from `_src` into `_dest` using the standard Base64 alphabet with `=` padding for the final chunk.
- **`_dest`:** Must hold at least `base64_encoded_size(_srcLen, _maxLineWidth)` bytes. A terminating `0` is written *after* the encoded data.
- **`_destLen`:** On return, set to the number of encoded bytes written (excluding the terminating `0`).
- **`_maxLineWidth`:** Insert a `'\n'` after every `_maxLineWidth` output characters; `0` disables wrapping. Must be divisible by 4.

#### Decoding

```c
int   base64_decode( const unsigned char *_src, 
                     size_t _srcLen, 
                     unsigned char *_dest,
                     size_t *_destLen);
```
- **Purpose:** Decodes Base64 input back to raw bytes.
- **`_dest`:** Should be sized `base64_decoded_maximum_size(_srcLen)`.
- **`_destLen`:** On return, set to the actual number of decoded bytes.
- **Return:** `0` on success, `-1` if the input contained an invalid (non-base64, non-whitespace, non-`=`) character. Whitespace (CR/LF/SP/HT) is ignored; input terminates at an `'='`.

### 3.2. `src/MulleBase64.h` — version

```c
#define MULLE_BASE64_VERSION  ((0UL << 20) | (1 << 8) | 2)
```
- Encoded as `(major << 20) | (minor << 8) | patch`, i.e. version **0.1.2**.

```c
static inline unsigned int   MulleBase64_get_version_major( void)
static inline unsigned int   MulleBase64_get_version_minor( void)
static inline unsigned int   MulleBase64_get_version_patch( void)
extern uint32_t   MulleBase64_get_version( void);
```
- Returns the major/minor/patch components and the full packed `MULLE_BASE64_VERSION` value respectively. `MulleBase64_get_version()` is defined in `src/MulleBase64.m`.

### 3.3. `src/NSData+Base64.h` — Objective-C category `NSData (Base64)`

Imported automatically by `MulleBase64.h`. Adapts the C codec to `NSData`. All methods return new (owned-by-autorelease-scope) objects.

- `- (NSData *) base64EncodedDataWithMaxLineWidth:(NSUInteger) size;`
  - Encode the receiver as Base64 into a new `NSData`. `size` is the line width in characters; **use `size = 0` to cram it all into a single line** (per the header comment). Sizes the buffer with `base64_encoded_size`, encodes, then truncates the result with `setLength`.
- `- (NSData *) base64EncodedData;`
  - Same as `base64EncodedDataWithMaxLineWidth:72` (the standard MIME width). If the encoded output length ever exceeded the precomputed buffer size, the code aborts (should not happen).
- `- (NSData *) base64DecodedData;`
  - Decode the receiver back to raw bytes in a new `NSData`. Allocates `base64_decoded_maximum_size` and returns `nil` if the C decoder reports an error (`-1`). Accepts both formatted (line-wrapped) and unformatted input.
- `- (NSString *) base64EncodedDescription;`
  - Returns a formatted (72-char wrapped) Base64 representation as an ASCII (`NSASCIIStringEncoding`) `NSString`. Returns `nil` on failure.
- `- (NSString *) base64EncodedUnformattedDescription;`
  - Returns a single-line (no line breaks) Base64 representation as an ASCII `NSString`.

Implementation notes (from `NSData+Base64.m`): the category methods use `[self length]` and `[self bytes]` to obtain the input, and `[NSMutableData dataWithLength:...]` / `[data mutableBytes]` / `[data setLength:...]` for the output.

## 4. Performance Characteristics

- **Encoding/decoding:** O(n) single pass with direct table lookups (`base64tab`, `base64idx`), no branches except chunk-tail handling.
- **Sizing helpers:** O(1).
- **Memory:** The C layer performs *no allocation* — speed and determinism at the cost of caller responsibility. Output expansion ratio is 4/3 (encode); decoded size is at most `(in+3)/4*3`.
- **Line wrapping:** Negligible overhead; breaks occur inline as output is produced. Note the code comment `_maxLineWidth must be divisible by 4`.
- **Errors:** Decode cost is O(n) even for invalid input; an invalid character sets an error flag and is skipped, with `-1` returned at the end.
- **Thread safety:** The codecs are stateless (only read-only static lookup tables are mutated never), so they are thread-safe without external locking.

## 5. AI Usage Recommendations & Patterns

- **Always size the encode destination with `base64_encoded_size`** — `base64_encode` has no bounds checking and writes a trailing `0`, so an undersized buffer overflows silently.
- **For decode, allocate `base64_decoded_maximum_size(srcLen)`** and read the actual byte count from `*_destLen` afterwards; do not assume the whole buffer was filled.
- **Check the decode return value** — it is `-1` on input errors; there is no exception mechanism.
- **Use `_maxLineWidth = 0` for unformatted output** and a multiple of 4 (e.g. 72) for MIME-style wrapped output. Cross-checking an encoded value against an expected single-line string will fail if you used the wrapped form.
- **Prefer the `NSData (Base64)` category methods** when dealing with `NSData`/`NSString`; they handle sizing and length truncation for you. Use the raw C functions only for buffer-level work.
- **Pitfall:** `base64DecodedData` returns `nil` on invalid input — treat a `nil` result as a validation failure, not a bug.

## 6. Integration Examples

### Example 1: Encoding raw bytes (C layer)

```c
#include "base64.h"

#define SRC_LEN      5
#define LINE_WIDTH   0


int   main( void)
{
   unsigned char   src[ SRC_LEN] = { 'H', 'e', 'l', 'l', 'o' };
   unsigned char   dst[ 32];
   size_t          dstLen;

   dstLen = base64_encoded_size( SRC_LEN, LINE_WIDTH);
   // dstLen == 9 : 8 encoded chars + terminating 0
   base64_encode( src, SRC_LEN, dst, &dstLen, LINE_WIDTH);

   // base64_encode has already written the terminating 0 after dstLen chars
   printf( "%s\n", dst);   /* => SGVsbG8= */
   return( 0);
}
```

### Example 2: Decoding with validation (C layer)

```c
#include "base64.h"

int   decodeInput( const unsigned char *encoded, size_t encodedLen)
{
   unsigned char   *decoded;
   size_t          decodedLen;
   size_t          maximumLen;
   int             rc;

   maximumLen = base64_decoded_maximum_size( encodedLen);
   decoded    = malloc( maximumLen);
   if( ! decoded)
      return( -1);

   rc         = base64_decode( encoded, encodedLen, decoded, &decodedLen);
   if( rc == 0 && decodedLen <= maximumLen)
      printf( "%zu bytes decoded\n", decodedLen);

   free( decoded);
   return( rc);
}
```

### Example 3: NSData round-trip via the category (Objective-C)

```objc
#import "MulleBase64.h"


int   main( void)
{
   NSData    *data;
   NSData    *encoded;
   NSData    *decoded;
   NSString  *oneLiner;

   // dataWithBytes is provided by MulleFoundationBase (NSData)
   data    = [NSData dataWithBytes:"Hello" length:5];
   encoded = [data base64EncodedData];                 // wrapped at 72 chars
   oneLiner = [data base64EncodedUnformattedDescription]; // single-line ASCII

   printf( "%s\n", [oneLiner UTF8String]);             // => SGVsbG8=

   decoded = [encoded base64DecodedData];
   if( decoded)
      printf( "decoded %lu bytes\n", [decoded length]);

   return( 0);
}
```

## 7. Dependencies

Direct `mulle-sde` dependencies (from `.mulle/etc/sourcetree/config` and `clib.json`):

- `MulleFoundationBase` — provides the `NSData`, `NSMutableData`, and `NSString` classes used by the Objective-C category.
- `mulle-objc-list` — runtime object-conversion info for executables; declared `no-header, no-import, no-link`, so it is **not** linked into the library itself.
- The ObjC runtime reachable through the `MulleFoundationBase` amalgamation.