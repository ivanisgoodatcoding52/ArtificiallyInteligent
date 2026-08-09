# This project targets three separate architecture tiers, each requiring a
# different SDK (older SDKs stop including support for older CPUs; the
# newest SDK doesn't exist yet when older CPUs were current). Rather than
# fight Theos' less-common multi-SDK-single-package mechanism, build each
# tier as its own separate .deb by choosing BUILD_ARCH on the command line:
#
#   make package BUILD_ARCH=armv6   -> iPod touch 2G, iPhone 3G (iOS 3.0-4.2.1)
#                                       Requires an SDK that still ships armv6
#                                       library slices, e.g. iPhoneOS4.3.sdk
#                                       or iPhoneOS5.1.sdk. This project's
#                                       currently-installed iPhoneOS6.1.sdk
#                                       does NOT have armv6 slices in its
#                                       system libraries (Apple dropped them
#                                       starting around Xcode 4.5), so armv6
#                                       will fail to link without adding one
#                                       of these older SDKs to $THEOS/sdks.
#
#   make package BUILD_ARCH=armv7   -> iPhone 3GS through the plain iPhone 5,
#                                       iPad 1-4, iPod touch 4/5, etc.
#                                       This is the default, and builds
#                                       cleanly against the iPhoneOS6.1.sdk
#                                       already installed.
#
#   make package BUILD_ARCH=arm64   -> iPhone 5s and later (anything with a
#                                       64-bit A-series chip), running the
#                                       SAME legacy-compatible UI as the
#                                       other tiers above.
#                                       Requires a newer SDK (iOS 7.0+) since
#                                       iPhoneOS6.1.sdk predates Apple's
#                                       arm64 support entirely. Grab one from
#                                       https://github.com/theos/sdks and
#                                       drop it into $THEOS/sdks.
#
#   make package BUILD_ARCH=modern  -> A separate, from-scratch iOS 7+ UI
#                                       port: real UIAlertController dialogs,
#                                       Auto Layout throughout, and a
#                                       refreshed flat visual design instead
#                                       of the legacy-compatible look the
#                                       other three tiers share. Floor is
#                                       iOS 7.0. Builds for both armv7 and
#                                       arm64 (anything that can run iOS 7+),
#                                       so it's the tier to reach for on a
#                                       device that doesn't need iOS 3-6
#                                       support. Needs an iOS 8+ SDK so
#                                       UIAlertController is actually
#                                       declared (same SDK requirement as
#                                       the arm64 tier above) - grab one from
#                                       https://github.com/theos/sdks.
#
# Additional SDKs (all free, community-mirrored) live at:
#   https://github.com/theos/sdks
# Download the .sdk folder you need and place it directly under $THEOS/sdks/
# (no extra unzip step needed if you clone the whole repo; individual folders
# also work if copied in directly).

BUILD_ARCH ?= armv7

ifeq ($(BUILD_ARCH),armv6)
ARCHS = armv6
TARGET = iphone:clang:4.3:3.0
else ifeq ($(BUILD_ARCH),arm64)
ARCHS = arm64
TARGET = iphone:clang:latest:7.0
else ifeq ($(BUILD_ARCH),modern)
ARCHS = armv7 arm64
TARGET = iphone:clang:latest:7.0
else
ARCHS = armv7
TARGET = iphone:clang:latest:3.0
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ArtificiallyInteligent

# Business-logic classes are identical across every tier - their runtime
# checks (AIHasNSURLSession, AIHasNSJSONSerialization, etc.) just always
# take the "modern" branch on newer tiers, so there's nothing tier-specific
# to change here.
ArtificiallyInteligent_FILES = Tweak.xm \
	Classes/Shared/AIJSONCompat.m \
	Classes/Shared/AIAPIManager.m \
	Classes/Shared/AIProvider.m \
	Classes/Shared/AIOpenAIProvider.m \
	Classes/Shared/AIOllamaProvider.m \
	Classes/Shared/AIVoidAIProvider.m \
	Classes/Shared/AIGenericProvider.m \
	Classes/Shared/AISettingsManager.m \
	Classes/Shared/AIConversationStore.m

# UI + compat-shim classes genuinely differ: the "modern" tier gets the
# from-scratch iOS7+ redesign in Classes/Modern, every other tier gets the
# wide-compatibility implementation in Classes/Legacy. Both expose the exact
# same class/function names, so nothing else in the project needs to know
# which one it's linked against.
ifeq ($(BUILD_ARCH),modern)
ArtificiallyInteligent_FILES += Classes/Modern/AICompat.m Classes/Modern/AIChatViewController.m Classes/Modern/AIMessageCell.m
ArtificiallyInteligent_CFLAGS = -IClasses/Modern -IClasses/Shared -fobjc-arc -Wno-deprecated-declarations -Wno-arc-performSelector-leaks
else
ArtificiallyInteligent_FILES += Classes/Legacy/AICompat.m Classes/Legacy/AIChatViewController.m Classes/Legacy/AIMessageCell.m
ArtificiallyInteligent_CFLAGS = -IClasses/Legacy -IClasses/Shared -fobjc-arc -Wno-deprecated-declarations -Wno-arc-performSelector-leaks
endif

ArtificiallyInteligent_FRAMEWORKS = UIKit Foundation CoreGraphics SystemConfiguration QuartzCore
ArtificiallyInteligent_WEAK_FRAMEWORKS = AVFoundation Security

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
