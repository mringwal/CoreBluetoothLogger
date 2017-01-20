/*
 * Copyright (C) 2017 Matthias Ringwald
 */

#import <CoreBluetooth/CoreBluetooth.h>

// RAW_MODE logs all calls instead of providing a cleaner overview
// #define ENABLE_RAW_MODE

// proxy for CentralManagerDelegate delegates
@interface CBLoggerCentralManagerDelegate : NSObject<CBCentralManagerDelegate>{
	id<CBCentralManagerDelegate> appDelegate;
}
-(void)setDelegate:(id<CBCentralManagerDelegate>)delegate;
-(id<CBCentralManagerDelegate>) delegate;
@end

// proxy for CBPeripheralDelegate delegates
@interface CBLoggerPeripheralDelegate : NSObject<CBPeripheralDelegate>{
	id<CBPeripheralDelegate> appDelegate;
}
-(void)setDelegate:(id<CBPeripheralDelegate>)delegate;
-(id<CBPeripheralDelegate>) delegate;
@end

// const strings
static const char * propertyNames[] = {
	"Broadcast",
	"Read",
	"WriteWithoutResponse",
	"Write",
	"Notify",
	"Indicate",
	"AuthenticatedSignedWrites",
	"ExtendedProperties",
	"NotifyEncryptionRequired",
	"IndicateEncryptionRequired",
};

// globals
static CBPeripheral * activePeripheral;

// get list for things that support [thing UUIDString]

NSString * uuidList(NSArray * array){
	BOOL first = YES;
	NSString * list = @"[";
	for (CBUUID * uuid in array){
		if (first){
			first = NO;
		} else {
			list = [list stringByAppendingString:@", "];
		}
		list = [list stringByAppendingString:[uuid UUIDString]];
	}
	list = [list stringByAppendingString:@"]"];
	return list;
}

// get list for things that support [[thing UUID] UUIDString]

NSString * uuidListIndirect(NSArray * array){
	BOOL first = YES;
	NSString * list = @"[";
	for (CBService * service in array){
		if (first){
			first = NO;
		} else {
			list = [list stringByAppendingString:@", "];
		}
		list = [list stringByAppendingString:[[service UUID] UUIDString]];
	}
	list = [list stringByAppendingString:@"]"];
	return list;
}

// get properties as human string

NSString * propertiesDescription(int properties){
	NSString * list = @"";
	int i;
	for (i=0;i<10;i++){
		if (properties & (1<<i)){
			if ([list length]){
				list = [list stringByAppendingString:@", "];
			}
			list = [list stringByAppendingFormat:@"%s", propertyNames[i]];
		}
	}
	return list;
}

// Categories for pretty print

@implementation NSData (CBLogger)
-(NSString*)hexdump {
	
	int i;
	uint32_t size = self.length;
	uint8_t * data = (uint8_t *) self.bytes;

    NSMutableString *output = [NSMutableString stringWithCapacity:size * 4 + 2];
    for(i = 0; i < size; i++){
        [output appendFormat:@"%02x ",data[i]];
    }
    [output appendString:@"  "];
    for(i = 0; i < size; i++){
    	char c = (char) data[i];
    	if (c >= 0x20 && c <= 0x7f){
	        [output appendFormat:@"%c",data[i]];
    	} else {
			[output appendString:@"."];    		
    	}
    }
    return output;
}
@end

@implementation NSArray (CBLogger)
-(NSString *)uuidList{
	return uuidList(self);
}
@end

@implementation CBPeripheral (CBLogger)
-(NSString *) shortDescription {
	return [NSString stringWithFormat:@"<%@/%@>", [[self identifier] UUIDString], [self name]];
}
-(NSString *) servicesDescription{
	return uuidListIndirect(self.services);
}
@end

@implementation CBService (CBLogger)
-(NSString *) includedServicesDescription{
	return uuidListIndirect(self.includedServices);
}
-(NSString *) characteristicsDescription{
	return uuidListIndirect(self.characteristics);
}
@end

@implementation CBCharacteristic (CBLogger)
-(NSString *) descriptorDescription{
	return uuidListIndirect(self.descriptors);
}
@end

#ifndef ENABLE_RAW_MODE
static void peripheralActive(CBPeripheral * peripheral){
	if (peripheral == activePeripheral) return;
	NSLog(@"CBL: Active peripheral: %@", [peripheral shortDescription]);
	activePeripheral = peripheral;
}
#endif

// Delegate Logging Helpers

@implementation CBLoggerCentralManagerDelegate
-(void)setDelegate:(id<CBCentralManagerDelegate>)delegate{
	appDelegate = delegate;
}
-(id<CBCentralManagerDelegate>) delegate{
	return appDelegate;
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBCentralManagerDelegate centralManagerDidUpdateState:] new state+%u", (int) [central state]);
#endif
	[self.delegate centralManagerDidUpdateState:central];
}
- (void)centralManager:(CBCentralManager *)central 
 didDiscoverPeripheral:(CBPeripheral *)peripheral 
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData 
                  RSSI:(NSNumber *)RSSI{
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBCentralManagerDelegate centralManager:didDiscoverPeripheral:advertisementData:RSSI:] peripheral=%@, advertisementdata=%@, RSSI: %d",
		[peripheral shortDescription], advertisementData, [RSSI intValue]);
#else
	NSLog(@"CBL: Found peripheral %@, RSSI %d, adv data %@", [peripheral shortDescription], [RSSI intValue], advertisementData);
#endif
	if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]){
		[self.delegate centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
	} else {
		NSLog(@"CBL: %@ does not implement centralManager:didDiscoverPeripheral:advertisementData:RSSI:", [self.delegate class]);
	}
}
- (void)centralManager:(CBCentralManager *)central 
didFailToConnectPeripheral:(CBPeripheral *)peripheral 
                 error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
    NSLog(@"-[CBCentralManagerDelegate centralManager:didFailToConnectPeripheral:error:] peripheral=%@, error=%@", [peripheral shortDescription], error);
#else
    NSLog(@"CBL: Connection to peripheral %@ failed, error %@", [peripheral shortDescription], error);
#endif
	if ([self.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]){
	    [self.delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
	} else {
		NSLog(@"CBL: %@ does not implement centralManager:didFailToConnectPeripheral:error:", [self.delegate class]);
	}
}
- (void)centralManager:(CBCentralManager *)central 
  didConnectPeripheral:(CBPeripheral *)peripheral{
#ifdef ENABLE_RAW_MODE
  	NSLog(@"-[CBCentralManagerDelegate centralManager:didConnectPeripheral:] peripheral=%@", [peripheral shortDescription]);
#else
  	NSLog(@"CBL: Connected to peripheral %@", [peripheral shortDescription]);
#endif
	if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]){
	  	[self.delegate centralManager:central didConnectPeripheral:peripheral];
	} else {
		NSLog(@"CBL: %@ does not implement centralManager:didConnectPeripheral:", [self.delegate class]);
	}
}

- (void)centralManager:(CBCentralManager *)central 
didDisconnectPeripheral:(CBPeripheral *)peripheral 
                 error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
  	NSLog(@"-[CBCentralManagerDelegate centralManager:didDisconnectPeripheral:error:] peripheral=%@, error=%@", [peripheral shortDescription], error);
#else
  	NSLog(@"CBL: Disconnected from peripheral %@", [peripheral shortDescription]);
#endif
	if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]){
	  	[self.delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement centralManager:didDisconnectPeripheral:error:", [self.delegate class]);
  	}
}
@end

@implementation CBLoggerPeripheralDelegate
-(void)setDelegate:(id<CBPeripheralDelegate>)delegate{
	appDelegate = delegate;
}
-(id<CBPeripheralDelegate>) delegate{
	return appDelegate;
}
- (void) peripheral:(CBPeripheral *)peripheral 
didDiscoverServices:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverServices:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverServices:], list:");
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Failed to discover services, error %@@", error);
	} else {
		NSLog(@"CBL: Discovered services, list:");
	}
#endif
	if (!error){
		for (CBService * service in peripheral.services){
			NSLog(@"     - Service %@ ", [[service UUID] UUIDString]);
		}
	}
	if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]){
		[self.delegate peripheral:peripheral didDiscoverServices:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didDiscoverServices:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverIncludedServicesForService:(CBService *)service 
             error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverIncludedServicesForService:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverIncludedServicesForService:], service UUID=%@", [[service UUID] UUIDString]);
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Failed to discover included services for service %@, error %@", [[service UUID] UUIDString], error);
	} else {
		NSLog(@"CBL: Discovered included services for service %@, list:", [[service UUID] UUIDString]);
	}
#endif
	if (!error){
		for (CBService * includedService in service.includedServices){
			NSLog(@"     - Included Service %@ ", [[includedService UUID] UUIDString]);
		}
	}
	if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)]){
		[self.delegate peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didDiscoverIncludedServicesForService:error:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverCharacteristicsForService:(CBService *)service 
             error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverCharacteristicsForService:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverCharacteristicsForService:], service UUID=%@", [[service UUID] UUIDString]);
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Failed to discover characteristics for service %@, error=%@", [[service UUID] UUIDString], error);
	} else {
		NSLog(@"CBL: Discovered characteristics for service %@, list:", [[service UUID] UUIDString]);
	}
#endif
	if (!error){
		for (CBCharacteristic * characteristic in service.characteristics){
			NSLog(@"     - Characteristic %@ - Properties %@", [[characteristic UUID] UUIDString], propertiesDescription(characteristic.properties));
		}
	}
	if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]){
		[self.delegate peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didDiscoverCharacteristicsForService:error:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverDescriptorsForCharacteristic:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverDescriptorsForCharacteristic:], descriptors UUIDs=%@", [characteristic descriptorDescription]);
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Failed to discover descriptors for characteristic %@, error=%@", [[characteristic UUID] UUIDString], error);
	} else {
		NSLog(@"CBL: Discovered descriptors for characteristic %@: list: %@", [[characteristic UUID] UUIDString], [characteristic descriptorDescription]);
	}
#endif
	if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]){
		[self.delegate peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didDiscoverDescriptorsForCharacteristic:error:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateValueForCharacteristic:], error=%@", error);
	} else {
		NSString* newStr = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateValueForCharacteristic:], characteristic UUID=%@, value=%@ ('%@')", [[characteristic UUID] UUIDString], characteristic.value, newStr);
		[newStr release];
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Characteristic %@ value update failed, error %@", [[characteristic UUID] UUIDString], error);
	} else {
		NSLog(@"CBL: Characteristic %@ new value: %@", [[characteristic UUID] UUIDString], [characteristic.value hexdump]);
	}
#endif
	if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]){
		[self.delegate peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didUpdateValueForCharacteristic:error:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateValueForDescriptor:(CBDescriptor *)descriptor 
             error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateValueForDescriptor:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateValueForDescriptor:], descriptor UUID=%@, value=%@", [[descriptor UUID] UUIDString], descriptor.value);
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Descriptor %@ value update failed, error %@", [[descriptor UUID] UUIDString], error);
	} else {
		NSLog(@"CBL: Descriptor %@ new: value %@", [[descriptor UUID] UUIDString], [descriptor.value hexdump]);
	}
#endif
	if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]){
		[self.delegate peripheral:peripheral didUpdateValueForDescriptor:descriptor error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didUpdateValueForDescriptor:error:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral 
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didWriteValueForCharacteristic:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didWriteValueForCharacteristic:], characteristic UUID=%@", [[characteristic UUID] UUIDString]);
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Write characteristic %@ failed, error %@", [[characteristic UUID] UUIDString], error);
	} else {
		NSLog(@"CBL: Write characteristic %@ succeeded", [[characteristic UUID] UUIDString]);
	}
#endif
	if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]){
		[self.delegate peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didWriteValueForCharacteristic:error:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral 
didWriteValueForDescriptor:(CBDescriptor *)descriptor 
             error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didWriteValueForDescriptor:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didWriteValueForDescriptor:], descriptor UUID=%@", [[descriptor UUID] UUIDString]);
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Write descriptor %@ failed, error %@", [[descriptor UUID] UUIDString], error);
	} else {
		NSLog(@"CBL: Write descriptor %@ succeeded", [[descriptor UUID] UUIDString]);
	}
#endif
	if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)]){
		[self.delegate peripheral:peripheral didWriteValueForDescriptor:descriptor error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didWriteValueForDescriptor:error:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error{
#ifdef ENABLE_RAW_MODE
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateNotificationStateForCharacteristic:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateNotificationStateForCharacteristic:], characteristic UUID=%@", [[characteristic UUID] UUIDString]);
	}
#else
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: enable/disable notifications for characteristic %@ failed, error %@", [[characteristic UUID] UUIDString], error);
	} else {
		NSLog(@"CBL: enable/disable notifications for characteristic %@ succeeded", [[characteristic UUID] UUIDString]);
	}
#endif
	if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]){
		[self.delegate peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didUpdateNotificationStateForCharacteristic:error:", [self.delegate class]);
  	}
}
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
	peripheralActive(peripheral);
	if (error){
		NSLog(@"CBL: Reading RSSI failed, error %@", error);
	} else {
		NSLog(@"CBL: Reading RSSI succeeded, value %d", [peripheral.RSSI intValue]);
	}
	if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateRSSI:error:)]){
		[self.delegate peripheralDidUpdateRSSI:peripheral error:error];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheralDidUpdateRSSI:error:", [self.delegate class]);
  	}
}
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
	NSLog(@"CBL: New name: %@", peripheral.name);
	if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateName:)]){
		[self.delegate peripheralDidUpdateName:peripheral];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheralDidUpdateName:", [self.delegate class]);
  	}
}
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices{
	NSLog(@"CBL: Services modified, list:");
	for (CBService * includedService in invalidatedServices){
		NSLog(@"     - Invalidated Service %@ ", [[includedService UUID] UUIDString]);
	}
	if ([self.delegate respondsToSelector:@selector(peripheral:didModifyServices:)]){
		[self.delegate peripheral:peripheral didModifyServices:invalidatedServices];
  	} else {
		NSLog(@"CBL: %@ does not implement peripheral:didModifyServices:", [self.delegate class]);
  	}
}
@end

static id<CBCentralManagerDelegate> createCentralManagerDelegate(id<CBCentralManagerDelegate> appDelegate){
	CBLoggerCentralManagerDelegate * loggerDelegate = [CBLoggerCentralManagerDelegate new];
	[loggerDelegate setDelegate:appDelegate];
	return loggerDelegate;
}

static id<CBPeripheralDelegate> createPeripheralDelegate(id<CBPeripheralDelegate> appDelegate){
	CBLoggerPeripheralDelegate * loggerDelegate = [CBLoggerPeripheralDelegate new];
	[loggerDelegate setDelegate:appDelegate];
	return loggerDelegate;
}

static int inside_init;

// Hook Stuff

%hook CBCentralManager
- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate 
                           queue:(dispatch_queue_t)queue{
	inside_init = 1;
#ifdef ENABLE_RAW_MODE
	NSLog(@"+[CBCentralManager initWithDelegate:queue:] delegate %@", delegate);
#endif
	delegate = createCentralManagerDelegate(delegate);
	self = %orig;
	inside_init = 0;
	return self;
}
- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate 
                           queue:(dispatch_queue_t)queue 
                         options:(NSDictionary<NSString *,id> *)options{
	if (!inside_init){
#ifdef ENABLE_RAW_MODE
		NSLog(@"+[CBCentralManager initWithDelegate:queue:options:] delegate %@, options %@", delegate, options);
#endif
		delegate = createCentralManagerDelegate(delegate);
	}
	return %orig;
}
- (void)scanForPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs 
                               options:(NSDictionary<NSString *,id> *)options{
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBCentralManager scanForPeripheralsWithServices:options:] options=%@", options);
#else
	NSLog(@"CBL: Scan for peripherals with services %@, options %@", uuidList(serviceUUIDs), options);
#endif
	%orig;
}
- (void)stopScan{
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBCentralManager stopScan:]");
#else
	NSLog(@"CBL: Stop scanning");
#endif
	%orig;
}
- (void)connectPeripheral:(CBPeripheral *)peripheral 
                  options:(NSDictionary<NSString *,id> *)options{
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBCentralManager connectPeripheral:options:] peripheral=%@, options=%@", [peripheral shortDescription], options);
#else
	NSLog(@"CBL: Connect to peripheral %@, options %@", [peripheral shortDescription], options);
#endif
	%orig;
}
%end

%hook CBPeripheral
-(void)setDelegate:(id<CBPeripheralDelegate>)delegate{
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral setDelegate:] peripheral %@, delegate %@", self, delegate);
#endif
	delegate = createPeripheralDelegate(delegate);
	%orig;
}
- (void)discoverServices:(NSArray<CBUUID *> *)serviceUUIDs{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral discoverServices:], peripheral=%@, service UUIDs=%@",
		[self shortDescription], [serviceUUIDs uuidList]);
#else
	NSLog(@"CBL: Discover services %@", [serviceUUIDs uuidList]);
#endif
	%orig;
}
- (void)discoverIncludedServices:(NSArray<CBUUID *> *)includedServiceUUIDs 
                      forService:(CBService *)service{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral discoverIncludedServices:forService:], peripheral=%@, included service UUIDs=%@, service=%@",
		[self shortDescription], [includedServiceUUIDs uuidList], [[service UUID] UUIDString]);
#else
	NSLog(@"CBL: Discover included services %@", [includedServiceUUIDs uuidList]);
#endif
	%orig;
}
- (void)discoverCharacteristics:(NSArray<CBUUID *> *)characteristicUUIDs 
                     forService:(CBService *)service{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral discoverCharacteristics:forService:], peripheral=%@, service UUID=%@, characteristic UUIDs=%@",
		[self shortDescription], [[service UUID] UUIDString], [characteristicUUIDs uuidList]);
#else
	NSLog(@"CB: Discover characteristics %@ for service %@", [characteristicUUIDs uuidList], [[service UUID] UUIDString]);
#endif
	%orig;
}
- (void)discoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral discoverDescriptorsForCharacteristic:], peripheral=%@, characteristic UUID=%@",
		[self shortDescription], [[characteristic UUID] UUIDString]);
#else
	NSLog(@"CBL: Discover descriptors for characteristic %@", [[characteristic UUID] UUIDString]);
#endif
	%orig;
}
- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral readValueForCharacteristic:], peripheral=%@, characteristic UUID=%@",
		[self shortDescription], [[characteristic UUID] UUIDString]);
#else
	NSLog(@"CBL: Read characteristic %@", [[characteristic UUID] UUIDString]);
#endif
	%orig;
}
- (void)readValueForDescriptor:(CBDescriptor *)descriptor{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral readValueForDescriptor:], peripheral=%@, descriptor UUID=%@",
		[self shortDescription], [[descriptor UUID] UUIDString]);
#else
	NSLog(@"CBL: Read descriptor %@", [[descriptor UUID] UUIDString]);
#endif
	%orig;
}
- (void)writeValue:(NSData *)data 
 forCharacteristic:(CBCharacteristic *)characteristic 
              type:(CBCharacteristicWriteType)type{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"-[CBPeripheral writeValue:forCharacteristic:type:], peripheral=%@, characteristic UUID=%@, type=%u, data=%@ ('%@')",
		[self shortDescription], [[characteristic UUID] UUIDString], (int)type, data, newStr);
	[newStr release];
#else
	switch (type){
		case CBCharacteristicWriteWithResponse:
			NSLog(@"CBL: Write characteristic %@ with response, value: %@",  [[characteristic UUID] UUIDString], [data hexdump]);
			break;
		case CBCharacteristicWriteWithoutResponse:
			NSLog(@"CBL: Write characteristic %@ without response, value: %@",  [[characteristic UUID] UUIDString], [data hexdump]);
			break;
		default:
			break;
	}
#endif
	%orig;
}
- (void)writeValue:(NSData *)data 
     forDescriptor:(CBDescriptor *)descriptor{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral writeValue:forDescriptor:], peripheral=%@, characteristic UUID=%@, data=%@",
		[self shortDescription], [[descriptor UUID] UUIDString], data);
#else
	NSLog(@"CBL: Write descriptor %@, value: %@",  [[descriptor UUID] UUIDString], [data hexdump]);
#endif
	%orig;
}
- (void)setNotifyValue:(BOOL)enabled 
     forCharacteristic:(CBCharacteristic *)characteristic{
	peripheralActive(self);
#ifdef ENABLE_RAW_MODE
	NSLog(@"-[CBPeripheral setNotifyValue:forCharacteristic:], peripheral=%@, characteristic UUID=%@, enabled=%u",
		[self shortDescription], [[characteristic UUID] UUIDString], enabled);
#else
	if (enabled){
		NSLog(@"CBL: Enable notification for characteristic %@", [[characteristic UUID] UUIDString]);
	} else {
		NSLog(@"CBL: Disable notification for characteristic %@", [[characteristic UUID] UUIDString]);
	}
#endif
	%orig;
}
%end
