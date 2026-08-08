//
//  AISettingsManager.h
//  Artificially Inteligent
//
//  Thin typed wrapper over NSUserDefaults. Keys here match exactly what the
//  Preferences bundle (Root.plist) writes, so changes made in Settings.app
//  take effect the next time the tweak reads a value — no extra sync step
//  needed beyond CFPreferences' normal behavior.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AIProviderType) {
    AIProviderTypeOpenAICompatible = 0,
    AIProviderTypeOllama           = 1,
    AIProviderTypeVoidAI           = 2,
    AIProviderTypeCustom           = 3
};

extern NSString * const AISettingsDidChangeNotification;

@interface AISettingsManager : NSObject

+ (instancetype)sharedManager;

// Provider selection
@property (nonatomic, assign) AIProviderType activeProviderType;

// Core connection config
@property (nonatomic, copy) NSString *apiURL;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *modelName;
@property (nonatomic, assign) double temperature;
@property (nonatomic, assign) NSInteger maxTokens;

// Advanced
@property (nonatomic, copy) NSString *systemPrompt;
@property (nonatomic, assign) NSTimeInterval requestTimeout;
@property (nonatomic, assign) BOOL streamingEnabled;
@property (nonatomic, assign) BOOL saveHistoryEnabled;

// Generic provider config (only used when activeProviderType == AIProviderTypeCustom)
@property (nonatomic, copy) NSString *genericProviderName;
@property (nonatomic, copy) NSString *genericAuthHeaderName;   // e.g. "Authorization"
@property (nonatomic, copy) NSString *genericAuthHeaderFormat; // e.g. "Bearer %@"
@property (nonatomic, copy) NSString *genericRequestTemplate;  // JSON string with {{message}}, {{model}}, {{system}} placeholders
@property (nonatomic, copy) NSString *genericResponsePath;     // dot-notation, e.g. "choices.0.message.content"

// Ollama-specific
@property (nonatomic, assign) NSInteger ollamaContextLength;

- (void)reloadFromDefaults;
- (void)clearAllStoredData;

@end
