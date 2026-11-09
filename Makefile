# Split View Pro — Theos / RootHide Makefile
# 目标：iOS 15.0–16.6.1, arm64e (A12+), RootHide bootstrap
#
# 本地/CI 均可构建：
#   make package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1
#   make package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1   # 普通 Dopamine 备用
#
# BUILD_PREFS=0 可只构建主 tweak（设置面板依赖 Preferences 私有头文件，
# 某些 CI SDK 没带时用这个开关先出主 deb）。

export TARGET = iphone:clang:latest:15.0
export ARCHS = arm64e
export PACKAGE_VERSION = 1.0.0

THEOS_PACKAGE_SCHEME ?= roothide
export THEOS_PACKAGE_SCHEME

TWEAK_NAME = SplitViewPro
SplitViewPro_FILES = $(shell find Sources -type f \( -name '*.m' -o -name '*.xm' -o -name '*.swift' \))
SplitViewPro_SWIFTFLAGS = -I$(THEOS_PROJECT_DIR)/Sources -swift-version 5
SplitViewPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-arc-performSelector-leaks
SplitViewPro_FRAMEWORKS = UIKit Foundation QuartzCore AVFAudio ReplayKit CoreTelephony CoreImage
SplitViewPro_LIBRARIES =
SplitViewPro_LDFLAGS = -undefined dynamic_lookup
SplitViewPro_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

# ---- 设置面板（1:1 的 26 页）----
BUILD_PREFS ?= 1
ifeq ($(BUILD_PREFS),1)
BUNDLE_NAME = SplitViewProPrefs
SplitViewProPrefs_FILES = $(shell find prefs -type f -name '*.swift') \
	Sources/Prefs/FVPrefsKeys.swift \
	Sources/Prefs/FVPrefsStore.swift \
	Sources/Support/FVLog.swift \
	Sources/Support/FVAppHelper.swift \
	Sources/Core/FVFileManager.swift \
	Sources/Tools/FVToolAction.swift
SplitViewProPrefs_SWIFTFLAGS = -I$(THEOS_PROJECT_DIR)/Sources -swift-version 5
SplitViewProPrefs_FRAMEWORKS = UIKit Foundation
SplitViewProPrefs_PRIVATE_FRAMEWORKS = Preferences
SplitViewProPrefs_CFLAGS = -fobjc-arc
SplitViewProPrefs_INSTALL_PATH = /Library/PreferenceBundles
include $(THEOS_MAKE_PATH)/bundle.mk
endif

after-install::
	install.exec "killall -9 SpringBoard 2>/dev/null || true"
