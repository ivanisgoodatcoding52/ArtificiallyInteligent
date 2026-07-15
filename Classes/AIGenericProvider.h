//
//  AIGenericProvider.h
//  Artificially Inteligent
//
//  Lets advanced users wire up an arbitrary chat API without new code:
//  they supply an endpoint, an auth header format, a JSON request template
//  (with {{message}}/{{history}}/{{model}}/{{system}} placeholders), and a
//  dot-notation path describing where the reply text lives in the response.
//

#import "AIProvider.h"

@interface AIGenericProvider : AIProvider
@end
