ARCHS = armv7
TARGET = iphone:clang:latest:3.0

THEOS_DEVICE_TARGETS = iphone:clang:10.0:3.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ArtificiallyInteligent

ArtificiallyInteligent_FILES = Tweak.xm \
	Classes/AICompat.m \
	Classes/AIJSONCompat.m \
	Classes/AIChatViewController.m \
	Classes/AIMessageCell.m \
	Classes/AIAPIManager.m \
	Classes/AIProvider.m \
	Classes/AIOpenAIProvider.m \
	Classes/AIOllamaProvider.m \
	Classes/AIVoidAIProvider.m \
	Classes/AIGenericProvider.m \
	Classes/AISettingsManager.m \
	Classes/AIConversationStore.m

ArtificiallyInteligent_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-arc-performSelector-leaks
ArtificiallyInteligent_FRAMEWORKS = UIKit Foundation CoreGraphics SystemConfiguration QuartzCore
ArtificiallyInteligent_WEAK_FRAMEWORKS = AVFoundation Security

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
