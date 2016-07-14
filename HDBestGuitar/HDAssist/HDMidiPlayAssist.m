//
//  HDMidiPlayAssist.m
//  HDBestGuitar
//
//  Created by 邓立兵 on 16/7/11.
//  Copyright © 2016年 HarryDeng. All rights reserved.
//

#import "HDMidiPlayAssist.h"

#import <MIKMIDI/MIKMIDISynthesizer.h>
#import <MIKMIDI/MIKMIDINoteOnCommand.h>
#import <MIKMIDI/MIKMIDINoteOffCommand.h>

@interface HDMidiPlayAssist ()

@property (nonatomic, strong) MIKMIDISynthesizer    *synthesizer;

/**
 *  获取 吉他 不同地方按键对应的音符值(吉他 音符值的二维数组(6 x 25))
 */
@property (nonatomic, strong) NSArray               *guiterNodes;

/**
 *  最后一个midi播放的时间
 */
@property (nonatomic, assign) CFAbsoluteTime        lastMidiPlayTime;

/**
 *  纪录最后一组吉他的数据，用来取消该组吉他时用
 */
@property (nonatomic, strong) NSDictionary          *guitarGroupInfo;


@end

@implementation HDMidiPlayAssist

+ (instancetype)shareInstance{
    static HDMidiPlayAssist *midiPlayAssist;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        midiPlayAssist = [[HDMidiPlayAssist alloc] init];
    });
    return midiPlayAssist;
}

#pragma mark -  延迟实例化
- (MIKMIDISynthesizer *)synthesizer{
    if (!_synthesizer) {
        _synthesizer = [[MIKMIDISynthesizer alloc] init];
        NSURL *soundfont = [[NSBundle mainBundle] URLForResource:@"GeneralUser GS MuseScore v1.442" withExtension:@"sf2"];
        NSError *error = nil;
        if (![_synthesizer loadSoundfontFromFileAtURL:soundfont presetID:27 error:&error]) {
            NSLog(@"Error loading soundfont for synthesizer. Sound will be degraded. %@", error);
        }
    }
    return _synthesizer;
}

- (NSArray *)guiterNodes{
    if (!_guiterNodes){
        _guiterNodes = @[
                         @[@64, @65, @66, @67, @68, @69, @70, @71, @72, @73, @74, @75, @76,
                           @77, @78,@79, @80, @81, @82, @83, @84, @85, @86, @87, @88],
                         
                         @[@59, @60, @61, @62, @63, @64, @65, @66, @67, @68, @69, @70, @71,
                           @72, @73, @74, @75, @76, @77, @78,@79, @80, @81, @82, @83],
                         
                         @[@55, @56, @57, @58, @59, @60, @61, @62, @63, @64, @65, @66, @67,
                           @68, @69, @70, @71, @72, @73, @74, @75, @76, @77, @78,@79],
                         
                         @[@50, @51, @52, @53, @54, @55, @56, @57, @58, @59, @60, @61, @62,
                           @63, @64, @65, @66, @67,@68, @69, @70, @71, @72, @73, @74],
                         
                         @[@45, @46, @47, @48, @49, @50, @51, @52, @53, @54, @55, @56, @57,
                           @58, @59, @60, @61, @62, @63, @64, @65, @66, @67,@68, @69],
                         
                         @[@40, @41, @42, @43, @44, @45, @46, @47, @48, @49, @50, @51, @52,
                           @53, @54, @55, @56, @57, @58, @59, @60, @61, @62, @63, @64]
                         ];
    }
    return _guiterNodes;
}



#pragma mark - 播放midi方法
/**
 *  直接播放midi音符，默认在0.5秒后停止播放该音符
 *
 *  @param note 音符，具体见项目README.md文件说明
 */
- (void)playMidiNote:(NSUInteger)note{
    if (_lastMidiPlayTime == 0) {
        _lastMidiPlayTime = CFAbsoluteTimeGetCurrent();
    }
    else {
        DLog(@"播放 %d 音符  时间间隔%0.2f秒", (int)note, CFAbsoluteTimeGetCurrent() - _lastMidiPlayTime);
        _lastMidiPlayTime = CFAbsoluteTimeGetCurrent();
    }
    
    MIKMIDINoteOnCommand *noteOn = [MIKMIDINoteOnCommand noteOnCommandWithNote:note velocity:127 channel:0 timestamp:[NSDate date]];
    [self.synthesizer handleMIDIMessages:@[noteOn]];
}


/**
 *  停止对播放midi音符 （单个）
 *
 *  @param note note 音符，具体见项目README.md文件说明
 */
- (void)stopPlayMidiNote:(NSUInteger)note{
    MIKMIDINoteOffCommand *noteOff = [MIKMIDINoteOffCommand noteOffCommandWithNote:note velocity:127 channel:0 timestamp:[NSDate date]];
    [self.synthesizer handleMIDIMessages:@[noteOff]];
}

/**
 *  停止对播放midi音符（所有）
 */
- (void)stopPlayMidiAllNotes{
    if (_guitarGroupInfo) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(recursionPlayMidi:) object:_guitarGroupInfo];
    }
}


/**
 *  直接播放midi音符组，默认在0.5秒后停止播放该音符 （同时播放）
 *
 *  @param notes 音符组，具体见项目README.md文件说明
 */
- (void)playMidiNotes:(NSArray <NSNumber *> *)notes{
    
    NSMutableArray *commands = [NSMutableArray array];
    NSMutableString *noteString = [NSMutableString string];
    [notes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [noteString appendFormat:@"%d ", obj.intValue];
        MIKMIDINoteOnCommand *noteOn = [MIKMIDINoteOnCommand noteOnCommandWithNote:obj.unsignedIntegerValue velocity:127 channel:0 timestamp:[NSDate date]];
        [commands addObject:noteOn];
    }];
    
    if (_lastMidiPlayTime == 0) {
        _lastMidiPlayTime = CFAbsoluteTimeGetCurrent();
    }
    else {
        DLog(@"同时播放 %@ 音符组 时间间隔%0.2f秒", noteString, CFAbsoluteTimeGetCurrent() - _lastMidiPlayTime);
        _lastMidiPlayTime = CFAbsoluteTimeGetCurrent();
    }
    
    [self.synthesizer handleMIDIMessages:commands];
}


/**
 *  使用吉他的弦位和品位来播放midi音符，默认在0.5秒后停止播放该音符
 *
 *  @param cord  弦位
 *  @param grade 品位
 */
- (void)playGuitarAtCord:(NSInteger)cord grade:(NSInteger)grade{
    NSUInteger note = [self.guiterNodes[cord][grade] unsignedIntegerValue];
    [self playMidiNote:note];
}


/**
 *  使用吉他的一组弦位和品位(时间间隔默认是0.3秒)来播放midi音符，默认在0.5秒后停止播放该音符
 *
 *  @param cords  一组弦位
 *  @param grades 一组品位（个数要和弦位一样）
 */
- (void)playGuitarAtCords:(NSArray *)cords grades:(NSArray *)grades{
    NSMutableArray *intervals = [NSMutableArray arrayWithCapacity:cords.count];
    for (int i=0; i<cords.count; i++) {
        [intervals addObject:@(0.3)];
    }
    [self playGuitarAtCords:cords grades:grades intervals:intervals];
}

/**
 *  使用吉他的一组弦位和品位 及一组时间间隔 来播放midi音符
 *
 *  @param cords     一组弦位
 *  @param grades    一组品位（个数要和弦位一样）
 *  @param intervals 一组时间间隔（个数要和弦位一样）
 */
- (void)playGuitarAtCords:(NSArray *)cords grades:(NSArray *)grades intervals:(NSArray *)intervals{
    [self playGuitarAtCord:[cords[0] integerValue] grade:[grades[0] integerValue]];
    [self playGuitarAtCords:cords grades:grades intervals:intervals index:1];
}

// 使用递归方法来处理 时间间隔 播放
- (void)playGuitarAtCords:(NSArray *)cords grades:(NSArray *)grades intervals:(NSArray *)intervals index:(NSInteger)index{
    
    if (cords.count <= index) {
        return ;
    }
    
    //因为在播放midi的时候，同步进行， 使用 dispatch_after 需要大概0.02秒的耗时, 就是这么严谨
    // gcd 没有取消 dispatch_after 方法，只能采取其它方法
    // http://stackoverflow.com/questions/12475450/prevent-dispatch-after-background-task-from-being-executed
    /*
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(([intervals[index-1] floatValue] - 0.02) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self playGuitarAtCord:[cords[index] integerValue] grade:[grades[index] integerValue]];
        [self playGuitarAtCords:cords grades:grades intervals:intervals index:index+1];
    });
     */
    
    _guitarGroupInfo = @{
                         @"cords"     : cords,
                         @"grades"    : grades,
                         @"intervals" : intervals,
                         @"index"     : @(index)
                         };
    // 因为在播放midi的时候，同步进行, 使用 performSelector 不需要耗时, 就是这么严谨
    [self performSelector:@selector(recursionPlayMidi:) withObject:_guitarGroupInfo afterDelay:([intervals[index-1] floatValue])];
}

- (void)recursionPlayMidi:(NSDictionary *)info1{
    NSArray *cords = _guitarGroupInfo[@"cords"];
    NSArray *grades = _guitarGroupInfo[@"grades"];
    NSArray *intervals = _guitarGroupInfo[@"intervals"];
    NSInteger index = [_guitarGroupInfo[@"index"] integerValue];
    [self playGuitarAtCord:[cords[index] integerValue] grade:[grades[index] integerValue]];
    [self playGuitarAtCords:cords grades:grades intervals:intervals index:index+1];
}

@end