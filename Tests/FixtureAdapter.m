// SPDX-License-Identifier: GPL-3.0-only
#import "FixtureAdapter.h"
@implementation MTFixtureAdapter {
    NSMutableDictionary<NSNumber *,NSNumber *> *_data;
    NSMutableDictionary<NSNumber *,NSDictionary *> *_effects;
    NSString *_world;
    BOOL _activated;
}
- (instancetype)init {if((self=[super init])){_effects=[NSMutableDictionary new];_mode=MTSessionSolo;[self newArea];}return self;}
- (NSDictionary *)values {return [_data copy];}
- (void)newArea {_world=NSUUID.UUID.UUIDString;_data=[NSMutableDictionary new];for(NSInteger i=0;i<MTFeatureCount;i++)_data[@(i)]=@(MTFeatureInfoAt(i)->initial);_data[@(MTFeatureHealth)]=@50;_data[@(MTFeatureStamina)]=@40;_data[@(MTFeatureLegion)]=@6;_data[@(MTFeaturePlayerMultiplier)]=@1;_data[@(MTFeatureErgo)]=@500;_data[@(MTFeatureSaveCoordinates)]=@10;}
- (void)onGameThread:(dispatch_block_t)work {dispatch_async(dispatch_get_main_queue(),work);}
- (MTGameContext *)captureContext {MTGameContext *c=[MTGameContext new];c.kind=_mode;c.identity=_mode==MTSessionLoading ? @"loading" : _world;c.note=@"TEST: ausschließlich simulierte Werte, keine Spielanbindung.";return c;}
- (void)releaseFeature:(NSNumber *)key {NSDictionary *record=_effects[key];if(record){NSMutableDictionary *owner=record[@"owner"];owner[key]=record[@"original"];[_effects removeObjectForKey:key];}}
- (void)releaseEffects {for(NSNumber *key in _effects.allKeys)[self releaseFeature:key];_activated=NO;}
- (MTFeatureState *)applyFeature:(MTFeature)feature wanted:(BOOL)wanted value:(double)value {
    MTFeatureState *result=[MTFeatureState new];result.available=YES;result.note=@"TEST: Änderung nur im simulierten Modell.";
    if(feature==MTFeatureActivate){if(_activated&&!wanted)[self releaseEffects];_activated=wanted;result.active=_activated;return result;}
    if(!_activated)return result;
    NSNumber *key=@(feature);NSDictionary *record=_effects[key];
    if(record && (!wanted || record[@"owner"]!=_data)){[self releaseFeature:key];record=nil;}
    if(wanted && !MTFeatureInfoAt(feature)->oneShot){
        if(!record){record=@{@"owner":_data,@"original":_data[key]};_effects[key]=record;}
        double target=feature==MTFeaturePlayerMultiplier ? [record[@"original"] doubleValue]*value : feature==MTFeatureLegion ? 99 : 100;
        _data[key]=@(target);result.active=[_data[key] doubleValue]==target;
    }return result;
}
- (NSString *)performOneShot:(MTFeature)feature value:(double)value {
    if(!_activated)return @"TEST: native master is required before an action";
    if(feature==MTFeatureErgo)_data[@(feature)]=@(value);
    if(feature==MTFeatureSaveCoordinates)_data[@(feature)]=@([_data[@(feature)] doubleValue]+100);
    return [NSString stringWithFormat:@"TEST: %@ = %@ · nur Simulation",MTFeatureInfoAt(feature)->title,_data[@(feature)]];
}
- (BOOL)setOverlayInteraction:(BOOL)wanted {return wanted;}
@end
