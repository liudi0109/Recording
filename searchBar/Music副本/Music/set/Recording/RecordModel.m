//
//  RecordModel.m
//  Music
//
//  Created by admin on 16/3/31.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "RecordModel.h"

#define KName @"name"
#define KTime @"time"
#define KSize @"size"
#define KUrl @"url"
#define KDate @"date"

@implementation RecordModel

// 编码
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.recordName forKey:KName];
    [aCoder encodeObject:self.recordSize forKey:KSize];
    [aCoder encodeObject:self.recordTime forKey:KTime];
    [aCoder encodeObject:self.recordUrl forKey:KUrl];
    [aCoder encodeObject:self.recordDate forKey:KDate];
}

// 解码
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.recordName = [aDecoder decodeObjectForKey:KName];
        self.recordSize = [aDecoder decodeObjectForKey:KSize];
        self.recordTime = [aDecoder decodeObjectForKey:KTime];
        self.recordUrl = [aDecoder decodeObjectForKey:KUrl];
        self.recordDate = [aDecoder decodeObjectForKey:KDate];
    }
    return self;
}

@end
