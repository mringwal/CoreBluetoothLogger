# iOS CoreBluetooth Logger

Show CoreBluetooth actions in syslog

## Requirements

- iOS Device with Jailbreak
- Xcode
- [theos build system](https://github.com/theos/theos)

## Compile

	export THEOS=/path/to/your/theos/checkout
	make
	make package

## Installation

Install .deb file as usual, e.g.:

- provide a TCP tunnel, set THEOS_DEVICE_IP and THEOS_DEVICE_PORT, and run make install, or
- copy the .deb file to your iOS device and install manually.  `dpkg -i ch.ringwald.corebluetoothlogger*`

## Usage

- Run app you're interested in
- Watch syslog messages, e.g. with [deviceconsole](https://github.com/rpetrich/deviceconsole)
- Uninstall when done - might leak memory :)

