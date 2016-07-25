//
//  RecordingVC.m
//  Music
//
//  Created by admin on 16/3/21.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "RecordingVC.h"
#import "SGPopSelectView.h"
#import <AVFoundation/AVFoundation.h>
#import "SongModel.h"
#import "RecordManager.h"
#import "EADSessionController.h"
#import "RecordModel.h"

@interface RecordingVC ()<UIGestureRecognizerDelegate,RecordManagerDelegate,UIActionSheetDelegate,EZMicrophoneDelegate>

/*
 * 录音
 */
// 输入的录制的名字
@property (nonatomic, strong) UITextField *tf;
// 循环存的路径
@property (nonatomic, strong) NSString *filePath;
// 判断是否正在录制
@property (nonatomic, assign) BOOL isRecording;
// 录制/暂停
@property (weak, nonatomic) IBOutlet UIButton *btn4recordOrPause;
// 计时器
@property (nonatomic, retain) NSTimer *timer;
// 读取文件
@property (nonatomic, strong) NSFileHandle *inFile;
// 写入文件
@property (nonatomic, strong) NSFileHandle *outFile;

// 计时器时间的显示
@property (weak, nonatomic) IBOutlet UILabel *lab4timer;
@property (weak, nonatomic) IBOutlet UILabel *lab4size;

@property (nonatomic, strong) NSString *timestr;
@property (nonatomic, assign) float time;

- (IBAction)btn4singleSing:(UIButton *)sender;
- (IBAction)btn4comRecording:(UIButton *)sender;

/*
 * 蓝牙外设
 */
// 设备提示
@property (nonatomic, strong) UIAlertController *alert;
// 临时数组
@property (nonatomic, strong) NSMutableArray *tempArray;

/*
 * 播放
 */
// 播放器 -> 全局唯一 ->，因为如果有两个AVPlayer，就会同时播放两个音乐
@property (nonatomic, retain) AVPlayer *player;
// 记录一下当前播放音乐的索引
@property (nonatomic, assign) NSInteger currentIndex;
// 记录当前正在播放的音乐
@property (nonatomic, retain) SongModel *currentMusic;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

// 第三方视图
@property (nonatomic, strong) SGPopSelectView *popView;

// 麦克风开关文字显示
@property (weak, nonatomic) IBOutlet UILabel *lab4MicroPhone;


@end

@implementation RecordingVC

/*
 
 * * * * 波形图 * * * *
 
 */

// 初始化
- (instancetype)init {
    if (self = [super init]) {
        [self initializeViewController];
    }
    return self;
}
// 初始化
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializeViewController];
    }
    return self;
}

#pragma mark - Initialize View Controller Here
-(void)initializeViewController {
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
}

// 自定义波形图的外观
- (void)buildWave {
    // 背景色
    self.audioPlot.backgroundColor = [UIColor colorWithRed:0.984 green:0.471 blue:0.525 alpha:1.0];
    // 波形色
    self.audioPlot.color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    // 波形
    self.audioPlot.plotType = EZPlotTypeRolling;
    self.audioPlot.shouldFill = YES;
    self.audioPlot.shouldMirror = YES;
    // 分贝
    self.dbPlot.plotType = EZPlotTypeBuffer;
    self.dbPlot.shouldMirror = NO;
    self.dbPlot.shouldFill = NO;
    // 打开话筒
    [self.microphone startFetchingAudio];
    self.lab4MicroPhone.text = @"Microphone On";
    
}

// 麦克风开关状态
-(void)toggleMicrophone:(id)sender {
    if( ![(UISwitch*)sender isOn] ){
        [self.microphone stopFetchingAudio];
        self.lab4MicroPhone.text = @"Microphone Off";
    }
    else {
        [self.microphone startFetchingAudio];
        self.lab4MicroPhone.text = @"Microphone On";
    }
}

#pragma mark - EZMicrophoneDelegate
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {

    dispatch_async(dispatch_get_main_queue(),^{
        // buffer[0] 左通道
        // buffer[1] 右通道
        [self.dbPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
        [self.audioPlot updateRolling:buffer[0] withRollingSize:bufferSize];
        
    });
    
}

-(void)microphone:(EZMicrophone *)microphone hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
    // 打印音频格式类型
    [EZAudio printASBD:audioStreamBasicDescription];
}

-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder or EZOutput. Say whattt...
    // 获取音频数据作为一个缓冲区列表，可以直接进入ezrecorder或ezoutput。说whattt…
}

#pragma mark -- lazy load

- (NSMutableArray *)tempArray {
    if (!_tempArray) {
        self.tempArray = [NSMutableArray array];
    }
    return _tempArray;
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 没在录制
    _isRecording = NO;
    // 更改button的text
    [self.btn4recordOrPause setImage:[UIImage imageNamed:@"录制"] forState:UIControlStateNormal];
    
    _currentIndex = -1;  // 列表从0开始，不能播放
    
    // 设置代理(自己是代理，帮播放器做事)
    [RecordManager sharedManager].recordingDelegate = self;
    
    // 没有外设
    [self noDevice];
    // 蓝牙设备
    [self accessory];
    // 点击事件
    [self bluetooth];
    
    // 波形图外观
    [self buildWave];
    
//    [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(drawRollingPlot) userInfo:nil repeats:YES];
    
}

/*
 
 * * * * 播放音乐 * * * *
 
 */
#pragma mark ----delegate
// 播放器每0.1秒会让代理（也就是这个页面）执行此事件
- (void)playerRecordingWithTime:(NSTimeInterval)time {
    
    // 播放时间
    NSString *playTime = [self stringWithTime:time];
    NSString *lastTime = self.currentMusic.songTime;
    self.timeLabel.text = [NSString stringWithFormat:@"正在录制...%@/%@",playTime,lastTime];
    
}

// 根据时间获取到字符串
- (NSString *)stringWithTime:(NSTimeInterval)time {
    NSInteger minute = time / 60;
    NSInteger seconds = (int)time % 60;
    return [NSString stringWithFormat:@"%.2ld:%.2ld",(long)minute,(long)seconds];
}

// 播放事件
- (void)startPlay {
    [[RecordManager sharedManager] playWithUrlString:self.currentMusic.mp3Url];
    [self buildUI];
}

#pragma mark ---get方法
- (SongModel *)currentMusic {
    
    if (_dataArray != nil && ![_dataArray isKindOfClass:[NSNull class]] && _dataArray.count != 0)
    {
        // 取到要播放的model
        SongModel *music = self.dataArray[self.currentIndex];
        return music;
    }
    return nil;
}

- (void)buildUI {
    self.nameLabel.text = self.currentMusic.songName;
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

/*
 
 * * * * 外设搜索 * * * *
 
 */

// 没有外设
- (void)noDevice {
    //创建alert
    self.alert = [UIAlertController alertControllerWithTitle:@"notice" message:nil preferredStyle:(UIAlertControllerStyleAlert)];
    
    //确定点击事件
    UIAlertAction *yes = [UIAlertAction actionWithTitle:@"No Accessories Connected" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        return;
    }];
    
    [_alert addAction:yes];

}

// 蓝牙设备
- (void)accessory {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    
    self.eaSessionController = [EADSessionController sharedController];
    // 连接的设备数组
    self.accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    
    
    // ------------后加--------------
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sessionDataReceived:) name:EADSessionDataReceivedNotification object:nil];
//    
//    EADSessionController *sessionController = [EADSessionController sharedController];
//    
//    _selectedAccessory = [sessionController accessory];
//    [self setTitle:[sessionController protocolString]];
//    [sessionController openSession];

}

- (void)viewWillDisappear:(BOOL)animated {
    
    // remove the observers
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EADSessionDataReceivedNotification object:nil];
    
    EADSessionController *sessionController = [EADSessionController sharedController];
    
    [sessionController closeSession];
    
    _selectedAccessory = nil;
    
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];
    
    _accessoryList = nil;
    
    _selectedAccessory = nil;
    
    _protocolSelectionActionSheet = nil;
    
    [super viewDidUnload];
}

#pragma mark UIActionSheetDelegate methods
// 点击协议之后调用
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_selectedAccessory && (buttonIndex >= 0) && (buttonIndex < [[_selectedAccessory protocolStrings] count]))
    {
        [_eaSessionController setupControllerForAccessory:_selectedAccessory
                                       withProtocolString:[[_selectedAccessory protocolStrings] objectAtIndex:buttonIndex]];

        
        // 跳转到传输界面
//        EADSessionTransferViewController *sessionTransferViewController =
//        [[EADSessionTransferViewController alloc] initWithNibName:@"EADSessionTransfer" bundle:nil];
//        
//        [[self navigationController] pushViewController:sessionTransferViewController animated:YES];
        
    }
    _selectedAccessory = nil;
    
    _protocolSelectionActionSheet = nil;
}


#pragma mark Internal
// 连接
- (void)_accessoryDidConnect:(NSNotification *)notification {
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    [_accessoryList addObject:connectedAccessory];
    // ----------------------
    NSLog(@"设备列表%@",_accessoryList);
    // ----------------------
    if ([_accessoryList count] == 0) { // 没有可连接的设备，弹出提示框
        [self presentViewController:_alert animated:YES completion:nil];
        [self.popView setHidden:YES];
    } else {
        [self.popView setHidden:NO];
    }
    
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([_accessoryList count] - 1) inSection:0];
//    [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    
}
// 未连接
- (void)_accessoryDidDisconnect:(NSNotification *)notification {
    EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    if (_selectedAccessory && [disconnectedAccessory connectionID] == [_selectedAccessory connectionID])
    {
        [_protocolSelectionActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    }
    
    int disconnectedAccessoryIndex = 0;
    for(EAAccessory *accessory in _accessoryList) {
        if ([disconnectedAccessory connectionID] == [accessory connectionID]) {
            break;
        }
        disconnectedAccessoryIndex++;
    }
    
    if (disconnectedAccessoryIndex < [_accessoryList count]) {
        [_accessoryList removeObjectAtIndex:disconnectedAccessoryIndex];
//        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:disconnectedAccessoryIndex inSection:0];
//        [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    } else {
        NSLog(@"could not find disconnected accessory in accessory list");
    }
    
    if ([_accessoryList count] == 0) {
        [self presentViewController:_alert animated:YES completion:nil];
        [self.popView setHidden:YES];
    } else {
        [self.popView setHidden:NO];
    }
}

// 点击事件
-(void)bluetooth{
    self.popView = [[SGPopSelectView alloc] init];
    
    NSLog(@"信息:%@",self.accessoryList);

    __weak typeof(self) weakSelf = self;
    self.popView.selectedHandle = ^(NSInteger selectedIndex){
        
        NSLog(@"选择 %ld, 内容 %@", (long)selectedIndex, weakSelf.tempArray[selectedIndex]);
        
        NSUInteger row = (long)selectedIndex;
        
        _selectedAccessory = [_accessoryList objectAtIndex:row];
        
        _protocolSelectionActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Protocol" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
        NSArray *protocolStrings = [weakSelf.selectedAccessory protocolStrings];
        for(NSString *protocolString in protocolStrings) {
            [weakSelf.protocolSelectionActionSheet addButtonWithTitle:protocolString];
        }
        
        [weakSelf.protocolSelectionActionSheet setCancelButtonIndex:[weakSelf.protocolSelectionActionSheet addButtonWithTitle:@"Cancel"]];
        [weakSelf.protocolSelectionActionSheet showInView:[weakSelf view]];
        
//        [[weakSelf view] deselectRowAtIndexPath:indexPath animated:YES];
        
   };
}

//点击选中
- (IBAction)showAction:(id)sender {
    CGPoint p = [(UIButton *)sender center];
    
    // 如果没有检查到外设，关闭列表打开提示
    if ([_accessoryList count] == 0) {
        [self presentViewController:_alert animated:YES completion:nil];
        [self.popView hide:YES];
    } else {
        [self.popView hide:NO];
        [self.tempArray removeAllObjects];
        // --------************------------
        for (EAAccessory *dis in self.accessoryList) {
            [self.tempArray addObject:dis.name];
        }
        // --------************------------
        self.popView.selections = self.tempArray;
    }

    [self.popView showFromView:self.view atPoint:p animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// 手势
- (IBAction)tap:(UITapGestureRecognizer *)sender {
    [self.popView hide:YES];
}
// 手势回收
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.view];
    if (self.popView.visible && CGRectContainsPoint(self.popView.frame, p)) {
        return NO;
    }
    return YES;
}

#pragma mark -- 接收蓝牙的data数据
- (void)_sessionDataReceived:(NSNotification *)notification
{
    EADSessionController *sessionController = (EADSessionController *)[notification object];
    uint32_t bytesAvailable = 0;
    
    while ((bytesAvailable = (unsigned)[sessionController readBytesAvailable]) > 0) {
        NSData *data = [sessionController readData:bytesAvailable];
        if (data) {
            _totalBytesRead += bytesAvailable;
            
            // 创建文件管理器
            NSFileManager *fm = [NSFileManager defaultManager];
            
            NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString * folderPath = [documentPath stringByAppendingString:@"/record/"];
            // 新建文件夹
            [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSString *urlStr = [folderPath stringByAppendingPathComponent:@"1.mp3"];
            self.filePath = [folderPath stringByAppendingPathComponent:@"循环.mp3"];
            //创建一个文件
            [fm createFileAtPath:urlStr contents:data attributes:nil];
            
            if (![fm fileExistsAtPath:_filePath]) {
                //创建一个需要写入的文件
                [fm createFileAtPath:_filePath contents:nil attributes:nil];
            };
            
//                        [fm removeItemAtPath:folderPath error:nil];
//                        [fm removeItemAtPath:_filePath error:nil];
            
            //读取文件
            self.inFile = [NSFileHandle fileHandleForReadingAtPath:urlStr];
            //写入文件
            self.outFile = [NSFileHandle fileHandleForWritingAtPath:_filePath];
            
            if(_inFile != nil) {
                //将偏移量设置为文件的末尾
                [_outFile seekToEndOfFile];
                //写入数据
                [_outFile writeData:data];
                
                //验证内容
                NSLog(@"inFile:%@",_inFile);
                NSLog(@"outFile:%@",_outFile);
                
                //关闭所有
                [_outFile closeFile];
                [_inFile closeFile];
            
            }
            NSLog(@"data:%@",data);
        }
#pragma mark -- 传入data为空时，提示
//        else {
//            
//            //创建alert
//            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Receive the data is empty, please try to connect the accessory" message:nil preferredStyle:(UIAlertControllerStyleAlert)];
//            
//            // 确定点击事件
//            UIAlertAction *yes = [UIAlertAction actionWithTitle:@"default" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
//                return;
//            }];
//           
//            [alert addAction:yes];
//           
//            [self presentViewController:alert animated:YES completion:nil];
//            
//        }
    }
    NSLog(@"收到的数据:%d",_totalBytesRead);
}

// 录制
- (IBAction)btn4singleSing:(UIButton *)sender {
#pragma mark -- 不连接外设时，设置提示，连接才可以录制
//    if (_selectedAccessory == nil) {
//        [self presentViewController:_alert animated:YES completion:nil];
//        [self.popView hide:YES];
//    } else {
//        [self.popView hide:NO];
        if (_isRecording == NO) {
            
            _isRecording = YES;
            
            [self.btn4recordOrPause setImage:[UIImage imageNamed:@"录制暂停"] forState:UIControlStateNormal];
            
            // 计时器
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
            
            // 点击协议后，点击录制按钮，观察者监测data数据
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sessionDataReceived:) name:EADSessionDataReceivedNotification object:nil];
            
            EADSessionController *sessionController = [EADSessionController sharedController];
            
            _selectedAccessory = [sessionController accessory];
            [self setTitle:[sessionController protocolString]];
            [sessionController openSession];
            
        } else if (_isRecording == YES) {
            _isRecording = NO;
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:EADSessionDataReceivedNotification object:nil];
            
            EADSessionController *sessionController = [EADSessionController sharedController];
            
            [sessionController closeSession];
            
            _selectedAccessory = nil;
            
            [self.btn4recordOrPause setImage:[UIImage imageNamed:@"录制"] forState:UIControlStateNormal];
            
            // 关闭计时器
            [self.timer invalidate];
            
            // 弹出alert
            [self setAlert];
        }

//    }
    
}

- (void)setAlert {
    //创建alert
    UIAlertController *recordAlert = [UIAlertController alertControllerWithTitle:@"Complete recording？" message:nil preferredStyle:(UIAlertControllerStyleAlert)];
    
    // 添加文本框输入，以名字对话框示例
    [recordAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"录音名字";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertTextFieldDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
    }];
    
    // 确定点击事件
    UIAlertAction *yes = [UIAlertAction actionWithTitle:@"default" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
 
        if (_filePath != nil) {
            // 移动文件（重命名）
            NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString * folderPath = [documentPath stringByAppendingString:@"/record/"];
            NSString *urlStr1 = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3",_tf.text]];
            
            // 创建文件管理器
            NSFileManager *fm = [NSFileManager defaultManager];
            
            [fm createDirectoryAtPath:[urlStr1 stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            NSError *error;
            BOOL isSuccess = [fm moveItemAtPath:_filePath toPath:urlStr1 error:&error];
            if (isSuccess) {
                NSLog(@"成功");
            }

        }
        
        // 确定保存录音，清空label时间和大小，下次录制时间和大小从0开始，取消等其他操作不做处理，可以继续录音
        self.time = 0.00;
        self.timestr = [NSString stringWithFormat:@"00:00.00"];
        [self.lab4timer setText:_timestr];
        
    }];
    UIAlertAction *no = [UIAlertAction actionWithTitle:@"cancel" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
#pragma mark --- 取消之后清空此次录制内容，没有作用暂时（可以尝试data清空）
//        _outFile = nil;
        return;
    }];
    [recordAlert addAction:yes];
    [recordAlert addAction:no];
    [self presentViewController:recordAlert animated:YES completion:nil];

}

// 计时器调用方法
- (float) updateTime{
    self.time += 0.1;
    self.timestr = [NSString stringWithFormat:@"%02d:%04.2f",(int)(_time / 60) ,_time - ( 60 * (int)( _time / 60 ) )];
    
    [self.lab4timer setText:_timestr];
    return _time;
}

- (void)alertTextFieldDidChange:(NSNotification *)notification{
    
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    
    if (alertController) {
        // tf 添加监听事件
        self.tf = alertController.textFields[0];
        // 如果输入名字确定按钮才显示
        UIAlertAction *action = alertController.actions.lastObject;
        action.enabled = _tf.text.length != 0;
        
    }
}

// 退出录制
- (IBAction)btn4comRecording:(UIButton *)sender {
    
    // 退出时暂停播放
    [[RecordManager sharedManager] pause];
    
    // 返回
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
