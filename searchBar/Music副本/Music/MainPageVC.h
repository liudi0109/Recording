//
//  MainPageVC.h
//  Music
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>

// 声明
typedef void (^timeBlock)(NSString *playTime,float sliderTime);

@interface MainPageVC : UIViewController

// 定义block块
@property (nonatomic, copy) timeBlock timeBlock;
@property (nonatomic, copy) timeBlock nilBlock;

@end
