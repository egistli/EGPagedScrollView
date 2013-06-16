//
//  EGViewController.m
//  EGPagedScrollViewDemo
//
//  Created by Egist Li on 13/5/24.
//  Copyright (c) 2013年 Egist Li. All rights reserved.
//

#import "EGViewController.h"

@interface EGViewController()

@property NSMutableArray *items;
@property NSMutableArray *viewCaches;
@property NSMutableDictionary *imageCaches;
@property EGPagedScrollView *pagedScrollView;
@property UILabel *titleLabel;

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
    self.view.backgroundColor = [UIColor blackColor];
    
    self.pagedScrollView = [[EGPagedScrollView alloc] initWithFrame: self.view.bounds];
    self.pagedScrollView.delegate = self;
    self.pagedScrollView.dataSource = self;
    self.pagedScrollView.enableZooming = YES;
    self.pagedScrollView.masterScrollView.showsHorizontalScrollIndicator = NO;
    self.pagedScrollView.masterScrollView.showsVerticalScrollIndicator = NO;
    
    [self.view addSubview: self.pagedScrollView];
    
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.frame = CGRectMake(0.f, self.pagedScrollView.bounds.size.height - 32.f, self.pagedScrollView.bounds.size.width, 32.f);
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor lightGrayColor];
    self.titleLabel.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.2];
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview: self.titleLabel];
    
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
        NSString *raw = [[NSString alloc] initWithData: [NSData dataWithContentsOfURL:[NSURL URLWithString:flickrAPIPoint]] encoding:NSUTF8StringEncoding];
        raw = [raw stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];

        NSError* error = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData: [raw dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
        
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

- (void) pagedScrollView: (EGPagedScrollView *)scrollView didFocusToPage: (NSUInteger) pageIndex; {
    NSDictionary *info = [self.items objectAtIndex:pageIndex];
    if (info) {
        NSString *title = [info objectForKey:@"title"];
        self.titleLabel.text = title;
    }
}

- (CGFloat) pagePaddingOfPagedScrollView:(EGPagedScrollView *)pagedScrollView {
    return 10.f;
}

#pragma mark - EGPagedScrollView DataSource
- (NSUInteger) numberOfItemsInPagedScrollView: (EGPagedScrollView *)pagedScrollView {
    return self.items.count;
}

- (UIView *) pagedScrollView:(EGPagedScrollView *)pagedScrollView viewForPageAtIndex:(NSUInteger)index {
    UIImageView *view = nil;

    if (self.viewCaches.count > index) {
        view = [self.viewCaches objectAtIndex:index];
    } else {
        view = [[UIImageView alloc] initWithFrame:view.frame];
        view.contentMode = UIViewContentModeScaleAspectFit;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    NSDictionary *info = nil;
    if (self.items.count > index)  {
        info = [self.items objectAtIndex:index];
        NSURL *url = [NSURL URLWithString: [[info objectForKey:@"media"] objectForKey:@"m"]];

        
        // check image
        UIImage *image = [self.imageCaches objectForKey:url];
        if (image != nil) {
            [view setImage: image];
        }  else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:url];
                UIImage *image = [UIImage imageWithData:data];
                // cahe
                [self.imageCaches setObject:image forKey:url];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // try update the imabe view
                    if ([pagedScrollView isDisplayingPageWithIndex:index]) {
                        [(UIImageView *)[self pagedScrollView:pagedScrollView viewForPageAtIndex:index] setImage:image];
                    }
                });
            });
            
            [self.viewCaches setObject:view atIndexedSubscript:index];
        }
    }
    
    return view;
}



@end
