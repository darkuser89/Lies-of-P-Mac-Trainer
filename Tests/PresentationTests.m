// SPDX-License-Identifier: GPL-3.0-only
#import <AppKit/AppKit.h>
#import "Overlay.h"
#import "TrainerMaterial.h"

@interface MTMaterialFixture : MTTrainerMaterial
@property(nonatomic) BOOL forceReduced,forceLegacy;
@end
@implementation MTMaterialFixture
- (BOOL)reducesTransparency {return self.forceReduced;}
- (BOOL)allowsLiquidGlass {return !self.forceLegacy && [super allowsLiquidGlass];}
@end

static NSEvent *event(NSWindow *w,NSView *view,NSPoint point,NSEventType type){
    return [NSEvent mouseEventWithType:type location:[view convertPoint:point toView:nil] modifierFlags:0 timestamp:0 windowNumber:w.windowNumber context:nil eventNumber:1 clickCount:1 pressure:1];
}
static void materialTests(void){
    NSView *content=[[NSView alloc]initWithFrame:NSMakeRect(0,0,300,200)];
    MTMaterialFixture *surface=[[MTMaterialFixture alloc]initWithContentView:content cornerRadius:14];
    MTTrainerMaterialMode native=[surface allowsLiquidGlass] ? MTTrainerMaterialLiquidGlass : MTTrainerMaterialVibrancy;
    NSCAssert(surface.materialMode==native && [content isDescendantOf:surface],@"native surface retains content");
    surface.forceLegacy=YES;[surface refreshAppearance];
    NSCAssert(surface.materialMode==MTTrainerMaterialVibrancy && [content isDescendantOf:surface],@"older macOS uses vibrancy with same content");
    surface.forceReduced=YES;[surface refreshAppearance];
    NSCAssert(surface.materialMode==MTTrainerMaterialOpaque && [content isDescendantOf:surface],@"Reduce Transparency uses opaque readable background");
    surface.forceLegacy=NO;surface.forceReduced=NO;[surface refreshAppearance];
    NSCAssert(surface.materialMode==native && [content isDescendantOf:surface],@"returning to system material preserves controls");
    NSView *host=[[NSView alloc]initWithFrame:NSMakeRect(0,0,800,600)];[host addSubview:surface];
    surface.frame=NSMakeRect(25,35,300,200);[surface layout];
    NSCAssert([surface hitTest:NSMakePoint(50,50)]==content && ![surface hitTest:NSMakePoint(700,500)],@"material routes hits to content and passes outside clicks through");
    surface.hidden=YES;NSCAssert(![surface hitTest:NSMakePoint(50,50)],@"hidden glass cannot intercept game input");
}
void MTPresentationRunTests(void){@autoreleasepool{
    [NSApplication sharedApplication];materialTests();
    NSWindow *w=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,1100,750) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];w.releasedWhenClosed=NO;
    MTOverlayRoot *root=[[MTOverlayRoot alloc]initWithFrame:NSMakeRect(25,35,1000,650) version:@"UI fixture"];
    [w.contentView addSubview:root];MTTrainerMaterial *surface=(MTTrainerMaterial *)root.panel;
    NSView *panel=surface.contentView;NSArray *rows=panel.subviews;
    NSCAssert(rows.count==(NSUInteger)MTFeatureCount,@"all catalog rows created inside glass content");
    root.panelVisible=NO;NSArray *hiddenSnapshots=[rows valueForKey:@"state"];
    MTTrainerState *state=[MTTrainerState new];state.ready=YES;state.overlayMouseActive=YES;[root updateState:state];
    for(NSUInteger i=0;i<rows.count;i++)NSCAssert([rows[i] valueForKey:@"state"]==hiddenSnapshots[i],@"hidden updates preserve existing presentation");
    for(int n=0;n<1000;n++){MTTrainerState *next=[MTTrainerState new];next.ready=YES;next.overlayMouseActive=YES;[root updateState:next];}
    for(NSUInteger i=0;i<rows.count;i++)NSCAssert([rows[i] valueForKey:@"state"]==hiddenSnapshots[i],@"1000 hidden polls perform no row presentation updates");
    root.panelVisible=YES;
    NSArray *baseline=[rows valueForKey:@"state"];
    for(int n=0;n<1000;n++){MTTrainerState *next=[MTTrainerState new];next.ready=YES;next.overlayMouseActive=YES;[root updateState:next];}
    for(NSUInteger i=0;i<rows.count;i++)NSCAssert([rows[i] valueForKey:@"state"]==baseline[i],@"unchanged visible snapshots reuse row presentation");
    state.features[0].wanted=YES;state.features[0].active=YES;state.features[0].note=@"native readback confirmed";[root updateState:state];
    MTFeatureState *shown=[rows[0] valueForKey:@"state"];
    NSCAssert(shown.active && shown.wanted && [rows[0] accessibilityValue]!=nil,@"real state changes appear in presentation and accessibility");
    for(NSUInteger i=1;i<rows.count;i++)NSCAssert([rows[i] valueForKey:@"state"]==baseline[i],@"changing one feature does not rebuild other rows");
    state.features[0].wanted=NO;state.features[0].active=NO;[root updateState:state];
    NSCAssert(!((MTFeatureState *)[rows[0] valueForKey:@"state"]).wanted,@"in-place state mutation is not lost by presentation caching");
    root.panelVisible=NO;state.features[0].wanted=YES;[root updateState:state];root.panelVisible=YES;
    NSCAssert(((MTFeatureState *)[rows[0] valueForKey:@"state"]).wanted,@"opening renders latest hidden state immediately");
    state.overlayMouseActive=NO;[root updateState:state];
    __block NSInteger clicks=0;
    for(NSNumber *scale in @[@0.7,@0.9,@1.3])for(NSString *position in @[@"top-left",@"center",@"bottom-right"]){
        [root applyOverlayOptions:@{@"visible":@YES,@"scale":scale,@"position":position}];
        [w.contentView layoutSubtreeIfNeeded];
        [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.03]];
        NSCAssert(NSContainsRect(root.bounds,surface.frame),@"glass panel fits window at every scale");
        NSRect rendered=[panel convertRect:panel.bounds toView:surface];
        NSCAssert(fabs(rendered.size.width-surface.bounds.size.width)<1 && fabs(rendered.size.height-surface.bounds.size.height)<1,@"native glass hosts scaled content without clipping its header or footer");
        for(NSInteger i=0;i<MTFeatureCount;i++){
            NSRect rowRect=[rows[i] convertRect:[rows[i] bounds] toView:surface];
            NSCAssert(NSContainsRect(surface.bounds,rowRect),@"each complete row remains visible after native glass layout");
            root.featureHandler=^(MTFeature f){NSCAssert(f==i,@"scaled glass hit maps to correct catalog feature");clicks++;};
            NSInteger before=clicks;NSView *row=rows[i];
            NSCAssert([root handleMouseEvent:event(w,row,NSMakePoint(244,10),NSEventTypeLeftMouseDown)],@"glass row click consumed");
            NSCAssert([root handleMouseEvent:event(w,row,NSMakePoint(244,10),NSEventTypeLeftMouseUp)],@"glass row release consumed");
            NSCAssert(clicks==before+1,@"exactly one action per click");
        }
    }
    NSPoint origin=surface.frame.origin;
    NSEvent *down=event(w,panel,NSMakePoint(80,10),NSEventTypeLeftMouseDown);
    NSCAssert([root handleMouseEvent:down],@"header drag starts through glass");
    NSPoint destination=[root convertPoint:NSMakePoint(origin.x-60,origin.y-40) toView:nil];
    NSEvent *drag=[NSEvent mouseEventWithType:NSEventTypeLeftMouseDragged location:destination modifierFlags:0 timestamp:0 windowNumber:w.windowNumber context:nil eventNumber:1 clickCount:1 pressure:1];
    [root handleMouseEvent:drag];[root handleMouseEvent:event(w,panel,NSMakePoint(80,10),NSEventTypeLeftMouseUp)];
    NSCAssert(!NSEqualPoints(origin,surface.frame.origin) && [root.overlayOptions[@"position"] isEqual:@"free"],@"header drag moves glass and preserves free position");
    for(NSInteger i=0;i<MTFeatureCount;i++){
        const MTFeatureInfo *info=MTFeatureInfoAt(i);if(!info->numeric)continue;
        __block NSInteger edits=0;root.valueHandler=^(MTFeature f,double value){NSCAssert(f==i && value==info->initial,@"numeric editor delivers exact value to original handler");edits++;};
        NSView *row=rows[i];CGFloat x=row.bounds.size.width-(info->integer ? 105 : 85)+5;
        [root handleMouseEvent:event(w,row,NSMakePoint(x,10),NSEventTypeLeftMouseDown)];
        [root handleMouseEvent:event(w,row,NSMakePoint(x,10),NSEventTypeLeftMouseUp)];
        NSString *text=[NSString stringWithFormat:info->integer ? @"%.0f" : @"%.4g",info->initial];
        NSEvent *typing=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:w.windowNumber context:nil characters:text charactersIgnoringModifiers:text isARepeat:NO keyCode:0];
        [root handleEvent:typing];
        NSEvent *enter=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:w.windowNumber context:nil characters:@"\r" charactersIgnoringModifiers:@"\r" isARepeat:NO keyCode:36];
        [root handleEvent:enter];NSCAssert(edits==1,@"numeric editing works through glass without dispatching a cheat action");break;
    }
    root.panelVisible=NO;
    NSCAssert(!root.wantsMouseInteraction && surface.hidden && ![root handleMouseEvent:down],@"hiding returns input without material intercept");
    [w close];printf("Template presentation passed: %ld rows, 1000 hidden/visible updates, glass/fallback/accessibility, scaling/clicks/drag/input.\n",(long)MTFeatureCount);
}}
