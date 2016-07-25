//
//  RecordingVC.h
//  Music
//
//  Created by admin on 16/3/21.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ExternalAccessory/ExternalAccessory.h>  // 蓝牙外设
#import "EZAudio.h"  // 波形图
#import "lame.h"  // lame库mp3编解码

//#import <Foundation/Foundation.h>
//#import <GLKit/GLKit.h>
//#import <AudioToolbox/AudioToolbox.h>
//#import <CoreGraphics/CoreGraphics.h>

@class SongModel;
@class EADSessionController;

@interface RecordingVC : UIViewController
{
    uint32_t _totalBytesRead;
}

// 要播放第几首
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, strong) SongModel *model;

// ----------蓝牙外设
@property (nonatomic, strong) NSMutableArray *accessoryList;
@property (nonatomic, strong) EAAccessory *selectedAccessory;
@property (nonatomic, strong) EADSessionController *eaSessionController;
@property (nonatomic, strong) UIActionSheet *protocolSelectionActionSheet;

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

// ---------- 波形图加分贝 -----------

/**
  波形图的背景板
 */
@property (nonatomic,weak) IBOutlet EZAudioPlot *audioPlot;

/**
  分贝的背景板
 */
@property (weak, nonatomic) IBOutlet EZAudioPlot *dbPlot;

/**
  麦克风
 */
@property (nonatomic,strong) EZMicrophone *microphone;

#pragma mark - Actions

/**
  microphone on and off.
 */
-(IBAction)toggleMicrophone:(id)sender;




@end
