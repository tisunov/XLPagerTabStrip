//
//  XLButtonBarPagerTabStripViewController.m
//  XLPagerTabStrip ( https://github.com/xmartlabs/XLPagerTabStrip )
//
//  Copyright (c) 2015 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "XLButtonBarViewCell.h"
#import "XLButtonBarPagerTabStripViewController.h"

@interface XLButtonBarPagerTabStripViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) IBOutlet XLButtonBarView * buttonBarView;
@property (nonatomic) BOOL shouldUpdateButtonBarView;
@property (nonatomic) NSArray *cachedCellWidths;
@property (nonatomic) BOOL isViewAppearing;
@property (nonatomic) BOOL isViewRotating;

@end

@implementation XLButtonBarPagerTabStripViewController

#pragma mark - Initialisation

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.shouldUpdateButtonBarView = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.shouldUpdateButtonBarView = YES;
    }
    return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.buttonBarView.superview){
        // If buttonBarView wasn't configured in a XIB or storyboard then it won't have
        // been added to the view so we need to do it programmatically.
        [self.view addSubview:self.buttonBarView];
    }
    
    if (!self.buttonBarView.delegate){
        self.buttonBarView.delegate = self;
    }
    if (!self.buttonBarView.dataSource){
        self.buttonBarView.dataSource = self;
    }
    self.buttonBarView.labelFont = [UIFont boldSystemFontOfSize:14.0f];
    self.buttonBarView.labelTextColor = [UIColor darkGrayColor];
    self.buttonBarView.leftRightMargin = 8;
    self.buttonBarView.scrollsToTop = NO;
    UICollectionViewFlowLayout *flowLayout = (id)self.buttonBarView.collectionViewLayout;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.buttonBarView.showsHorizontalScrollIndicator = NO;
    
    CALayer *bottomBorderLayer = [CALayer layer];
    bottomBorderLayer.borderColor = [UIColor colorWithRed:0.784 green:0.780 blue:0.800 alpha:1.000].CGColor;
    bottomBorderLayer.borderWidth = 0.25;
    bottomBorderLayer.frame = CGRectMake(0, self.buttonBarView.frame.size.height - 1, self.buttonBarView.frame.size.width, 1);
    [self.buttonBarView.layer addSublayer:bottomBorderLayer];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isViewAppearing = YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isViewAppearing = NO;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (self.isViewAppearing || self.isViewRotating)
    {
        // Force the UICollectionViewFlowLayout to get laid out again with the new size if
        // a) The view is appearing.  This ensures that
        //    collectionView:layout:sizeForItemAtIndexPath: is called for a second time
        //    when the view is shown and when the view *frame(s)* are actually set
        //    (we need the view frame's to have been set to work out the size's and on the
        //    first call to collectionView:layout:sizeForItemAtIndexPath: the view frame(s)
        //    aren't set correctly)
        // b) The view is rotating.  This ensures that
        //    collectionView:layout:sizeForItemAtIndexPath: is called again and can use the views
        //    *new* frame so that the buttonBarView cell's actually get resized correctly
        self.cachedCellWidths = nil; // Clear/invalidate our cache of cell widths
        UICollectionViewFlowLayout *flowLayout = (id)self.buttonBarView.collectionViewLayout;
        [flowLayout invalidateLayout];
        
        // Ensure the buttonBarView.frame is sized correctly after rotation on iOS 7 devices
        [self.buttonBarView layoutIfNeeded];
        
        // When the view first appears or is rotated we also need to ensure that the barButtonView's
        // selectedBar is resized and its contentOffset/scroll is set correctly (the selected
        // tab/cell may end up either skewed or off screen after a rotation otherwise)
        [self.buttonBarView moveToIndex:self.currentIndex animated:NO swipeDirection:XLPagerTabStripDirectionNone pagerScroll:XLPagerScrollOnlyIfOutOfScreen];
    }
    
    // When presenting for previewing with 3D Touch Peek, sequence of events changes and
    // bar stays at offset 0 even if self.currentIndex non 0
    if (self.currentIndex > 0 && self.buttonBarView.contentOffset.x == 0) {
        [self.buttonBarView moveToIndex:self.currentIndex animated:NO swipeDirection:XLPagerTabStripDirectionNone pagerScroll:XLPagerScrollNO];
    }
    
}


#pragma mark - View Rotation

// Called on iOS 8+ only
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.isViewRotating = YES;
}

// Called on iOS 7 only
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.isViewRotating = YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.isViewRotating = NO;
}


#pragma mark - Public methods

-(void)reloadPagerTabStripView
{
    self.cachedCellWidths = nil; // Clear/invalidate our cache of cell widths
    
    [super reloadPagerTabStripView];
    if ([self isViewLoaded]){
        [self.buttonBarView reloadData];
        [self.buttonBarView moveToIndex:self.currentIndex animated:NO swipeDirection:XLPagerTabStripDirectionNone pagerScroll:XLPagerScrollYES];
    }
}


#pragma mark - Properties

-(XLButtonBarView *)buttonBarView
{
    if (!_buttonBarView)
    {
        // If _buttonBarView is nil then it wasn't configured in a XIB or storyboard so
        // this class is being used programmatically. We need to initialise the buttonBarView,
        // setup some sensible defaults (which can of course always be re-set in the sub-class),
        // and set an appropriate frame. The buttonBarView gets added to to the view in viewDidLoad:
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 25, 0, 25);
        _buttonBarView = [[XLButtonBarView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0f) collectionViewLayout:flowLayout];
        _buttonBarView.backgroundColor = [UIColor orangeColor];
        _buttonBarView.selectedBar.backgroundColor = [UIColor blackColor];
        _buttonBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        // If a XIB or storyboard hasn't been used we also need to register the cell reuseIdentifier
        // as well otherwise we'll get a crash when the code attempts to dequeue any cell's
        [_buttonBarView registerClass:[XLButtonBarViewCell class] forCellWithReuseIdentifier:@"Cell"];
        // If a XIB or storyboard hasn't been used then the containView frame that was setup in the
        // XLPagerTabStripViewController won't have accounted for the buttonBarView. So we need to adjust
        // its y position (and also its height) so that childVC's don't appear under the buttonBarView.
        CGRect newContainerViewFrame = self.containerView.frame;
        newContainerViewFrame.origin.y = 44.0f;
        newContainerViewFrame.size.height = self.containerView.frame.size.height - (44.0f - self.containerView.frame.origin.y);
        self.containerView.frame = newContainerViewFrame;
    }
    return _buttonBarView;
}

- (NSArray *)cachedCellWidths
{
    if (!_cachedCellWidths)
    {
        // First calculate the minimum width required by each cell
        
        UICollectionViewFlowLayout *flowLayout = (id)self.buttonBarView.collectionViewLayout;
        NSUInteger numberOfCells = self.pagerTabStripChildViewControllers.count;
        
        NSMutableArray *minimumCellWidths = [[NSMutableArray alloc] init];
        
        CGFloat collectionViewContentWidth = 0;
        
        for (UIViewController<XLPagerTabStripChildItem> *childController in self.pagerTabStripChildViewControllers)
        {
            // FIXME: Don't create UILabel just to measture cell width
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.font = self.buttonBarView.labelFont;
            label.text = childController.title;
            CGSize labelSize = [label intrinsicContentSize];
            
            CGFloat minimumCellWidth = labelSize.width + (self.buttonBarView.leftRightMargin * 2);
            NSNumber *minimumCellWidthValue = [NSNumber numberWithFloat:minimumCellWidth];
            [minimumCellWidths addObject:minimumCellWidthValue];
            
            collectionViewContentWidth += minimumCellWidth;
        }
        
        // To get an acurate collectionViewContentWidth account for the spacing between cells
        CGFloat cellSpacingTotal = ((numberOfCells-1) * flowLayout.minimumInteritemSpacing);
        collectionViewContentWidth += cellSpacingTotal;
        
        CGFloat collectionViewAvailableVisibleWidth = self.buttonBarView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right;
        
        // Do we need to stetch any of the cell widths to fill the screen width?
        if (!self.shouldCellsFillAvailableWidth || collectionViewAvailableVisibleWidth < collectionViewContentWidth)
        {
            // The collection view's content width is larger that the visible width available so it needs to scroll
            // OR shouldCellsFillAvailableWidth == NO...
            // No need to stretch any of the cells, we can just use the minimumCellWidths for the cell widths.
            _cachedCellWidths = minimumCellWidths;
        }
        else
        {
            // The collection view's content width is smaller that the visible width available so it won't ever scroll
            // AND shouldCellsFillAvailableWidth == YES so we want to stretch the cells to fill the width.
            // We now need to calculate how much to stretch each tab...
            
            // In an ideal world the cell's would all have an equal width, however the cell labels vary in length
            // so some of the longer labelled cells might not need to stetch where as the shorter labelled cells do.
            // In order to determine what needs to stretch and what doesn't we have to recurse through suggestedStetchedCellWidth
            // values (the value decreases with each recursive call) until we find a value that works.
            // The first value to try is the largest (for the case where all the cell widths are equal)
            CGFloat stetchedCellWidthIfAllEqual = (collectionViewAvailableVisibleWidth - cellSpacingTotal) / numberOfCells;
            
            CGFloat generalMiniumCellWidth = [self calculateStretchedCellWidths:minimumCellWidths suggestedStetchedCellWidth:stetchedCellWidthIfAllEqual previousNumberOfLargeCells:0];
            
            NSMutableArray *stetchedCellWidths = [[NSMutableArray alloc] init];
            
            for (NSNumber *minimumCellWidthValue in minimumCellWidths)
            {
                CGFloat minimumCellWidth = minimumCellWidthValue.floatValue;
                CGFloat cellWidth = (minimumCellWidth > generalMiniumCellWidth) ? minimumCellWidth : generalMiniumCellWidth;
                NSNumber *cellWidthValue = [NSNumber numberWithFloat:cellWidth];
                [stetchedCellWidths addObject:cellWidthValue];
            }
            
            _cachedCellWidths = stetchedCellWidths;
        }
    }
    return _cachedCellWidths;
}

- (CGFloat)calculateStretchedCellWidths:(NSArray *)minimumCellWidths suggestedStetchedCellWidth:(CGFloat)suggestedStetchedCellWidth previousNumberOfLargeCells:(NSUInteger)previousNumberOfLargeCells
{
    // Recursively attempt to calculate the stetched cell width
    
    NSUInteger numberOfLargeCells = 0;
    CGFloat totalWidthOfLargeCells = 0;
    
    for (NSNumber *minimumCellWidthValue in minimumCellWidths)
    {
        CGFloat minimumCellWidth = minimumCellWidthValue.floatValue;
        if (minimumCellWidth > suggestedStetchedCellWidth) {
            totalWidthOfLargeCells += minimumCellWidth;
            numberOfLargeCells++;
        }
    }
    
    // Is the suggested width any good?
    if (numberOfLargeCells > previousNumberOfLargeCells)
    {
        // The suggestedStetchedCellWidth is no good :-( ... calculate a new suggested width
        UICollectionViewFlowLayout *flowLayout = (id)self.buttonBarView.collectionViewLayout;
        CGFloat collectionViewAvailableVisibleWidth = self.buttonBarView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right;
        NSUInteger numberOfCells = minimumCellWidths.count;
        CGFloat cellSpacingTotal = ((numberOfCells-1) * flowLayout.minimumInteritemSpacing);
        
        NSUInteger numberOfSmallCells = numberOfCells - numberOfLargeCells;
        CGFloat newSuggestedStetchedCellWidth =  (collectionViewAvailableVisibleWidth - totalWidthOfLargeCells - cellSpacingTotal) / numberOfSmallCells;
        
        return [self calculateStretchedCellWidths:minimumCellWidths suggestedStetchedCellWidth:newSuggestedStetchedCellWidth previousNumberOfLargeCells:numberOfLargeCells];
    }
    
    // The suggestion is good
    return suggestedStetchedCellWidth;
}


#pragma mark - XLPagerTabStripViewControllerDelegate

-(void)pagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController
          updateIndicatorFromIndex:(NSInteger)fromIndex
                           toIndex:(NSInteger)toIndex
{
    if (self.shouldUpdateButtonBarView){
        XLPagerTabStripDirection direction = XLPagerTabStripDirectionLeft;
        if (toIndex < fromIndex){
            direction = XLPagerTabStripDirectionRight;
        }
        [self.buttonBarView moveToIndex:toIndex animated:YES swipeDirection:direction pagerScroll:XLPagerScrollYES];
        if (self.changeCurrentIndexBlock) {
            XLButtonBarViewCell *oldCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex != fromIndex ? fromIndex : toIndex inSection:0]];
            XLButtonBarViewCell *newCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];

            self.changeCurrentIndexBlock(oldCell, newCell, YES);
        }
    }
}

-(void)pagerTabStripViewController:(XLPagerTabStripViewController *)pagerTabStripViewController
          updateIndicatorFromIndex:(NSInteger)fromIndex
                           toIndex:(NSInteger)toIndex
            withProgressPercentage:(CGFloat)progressPercentage
                   indexWasChanged:(BOOL)indexWasChanged
{
    if (self.shouldUpdateButtonBarView){
        [self.buttonBarView moveFromIndex:fromIndex
                                  toIndex:toIndex
                   withProgressPercentage:progressPercentage pagerScroll:XLPagerScrollYES];
        
        if (self.changeCurrentIndexProgressiveBlock) {
            XLButtonBarViewCell *oldCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex != fromIndex ? fromIndex : toIndex inSection:0]];
            XLButtonBarViewCell *newCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
            self.changeCurrentIndexProgressiveBlock(oldCell, newCell, progressPercentage, indexWasChanged, YES);
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.cachedCellWidths.count > indexPath.row)
    {
        NSNumber *cellWidthValue = self.cachedCellWidths[indexPath.row];
        CGFloat cellWidth = [cellWidthValue floatValue];
        return CGSizeMake(cellWidth, collectionView.frame.size.height);
    }
    return CGSizeZero;
}

#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //There's nothing to do if we select the current selected tab
    if (indexPath.item == self.currentIndex)
        return;
    
    [self.buttonBarView moveToIndex:indexPath.item animated:YES swipeDirection:XLPagerTabStripDirectionNone pagerScroll:XLPagerScrollYES];
    self.shouldUpdateButtonBarView = NO;
    
    XLButtonBarViewCell *oldCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
    oldCell.label.textColor = self.buttonBarView.labelTextColor;
    
    XLButtonBarViewCell *newCell = (XLButtonBarViewCell*)[self.buttonBarView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
    newCell.label.textColor = self.buttonBarView.labelSelectedTextColor;
    
    if (self.isProgressiveIndicator) {
        if (self.changeCurrentIndexProgressiveBlock) {
            self.changeCurrentIndexProgressiveBlock(oldCell, newCell, 1, YES, YES);
        }
    }
    else{
        if (self.changeCurrentIndexBlock) {
            self.changeCurrentIndexBlock(oldCell, newCell, YES);
        }
    }
    
    [self moveToViewControllerAtIndex:indexPath.item];
}

#pragma merk - UICollectionViewDataSource

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.pagerTabStripChildViewControllers.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    XLButtonBarViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    if (!cell){
        cell = [[XLButtonBarViewCell alloc] initWithFrame:CGRectMake(0, 0, 50, self.buttonBarView.frame.size.height)];
    }
    NSAssert([cell isKindOfClass:[XLButtonBarViewCell class]], @"UICollectionViewCell should be or extend XLButtonBarViewCell");
    XLButtonBarViewCell * buttonBarCell = (XLButtonBarViewCell *)cell;
    UIViewController<XLPagerTabStripChildItem> * childController =   [self.pagerTabStripChildViewControllers objectAtIndex:indexPath.item];
    
    buttonBarCell.label.font = self.buttonBarView.labelFont;
    buttonBarCell.label.textColor = indexPath.row == self.currentIndex ? self.buttonBarView.labelSelectedTextColor : self.buttonBarView.labelTextColor;
    buttonBarCell.label.text = childController.title;
    
    if (self.isProgressiveIndicator) {
        if (self.changeCurrentIndexProgressiveBlock) {
            self.changeCurrentIndexProgressiveBlock(self.currentIndex == indexPath.item ? nil : cell , self.currentIndex == indexPath.item ? cell : nil, 1, YES, NO);
        }
    }
    else{
        if (self.changeCurrentIndexBlock) {
            self.changeCurrentIndexBlock(self.currentIndex == indexPath.item ? nil : cell , self.currentIndex == indexPath.item ? cell : nil, NO);
        }
    }
    
    return buttonBarCell;
}


#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [super scrollViewDidEndScrollingAnimation:scrollView];
    if (scrollView == self.containerView){
        self.shouldUpdateButtonBarView = YES;
    }
}


@end
