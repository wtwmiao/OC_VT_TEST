//
//  VTEncoder.h
//  VideotoolBox_Test
//
//  Created by huiti123 on 2017/6/1.
//  Copyright © 2017年 wtw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>


//https://github.com/shawn7com/VTEncodeDemo

/**
 CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
*/
@interface VTEncoder : NSObject


// 设置编码器 参考libx264 参数配置
/*
 c->bit_rate = 400000;
 c->time_base.den = 25;  //zhen lv
 c->time_base.num = 1;
 c->gop_size = 250;
 */
-(void) initEncoder;

-(void) encodeSample:(uint8_t *)buffer size:(NSInteger)size;

-(void) encodeSample:(CMSampleBufferRef ) sampleBuffer;

-(void) clearEecoder;


@end
