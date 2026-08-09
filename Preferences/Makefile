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
# See the main Makefile for the full explanation of the four build tiers
# and which SDK each one requires. The Settings.app pane itself (this
# subproject) needs no code changes across tiers - only arch/SDK selection.

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ArtificiallyInteligentPrefs

ArtificiallyInteligentPrefs_FILES = AIPrefsRootListController.m
ArtificiallyInteligentPrefs_INSTALL_PATH = /Library/PreferenceBundles
ArtificiallyInteligentPrefs_FRAMEWORKS = UIKit Foundation
ArtificiallyInteligentPrefs_PRIVATE_FRAMEWORKS = Preferences
# Root.plist (specifiers), Info.plist (bundle metadata / NSPrincipalClass),
# and Icon.png all live in Resources/ - without this, none of them actually
# get copied into the built .bundle, which is why the Settings pane showed
# up blank: loadSpecifiersFromPlistName:@"Root" had no Root.plist to find.
ArtificiallyInteligentPrefs_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 Preferences || true"
