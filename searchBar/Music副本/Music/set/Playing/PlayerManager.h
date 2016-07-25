//
//  PlayerManager.h
//  MusicPlayer
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PlayerManagerDelegate <NSObject>

// 播放中间一直在重复执行该方法
- (void)playerPlayingWithTime:(NSTimeInterval)time;

@end

@interface PlayerManager : NSObject

// 判断状态（是否正在播放）
@property (nonatomic, assign) BOOL isPlaying;
// 设置代理
@property (nonatomic, assign) id <PlayerManagerDelegate> playingDelegate;

// 播放
- (void)play;
// 暂停
- (void)pause;

// 改变进度
- (void)seekToTime:(NSTimeInterval)time;

+ (instancetype) sharedManager;

// 给一个连接，让AVPlayer播放
- (void)playWithUrlString:(NSString *)urlStr;

@end
