//
//  UIImage+Cropping.m
//  FoldingImageViewSample
//
//  Created by Jim Korbin on 4/20/13.
//  Copyright (c) 2013 DarkKor. All rights reserved.
//

#import "UIImage+Cropping.h"

#define isRetina (([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && [[UIScreen mainScreen] scale] == 2.0 ? YES : NO))

@implementation UIImage (Cropping)

- (UIImage *)cropWithRect: (CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    [self drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)];
    
    UIImage *_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return _image;
}

@end
