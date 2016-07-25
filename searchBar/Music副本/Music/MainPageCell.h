//
//  MainPageCell.h
//  Music
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SongModel;

typedef void (^Block)();

@interface MainPageCell : UITableViewCell

@property (nonatomic, copy) SongModel *model;

// 定义block
@property (nonatomic, copy) Block myBlock;

@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@property (weak, nonatomic) IBOutlet UILabel *musicNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;


@end
