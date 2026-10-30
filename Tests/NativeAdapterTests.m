// SPDX-License-Identifier: GPL-3.0-only
#import <AppKit/AppKit.h>
#import <mach/mach_vm.h>
#import "LiesOfPAdapter.h"
#import "MemoryAccess.h"
#import "TrainerFeatures.h"
#import "OverlayShortcuts.h"
#import "PlatformCursor.h"
@interface LOPGameAdapter (LedgerTests)
- (BOOL)write:(NSString *)key owner:(uintptr_t)owner base:(uintptr_t)base stat:(uint8_t)stat offset:(size_t)offset bytes:(const void *)bytes length:(size_t)length;
- (void)restorePrefix:(NSString *)prefix;
@end
static void platformCursorTests(void) {
    __block MTPlatformCursorState state={.application=1,.cursor=2,.reference=3,.type=0,.overrideType=-1,.visible=YES,.hasShape=NO,.hasDefaultShape=YES,.free=YES};
    __block NSUInteger writes=0;__block BOOL failVisibility=NO;
    MTPlatformCursorLease *lease=[[MTPlatformCursorLease alloc]initWithRead:^MTPlatformCursorState{return state;}
        apply:^BOOL(MTPlatformCursorState owner,MTPlatformCursorOperation operation,int32_t value){
            NSCAssert(owner.application==state.application && owner.cursor==state.cursor && owner.reference==state.reference,@"never apply to another native cursor owner");
            if(operation==MTPlatformCursorVisibility && value && failVisibility)return NO;
            writes++;
            if(operation==MTPlatformCursorOverride)state.overrideType=value;
            else if(operation==MTPlatformCursorType){state.type=value;state.hasShape=value!=0;}
            else state.visible=value!=0;
            return YES;
        }];
    NSCAssert([lease show] && state.type==1 && state.overrideType==1 && state.visible && state.hasShape,@"visible flag alone is insufficient: acquire a real native cursor shape");
    NSUInteger initialWrites=writes;NSCAssert([lease show] && writes==initialWrites,@"polls do not change the captured original or repeat native calls");
    [lease restore:YES];NSCAssert(state.type==0 && state.overrideType==-1 && state.visible && !state.hasShape,@"close restores the original shape and native visibility flag");
    state.visible=NO;state.free=NO;
    NSCAssert(![lease show] && state.visible,@"cursor can be visible while capture still prevents a free mouse; do not grant UI clicks");
    state.free=YES;NSCAssert([lease show],@"confirm only after native capture becomes free");
    [lease restore:YES];NSCAssert(!state.visible && state.type==0 && state.overrideType==-1,@"originally hidden cursor is restored");
    NSCAssert([lease show],@"acquire for an external menu change");state.overrideType=2;
    NSCAssert(![lease show],@"a later game cursor override wins");initialWrites=writes;[lease restore:YES];
    NSCAssert(state.overrideType==2 && writes==initialWrites,@"never overwrite the later menu's cursor state");
    state.overrideType=-1;state.type=0;state.visible=NO;
    NSCAssert([lease show],@"acquire before owner replacement");state.cursor=4;state.reference=5;
    initialWrites=writes;[lease restore:YES];NSCAssert(writes==initialWrites,@"owner replacement cannot receive stale restoration");
    state.overrideType=-1;state.type=0;state.visible=NO;
    failVisibility=YES;NSCAssert(![lease show] && state.overrideType==-1 && state.type==0 && !state.visible,@"partial acquisition is rolled back");failVisibility=NO;
    NSCAssert([lease show],@"acquire before a menu transition");[lease restore:NO];
    NSCAssert(state.overrideType==-1 && state.visible && state.type==1,@"menu transition removes only our force and retains the menu-visible appearance");
    state.hasDefaultShape=NO;initialWrites=writes;NSCAssert(![lease show] && writes==initialWrites,@"unavailable native cursor shape cannot be claimed");
    puts("Platform cursor checks: native shape/visibility, capture confirmation, stable baseline, restoration, menu changes, owner replacement and partial rollback.");
}
void LOPRunNativeUnitTests(void) {
    platformCursorTests();
    LOPGameAdapter *adapter=[LOPGameAdapter new];
    NSCAssert(adapter.captureContext.kind==MTSessionUnsupported,@"foreign executable cannot bind native addresses");
    for(NSInteger i=0;i<MTFeatureCount;i++) {
        const MTFeatureInfo *info=MTFeatureInfoAt(i);
        MTFeatureState *state=[adapter applyFeature:i wanted:YES value:info->initial];
        NSCAssert(!state.available&&!state.active,@"all native writes rejected in a foreign process");
        if(info->oneShot)NSCAssert([[adapter performOneShot:i value:info->initial] containsString:@"nicht aktiv"],@"one-shots need a native solo context");
        NSCAssert(info->key!=111,@"emergency shortcut remains reserved for emergency release");
        NSCAssert(info->modifiers==MTTrainerModifiers && info->key<96,@"feature bindings use Control-Shift and no function keys");
        for(NSInteger j=0;j<i;j++){const MTFeatureInfo *other=MTFeatureInfoAt(j);NSCAssert(info->key!=other->key||info->modifiers!=other->modifiers,@"37 distinct hotkeys");}
    }
    [adapter releaseEffects];
    uint64_t owned=7,target=11;
    NSCAssert([adapter write:@"feature/value" owner:0 base:(uintptr_t)&owned stat:0 offset:0 bytes:&target length:8]&&owned==11,@"capture original and confirm owned data");
    [adapter restorePrefix:@""];NSCAssert(owned==7,@"empty prefix releases every record, including global flags");
    NSCAssert([adapter write:@"feature/value" owner:0 base:(uintptr_t)&owned stat:0 offset:0 bytes:&target length:8],@"reacquire");
    owned=19;[adapter restorePrefix:@""];NSCAssert(owned==19,@"external changes win over restoration");
    NSCAssert([adapter write:@"feature/value" owner:0 base:(uintptr_t)&owned stat:0 offset:0 bytes:&target length:8],@"new baseline");
    owned=23;NSCAssert(![adapter write:@"feature/value" owner:0 base:(uintptr_t)&owned stat:0 offset:0 bytes:&target length:8]&&owned==23,@"polling does not overwrite a changed external owner");
    [adapter restorePrefix:@""];
    NSCAssert([adapter write:@"feature/value" owner:0 base:(uintptr_t)&owned stat:0 offset:0 bytes:&target length:8],@"disable clears a conflict");
    [adapter restorePrefix:@""];NSCAssert(owned==23,@"fresh baseline is restored");
    NSCAssert([adapter.runReversibleChecks[@"skipped"] length]>0,@"foreign-host checks never masquerade as in-game tests");
    uint64_t local=1,newValue=42;
    NSCAssert(MTWriteMemory(&local,&newValue,8)&&local==42,@"bounded native data write/readback");
    NSCAssert(!MTWriteMemory(&local,&newValue,65)&&!MTWriteMemory(&local,NULL,8)&&!MTWriteMemory(&local,&newValue,0),@"oversize and empty writes fail");
    mach_vm_address_t page=0;NSCAssert(mach_vm_allocate(mach_task_self(),&page,vm_page_size,VM_FLAGS_ANYWHERE)==KERN_SUCCESS,@"allocate test page");
    NSCAssert(mach_vm_protect(mach_task_self(),page,vm_page_size,NO,VM_PROT_READ)==KERN_SUCCESS,@"read-only fixture");
    NSCAssert(!MTWriteMemory((void *)page,&newValue,8),@"read-only memory remains protected");
    mach_vm_deallocate(mach_task_self(),page,vm_page_size);
    puts("Native adapter unit checks: foreign process rejected for all 37 entries, unique hotkeys, bounded data writes, no protection changes.");
}
