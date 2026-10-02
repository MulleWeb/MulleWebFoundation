# MulleZlib Library Documentation for AI
<!-- Keywords: zlib, compression, decompression, deflate, NSData, category, version -->
## 1. Introduction & Purpose

MulleZlib adds DEFLATE compression and decompression capabilities to NSData through category methods. Wraps the zlib library for streaming data compression using industry-standard algorithm. Enables data size reduction for storage, transmission, and archival while maintaining data integrity through checksum verification.

## 2. Key Concepts & Design Philosophy

- **Category Extension**: Seamless NSData integration without subclassing
- **Zlib Wrapper**: RFC 1950 zlib format with compression headers
- **Configurable Compression**: Compression level (0-9) trade-off speed vs. ratio
- **Single-Pass API**: Simple methods for complete data compression/decompression
- **Error-Safe**: Automatic validation and corruption detection
- **Standard Algorithm**: DEFLATE algorithm (RFC 1951) widely compatible
- **Checksum Verification**: Adler-32 checksum ensures data integrity

## 3. Core API & Data Structures

### `src/MulleZlib.h`

Library entry point that any consumer must `#import`. Defines the version
macro and accessors, and exposes the `NSData( MulleZlib)` category via
`#import "NSData+MulleZlib.h"`.

#### Version API

- **Purpose:** Identifies the MulleZlib library version.
- **Key Macros / Functions:**
  - `#define MULLE_ZLIB_VERSION  ((0UL << 20) | (15 << 8) | 16)` — packed `major/minor/patch` version number.
  - `static inline unsigned int   MulleZlib_get_version_major( void)` — returns the major version (`version >> 20`).
  - `static inline unsigned int   MulleZlib_get_version_minor( void)` — returns the minor version (`(version >> 8) & 0xFFF`).
  - `static inline unsigned int   MulleZlib_get_version_patch( void)` — returns the patch version (`version & 0xFF`).
  - `extern uint32_t   MulleZlib_get_version( void);` — returns the full packed `MULLE_ZLIB_VERSION` value.

### `src/NSData+MulleZlib.h`

#### NSData (MulleZlib) Category

- **Purpose:** Extends the `NSData` objects, adding zlib (DEFLATE) compression
  and decompression without subclassing.
- **Lifecycle Functions:** No lifecycle functions are introduced. `NSData`
  instances are created/destroyed as usual (see `MulleFoundationBase`);
  each method below returns a newly allocated `NSData` result.
- **Core Operations:**
  - `- (NSData *) mulleZlibCompressedDataWithCompressionLevel:(int) level;` — compress the receiver with an explicit zlib compression level (0-9).
  - `- (NSData *) mulleZlibCompressedData;` — compress the receiver with the default compression level (6).
  - `- (NSData *) mulleZlibDecompressedData;` — decompress a zlib-compressed receiver (accepts zlib or gzip header via `inflateInit2(..., 15 + 32)`). Returns `nil` on corrupted/invalid input.

### Compression Levels

```objc
0  (Z_NO_COMPRESSION)      - No compression (store only)
1  (Z_BEST_SPEED)          - Fastest compression, worst ratio
2-6 (default is 6)         - Balanced compression
7-9                        - Best compression, slowest
9  (Z_BEST_COMPRESSION)    - Maximum compression ratio
```

Typical usage:
- **0**: Store without compression (compatibility/access patterns)
- **1-3**: Fast compression for real-time compression
- **6**: Default; good balance
- **9**: Archival; maximum compression

### Format

- **Input**: Raw binary data (NSData)
- **Output**: zlib-wrapped DEFLATE format
- **Header**: RFC 1950 zlib format (CMF + FLG + compressed data + checksum)
- **Checksum**: Adler-32 for integrity verification

## 4. Performance Characteristics

- **Compression**: O(n) where n is input size; varies by level (1-9)
- **Decompression**: O(n) independent of compression level
- **Memory**: O(k) working memory where k is window size (32KB typical)
- **Ratio**: 30-90% compression typical (depends on data type)
- **Level Impact**:
  - Level 1: ~2x speed vs. level 9, ~70% of compression ratio
  - Level 6: Optimal balance; recommended default
  - Level 9: ~10x slower than level 1, ~5% better ratio
- **Incompressible Data**: Might expand (adds 18-byte overhead minimum)

## 5. AI Usage Recommendations & Patterns

### Best Practices

- **Network Transfer**: Compress before transmission; typical 50-80% reduction
- **Storage**: Use level 6-9 for archival; level 1-3 for real-time
- **Cache Invalidation**: Compressed data should be versioned
- **Error Handling**: Verify decompressed size matches expected
- **Streaming**: For large data, consider streaming compression APIs
- **Compatibility**: Zlib format widely supported; safe for interchange
- **Measure**: Verify compression actually reduces size for your data type

### Common Pitfalls

- **Text vs. Binary**: Text compresses well; already-compressed data (jpeg, mp3) won't benefit
- **Expansion on Incompressible**: Small incompressible data may expand
- **Memory Overhead**: Large data requires large working buffers
- **Level Confusion**: Default (6) good; don't assume higher is always better
- **Partial Decompression**: Can't decompress part of stream; need full stream
- **Format Incompatibility**: Don't confuse with gzip (different header) or raw DEFLATE
- **Checksum Mismatch**: Corrupted data detected on decompression (exception/error)

### Idiomatic Usage

```objc
// The "mulle-sde way" - as in test/simple/simple.m and the README.
// Create data, compress, decompress, and verify the round-trip:

static char   longtext[] = "Compression and decompression of NSData.";

NSData        *data;
NSData        *compressed;
NSData        *decompressed;

data         = [NSData dataWithBytes:longtext
                         length:sizeof( longtext)];
compressed   = [data mulleZlibCompressedData];        // default level 6
decompressed = [compressed mulleZlibDecompressedData];
if( ! [data isEqualToData:decompressed])
   mulle_printf( "CORRUPTION FAIL\n");
```

## 6. Integration Examples

### Example 1: Basic Compression and Decompression

```objc
#import <MulleZlib/MulleZlib.h>

// modeled after test/simple/simple.m
void  check( char *s, size_t len)
{
   NSData   *data;
   NSData   *compressed;
   NSData   *decompressed;

   data         = [NSData dataWithBytes:s
                                   length:len];
   compressed   = [data mulleZlibCompressedData];
   if( ! compressed && len)
      mulle_printf( "COMPRESSION FAIL\n");
   decompressed = [compressed mulleZlibDecompressedData];
   if( ! decompressed && len)
      mulle_printf( "DECOMPRESSION FAIL\n");
   if( ! [data isEqualToData:decompressed])
      mulle_printf( "CORRUPTION FAIL\n");
}


int  main( void)
{
   check( "The quick brown fox jumps over the lazy dog", 44);
   return( 0);
}
```

### Example 2: Compression Level Comparison

```objc
#import <MulleZlib/MulleZlib.h>

int main() {
    NSMutableString *data = [NSMutableString string];
    for (int i = 0; i < 1000; i++) {
        [data appendString:@"Lorem ipsum dolor sit amet consectetur adipiscing elit. "];
    }
    
    NSData *original = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Original size: %lu bytes\n", [original length]);
    
    // Test different compression levels
    int levels[] = {0, 1, 3, 6, 9};
    for (int i = 0; i < 5; i++) {
        NSData *compressed = [original mulleZlibCompressedDataWithCompressionLevel:levels[i]];
        float ratio = [compressed length] / (float)[original length];
        NSLog(@"Level %d: %lu bytes (%.1f%%)", 
              levels[i], [compressed length], ratio * 100);
    }
    
    return 0;
}
```

### Example 3: Compressing File Data

```objc
#import <MulleZlib/MulleZlib.h>

int main() {
    NSString *filePath = @"/tmp/large_file.txt";
    
    // Read file
    NSError *error = nil;
    NSData *fileData = [NSData dataWithContentsOfFile:filePath 
                                              options:0 
                                                error:&error];
    if (error) {
        NSLog(@"Error reading file: %@", error);
        return 1;
    }
    
    // Compress
    NSData *compressed = [fileData mulleZlibCompressedData];
    
    NSString *compressedPath = @"/tmp/large_file.txt.zlib";
    [compressed writeToFile:compressedPath atomically:YES];
    
    float ratio = [compressed length] / (float)[fileData length];
    NSLog(@"Compressed: %.1f%% of original", ratio * 100);
    NSLog(@"Saved to: %@", compressedPath);
    
    return 0;
}
```

### Example 4: Decompressing Received Data

```objc
#import <MulleZlib/MulleZlib.h>

int main() {
    // Simulate receiving compressed data from network
    NSString *original = @"Server response data";
    NSData *responseData = [original dataUsingEncoding:NSUTF8StringEncoding];
    NSData *received = [responseData mulleZlibCompressedData];
    
    NSLog(@"Received %lu bytes (compressed)", [received length]);
    
    // Decompress
    NSError *error = nil;
    NSData *decompressed = [received mulleZlibDecompressedData];
    
    NSString *response = [[NSString alloc] initWithData:decompressed 
                                               encoding:NSUTF8StringEncoding];
    NSLog(@"Response: %@", response);
    
    [response release];
    return 0;
}
```

### Example 5: Storage with Compression

```objc
#import <MulleZlib/MulleZlib.h>

int main() {
    NSMutableArray *records = [NSMutableArray array];
    
    // Create large dataset
    for (int i = 0; i < 1000; i++) {
        NSDictionary *record = @{
            @"id": [NSNumber numberWithInt:i],
            @"name": [NSString stringWithFormat:@"Record_%d", i],
            @"data": @"Some associated data content"
        };
        [records addObject:record];
    }
    
    // Serialize to plist
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization 
        dataWithPropertyList:records
                     format:NSPropertyListBinaryFormat
                    options:0
                      error:&error];
    
    if (!error) {
        // Store compressed
        NSData *compressed = [plistData mulleZlibCompressedDataWithCompressionLevel:9];
        [compressed writeToFile:@"/tmp/records.zlib" atomically:YES];
        
        float ratio = [compressed length] / (float)[plistData length];
        NSLog(@"Stored %lu records (%.1f%% of original)", [records count], ratio * 100);
    }
    
    return 0;
}
```

### Example 6: Compression Effectiveness Testing

```objc
#import <MulleZlib/MulleZlib.h>

int main() {
    // Test various data types
    struct {
        NSString *name;
        NSData *data;
    } tests[] = {
        {
            @"Repetitive text",
            [@"AAAA" dataUsingEncoding:NSUTF8StringEncoding]
        },
        {
            @"Random binary",
            [NSData dataWithBytes:(char[]){0xFF, 0xFE, 0xFD, 0xFC} length:4]
        },
        {
            @"JSON data",
            [@"{\"key\":\"value\",\"count\":123}" dataUsingEncoding:NSUTF8StringEncoding]
        }
    };
    
    NSLog(@"Compression effectiveness:\n");
    for (int i = 0; i < 3; i++) {
        NSData *original = tests[i].data;
        NSData *compressed = [original mulleZlibCompressedData];
        float ratio = [compressed length] / (float)[original length];
        NSLog(@"%@: %lu → %lu bytes (%.1f%%)", 
              tests[i].name, [original length], [compressed length], ratio * 100);
    }
    
    return 0;
}
```

### Example 7: Error Detection via Decompression

```objc
#import <MulleZlib/MulleZlib.h>

int main() {
    NSData *original = [@"Data to compress" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *compressed = [original mulleZlibCompressedData];
    
    // Simulate data corruption
    NSMutableData *corrupted = [NSMutableData dataWithData:compressed];
    if ([corrupted length] > 10) {
        unsigned char *bytes = (unsigned char *)[corrupted mutableBytes];
        bytes[5] ^= 0xFF;  // Flip bits
    }
    
    // Try to decompress corrupted data
    NSData *decompressed = [corrupted mulleZlibDecompressedData];
    
    if (!decompressed) {
        NSLog(@"✓ Corruption detected!");
    } else if (![decompressed isEqual:original]) {
        NSLog(@"✓ Data mismatch detected!");
    } else {
        NSLog(@"✗ Corruption not detected (unlikely)");
    }
    
    return 0;
}
```

### Example 8: Batch Compression

```objc
#import <MulleZlib/MulleZlib.h>

int main() {
    NSArray *files = @[@"file1.txt", @"file2.txt", @"file3.txt"];
    NSMutableArray *compressed = [NSMutableArray array];
    
    for (NSString *filename in files) {
        NSData *data = [NSData dataWithContentsOfFile:
            [NSString stringWithFormat:@"/tmp/%@", filename]];
        
        if (data) {
            NSData *cdata = [data mulleZlibCompressedDataWithCompressionLevel:6];
            NSDictionary *entry = @{
                @"filename": filename,
                @"original": [NSNumber numberWithUnsignedInteger:[data length]],
                @"compressed": [NSNumber numberWithUnsignedInteger:[cdata length]]
            };
            [compressed addObject:entry];
        }
    }
    
    NSLog(@"Compression summary: %@", compressed);
    
    return 0;
}
```

## 7. Dependencies

Direct `mulle-sde` dependencies (from `.mulle/etc/sourcetree/config`):

- `zlib` — the underlying compression library (C library, `zlib.h`; on Darwin the system `z` via a node is used instead)
- `MulleFoundationBase` — amalgamates the foundation libraries and provides `NSData`/`NSMutableData` and the `mulle_allocator`
- `mulle-objc-list` — lists mulle-objc runtime information (no header, no link; not exposed in the public API)
- `craftinfo/zlib-craftinfo` — local craft information node for building zlib with `mulle-sde`
