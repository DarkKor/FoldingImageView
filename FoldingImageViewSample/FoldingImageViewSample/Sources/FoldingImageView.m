//
//  FoldingImageView.m
//  Folding
//
//  Created by DarkKor on 4/19/13.
//  Copyright (c) 2013 DarkKor. All rights reserved.
//

#import "FoldingImageView.h"

#define CGPointDistance(first, second)(sqrt(pow(first.x - second.x, 2) + pow(first.y - second.y, 2)))
#define kAnimationDuration 0.1
#define DEGREES_TO_RADIANS(__ANGLE__) ( __ANGLE__ * M_PI / 180.0)
#define partsCount 6

#define isRetina (([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && [[UIScreen mainScreen] scale] == 2.0 ? YES : NO))

@interface FoldingImageView ()

@property (nonatomic, copy) FoldingImageViewCompletionBlock completion;

- (void)loadPartsForFolding: (FoldDirection)direction withTag: (int)tag hidden: (BOOL)hidden;
- (void)preparePartsForTag: (int)tag;
- (void)makeParts;

@end

@implementation FoldingImageView

@synthesize supportedDirections;
@synthesize isManual;
@synthesize isOpen;
@synthesize openOffset;
@synthesize image;
@synthesize completion;
@synthesize activeDirection;

- (id)initWithImage:(UIImage *)_anImage frame:(CGRect)_frame bends: (NSInteger)_bends
{
    self = [super initWithFrame:_frame];
    if(self)
    {
        image = [_anImage retain];
        currentWidth = _frame.size.width;
        openOffset = _frame.size.width * 0.5;
        bendsCount = _bends;
        isManual = YES;
        
        supportedDirections = [@[
                                 [NSNumber numberWithInt:FoldDirectionRight],
                                 [NSNumber numberWithInt:FoldDirectionLeft],
                                 [NSNumber numberWithInt:FoldDirectionUp],
                                 [NSNumber numberWithInt:FoldDirectionDown]
                               ] retain];
        
        [self makeParts];
        
        shouldFolding = NO;
        activeDirection = FoldDirectionNone;
        maybeActiveDirection = activeDirection;
    }
    return self;
}


- (void)dealloc
{
    [image release];
    [supportedDirections release];
    [imgView release];
    [completion release];
    [super dealloc];
}

#pragma mark - Public Methods

- (BOOL)isDirectionSupported: (FoldDirection)direction
{
    return [supportedDirections containsObject:[NSNumber numberWithInt:direction]];
}

- (void)openToOffset: (float)offset direction: (FoldDirection)direction completion: (void(^)(void))_completion
{
    if(isOpen)
    {
        NSLog(@"Close your folding view at first.");
        return;
    }
    
    activeDirection = direction;
    openOffset = offset;
    
    [self foldWithAngle: [self angleForOffset:openOffset]
              direction: direction
               animated: YES
             completion: ^{
                 isOpen = YES;
                 _completion();
             }];
}

- (void)closeWithCompletion: (void(^)(void))_completion
{
    [self foldWithAngle:0
              direction:activeDirection
               animated:YES
             completion:^{
                 isOpen = NO;
                 _completion();
             }];
}

- (void)setIsManual:(BOOL)_isManual
{
    isManual = _isManual;
    self.userInteractionEnabled = isManual;
}

- (void)setImage:(UIImage *)img
{
    if(img != image)
    {
        [img retain];
        [image release];
        image = img;
    }
    
    __block FoldingImageView *_self = self;
    FoldingImageViewCompletionBlock _completion = ^{
        NSLog(@"ok!");
        
        
        
        UIImageView *_imgView = [[UIImageView alloc] initWithImage:image];
        _imgView.alpha = 0.0;
        [_self addSubview:_imgView];
        [_imgView release];
        
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        CGRect frame = indicator.frame;
        frame.origin.x = CGRectGetMidX(_imgView.frame) - frame.size.width * 0.5;
        frame.origin.y = CGRectGetMidY(_imgView.frame) - frame.size.height * 0.5;
        indicator.frame = frame;
        
        [indicator startAnimating];
        [_self addSubview:indicator];
        [indicator release];
        
        [UIView animateWithDuration:0.5
                         animations:^{
                             _imgView.alpha = 1.0;
                         }
                         completion:^(BOOL finished){
                             [_self makeParts];
                             [_imgView removeFromSuperview];
                             [indicator removeFromSuperview];
                         }];
        
    };
    
    if(isOpen)
        [self foldWithAngle:0 direction:activeDirection animated:YES completion:^{
            isOpen = NO;
            activeDirection = FoldDirectionNone;
            _completion();
        }];
    else
        _completion();
}

#pragma mark - Private Utility Methods

- (BOOL)isDirectionIsHorizontal:(FoldDirection)direction
{
    if(direction == FoldDirectionRight || direction == FoldDirectionLeft)
        return YES;
    else
        return NO;
}

- (void)makeParts
{
    BOOL hidden = [self isDirectionIsHorizontal:activeDirection];
    
    //  Split image to foldable parts
    [self loadPartsForFolding:FoldDirectionRight withTag:kFoldingHorPartStartTag hidden:!hidden];
    [self loadPartsForFolding:FoldDirectionUp withTag:kFoldingVerPartStartTag hidden:hidden];
}

- (void)preparePartsForTag:(int)tag
{
    int anotherTag;
    if(tag == kFoldingHorPartStartTag)
        anotherTag = kFoldingVerPartStartTag;
    else if(tag == kFoldingVerPartStartTag)
        anotherTag = kFoldingHorPartStartTag;
    
    for(int i = 0; i < bendsCount; i++)
    {
        [[self viewWithTag:(tag+i)] setHidden:NO];
        [[self viewWithTag:(anotherTag+i)] setHidden:YES];
    }
}

- (void)loadPartsForFolding: (FoldDirection)direction withTag: (int)tag hidden: (BOOL)hidden
{
    double width, height;
    
    //Calc dimensions
    if(direction == FoldDirectionRight || direction == FoldDirectionLeft)
    {
        width = image.size.width * (1.0f / bendsCount);
        height = image.size.height;
    }
    else if(direction == FoldDirectionDown || direction == FoldDirectionUp)
    {
        width = image.size.width;
        height = image.size.height * (1.0f / bendsCount);
    }
    
    
    //Split
    for(int i = 0; i < bendsCount; i++)
    {
        //Calc rect
        CGRect rectPart, rectImage;
        if(direction == FoldDirectionRight || direction == FoldDirectionLeft)
        {
            rectPart = CGRectMake(i * width, 0, width, height);
            rectImage = CGRectMake(i * width, 0, width, height);
        }
        else if(direction == FoldDirectionDown || direction == FoldDirectionUp)
        {
            rectPart = CGRectMake(0, i * height, width, height);
            rectImage = CGRectMake(0, i * height, width, height);
        }
        
        UIView *oldPart = [[self viewWithTag:tag + i] retain];
        [oldPart removeFromSuperview];
        CALayer *oldShadowLayer = [[oldPart.layer sublayers] objectAtIndex:0];
        
        UIImage *img = [self crop:image rect:rectImage];
        
        //Create part
        UIView *part = [[UIView alloc] initWithFrame:rectPart];
        part.contentScaleFactor = image.scale;
        part.layer.contentsScale = image.scale;
        part.layer.contents = (id)img.CGImage;
        part.tag = (tag+i);
        part.hidden = hidden;
        [self addSubview:part];
        if(oldPart)
        {
            part.layer.transform = oldPart.layer.transform;
            part.layer.position = oldPart.layer.position;
        }
        [part release];
        
        //Add shadow layer
        CALayer *shadowLayer = [CALayer layer];
        shadowLayer.anchorPoint = CGPointMake(0.0, 0.0);
        shadowLayer.bounds = CGRectMake(0, 0.0, width, height);
        shadowLayer.backgroundColor = [UIColor blackColor].CGColor;
        shadowLayer.opacity = oldShadowLayer == nil ? 0.0 : oldShadowLayer.opacity;
        [part.layer insertSublayer:shadowLayer atIndex:0];
        
        [oldPart release];
    }
    
    //  Remove unused parts
    for(UIView *view in self.subviews)
    {
        if(view.tag >= tag + bendsCount)
            [view removeFromSuperview];
    }
}

- (void)foldWithAngle: (float)value direction: (FoldDirection)direction animated: (BOOL)animated completion: (void(^)(void))_completion
{
    //  Setup layers and parts
    int tag = ([self isDirectionIsHorizontal:direction] ? kFoldingHorPartStartTag : kFoldingVerPartStartTag);
    [self preparePartsForTag:tag];
    
    //  Variables
    int i = (direction == FoldDirectionRight || direction == FoldDirectionDown ? 0 : bendsCount-1);/*step from 0 to 3 for rigth and up, downstep from 3 to 0 for left and down*/
    double width = image.size.width * (1.0f / bendsCount);
    double height = image.size.height * (1.0f / bendsCount);
    double dir;
    double offset;
    CATransform3D trans = CATransform3DIdentity;
	
    float sizeOfTurnedPart = ([self isDirectionIsHorizontal:direction] ? width * 0.5 * cos(value) : height * 0.5 * cos(value));
    
    //  Calc initial offset for first part based on angle
    if(direction == FoldDirectionLeft)
        offset = width * bendsCount - sizeOfTurnedPart;
    else if(direction == FoldDirectionRight)
        offset = sizeOfTurnedPart;
    else if(direction == FoldDirectionDown)
        offset = sizeOfTurnedPart;
    else if(direction == FoldDirectionUp)
        offset = height * bendsCount - sizeOfTurnedPart;
    
    
    //  Split image to 4 view
    while((i < bendsCount && (direction == FoldDirectionRight || direction == FoldDirectionDown)) || /*    step from 0 to 3 for right and up folding*/
          (i >= 0 && (direction == FoldDirectionLeft || direction == FoldDirectionUp)))     /*downstep from 3 to 0 for left and down folding*/
    {
        //  Working layers
        UIView *part = [self viewWithTag:(tag+i)];//Part
        CALayer *shadowLayer = [part.layer.sublayers objectAtIndex:0];//Shadow overlay on this part
        
        
        //  Direction of rotating (alternation, or "cheredovanie")
        if(direction == FoldDirectionDown || direction == FoldDirectionUp)
            dir = (i % 2 == 0 ? -1 : 1);
        else if(direction == FoldDirectionLeft || direction == FoldDirectionRight)
            dir = (i % 2 == 0 ? 1 : -1);
        
        //  Calc rotating transform
        CATransform3D newTrans;
        if(direction == FoldDirectionLeft || direction == FoldDirectionRight)
            newTrans = CATransform3DRotate(trans, value * dir, 0, 1, 0);
        else if(direction == FoldDirectionDown || direction == FoldDirectionUp)
            newTrans = CATransform3DRotate(trans, value * dir, 1, 0, 0);
        
        //  Calc new position
        CGPoint newPosition;
        if(direction == FoldDirectionLeft || direction == FoldDirectionRight)
            newPosition = CGPointMake(offset, part.layer.position.y);
        else if(direction == FoldDirectionDown || direction == FoldDirectionUp)
            newPosition = CGPointMake(part.layer.position.x, offset);
        
        //  Animate if needed
        if(animated)
        {
            //  Create animations
            
            CABasicAnimation *animRot = [CABasicAnimation animationWithKeyPath:@"transform"];
            animRot.fromValue = [NSValue valueWithCATransform3D:part.layer.transform];
            animRot.toValue = [NSValue valueWithCATransform3D:newTrans];
            animRot.duration = kAnimationDuration;
            animRot.removedOnCompletion = YES;
            animRot.fillMode = kCAFillModeBoth;
            
            CABasicAnimation *animPos = [CABasicAnimation animationWithKeyPath:@"position"];
            animPos.fromValue = [NSValue valueWithCGPoint:part.layer.position];
            animPos.toValue = [NSValue valueWithCGPoint:newPosition];
            animPos.duration = kAnimationDuration;
            animPos.removedOnCompletion = YES;
            animPos.fillMode = kCAFillModeBoth;
            
            CAAnimationGroup *group = [[CAAnimationGroup animation] retain];
            group.duration = kAnimationDuration;
            group.removedOnCompletion = YES;
            group.animations = [NSArray arrayWithObjects:animPos, animRot, nil];
            group.fillMode = kCAFillModeBoth;
            
            
            CABasicAnimation *animOpa = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animOpa.fromValue = [NSNumber numberWithFloat:shadowLayer.opacity];
            animOpa.toValue = [NSNumber numberWithFloat:(value * dir * 0.5)];
            animOpa.duration = kAnimationDuration;
            animOpa.removedOnCompletion = YES;
            animOpa.fillMode = kCAFillModeBoth;
            
            
            //  Apply animations
            
            [group setDelegate:self];
            
            [part.layer addAnimation:group forKey:nil];
            [shadowLayer addAnimation:animOpa forKey:nil];
        }
        
        
        //  Apply changes
        part.layer.transform = newTrans;
        part.layer.position = newPosition;
        shadowLayer.opacity = value * dir * 0.5;
        
        offset += sizeOfTurnedPart * 2 * (direction == FoldDirectionRight || direction == FoldDirectionDown ? 1.0 : -1.0);
        
        //  Step from 0 to 3 for rigth and up, downstep from 3 to 0 for left and down
        i += (direction == FoldDirectionRight || direction == FoldDirectionDown ? 1 : -1);
    }
    
    
    //Apply final transform with perspective
    trans = CATransform3DIdentity;
	trans.m34 = 1.0f / kPerspective;
	[self.layer setSublayerTransform:trans];
    
    
    if(animated)
        self.completion = _completion;
    else
        _completion();
}

- (BOOL)isPointNearEdges: (CGPoint)point
{
    //  Check if user taps near corner to allow him fold
    
    BOOL inTheMiddleOfX = point.x > 0.3 * self.bounds.size.width && point.x < 0.7 * self.bounds.size.width;
    BOOL inTheMiddleOfY = point.y > 0.3 * self.bounds.size.height && point.y < 0.7 * self.bounds.size.height;
    BOOL outsideView = !CGRectContainsPoint(self.bounds, point);
    
    if((inTheMiddleOfX && inTheMiddleOfY) || outsideView)
        return NO;
    else
        return YES;
}

- (FoldDirection)edgeByPoint: (CGPoint)point
{
    if(point.x < 0.3 * self.bounds.size.width)
        return FoldDirectionLeft;
    else if(point.x > 0.7 * self.bounds.size.width)
        return FoldDirectionRight;
    else if(point.y < 0.3 * self.bounds.size.height)
        return FoldDirectionUp;
    else if(point.y > 0.7 * self.bounds.size.height)
        return FoldDirectionDown;
    else
        return FoldDirectionNone; //  Undefined situation, let's skip folding ability
}

- (FoldDirection)directionOfFoldingByPoint: (CGPoint)point andPoint: (CGPoint)previousPoint
{
    //  We need some distance to definitely say, where user want fold
    float distance = CGPointDistance(point, previousPoint);
    if(distance > 0.03 * MIN(self.bounds.size.width, self.bounds.size.height))
    {
        int horizontalDirection = point.x - previousPoint.x;
        int verticalDirection = point.y - previousPoint.y;
        
        if(abs(horizontalDirection) > abs(verticalDirection))
        {
            //  Let's see only horizontal directions
            
            if(horizontalDirection < 0 && maybeActiveDirection == FoldDirectionRight)
                return FoldDirectionRight;
            else if(horizontalDirection > 0 && maybeActiveDirection == FoldDirectionLeft)
                return FoldDirectionLeft;
        }
        else
        {
            //  Let's see only vertical directions
            
            if(verticalDirection < 0 && maybeActiveDirection == FoldDirectionDown)
                return FoldDirectionDown;
            else if(verticalDirection > 0 && maybeActiveDirection == FoldDirectionUp)
                return FoldDirectionUp;
        }
    }
    return FoldDirectionNone;
}

- (float)offsetFromEdge: (CGPoint)point direction: (FoldDirection)foldDirection
{
    float value = 0;
    if(foldDirection == FoldDirectionRight)
        value =  MAX(self.bounds.size.width - point.x, 0);
    else if(foldDirection == FoldDirectionLeft)
        value =  MAX(point.x, 0);
    else if(foldDirection == FoldDirectionUp)
        value =  MAX(point.y, 0);
    else if(foldDirection == FoldDirectionDown)
        value =  MAX(self.bounds.size.height - point.y, 0);
    return value;
}

- (CGRect)boundsForView
{
    CGRect frame;
    if(activeDirection == FoldDirectionRight)
        frame =  CGRectMake(0, 0, currentWidth, self.bounds.size.height);
    else if(activeDirection == FoldDirectionLeft)
        frame =  CGRectMake(self.bounds.size.width - currentWidth, 0, currentWidth, self.bounds.size.height);
    else if(activeDirection == FoldDirectionDown)
        frame =  CGRectMake(0, 0, self.bounds.size.width, currentWidth);
    else if(activeDirection == FoldDirectionUp)
        frame =  CGRectMake(0, self.bounds.size.height - currentWidth, self.bounds.size.width, currentWidth);
    else
        frame = self.bounds;
    
    return frame;
}

- (float)angleForOffset: (float)offset
{
    float size = [self isDirectionIsHorizontal:activeDirection] ? self.bounds.size.width : self.bounds.size.height;
    float progress = (size - offset) / size;
    float angle = acosf(MAX(MIN(progress, 1.0f), 0.0f));
    
    return angle;
}

#pragma mark - CAAnimationDelegate Methods

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if(flag && completion)
    {
        completion();
        self.completion = nil;
    }
}

#pragma mark - User Interaction

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *firstTouch = [touches anyObject];
    firstTouchLocation = [firstTouch locationInView:self];
    
    maybeActiveDirection = FoldDirectionNone;
    
    if(isOpen)
    {
        shouldFolding = CGRectContainsPoint([self boundsForView], firstTouchLocation);
    }
    else
    {
        shouldFolding = [self isPointNearEdges:firstTouchLocation];
        if(shouldFolding)
            maybeActiveDirection = [self edgeByPoint:firstTouchLocation];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(shouldFolding)
    {
        UITouch *secondTouch = [touches anyObject];
        CGPoint secondTouchLocation = [secondTouch locationInView:self];
        
        if(activeDirection == FoldDirectionNone)
        {
            //  Detect active folding direction
            
            activeDirection = [self directionOfFoldingByPoint:secondTouchLocation andPoint:firstTouchLocation];
            
            
            if(![self isDirectionSupported:maybeActiveDirection])
            {
                shouldFolding = NO;
                activeDirection = FoldDirectionNone;
                maybeActiveDirection = activeDirection;
            }
        }
        else
        {
            
            //  Fold view if it allowed by offset
            
            currentWidth = [self offsetFromEdge:secondTouchLocation direction:activeDirection];
            if(currentWidth < openOffset)
                [self foldWithAngle:[self angleForOffset:currentWidth] direction:activeDirection animated:NO completion:^{}];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(shouldFolding)
    {
        UITouch *lastTouch = [touches anyObject];
        CGPoint lastTouchLocation = [lastTouch locationInView:self];
        
        currentWidth = [self offsetFromEdge:lastTouchLocation direction:activeDirection];
        if(currentWidth < openOffset * 0.5)
        {
            //  Close
            
            [self foldWithAngle:0 direction:activeDirection animated:YES completion:^{}];
            currentWidth = ([self isDirectionIsHorizontal:activeDirection] ? self.bounds.size.width : self.bounds.size.height);
            
            isOpen = NO;
        }
        else
        {
            //  Open
            
            [self foldWithAngle:[self angleForOffset:openOffset] direction:activeDirection animated:YES completion:^{}];
            currentWidth = ([self isDirectionIsHorizontal:activeDirection] ? self.frame.size.width : self.frame.size.height) - openOffset;
            
            isOpen = YES;
        }
    }
    
    shouldFolding = NO;
    
    if(!isOpen)
    {
        shouldFolding = NO;
        activeDirection = FoldDirectionNone;
        maybeActiveDirection = activeDirection;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL yes = CGRectContainsPoint([self boundsForView], point);
    return yes;
}

#pragma mark - Private Utility Methods

//  I decided to move cropping method from UIImage category to this class to make this class self-contained without any dependencies besides QuartzCore-framework.
- (UIImage *)crop: (UIImage *)source rect: (CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, isRetina ? 2.0 : 1.0);
    [source drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)];
    
    UIImage *_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return _image;
}

@end
