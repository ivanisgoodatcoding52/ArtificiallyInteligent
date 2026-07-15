ARCHS = armv6 armv7 arm64
TARGET = iphone:clang:latest:3.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ArtificiallyInteligentPrefs

ArtificiallyInteligentPrefs_FILES = AIPrefsRootListController.m
ArtificiallyInteligentPrefs_INSTALL_PATH = /Library/PreferenceBundles
ArtificiallyInteligentPrefs_FRAMEWORKS = UIKit Foundation
ArtificiallyInteligentPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 Preferences || true"
