# iOS CoreBluetooth GATT Logger

Show CoreBluetooth actions in syslog

## Requirements

- iOS Device with Jailbreak
- Xcode
- theos build system

## Compile

	export THEOS=/path/to/your/theos/checkout
	make
	make package

## Installation

Install .deb file as usual, e.g.:

a) provide a TCP tunnel, set THEOS_DEVICE_IP and THEOS_DEVICE_PORT, and run make install
b) manually copy the .deb file to your iOS device. dpkg -i ch.ringwald.gattlogger*

## Usage

- Run app you're interested in
- Watch syslog messages, e.g. with [deviceconsole](https://github.com/rpetrich/deviceconsole)
- Uninstall when done - might leak memory :)

