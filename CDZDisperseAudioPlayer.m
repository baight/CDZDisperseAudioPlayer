//
//  CDZDisperseAudioPlayer.m
//  
//
//  Created by baight on 15/9/17.
//  Copyright (c) 2013 baight. All rights reserved.
//

#import "CDZDisperseAudioPlayer.h"

#pragma mark - CDZAudioItem Category
@protocol CDZAudioItemDelegate <NSObject>
- (void) audioItemDidFinishPlay:(CDZAudioItem*)audioItem error:(NSError*)error;
@end


@interface CDZAudioItem ()<AVAudioPlayerDelegate>{
    AVAudioPlayer* _audioPlayer;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, strong, readonly) AVAudioPlayer* audioPlayer;

- (void)play;
- (void)pause;
- (void)stop;

@end





#pragma mark - CDZDisperseAudioPlayer Implementation
@implementation CDZDisperseAudioPlayer{
    NSUInteger _currentPosition;
    NSInteger _currentLoop;
    NSInteger _state;  // 0停止，1播放，2暂停
    
    BOOL _needPlayWhenActive;
    BOOL _isAudioSessionInterrupt;
}
- (id)init{
    if(self = [super init]){
        _numberOfLoops = 1;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
}
- (void)dealloc{
    self.currentAudioItem.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidBecomeActive:(NSNotification*)notification{
    // 如果是interrupt，则在interrup结束后开始播放
    if(_isAudioSessionInterrupt){
        _isAudioSessionInterrupt = NO;
        return;
    }
    if(_needPlayWhenActive){
        [self play];
    }
    
}
- (void)applicationWillResignActive:(NSNotification*)notification{
    if(_isAudioSessionInterrupt){
        return;
    }
    if(_state == 1){
        [self pause];
        _needPlayWhenActive = YES;
    }
    else{
        _needPlayWhenActive = NO;
    }
}
- (void)audioSessionInterrupt:(NSNotification*)notification{
    AVAudioSessionInterruptionType interruptionType = [[notification.userInfo objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    // 开始
    if(interruptionType == AVAudioSessionInterruptionTypeBegan){
        _isAudioSessionInterrupt = YES;
        if(_state == 1){
            [self pause];
            _needPlayWhenActive = YES;
        }
        else{
            _needPlayWhenActive = NO;
        }
    }
    // 结束
    else{
        _isAudioSessionInterrupt = NO;
        if(_needPlayWhenActive){
            [self play];
        }
    }
}

- (void)play{
    self.currentAudioItem.delegate = self;
    [self.currentAudioItem play];
    _state = 1;
}
- (void)pause{
    _state = 2;
    [self.currentAudioItem pause];
}
- (void)stop{
    _state = 0;
    [self.currentAudioItem stop];
    _currentPosition = 0;
    _currentLoop = 0;
}

- (CDZAudioItem*)currentAudioItem{
    if(_currentPosition >= _audioItemArray.count){
        return nil;
    }
    return [_audioItemArray objectAtIndex:_currentPosition];
}

#pragma mark - CDZAudioItemDelegate
- (void) audioItemDidFinishPlay:(CDZAudioItem*)audioItem error:(NSError*)error{
    self.currentAudioItem.delegate = nil;
    _currentPosition++;
    if(_currentPosition >= _audioItemArray.count){
        _currentPosition = 0;
        
        if(_numberOfLoops <= 0){
            self.currentAudioItem.delegate = self;
            [self.currentAudioItem play];
        }
        else{
            _currentLoop++;
            if(_currentLoop >= _numberOfLoops){
                _currentLoop = 0;
                _state = 0;
                if([_delegate respondsToSelector:@selector(disperseAudioPlayerDidFinishPlay:)]){
                    [_delegate disperseAudioPlayerDidFinishPlay:self];
                }
            }
            else{
                self.currentAudioItem.delegate = self;
                [self.currentAudioItem play];
            }
        }
    }
    else{
        self.currentAudioItem.delegate = self;
        [self.currentAudioItem play];
    }
}

@end








#pragma mark - CDZAudioItem Implementation
@implementation CDZAudioItem{
    NSTimeInterval _mutePlayTime;
    NSTimeInterval _muteHasPlayedTime;
    NSInteger _state;  // 0停止，1播放，2暂停
}
- (id)initWithAudioFileName:(NSString*)audioFileName{
    if(self = [super init]){
        _audioFileName = audioFileName;
    }
    return self;
}
- (id)initWithAudioData:(NSData*)audioData{
    if(self = [super init]){
        _audioData = audioData;
    }
    return self;
}
- (id)initWithAudioPlayer:(AVAudioPlayer*)audioPlayer{
    if(self = [super init]){
        _audioPlayer = audioPlayer;
        _audioPlayer.delegate = self;
    }
    return self;
}
- (id)initWithMuteTime:(NSTimeInterval)muteTime{
    if(self = [super init]){
        _muteAudio = YES;
        _muteTime = muteTime;
    }
    return self;
}
- (void)dealloc{
    _audioPlayer.delegate = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finishMuteTime) object:nil];
}

- (void)play{
    if(_state == 1){
        return;
    }
    _state = 1;
    if(self.muteAudio){
        if(self.muteTime > 0){
            if(self.muteTime > _muteHasPlayedTime){
                _mutePlayTime = [NSProcessInfo processInfo].systemUptime;
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [self performSelector:@selector(finishMuteTime) withObject:nil afterDelay:self.muteTime - _muteHasPlayedTime];
                });
            }
            else{
                [self sendDelegateFinishWithError:nil];
            }
        }
        else{
            [self sendDelegateFinishWithError:nil];
        }
    }
    else{
        if(self.audioPlayer == nil){
            NSError* error = [[NSError alloc]initWithDomain:@"CDZAudioItemError" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"创建播放器失败"}];
            [self sendDelegateFinishWithError:error];
        }
        else{
            [self.audioPlayer play];
        }
    }
}
- (void)pause{
    if(_state == 2){
        return;
    }
    _state = 2;
    if(self.muteAudio){
        if(_mutePlayTime > 0){
            NSTimeInterval currentTime = [NSProcessInfo processInfo].systemUptime;
            _muteHasPlayedTime = currentTime - _mutePlayTime;
            _mutePlayTime = 0;
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finishMuteTime) object:nil];
        }
        else{
            
        }
    }
    else{
        // 当暂停的时间，离音频结束的时间特别近时，该AVAudioPlayer将无法再次播放
        if(self.audioPlayer.duration - self.audioPlayer.currentTime < 0.2){
            
        }
        else{
            [self.audioPlayer pause];
        }
    }
}
- (void)stop{
    _state = 0;
    _mutePlayTime = 0;
    _muteHasPlayedTime = 0;
    [_audioPlayer stop];
    _audioPlayer.currentTime = 0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finishMuteTime) object:nil];
}


- (AVAudioPlayer*)audioPlayer{
    if(_audioPlayer == nil){
        if(_audioData){
            NSError* error = nil;
            _audioPlayer = [[AVAudioPlayer alloc]initWithData:_audioData error:&error];
            _audioPlayer.delegate = self;
        }
        else if(_audioFileName){
            NSError* error = nil;
            NSString* path = [[NSBundle mainBundle] pathForResource:_audioFileName ofType:nil];
            if(path.length > 0){
                NSURL* pathUrl = [NSURL fileURLWithPath:path];
                _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:pathUrl error:&error];
                _audioPlayer.delegate = self;
            }
        }
    }
    return _audioPlayer;
}

- (void)sendDelegateFinishWithError:(NSError*)error{
    [_delegate audioItemDidFinishPlay:self error:error];
}

- (void)finishMuteTime{
    _mutePlayTime = 0;
    _muteHasPlayedTime = 0;
    if(_state == 1){
        _state = 0;
        [self sendDelegateFinishWithError:nil];
    }
}
#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if(_state == 1){
        _state = 0;
        [self sendDelegateFinishWithError:nil];
    }
}
/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    [self sendDelegateFinishWithError:error];
}

@end


// 303730915@qq.com
