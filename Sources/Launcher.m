// SPDX-License-Identifier: GPL-3.0-only
#import <AppKit/AppKit.h>
#import "GameProfile.h"
#import "GameAdapter.h"
#import "OverlaySettings.h"
#import "SelectionSettings.h"
#import "TrainerMaterial.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
@interface MTLauncherBackground : NSView
@end
@implementation MTLauncherBackground
- (BOOL)isOpaque {return YES;}
- (void)drawRect:(NSRect)dirty {
    (void)dirty;
    NSGradient *gradient=[[NSGradient alloc]initWithStartingColor:[NSColor colorWithSRGBRed:0.075 green:0.08 blue:0.09 alpha:1]
        endingColor:[NSColor colorWithSRGBRed:0.13 green:0.105 blue:0.085 alpha:1]];
    [gradient drawInRect:self.bounds angle:75];
}
@end
@interface MTLauncher : NSObject <NSApplicationDelegate>
@property(nonatomic) NSWindow *window;
@property(nonatomic) NSDictionary *configuration;
@property(nonatomic) NSPopUpButton *profiles;
@property(nonatomic) NSTextField *status;
@property(nonatomic) NSButton *start;
@property(nonatomic) NSButton *restoreSelection;
@property(nonatomic) NSRunningApplication *game;
@property(nonatomic,copy) NSString *session;
@property(nonatomic,copy) NSString *runningProfileID;
@property(nonatomic) id settingsObserver,runtimeObserver,selectionObserver;
@end
@implementation MTLauncher
- (NSDictionary *)profile {return self.configuration[@"profiles"][self.profiles.indexOfSelectedItem];}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    NSError *error=nil;self.configuration=MTLoadConfiguration([NSBundle.mainBundle pathForResource:@"TrainerConfig" ofType:@"json"],&error);
    if(!self.configuration){NSAlert *a=[NSAlert new];a.messageText=error.localizedDescription;[a runModal];[NSApp terminate:nil];return;}
    self.window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,700,500) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO];
    self.window.releasedWhenClosed=NO;self.window.title=self.configuration[@"app"][@"name"];
    self.window.titlebarAppearsTransparent=NO;self.window.titleVisibility=NSWindowTitleVisible;
    self.window.appearance=[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    self.window.opaque=YES;self.window.backgroundColor=[NSColor colorWithSRGBRed:0.075 green:0.08 blue:0.09 alpha:1];
    self.window.contentView=[[MTLauncherBackground alloc]initWithFrame:self.window.contentView.bounds];
    NSColor *brass=[NSColor colorWithSRGBRed:0.83 green:0.66 blue:0.42 alpha:1];
    NSView *header=[NSView new];
    NSImageView *icon=[NSImageView new];icon.image=[[NSImage alloc]initWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"AppIcon" ofType:@"icns"]];
    icon.imageScaling=NSImageScaleProportionallyUpOrDown;icon.translatesAutoresizingMaskIntoConstraints=NO;
    icon.accessibilityElement=NO;[header addSubview:icon];
    NSTextField *eyebrow=[NSTextField labelWithString:@"TRAINER"];eyebrow.font=[NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];eyebrow.textColor=brass;
    NSTextField *title=[NSTextField labelWithString:@"Lies of P"];title.font=[NSFont fontWithName:@"Baskerville-SemiBold" size:38] ?: [NSFont boldSystemFontOfSize:36];
    title.textColor=[NSColor colorWithSRGBRed:0.97 green:0.92 blue:0.83 alpha:1];
    NSTextField *edition=[NSTextField labelWithString:@"37 Funktionen · Steam 1.14.0 · Apple Silicon"];edition.font=[NSFont systemFontOfSize:12];edition.textColor=NSColor.secondaryLabelColor;
    NSStackView *heading=[NSStackView stackViewWithViews:@[eyebrow,title,edition]];heading.orientation=NSUserInterfaceLayoutOrientationVertical;heading.alignment=NSLayoutAttributeLeading;heading.spacing=6;heading.translatesAutoresizingMaskIntoConstraints=NO;[header addSubview:heading];
    [NSLayoutConstraint activateConstraints:@[[header.heightAnchor constraintEqualToConstant:128],
        [icon.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],[icon.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:120],[icon.heightAnchor constraintEqualToConstant:120],
        [heading.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:24],
        [heading.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor],
        [heading.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]]];
    self.profiles=[[NSPopUpButton alloc]initWithFrame:NSZeroRect pullsDown:NO];
    for(NSDictionary *p in self.configuration[@"profiles"])[self.profiles addItemWithTitle:p[@"name"]];
    self.profiles.target=self;self.profiles.action=@selector(refresh:);
    NSTextField *profileLabel=[NSTextField labelWithString:@"SPIELPROFIL"];profileLabel.font=[NSFont systemFontOfSize:10 weight:NSFontWeightSemibold];profileLabel.textColor=brass;
    NSButton *choose=[NSButton buttonWithTitle:@"Spiele-App wählen …" target:self action:@selector(choose:)];
    self.restoreSelection=[NSButton checkboxWithTitle:@"Mit zuletzt benutzten Cheats starten" target:self action:@selector(changeRestoreSelection:)];
    self.restoreSelection.font=[NSFont systemFontOfSize:13];
    self.start=[NSButton buttonWithTitle:@"Lies of P mit Trainer starten" target:self action:@selector(startGame:)];
    self.start.controlSize=NSControlSizeLarge;self.start.font=[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    self.start.bezelColor=[NSColor colorWithSRGBRed:0.65 green:0.29 blue:0.14 alpha:1];self.start.contentTintColor=NSColor.whiteColor;
    NSView *spacer=[NSView new];[spacer setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    NSStackView *actions=[NSStackView stackViewWithViews:@[choose,spacer,self.start]];actions.orientation=NSUserInterfaceLayoutOrientationHorizontal;actions.alignment=NSLayoutAttributeCenterY;actions.spacing=12;
    NSView *profileContent=[NSView new];
    MTTrainerMaterial *profileSurface=[[MTTrainerMaterial alloc]initWithContentView:profileContent cornerRadius:16];
    NSStackView *controls=[NSStackView stackViewWithViews:@[profileLabel,self.profiles,self.restoreSelection,actions]];
    controls.orientation=NSUserInterfaceLayoutOrientationVertical;controls.alignment=NSLayoutAttributeLeading;controls.spacing=14;controls.translatesAutoresizingMaskIntoConstraints=NO;[profileContent addSubview:controls];
    [NSLayoutConstraint activateConstraints:@[[profileSurface.heightAnchor constraintEqualToConstant:196],
        [controls.leadingAnchor constraintEqualToAnchor:profileContent.leadingAnchor constant:20],
        [controls.trailingAnchor constraintEqualToAnchor:profileContent.trailingAnchor constant:-20],
        [controls.topAnchor constraintEqualToAnchor:profileContent.topAnchor constant:18],
        [controls.bottomAnchor constraintLessThanOrEqualToAnchor:profileContent.bottomAnchor constant:-18],
        [self.profiles.widthAnchor constraintEqualToAnchor:controls.widthAnchor],
        [actions.widthAnchor constraintEqualToAnchor:controls.widthAnchor],[actions.heightAnchor constraintEqualToConstant:38],
        [self.start.widthAnchor constraintEqualToConstant:280],[self.start.heightAnchor constraintEqualToConstant:38]]];
    self.status=[NSTextField wrappingLabelWithString:@""];self.status.font=[NSFont systemFontOfSize:11];self.status.textColor=NSColor.secondaryLabelColor;self.status.selectable=YES;
    NSTextField *shortcut=[NSTextField labelWithString:@"⌘^  Trainer und Maus öffnen / schließen"];shortcut.font=[NSFont systemFontOfSize:11];shortcut.textColor=brass;
    NSStackView *stack=[NSStackView stackViewWithViews:@[header,profileSurface,self.status,shortcut]];stack.orientation=NSUserInterfaceLayoutOrientationVertical;stack.alignment=NSLayoutAttributeLeading;stack.spacing=18;stack.translatesAutoresizingMaskIntoConstraints=NO;
    [self.window.contentView addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor constant:28],
        [stack.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor constant:-28],
        [stack.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor constant:26],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:self.window.contentView.bottomAnchor constant:-24],
        [header.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [profileSurface.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [self.status.widthAnchor constraintEqualToAnchor:stack.widthAnchor],[self.status.heightAnchor constraintGreaterThanOrEqualToConstant:32]]];
    __weak MTLauncher *weakSelf=self;
    self.settingsObserver=[NSDistributedNotificationCenter.defaultCenter addObserverForName:MTOverlayChangedNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *event){
        MTLauncher *owner=weakSelf;if(!owner.game || owner.game.terminated)return;
        NSDictionary *options=MTOverlayMessageOptions(event.object,owner.session,owner.game.processIdentifier);
        if(options)[NSUserDefaults.standardUserDefaults setObject:options forKey:MTOverlayPreferencesKey];
    }];
    self.selectionObserver=[NSDistributedNotificationCenter.defaultCenter addObserverForName:MTSelectionChangedNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *event){
        MTLauncher *owner=weakSelf;if(!owner.game || !owner.runningProfileID.length)return;
        NSDictionary *selection=MTSelectionMessageValue(event.object,owner.session,owner.game.processIdentifier);
        if(selection)MTSaveSelection(NSUserDefaults.standardUserDefaults,owner.runningProfileID,selection);
    }];
    self.runtimeObserver=[NSDistributedNotificationCenter.defaultCenter addObserverForName:@"local.mactrainer.liesofp.runtime" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *event){
        MTLauncher *owner=weakSelf;NSDictionary *info=event.userInfo;
        if(!owner.game || ![event.object isEqual:owner.session] || [info[@"pid"] intValue]!=owner.game.processIdentifier)return;
        owner.status.stringValue=[info[@"ready"] boolValue]?@"Trainer im Spiel verbunden · Einzelspieler bestätigt.":[NSString stringWithFormat:@"Trainerbibliothek verbunden · %@ · %@",info[@"status"]?:@"",info[@"message"]?:@""];
    }];
    [self refresh:nil];[self.window center];[self.window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
}
- (NSString *)pathKey {return [@"GamePath." stringByAppendingString:self.profile[@"id"]];}
- (void)changeRestoreSelection:(id)sender {(void)sender;MTSetRestoreSelection(NSUserDefaults.standardUserDefaults,self.profile[@"id"],self.restoreSelection.state==NSControlStateValueOn);}
- (void)refresh:(id)sender {(void)sender;self.start.enabled=NO;
    self.restoreSelection.state=MTShouldRestoreSelection(NSUserDefaults.standardUserDefaults,self.profile[@"id"])?NSControlStateValueOn:NSControlStateValueOff;
    if(![self.profile[@"enabled"] boolValue]){self.status.stringValue=@"Dieses Spielprofil ist nicht freigegeben.";return;}
    if([MTCreateGameAdapter() isMemberOfClass:MTUnsupportedAdapter.class]){self.status.stringValue=@"Spieladapter fehlt. MTCreateGameAdapter muss eine geprüfte Anbindung liefern.";return;}
    NSString *path=[NSUserDefaults.standardUserDefaults stringForKey:self.pathKey];
    if(!path.length){path=[NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:self.profile[@"bundleIdentifier"]].path;if(path.length)[NSUserDefaults.standardUserDefaults setObject:path forKey:self.pathKey];}
    NSError *error=nil;
    if(!path.length){self.status.stringValue=@"Bitte passende Spiele-App auswählen.";return;}
    self.start.enabled=MTInspectGame(path,self.profile,&error)!=nil;self.status.stringValue=self.start.enabled ? path : error.localizedDescription;
}
- (void)choose:(id)sender {(void)sender;NSOpenPanel *panel=[NSOpenPanel openPanel];panel.canChooseFiles=YES;panel.canChooseDirectories=NO;panel.allowsMultipleSelection=NO;panel.allowedContentTypes=@[UTTypeApplicationBundle];
    if([panel runModal]==NSModalResponseOK){[NSUserDefaults.standardUserDefaults setObject:panel.URL.path forKey:self.pathKey];[self refresh:nil];}}
- (void)startGame:(id)sender {(void)sender;if(![self.profile[@"enabled"] boolValue])return;
    if([NSRunningApplication runningApplicationsWithBundleIdentifier:self.profile[@"bundleIdentifier"]].count){self.status.stringValue=@"Die laufende Spielinstanz bitte regulär beenden.";return;}
    NSString *path=[NSUserDefaults.standardUserDefaults stringForKey:self.pathKey];
    if(!path.length){path=[NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:self.profile[@"bundleIdentifier"]].path;if(path.length)[NSUserDefaults.standardUserDefaults setObject:path forKey:self.pathKey];}
    NSError *error=nil;NSDictionary *game=MTInspectGame(path,self.profile,&error);if(!game){self.status.stringValue=error.localizedDescription;return;}
    NSString *module=[NSBundle.mainBundle pathForResource:@"TrainerOverlay" ofType:@"dylib"];
    NSWorkspaceOpenConfiguration *c=[NSWorkspaceOpenConfiguration configuration];c.createsNewApplicationInstance=YES;c.activates=YES;
    self.session=NSUUID.UUID.UUIDString;
    self.runningProfileID=self.profile[@"id"];
    NSMutableDictionary *environment=[@{@"DYLD_INSERT_LIBRARIES":module,@"MT_TRAINER_TARGET":game[@"executable"],@"MT_TRAINER_CONFIG":[NSBundle.mainBundle pathForResource:@"TrainerConfig" ofType:@"json"],@"MT_TRAINER_PROFILE":self.profile[@"id"],@"MT_TRAINER_SESSION":self.session,@"MT_TRAINER_OVERLAY_OPTIONS":MTEncodeOverlayOptions([NSUserDefaults.standardUserDefaults objectForKey:MTOverlayPreferencesKey])} mutableCopy];
    if([self.profile[@"steamAppId"] length]){environment[@"SteamAppId"]=self.profile[@"steamAppId"];environment[@"SteamGameId"]=self.profile[@"steamAppId"];}
    environment[@"MT_TRAINER_SELECTION"]=MTEncodeSelection(MTLoadLaunchSelection(NSUserDefaults.standardUserDefaults,self.runningProfileID));
    c.environment=environment;
    __weak MTLauncher *weakSelf=self;
    [NSWorkspace.sharedWorkspace openApplicationAtURL:[NSURL fileURLWithPath:game[@"path"]] configuration:c completionHandler:^(NSRunningApplication *app,NSError *failure){dispatch_async(dispatch_get_main_queue(),^{weakSelf.game=app;weakSelf.status.stringValue=failure ? failure.localizedDescription : app ? @"Start angefordert. Ob DYLD-Laden unterstützt wird, ist pro Spiel zu prüfen." : @"Kein Spielprozess gestartet.";});}];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {(void)application;return !self.game || self.game.terminated;}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)visible {(void)application;if(!visible)[self.window makeKeyAndOrderFront:nil];return YES;}
- (void)applicationWillTerminate:(NSNotification *)notification {(void)notification;if(self.settingsObserver)[NSDistributedNotificationCenter.defaultCenter removeObserver:self.settingsObserver];if(self.runtimeObserver)[NSDistributedNotificationCenter.defaultCenter removeObserver:self.runtimeObserver];if(self.selectionObserver)[NSDistributedNotificationCenter.defaultCenter removeObserver:self.selectionObserver];}
@end
int main(void){@autoreleasepool{[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];MTLauncher *delegate=[MTLauncher new];NSApp.delegate=delegate;[NSApp run];}return 0;}
