// SPDX-License-Identifier: GPL-3.0-only
#import <AppKit/AppKit.h>
#import "SelectionSettings.h"
#import "GameBridge.h"
#import "FixtureAdapter.h"
#include <string.h>
static void selectionDrain(void){for(int i=0;i<16;i++)[NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];}
static NSDictionary *selectedFixture(void){
    MTTrainerState *state=[MTTrainerState new];
    state.features[MTFeatureActivate].wanted=NO;state.features[MTFeatureHealth].wanted=YES;
    state.features[MTFeaturePlayerMultiplier].wanted=YES;state.features[MTFeaturePlayerMultiplier].value=3.5;
    for(NSInteger i=0;i<MTFeatureCount;i++)if(MTFeatureInfoAt(i)->oneShot)state.features[i].wanted=YES;
    return MTSelectionForFeatures(state.features);
}
static BOOL hasWanted(NSDictionary *selection){for(NSDictionary *entry in selection[@"features"])if([entry[@"wanted"] boolValue])return YES;return NO;}
BOOL MTSelectionRunChild(int argc,const char *argv[],int *result){
    if(argc!=3 || (strcmp(argv[1],"--selection-fixture-write") && strcmp(argv[1],"--selection-fixture-read")))return NO;
    NSString *suite=[NSString stringWithUTF8String:argv[2]];
    NSCAssert([suite hasPrefix:@"local.mactrainer.liesofp.selection-test."],@"child uses an isolated test domain");
    NSUserDefaults *preferences=[[NSUserDefaults alloc]initWithSuiteName:suite];
    if(!strcmp(argv[1],"--selection-fixture-write")){
        MTSaveSelection(preferences,@"steam-114-arm64",selectedFixture());
        NSCAssert([preferences synchronize],@"flush the isolated fixture before terminating its process");
    }else{
        MTFixtureAdapter *adapter=[MTFixtureAdapter new];adapter.mode=MTSessionLoading;
        NSCAssert(!MTShouldRestoreSelection(preferences,@"steam-114-arm64") && !hasWanted(MTLoadLaunchSelection(preferences,@"steam-114-arm64")),@"restore is opt-in, even when a previous selection exists");
        MTSetRestoreSelection(preferences,@"steam-114-arm64",YES);
        NSCAssert(MTShouldRestoreSelection(preferences,@"steam-114-arm64"),@"explicit option enables restoration");
        NSUserDefaults *freshPreferences=[[NSUserDefaults alloc]initWithSuiteName:suite];
        NSCAssert(MTShouldRestoreSelection(freshPreferences,@"steam-114-arm64"),@"option survives a fresh preferences instance");
        MTGameBridge *bridge=[[MTGameBridge alloc]initWithAdapter:adapter selection:MTLoadLaunchSelection(preferences,@"steam-114-arm64")];
        [bridge poll];selectionDrain();
        NSCAssert(!bridge.state.ready && bridge.state.features[MTFeatureHealth].wanted && !bridge.state.features[MTFeatureHealth].active && [adapter.values[@(MTFeatureHealth)] intValue]==50,@"fresh process restores choices but waits for a loaded solo context");
        adapter.mode=MTSessionSolo;[bridge poll];selectionDrain();
        NSCAssert(bridge.state.features[MTFeatureActivate].active && bridge.state.features[MTFeatureHealth].active && bridge.state.features[MTFeaturePlayerMultiplier].active && bridge.state.features[MTFeaturePlayerMultiplier].value==3.5 && [adapter.values[@(MTFeaturePlayerMultiplier)] doubleValue]==3.5,@"fresh process activates the native master for saved cheats even when the old master preference was off");
        for(NSInteger i=0;i<MTFeatureCount;i++)if(MTFeatureInfoAt(i)->oneShot)NSCAssert(!bridge.state.features[i].wanted,@"never restore a GO action as selected");
        NSCAssert([adapter.values[@(MTFeatureErgo)] intValue]==500 && [adapter.values[@(MTFeatureSaveCoordinates)] intValue]==10,@"loading does not execute permanent edits or saved-coordinate actions");
        MTSetRestoreSelection(preferences,@"steam-114-arm64",NO);
        NSCAssert(!hasWanted(MTLoadLaunchSelection(preferences,@"steam-114-arm64")) && hasWanted(MTLoadSelection(preferences,@"steam-114-arm64")),@"unchecking starts unselected without deleting the saved selection");
        NSCAssert(!MTShouldRestoreSelection(preferences,@"different-profile"),@"restore choice is isolated per profile");
    }
    *result=0;return YES;
}
static void runChild(NSString *mode,NSString *suite){
    NSTask *task=[NSTask new];task.executableURL=[NSURL fileURLWithPath:NSProcessInfo.processInfo.arguments.firstObject];task.arguments=@[mode,suite];
    NSError *error=nil;NSCAssert([task launchAndReturnError:&error],@"launch isolated persistence fixture: %@",error);
    [task waitUntilExit];NSCAssert(task.terminationStatus==0,@"isolated persistence process succeeded");
}
void MTSelectionRunTests(void){
    NSDictionary *selected=selectedFixture();NSCAssert(hasWanted(selected),@"continuous selection captured");
    NSCAssert([selected isEqual:MTDecodeSelection(MTEncodeSelection(selected))],@"selection survives launch-environment encoding");
    for(NSDictionary *entry in selected[@"features"])NSCAssert(!MTFeatureInfoAt([entry[@"id"] integerValue])->oneShot,@"one-shots are excluded from persistence");
    NSMutableDictionary *bad=[selected mutableCopy];bad[@"schema"]=@2;NSCAssert(!hasWanted(MTNormalizeSelection(bad)),@"unknown schema never activates choices");
    bad=[selected mutableCopy];bad[@"features"]=@[@{@"id":@(MTFeaturePlayerMultiplier),@"wanted":@YES,@"value":@1000000}];NSCAssert(!hasWanted(MTNormalizeSelection(bad)),@"out-of-range factors cannot be restored");
    bad=[selected mutableCopy];bad[@"features"]=@[selected[@"features"][0],selected[@"features"][0]];NSCAssert(!hasWanted(MTNormalizeSelection(bad)),@"ambiguous duplicate feature IDs are rejected");
    NSCAssert(!hasWanted(MTDecodeSelection(@"invalid JSON")) && !hasWanted(MTNormalizeSelection(NSNull.null)),@"invalid persistence input starts unselected");
    NSString *message=MTSelectionMessage(selected,@"session-A",42);
    NSCAssert([MTSelectionMessageValue(message,@"session-A",42) isEqual:selected] && !MTSelectionMessageValue(message,@"session-B",42) && !MTSelectionMessageValue(message,@"session-A",43),@"only the launched process/session can save its selection");
    MTFixtureAdapter *adapter=[MTFixtureAdapter new];MTGameBridge *bridge=[[MTGameBridge alloc]initWithAdapter:adapter selection:selected];
    __block NSDictionary *saved=nil;__block NSUInteger saves=0;bridge.selectionChanged=^(NSDictionary *selection){NSCAssert(NSThread.isMainThread,@"preferences are committed on the launcher/main side");saved=selection;saves++;};
    [bridge poll];selectionDrain();NSCAssert(saves==0,@"restoring/polling does not replace the stored choice");
    [bridge setValue:4.5 forFeature:MTFeaturePlayerMultiplier];selectionDrain();NSCAssert(saves==1 && hasWanted(saved),@"numeric continuous-factor changes are persisted");
    [bridge performFeature:MTFeatureErgo];selectionDrain();NSCAssert(saves==1,@"GO actions never create a replay record");
    [bridge performAction:MTTrainerDisableAll];selectionDrain();NSCAssert(saves==2 && !hasWanted(saved),@"all-off is saved so it stays off after a restart");
    MTGameBridge *disabled=[[MTGameBridge alloc]initWithAdapter:[MTFixtureAdapter new] selection:saved];[disabled poll];selectionDrain();NSCAssert(!disabled.state.features[MTFeatureHealth].active,@"all-off survives a fresh bridge");
    adapter=[MTFixtureAdapter new];adapter.mode=MTSessionNetwork;bridge=[[MTGameBridge alloc]initWithAdapter:adapter selection:selected];
    bridge.selectionChanged=^(NSDictionary *selection){saved=selection;};[bridge poll];selectionDrain();NSCAssert(!bridge.state.ready && !hasWanted(saved),@"network gate clears the persisted selection as well");
    NSString *suite=[@"local.mactrainer.liesofp.selection-test." stringByAppendingString:NSUUID.UUID.UUIDString];
    NSUserDefaults *preferences=[[NSUserDefaults alloc]initWithSuiteName:suite];
    NSString *file=[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Library/Preferences/%@.plist",suite]];
    NSCAssert(![NSFileManager.defaultManager fileExistsAtPath:file],@"test domain is new and not user preferences");
    @try{
        runChild(@"--selection-fixture-write",suite);
        runChild(@"--selection-fixture-read",suite);
        NSCAssert(!hasWanted(MTLoadSelection(preferences,@"different-profile")),@"profiles cannot activate each other's choices");
    }@finally{
        [preferences removePersistentDomainForName:suite];[preferences synchronize];
        [NSFileManager.defaultManager removeItemAtPath:file error:NULL];
    }
    puts("Selection persistence: separate writer/reader processes, loaded-solo activation, factors, one-shot exclusion, all-off, network clear, schema/range validation and session/profile isolation passed.");
}
