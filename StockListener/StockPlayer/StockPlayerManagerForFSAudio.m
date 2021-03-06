//
//  StockPlayerManager.m
//  StockListener
//
//  Created by Guozhen Li on 11/29/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockPlayerManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "FSAudioStream.h"
#import "FSAudioController.h"
#import "FSPlaylistItem.h"
#import "StockInfo.h"
#import "StockRefresher.h"
#import "DatabaseHelper.h"

#define UP_SOUND @"up.mp3"
#define DOWN_SOUND @"down.mp3"
#define MUSIC_SOUND @"test.mp3"

#define SPEACH_COUNTER 6

//#define NSLog(a)
#if 0

@interface StockPlayerManager() {
    int _currentPlayIndex;
    BOOL _continueRefresh;
    int speachCounter;
}

@property (nonatomic,strong) FSAudioController *audioController;
@property (nonatomic,strong) FSAudioController *musicController;
@property (nonatomic,strong) AVSpeechSynthesizer *speechPlayer;
@property (nonatomic,strong) NSString *currentPlaySID;
@property (atomic,strong) NSMutableArray* playList;
@property (nonatomic,assign) BOOL musicPaused;
@property (nonatomic,assign) BOOL nowSpeaking;

@end

@implementation StockPlayerManager

- (id) init {
    if (self = [super init]) {
        _currentPlayIndex = 0;
        _continueRefresh = NO;
        _configuration = [[FSStreamConfiguration alloc] init];
        _configuration.usePrebufferSizeCalculationInSeconds = YES;
        self.playList =[[NSMutableArray alloc] init];
        self.musicPaused = NO;
        self.nowSpeaking = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onStockValueRefreshed)
                                                     name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                                   object:nil];
        speachCounter = 0;
    }
    return self;
}

/*
 * =======================================
 * Observer
 * =======================================
 */

- (void)onStockValueRefreshed {
    if ([[DatabaseHelper getInstance].stockList count] == 0) {
        return;
    }
    if (_continueRefresh == NO) {
        return;
    }
    if (_nowSpeaking == YES) {
        return;
    }
    if ([self.playList count] > 0) {
        [self.playList removeAllObjects];
        return;
    }
    
    StockInfo* info = [[DatabaseHelper getInstance] getInfoById:_currentPlaySID];
    if (info == nil) {
        [self pause];
        return;
    }

    float value = info.changeRate * 100;
    [self setLockScreenTitle:[NSString stringWithFormat:@"%@  %@ (%.2f%%)", info.name, [self valueToStr:info.price], value] andTime:info.updateTime andRate:info.changeRate];

    speachCounter++;
    if (speachCounter == SPEACH_COUNTER) {
        [self stockSpeachFired];
        return;
    }
    
    if (info.speed > 0) {
        [self playStockValueUp:info.step];
    } else if (info.speed < 0) {
        [self playStockValueDown:info.step];
    } else {
        [self playMusic];
    }
}

/*
 * =======================================
 * Controllers getter
 * =======================================
 */
- (FSAudioController *)audioController
{
    if (!_audioController) {
        _audioController = [[FSAudioController alloc] init];
        _audioController.delegate = self;
        self.audioController.configuration = _configuration;
        __weak StockPlayerManager *weakSelf = self;
        [weakSelf.audioController setVolume:1];
        _audioController.onStateChange = ^(FSAudioStreamState state) {
            switch (state) {
                case kFsAudioStreamPlaybackCompleted:{
                    dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Stock play completed");
                        [weakSelf playStockSound];
                    });
                    break;
                }
                default:
                    break;
            }
        };
    }
    return _audioController;
}

- (FSAudioController *)musicController
{
    if (!_musicController) {
        _musicController = [[FSAudioController alloc] init];
        _musicController.delegate = self;
        self.musicController.configuration = _configuration;
        self.musicController.url = [self parseLocalFileUrl:[NSString stringWithFormat:@"file://%@", MUSIC_SOUND ]];
        [self.musicController setVolume:0.3];
        __weak StockPlayerManager *weakSelf = self;
        _musicController.onStateChange = ^(FSAudioStreamState state) {
            switch (state) {
                case kFsAudioStreamPlaybackCompleted:{
                    dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Play music completed");
                    [weakSelf playMusic];
                    });
                    break;
                }
                default:
                    break;
            }
        };
    }
    return _musicController;
}

- (AVSpeechSynthesizer *)speechPlayer
{
    if (!_speechPlayer) {
        _speechPlayer = [[AVSpeechSynthesizer alloc] init];
        _speechPlayer.delegate = self;
    }
    return _speechPlayer;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"didFinishSpeech");
    speachCounter = 0;
    _nowSpeaking = NO;
    [self playMusic];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"didPauseSpeach");
    speachCounter = 0;
    _nowSpeaking = NO;
    [self playMusic];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"didCancelSpeach");
    speachCounter = 0;
    _nowSpeaking = NO;
    [self playMusic];
}

/*
 * =======================================
 * Delegate
 * =======================================
 */
- (BOOL)audioController:(FSAudioController *)audioController allowPreloadingForStream:(FSAudioStream *)stream
{
    // We could do some fine-grained control here depending on the connectivity status, for example.
    // Allow all preloads for now.
    return YES;
}

- (void)audioController:(FSAudioController *)audioController preloadStartedForStream:(FSAudioStream *)stream
{
    // Should we display the preloading status somehow?
}

/*
 * =======================================
 * Private
 * =======================================
 */

- (NSString*) valueToStr:(float)value {
    NSString* str = [NSString stringWithFormat:@"%.3f", value];
    int index = (int)[str length] - 1;
    for (; index >= 0; index--) {
        char c = [str characterAtIndex:index];
        if (c !='0') {
            break;
        }
    }
    if (index <= 0) {
        return @"0";
    }
    if ([str characterAtIndex:index] == '.') {
        index--;
    }
    if (index <= 0) {
        return @"0";
    }
    str = [str substringToIndex:index+1];
    return str;
}

-(void) playStockValueUp: (int)step {
    for (int i=0; i<step; i++) {
        [self.playList addObject:[NSString stringWithFormat:@"file://%@", UP_SOUND ]];
    }
    [self playStockSound];
}

-(void) playStockValueDown: (int)step {
    for (int i=0; i<step; i++) {
        [self.playList addObject:[NSString stringWithFormat:@"file://%@", DOWN_SOUND ]];
    }
    [self playStockSound];
}

- (void)speak: (NSString*)str {
    [self pauseMusic];
    AVSpeechUtterance* u=[[AVSpeechUtterance alloc]initWithString:str];
    u.voice=[AVSpeechSynthesisVoice voiceWithLanguage:@"zh-TW"];
    _nowSpeaking = YES;
    [self.speechPlayer speakUtterance:u];
}

- (void) setLockScreenTitle:(NSString*) str andTime:(NSString*)time andRate:(float)rate {
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    songInfo[MPMediaItemPropertyTitle] = str;
    songInfo[MPMediaItemPropertyArtist] = time;
    int value = rate * 1000 + 100;
//    NSLog(@"rate=%f value = %d", rate, value);
    [songInfo setObject:[NSNumber numberWithFloat:200] forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:[NSNumber numberWithFloat:value] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [songInfo setObject:[NSNumber numberWithFloat:0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

- (NSURL *)parseLocalFileUrl:(NSString *)fileUrl
{
    // Resolve the local bundle URL
    NSString *path = [fileUrl substringFromIndex:7];
    
    NSRange range = [path rangeOfString:@"." options:NSBackwardsSearch];
    
    NSString *fileName = [path substringWithRange:NSMakeRange(0, range.location)];
    NSString *suffix = [path substringWithRange:NSMakeRange(range.location + 1, [path length] - [fileName length] - 1)];
    
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:fileName ofType:suffix]];
}

- (void) playStockSound {
    NSLog(@"PlayStock");
    if (!_continueRefresh) {
        NSLog(@"    Skip: !continueRefresh");
        NSLog(@"PlayStock Done");
        return;
    }
    if ([self.playList count] > 0) {
        NSString* url = [self.playList objectAtIndex:0];
        self.audioController.url = [self parseLocalFileUrl:url];
        [self pauseMusic];
        NSLog(@"    Play stock");
        [self.audioController play];
        [self.playList removeObjectAtIndex:0];
    } else {
        NSLog(@"    Complet: Play music");
        [self playMusic];
    }
    NSLog(@"PlayStock Done");
}

- (void) playMusic {
    NSLog(@"PlayMusic");
    if ([self.playList count] > 0) {
        NSLog(@"    Skip: playlist cout > 0");
        return;
    }
    if (!_continueRefresh) {
        NSLog(@"    !continueRefresh");
        return;
    }
//    [self.audioController stop];
    if (self.musicPaused) {
        NSLog(@"    music Paused: paly with pause()");
        [self.musicController pause];
        self.musicPaused = NO;
        return;
    }
    if (![self.musicController isPlaying]) {
        NSLog(@"    Play with play");
        [self.musicController play];
    }
    self.musicPaused = NO;
}

- (void) pauseMusic {
    if (!self.musicPaused && [self.musicController isPlaying]) {
        NSLog(@"Pause Music");
        [self.musicController pause];
        self.musicPaused = YES;
    }
}

- (void)stockSpeachFired {
    StockInfo* info = [[DatabaseHelper getInstance] getInfoById:_currentPlaySID];
    if (info == nil) {
        speachCounter = 0;
        _nowSpeaking = NO;
        [self playMusic];
        return;
    }
    
    float value = info.changeRate * 100;
    NSString* proceStr = [NSString stringWithFormat:@"%@, 百分之%.2f", [self valueToStr:info.price], value];
    [self speak:proceStr];
}

/*
 * =======================================
 * APIs
 * =======================================
 */
- (void) play {
    if ([[DatabaseHelper getInstance].stockList count] == 0) {
        _continueRefresh = false;
        return;
    }
    _continueRefresh = true;

    if (_currentPlayIndex < 0 || _currentPlayIndex >= [[DatabaseHelper getInstance].stockList count]) {
        _currentPlayIndex = 0;
    }
    StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:_currentPlayIndex];
    [self setCurrentPlaySID:info.sid];
    
    speachCounter = 0;
    _nowSpeaking = NO;
    
    [self playMusic];
    
    if (self.delegate) {
        [self.delegate onPlaying:info];
    }
}

-(void) pause {
    [self.playList removeAllObjects];
    _continueRefresh = false;
    [self pauseMusic];
    
    if (self.delegate) {
        [self.delegate onPLayPaused];
    }
}

-(BOOL) isPlaying {
    return _continueRefresh;
}

-(void) next {
    _currentPlayIndex++;
    if (_currentPlayIndex >= [[DatabaseHelper getInstance].stockList count]) {
        _currentPlayIndex = 0;
    }
    [self pause];
    [self play];
}

-(void) pre {
    _currentPlayIndex--;
    if (_currentPlayIndex < 0) {
        _currentPlayIndex = (int)[[DatabaseHelper getInstance].stockList count] -1;
    }
    [self pause];
    [self play];
}

-(void) playByIndex:(int)index {
    if (index < 0) {
        index = 0;
    }
    if (index >= [[DatabaseHelper getInstance].stockList count]) {
        index = 0;
    }
    _currentPlayIndex = index;
    [self pause];
    [self play];
}

@end
#endif