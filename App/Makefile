BUILD_ARCH ?= armv7

ifeq ($(BUILD_ARCH),armv6)
ARCHS = armv6
TARGET = iphone:clang:4.3:4.0
else ifeq ($(BUILD_ARCH),a4a6)
ARCHS = armv7
TARGET = iphone:clang:6.1:5.0
else ifeq ($(BUILD_ARCH),arm64)
ARCHS = arm64
TARGET = iphone:clang:latest:7.0
else ifeq ($(BUILD_ARCH),modern)
ARCHS = armv7 arm64
TARGET = iphone:clang:latest:7.0
else
ARCHS = armv7
TARGET = iphone:clang:6.1:4.0
endif
# See the main Makefile for the full explanation of the build tiers and
# which SDK each one requires. This subproject reuses the exact same
# Classes/Shared/ + (Classes/Legacy/ or Classes/Modern/) source as the
# tweak itself - the standalone app is just a thin AppDelegate/main.m shell
# around the same AIChatViewController.

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = ArtificiallyInteligentApp

ArtificiallyInteligentApp_FILES = main.m AIAppDelegate.m \
	../Classes/Shared/AIJSONCompat.m \
	../Classes/Shared/AIAPIManager.m \
	../Classes/Shared/AIProvider.m \
	../Classes/Shared/AIOpenAIProvider.m \
	../Classes/Shared/AIOllamaProvider.m \
	../Classes/Shared/AIVoidAIProvider.m \
	../Classes/Shared/AIGenericProvider.m \
	../Classes/Shared/AISettingsManager.m \
	../Classes/Shared/AIConversationStore.m \
	../Classes/Shared/AIExternalBridge.m

ifeq ($(BUILD_ARCH),modern)
ArtificiallyInteligentApp_FILES += ../Classes/Modern/AICompat.m ../Classes/Modern/AIChatViewController.m ../Classes/Modern/AIMessageCell.m
ArtificiallyInteligentApp_CFLAGS = -I../Classes/Modern -I../Classes/Shared -fobjc-arc -Wno-deprecated-declarations -Wno-arc-performSelector-leaks
else
ArtificiallyInteligentApp_FILES += ../Classes/Legacy/AICompat.m ../Classes/Legacy/AIChatViewController.m ../Classes/Legacy/AIMessageCell.m
ArtificiallyInteligentApp_CFLAGS = -I../Classes/Legacy -I../Classes/Shared -fobjc-arc -Wno-deprecated-declarations -Wno-arc-performSelector-leaks
endif

ArtificiallyInteligentApp_FRAMEWORKS = UIKit Foundation CoreGraphics CoreFoundation SystemConfiguration QuartzCore
ArtificiallyInteligentApp_WEAK_FRAMEWORKS = AVFoundation Security
ArtificiallyInteligentApp_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk
