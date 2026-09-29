//
//  DrawingView2.m
//  occoreStudy
//
//  Created by 谢鹏 on 2026/4/2.
//

// DrawingView.m
#import "DrawingView2.h"
#import "Stroke.h"

@interface DrawingView2 ()
@property (nonatomic, strong) NSMutableArray<Stroke *> *strokes; // 所有的笔画记录
@property (nonatomic, strong) Stroke *currentStroke;             // 当前正在画的笔画
@property (nonatomic, strong) UIColor *currentColor;
@property (nonatomic, assign) CGFloat currentLineWidth;
@end

@implementation DrawingView2

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _strokes = [NSMutableArray array];
        _currentLineWidth = 5.0;
        _currentColor = [UIColor blackColor];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

#pragma mark - 触摸事件处理

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    // 1. 创建新的笔画对象
    self.currentStroke = [[Stroke alloc] init];
    self.currentStroke.points = [NSMutableArray array];
    self.currentStroke.color = self.currentColor;
    self.currentStroke.lineWidth = self.currentLineWidth;
    self.currentStroke.type = StrokeTypeFreehand;
    
    // 2. 记录起点
    [self.currentStroke.points addObject:[NSValue valueWithCGPoint:point]];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    // 3. 记录路径点
    [self.currentStroke.points addObject:[NSValue valueWithCGPoint:point]];
    
    // 4. 触发重绘
    // 优化：这里可以计算 dirtyRect 只重绘局部区域，但为了简单演示，我们重绘整个视图
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 5. 笔画结束，存入历史记录
    [self.strokes addObject:self.currentStroke];
    self.currentStroke = nil;
}

#pragma mark - Core Graphics 绘制

- (void)drawRect:(CGRect)rect {
    // 1. 获取当前图形上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 2. 遍历所有已完成的笔画进行重绘
    for (Stroke *stroke in self.strokes) {
        [self drawStroke:stroke inContext:context];
    }
    
    // 3. 绘制当前正在画的笔画
    if (self.currentStroke) {
        [self drawStroke:self.currentStroke inContext:context];
    }
}

// 封装具体的绘制逻辑
- (void)drawStroke:(Stroke *)stroke inContext:(CGContextRef)context {
    if (stroke.points.count < 2) return;
    
    CGContextSaveGState(context); // 保存状态
    
    // 设置样式
    CGContextSetLineWidth(context, stroke.lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound); // 圆角线帽
    CGContextSetLineJoin(context, kCGLineJoinRound); // 圆角连接
    CGContextSetStrokeColorWithColor(context, stroke.color.CGColor);
    
    // 开始路径
    CGContextBeginPath(context);
    
    // 获取点数组
    NSArray<NSValue *> *points = stroke.points;
    CGPoint firstPoint = [points[0] CGPointValue];
    CGContextMoveToPoint(context, firstPoint.x, firstPoint.y);
    
    // 添加线段
    for (int i = 1; i < points.count; i++) {
        CGPoint point = [points[i] CGPointValue];
        CGContextAddLineToPoint(context, point.x, point.y);
    }
    
    // 描边
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context); // 恢复状态
}

#pragma mark - 公共方法

- (void)undo {
    if (self.strokes.count > 0) {
        [self.strokes removeLastObject];
        [self setNeedsDisplay];
    }
}

- (void)clear {
    [self.strokes removeAllObjects];
    [self setNeedsDisplay];
}

// 导出图片功能
- (UIImage *)getImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
