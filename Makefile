export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CoreBluetoothLogger
CoreBluetoothLogger_FILES = Tweak.xm
CoreBluetoothLogger_FRAMEWORKS = CoreBluetooth
include $(THEOS_MAKE_PATH)/tweak.mk


