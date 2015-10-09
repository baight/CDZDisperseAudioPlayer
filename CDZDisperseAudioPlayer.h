//
//  CDZDisperseAudioPlayer.h
//
//
//  Created by baight on 15/9/17.
//  Copyright (c) 2013 baight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


/*
 有音频a，b，c，d，现要求：播放三遍a，停5秒，再今次播放b，c，d。
 CDZDisperseAudioPlayer 就是为了方便地解决这样一个问题
 
 CDZAudioItem* a = [[CDZAudioItem alloc]initWithAudioFileName:@"a.mp3"];
 CDZAudioItem* b = [[CDZAudioItem alloc]initWithAudioFileName:@"b.mp3"];
 CDZAudioItem* c = [[CDZAudioItem alloc]initWithAudioFileName:@"c.mp3"];
 CDZAudioItem* d = [[CDZAudioItem alloc]initWithAudioFileName:@"d.mp3"];
 CDZAudioItem* interval = [[CDZAudioItem alloc]initWithMuteTime:5];
 
 self.player = [[CDZDisperseAudioPlayer alloc] init];
 self.player.audioItemArray = @[a, a, a, interval, b, c, d];
 [self.player play];
 
 */




@class CDZAudioItem;
@interface CDZDisperseAudioPlayer : NSObject

@property (nonatomic, assign) id delegate;
@property (nonatomic, strong, readonly) CDZAudioItem* currentAudioItem;
@property (nonatomic, assign) NSInteger numberOfLoops;  // 默认1，小于等于0时，表示无限循环

// audioItemArray 成员为 CDZAudioItem 
@property (nonatomic, strong) NSArray* audioItemArray;

- (void)play;
- (void)pause;
- (void)stop;

@end

@protocol CDZDisperseAudioPlayerDelegate <NSObject>
@optional
- (void)disperseAudioPlayerDidFinishPlay:(CDZDisperseAudioPlayer*)player;
@end




















@interface CDZAudioItem : NSObject
@property (nonatomic, strong, readonly) NSString* audioFileName;
@property (nonatomic, strong, readonly) NSData* audioData;

@property (nonatomic, assign) BOOL muteAudio; // 如果muteAudio为YES，在会在 muteTime 时间不播放任何声音
@property (nonatomic, assign) NSTimeInterval muteTime;


- (id)initWithAudioFileName:(NSString*)audioFileName;
- (id)initWithAudioData:(NSData*)audioData;
- (id)initWithAudioPlayer:(AVAudioPlayer*)audioPlayer;
- (id)initWithMuteTime:(NSTimeInterval)muteTime;

@end


// 303730915@qq.com
