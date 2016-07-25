//
//  MySongCell.m
//  Music
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "MySongCell.h"
#import "RecordModel.h"

@implementation MySongCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setModel:(RecordModel *)model {

    _model = model;
    
    self.nameLabel.text = model.recordName;
    self.sizeLabel.text = [NSString stringWithFormat:@"大小:%@，MP3",model.recordSize];
    self.timeLabel.text = [NSString stringWithFormat:@"时长:%@",model.recordTime];
    
    self.dateLabel.text = model.recordDate;

    self.lastTimeLabel.text = model.recordTime;

    self.playTimeLabel.text = model.playTime;
    
    self.timeSlider.value = model.sliderValue;
    self.timeSlider.maximumValue = model.slidermaxValue;
    
//    [self.btn4play setImage:[UIImage imageNamed:@"小暂停"] forState:UIControlStateNormal];
    
}

- (IBAction)btn4play:(id)sender {
    self.playBlock(_model.recordUrl,_model,_model.sliderValue,_model.slidermaxValue);
}

- (IBAction)timeSlider:(id)sender {
    self.sliderBlock();
}



@end
