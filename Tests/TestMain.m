// SPDX-License-Identifier: GPL-3.0-only
#import <AppKit/AppKit.h>
#import <mach-o/loader.h>
#import <mach/machine.h>
#import <Carbon/Carbon.h>
#import "GameBridge.h"
#import "FixtureAdapter.h"
#import "GameProfile.h"
#import "MemoryAccess.h"
#import "Overlay.h"
#import "TrainerMaterial.h"
#include <math.h>
static void drain(void){for(int i=0;i<16;i++)[NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];}
static void bridgeTests(void){
    MTFixtureAdapter *a=[MTFixtureAdapter new];MTGameBridge *b=[[MTGameBridge alloc]initWithAdapter:a];
    [b poll];drain();NSCAssert(b.state.ready,@"solo test context ready");
    [b performFeature:MTFeatureHealth];[b performFeature:MTFeaturePlayerMultiplier];drain();
    NSCAssert(b.state.features[MTFeatureHealth].active && [a.values[@(MTFeatureHealth)] intValue]==100 && [a.values[@(MTFeaturePlayerMultiplier)] doubleValue]==2,@"confirmed fixture effects");
    [b poll];drain();NSCAssert([a.values[@(MTFeaturePlayerMultiplier)] doubleValue]==2,@"factors never compound");
    [b setValue:NAN forFeature:MTFeaturePlayerMultiplier];[b setValue:100 forFeature:MTFeaturePlayerMultiplier];drain();NSCAssert(b.state.features[MTFeaturePlayerMultiplier].value==2,@"invalid numeric values ignored");
    [b setValue:1000.5 forFeature:MTFeatureErgo];drain();NSCAssert(b.state.features[MTFeatureErgo].value==1000,@"integer amounts enforced");
    a.mode=MTSessionLoading;[b poll];drain();
    NSCAssert(!b.state.ready && b.state.features[MTFeatureHealth].wanted && !b.state.features[MTFeatureHealth].active && [a.values[@(MTFeatureHealth)] intValue]==50,@"loading releases effects but preserves choices");
    uint64_t context=b.state.context;[b poll];drain();NSCAssert(b.state.context==context,@"stable loading context");
    [a newArea];a.mode=MTSessionSolo;[b poll];drain();NSCAssert(b.state.features[MTFeatureHealth].active && [a.values[@(MTFeaturePlayerMultiplier)] doubleValue]==2,@"new area rebinds continuous effects");
    [b poll];[b performFeature:MTFeatureErgo];[b performFeature:MTFeatureSaveCoordinates];[a newArea];drain();
    NSCAssert([a.values[@(MTFeatureErgo)] intValue]==500 && [a.values[@(MTFeatureSaveCoordinates)] intValue]==10 && b.state.features[MTFeatureHealth].active,@"stale one-shot actions are discarded across direct travel");
    a.mode=MTSessionNetwork;[b setOverlayInteraction:YES];[b poll];drain();
    NSCAssert(!b.state.ready && b.state.overlayMouseActive && !b.state.features[MTFeatureHealth].wanted && [a.values[@(MTFeaturePlayerMultiplier)] doubleValue]==1,@"network gate clears choices without disabling UI ownership");
    [b performFeature:MTFeatureErgo];drain();NSCAssert([a.values[@(MTFeatureErgo)] intValue]==500,@"network blocks one-shots");
    a.mode=MTSessionSolo;[b poll];drain();NSCAssert(!b.state.features[MTFeatureHealth].active,@"network return never resumes cheats");
    [b performFeature:MTFeatureHealth];drain();[b poll];for(int i=0;i<24;i++)[b performFeature:MTFeatureSaveCoordinates];[b performAction:MTTrainerDisableAll];a.mode=MTSessionLoading;drain();
    NSCAssert(!b.state.features[MTFeatureHealth].wanted && [a.values[@(MTFeatureSaveCoordinates)] intValue]==10,@"emergency shortcut survives full queue and loading");
    [b setOverlayInteraction:NO];drain();NSCAssert(!b.state.overlayMouseActive,@"UI release survives loading");
    MTGameBridge *unsupported=[[MTGameBridge alloc]initWithAdapter:[MTUnsupportedAdapter new]];[unsupported poll];[unsupported performFeature:MTFeatureHealth];drain();NSCAssert(!unsupported.state.ready && !unsupported.state.features[0].active,@"unknown adapter cannot claim a working cheat");
}
static NSEvent *mouse(NSWindow *window,NSView *view,NSPoint p,NSEventType type){return [NSEvent mouseEventWithType:type location:[view convertPoint:p toView:nil] modifierFlags:0 timestamp:0 windowNumber:window.windowNumber context:nil eventNumber:1 clickCount:1 pressure:1];}
static NSEvent *keyEvent(unsigned short code,NSEventModifierFlags flags,NSString *characters){return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:flags timestamp:0 windowNumber:0 context:nil characters:characters charactersIgnoringModifiers:characters isARepeat:NO keyCode:code];}
static unsigned short layoutKey(const MTFeatureInfo *info){
    NSString *character=[info->shortcut substringFromIndex:info->shortcut.length-1];
    if([@"1234567890" containsString:character])return info->key;
    for(unsigned short code=0;code<96;code++)if([[[keyEvent(code,0,@"") charactersByApplyingModifiers:0] uppercaseString] isEqual:character])return code;
    return info->key;
}
static void shortcutTests(void){
    [NSApplication sharedApplication];
    NSArray *system=@[@{(__bridge NSString *)kHISymbolicHotKeyCode:@18,(__bridge NSString *)kHISymbolicHotKeyModifiers:@(controlKey|shiftKey),(__bridge NSString *)kHISymbolicHotKeyEnabled:@YES}];
    NSCAssert(MTSystemShortcutMatches(system,18,MTTrainerModifiers),@"active system shortcut has priority");
    NSCAssert(!MTSystemShortcutMatches(system,19,MTTrainerModifiers) && !MTSystemShortcutMatches(system,18,NSEventModifierFlagCommand),@"key and exact modifiers both matter");
    NSArray *disabled=@[@{(__bridge NSString *)kHISymbolicHotKeyCode:@18,(__bridge NSString *)kHISymbolicHotKeyModifiers:@(controlKey|shiftKey),(__bridge NSString *)kHISymbolicHotKeyEnabled:@NO}];
    NSCAssert(!MTSystemShortcutMatches(disabled,18,MTTrainerModifiers) && MTSystemShortcutMatches(nil,18,MTTrainerModifiers),@"disabled bindings are free; an unreadable system configuration fails closed");
    NSCAssert(MTRefreshSystemShortcuts(),@"read the current macOS symbolic shortcuts without changing them");
    NSCAssert(MTShortcutKeyCode(MTShortcutPanel)==10 && MTShortcutModifiersFor(MTShortcutPanel)==NSEventModifierFlagCommand,@"user-requested Command-caret is preserved");
    NSCAssert(MTShortcutForEvent(keyEvent(10,NSEventModifierFlagCommand|NSEventModifierFlagOption,@"^"))<0 && MTShortcutForEvent(keyEvent(22,NSEventModifierFlagCommand|NSEventModifierFlagShift,@"^"))<0,@"old Option-caret and macOS Command-Shift-6 alias are not trainer shortcuts");
    NSCAssert(MTShortcutCount==2 && MTShortcutForEvent(keyEvent(49,MTTrainerModifiers,@" "))<0,@"no separate mouse shortcut exists");
    BOOL available=MTTrainerShortcutAvailable(18,MTTrainerModifiers);
    MTBlockTrainerShortcut(18,MTTrainerModifiers);NSCAssert(!MTTrainerShortcutAvailable(18,MTTrainerModifiers),@"registration conflict cannot fall back to a duplicate local binding");
    MTRefreshSystemShortcuts();NSCAssert(MTTrainerShortcutAvailable(18,MTTrainerModifiers)==available,@"activation reloads the actual system bindings");
    unsigned blocked=0;
    for(NSInteger i=0;i<MTShortcutCount;i++)blocked+=!MTTrainerShortcutAvailable(MTShortcutKeyCode(i),MTShortcutModifiersFor(i));
    for(NSInteger i=0;i<MTFeatureCount;i++)blocked+=!MTTrainerShortcutAvailable(layoutKey(MTFeatureInfoAt(i)),MTFeatureInfoAt(i)->modifiers);
    printf("Shortcut policy: system configuration read; %u of 39 declared bindings blocked; Command-caret jointly controls panel/mouse; no separate mouse shortcut.\n",blocked);
}
static void uiTests(void){
    [NSApplication sharedApplication];
    NSWindow *w=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,1000,620) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];w.releasedWhenClosed=NO;
    MTOverlayRoot *r=[[MTOverlayRoot alloc]initWithFrame:NSMakeRect(20,30,950,550) version:@"UI TEST"];
    [w.contentView addSubview:r];MTTrainerState *s=[MTTrainerState new];s.ready=YES;s.overlayMouseActive=YES;[r updateState:s];
    __block NSInteger clicks=0;
    for(NSNumber *scale in @[@0.7,@0.9,@1.3])for(NSString *pos in @[@"top-left",@"bottom-right",@"center"]){
        [r applyOverlayOptions:@{@"scale":scale,@"position":pos}];
        NSCAssert(NSContainsRect(r.bounds,r.panel.frame),@"panel fits window");
        for(NSInteger i=0;i<MTFeatureCount;i++){
            r.featureHandler=^(MTFeature f){NSCAssert(f==i,@"correct click target");clicks++;};
            NSView *row=((MTTrainerMaterial *)r.panel).contentView.subviews[i];NSInteger before=clicks;
            NSCAssert([r handleMouseEvent:mouse(w,row,NSMakePoint(244,10),NSEventTypeLeftMouseDown)],@"click consumed");
            NSCAssert([r handleMouseEvent:mouse(w,row,NSMakePoint(244,10),NSEventTypeLeftMouseUp)],@"release consumed");NSCAssert(clicks==before+1,@"one dispatch per click");
        }
    }
    for(NSInteger i=0;i<MTFeatureCount;i++){
        const MTFeatureInfo *info=MTFeatureInfoAt(i);__block NSInteger invoked=0;
        r.featureHandler=^(MTFeature feature){NSCAssert(feature==i,@"new character binding selects its catalog entry: expected %ld, received %ld",(long)i,(long)feature);invoked++;};
        NSString *character=[info->shortcut substringFromIndex:info->shortcut.length-1];
        unsigned short code=layoutKey(info);
        BOOL free=MTTrainerShortcutAvailable(code,info->modifiers);
        BOOL handled=[r handleEvent:keyEvent(code,info->modifiers,character)];
        NSCAssert(handled==free && invoked==(free?1:0),@"all 37 character shortcuts obey the system conflict policy");
    }
    for(NSNumber *flags in @[@0,@(NSEventModifierFlagShift),@(NSEventModifierFlagOption),@(NSEventModifierFlagShift|NSEventModifierFlagOption)])
        for(NSNumber *code in @[@122,@120,@99,@118,@96,@97,@98,@100,@101,@109,@103,@111])
            NSCAssert(![r handleEvent:keyEvent(code.unsignedShortValue,flags.unsignedIntegerValue,@"")],@"former function-key banks and plain F12 pass through");
    NSDictionary *launch=MTOverlayOptionsForLaunch(@{@"visible":@YES,@"badge":@YES,@"mouse":@NO,@"position":@"bottom-right",@"scale":@1.3});
    NSCAssert(![launch[@"visible"] boolValue] && ![launch[@"badge"] boolValue] && [launch[@"mouse"] boolValue] && [launch[@"position"] isEqual:@"bottom-right"] && [launch[@"scale"] doubleValue]==1.3,@"new sessions open hidden, preserve layout, and prepare mouse");
    [r applyOverlayOptions:launch];NSCAssert(r.panel.hidden && r.badge.hidden && !r.wantsMouseInteraction,@"launch policy hides both panel and badge without claiming mouse");
    [r applyOverlayOptions:@{@"mouse":@NO}];NSCAssert(r.panelVisible && r.wantsMouseInteraction && [r.overlayOptions[@"mouse"] boolValue],@"legacy mouse-off preference cannot separate the panel and mouse");
    __block NSInteger inputRequests=0;__block BOOL requestedMouse=YES;r.optionsChanged=^(NSDictionary *options){inputRequests++;requestedMouse=[options[@"visible"] boolValue]&&[options[@"mouse"] boolValue];};
    [r togglePanel:nil];NSCAssert(r.panel.hidden && !r.wantsMouseInteraction && !requestedMouse,@"hide gives game input back");
    [r togglePanel:nil];NSCAssert(!r.panel.hidden && r.wantsMouseInteraction && [r.overlayOptions[@"mouse"] boolValue] && requestedMouse,@"Command-caret opens with mouse even after display-only was saved");
    s.overlayMouseActive=NO;[r updateState:s];
    MTFixtureAdapter *mouseAdapter=[MTFixtureAdapter new];
    MTGameBridge *mouseBridge=[[MTGameBridge alloc]initWithAdapter:mouseAdapter];
    [mouseBridge poll];drain();
    r.featureHandler=^(MTFeature feature){[mouseBridge performFeature:feature];};
    NSView *healthRow=((MTTrainerMaterial *)r.panel).contentView.subviews[MTFeatureHealth];
    NSPoint healthPoint=[healthRow convertPoint:NSMakePoint(244,10) toView:r.superview];
    NSCAssert([r hitTest:healthPoint]==healthRow,@"AppKit targets visible cheat rows without waiting for engine cursor confirmation");
    for(NSInteger n=0;n<2;n++){
        NSCAssert([r handleMouseEvent:mouse(w,healthRow,NSMakePoint(244,10),NSEventTypeLeftMouseDown)],@"visible overlay consumes cheat clicks even without native cursor readback");
        NSCAssert([r handleMouseEvent:mouse(w,healthRow,NSMakePoint(244,10),NSEventTypeLeftMouseUp)],@"matching release cannot pass through to gameplay");
        drain();
        NSCAssert(mouseBridge.state.features[MTFeatureHealth].wanted==(n==0) && mouseBridge.state.features[MTFeatureHealth].active==(n==0),@"mouse toggles the real bridge exactly once per click");
    }
    s.ready=NO;[r updateState:s];
    NSCAssert([r handleMouseEvent:mouse(w,healthRow,NSMakePoint(244,10),NSEventTypeLeftMouseDown)] && [r handleMouseEvent:mouse(w,healthRow,NSMakePoint(244,10),NSEventTypeLeftMouseUp)],@"loading consumes overlay clicks without sending them to the game");
    drain();NSCAssert(!mouseBridge.state.features[MTFeatureHealth].wanted,@"loading UI does not issue a cheat command");
    s.ready=YES;[r updateState:s];
    NSView *content=((MTTrainerMaterial *)r.panel).contentView;
    NSPoint origin=r.panel.frame.origin;
    NSCAssert([r handleMouseEvent:mouse(w,content,NSMakePoint(80,10),NSEventTypeLeftMouseDown)],@"header remains usable without native player mouse ownership");
    [r handleMouseEvent:mouse(w,content,NSMakePoint(140,50),NSEventTypeLeftMouseDragged)];
    [r handleMouseEvent:mouse(w,content,NSMakePoint(140,50),NSEventTypeLeftMouseUp)];
    NSCAssert(!NSEqualPoints(origin,r.panel.frame.origin),@"header can be dragged while a player is unavailable");
    NSCAssert(![r handleEvent:keyEvent(49,MTTrainerModifiers,@" ")] && r.wantsMouseInteraction,@"removed mouse chord cannot disable joint input");
    NSCAssert(![r handleEvent:keyEvent(53,0,@"")] && r.panelVisible,@"Escape does not introduce another panel toggle");
    NSInteger inputRequestsBeforeClose=inputRequests;
    [r togglePanel:nil];NSCAssert(r.panel.hidden && !r.wantsMouseInteraction && !requestedMouse && inputRequests==inputRequestsBeforeClose+1,@"second Command-caret releases mouse exactly once");
    s.ready=NO;[r updateState:s];__block NSInteger stops=0;r.actionHandler=^(MTTrainerAction action){NSCAssert(action==MTTrainerDisableAll,@"emergency shortcut stop");stops++;};
    NSEvent *stopKey=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:MTTrainerModifiers timestamp:0 windowNumber:0 context:nil characters:@"" charactersIgnoringModifiers:@"" isARepeat:NO keyCode:51];[r handleEvent:stopKey];NSCAssert(stops==1,@"emergency shortcut works during loading");[r setValue:@(MTFeatureX) forKey:@"editingFeature"];[r handleEvent:stopKey];NSCAssert(stops==2,@"emergency shortcut also works inside numeric editing");
    NSCAssert(![r handleEvent:keyEvent(12,NSEventModifierFlagCommand,@"q")] && ![r handleEvent:keyEvent(53,NSEventModifierFlagCommand|NSEventModifierFlagOption,@"")] && ![r handleEvent:keyEvent(111,0,@"")],@"editor passes application quit, force quit and old F12 through");
    MTOverlayShortcuts *keys=[MTOverlayShortcuts new];keys.enabled=YES;[keys setRegistered:YES shortcut:MTShortcutPanel];__block int toggles=0;keys.handler=^(MTOverlayShortcut action){(void)action;toggles++;};
    [keys nativeShortcut:MTShortcutPanel pressed:YES];[keys nativeShortcut:MTShortcutPanel pressed:YES];NSCAssert(toggles==1,@"native repeats cannot toggle twice");[keys nativeShortcut:MTShortcutPanel pressed:NO];[keys nativeShortcut:MTShortcutPanel pressed:YES];NSCAssert(toggles==2,@"fresh press toggles");
    keys.enabled=NO;NSCAssert(![keys nativeShortcut:MTShortcutPanel pressed:YES],@"inactive app owns no hotkeys");
    NSCAssert(!MTOverlayMessageOptions(MTOverlayMessage(@{},@"A",12),@"B",12),@"foreign settings sessions ignored");
    [w close];
}
static void profileTests(NSString *configPath){
    NSError *error=nil;NSDictionary *config=MTLoadConfiguration(configPath,&error);NSCAssert(config && !error,@"valid template config");NSCAssert(!MTLoadConfiguration(nil,NULL),@"missing config fails safely");
    NSCAssert(!MTInspectGame(@"relative.app",config[@"profiles"][0],NULL),@"disabled/missing identity never launches");
    NSCAssert(!MTCurrentProcessMatches(config[@"profiles"][0],@"/unknown"),@"disabled profile never installs runtime");
    NSString *folder=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];[NSFileManager.defaultManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:NULL];
    @try{
        NSString *file=[folder stringByAppendingPathComponent:@"fake-executable"];
        struct mach_header_64 h={.magic=MH_MAGIC_64,.cputype=CPU_TYPE_ARM64,.filetype=MH_EXECUTE,.ncmds=1,.sizeofcmds=sizeof(struct uuid_command)};
        struct uuid_command u={.cmd=LC_UUID,.cmdsize=sizeof(u)};NSUUID *uuid=[NSUUID UUID];[uuid getUUIDBytes:u.uuid];NSMutableData *data=[NSMutableData dataWithBytes:&h length:sizeof(h)];[data appendBytes:&u length:sizeof(u)];[data writeToFile:file atomically:YES];
        NSCAssert([MTReadExecutableIdentity(file)[@"uuid"] isEqual:uuid.UUIDString],@"exact arm64 identity read");
        h.ncmds=2;memcpy(data.mutableBytes,&h,sizeof(h));[data writeToFile:file atomically:YES];NSCAssert(!MTReadExecutableIdentity(file),@"truncated Mach-O rejected");
        NSMutableDictionary *bad=[config mutableCopy];bad[@"profiles"]=@[@{@"id":@"bad",@"name":@"Bad",@"enabled":@YES,@"bundleIdentifier":@"example.game",@"executable":@"Game",@"uuids":@[]}];
        NSString *json=[folder stringByAppendingPathComponent:@"bad.json"];[[NSJSONSerialization dataWithJSONObject:bad options:0 error:NULL]writeToFile:json atomically:YES];NSCAssert(!MTLoadConfiguration(json,NULL),@"active profile without UUID denied");
    }@finally{[NSFileManager.defaultManager removeItemAtPath:folder error:NULL];}
    uint8_t byte;NSCAssert(!MTReadMemory((void *)1,&byte,1) && !MTWriteByte((void *)1,0,1),@"unmapped memory denied");
    float local=1;NSCAssert(MTWriteFloat(&local,0,2) && local==2 && !MTWriteFloat(&local,0,NAN),@"writable finite data only");
}
void MTPresentationRunTests(void);
void LOPRunNativeUnitTests(void);
void MTSelectionRunTests(void);
BOOL MTSelectionRunChild(int argc,const char *argv[],int *result);
int main(int argc,const char *argv[]){@autoreleasepool{int result=0;if(MTSelectionRunChild(argc,argv,&result))return result;NSCAssert(argc==2,@"config argument");shortcutTests();LOPRunNativeUnitTests();bridgeTests();MTSelectionRunTests();profileTests([NSString stringWithUTF8String:argv[1]]);uiTests();MTPresentationRunTests();puts("Template checks passed: fixture effects/restoration, travel, stale actions, loading/emergency shortcut, network gate, unsupported adapter, scaled clicks, shortcuts, profiles and bounded memory.");}return 0;}
