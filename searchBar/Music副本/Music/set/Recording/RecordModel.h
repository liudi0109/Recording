//
//  RecordModel.h
//  Music
//
//  Created by admin on 16/3/31.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordModel : NSObject<NSCoding>

@property (nonatomic ,strong) NSString * recordName;
@property (nonatomic ,strong) NSString * recordTime;
@property (nonatomic ,strong) NSString * recordSize;
@property (nonatomic ,strong) NSString * recordUrl;
@property (nonatomic ,strong) NSString * recordDate;

@property (nonatomic, strong) NSString *playTime;
@property (nonatomic, assign) float sliderValue;
@property (nonatomic, assign) float slidermaxValue;

@end
