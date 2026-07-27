ARCHS = armv7
TARGET = iphone:clang:latest:3.0
# See the main Makefile for why arm64 is omitted (iPhoneOS6.1.sdk predates
# Apple's arm64 support entirely).

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ArtificiallyInteligentPrefs

ArtificiallyInteligentPrefs_FILES = AIPrefsRootListController.m
ArtificiallyInteligentPrefs_INSTALL_PATH = /Library/PreferenceBundles
ArtificiallyInteligentPrefs_FRAMEWORKS = UIKit Foundation
ArtificiallyInteligentPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 Preferences || true"
