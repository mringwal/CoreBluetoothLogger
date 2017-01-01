#import <CoreBluetooth/CoreBluetooth.h>

static id<CBCentralManagerDelegate> appCentralManagerDelegate;
static id<CBCentralManagerDelegate> loggerCentralManagerDelegate;

@implementation CBPeripheral (Logger)
-(NSString *) shortDescription {
	return [NSString stringWithFormat:@"<%@/%@>", [[self identifier] UUIDString], [self name]];
}
@end

@interface GATTLoggerCentralManagerDelegate : NSObject<CBCentralManagerDelegate>
@end
@implementation GATTLoggerCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
	NSLog(@"-{CBCentralManagerDelegate centralManagerDidUpdateState:]");
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

static id<CBCentralManagerDelegate> getCentralManagerDelegate(void){
	if (!loggerCentralManagerDelegate){
		loggerCentralManagerDelegate = [GATTLoggerCentralManagerDelegate new];
	}
	return loggerCentralManagerDelegate;
}

static int inside_init;

%hook CBCentralManager
- (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate 
                           queue:(dispatch_queue_t)queue
{
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
                         options:(NSDictionary<NSString *,id> *)options
{
	if (!inside_init){
		NSLog(@"+[CBCentralManager initWithDelegate:queue:options:] options %@", options);
		appCentralManagerDelegate = delegate;
		delegate = getCentralManagerDelegate();
	}
	return %orig(getCentralManagerDelegate(), queue, options);
}

- (void)connectPeripheral:(CBPeripheral *)peripheral 
                  options:(NSDictionary<NSString *,id> *)options
{
	NSLog(@"-[CBCentralManager connectPeripheral:options:] peripheral=%@", [peripheral shortDescription]);
	%orig;
}

- (void)scanForPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs 
                               options:(NSDictionary<NSString *,id> *)options
{
	NSLog(@"-[CBCentralManager scanForPeripheralsWithServices:options:]");
	%orig;
}

- (void)stopScan
{
	NSLog(@"-[CBCentralManager stopScan:]");
	%orig;
}

%end
