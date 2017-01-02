#import <CoreBluetooth/CoreBluetooth.h>

@interface GATTLoggerCentralManagerDelegate : NSObject<CBCentralManagerDelegate>
@end

@interface GATTLoggerPeripheralDelegate : NSObject<CBPeripheralDelegate>
@end

// intercepted delegates

static id<CBCentralManagerDelegate> appCentralManagerDelegate;
static id<CBCentralManagerDelegate> loggerCentralManagerDelegate;
static id<CBPeripheralDelegate>     appPeripheralDelegate;
static id<CBPeripheralDelegate>     loggerPeripheralDelegate;

// get list for things that support [[thing UUID] UUIDString]

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
	return list;
}

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

@implementation NSArray (Logger)
-(NSString *)uuidList{
	return uuidList(self);
}
@end

@implementation CBPeripheral (Logger)
-(NSString *) shortDescription {
	return [NSString stringWithFormat:@"<%@/%@>", [[self identifier] UUIDString], [self name]];
}
-(NSString *) servicesDescription{
	return uuidListIndirect(self.services);
}
@end

@implementation CBService (Logger)
-(NSString *) includedServicesDescription{
	return uuidListIndirect(self.includedServices);
}
-(NSString *) characteristicsDescription{
	return uuidListIndirect(self.characteristics);
}
@end

@implementation CBCharacteristic
-(NSString *) descriptorDescription{
	return uuidListIndirect(self.descriptors);
}
@end

// Delegate Logging Helpers

@implementation GATTLoggerCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
	NSLog(@"-{CBCentralManagerDelegate centralManagerDidUpdateState:] new state+%u", (int) [central state]);
	[appCentralManagerDelegate centralManagerDidUpdateState:central];
}
- (void)centralManager:(CBCentralManager *)central 
 didDiscoverPeripheral:(CBPeripheral *)peripheral 
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData 
                  RSSI:(NSNumber *)RSSI{
	NSLog(@"-[CBCentralManagerDelegate centralManager:didDiscoverPeripheral:advertisementData:RSSI:] peripheral=%@, advertisementdata=%@, RSSI: %d",
		[peripheral shortDescription], advertisementData, [RSSI intValue]);
	[appCentralManagerDelegate centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
}
- (void)centralManager:(CBCentralManager *)central 
didFailToConnectPeripheral:(CBPeripheral *)peripheral 
                 error:(NSError *)error{
    NSLog(@"-[CBCentralManagerDelegate centralManager:didFailToConnectPeripheral:error:] peripheral=%@, error=%@", [peripheral shortDescription], error);
    [appCentralManagerDelegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
}
- (void)centralManager:(CBCentralManager *)central 
  didConnectPeripheral:(CBPeripheral *)peripheral{
  	NSLog(@"-[CBCentralManagerDelegate centralManager:didConnectPeripheral:] peripheral=%@", [peripheral shortDescription]);
  	[appCentralManagerDelegate centralManager:central didConnectPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central 
didDisconnectPeripheral:(CBPeripheral *)peripheral 
                 error:(NSError *)error{
  	NSLog(@"-[CBCentralManagerDelegate centralManager:didDisconnectPeripheral:error:] peripheral=%@, error=%@", [peripheral shortDescription], error);
  	[appCentralManagerDelegate centralManager:central didDisconnectPeripheral:peripheral error:error];
}
@end

@implementation GATTLoggerPeripheralDelegate
- (void) peripheral:(CBPeripheral *)peripheral 
didDiscoverServices:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverServices:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverServices:], list:");
		for (CBService * service in peripheral.services){
			NSLog(@"    Service %@ ", [[service UUID] UUIDString]);
		}
	}
	[appPeripheralDelegate peripheral:peripheral didDiscoverServices:error];
}
- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverIncludedServicesForService:(CBService *)service 
             error:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverIncludedServicesForService:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverIncludedServicesForService:], service UUID=%@", [[service UUID] UUIDString]);
		for (CBService * includedService in service.includedServices){
			NSLog(@"    Included Service %@ ", [[includedService UUID] UUIDString]);
		}
	}
	[appPeripheralDelegate peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
}
- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverCharacteristicsForService:(CBService *)service 
             error:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverCharacteristicsForService:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverCharacteristicsForService:], service UUID=%@", [[service UUID] UUIDString]);
		for (CBCharacteristic * characteristic in service.characteristics){
			NSLog(@"    Characteristic %@ - Properties %@", [[characteristic UUID] UUIDString], propertiesDescription(characteristic.properties));
		}
	}
	[appPeripheralDelegate peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
}
- (void)peripheral:(CBPeripheral *)peripheral 
didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverDescriptorsForCharacteristic:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didDiscoverDescriptorsForCharacteristic:], descriptors UUIDs=%@", [characteristic descriptorDescription]);
	}
	[appPeripheralDelegate peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:error];
}
- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateValueForCharacteristic:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateValueForCharacteristic:], characteristic UUID=%@, value=%@", [[characteristic UUID] UUIDString], characteristic.value);
	}
	[appPeripheralDelegate peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
}
- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateValueForDescriptor:(CBDescriptor *)descriptor 
             error:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateValueForDescriptor:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateValueForDescriptor:], descriptor UUID=%@, value=%@", [[descriptor UUID] UUIDString], descriptor.value);
	}
	[appPeripheralDelegate peripheral:peripheral didUpdateValueForDescriptor:descriptor error:error];
}
- (void)peripheral:(CBPeripheral *)peripheral 
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didWriteValueForCharacteristic:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didWriteValueForCharacteristic:], characteristic UUID=%@", [[characteristic UUID] UUIDString]);
	}
	[appPeripheralDelegate peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
}
- (void)peripheral:(CBPeripheral *)peripheral 
didWriteValueForDescriptor:(CBDescriptor *)descriptor 
             error:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didWriteValueForDescriptor:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didWriteValueForDescriptor:], descriptor UUID=%@", [[descriptor UUID] UUIDString]);
	}
	[appPeripheralDelegate peripheral:peripheral didWriteValueForDescriptor:descriptor error:error];
}
- (void)peripheral:(CBPeripheral *)peripheral 
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic 
             error:(NSError *)error{
	if (error){
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateNotificationStateForCharacteristic:], error=%@", error);
	} else {
		NSLog(@"-[CBPeripheralDelegate peripheral:didUpdateNotificationStateForCharacteristic:], characteristic UUID=%@", [[characteristic UUID] UUIDString]);
	}
	[appPeripheralDelegate peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:error];
}
@end

static id<CBCentralManagerDelegate> getCentralManagerDelegate(void){
	if (!loggerCentralManagerDelegate){
		loggerCentralManagerDelegate = [GATTLoggerCentralManagerDelegate new];
	}
	return loggerCentralManagerDelegate;
}

static id<CBPeripheralDelegate> getPeripheralDelegate(void){
	if (!loggerPeripheralDelegate){
		loggerPeripheralDelegate = [GATTLoggerPeripheralDelegate new];
	}
	return loggerPeripheralDelegate;
}

static int inside_init;

// Hook Stuff

%hook CBCentralManager
- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate 
                           queue:(dispatch_queue_t)queue{
	inside_init = 1;
	NSLog(@"+[CBCentralManager initWithDelegate:queue:]");
	appCentralManagerDelegate = delegate;
	delegate = getCentralManagerDelegate();
	self = %orig;
	inside_init = 0;
	return self;
}

- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate 
                           queue:(dispatch_queue_t)queue 
                         options:(NSDictionary<NSString *,id> *)options{
	if (!inside_init){
		NSLog(@"+[CBCentralManager initWithDelegate:queue:options:] options %@", options);
		appCentralManagerDelegate = delegate;
		delegate = getCentralManagerDelegate();
	}
	return %orig(getCentralManagerDelegate(), queue, options);
}

- (void)connectPeripheral:(CBPeripheral *)peripheral 
                  options:(NSDictionary<NSString *,id> *)options{
	NSLog(@"-[CBCentralManager connectPeripheral:options:] peripheral=%@, options=%@", [peripheral shortDescription], options);
	%orig;
}

- (void)scanForPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs 
                               options:(NSDictionary<NSString *,id> *)options{
	NSLog(@"-[CBCentralManager scanForPeripheralsWithServices:options:] options=%@", options);
	%orig;
}

- (void)stopScan{
	NSLog(@"-[CBCentralManager stopScan:]");
	%orig;
}
%end

%hook CBPeripheral
-(void)setDelegate:(id<CBPeripheralDelegate>)delegate{
	NSLog(@"-[CBPeripheral setDelegate:]");
	appPeripheralDelegate = delegate;
	delegate = getPeripheralDelegate();
	%orig;
}
- (void)discoverServices:(NSArray<CBUUID *> *)serviceUUIDs{
	NSLog(@"-[CBPeripheral discoverServices:], peripheral=%@, service UUIDs=%@",
		[self shortDescription], [serviceUUIDs uuidList]);
	%orig;
}
- (void)discoverIncludedServices:(NSArray<CBUUID *> *)includedServiceUUIDs 
                      forService:(CBService *)service{
	NSLog(@"-[CBPeripheral discoverIncludedServices:forService:], peripheral=%@, included service UUIDs=%@, service=%@",
		[self shortDescription], [includedServiceUUIDs uuidList], [[service UUID] UUIDString]);
	%orig;
}
- (void)discoverCharacteristics:(NSArray<CBUUID *> *)characteristicUUIDs 
                     forService:(CBService *)service{
	NSLog(@"-[CBPeripheral discoverCharacteristics:forService:], peripheral=%@, service UUID=%@, characteristic UUIDs=%@",
		[self shortDescription], [[service UUID] UUIDString], [characteristicUUIDs uuidList]);
	%orig;
}
- (void)discoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic{
	NSLog(@"-[CBPeripheral discoverDescriptorsForCharacteristic:], peripheral=%@, characteristic UUID=%@",
		[self shortDescription], [[characteristic UUID] UUIDString]);
	%orig;
}
- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic{
	NSLog(@"-[CBPeripheral readValueForCharacteristic:], peripheral=%@, characteristic UUID=%@",
		[self shortDescription], [[characteristic UUID] UUIDString]);
	%orig;
}
- (void)readValueForDescriptor:(CBDescriptor *)descriptor{
	NSLog(@"-[CBPeripheral readValueForDescriptor:], peripheral=%@, descriptor UUID=%@",
		[self shortDescription], [[descriptor UUID] UUIDString]);
	%orig;
}
- (void)writeValue:(NSData *)data 
 forCharacteristic:(CBCharacteristic *)characteristic 
              type:(CBCharacteristicWriteType)type{
	NSLog(@"-[CBPeripheral writeValue:forCharacteristic:type:], peripheral=%@, characteristic UUID=%@, type=%u, data=%@",
		[self shortDescription], [[characteristic UUID] UUIDString], (int)type, data);
}
- (void)writeValue:(NSData *)data 
     forDescriptor:(CBDescriptor *)descriptor{
	NSLog(@"-[CBPeripheral writeValue:forDescriptor:], peripheral=%@, characteristic UUID=%@, data=%@",
		[self shortDescription], [[descriptor UUID] UUIDString], data);
}
- (void)setNotifyValue:(BOOL)enabled 
     forCharacteristic:(CBCharacteristic *)characteristic{
	NSLog(@"-[CBPeripheral setNotifyValue:forCharacteristic:], peripheral=%@, characteristic UUID=%@, enabled=%u",
		[self shortDescription], [[characteristic UUID] UUIDString], enabled);
}
%end
