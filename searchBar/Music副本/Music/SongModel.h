//
//  MySongTVC.m
//  Music
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SongModel : NSObject

@property (nonatomic ,strong) NSString * songName;
@property (nonatomic ,strong) NSString * songTime;
@property (nonatomic ,strong) NSString * songSize;
@property (nonatomic ,strong) NSString * mp3Url;
@property (nonatomic ,strong) NSString * picUrl;

// 歌词播放时间
@property (nonatomic, assign) NSTimeInterval time;
// 歌词内容
@property (nonatomic, strong) NSString *lyricContext;

- (instancetype)initWithTime:(NSTimeInterval)time
                lyricContext:(NSString *)lyric;

@end
