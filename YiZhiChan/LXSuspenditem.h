//
//  LXSuspenditem.h
//  YiZhiChan
//
//  Created by Michael on 16/4/20.
//  Copyright © 2016年 吴亚举. All rights reserved.
//  可移动图标的模型文件

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LXSuspenditemType) {
    LXSuspenditemTypePlaceholder = 0,
    LXSuspenditemTypeEntity
};

@interface LXSuspenditem : NSObject

@property (nonatomic, copy)NSString *imageName;
@property (nonatomic, copy)NSString *title;
@property (nonatomic, assign)LXSuspenditemType type;

@end
