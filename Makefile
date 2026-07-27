ARCHS = armv7
TARGET = iphone:clang:latest:3.0
# NOTE: arm64 is intentionally omitted here. iPhoneOS6.1.sdk predates Apple's
# arm64 support entirely (added around Xcode 5.0.1 / iOS 7.0.3, several
# months after 6.1 shipped), so its headers have no arm64 definitions at all
# -- this fails deep inside system headers before any of this project's own
# code is even reached, and can't be fixed from the source side. With only
# this SDK installed, armv7 is the newest architecture buildable, which still
# covers every 32-bit device in the target range (iPhone 3GS through the
# plain iPhone 5, iPad 1-4, iPod touch 4/5, etc). To add arm64 back (needed
# for 64-bit-only host processes on iPhone 5s/6/6s+), install a newer SDK
# (iOS 7+) from https://github.com/theos/sdks into $THEOS/sdks, then use
# THEOS_DEVICE_TARGETS with a per-arch SDK split, e.g.:
#   THEOS_DEVICE_TARGETS = iphone:clang:6.1:3.0 iphone:clang:9.3:7.0
#   ARCHS = armv7
#   ARCHS_iphone:clang:9.3:7.0 = arm64
# so armv7 keeps building against 6.1 while arm64 builds against the newer SDK.

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
