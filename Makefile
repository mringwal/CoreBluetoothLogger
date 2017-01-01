# ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GATTLogger
GATTLogger_FILES = Tweak.xm
GATTLogger_FRAMEWORKS = CoreBluetooth
include $(THEOS_MAKE_PATH)/tweak.mk


