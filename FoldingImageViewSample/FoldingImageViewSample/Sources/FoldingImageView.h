//
//  FoldingImageView.h
//  Folding
//
//  Created by DarkKor on 4/19/13.
//  Copyright (c) 2013 DarkKor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define kFoldingCancelValue 0.0
#define kFoldingLimitValue 0.42
#define kPerspective 2500.0
#define kFoldingHorPartStartTag 9877543
#define kFoldingVerPartStartTag 9977544
#define kFoldingOriginalImage 9977545

typedef enum
{
    FoldDirectionRight,//0
    FoldDirectionLeft,//1
    FoldDirectionDown,//2
    FoldDirectionUp,//3
    FoldDirectionNone//4
}
FoldDirection;

typedef void(^FoldingImageViewCompletionBlock)(void);

@interface FoldingImageView : UIView
{
    UIImage *image;
    UIImageView *imgView;
    
    FoldingImageViewCompletionBlock completion;
    
    NSMutableArray *verticalParts, *horizontalParts;
    
    NSArray *supportedDirections;
    FoldDirection activeDirection, maybeActiveDirection;
    
    BOOL shouldFolding, isOpen, isManual;
    int bendsCount;
    float openOffset, currentWidth;
    
    CGPoint firstTouchLocation;
}

@property (nonatomic, assign) float openOffset;
@property (nonatomic, assign) BOOL isManual;
@property (nonatomic, readonly) BOOL isOpen;
@property (nonatomic, readonly) FoldDirection activeDirection;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSArray *supportedDirections;

- (id)initWithImage:(UIImage *)_image frame:(CGRect)_frame bends: (NSInteger)_bends;

- (BOOL)isDirectionSupported: (FoldDirection)direction;

- (void)setImage: (UIImage *)img;

- (void)openToOffset: (float)offset direction: (FoldDirection)direction completion: (void(^)(void))completion;
- (void)closeWithCompletion: (void(^)(void))completion;

@end
