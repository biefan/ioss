#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <FrontBoard/FBProcessManager.h>
#import <FrontBoard/FBApplicationProcess.h>

// FBProcessManager / FBApplicationProcess 是私有类,不同 iOS 版本方法可能有差异,
// 已对照 Theos vendor 头文件核实过当前签名(FrontBoard/FBProcessManager.h,
// FrontBoard/FBApplicationProcess.h),升级系统后如失效需自行重新核对。
// killForReason: 的 reason 取值在现有头文件里没有文档化的枚举,这里用 0。

// 配置文件: defaults write /var/mobile/Library/Preferences/com.biefan.memsweeper.plist enabled -bool true
//           defaults write /var/mobile/Library/Preferences/com.biefan.memsweeper.plist whitelist -array "com.your.app"
// 修改后热更新: notifyutil -p com.biefan.memsweeper/reload

static NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.biefan.memsweeper.plist";
#define kReloadNotifyName "com.biefan.memsweeper/reload"

static BOOL gEnabled = YES;
static NSSet<NSString *> *gWhitelist;

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

    NSMutableSet *whitelist = [DefaultWhitelist() mutableCopy];
    NSArray *extra = prefs[@"whitelist"];
    if ([extra isKindOfClass:[NSArray class]]) {
        [whitelist addObjectsFromArray:extra];
    }
    gWhitelist = whitelist;
}

static void SweepBackgroundApps(void) {
    if (!gEnabled) {
        return;
    }
    FBProcessManager *manager = [%c(FBProcessManager) sharedInstance];
    for (FBApplicationProcess *process in [manager allApplicationProcesses]) {
        NSString *bundleID = process.bundleIdentifier;
        if (!bundleID || [gWhitelist containsObject:bundleID]) {
            continue;
        }
        [process killForReason:0 andReport:NO withDescription:@"MemSweeper: 内存告警自动清理"];
    }
}

static void ReloadNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    ReloadPrefs();
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    ReloadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ReloadNotifyCallback,
                                     CFSTR(kReloadNotifyName), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MEMORYPRESSURE, 0,
                                                        DISPATCH_MEMORYPRESSURE_WARN | DISPATCH_MEMORYPRESSURE_CRITICAL,
                                                        dispatch_get_main_queue());
    dispatch_source_set_event_handler(source, ^{
        SweepBackgroundApps();
    });
    dispatch_resume(source);

    // dispatch_source_t 需要被强引用持有,否则会被提前释放
    objc_setAssociatedObject(self, "MemSweeperSource", source, OBJC_ASSOCIATION_RETAIN);
}

%end
