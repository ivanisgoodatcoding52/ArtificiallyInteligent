//
//  AIVoidAIProvider.h
//  Artificially Inteligent
//
//  Talks to VoidAI (https://voidai.app), which exposes an OpenAI-compatible
//  surface. Implemented as its own class (rather than reusing
//  AIOpenAIProvider directly) so the base URL and any VoidAI-specific
//  quirks can diverge later without touching the generic OpenAI path.
//

#import "AIProvider.h"

@interface AIVoidAIProvider : AIProvider
@end
