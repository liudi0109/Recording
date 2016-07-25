//
//  PlayingVC.m
//  Music
//
//  Created by admin on 16/3/21.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "PlayingVC.h"
#import <AVFoundation/AVFoundation.h>
#import "SongModel.h"
#import "RecordModel.h"
#import "PlayerManager.h"

@interface PlayingVC ()<PlayerManagerDelegate>

// 播放器 -> 全局唯一 ->，因为如果有两个AVPlayer，就会同时播放两个音乐
@property (nonatomic, retain) AVPlayer *player;

// 记录一下当前播放音乐的索引
@property (nonatomic, assign) NSInteger currentIndex;
// 记录当前正在播放的音乐
@property (nonatomic, retain) SongModel *currentMusic;

@property (weak, nonatomic) IBOutlet UILabel *musicName;

@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@property (weak, nonatomic) IBOutlet UILabel *playTime;

@property (weak, nonatomic) IBOutlet UILabel *lastTime;

@property (weak, nonatomic) IBOutlet UISlider *timeSlider;

- (IBAction)btn4back:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btn4playOrPause;


@end

static PlayingVC *play = nil;

@implementation PlayingVC

+ (instancetype)sharedPlayingVC {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 拿到main storyBoard
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        // 在main storyBoard 拿到我们要用的视图控制器
        play = [sb instantiateViewControllerWithIdentifier:@"playingVC"];
        
    });
    return play;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentIndex = -1;  // 列表从0开始，不能播放
    
    // 图片设置圆角
    _imgView.layer.masksToBounds = YES;
    _imgView.layer.cornerRadius = _imgView.frame.size.width / 2;
    
    // 设置代理(自己是代理，帮播放器做事)
    [PlayerManager sharedManager].playingDelegate = self;
    
}

#pragma mark ----delegate
// 播放器每0.1秒会让代理（也就是这个页面）执行此事件
- (void)playerPlayingWithTime:(NSTimeInterval)time {
    self.timeSlider.value = time;
    // 播放时间
    self.playTime.text = [self stringWithTime:time];
    // 每0.1秒旋转一度
    self.imgView.transform = CGAffineTransformRotate(self.imgView.transform, M_PI / 180);
}

// 根据时间获取到字符串
- (NSString *)stringWithTime:(NSTimeInterval)time {
    NSInteger minute = time / 60;
    NSInteger seconds = (int)time % 60;
    return [NSString stringWithFormat:@"%.2ld:%.2ld",(long)minute,(long)seconds];
}

// 播放事件
- (void)startPlay {
    
    [[PlayerManager sharedManager] playWithUrlString:self.currentMusic.mp3Url];
    
    [self buildUI];
}

#pragma mark ---get方法
- (SongModel *)currentMusic {
    // 取到要播放的model
    SongModel *music = self.dataArray[self.currentIndex];
    return music;
}

- (void)buildUI {
    
    self.musicName.text = self.currentMusic.songName;
    self.lastTime.text = self.currentMusic.songTime;
    
    // 改变进度条的最大值
    NSRange minuteRange = NSMakeRange(1, 1);
    NSString *minuteStr = [self.currentMusic.songTime substringWithRange:minuteRange];
    
    NSRange secondRange = NSMakeRange(3, 2);
    NSString *secondStr = [self.currentMusic.songTime substringWithRange:secondRange];
    self.timeSlider.maximumValue = [minuteStr integerValue] * 60 + [secondStr integerValue];
    
}

// 判断（当前音乐与要播放的音乐）
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 如果要播放的音乐和当前的音乐一样，什么也不做
    if (_index == _currentIndex) {
        return;
    }
    // 如果不相同，当前播放的音乐变成要播放的音乐
    _currentIndex = _index;
    
    [self startPlay];
}


// 懒加载
- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer new];
    }
    return _player;
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}


- (IBAction)timeSlider:(UISlider *)sender {
    UISlider *slider = sender;
    // 调用接口
    [[PlayerManager sharedManager] seekToTime:slider.value];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btn4back:(id)sender {
    [[PlayerManager sharedManager] pause];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btn4playOrPause:(id)sender {
    // 判断是否正在播放
    if ([PlayerManager sharedManager].isPlaying) {
        // 如果正在播放，就暂停，同时改变text
        [[PlayerManager sharedManager] pause];
        [sender setImage:[UIImage imageNamed:@"暂停"] forState:(UIControlStateNormal)];
    } else {
        [[PlayerManager sharedManager] play];
        [sender setImage:[UIImage imageNamed:@"播放"] forState:(UIControlStateNormal)];
    }

}
@end
