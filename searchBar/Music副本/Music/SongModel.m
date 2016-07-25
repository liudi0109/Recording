//
//  SongModel.m
//  Music
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "SongModel.h"

@implementation SongModel

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

- (instancetype)initWithTime:(NSTimeInterval)time
                lyricContext:(NSString *)lyric {
    if (self = [super init]) {
        _time = time;
        _lyricContext = lyric;
    }
    return self;
}

@end
