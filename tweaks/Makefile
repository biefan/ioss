# 注意: 这个聚合 Makefile 在部分 Theos 版本上会报
# "Theos version mismatch! common.mk [version 0] loaded in tandem with rules.mk [...]"。
# 如果遇到这个报错,改用 tweaks/README.md 里的逐个目录 `make package` 方式构建,
# 那种方式已经验证可以正常工作。

ifndef THEOS
$(error THEOS 未设置,请先安装并配置 Theos: https://theos.dev)
endif

THEOS_MAKE_PATH := $(THEOS)/makefiles

SUBPROJECTS += speedspring memsweeper blurbegone powerguard

include $(THEOS_MAKE_PATH)/aggregate.mk
