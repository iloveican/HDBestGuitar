//
//  HDGuitarCordView.h
//  HDBestGuitar
//
//  Created by Harry on 16/7/7.
//  Copyright © 2016年 HarryDeng. All rights reserved.
//

#import <UIKit/UIKit.h>


@class HDGuitarCordView;

@protocol HDGuitarCordViewDelegate <NSObject>

/**
 *  吉他六弦界面，点击的第几根弦
 *
 *  @param guitarCordView 吉他六弦界面
 *  @param index          第几根弦 0-5: 第一到第六弦
 */
- (void)hdGuitarCordView:(HDGuitarCordView *)guitarCordView atIndex:(NSInteger)index;

@end


/**
 *  六线谱界面
 */
@interface HDGuitarCordView : UIView

@property (nonatomic, assign) id <HDGuitarCordViewDelegate> delegate;

/**
 *  促发 第 index 弦动画效果
 *
 *  @param index
 */
- (void)animationGuitarCordLineAtIndex:(NSInteger)index;

@end
