//
//  LXSuspenditemViewCell.m
//  YiZhiChan
//
//  Created by Michael on 16/4/20.
//  Copyright © 2016年 吴亚举. All rights reserved.
//

#import "LXSuspenditemViewCell.h"
#import "Masonry.h"
#import "LXSuspenditem.h"

#define ImageRadio 0.7

@interface LXSuspenditemViewCell ()

@property (nonatomic, strong)UIImageView *imageView;
@property (nonatomic, strong)UILabel *label;

@end

@implementation LXSuspenditemViewCell

- (void)awakeFromNib{
    
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
//        UIView *backView = [[UIView alloc] init];
//        backView.backgroundColor = [UIColor clearColor];
//        [self.contentView addSubview:backView];
//        [backView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.equalTo(self.contentView);
//        }];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:imageView];
        self.imageView = imageView;
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top);
            make.left.equalTo(self.contentView.mas_left);
            make.right.equalTo(self.contentView.mas_right);
            make.height.equalTo(self.contentView.mas_height).multipliedBy(ImageRadio);
        }];
        
        UILabel *label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        [self.contentView addSubview:label];
        self.label = label;
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(imageView.mas_bottom);
            make.left.equalTo(self.contentView.mas_left);
            make.bottom.equalTo(self.contentView.mas_bottom);
            make.right.equalTo(self.contentView.mas_right);
        }];
    }
    
    return self;
}

//- (instancetype)initWithFrame:(CGRect)frame{
//    if (self = [super initWithFrame:frame]) {
//        UIView *view = [[UIView alloc] init];
//        view.backgroundColor = [UIColor grayColor];
//        view.layer.cornerRadius = 8;
//        [self.contentView addSubview:view];
//        [view mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.equalTo(self.contentView);
//        }];
//        
//        UILabel *label = [[UILabel alloc] init];
//        label.textColor = [UIColor whiteColor];
//        label.textAlignment = NSTextAlignmentCenter;
//        label.font = [UIFont systemFontOfSize:20];
//        [view addSubview:label];
//        [label mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.equalTo(view);
//        }];
//        self.label = label;
//    }
//    
//    return self;
//}

- (void)setSuspenditem:(LXSuspenditem *)suspenditem{
    _suspenditem = suspenditem;
    if (suspenditem.type == LXSuspenditemTypePlaceholder) {
        self.imageView.image = nil;
        self.label.text = nil;
    }else if (suspenditem.type == LXSuspenditemTypeEntity){
        self.imageView.image = [UIImage imageNamed:suspenditem.imageName];
        self.label.text = suspenditem.title;
    }
}


@end
