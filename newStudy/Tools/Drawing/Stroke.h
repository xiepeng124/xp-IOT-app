//
//  Steoke.h
//  occoreStudy
//
//  Created by 谢鹏 on 2026/4/2.
//

// Stroke.h
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, StrokeType) {
    StrokeTypeFreehand, // 自由绘制
    StrokeTypeLine,     // 直线 (可扩展)
    StrokeTypeRect      // 矩形 (可扩展)
};

@interface Stroke : NSObject
@property (nonatomic, strong) NSMutableArray<NSValue *> *points; // 存储 CGPoint
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) StrokeType type;
@end
