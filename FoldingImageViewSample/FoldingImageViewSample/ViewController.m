//
//  ViewController.m
//  FoldingImageViewSample
//
//  Created by Jim Korbin on 4/19/13.
//  Copyright (c) 2013 DarkKor. All rights reserved.
//

#import "ViewController.h"
#import "FoldingImageView.h"
#import "UIImage+Cropping.h"

#define kFoldingViewRect CGRectMake(32, 32, 256, 256)
#define kTagForFoldingView 105

typedef enum
{
    DemoActionQuickChange = 0,
    DemoActionTakePhoto,
    DemoActionTakePicture,
    DemoActionIncreaseOffset,
    DemoActionDecreaseOffset,
    DemoActionOpen,
    DemoActionClose
}
DemoAction;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSArray *titles = @[@"Quick change picture", @"Take photo", @"Take picture", @"Increase offset by 10px", @"Decrease offset by 10px"];
    NSInteger tags[] = {DemoActionQuickChange, DemoActionTakePhoto, DemoActionTakePicture, DemoActionIncreaseOffset, DemoActionDecreaseOffset};
    for(int i = 0; i < titles.count; i++)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.frame = CGRectMake(kFoldingViewRect.origin.x, kFoldingViewRect.origin.y + kFoldingViewRect.size.height * i / titles.count, kFoldingViewRect.size.width, kFoldingViewRect.size.height / titles.count);
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnOptions_Tapped:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = tags[i];
        [self.view addSubview:btn];
    }
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(kFoldingViewRect.origin.x, CGRectGetMaxY(kFoldingViewRect), kFoldingViewRect.size.width * 0.5, kFoldingViewRect.size.height / titles.count);
    [btn setTitle:@"Open" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnOptions_Tapped:) forControlEvents:UIControlEventTouchUpInside];
    btn.tag = DemoActionOpen;
    [self.view addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(kFoldingViewRect.origin.x + kFoldingViewRect.size.width * 0.5, CGRectGetMaxY(kFoldingViewRect), kFoldingViewRect.size.width * 0.5, kFoldingViewRect.size.height / titles.count);
    [btn setTitle:@"Close" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnOptions_Tapped:) forControlEvents:UIControlEventTouchUpInside];
    btn.tag = DemoActionClose;
    [self.view addSubview:btn];
    
    
    
    FoldingImageView *foldingView = [[[FoldingImageView alloc] initWithImage:[UIImage imageNamed:@"1.jpg"] frame:kFoldingViewRect bends:4] autorelease];
    foldingView.tag = kTagForFoldingView;
    [self.view addSubview:foldingView];
    
    
    
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(160, 380, 160, 37)];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.text = @"Hidden text";
    lbl.backgroundColor = [UIColor clearColor];
    [self.view addSubview:lbl];
    
    FoldingImageView *bottomFoldingView = [[[FoldingImageView alloc] initWithImage:[UIImage imageNamed:@"3.jpg"]
                                                                             frame:CGRectMake(0, 360, 320, 100)
                                                                             bends:6] autorelease];
    bottomFoldingView.supportedDirections = @[[NSNumber numberWithInt:FoldDirectionRight]];
    [self.view addSubview:bottomFoldingView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnOptions_Tapped:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case DemoActionQuickChange:
            [self quickChangePicture];
            break;
            
        case DemoActionTakePhoto:
            [self takePhoto];
            break;
            
        case DemoActionTakePicture:
            [self takePicture];
            break;
            
        case DemoActionIncreaseOffset:
            [self increaseOffset];
            break;
            
        case DemoActionDecreaseOffset:
            [self decreaseOffset];
            break;
            
        case DemoActionOpen:
            [self open];
            break;
            
        case DemoActionClose:
            [self close];
            break;
            
        default:
            break;
    }
}

#pragma mark - Demo Methods

- (void)quickChangePicture
{
    FoldingImageView *foldingView = (FoldingImageView *)[self.view viewWithTag:kTagForFoldingView];
    
    UIImage *img = [UIImage imageNamed:@"2.jpg"];
    if(foldingView.image == img)
        img = [UIImage imageNamed:@"1.jpg"];
    foldingView.image = img;
}

- (void)takePhoto
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *cameraPicker = [[[UIImagePickerController alloc] init] autorelease];
        cameraPicker.delegate = self;
        cameraPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:cameraPicker animated:YES completion:^{}];
    }
}

- (void)takePicture
{
    UIImagePickerController *cameraPicker = [[[UIImagePickerController alloc] init] autorelease];
    cameraPicker.delegate = self;
    cameraPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:cameraPicker animated:YES completion:^{}];
}

- (void)increaseOffset
{
    FoldingImageView *foldingView = (FoldingImageView *)[self.view viewWithTag:kTagForFoldingView];
    foldingView.openOffset = foldingView.openOffset - 10;
}

- (void)decreaseOffset
{
    FoldingImageView *foldingView = (FoldingImageView *)[self.view viewWithTag:kTagForFoldingView];
    foldingView.openOffset = foldingView.openOffset + 10;
}

- (void)open
{
    FoldingImageView *foldingView = (FoldingImageView *)[self.view viewWithTag:kTagForFoldingView];
    [foldingView openToOffset:foldingView.openOffset direction:arc4random() % FoldDirectionNone completion:^{}];
}

- (void)close
{
    FoldingImageView *foldingView = (FoldingImageView *)[self.view viewWithTag:kTagForFoldingView];
    [foldingView closeWithCompletion:^{}];
}

#pragma mark - UIImagePickerController Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *img = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage *cropped = [img cropWithRect:CGRectMake((img.size.width - kFoldingViewRect.size.width) * 0.5, (img.size.height - kFoldingViewRect.size.height) * 0.5, kFoldingViewRect.size.width, kFoldingViewRect.size.height)];
    
    FoldingImageView *foldingView = (FoldingImageView *)[self.view viewWithTag:kTagForFoldingView];
    [foldingView setImage:cropped];
    
    [picker dismissModalViewControllerAnimated:YES];
}

@end
