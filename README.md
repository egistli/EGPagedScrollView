## EGPagedScrollView ##
It's a wrapped UIScrollView with delegate on itself which

1. adjusts subviews' frame accordingly when rotated
2. Reuse subviews so that we don't have to hold all subviews all the time

### Getting Start ###

First, add files under "EGPagedScrollView" to your project and include "EGPagedScrollView.h".

Then create an instance of EGPagedScrollView, add it to your view and set the delegate which should comforms to EGPagedScrollViewDelegate.

```
EGPagedScrollView *pagedScrollView = [[EGPagedScrollView alloc] initWithFrame: self.view.bounds]];
pagedScrollView.delegate = self;
```
Your delegate object should implemnt required methods as below:

```
- (NSUInteger) numberOfItemsInPagedScrollView: (EGPagedScrollView *)pagedScrollViewController;
- (UIView *) pagedScrollView: (EGPagedScrollView *)pagedScrollView viewForPageAtIndex: (NSUInteger) index;
```
 And that's it, for the other details just refer to the example project.
 
 ### License ###

Licensed under MIT. 