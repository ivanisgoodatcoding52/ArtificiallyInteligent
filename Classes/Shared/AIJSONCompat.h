//
//  AIJSONCompat.h
//  Artificially Inteligent
//
//  NSJSONSerialization only exists on iOS 5.0+. This wrapper picks it when
//  available and otherwise uses a small hand-rolled JSON parser/serializer
//  sufficient for the flat/shallow request-response shapes AI APIs use
//  (objects, arrays, strings, numbers, bools, null). It is not meant to be
//  a general purpose JSON library — just enough to talk to chat APIs.
//

#import <Foundation/Foundation.h>

@interface AIJSONCompat : NSObject

+ (NSData *)dataWithJSONObject:(id)object error:(NSError **)error;
+ (id)JSONObjectWithData:(NSData *)data error:(NSError **)error;

@end
