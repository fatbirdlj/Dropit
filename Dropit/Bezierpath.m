//
//  Bezierpath.m
//  Dropit
//
//  Created by 刘江 on 2017/3/28.
//  Copyright © 2017年 Flicker. All rights reserved.
//

#import "Bezierpath.h"

@implementation Bezierpath

- (void)setPath:(UIBezierPath *)path{
    _path = path;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect{
    [self.path stroke];
}

@end
