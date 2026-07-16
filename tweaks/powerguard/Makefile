export THEOS_PACKAGE_SCHEME = rootless

# 显式钉住 SDK 版本(而不是 latest):部分 Theos 工具链自带的 clang 跟较新 SDK(15.6/16.5)
# 的 libc++ module map 有冲突,编译期报 "redefinition of module 'std_config'"。
# 14.5 SDK 头文件在实测环境里能正常编译,-mios-version-min 仍然按下面 15.0 算,不影响
# 最终产物的最低系统要求。如果你自己的 Theos 环境没有这个问题,可以放心改回 latest。
TARGET := iphone:clang:14.5:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PowerGuard
PowerGuard_FILES = Tweak.xm
PowerGuard_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
