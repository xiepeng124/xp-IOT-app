//
//  DrawingView2.h
//  occoreStudy
//
//  Created by 谢鹏 on 2026/4/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DrawingView2 : UIView
// 清空画布
- (void)clear;
// 撤销上一步
- (void)undo;
// 获取当前绘制内容的图片
- (UIImage *)getImage;
@end

NS_ASSUME_NONNULL_END
