// SPDX-License-Identifier: GPL-3.0-only
#import "TrainerMaterial.h"
#import <QuartzCore/QuartzCore.h>

@implementation MTTrainerMaterial {
    NSView *_material;
    CGFloat _radius;
    id _displayObserver;
}
- (instancetype)initWithContentView:(NSView *)content cornerRadius:(CGFloat)radius {
    if((self=[super initWithFrame:content.frame])) {
        _contentView=content;_radius=radius;
        self.identifier=@"TrainerMaterial";
        [self refreshAppearance];
        __weak MTTrainerMaterial *weakSelf=self;
        _displayObserver=[NSWorkspace.sharedWorkspace.notificationCenter
            addObserverForName:NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification object:nil
            queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *event){(void)event;[weakSelf refreshAppearance];}];
    }return self;
}
- (void)dealloc {if(_displayObserver)[NSWorkspace.sharedWorkspace.notificationCenter removeObserver:_displayObserver];}
- (BOOL)isFlipped {return YES;}
- (BOOL)isOpaque {return NO;}
- (BOOL)allowsLiquidGlass {if(@available(macOS 26.0,*))return YES;return NO;}
- (BOOL)reducesTransparency {return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceTransparency || NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;}
- (void)refreshAppearance {
    BOOL reduced=[self reducesTransparency];
    MTTrainerMaterialMode mode=reduced ? MTTrainerMaterialOpaque : [self allowsLiquidGlass] ? MTTrainerMaterialLiquidGlass : MTTrainerMaterialVibrancy;
    if(_material && mode==_materialMode)return;
    if(@available(macOS 26.0,*))if([_material isKindOfClass:NSGlassEffectView.class])((NSGlassEffectView *)_material).contentView=nil;
    [_contentView removeFromSuperview];[_material removeFromSuperview];
    _materialMode=mode;
    if(@available(macOS 26.0,*)) {
        if(mode==MTTrainerMaterialLiquidGlass){
            NSGlassEffectView *glass=[[NSGlassEffectView alloc]initWithFrame:self.bounds];
            glass.cornerRadius=_radius;glass.style=NSGlassEffectViewStyleRegular;
            glass.contentView=_contentView;_material=glass;
        }
    }
    if(!_material || mode!=MTTrainerMaterialLiquidGlass){
        if(mode==MTTrainerMaterialVibrancy){
            NSVisualEffectView *blur=[[NSVisualEffectView alloc]initWithFrame:self.bounds];
            blur.material=NSVisualEffectMaterialHUDWindow;blur.blendingMode=NSVisualEffectBlendingModeWithinWindow;
            blur.state=NSVisualEffectStateActive;_material=blur;
        }else{
            _material=[[NSView alloc]initWithFrame:self.bounds];_material.wantsLayer=YES;
            _material.layer.backgroundColor=[NSColor colorWithWhite:0.09 alpha:1].CGColor;
        }
        _material.wantsLayer=YES;_material.layer.cornerRadius=_radius;_material.layer.masksToBounds=YES;
        [_material addSubview:_contentView];
    }
    _material.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
    _contentView.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
    [self addSubview:_material];[self layout];
}
- (void)layout {
    [super layout];_material.frame=self.bounds;_contentView.frame=_material.bounds;
    NSSize size=_logicalContentSize.width>0 && _logicalContentSize.height>0 ? _logicalContentSize : _material.bounds.size;
    _contentView.bounds=NSMakeRect(0,0,size.width,size.height);
}
- (NSView *)hitTest:(NSPoint)point {
    // Route directly to existing controls, not the material's private subviews.
    if(self.isHiddenOrHasHiddenAncestor || !NSPointInRect([self convertPoint:point fromView:self.superview],self.bounds))return nil;
    return [_contentView hitTest:[_contentView.superview convertPoint:point fromView:self.superview]];
}
@end
