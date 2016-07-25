//
//  PlayingVC.h
//  Music
//
//  Created by admin on 16/3/21.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SongModel;

@interface PlayingVC : UIViewController

+ (instancetype)sharedPlayingVC;

// 要播放第几首
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, strong) SongModel *model;

@end
