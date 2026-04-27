//
//  AppDelegate.h
//  ClipboardManager
//
//  Created by Riley Koo on 4/22/26.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

// Menu bar item
@property (strong, nonatomic) NSStatusItem *statusItem;

// Clipboard monitoring
@property (strong, nonatomic) NSTimer *clipboardTimer;
@property (assign, nonatomic) NSInteger lastChangeCount;

// Storage for clipboard history
@property (strong, nonatomic) NSMutableArray<NSString *> *clipboardHistory;
@property (strong, nonatomic) NSMutableArray<NSString *> *pinned;

// Maximum number of items to store
@property (assign, nonatomic) NSInteger maxHistorySize;
@property (assign, nonatomic) NSInteger currentHistoryIndex;
@property (strong, nonatomic) NSTimer *cycleResetTimer;
@property (strong, nonatomic) id eventMonitor;

@property (strong, nonatomic) NSPanel *toastPanel;


// Methods you'll implement
- (void)setupMenuBar;
- (void)startClipboardMonitoring;
- (void)checkClipboard:(NSTimer *)timer;
- (void)addToHistory:(NSString *)text;
- (void)updateMenu;
- (void)copyHistoryItemToPasteboard:(id)sender;
- (void)deleteHistoryItem:(id)sender;
- (void)pinItem:(id)sender;
- (void)cycleToPreviousClipboard;
- (void)finalizeCycleSelection;
- (void)registerHotkey;
- (void)showToast:(NSString *)text;

@end
