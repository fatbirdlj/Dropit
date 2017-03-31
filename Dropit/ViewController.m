//
//  ViewController.m
//  Dropit
//
//  Created by 刘江 on 2017/3/28.
//  Copyright © 2017年 Flicker. All rights reserved.
//

#import "ViewController.h"
#import "Bezierpath.h"

@interface ViewController () <UIDynamicAnimatorDelegate,UICollisionBehaviorDelegate>
@property (weak, nonatomic) IBOutlet Bezierpath *gameView;
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIAttachmentBehavior *attachment;
@property (weak, nonatomic) UIView *dropView;
@property (nonatomic) CGSize dropSize;
@property (strong, nonatomic) UICollisionBehavior *collision;
@property (strong, nonatomic) UIGravityBehavior *gravity;
@property (strong, nonatomic) UIDynamicItemBehavior *animationOption;
@end

@implementation ViewController

#pragma mark - Getter

- (UIDynamicAnimator *)animator{
    if (!_animator) {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.gameView];
        _animator.delegate = self;
    }
    return _animator;
}

- (UICollisionBehavior *)collision{
    if (!_collision) {
        _collision = [[UICollisionBehavior alloc] init];
        _collision.translatesReferenceBoundsIntoBoundary = YES;
        _collision.collisionDelegate = self;
        [self.animator addBehavior:_collision];
    }
    return _collision;
}

- (UIGravityBehavior *)gravity{
    if (!_gravity) {
        _gravity = [[UIGravityBehavior alloc] init];
        _gravity.magnitude = 0.9;
        [self.animator addBehavior:_gravity];
    }
    return _gravity;
}

- (UIDynamicItemBehavior *)animationOption{
    if (!_animationOption) {
        _animationOption = [[UIDynamicItemBehavior alloc] init];
        _animationOption.allowsRotation = NO;
        [self.animator addBehavior:_animationOption];
    }
    return _animationOption;
}

#pragma mark - Add Animation for Item

- (void)addAnimationForItem:(id<UIDynamicItem>)item{
    [self.gravity addItem:item];
    [self.collision addItem:item];
    [self.animationOption addItem:item];
}

#pragma mark - Remove Animation for Item

- (void)removeAnimationForItem:(id<UIDynamicItem>)item{
    [self.gravity removeItem:item];
    [self.collision removeItem:item];
    [self.animationOption removeItem:item];
}


#pragma mark - Gesture Event

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    [self drop];
}

- (void)drop{
    int randomX = (arc4random() % (int)self.gameView.bounds.size.width)/ self.dropSize.width;
    CGRect frame = CGRectMake(randomX * self.dropSize.width, self.dropSize.height/2, self.dropSize.width, self.dropSize.height);
    
    UIView *dropView = [[UIView alloc] initWithFrame:frame];
    dropView.backgroundColor = [UIColor greenColor];
    [self.gameView addSubview:dropView];
    [self addAnimationForItem:dropView];
    self.dropView = dropView;
}


- (IBAction)pan:(UIPanGestureRecognizer *)sender {
    CGPoint gesturePoint = [sender locationInView:self.gameView];
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self attachDropviewToPoint:gesturePoint];
    } else if (sender.state == UIGestureRecognizerStateChanged){
        self.attachment.anchorPoint = gesturePoint;
    } else if (sender.state == UIGestureRecognizerStateEnded){
        [self.animator removeBehavior:self.attachment];
        self.gameView.path = nil;
    }
}

- (void)attachDropviewToPoint:(CGPoint)anchorPoint{
    if (self.dropView) {
        self.attachment = [[UIAttachmentBehavior alloc] initWithItem:self.dropView attachedToAnchor:anchorPoint];
        __weak UIView *dropView = self.dropView;
        __weak ViewController *weakself = self;
        self.attachment.action = ^{
            UIBezierPath *path = [[UIBezierPath alloc] init];
            [path moveToPoint:weakself.attachment.anchorPoint];
            [path addLineToPoint:dropView.center];
            weakself.gameView.path = path;
        };
        self.dropView = nil;
        [self.animator addBehavior:self.attachment];
    }
}

#pragma mark - Drop Size Definition

#define blockMaxCount 8

- (CGSize)dropSize{
    if (!_dropSize.width && !_dropSize.height) {
        int x = self.gameView.bounds.size.width / blockMaxCount;
        _dropSize = CGSizeMake(x, x);
    }
    return _dropSize;
}

#pragma mark - Remove Completed Rows

- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier{
    [self removeCompletedRows];
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator{
    [self removeCompletedRows];
}

- (void)removeCompletedRows{
    NSMutableArray *dropsToRemove = [[NSMutableArray alloc] init];
    
    for (CGFloat y=self.gameView.bounds.size.height-self.dropSize.height/2; y>0; y-=self.dropSize.height) {
        
        BOOL rowIsComplete = YES;
        NSMutableArray *dropsFound = [[NSMutableArray alloc] init];
        for (CGFloat x=self.dropSize.width/2; x<=self.gameView.bounds.size.width-self.dropSize.width/2; x+=self.dropSize.width) {
            UIView *hitView = [self.gameView hitTest:CGPointMake(x, y) withEvent:nil];
            if ([hitView superview] == self.gameView) {
                [dropsFound addObject:hitView];
            } else {
                rowIsComplete = NO;
                break;
            }
        }
        
        if (![dropsFound count]) break;
        if (rowIsComplete) [dropsToRemove addObjectsFromArray:dropsFound];
    }
    
    if ([dropsToRemove count]) {
        for (UIView *drop in dropsToRemove) {
            [self removeAnimationForItem:drop];
        }
        
        [self animateRemovingDrops:dropsToRemove];
    }
}

- (void)animateRemovingDrops:(NSArray *)dropsToRemove{
    [UIView animateWithDuration:0.2 animations:^{
        for (UIView *drop in dropsToRemove) {
            drop.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        [dropsToRemove makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }];
}


@end
