//
//  EGPagedScrollView.m
//  EGPagedScrollView
//
//  Created by Egist Li on 13/5/24.
//  Copyright (c) 2013年 Egist Li. All rights reserved.
//

#import "EGPagedScrollView.h"

@interface EGPagedScrollView() <UIScrollViewDelegate>

@property NSMutableSet *dequeuedPages;
@property NSMutableSet *visiblePages;
@property (assign) NSUInteger totalPages;
@property (assign) NSUInteger focusPageNum;

@end

@implementation EGPagedScrollView

#pragma mark - Life Cycle
- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        self.focusPageNum = self.totalPages = 0;
        
        // base scrollview setting
        self.masterScrollView = [[UIScrollView alloc] init];
        self.masterScrollView.frame = self.bounds;
        self.masterScrollView.backgroundColor = [UIColor clearColor];
        self.masterScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.masterScrollView.pagingEnabled = YES;
        self.masterScrollView.delegate = self;
        
        [self addSubview: self.masterScrollView];
        
        // give some views to dequeuedPages
        self.visiblePages = [NSMutableSet setWithCapacity:2];
        self.dequeuedPages = [NSMutableSet setWithCapacity:2];
    }

    return self;
}

- (void) layoutSubviews {
    [self updateMasterFrame];
    [self updateMasterContentSize];
    
    for (UIScrollView *v in self.visiblePages) {
        [v setZoomScale:1.f animated:YES];
        [self configureViewFrame:v forIndex:v.tag];
    }
    [self showPageAtIndex:self.focusPageNum animated:NO];
}

#pragma mark - Setter for delegate and datasource

- (void) setDataSource:(id<EGPagedScrollViewDataSource>)dataSource {
    _dataSource = dataSource;
    if (self.superview) {
        [self reload];
    }
}

- (void) setDelegate:(id<EGPagedScrollViewDelegate>)delegate {
    _delegate = delegate;
    if (self.superview && self.dataSource) {
        [self reload];
    }
}

- (void) didMoveToSuperview {
    [self reload];
}

#pragma mark - Handling pages

- (void) updateMasterFrame {
    CGRect frame = self.bounds;
    frame.origin.x -= [self pagePadding];
    frame.size.width += [self pagePadding] * 2;
    self.masterScrollView.frame = frame;
}

- (void) updateMasterContentSize {
    self.masterScrollView.contentSize = CGSizeMake(self.totalPages * [self pageWidth], self.bounds.size.height);
}

- (void) updateFocusPageNumFromOffset {
    NSUInteger newPageNum = self.masterScrollView.contentOffset.x / [self pageWidth];
    
    if (newPageNum != self.focusPageNum) {
        // reset previous page's zoom scale
        for (UIScrollView *v in self.visiblePages) {
            if (v.tag == self.focusPageNum) {
                [v setZoomScale:1.f animated:NO];
                break;
            }
        }
        
        self.focusPageNum = newPageNum;
        
        if ([self.delegate respondsToSelector:@selector(pagedScrollView:didFocusToPage:)]) {
            [self.delegate pagedScrollView:self didFocusToPage:self.focusPageNum];
        }
    }
}

- (void) reload {
    self.totalPages = [self.dataSource numberOfItemsInPagedScrollView:self];
    [self updateMasterContentSize];
    [self preparePageAtIndex:self.focusPageNum];
}

- (void) showPageAtIndex: (NSUInteger) index animated: (BOOL) animated {
    [self.masterScrollView setContentOffset: CGPointMake([self pageWidth] * index, 0) animated:animated];
}

- (void) preparePageAtIndex: (NSUInteger) index {
    if (self.totalPages == 0) {
        return;
    }
    
    UIScrollView *page = [self.dequeuedPages anyObject];
    if (page == nil) {
        page = [[UIScrollView alloc] init];
        page.delegate = self;
        page.minimumZoomScale = 1.f;
        page.maximumZoomScale = 3.f;
    } else {
        [self.dequeuedPages removeObject: page];
    }
    
    [self configureViewFrame: page forIndex:index];
    [self.masterScrollView addSubview: page];
    [self.visiblePages addObject:page];
    
    UIView *view = [self.dataSource pagedScrollView:self viewForPageAtIndex:index];
    if (view.superview != page) {
        [view removeFromSuperview];
        [page.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [(UIView *)obj removeFromSuperview];
        }];
    }
    
    view.frame = page.bounds;
    [page addSubview:view];
}

- (void) configureViewFrame: (UIScrollView *)scrollView forIndex: (NSUInteger)index {
    scrollView.tag = index;
    scrollView.frame = CGRectMake([self pageWidth] * index + [self pagePadding],
                                  0,
                                  [self innerPageWidth],
                                  [self pageHeight]);
    scrollView.contentSize = scrollView.frame.size;
}

#pragma mark - Asking delegate for properties

- (CGFloat) pagePadding {
    CGFloat padding = 0.f;
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagePaddingOfPagedScrollView:)]) {
        padding = [self.delegate pagePaddingOfPagedScrollView:self];
    }
    return padding;
}

- (CGFloat) innerPageWidth {
    return self.bounds.size.width;
}

// page width includes padding
- (CGFloat) pageWidth {
    return self.bounds.size.width + 2 * [self pagePadding];
}

- (CGFloat) pageHeight {
    CGFloat pageHeight = self.bounds.size.height;
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageHeightOfPagedScrollingView:)]) {
        pageHeight = [self.delegate pageHeightOfPagedScrollView:self];
    }
    return pageHeight;
}

- (BOOL) isDisplayingPageWithIndex: (NSUInteger) index {
    for (UIScrollView *v in self.visiblePages) {
        if (v.tag == index) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - master scrollview delegate
- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView == self.masterScrollView) { return nil; }
    UIView *view = nil;
    if (self.enableZooming && scrollView.subviews.count > 0) {
        view = [[scrollView subviews] objectAtIndex:0];
    }
    return view;
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    if (scrollView == self.masterScrollView) { return; }
    // doing nothing here.
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.masterScrollView) { return; }
    
    [self updateFocusPageNumFromOffset];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.masterScrollView) { return; }
    
    CGFloat pageWidth = [self pageWidth];
    NSInteger firstShowingPageIndex = (int)floor((CGRectGetMinX(scrollView.bounds) - 1.f) / pageWidth);
    firstShowingPageIndex = MAX(0, firstShowingPageIndex);
    NSUInteger lastShowingPageIndex = (int)ceil(CGRectGetMaxX(scrollView.bounds) / pageWidth);
    lastShowingPageIndex = MIN(lastShowingPageIndex, self.totalPages);
    
    for (UIScrollView *v in self.visiblePages) {
        if (v.tag < firstShowingPageIndex || v.tag > lastShowingPageIndex) {
            [v removeFromSuperview];
            [self.dequeuedPages addObject:v];
        }
    }
    [self.visiblePages minusSet: self.dequeuedPages];
    
    for (int i = firstShowingPageIndex; i <= lastShowingPageIndex; i++) {
        // prepare pages
        if ([self isDisplayingPageWithIndex:i]) {
            continue;
        }
        [self preparePageAtIndex:i];
    }
}


@end
