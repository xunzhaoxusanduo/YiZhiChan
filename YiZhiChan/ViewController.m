//
//  ViewController.m
//  YiZhiChan
//
//  Created by Michael on 16/4/1.
//  Copyright © 2016年 吴亚举. All rights reserved.
//

#import "ViewController.h"
#import "SDCycleScrollView.h"
#import "LXReorderableCollectionViewFlowLayout.h"
#import "LXSuspenditemViewCell.h"
#import "LXSuspenditem.h"

static NSString *const CellReuseIdentify = @"LXSuspenditemViewCell";

@interface ViewController () <SDCycleScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong)NSMutableArray *homeDataArray;
@property (nonatomic, strong)UIView *headView;
@property (nonatomic, strong)UICollectionView *collectionView;
@property (nonatomic, strong)SDCycleScrollView *bgScrollView;

@property (nonatomic, strong)NSMutableArray *dataArray;

@end


@implementation ViewController

- (NSMutableArray *)dataArray{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
        for (int i = 0; i < 16; i++) {
            if (i %2 == 0) {
                LXSuspenditem *item = [[LXSuspenditem alloc] init];
                item.title = [NSString stringWithFormat:@"%dtext", i];
                item.type = LXSuspenditemTypePlaceholder;
                [_dataArray addObject:item];
            }else {
                LXSuspenditem *item = [[LXSuspenditem alloc] init];
                item.title = [NSString stringWithFormat:@"%dtext", i];
                item.type = LXSuspenditemTypeEntity;
                [_dataArray addObject:item];
            }
        }
    }
    
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupSubView];
    [self setupCollectionView];
    
    UISwipeGestureRecognizer *leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.collectionView addGestureRecognizer:leftSwipeGestureRecognizer];
    
    UISwipeGestureRecognizer *rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.collectionView addGestureRecognizer:rightSwipeGestureRecognizer];
}

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)sender {
    switch (sender.direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            [self.bgScrollView downImage];
            break;
        case UISwipeGestureRecognizerDirectionRight:
            [self.bgScrollView upImage];
            break;
        default:
            break;
    }
}

- (void)setupSubView{
    NSArray *imagesURLStrings = @[
                                  @"https://ss2.baidu.com/-vo3dSag_xI4khGko9WTAnF6hhy/super/whfpf%3D425%2C260%2C50/sign=a4b3d7085dee3d6d2293d48b252b5910/0e2442a7d933c89524cd5cd4d51373f0830200ea.jpg",
                                  @"https://ss0.baidu.com/-Po3dSag_xI4khGko9WTAnF6hhy/super/whfpf%3D425%2C260%2C50/sign=a41eb338dd33c895a62bcb3bb72e47c2/5fdf8db1cb134954a2192ccb524e9258d1094a1e.jpg",
                                  @"http://c.hiphotos.baidu.com/image/w%3D400/sign=c2318ff84334970a4773112fa5c8d1c0/b7fd5266d0160924c1fae5ccd60735fae7cd340d.jpg"
                                  ];
    SDCycleScrollView *bgScrollView = [SDCycleScrollView cycleScrollViewWithFrame:self.view.frame delegate:self placeholderImage:[UIImage imageNamed:@"placeholder"]];
    bgScrollView.showPageControl = NO;
    bgScrollView.autoScroll = NO;
    bgScrollView.infiniteLoop = NO;
    bgScrollView.bannerImageViewContentMode = UIViewContentModeScaleAspectFill;
    self.bgScrollView = bgScrollView;
    [self.view addSubview:bgScrollView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        bgScrollView.imageURLStringsGroup = imagesURLStrings;
    });
}

- (void)setupCollectionView {
    LXReorderableCollectionViewFlowLayout *flowLayout = [[LXReorderableCollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(100, 100);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.height)
//                                        collectionViewLayout:flowLayout];
//    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame
                                                          collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    self.collectionView = collectionView;
    [self.bgScrollView addSubview:collectionView];
    
//    [self.collectionView registerNib:[UINib nibWithNibName:@"LXSuspenditemViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:CellReuseIdentify];
    [self.collectionView registerClass:[LXSuspenditemViewCell class] forCellWithReuseIdentifier:CellReuseIdentify];
}

#pragma mark - UICollectionViewDataSource 数据源方法
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    LXSuspenditemViewCell *cell = (LXSuspenditemViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentify forIndexPath:indexPath];
    cell.suspenditem = self.dataArray[indexPath.row];
    
    return cell;
}

#pragma mark - LXReorderableCollectionViewDataSource methods

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    LXSuspenditem *fromSuspenditem = self.dataArray[fromIndexPath.item];
    LXSuspenditem *toSuspenditem = self.dataArray[toIndexPath.item];
    self.dataArray[fromIndexPath.item] = toSuspenditem;
    self.dataArray[toIndexPath.item] = fromSuspenditem;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    LXSuspenditem *suspenditem = self.dataArray[indexPath.item];
    
    if (suspenditem.type == LXSuspenditemTypeEntity) {
        return YES;
    }else {
        return NO;
    }
}

@end
