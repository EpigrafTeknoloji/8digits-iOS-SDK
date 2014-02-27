//
//  EDView.m
//  8DigitsExample
//
//  Created by skizilkaya on 27.02.2014.
//  Copyright (c) 2014 skizilkaya. All rights reserved.
//

#import "EDView.h"
#import "EDNotification.h"
#import "ED_ARC.h"
#import <QuartzCore/QuartzCore.h>

#define MainWindow [[[UIApplication sharedApplication] windows] objectAtIndex:0]

@interface EDView ()


@property (nonatomic, strong) UIActivityIndicatorView   * loader;
@property (nonatomic, strong) UIImageView               * imageView;
@property (nonatomic, strong) EDNotification            * notification;
@property (nonatomic, strong) UILabel                   * titleLabel;
@property (nonatomic, strong) UILabel                   * detailsLabel;
@end

@implementation EDView

- (id)initWithNotification:(EDNotification *) notification {
    self = [super initWithFrame:[MainWindow bounds]];
    if (self) {
        self.alpha              = .0f;
        self.notification       = notification;
        
        CAGradientLayer *bgLayer = [self blueGradient];
        bgLayer.frame = self.bounds;
        [self.layer insertSublayer:bgLayer atIndex:0];
        
        [self buildUI];
    }
    return self;
}

- (void) buildUI {
    CGRect mainFrame        = [MainWindow frame];
    NSInteger padding       = 0;
    
    if (mainFrame.size.height == 568) {
        padding = 20;
    }
    
    //Close Button
    UIButton * closeButton  = [UIButton buttonWithType:UIButtonTypeCustom];

    closeButton.frame       = CGRectMake(mainFrame.size.width - 60, 22, 47, 42);
    
    [closeButton setImage:[UIImage imageNamed:@"EDCloseButton.png"]
                 forState:UIControlStateNormal];
    
    [closeButton addTarget:self
                    action:@selector(hide)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:closeButton];
    
    
    self.imageView          = [[UIImageView alloc] initWithFrame:CGRectMake(30,
                                                                           closeButton.frame.origin.y + 60,
                                                                           260, 260)];
    self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.imageView.layer.borderWidth    = 1;
    [self addSubview:self.imageView];
    
    
    self.loader             = [[UIActivityIndicatorView alloc]
                               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.loader startAnimating];
    [self.loader setHidesWhenStopped:YES];
    [self.loader setCenter:self.imageView.center];
    [self addSubview:self.loader];
    
    
    self.titleLabel         = [[UILabel alloc] initWithFrame:CGRectMake(20,
                                                                        self.imageView.frame.origin.y +
                                                                        self.imageView.frame.size.height + padding,
                                                                        280, 40)];
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.titleLabel setTextColor:[UIColor whiteColor]];
    [self.titleLabel setText:self.notification.title];
    
    [self addSubview:self.titleLabel];
    
    
    self.detailsLabel       = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
    [self.detailsLabel setNumberOfLines:0];
    [self.detailsLabel setFont:[UIFont systemFontOfSize:14]];
    [self.detailsLabel setTextColor:[UIColor whiteColor]];
    [self.detailsLabel setText:self.notification.details];
    [self addSubview:self.detailsLabel];
    [self.detailsLabel sizeToFit];
    [self.detailsLabel setFrame:CGRectMake(10,
                                          self.titleLabel.frame.origin.y +
                                          self.titleLabel.frame.size.height - 4 + padding/2,
                                           300, self.detailsLabel.frame.size.height)];
    
    [self.detailsLabel setTextAlignment:NSTextAlignmentCenter];
    
    
    UIButton * actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame      = CGRectMake(0, 0, 100, 34);
    [actionButton setCenter:self.detailsLabel.center];
    [actionButton setCenter:CGPointMake(actionButton.center.x,
                                        self.detailsLabel.frame.origin.y + self.detailsLabel.frame.size.height + 25 + padding)];
    [actionButton addTarget:self
                     action:@selector(hide)
           forControlEvents:UIControlEventTouchUpInside];
    [actionButton setTitle:self.notification.buttonText
                  forState:UIControlStateNormal];
    [actionButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    [actionButton.layer setBorderWidth:1];
    [self addSubview:actionButton];
    
    [self downloadImage];

}

- (void) show {
    if (self.frame.size.width > 320) {
        return;
    }
    [[[UIApplication sharedApplication].delegate window] addSubview:self];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [self setAlpha:1];
    [UIView commitAnimations];
}

- (void) hide {
    [UIView animateWithDuration:0.5
     
                     animations:^ {
                         [self setAlpha:0];
                         
                     } completion: ^ (BOOL finished) {
                         [super removeFromSuperview];
                     }];
}

- (void) downloadImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData  * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.notification.imageURL]];
        UIImage * image = [[UIImage alloc] initWithData:imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.imageView setImage:image];
            [self.loader stopAnimating];
        });
    });

}

- (CAGradientLayer*) blueGradient {
    
    UIColor *colorOne = [UIColor colorWithRed:(120/255.0) green:(135/255.0) blue:(150/255.0) alpha:1.0];
    UIColor *colorTwo = [UIColor colorWithRed:(57/255.0)  green:(79/255.0)  blue:(96/255.0)  alpha:1.0];
    
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, nil];
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
    NSNumber *stopTwo = [NSNumber numberWithFloat:1.0];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
    
}

- (void) dealloc {
    
    ED_ARC_RELEASE(self.imageView);
    self.imageView    = nil;
    
    ED_ARC_RELEASE(self.titleLabel);
    self.titleLabel   = nil;
    
    ED_ARC_RELEASE(self.detailsLabel);
    self.detailsLabel = nil;
    
    ED_ARC_RELEASE(self.notification);
    self.notification = nil;
}

@end
