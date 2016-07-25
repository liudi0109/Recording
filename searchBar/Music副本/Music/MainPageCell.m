//
//  MainPageCell.m
//  Music
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "MainPageCell.h"
#import "SongModel.h"

@implementation MainPageCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)setModel:(SongModel *)model {
    
    self.musicNameLabel.text = model.songName;
    
    // 歌曲时间
    self.timeLabel.text = [NSString stringWithFormat:@"时长:%@",model.songTime];
    
    self.sizeLabel.text = model.songSize;
    
}

// 回调到主页，按钮实现跳转功能
- (IBAction)recordingLabel:(UIButton *)sender {
    self.myBlock();
}


@end
