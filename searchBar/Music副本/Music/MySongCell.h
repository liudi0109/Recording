//
//  MySongCell.h
//  Music
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RecordModel;

typedef void (^Block)();
typedef void (^playBlock)(NSString *musicUrl,RecordModel *RecordModel,float sliderValue,float slidermaxValue);

@interface MySongCell : UITableViewCell

@property (nonatomic, strong) RecordModel *model;

// 定义block
@property (nonatomic, copy) playBlock playBlock;
@property (nonatomic, copy) Block sliderBlock;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UIButton *btn4play;

@property (weak, nonatomic) IBOutlet UILabel *playTimeLabel;

@property (weak, nonatomic) IBOutlet UILabel *lastTimeLabel;

@property (weak, nonatomic) IBOutlet UISlider *timeSlider;

@property (weak, nonatomic) IBOutlet UILabel *totalLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *totalLabelHeight;

@end
