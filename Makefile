export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GATTLogger
GATTLogger_FILES = Tweak.xm
GATTLogger_FRAMEWORKS = CoreBluetooth
include $(THEOS_MAKE_PATH)/tweak.mk


