#import <UIKit/UIKit.h>

// 配置文件: defaults write /var/mobile/Library/Preferences/com.biefan.speedspring.plist enabled -bool true
//           defaults write /var/mobile/Library/Preferences/com.biefan.speedspring.plist speed -float 2.0
// 修改后无需 respring,执行一次即可热更新:
//           notifyutil -p com.biefan.speedspring/reload

static NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.biefan.speedspring.plist";
#define kReloadNotifyName "com.biefan.speedspring/reload"

static const float kDefaultSpeed = 1.8f;
static const float kMinSpeed = 1.0f;
static const float kMaxSpeed = 5.0f;

static float gSpeed = kDefaultSpeed;

static float ClampSpeed(float speed) {
    return MAX(kMinSpeed, MIN(kMaxSpeed, speed));
}

static void ReloadPrefs(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    NSNumber *enabled = prefs[@"enabled"];
    if (enabled && ![enabled boolValue]) {
        gSpeed = kMinSpeed;
        return;
    }
    NSNumber *speed = prefs[@"speed"];
    gSpeed = ClampSpeed(speed ? [speed floatValue] : kDefaultSpeed);
}

// 设备过热或已开启低电量模式时,系统已经在主动省电,这时把倍速强制收回 1.0x,
// 避免额外的动画渲染开销添油加醋。
static float EffectiveSpeed(void) {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if (info.isLowPowerModeEnabled || info.thermalState >= NSProcessInfoThermalStateSerious) {
        return kMinSpeed;
    }
    return gSpeed;
}

static void ApplyToExistingWindows(void) {
    float speed = EffectiveSpeed();
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        window.layer.speed = speed;
    }
}

static void ReloadNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    ReloadPrefs();
    ApplyToExistingWindows();
}

%hook UIWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        self.layer.speed = EffectiveSpeed();
    }
    return self;
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    [[NSNotificationCenter defaultCenter] addObserverForName:NSProcessInfoThermalStateDidChangeNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification *note) {
        ApplyToExistingWindows();
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSProcessInfoPowerStateDidChangeNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification *note) {
        ApplyToExistingWindows();
    }];
}

%end

%ctor {
    ReloadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ReloadNotifyCallback,
                                     CFSTR(kReloadNotifyName), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
