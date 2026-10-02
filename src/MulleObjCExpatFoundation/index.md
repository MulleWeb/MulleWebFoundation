# MulleObjCExpatFoundation Library Documentation for AI
<!-- Keywords: xml, plist -->

## 1. Introduction & Purpose

MulleObjCExpatFoundation adds XML parsing capability to mulle-objc through NSPropertyListSerialization categories. Enables reading and writing property lists in XML format (commonly used plist format) using the libexpat XML parser. Provides seamless integration with existing plist APIs while adding XML support for data interchange and configuration files.

## 2. Key Concepts & Design Philosophy

- **Category-Based Extension**: Extends NSPropertyListSerialization without subclassing
- **libexpat Integration**: Uses proven expat C library for XML parsing
- **Format Compatibility**: Supports standard macOS/iOS XML plist format
- **Transparent API**: Uses same NSPropertyListSerialization API as other formats
- **Safe Parsing**: Validates XML structure and plist format during parsing
- **Base64 Support**: Handles binary data encoding in XML via base64

## 3. Core API & Data Structures

### NSPropertyListSerialization (XML Format Support)

The XML support is integrated into NSPropertyListSerialization using the standard format parameter:

#### XML Format Constant

```objc
NSPropertyListXMLFormat  // Specifies XML format for serialization
```

#### Parsing XML Plists

```objc
NSError *error = nil;
NSData *xmlData = [NSData dataWithContentsOfFile:@"data.plist"];

id plist = [NSPropertyListSerialization 
    propertyListWithData:xmlData 
    options:NSPropertyListImmutable 
    format:NULL 
    error:&error];

if (error) {
    NSLog(@"Parse error: %@", [error localizedDescription]);
}
```

#### Generating XML Plists

```objc
NSError *error = nil;
NSDictionary *data = @{@"key": @"value"};

NSData *xmlData = [NSPropertyListSerialization 
    dataWithPropertyList:data 
    format:NSPropertyListXMLFormat 
    options:0 
    error:&error];

if (!error) {
    [xmlData writeToFile:@"output.plist" atomically:YES];
}
```

### MulleObjCExpatParser

#### Purpose

Internal parser class for XML plist parsing. Usually accessed through NSPropertyListSerialization; direct use not typically needed.

```objc
@interface MulleObjCExpatParser : NSObject
@end
```

#### Data Structures

- `_stack`: Stack-based structure for tracking nested XML elements
- `_textStorage`: Accumulates text content during parsing
- `_dateFormatter`: Converts ISO 8601 date strings to NSDate objects

### Supported XML Plist Format

The XML plist format is standardized:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>name</key>
        <string>value</string>
        <key>number</key>
        <integer>42</integer>
        <key>data</key>
        <data>YmluYXJ5ZGF0YQ==</data>
        <key>date</key>
        <date>2025-03-15T10:30:00Z</date>
    </dict>
</plist>
```

#### XML Elements

- `<plist>`: Root element (version="1.0")
- `<dict>`: Dictionary/map (contains key/value pairs)
- `<array>`: Array/list (contains elements)
- `<key>`: Dictionary key (string, appears before value)
- `<string>`: String value
- `<data>`: Binary data (base64-encoded)
- `<integer>`: Integer number
- `<real>`: Floating-point number
- `<true/>`: Boolean true value
- `<false/>`: Boolean false value
- `<date>`: ISO 8601 date/time
- `<nil/>`: Null/nil value

## 4. Performance Characteristics

- **Parsing**: O(n) where n is XML file size (stream-based expat parsing)
- **Memory**: Efficient tree building; memory proportional to data size
- **Serialization**: O(n) generating XML output
- **Base64**: O(n) encoding/decoding binary data
- **Validation**: Expat validates XML well-formedness during parsing
- **Thread-Safety**: NSPropertyListSerialization thread-safe; parsers not reentrant

## 5. AI Usage Recommendations & Patterns

### Best Practices

- **Use NSPropertyListSerialization**: Always use high-level API, not direct parser
- **Format Negotiation**: Detect format or use NSPropertyListFormat output parameter
- **Error Handling**: Always check error parameter for parse failures
- **Data Validation**: Validate plist structure after parsing
- **Performance**: For large files, consider incremental parsing with expat directly
- **Compatibility**: XML format is widely compatible; good for data exchange

### Common Pitfalls

- **Malformed XML**: Invalid XML raises parse errors; validate input
- **Encoding**: XML must declare encoding; UTF-8 assumed if not specified
- **Binary Data**: Binary data must be base64-encoded in XML format
- **Date Format**: Dates must be ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)
- **Key Order**: Dictionary key order not preserved in XML; don't rely on it
- **Performance**: XML more verbose than binary format; larger file sizes
- **DTD**: DOCTYPE declaration required for compatibility; included automatically

### Idiomatic Usage

```objc
// Pattern 1: Parse XML plist from file
NSError *error = nil;
NSData *data = [NSData dataWithContentsOfFile:@"config.plist"];
NSDictionary *config = [NSPropertyListSerialization 
    propertyListWithData:data 
    options:NSPropertyListImmutable 
    format:NULL 
    error:&error];

if (error) {
    NSLog(@"Failed to parse: %@", error);
}

// Pattern 2: Write plist as XML
NSError *error = nil;
NSData *xml = [NSPropertyListSerialization 
    dataWithPropertyList:dataDict 
    format:NSPropertyListXMLFormat 
    options:0 
    error:&error];

[xml writeToFile:@"output.plist" atomically:YES];

// Pattern 3: Format detection
NSPropertyListFormat format;
id plist = [NSPropertyListSerialization 
    propertyListWithData:data 
    options:NSPropertyListImmutable 
    format:&format 
    error:&error];

NSString *formatName = (format == NSPropertyListXMLFormat) ? 
    @"XML" : @"Other";
NSLog(@"Detected format: %@", formatName);
```

## 6. Integration Examples

### Example 1: Parse XML Plist File

```objc
#import <MulleObjCExpatFoundation/MulleObjCExpatFoundation.h>

int main() {
    NSError *error = nil;
    NSString *path = @"config.plist";
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    if (!data) {
        NSLog(@"Failed to read file");
        return 1;
    }
    
    NSDictionary *config = [NSPropertyListSerialization 
        propertyListWithData:data 
        options:NSPropertyListImmutable 
        format:NULL 
        error:&error];
    
    if (error) {
        NSLog(@"Parse error: %@", [error localizedDescription]);
        return 1;
    }
    
    NSLog(@"Config loaded: %@", config);
    return 0;
}
```

### Example 2: Create and Write XML Plist

```objc
#import <MulleObjCExpatFoundation/MulleObjCExpatFoundation.h>

int main() {
    NSDictionary *data = @{
        @"name": @"Application",
        @"version": @"1.0",
        @"enabled": @YES,
        @"maxRetries": @3,
        @"timeout": @30.5
    };
    
    NSError *error = nil;
    NSData *xmlData = [NSPropertyListSerialization 
        dataWithPropertyList:data 
        format:NSPropertyListXMLFormat 
        options:0 
        error:&error];
    
    if (error) {
        NSLog(@"Serialization error: %@", error);
        return 1;
    }
    
    [xmlData writeToFile:@"app.plist" atomically:YES];
    NSLog(@"Plist written successfully");
    
    return 0;
}
```

### Example 3: Handle Complex Data Types

```objc
#import <MulleObjCExpatFoundation/MulleObjCExpatFoundation.h>

int main() {
    NSString *binaryString = @"Hello, World!";
    NSData *binaryData = [binaryString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *complexData = @{
        @"text": @"Sample text",
        @"binary": binaryData,
        @"array": @[@"item1", @"item2", @"item3"],
        @"date": [NSDate date],
        @"nested": @{
            @"key": @"value",
            @"count": @42
        }
    };
    
    NSError *error = nil;
    NSData *xmlData = [NSPropertyListSerialization 
        dataWithPropertyList:complexData 
        format:NSPropertyListXMLFormat 
        options:0 
        error:&error];
    
    if (!error) {
        NSString *xmlString = [[NSString alloc] 
            initWithData:xmlData 
            encoding:NSUTF8StringEncoding];
        NSLog(@"Generated XML:\n%@", xmlString);
        [xmlString release];
    }
    
    return 0;
}
```

### Example 4: Format Detection

```objc
#import <MulleObjCExpatFoundation/MulleObjCExpatFoundation.h>

int main() {
    NSData *plistData = [NSData dataWithContentsOfFile:@"data.plist"];
    
    NSError *error = nil;
    NSPropertyListFormat format;
    id plist = [NSPropertyListSerialization 
        propertyListWithData:plistData 
        options:NSPropertyListImmutable 
        format:&format 
        error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return 1;
    }
    
    switch (format) {
        case NSPropertyListOpenStepFormat:
            NSLog(@"Format: OpenStep");
            break;
        case NSPropertyListXMLFormat:
            NSLog(@"Format: XML");
            break;
        case NSPropertyListBinaryFormat:
            NSLog(@"Format: Binary");
            break;
        default:
            NSLog(@"Format: Unknown");
    }
    
    return 0;
}
```

### Example 5: Round-Trip Conversion

```objc
#import <MulleObjCExpatFoundation/MulleObjCExpatFoundation.h>

int main() {
    // Read from XML
    NSError *readError = nil;
    NSData *xmlData = [NSData dataWithContentsOfFile:@"input.plist"];
    NSDictionary *data = [NSPropertyListSerialization 
        propertyListWithData:xmlData 
        options:NSPropertyListMutableContainers 
        format:NULL 
        error:&readError];
    
    if (readError) {
        NSLog(@"Read error: %@", readError);
        return 1;
    }
    
    // Modify data
    NSMutableDictionary *modified = (NSMutableDictionary *)data;
    [modified setObject:@"updated" forKey:@"version"];
    
    // Write back as XML
    NSError *writeError = nil;
    NSData *outputXml = [NSPropertyListSerialization 
        dataWithPropertyList:modified 
        format:NSPropertyListXMLFormat 
        options:0 
        error:&writeError];
    
    if (writeError) {
        NSLog(@"Write error: %@", writeError);
        return 1;
    }
    
    [outputXml writeToFile:@"output.plist" atomically:YES];
    NSLog(@"Round-trip successful");
    
    return 0;
}
```

### Example 6: Error Handling

```objc
#import <MulleObjCExpatFoundation/MulleObjCExpatFoundation.h>

int main() {
    NSString *invalidXML = @"<invalid>XML";
    NSData *data = [invalidXML dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    id result = [NSPropertyListSerialization 
        propertyListWithData:data 
        options:NSPropertyListImmutable 
        format:NULL 
        error:&error];
    
    if (error) {
        NSLog(@"Parse failed:");
        NSLog(@"  Domain: %@", [error domain]);
        NSLog(@"  Code: %ld", (long)[error code]);
        NSLog(@"  Description: %@", [error localizedDescription]);
        NSLog(@"  Reason: %@", [error localizedFailureReason]);
        return 1;
    }
    
    NSLog(@"Parsed successfully: %@", result);
    return 0;
}
```

## 7. Dependencies

- libexpat (XML parser C library)
- MulleObjCStandardFoundation (NSPropertyListSerialization, NSData)
- MulleObjCPlistFoundation (plist base format)
- MulleBase64 (base64 encoding for binary data)
- MulleFoundationBase
