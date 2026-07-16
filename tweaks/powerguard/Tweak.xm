#import <UIKit/UIKit.h>
#import <FrontBoard/FBProcessManager.h>
#import <FrontBoard/FBApplicationProcess.h>
#import <LowPowerMode/LowPowerMode.h>

// iOS 不像安卓那样对越狱插件开放 CPU 调频/governor 接口,强行设置最高频率需要动内核层,
// 风险和复杂度是另一回事,不在这个插件范畴内。PowerGuard 做两件事:
//   1. 低电量且没充电时,自动打开系统的低电量模式(iOS 官方的 CPU/GPU 降频、后台限制机制),
//      充电或电量回升后自动关闭,跟系统自己在电量 20% 时弹的提示是同一套开关,只是自动化了。
//   2. 设备过热,或者低电量模式已经开着(不管是不是这个插件开的)时,顺手清理一遍后台 App。
//
// FBProcessManager / FBApplicationProcess 是私有类,已对照 Theos vendor 头文件核实签名
// (FrontBoard/FBProcessManager.h, FrontBoard/FBApplicationProcess.h)。
// _PLLowPowerMode 来自 LowPowerMode.framework(vendor/include/LowPowerMode),
// 头文件标注 API_AVAILABLE(ios(15.0)),跟这个插件的最低系统要求一致。
// killForReason: 的 reason 取值没有文档化的枚举,这里用 0。

// 配置文件: defaults write /var/mobile/Library/Preferences/com.biefan.powerguard.plist enabled -bool true
//           defaults write /var/mobile/Library/Preferences/com.biefan.powerguard.plist whitelist -array "com.your.app"
//           defaults write /var/mobile/Library/Preferences/com.biefan.powerguard.plist autoLPM -bool true
//           defaults write /var/mobile/Library/Preferences/com.biefan.powerguard.plist lowBatteryThreshold -int 20
//           defaults write /var/mobile/Library/Preferences/com.biefan.powerguard.plist restoreBatteryThreshold -int 80
// 修改后热更新: notifyutil -p com.biefan.powerguard/reload

static NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.biefan.powerguard.plist";
#define kReloadNotifyName "com.biefan.powerguard/reload"

static const NSTimeInterval kMinSweepInterval = 300.0;

static BOOL gEnabled = YES;
static BOOL gAutoLPMEnabled = YES;
static float gLowBatteryThreshold = 0.20f;
static float gRestoreBatteryThreshold = 0.80f;
static NSSet<NSString *> *gWhitelist;
static NSTimeInterval gLastSweepAt = 0;

static NSSet<NSString *> *DefaultWhitelist(void) {
    return [NSSet setWithArray:@[
        @"com.apple.springboard",
        @"com.apple.mobilephone",
        @"com.apple.MobileSMS",
    ]];
}

static void ReloadPrefs(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];

    NSNumber *enabled = prefs[@"enabled"];
    gEnabled = enabled ? [enabled boolValue] : YES;

    NSNumber *autoLPM = prefs[@"autoLPM"];
    gAutoLPMEnabled = autoLPM ? [autoLPM boolValue] : YES;

    NSNumber *lowThreshold = prefs[@"lowBatteryThreshold"];
    gLowBatteryThreshold = lowThreshold ? ([lowThreshold floatValue] / 100.0f) : 0.20f;

    NSNumber *restoreThreshold = prefs[@"restoreBatteryThreshold"];
    gRestoreBatteryThreshold = restoreThreshold ? ([restoreThreshold floatValue] / 100.0f) : 0.80f;

    NSMutableSet *whitelist = [DefaultWhitelist() mutableCopy];
    NSArray *extra = prefs[@"whitelist"];
    if ([extra isKindOfClass:[NSArray class]]) {
        [whitelist addObjectsFromArray:extra];
    }
    gWhitelist = whitelist;
}

static BOOL ShouldSavePower(void) {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    return info.isLowPowerModeEnabled || info.thermalState >= NSProcessInfoThermalStateSerious;
}

static void SweepBackgroundApps(void) {
    FBProcessManager *manager = [%c(FBProcessManager) sharedInstance];
    for (FBApplicationProcess *process in [manager allApplicationProcesses]) {
        NSString *bundleID = process.bundleIdentifier;
        if (!bundleID || [gWhitelist containsObject:bundleID]) {
            continue;
        }
        [process killForReason:0 andReport:NO withDescription:@"PowerGuard: 省电清理"];
    }
}

static void EvaluateSweep(void) {
    if (!gEnabled || !ShouldSavePower()) {
        return;
    }
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - gLastSweepAt < kMinSweepInterval) {
        return;
    }
    gLastSweepAt = now;
    SweepBackgroundApps();
}

static void EvaluateAutoLPM(void) {
    if (!gEnabled || !gAutoLPMEnabled) {
        return;
    }

    UIDevice *device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = YES;
    float level = device.batteryLevel;
    if (level < 0) {
        return;
    }
    UIDeviceBatteryState state = device.batteryState;
    BOOL charging = (state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull);

    _PLLowPowerMode *lpm = [%c(_PLLowPowerMode) sharedInstance];
    BOOL currentlyOn = [lpm getPowerMode] != 0;

    if (!currentlyOn && !charging && level <= gLowBatteryThreshold) {
        [lpm setPowerMode:1 fromSource:kPMLPMSourceSettings];
    } else if (currentlyOn && (charging || level >= gRestoreBatteryThreshold)) {
        [lpm setPowerMode:0 fromSource:kPMLPMSourceSettings];
    }
}

static void EvaluateState(void) {
    EvaluateAutoLPM();
    EvaluateSweep();
}

static void ReloadNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    ReloadPrefs();
    EvaluateState();
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    ReloadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ReloadNotifyCallback,
                                     CFSTR(kReloadNotifyName), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    [UIDevice currentDevice].batteryMonitoringEnabled = YES;

    [[NSNotificationCenter defaultCenter] addObserverForName:NSProcessInfoThermalStateDidChangeNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification *note) {
        EvaluateState();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSProcessInfoPowerStateDidChangeNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification *note) {
        EvaluateState();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification *note) {
        EvaluateAutoLPM();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification *note) {
        EvaluateAutoLPM();
    }];

    EvaluateState();
}

%end
