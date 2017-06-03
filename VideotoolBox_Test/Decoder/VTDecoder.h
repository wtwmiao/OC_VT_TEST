//
//  VTDecoder.h
//  VideotoolBox_Test
//
//  Created by huiti123 on 2017/5/26.
//  Copyright © 2017年 wtw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

// CV core video
// CM  core media


@interface VTDecoder : NSObject

// 初始化 用pps sps 构造 CMVideoFormatDescriptionRef 信息, 这个是CoreMedia对 sps pps信息的封装.
// 通过 构造一个 解码器 .CMVideoFormatDescriptionRef
// 并且通过  CFDictionaryRef attrs 配置解码器参数.  这个是 用户自定义的信息. 其他编码信息可以从sps pps中获取.

// 参照 h264 解码器构造. 在构造中解码side_data. 默认构造解码器的高宽等信息.
/* 
 if (avctx->extradata_size > 0 && avctx->extradata) {
ret = ff_h264_decode_extradata(h, avctx->extradata, avctx->extradata_size);
if (ret < 0) {
    ff_h264_free_context(h);
    return ret;
}
}*/
-(void) initDecoder;

/*
   解码一帧数据. 将 nal 构造成 CoreMedia 支持的 CMSampleBufferRef.
 
 参照 h264 处理 (每一个 avpacket 带有 pts 和 side_data)
 也就是 CMTime 和 CMVideoFormatDescriptionRef 携带信息.
 */

-(void) decodeSample:(uint8_t *)buffer size:(NSInteger)size;

-(void) clearDecoder;



@end
