//
//  EGPagedScrollView.h
//  EGPagedScrollView
//
//  Created by Egist Li on 13/5/24.
//  Copyright (c) 2013年 Egist Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class EGPagedScrollView;

@protocol EGPagedScrollViewDataSource <NSObject>
@required
- (NSUInteger) numberOfItemsInPagedScrollView: (EGPagedScrollView *)pagedScrollViewController;
- (UIView *) pagedScrollView: (EGPagedScrollView *)pagedScrollView viewForPageAtIndex: (NSUInteger) index;

@end

@protocol EGPagedScrollViewDelegate <NSObject>

@optional
- (CGFloat) pagePaddingOfPagedScrollView: (EGPagedScrollView *)pagedScrollView;
- (CGFloat) pageHeightOfPagedScrollView: (EGPagedScrollView *)pagedScrollView;

- (void) pagedScrollView: (EGPagedScrollView *)scrollView didFocusToPage: (NSUInteger) pageIndex;
@end

@interface EGPagedScrollView : UIView

@property UIScrollView *masterScrollView;
@property (nonatomic, assign) id<EGPagedScrollViewDataSource> dataSource;
@property (nonatomic, assign) id<EGPagedScrollViewDelegate> delegate;
@property BOOL enableZooming;

- (void) reload;
- (void) showPageAtIndex: (NSUInteger) index animated: (BOOL) animated;
- (BOOL) isDisplayingPageWithIndex: (NSUInteger) index;

- (void) setDataSource:(id<EGPagedScrollViewDataSource>)dataSource;
- (void) setDelegate:(id<EGPagedScrollViewDelegate>)delegate;

@end