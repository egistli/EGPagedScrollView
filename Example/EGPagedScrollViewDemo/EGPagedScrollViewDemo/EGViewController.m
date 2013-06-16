//
//  EGViewController.m
//  EGPagedScrollViewDemo
//
//  Created by Egist Li on 13/5/24.
//  Copyright (c) 2013年 Egist Li. All rights reserved.
//

#import "EGViewController.h"

#define ARC4RANDOM_MAX 0x100000000

@interface EGViewController()

@property NSMutableArray *items;
@property NSMutableArray *viewCaches;
@property NSMutableDictionary *imageCaches;
@property EGPagedScrollView *pagedScrollView;

@end

@implementation EGViewController

- (id) init {
    self = [super init];
    if (self) {
        self.items = [[NSMutableArray alloc] initWithCapacity:10];
        self.imageCaches = [[NSMutableDictionary alloc] initWithCapacity:10];
        self.viewCaches = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor whiteColor];

    CGRect smallerBound = self.view.bounds;
    smallerBound.size.width = smallerBound.size.width * 0.6;
    smallerBound.size.height = smallerBound.size.height * 0.6;
    
    self.pagedScrollView = [[EGPagedScrollView alloc] initWithFrame: smallerBound];
    [self.pagedScrollView setDelegate:self];
    [self.pagedScrollView setDataSource:self];
    self.pagedScrollView.enableZooming = NO;
    
    self.pagedScrollView.center = self.view.center;
    
    [self.view addSubview: self.pagedScrollView];
    
    [self updateItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data Handling

- (void) updateItems {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        static NSString *flickrAPIPoint = @"http://api.flickr.com/services/feeds/photos_public.gne?format=json&nojsoncallback=1";

        NSError* error = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData: [NSData dataWithContentsOfURL:[NSURL URLWithString:flickrAPIPoint]] options:NSJSONReadingAllowFragments error:&error];
        
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.items = [response objectForKey:@"items"];
                [self.pagedScrollView reload];
            });
        } else {
            NSLog(@"error occurred when fetching flickr photos: %@", error);
        }
    });


}

#pragma mark - EGpagedScrollView Delegate

- (CGFloat) pagePaddingOfPagedScrollView:(EGPagedScrollView *)pagedScrollView {
    return 10.f;
}

#pragma mark - EGPagedScrollView DataSource
- (NSUInteger) numberOfItemsInPagedScrollView: (EGPagedScrollView *)pagedScrollView {
    return self.items.count;
}

- (UIView *) pagedScrollView:(EGPagedScrollView *)pagedScrollView viewForPageAtIndex:(NSUInteger)index {
    UIView *view = nil;

    if (self.viewCaches.count > index) {
        view = [self.viewCaches objectAtIndex:index];
    } else {
        view = [[UIView alloc] init];
        view.frame = pagedScrollView.bounds;
        view.backgroundColor = [UIColor colorWithRed:((double)arc4random() / ARC4RANDOM_MAX) green:((double)arc4random() / ARC4RANDOM_MAX) blue:((double)arc4random() / ARC4RANDOM_MAX) alpha:1];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.frame];
        imageView.tag = 999;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [view addSubview:imageView];
        
        UILabel *noLabel = [[UILabel alloc] init];
        noLabel.frame = CGRectMake(0.f, pagedScrollView.bounds.size.height - 32.f, pagedScrollView.bounds.size.width, 32.f);
        noLabel.tag = 998;
        noLabel.textAlignment = NSTextAlignmentCenter;
        noLabel.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.8];
        noLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        
        [view addSubview:noLabel];
    }
    
    NSDictionary *info = nil;
    if (self.items.count > index)  {
        info = [self.items objectAtIndex:index];
        NSURL *url = [NSURL URLWithString: [[info objectForKey:@"media"] objectForKey:@"m"]];
        NSString *title = [info objectForKey:@"title"];
        [(UILabel *)[view viewWithTag:998] setText: title];
        
        // check image
        UIImage *image = [self.imageCaches objectForKey:url];
        if ([(UIImageView *)[view viewWithTag:999] image] != image) {
            [(UIImageView *)[view viewWithTag:999] setImage: image];
        }  else {
            // view == nil
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:url];
                UIImage *image = [UIImage imageWithData:data];
                // cahe
                [self.imageCaches setObject:image forKey:url];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // try update the imabe view
                    if ([pagedScrollView isDisplayingPageWithIndex:index]) {
                        [(UIImageView *)[[self pagedScrollView:pagedScrollView viewForPageAtIndex:index] viewWithTag:999] setImage:image];
                    }
                });
            });
            
            [self.viewCaches setObject:view atIndexedSubscript:index];
        }
    }
    
    return view;
}



@end
