#import <UIKit/UIKit.h>

// 配置文件: defaults write /var/mobile/Library/Preferences/com.biefan.blurbegone.plist enabled -bool true
// 修改后热更新: notifyutil -p com.biefan.blurbegone/reload
//
// 默认只注入 SpringBoard(控制中心、多任务、文件夹等系统毛玻璃)。
// 如需覆盖第三方 App 内的毛玻璃效果,把 blurbegone.plist 的 Bundles 列表改成目标 App 的 bundle id。

static NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.biefan.blurbegone.plist";
#define kReloadNotifyName "com.biefan.blurbegone/reload"

static BOOL gDisabled = YES;

static void ReloadPrefs(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    NSNumber *enabled = prefs[@"enabled"];
    gDisabled = enabled ? [enabled boolValue] : YES;
}

static void ReloadNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    ReloadPrefs();
}

%hook UIVisualEffectView

- (void)setEffect:(UIVisualEffect *)effect {
    %orig(gDisabled ? nil : effect);
}

%end

%ctor {
    ReloadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ReloadNotifyCallback,
                                     CFSTR(kReloadNotifyName), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
