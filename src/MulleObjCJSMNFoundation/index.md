# MulleObjCJSMNFoundation Library Documentation for AI

## 1. Introduction & Purpose

**MulleObjCJSMNFoundation** provides JSON parsing for Objective-C via JSMN (Jansson-inspired Minimal JSON parser). It enables parsing JSON into Foundation objects (NSDictionary, NSArray, NSString, NSNumber) with support for streaming/incremental parsing ideal for large JSON documents or real-time data feeds.

This library is particularly useful for:
- Parsing JSON API responses
- Processing large JSON files without loading entirely into memory
- Streaming JSON from network connections
- Building JSON-based REST clients
- Real-time JSON data processing
- Cross-platform JSON handling

## 2. Key Concepts & Design Philosophy

- **JSMN-Based**: Uses high-performance JSMN C parser under the hood
- **Incremental Parsing**: Parse JSON data in chunks; useful for streams
- **Minimal Memory**: Only allocates tokens as needed
- **Error Recovery**: Handles incomplete JSON gracefully
- **Standard Conversion**: Automatic conversion to Foundation types
- **Flexible Options**: Control parsing behavior via properties

## 3. Core API & Data Structures

### Main Parser: `MulleJSMNParser`

#### Properties

- `@property (getter=isIncomplete) BOOL incomplete`
  - YES if JSON parsing is incomplete (more data expected)
  - Useful for detecting incomplete documents in streams
  - Check this when `parseData:` returns nil

- `@property BOOL trueFalseAsStrings`
  - If YES: `true` and `false` become NSString
  - If NO: Become NSNumber with 1 and 0 (default)
  - Useful for preserving JSON boolean semantics

- `@property (retain) id userInfo`
  - Arbitrary user data available during parsing
  - Cleared on `-reset`

- `@property (retain) id object`
  - Last parsed object result
  - Same as return value from most recent `parseData:` or `parseBytes:`

#### Core Methods

- `- (id) parseData:(NSData *)data` → `id`
  - Parse JSON from NSData
  - Returns NSDictionary, NSArray, NSString, NSNumber, or nil
  - Can be called incrementally: check `isIncomplete` after nil return
  - Already-parsed data is not re-parsed on subsequent calls
  - **Use case**: Complete JSON parsing

- `- (id) parseBytes:(void *)bytes length:(NSUInteger)length` → `id`
  - Parse JSON from raw bytes
  - Returns same types as `parseData:`
  - Must pass complete JSON chunks for incremental parsing
  - **Example**: Incrementally parse `"{"` then `"}"` doesn't work; pass `"{"` then `"{}"` 
  - **Use case**: Low-level streaming from network sockets

#### Utilities

- `- (void) reset`
  - Reset parser state and clear user data
  - Clears `userInfo` and `object` properties
  - Allows reuse for next JSON document
  - Required between parsing different JSON documents

- `- (NSError *) errorWithName:(NSString *)name bytes:(void *)bytes length:(NSUInteger)length range:(NSRange)range` → `NSError *`
  - Generate NSError for parse failures
  - Internal use; called automatically on errors
  - For custom error reporting

### NSString Extension: `NSString (MulleJSMNParser)`

- `- (id) mulleJSON` → `id`
  - Convenience method: parse receiver as JSON
  - Equivalent to creating parser and calling `parseData:`
  - Returns parsed object or nil on error
  - **Use case**: One-line JSON parsing

## 4. Performance Characteristics

- **Parsing**: O(n) where n = JSON length; typical: 10-100 MB/s
- **Memory**: O(m) where m = token count (not full document)
- **Streaming**: Incremental; can parse huge documents with small fixed memory
- **Token Allocation**: Dynamic; grows as needed
- **Typical**: < 10ms for 1 MB JSON on modern hardware

## 5. AI Usage Recommendations & Patterns

### Pattern 1: Simple JSON Parsing
Convert JSON string to objects:

```objc
NSString *jsonString = @"{\"name\": \"Alice\", \"age\": 30}";
NSDictionary *dict = [jsonString mulleJSON];
// dict: @{@"name": @"Alice", @"age": @30}
```

### Pattern 2: Parse with Custom Parser
Reusable parser instance:

```objc
MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];
NSDictionary *result1 = [parser parseData:jsonData1];
[parser reset];
NSDictionary *result2 = [parser parseData:jsonData2];
```

### Pattern 3: Incremental Streaming
Parse JSON from network stream:

```objc
MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];

// Receive chunks from network
NSData *chunk1 = /* network data */;
id result = [parser parseData:chunk1];

if (result == nil && [parser isIncomplete]) {
    // More data expected
    NSData *chunk2 = /* more network data */;
    result = [parser parseData:chunk2];
}

if (result) {
    NSLog(@"Parsed: %@", result);
}
```

### Pattern 4: JSONL (JSON Lines) Processing
Parse stream of JSON objects:

```objc
NSArray *jsonLines = @[
    @"{\"id\": 1, \"name\": \"Alice\"}",
    @"{\"id\": 2, \"name\": \"Bob\"}",
    @"{\"id\": 3, \"name\": \"Charlie\"}"
];

MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];
NSMutableArray *results = [NSMutableArray array];

for (NSString *line in jsonLines) {
    NSDictionary *obj = [parser parseData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    if (obj) {
        [results addObject:obj];
        [parser reset];
    }
}
```

### Pattern 5: Error Handling
Graceful JSON parsing with error info:

```objc
MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];
NSDictionary *result = [parser parseData:jsonData];

if (!result) {
    if ([parser isIncomplete]) {
        NSLog(@"Incomplete JSON; more data needed");
    } else {
        NSLog(@"Parse error");
    }
}
```

### Pattern 6: Boolean Handling Control
Choose JSON boolean representation:

```objc
MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];
parser.trueFalseAsStrings = YES;  // true/false as @"true"/@"false"

NSDictionary *obj = [parser parseData:@"{\"active\": true}".dataUsingEncoding:NSUTF8StringEncoding];
// obj[@"active"] is @"true" instead of @1
```

### Common Pitfalls
- **Double parsing**: Don't re-parse already-parsed chunks incrementally
- **Not resetting**: Must call `-reset` between different JSON documents
- **Assuming completion**: Always check `isIncomplete` when parse returns nil
- **Network buffering**: Network chunks may split JSON; use larger buffers
- **Memory growth**: Very large JSON documents can require many tokens

## 6. Integration Examples

### Example 1: REST API Response Parsing
```objc
@interface APIClient : NSObject
- (NSDictionary *) fetchUserWithID:(NSString *)userID;
@end

@implementation APIClient
- (NSDictionary *) fetchUserWithID:(NSString *)userID {
    MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];
    
    NSURL *url = [NSURL URLWithString:
        [NSString stringWithFormat:@"http://api.example.com/users/%@", userID]];
    NSData *jsonData = [NSData dataWithContentsOfURL:url];
    
    return [parser parseData:jsonData];
}
@end
```

### Example 2: Streaming JSON from Network
```objc
@interface StreamingJSONReceiver : NSObject
- (void) receiveJSONStream:(NSInputStream *)stream;
@end

@implementation StreamingJSONReceiver
- (void) receiveJSONStream:(NSInputStream *)stream {
    MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];
    NSMutableData *buffer = [NSMutableData data];
    
    uint8_t readBuffer[1024];
    NSInteger bytesRead;
    
    while ((bytesRead = [stream read:readBuffer maxLength:sizeof(readBuffer)]) > 0) {
        [buffer appendBytes:readBuffer length:bytesRead];
        
        id parsed = [parser parseData:buffer];
        if (parsed) {
            NSLog(@"Received JSON object: %@", parsed);
            [parser reset];
            [buffer setLength:0];
        } else if (![parser isIncomplete]) {
            NSLog(@"JSON parse error");
            break;
        }
    }
}
@end
```

### Example 3: Array of JSON Objects
```objc
NSString *jsonString = @"[{\"id\": 1, \"name\": \"Alice\"}, {\"id\": 2, \"name\": \"Bob\"}]";
NSArray *users = [jsonString mulleJSON];

for (NSDictionary *user in users) {
    NSLog(@"User: %@ (ID: %@)", user[@"name"], user[@"id"]);
}
```

### Example 4: Nested JSON Parsing
```objc
NSString *jsonString = @"{\"user\": {\"name\": \"Alice\", \"profile\": {\"age\": 30}}}";
NSDictionary *root = [jsonString mulleJSON];

NSDictionary *user = root[@"user"];
NSDictionary *profile = user[@"profile"];
NSNumber *age = profile[@"age"];

NSLog(@"Age: %@", age);
```

### Example 5: JSON Array Streaming
```objc
- (void) parseJSONArrayStream:(NSInputStream *)stream {
    MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];
    NSMutableData *buffer = [NSMutableData data];
    NSMutableArray *results = [NSMutableArray array];
    
    uint8_t readBuffer[2048];
    NSInteger bytesRead;
    
    while ((bytesRead = [stream read:readBuffer maxLength:sizeof(readBuffer)]) > 0) {
        [buffer appendBytes:readBuffer length:bytesRead];
        
        NSString *bufferStr = [[NSString alloc] initWithData:buffer 
                                                      encoding:NSUTF8StringEncoding];
        if ([bufferStr rangeOfString:@"}"].location != NSNotFound) {
            // Likely has a complete object
            id parsed = [parser parseData:buffer];
            if (parsed) {
                [results addObject:parsed];
                [parser reset];
                [buffer setLength:0];
            }
        }
        [bufferStr release];
    }
}
```

### Example 6: Error-Tolerant JSON Parsing
```objc
- (id) parseJSONSafely:(NSData *)data {
    MulleJSMNParser *parser = [[MulleJSMNParser new] autorelease];
    
    id result = [parser parseData:data];
    
    if (!result) {
        if ([parser isIncomplete]) {
            NSLog(@"Warning: Incomplete JSON, returning nil");
        } else {
            NSLog(@"Error: Failed to parse JSON");
        }
        return nil;
    }
    
    return result;
}
```

## 7. Dependencies

- **MulleFoundation** - NSDictionary, NSArray, NSString, NSNumber
- **JSMN** - Embedded JSON parser (C) - vendored, no external dependency
- **mulle-objc** (runtime) - Objective-C runtime support
- Standard C library

## 8. Limitations

- **Unicode**: UTF-8 only; other encodings require pre-conversion
- **Streaming**: JSON must be complete logical units (full objects/arrays)
- **Size**: Very large token counts may require large allocations
- **No Comments**: JSON specification doesn't allow comments
- **Strict RFC 4627**: Follows strict JSON spec; no extensions

## 9. Standards & References

- **RFC 4627**: The application/json Media Type for JavaScript Object Notation (JSON)
- **JSMN Parser**: Jansson-inspired minimal JSON parser
- **JSON Spec**: https://www.json.org/

## 10. Version Information

MulleObjCJSMNFoundation version macro: `MULLE_OBJC_JSMN_FOUNDATION_VERSION`
- Format: `(major << 20) | (minor << 8) | patch`
- Reflects both wrapper and bundled JSMN versions
