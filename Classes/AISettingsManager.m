//
//  AISettingsManager.m
//  Artificially Inteligent
//

#import "AISettingsManager.h"

NSString * const AISettingsDidChangeNotification = @"AISettingsDidChangeNotification";

static NSString * const kAIDefaultsSuite       = @"com.yourname.artificiallyinteligent";

static NSString * const kKeyProviderType       = @"AIActiveProviderType";
static NSString * const kKeyAPIURL             = @"AIApiURL";
static NSString * const kKeyAPIKey             = @"AIApiKey";
static NSString * const kKeyModelName          = @"AIModelName";
static NSString * const kKeyTemperature        = @"AITemperature";
static NSString * const kKeyMaxTokens          = @"AIMaxTokens";
static NSString * const kKeySystemPrompt       = @"AISystemPrompt";
static NSString * const kKeyRequestTimeout     = @"AIRequestTimeout";
static NSString * const kKeyStreamingEnabled   = @"AIStreamingEnabled";
static NSString * const kKeySaveHistory        = @"AISaveHistoryEnabled";
static NSString * const kKeyGenericName        = @"AIGenericProviderName";
static NSString * const kKeyGenericAuthHeader  = @"AIGenericAuthHeaderName";
static NSString * const kKeyGenericAuthFormat  = @"AIGenericAuthHeaderFormat";
static NSString * const kKeyGenericTemplate    = @"AIGenericRequestTemplate";
static NSString * const kKeyGenericRespPath    = @"AIGenericResponsePath";
static NSString * const kKeyOllamaContextLen   = @"AIOllamaContextLength";

@interface AISettingsManager ()
@property (nonatomic, strong) NSUserDefaults *defaults;
@end

@implementation AISettingsManager

+ (instancetype)sharedManager {
    static AISettingsManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AISettingsManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Falls back to standardUserDefaults if the named suite can't be
        // created (sandboxed contexts on some rootless setups).
        _defaults = [[NSUserDefaults alloc] initWithSuiteName:kAIDefaultsSuite] ?: [NSUserDefaults standardUserDefaults];
        [self registerDefaults];
    }
    return self;
}

- (void)registerDefaults {
    [self.defaults registerDefaults:@{
        kKeyProviderType: @(AIProviderTypeOpenAICompatible),
        kKeyAPIURL: @"",
        kKeyAPIKey: @"",
        kKeyModelName: @"gpt-3.5-turbo",
        kKeyTemperature: @0.7,
        kKeyMaxTokens: @512,
        kKeySystemPrompt: @"You are a helpful assistant.",
        kKeyRequestTimeout: @30.0,
        kKeyStreamingEnabled: @NO,
        kKeySaveHistory: @YES,
        kKeyGenericName: @"Custom Provider",
        kKeyGenericAuthHeader: @"Authorization",
        kKeyGenericAuthFormat: @"Bearer %@",
        kKeyGenericTemplate: @"",
        kKeyGenericRespPath: @"choices.0.message.content",
        kKeyOllamaContextLen: @2048
    }];
}

- (void)reloadFromDefaults {
    [self.defaults synchronize];
}

#pragma mark - Accessors

- (AIProviderType)activeProviderType {
    return (AIProviderType)[self.defaults integerForKey:kKeyProviderType];
}
- (void)setActiveProviderType:(AIProviderType)activeProviderType {
    [self.defaults setInteger:activeProviderType forKey:kKeyProviderType];
    [self notifyChanged];
}

- (NSString *)apiURL { return [self.defaults stringForKey:kKeyAPIURL]; }
- (void)setApiURL:(NSString *)apiURL { [self.defaults setObject:apiURL ?: @"" forKey:kKeyAPIURL]; [self notifyChanged]; }

- (NSString *)apiKey { return [self.defaults stringForKey:kKeyAPIKey]; }
- (void)setApiKey:(NSString *)apiKey { [self.defaults setObject:apiKey ?: @"" forKey:kKeyAPIKey]; [self notifyChanged]; }

- (NSString *)modelName { return [self.defaults stringForKey:kKeyModelName]; }
- (void)setModelName:(NSString *)modelName { [self.defaults setObject:modelName ?: @"" forKey:kKeyModelName]; [self notifyChanged]; }

- (double)temperature { return [self.defaults doubleForKey:kKeyTemperature]; }
- (void)setTemperature:(double)temperature { [self.defaults setDouble:temperature forKey:kKeyTemperature]; [self notifyChanged]; }

- (NSInteger)maxTokens { return [self.defaults integerForKey:kKeyMaxTokens]; }
- (void)setMaxTokens:(NSInteger)maxTokens { [self.defaults setInteger:maxTokens forKey:kKeyMaxTokens]; [self notifyChanged]; }

- (NSString *)systemPrompt { return [self.defaults stringForKey:kKeySystemPrompt]; }
- (void)setSystemPrompt:(NSString *)systemPrompt { [self.defaults setObject:systemPrompt ?: @"" forKey:kKeySystemPrompt]; [self notifyChanged]; }

- (NSTimeInterval)requestTimeout { return [self.defaults doubleForKey:kKeyRequestTimeout]; }
- (void)setRequestTimeout:(NSTimeInterval)requestTimeout { [self.defaults setDouble:requestTimeout forKey:kKeyRequestTimeout]; [self notifyChanged]; }

- (BOOL)streamingEnabled { return [self.defaults boolForKey:kKeyStreamingEnabled]; }
- (void)setStreamingEnabled:(BOOL)streamingEnabled { [self.defaults setBool:streamingEnabled forKey:kKeyStreamingEnabled]; [self notifyChanged]; }

- (BOOL)saveHistoryEnabled { return [self.defaults boolForKey:kKeySaveHistory]; }
- (void)setSaveHistoryEnabled:(BOOL)saveHistoryEnabled { [self.defaults setBool:saveHistoryEnabled forKey:kKeySaveHistory]; [self notifyChanged]; }

- (NSString *)genericProviderName { return [self.defaults stringForKey:kKeyGenericName]; }
- (void)setGenericProviderName:(NSString *)v { [self.defaults setObject:v ?: @"" forKey:kKeyGenericName]; [self notifyChanged]; }

- (NSString *)genericAuthHeaderName { return [self.defaults stringForKey:kKeyGenericAuthHeader]; }
- (void)setGenericAuthHeaderName:(NSString *)v { [self.defaults setObject:v ?: @"" forKey:kKeyGenericAuthHeader]; [self notifyChanged]; }

- (NSString *)genericAuthHeaderFormat { return [self.defaults stringForKey:kKeyGenericAuthFormat]; }
- (void)setGenericAuthHeaderFormat:(NSString *)v { [self.defaults setObject:v ?: @"" forKey:kKeyGenericAuthFormat]; [self notifyChanged]; }

- (NSString *)genericRequestTemplate { return [self.defaults stringForKey:kKeyGenericTemplate]; }
- (void)setGenericRequestTemplate:(NSString *)v { [self.defaults setObject:v ?: @"" forKey:kKeyGenericTemplate]; [self notifyChanged]; }

- (NSString *)genericResponsePath { return [self.defaults stringForKey:kKeyGenericRespPath]; }
- (void)setGenericResponsePath:(NSString *)v { [self.defaults setObject:v ?: @"" forKey:kKeyGenericRespPath]; [self notifyChanged]; }

- (NSInteger)ollamaContextLength { return [self.defaults integerForKey:kKeyOllamaContextLen]; }
- (void)setOllamaContextLength:(NSInteger)v { [self.defaults setInteger:v forKey:kKeyOllamaContextLen]; [self notifyChanged]; }

#pragma mark - Housekeeping

- (void)notifyChanged {
    [self.defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:AISettingsDidChangeNotification object:self];
}

- (void)clearAllStoredData {
    NSDictionary *dict = [self.defaults dictionaryRepresentation];
    for (NSString *key in dict) {
        [self.defaults removeObjectForKey:key];
    }
    [self registerDefaults];
    [self notifyChanged];
}

@end
