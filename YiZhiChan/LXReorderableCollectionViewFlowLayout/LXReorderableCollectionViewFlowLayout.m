//
//  LXReorderableCollectionViewFlowLayout.m
//
//  Created by Stan Chang Khin Boon on 1/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "LXReorderableCollectionViewFlowLayout.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#ifndef CGGEOMETRY_LXSUPPORT_H_
CG_INLINE CGPoint
LXS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, LXScrollingDirection) {
    LXScrollingDirectionUnknown = 0,
    LXScrollingDirectionUp,
    LXScrollingDirectionDown,
    LXScrollingDirectionLeft,
    LXScrollingDirectionRight
};

static NSString * const kLXScrollingDirectionKey = @"LXScrollingDirection";
static NSString * const kLXCollectionViewKeyPath = @"collectionView";


/**
 *  CADisplayLink分类
 */
@interface CADisplayLink (LX_userInfo)
@property (nonatomic, copy) NSDictionary *LX_userInfo;
@end

@implementation CADisplayLink (LX_userInfo)
- (void) setLX_userInfo:(NSDictionary *) LX_userInfo {
    objc_setAssociatedObject(self, "LX_userInfo", LX_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *) LX_userInfo {
    return objc_getAssociatedObject(self, "LX_userInfo");
}
@end


/**
 *  UICollectionViewCell分类
 *  提供截取UICollectionViewCell的功能
 */
@interface UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIView *)LX_snapshotView;

@end

@implementation UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIView *)LX_snapshotView {
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        return [self snapshotViewAfterScreenUpdates:YES];
    } else {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [[UIImageView alloc] initWithImage:image];
    }
}

@end


@interface LXReorderableCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;
@property (strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDataSource> dataSource;
@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDelegateFlowLayout> delegate;

@end

@implementation LXReorderableCollectionViewFlowLayout

- (void)setDefaults {
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

/**
 *  给collectionView添加手势识别器
 */
- (void)setupCollectionView {
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];

    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object:nil];
}

/**
 *  从collectionView上移除手势识别器
 */
- (void)tearDownCollectionView {
    // Tear down long press gesture
    if (_longPressGestureRecognizer) {
        UIView *view = _longPressGestureRecognizer.view;
        if (view) {
            [view removeGestureRecognizer:_longPressGestureRecognizer];
        }
        _longPressGestureRecognizer.delegate = nil;
        _longPressGestureRecognizer = nil;
    }
    
    // Tear down pan gesture
    if (_panGestureRecognizer) {
        UIView *view = _panGestureRecognizer.view;
        if (view) {
            [view removeGestureRecognizer:_panGestureRecognizer];
        }
        _panGestureRecognizer.delegate = nil;
        _panGestureRecognizer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self invalidatesScrollTimer];
    [self tearDownCollectionView];
    [self removeObserver:self forKeyPath:kLXCollectionViewKeyPath];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.hidden = YES;
    }
}

- (id<LXReorderableCollectionViewDataSource>)dataSource {
    return (id<LXReorderableCollectionViewDataSource>)self.collectionView.dataSource;
}

- (id<LXReorderableCollectionViewDelegateFlowLayout>)delegate {
    return (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}

/**
 *  更新布局
 */
- (void)invalidateLayoutIfNecessary {
    // 获取当前移动到的位置所在的indexPath
    NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:self.currentView.center];
    // 上一次所在的indexPath
    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    
    if ((newIndexPath == nil) || [newIndexPath isEqual:previousIndexPath]) {
        return;
    }
    
    // 询问代理是否可以从前一个位置移动到当前位置
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        ![self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath]) {
        return;
    }
    
    self.selectedItemIndexPath = newIndexPath;
    
    // 通知代理将要从前一个位置移动到当前位置
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
    }

    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
//            [strongSelf.collectionView deleteItemsAtIndexPaths:@[ previousIndexPath ]];
//            [strongSelf.collectionView insertItemsAtIndexPaths:@[ newIndexPath ]];
//            [strongSelf.collectionView moveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
//            [strongSelf.collectionView reloadData];
//            [self invalidateLayout];
        }
    } completion:^(BOOL finished) {
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath didMoveToIndexPath:newIndexPath];
        }
    }];
//    [self.collectionView reloadData];
//    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
//        [self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath didMoveToIndexPath:newIndexPath];
//    }
}

/**
 *  停止定时器
 */
- (void)invalidatesScrollTimer {
//    if (!self.displayLink.paused) {
//        [self.displayLink invalidate];
//    }
//    self.displayLink = nil;
}

/**
 *  在制定方向上开启定时器
 *
 *  @param direction 制定方向
 */
- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction {
//    if (!self.displayLink.paused) {
//        LXScrollingDirection oldDirection = [self.displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
//
//        if (direction == oldDirection) {
//            return;
//        }
//    }
//    
//    [self invalidatesScrollTimer];
//
//    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
//    self.displayLink.LX_userInfo = @{ kLXScrollingDirectionKey : @(direction) };
//
//    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Target/Action methods

// Tight loop, allocate memory sparely, even if they are stack allocation.
/**
 *  定时器处理方法
 *
 *  @param displayLink <#displayLink description#>
 */
- (void)handleScroll:(CADisplayLink *)displayLink {
//    LXScrollingDirection direction = (LXScrollingDirection)[displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
//    if (direction == LXScrollingDirectionUnknown) {
//        return;
//    }
//    
//    CGSize frameSize = self.collectionView.bounds.size;
//    CGSize contentSize = self.collectionView.contentSize;
//    CGPoint contentOffset = self.collectionView.contentOffset;
//    UIEdgeInsets contentInset = self.collectionView.contentInset;
//    // Important to have an integer `distance` as the `contentOffset` property automatically gets rounded
//    // and it would diverge from the view's center resulting in a "cell is slipping away under finger"-bug.
//    CGFloat distance = rint(self.scrollingSpeed * displayLink.duration);
//    CGPoint translation = CGPointZero;
//    
//    switch(direction) {
//        case LXScrollingDirectionUp: {
//            distance = -distance;
//            CGFloat minY = 0.0f - contentInset.top;
//            
//            if ((contentOffset.y + distance) <= minY) {
//                distance = -contentOffset.y - contentInset.top;
//            }
//            
//            translation = CGPointMake(0.0f, distance);
//        } break;
//        case LXScrollingDirectionDown: {
//            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom;
//            
//            if ((contentOffset.y + distance) >= maxY) {
//                distance = maxY - contentOffset.y;
//            }
//            
//            translation = CGPointMake(0.0f, distance);
//        } break;
//        case LXScrollingDirectionLeft: {
//            distance = -distance;
//            CGFloat minX = 0.0f - contentInset.left;
//            
//            if ((contentOffset.x + distance) <= minX) {
//                distance = -contentOffset.x - contentInset.left;
//            }
//            
//            translation = CGPointMake(distance, 0.0f);
//        } break;
//        case LXScrollingDirectionRight: {
//            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width + contentInset.right;
//            
//            if ((contentOffset.x + distance) >= maxX) {
//                distance = maxX - contentOffset.x;
//            }
//            
//            translation = CGPointMake(distance, 0.0f);
//        } break;
//        default: {
//            // Do nothing...
//        } break;
//    }
//    
//    self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, translation);
//    self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
//    self.collectionView.contentOffset = LXS_CGPointAdd(contentOffset, translation);
}

/**
 *  处理长按手势
 *
 */
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            
            // 询问代理长按处的图标是否可以移动
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
               ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            self.currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];
            
            // 获取collectionViewCell高亮状态时的截图
            collectionViewCell.highlighted = YES;
            UIView *highlightedImageView = [collectionViewCell LX_snapshotView];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;
            
            // 获取collectionViewCell正常状态时的截图
            collectionViewCell.highlighted = NO;
            UIView *imageView = [collectionViewCell LX_snapshotView];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            [self.collectionView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            // 实现识别长按手势时图标放大效果
            __weak typeof(self) weakSelf = self;
            [UIView
             animateWithDuration:0.3
             delay:0.0
             options:UIViewAnimationOptionBeginFromCurrentState
             animations:^{
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     strongSelf.currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                     highlightedImageView.alpha = 0.0f;
                     imageView.alpha = 1.0f;
                 }
             }
             completion:^(BOOL finished) {
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     [highlightedImageView removeFromSuperview];
                     
                     if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                         [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                     }
                 }
             }];
            
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            
            if (currentIndexPath) {
                // 通知代理停止移动
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                }
                
                self.selectedItemIndexPath = nil;
                self.currentViewCenter = CGPointZero;
                
                UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];
                
                self.longPressGestureRecognizer.enabled = NO;
                
                __weak typeof(self) weakSelf = self;
                [UIView
                 animateWithDuration:0.3
                 delay:0.0
                 options:UIViewAnimationOptionBeginFromCurrentState
                 animations:^{
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                         strongSelf.currentView.center = layoutAttributes.center;
                     }
                 }
                 completion:^(BOOL finished) {
                     
                     self.longPressGestureRecognizer.enabled = YES;
                     
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         [strongSelf.currentView removeFromSuperview];
                         strongSelf.currentView = nil;
                         [strongSelf invalidateLayout];
                         
                         if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                             [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:currentIndexPath];
                         }
                     }
                 }];
            }
        } break;
            
        default: break;
    }
}

/**
 *  处理移动手势
 *
 */
- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            // 获取移动的增量
            self.panTranslationInCollectionView = [gestureRecognizer translationInView:self.collectionView];
            
            CGPoint viewCenter = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            self.currentView.center = viewCenter;
            
            // 在移动的过程中随时更新布局
            [self invalidateLayoutIfNecessary];
            
//            switch (self.scrollDirection) {
//                case UICollectionViewScrollDirectionVertical: {
//                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
//                        [self setupScrollTimerInDirection:LXScrollingDirectionUp];
//                    } else {
//                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
//                            [self setupScrollTimerInDirection:LXScrollingDirectionDown];
//                        } else {
//                            [self invalidatesScrollTimer];
//                        }
//                    }
//                } break;
//                case UICollectionViewScrollDirectionHorizontal: {
//                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
//                        [self setupScrollTimerInDirection:LXScrollingDirectionLeft];
//                    } else {
//                        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
//                            [self setupScrollTimerInDirection:LXScrollingDirectionRight];
//                        } else {
//                            [self invalidatesScrollTimer];
//                        }
//                    }
//                } break;
//            }
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self invalidatesScrollTimer];
        } break;
        default: {
            // Do nothing...
        } break;
    }
}

#pragma mark - UICollectionViewLayout overridden methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                [self applyLayoutAttributes:layoutAttributes];
            } break;
            default: {
                // Do nothing...
            } break;
        }
    }
    
    return layoutAttributesForElementsInRect;
}

/**
 *  获取indexPath处的布局属性
 *
 */
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            [self applyLayoutAttributes:layoutAttributes];
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    return layoutAttributes;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kLXCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
            [self tearDownCollectionView];
        }
    }
}

#pragma mark - Notifications

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

#pragma mark - Depreciated methods

#pragma mark Starting from 0.1.0
- (void)setUpGestureRecognizersOnCollectionView {
    // Do nothing...
}

@end
