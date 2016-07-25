//
//  MainPageVC.m
//  Music
//
//  Created by admin on 16/3/22.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "MainPageVC.h"
#import "MainPageCell.h"
#import "MySongCell.h"
#import "RecordingVC.h"
#import "PlayingVC.h"
#import "SongModel.h"
#import "RecordModel.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MJRefresh.h"

@interface MainPageVC ()<UITableViewDelegate,UITableViewDataSource,MPMediaPickerControllerDelegate,UISearchBarDelegate,AVAudioPlayerDelegate>

// 清唱按钮
- (IBAction)singleSong:(id)sender;
// 编辑按钮
- (IBAction)editAction:(UIBarButtonItem *)sender;

// 多选（暂未使用）
@property (nonatomic,strong) NSMutableDictionary *selectedDic;

// segment分组选择按钮
@property (weak, nonatomic) IBOutlet UISegmentedControl *selectSegCon;
// tableView表格
@property (weak, nonatomic) IBOutlet UITableView *tableView;

/*
 * 播放
 */
// 播放器
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
// 判断播放状态
@property (nonatomic, assign) BOOL isPlaying;
// 替代按钮
@property (nonatomic, strong) UIButton *playOrPause;
// 计数器
@property (nonatomic, retain) NSTimer *timer;
// 进度条value
@property (nonatomic, assign) float sliderValue;
@property (nonatomic, assign) float sliderMaxValue;
// 播放时间
@property (nonatomic, strong) NSString *playTime;
// 正在播放的model
@property (nonatomic, strong) RecordModel *currentModel;

/*
 * 搜索
 */
// 搜索框
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
// 搜索框的高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeight;
// 存放搜索结果
@property (nonatomic, retain) NSMutableArray *searchResult;
// 本地歌曲名字数组
@property (nonatomic ,strong) NSMutableArray *localNameArray;
// 存放搜索出的歌曲的详细信息
@property (nonatomic, strong) NSMutableArray *searchArray;
// 判断标志：显示不同cell
@property (nonatomic, assign) NSInteger number;
// bool判断searchBar状态
@property (nonatomic, assign) BOOL searchEdit;

/*
 * 录音
 */
// 本地歌曲数组
@property (nonatomic ,strong) NSMutableArray * songArray;
// 录制文件数组
@property (nonatomic ,strong) NSMutableArray *recordArray;
// 本地音乐model
@property (nonatomic ,strong) SongModel *model;
// 当前录制的文件路径
@property (nonatomic, strong) NSString *currentFilePath;

/*
 * cell伸缩
 */
// 监听cell状态
@property (nonatomic, assign) BOOL isOpen;
// 记录选择cell的row
@property (nonatomic, strong) NSIndexPath *selectedIndex;

@end

@implementation MainPageVC

- (void)viewWillAppear:(BOOL)animated {
    // 取消选中
    NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
    if(selected) [self.tableView deselectRowAtIndexPath:selected animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isPlaying = NO;
    
    // 隐藏搜索框，高度设为0
    self.searchBar.hidden = YES;
    self.searchBarHeight.constant = 0;
    
    // 脚视图设为空，正常数据下面就没有多余cell啦
    self.tableView.tableFooterView = [UIView new];
    
    // 本地音乐的布局
    [self localMusicBuildUI];
    
    // 读取我的演唱
    [self readFile];
    
    // 控制分类按钮
    [self segmentUI];
    
    // 本地音乐cell注册
    [self.tableView registerNib:[UINib nibWithNibName:@"MainPageCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"localCell"];
    // 我的录音注册
    [self.tableView registerNib:[UINib nibWithNibName:@"MySongCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"myCell"];
    
    // 刷新
    [self addRefreshAndLoad];
    
    // 搜索时更新(代理)
    self.searchBar.delegate = self;
    
    // 创建编辑按钮
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    // 让UITableView的内容从UINavigation Bar下面开始，并且这个页面的View占据整个屏幕
    self.automaticallyAdjustsScrollViewInsets = YES;
    
}

// segment布局
- (void)segmentUI {
    
    [self.selectSegCon addTarget:self action:@selector(changeArray:) forControlEvents:(UIControlEventValueChanged)];
    self.selectSegCon.tintColor = [UIColor clearColor];
    // 下面的代码实同正常状态和按下状态的属性控制,比如字体的大小和颜色等
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor darkGrayColor], NSForegroundColorAttributeName, nil];//[UIFont boldSystemFontOfSize:12],NSFontAttributeName
    [self.selectSegCon setTitleTextAttributes:attributes forState:UIControlStateNormal];
    NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObject:[UIColor blueColor] forKey:NSForegroundColorAttributeName];
    [self.selectSegCon setTitleTextAttributes:highlightedAttributes forState:UIControlStateSelected];
}

#pragma mark -- segment点击事件
-(void)changeArray:(UISegmentedControl *)sender{
    if (self.selectSegCon.selectedSegmentIndex == 0) {
        self.number = 0;
//        self.searchBarHeight.constant = 44;
    } else {
        [self readFile];
//        [self.tableView.mj_header beginRefreshing];
        self.searchBarHeight.constant = 0;
        self.number = 1;
    }
    [self.tableView reloadData];
}

// 本地音乐的布局
- (void)localMusicBuildUI {
    
    // 从ipod库中读出音乐文件
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    // 读取条件
    MPMediaPropertyPredicate *albumNamePredicate =
    [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic] forProperty: MPMediaItemPropertyMediaType];
    [everything addFilterPredicate:albumNamePredicate];
    
    NSArray *itemsFromGenericQuery = [everything items];
    
    // 移除原来的信息
    if (self.songArray.count) {
        [self.songArray removeAllObjects];
    }
    
    for (MPMediaItem *song in itemsFromGenericQuery) {
        
        //1、创建SongModel
        //2. 使用点语法拿到
        //3. 每一次遍历赋值后，将model放进数组中
        
        self.model = [SongModel new];
        
        // 歌名
        self.model.songName = song.title;
        
        [self.localNameArray addObject:song.title];
        
        // 时长
        NSInteger minute = (int)song.playbackDuration / 60;
        NSInteger seconds = (int)song.playbackDuration % 60;
        self.model.songTime = [NSString stringWithFormat:@"%.2ld:%.2ld",(long)minute,(long)seconds];
        
        // 网址
        NSURL *url = song.assetURL;
        self.model.mp3Url = [url absoluteString];
        
//        NSLog(@"网址:%@",self.model.mp3Url);
        
        self.model.lyricContext  = [song valueForProperty:MPMediaItemPropertyLyrics];
        
        [self.songArray addObject:self.model];
    }
}
// 读取我的演唱
- (void)readFile {
    // 刷新
    [self.tableView reloadData];
    
    // 文件夹路径
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    NSString * folderPath = [documentPath stringByAppendingString:@"/record"];
    
    // 沙盒数组
    NSArray *fileList;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    fileList =[fileManager contentsOfDirectoryAtPath:folderPath error:NULL];
    
    // 移除原来信息
    if (self.recordArray.count) {
        [self.recordArray removeAllObjects];
    }

    // 遍历沙盒数组，获取沙盒音乐文件
    for (NSString *file in fileList) {
        
        // 1.mp3每次读取的字节数，过滤掉
        if ([file isEqualToString:@"1.mp3"]) {
            continue;
        }
        
        self.currentFilePath = [folderPath stringByAppendingPathComponent:file];
//        NSLog(@"currentFilePath:%@",_currentFilePath);
        
        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:_currentFilePath error:&error];
        
        if (fileAttributes != nil) {
           
            // 文件大小
            NSNumber *fileByte = [fileAttributes objectForKey:NSFileSize];
            NSInteger fileSize = [fileByte integerValue] / 1024;
        
            // 录制日期
            NSDate *fileCreateDate = [fileAttributes objectForKey:NSFileCreationDate];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"YY/MM/dd hh:mm:ss"];
            
            // 总时间
            NSURL *url = [NSURL fileURLWithPath:_currentFilePath];
            AVURLAsset *avUrl = [AVURLAsset assetWithURL:url];
            CMTime time = [avUrl duration];
            int seconds = ceil(time.value/time.timescale);
            NSString *timeStr = [NSString stringWithFormat:@"%.2d:%.2ds",seconds/60,seconds%60];
//            NSLog(@"时间:%d",seconds);
            
            // 改变进度条的最大值
            NSRange minuteRange = NSMakeRange(1, 1);
            NSString *minuteStr = [timeStr substringWithRange:minuteRange];
            NSRange secondRange = NSMakeRange(3, 2);
            NSString *secondStr = [timeStr substringWithRange:secondRange];
            self.sliderMaxValue = [minuteStr integerValue] * 60 + [secondStr integerValue];
//            NSLog(@"max:%f",self.sliderMaxValue);
            
            
            RecordModel *recordModel = [RecordModel new];
            recordModel.recordName = file;
            recordModel.recordSize = [NSString stringWithFormat:@"%ldKB",(long)fileSize];
            recordModel.recordDate = [dateFormatter stringFromDate:fileCreateDate];
            recordModel.recordUrl = _currentFilePath;
            recordModel.recordTime = timeStr;
            recordModel.playTime = @"00:00";
            recordModel.slidermaxValue = self.sliderMaxValue;
            [self.recordArray addObject:recordModel];
        }
        else {
            NSLog(@"Path (%@) is invalid.", _currentFilePath);
        }
        
    }
}

#pragma mark -- 方法：下拉刷新 上拉加载
- (void)addRefreshAndLoad{
    // 下拉刷新
    __unsafe_unretained UITableView *tableView = self.tableView;
    
    tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        
        // 刷新时在第一个segment页显示搜索框
        self.searchBar.hidden = NO;
        if (self.selectSegCon.selectedSegmentIndex == 0) {
            self.number = 0;
            self.searchBarHeight.constant = 44;
        }
        
        // 刷新时读取数据
        [self readFile];
        
        NSLog(@"重新读取数据");
        
        // 模拟延迟加载数据，因此2秒后才调用
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 结束刷新
            [tableView.mj_header endRefreshing];
        });
    }];
    // 设置自动切换透明度(在导航栏下面自动隐藏)
    tableView.mj_header.automaticallyChangeAlpha = YES;
}

#pragma mark -- UISearchBarDelegate
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{// 开始编辑时触发
    self.searchBar.showsCancelButton = YES;
    self.searchEdit = YES;
}
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{// 按下取消按钮时触发
    self.searchBar.showsCancelButton = NO;
    self.searchEdit = NO;
    [self.searchBar resignFirstResponder];
    [self.tableView reloadData];
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{//搜索框中的内容发生改变时 回调（即要搜索的内容改变）
    NSLog(@"changed");
    self.searchEdit = YES;
    if (_searchBar.text.length == 0) {
        return;
    }else{
        [self.searchResult removeAllObjects];
        [self.searchArray removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self contains[cd]%@",self.searchBar.text];
        self.searchResult = [NSMutableArray arrayWithArray:[self.localNameArray filteredArrayUsingPredicate:predicate]];
        
        for (NSString *str in self.searchResult) {
            for (SongModel *model in self.songArray) {
                if ([model.songName isEqualToString:str]) {
                    [self.searchArray addObject:model];
                    continue;
                }
            }
        }
        [self.tableView reloadData];
        
    }
}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{// 按下小键盘搜索按钮时触发
    self.searchBar.showsCancelButton = NO;
    self.searchEdit = YES;
    [self.searchBar resignFirstResponder];
    [self.tableView reloadData];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.number == 0) {
        
        if (self.searchEdit == YES) {
            return self.searchArray.count;
        } else {
            return self.songArray.count;
        }
    }
    return _recordArray.count;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.number == 0) {
        MainPageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"localCell" forIndexPath:indexPath];
        
        if (self.searchEdit == YES) { // 搜索状态
            if (_searchArray.count) {
                SongModel *model = self.searchArray[indexPath.row];
                [cell setModel:model];
            }
        } else {
            if (_songArray.count) {
                SongModel *model = self.songArray[indexPath.row];
                [cell setModel:model];
            }
        }
        
        // cell无选中灰色
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        // 点击录制按钮，跳转到录制界面
        cell.myBlock = ^() {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            RecordingVC *recording = [storyboard instantiateViewControllerWithIdentifier:@"recording"];
            recording.index = indexPath.row;
            if (self.searchEdit == YES) {
                recording.dataArray = self.searchArray;
            } else {
                recording.dataArray = self.songArray;
            }
            
            [self showDetailViewController:recording sender:nil];
        };
        return cell;
        
    } else {
        MySongCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCell" forIndexPath:indexPath];
        // cell无选中灰色
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
//        __weak typeof(cell) weakSelf = cell;
        // 点击播放按钮 -- 播放回调
        cell.playBlock = ^(NSString *musicUrl,RecordModel *recordModel,float sliderValue,float slidermaxValue) {
            if (_currentFilePath != nil) {
        
                self.currentModel = recordModel;
//                NSLog(@"当前model:%@",self.currentModel);
                self.sliderValue = sliderValue;
                self.sliderMaxValue = slidermaxValue;
                
                if (_isPlaying == NO) {
                    _isPlaying = YES;
                    [self.playOrPause setImage:[UIImage imageNamed:@"小播放"] forState:UIControlStateNormal];
                    AVAudioSession *session = [AVAudioSession sharedInstance];
                    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
                    [session setActive:YES error:nil];
                    
                    NSError *error=nil;
                    // 1.url播放
                    NSURL *url = [NSURL fileURLWithPath:musicUrl];
                    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
                    _audioPlayer.delegate = self;
                    _audioPlayer.numberOfLoops=0;
                    _audioPlayer.volume = 1.0;
                    [_audioPlayer prepareToPlay];
                    if (error) {
                        NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
                        return;
                    }
                    [_audioPlayer play];
                    
//                    self.progressSlider.maximumValue = _audioPlayer.duration;
//                    NSLog(@"max:%f",self.progressSlider.maximumValue);
                    
                    //用NSTimer来监控音频播放进度
                    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playProgress) userInfo:nil repeats:YES];
                    
                } else if (_isPlaying == YES) {
                    _isPlaying = NO;
                    [self.playOrPause setImage:[UIImage imageNamed:@"小暂停"] forState:UIControlStateNormal];
                    [_audioPlayer pause];
                    [self.timer invalidate];
                }
            }
        };
        
        // slider事件 -- 回调
        __weak typeof (cell)sliderSelf = cell;
        cell.sliderBlock = ^() {

            UISlider *slider = sliderSelf.timeSlider;

            [_audioPlayer stop];
            
            [_audioPlayer setCurrentTime:slider.value];
            
            [_audioPlayer prepareToPlay];
            
            [_audioPlayer play];
        };
    
        // cell伸展
        if (indexPath.row == _selectedIndex.row && _selectedIndex != nil) {
    
            if (_isOpen == YES) {//如果是展开
                if (_recordArray.count) {
                    RecordModel *model =  self.recordArray[_selectedIndex.row];
                    
                    cell.playTimeLabel.text = nil;
                    cell.totalLabelHeight.constant = 50;
                    cell.playTimeLabel.hidden = NO;
                    cell.lastTimeLabel.hidden = NO;
                    cell.timeSlider.hidden = NO;
                    cell.btn4play.hidden = NO;
                    
                    self.playOrPause = cell.btn4play;
                    
                    // 刚伸展未播放的时候置空
                    model.playTime = @"00:00";
                    model.sliderValue = 0;
                    
                    // 播放block
                    __weak typeof (self)playSelf = self;
                    self.timeBlock = ^(NSString *playTime,float sliderTime) {
                        
//                        NSLog(@"slider:%f",sliderTime);
                        
                        if (self.currentModel == model) {
                            [playSelf.playOrPause setImage:[UIImage imageNamed:@"小播放"] forState:UIControlStateNormal];
                            playSelf.currentModel.playTime = playTime;
                            playSelf.currentModel.sliderValue = sliderTime;
                            
//                            NSLog(@"播放:%@",playSelf.currentModel.playTime);
                            [cell setModel:playSelf.currentModel];
                        } else {
                            [playSelf.playOrPause setImage:[UIImage imageNamed:@"小暂停"] forState:UIControlStateNormal];
                            model.playTime = @"00:00";
                            model.sliderValue = 0;
                            [cell setModel:model];
                        }
                    };
                    // 置空block
                    self.nilBlock = ^(NSString *playTime,float sliderTime) {
                        model.playTime = @"00:00";
                        model.sliderValue = 0;
                        [cell setModel:model];
                    };
                    [cell setModel:model];
                    
                }
                _isOpen = YES;
            } else {//收起
                
                if (_recordArray.count) {
                    RecordModel *model =  self.recordArray[_selectedIndex.row];
                    cell.totalLabelHeight.constant = 0;
                    cell.playTimeLabel.hidden = YES;
                    cell.lastTimeLabel.hidden = YES;
                    cell.timeSlider.hidden = YES;
                    cell.btn4play.hidden = YES;
                    [cell setModel:model];
                }
                _isOpen = NO;
            }
        } else {//不是自身
            if (_recordArray.count) {
                RecordModel *model =  self.recordArray[indexPath.row];
                cell.totalLabelHeight.constant = 0;
                cell.playTimeLabel.hidden = YES;
                cell.lastTimeLabel.hidden = YES;
                cell.timeSlider.hidden = YES;
                cell.btn4play.hidden = YES;
                [cell setModel:model];
            }
            _isOpen = NO;
            
        }
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView reloadData];
    
    if (self.number == 0) {
        // 跳转到播放页面
        PlayingVC *play = [PlayingVC sharedPlayingVC];
        play.index = indexPath.row;  // 传下标过去
        if (self.searchEdit == YES) {
            play.dataArray = self.searchArray;
        } else {
            play.dataArray = self.songArray;
        }
        [self showDetailViewController:play sender:nil];
    } else {
        
        // ------------ 增加一项 -------------
//        if (self.tableView.editing) {
//            [self.selectedDic setObject:indexPath forKey:self.recordArray[indexPath.row]];
//        }
        
        //将索引加到数组中
        NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
        
        if (_selectedIndex != nil && indexPath.row == _selectedIndex.row) {
            _isOpen = !_isOpen;
        } else if (_selectedIndex != nil && indexPath.row != _selectedIndex.row) {
            //将选中的和所有索引都加进数组中
            indexPaths = [NSArray arrayWithObjects:indexPath, _selectedIndex,nil];
            _isOpen = YES;
        }
        
        //记下选中的索引
        _selectedIndex = indexPath;
        
        //刷新
        [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        
    }
    
}
//返回每行的高度
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.number == 1) {
       
        if (_selectedIndex != nil && indexPath.row == _selectedIndex.row) {
            
            if (self.isOpen == YES) {
                return 110;
            } else {
                return 50;
            }
        } else {
            return 50;
        }
    }
    return 80;
}

#pragma mark - lazyLoad
- (NSMutableArray *)songArray {
    if (!_songArray) {
        _songArray = [NSMutableArray array];
    }
    return _songArray;
}
- (NSMutableArray *)recordArray {
    if (!_recordArray) {
        _recordArray = [NSMutableArray array];
    }
    return _recordArray;
}
- (NSMutableDictionary *)selectedDic {
    if (_selectedDic == nil) {
        _selectedDic = [[NSMutableDictionary alloc]init];
    }
    return _selectedDic;
}
- (NSMutableArray *)localNameArray {
    if (!_localNameArray) {
        _localNameArray = [NSMutableArray array];
    }
    return _localNameArray;
}
- (NSMutableArray *)searchArray {
    if (!_searchArray) {
        _searchArray = [NSMutableArray array];
    }
    return _searchArray;
}
- (AVAudioPlayer *)audioPlayer {
    if (!_audioPlayer) {
        _audioPlayer = [AVAudioPlayer new];
    }
    return _audioPlayer;
}

#pragma mark --cell自定义滚动操作（删除和分享一起实现）
/*
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (self.number == 1) {
        // 向父类发送消息
        [super setEditing:editing animated:animated];
        // 在OC里面，重写父类的方法，必须先向父类发送super消息，尤其是系统的类
        [self.tableView setEditing:editing animated:animated];
        
        // 编辑按钮的文字 “编辑” “完成”
        self.navigationItem.rightBarButtonItem.title = editing?@"Done":@"Edit";
    } else {
        return;
    }
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
}  // iOS8新增的，写它才能实现增加删除，里面不用写方法
 */

/*
//编辑样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

//取消一项
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        [self.selectedDic removeObjectForKey:self.recordArray[indexPath.row]];
    }
}
//删除员工
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row <= [self.recordArray count]) {
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
}
 */

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_selectSegCon.selectedSegmentIndex == 0) {
        return NO;
    }
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.number == 1) {
        
        UITableViewRowAction *action1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"删除");
            
            // 获取删除的对象
            RecordModel *model = [_recordArray objectAtIndex:indexPath.row];  // 增加生命周期
            
            // 删除沙盒数据
            // 1.获取model沙盒路径
            NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
            NSString * folderPath = [documentPath stringByAppendingString:@"/record"];
            NSString *ss = [NSString stringWithFormat:@"/%@",model.recordName];
            NSString *currentPath = [folderPath stringByAppendingString:ss];
            // 2.在沙盒中移除这个路径
            NSFileManager *fM = [NSFileManager defaultManager];
            [fM removeItemAtPath:currentPath error:nil];
            
            // 删除cell显示数据
            [_recordArray removeObjectAtIndex:indexPath.row];
            
            // 更新UI --行
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
        }];
        UITableViewRowAction *action2 = [UITableViewRowAction rowActionWithStyle:(UITableViewRowActionStyleDestructive) title:@"分享" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"分享");
            
            // 获取分享model
            RecordModel *model = [_recordArray objectAtIndex:indexPath.row];  // 增加生命周期
            // 首先初始化activityItems参数
            NSString *name = model.recordName;
            UIImage *image = [UIImage imageNamed:@"cell"];
            NSArray *activityItems = @[name, image];
            
            // 初始化一个UIActivityViewController
            UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:Nil];
            
            // 写一个bolck，用于completionHandler的初始化
            UIActivityViewControllerCompletionWithItemsHandler myBlock = ^(NSString * __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError) {
                
                NSLog(@"%@", activityType);
                if(completed) {
                    NSLog(@"completed");
                } else {
                    NSLog(@"cancled");
                }
                [activityVC dismissViewControllerAnimated:YES completion:Nil];
            };
            
            // 初始化completionHandler，当post结束之后（无论是done还是cancel）该blog都会被调用
            activityVC.completionWithItemsHandler = myBlock;
            
            // 以模态方式展现出UIActivityViewController
            [self presentViewController:activityVC animated:YES completion:Nil];
            
        }];
        return @[action1, action2];
        
    }
    return nil;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// 点击清唱，进入录制页面
- (IBAction)singleSong:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RecordingVC *recording = [storyboard instantiateViewControllerWithIdentifier:@"recording"];
    NSMutableArray *array = [NSMutableArray array];
    recording.dataArray = array;
    [self showDetailViewController:recording sender:nil];
    
}

// 点击tableView多选删除
- (IBAction)editAction:(UIBarButtonItem *)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    if (self.tableView.editing) {
        [self.navigationItem.rightBarButtonItem setTitle:@"delete"];
    }
    else{
        [self.navigationItem.rightBarButtonItem setTitle:@"edit"];
        if (self.selectedDic.count>0) {
            NSArray *array = [self.selectedDic allKeys];
            [self.recordArray removeObjectsInArray:array];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithArray:[self.selectedDic allValues]] withRowAnimation:UITableViewRowAnimationFade];
            
            [self.selectedDic removeAllObjects];
        }
    }
    
}

#pragma mark -- 播放

//播放进度条
- (void)playProgress {

    self.sliderValue = _audioPlayer.currentTime;
//    NSLog(@"value:%f",self.progressSlider.value);
    
    NSInteger minute = _audioPlayer.currentTime / 60;
    NSInteger second = (int)_audioPlayer.currentTime % 60;
    // 播放时间
    self.playTime = [NSString stringWithFormat:@"%.2ld:%.2ld",(long)minute,(long)second];
    // 回调
    self.timeBlock(self.playTime,self.sliderValue);

}

//播放完成时调用的方法  (代理里的方法),需要设置代理才可以调用
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self.playOrPause setImage:[UIImage imageNamed:@"小暂停"] forState:UIControlStateNormal];
    [self.timer invalidate];
    self.nilBlock(self.playTime,self.sliderValue);
    
}

@end
