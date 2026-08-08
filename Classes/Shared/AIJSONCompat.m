//
//  AIJSONCompat.m
//  Artificially Inteligent
//

#import "AIJSONCompat.h"
#import "AICompat.h"

@interface AILegacyJSONParser : NSObject {
    const char *_bytes;
    NSUInteger _length;
    NSUInteger _index;
}
- (instancetype)initWithData:(NSData *)data;
- (id)parse;
@end

@implementation AIJSONCompat

+ (NSData *)dataWithJSONObject:(id)object error:(NSError **)error {
    if (AIHasNSJSONSerialization()) {
        return [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
    }
    NSString *str = [self legacySerialize:object];
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

+ (id)JSONObjectWithData:(NSData *)data error:(NSError **)error {
    if (AIHasNSJSONSerialization()) {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    }
    AILegacyJSONParser *parser = [[AILegacyJSONParser alloc] initWithData:data];
    id result = [parser parse];
    if (!result && error) {
        *error = [NSError errorWithDomain:@"AIJSONCompat" code:1
                                  userInfo:@{NSLocalizedDescriptionKey: @"Legacy JSON parse failed"}];
    }
    return result;
}

#pragma mark - Legacy serialization (encode only what our providers need)

+ (NSString *)legacySerialize:(id)obj {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *parts = [NSMutableArray array];
        for (id key in obj) {
            NSString *k = [self legacySerialize:[key description]];
            NSString *v = [self legacySerialize:obj[key]];
            [parts addObject:[NSString stringWithFormat:@"%@:%@", k, v]];
        }
        return [NSString stringWithFormat:@"{%@}", [parts componentsJoinedByString:@","]];
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *parts = [NSMutableArray array];
        for (id item in obj) {
            [parts addObject:[self legacySerialize:item]];
        }
        return [NSString stringWithFormat:@"[%@]", [parts componentsJoinedByString:@","]];
    }
    if ([obj isKindOfClass:[NSString class]]) {
        NSMutableString *escaped = [NSMutableString stringWithString:obj];
        [escaped replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, escaped.length)];
        [escaped replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, escaped.length)];
        [escaped replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, escaped.length)];
        return [NSString stringWithFormat:@"\"%@\"", escaped];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            return [obj boolValue] ? @"true" : @"false";
        }
        return [obj stringValue];
    }
    if (!obj || obj == [NSNull null]) {
        return @"null";
    }
    return @"null";
}

@end

#pragma mark - Legacy parsing (decode only what API responses need)

@implementation AILegacyJSONParser

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _bytes = (const char *)data.bytes;
        _length = data.length;
        _index = 0;
    }
    return self;
}

- (void)skipWhitespace {
    while (_index < _length && isspace((unsigned char)_bytes[_index])) _index++;
}

- (id)parse {
    [self skipWhitespace];
    return [self parseValue];
}

- (id)parseValue {
    [self skipWhitespace];
    if (_index >= _length) return nil;
    char c = _bytes[_index];
    if (c == '{') return [self parseObject];
    if (c == '[') return [self parseArray];
    if (c == '"') return [self parseString];
    if (c == 't' || c == 'f') return [self parseBool];
    if (c == 'n') { _index += 4; return [NSNull null]; }
    return [self parseNumber];
}

- (NSDictionary *)parseObject {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    _index++; // {
    [self skipWhitespace];
    if (_index < _length && _bytes[_index] == '}') { _index++; return dict; }
    while (_index < _length) {
        [self skipWhitespace];
        NSString *key = [self parseString];
        [self skipWhitespace];
        if (_index < _length && _bytes[_index] == ':') _index++;
        id value = [self parseValue];
        if (key) dict[key] = value ?: [NSNull null];
        [self skipWhitespace];
        if (_index < _length && _bytes[_index] == ',') { _index++; continue; }
        if (_index < _length && _bytes[_index] == '}') { _index++; break; }
        break;
    }
    return dict;
}

- (NSArray *)parseArray {
    NSMutableArray *arr = [NSMutableArray array];
    _index++; // [
    [self skipWhitespace];
    if (_index < _length && _bytes[_index] == ']') { _index++; return arr; }
    while (_index < _length) {
        id value = [self parseValue];
        if (value) [arr addObject:value];
        [self skipWhitespace];
        if (_index < _length && _bytes[_index] == ',') { _index++; continue; }
        if (_index < _length && _bytes[_index] == ']') { _index++; break; }
        break;
    }
    return arr;
}

- (NSString *)parseString {
    if (_bytes[_index] != '"') return nil;
    _index++;
    NSMutableString *result = [NSMutableString string];
    while (_index < _length && _bytes[_index] != '"') {
        char c = _bytes[_index];
        if (c == '\\' && _index + 1 < _length) {
            char next = _bytes[_index + 1];
            switch (next) {
                case 'n': [result appendString:@"\n"]; break;
                case 't': [result appendString:@"\t"]; break;
                case '"': [result appendString:@"\""]; break;
                case '\\': [result appendString:@"\\"]; break;
                case '/': [result appendString:@"/"]; break;
                default: [result appendFormat:@"%c", next]; break;
            }
            _index += 2;
        } else {
            [result appendFormat:@"%c", c];
            _index++;
        }
    }
    _index++; // closing quote
    return result;
}

- (NSNumber *)parseNumber {
    NSUInteger start = _index;
    while (_index < _length &&
           (isdigit((unsigned char)_bytes[_index]) || _bytes[_index] == '-' ||
            _bytes[_index] == '+' || _bytes[_index] == '.' || _bytes[_index] == 'e' || _bytes[_index] == 'E')) {
        _index++;
    }
    NSString *numStr = [[NSString alloc] initWithBytes:_bytes + start
                                                  length:_index - start
                                                encoding:NSUTF8StringEncoding];
    return @([numStr doubleValue]);
}

- (NSNumber *)parseBool {
    if (_bytes[_index] == 't') { _index += 4; return @YES; }
    _index += 5;
    return @NO;
}

@end
