//
//  VTEncoder.m
//  VideotoolBox_Test
//
//  Created by huiti123 on 2017/6/1.
//  Copyright © 2017年 wtw. All rights reserved.
//

#import "VTEncoder.h"

@implementation VTEncoder{
    VTCompressionSessionRef _encodeSession;
    
   const   uint8_t * _pps;
  const  uint8_t * _sps;
    
    size_t  _spsSize;
    size_t  _ppsSize;
    
    NSInteger  _width;
    NSInteger  _height;
    
    NSInteger _frameCount;
    
    
}

-(instancetype )init{
    self = [super init];
    if(self ){
        _pps = _sps = NULL;
    }
    
    return  self;
}
// c 语言方法,编码回调,每编码完成一帧视频都会回调这个方法.

void encodeOutputCallBack(void *userData ,void *sourceFrameRefCon, OSStatus status,VTEncodeInfoFlags infoFlags,
                          CMSampleBufferRef sampleBuffer){
    if (status != noErr) {
        NSLog(@"did compressh264 error: with status  %d,infoFlags = %d",(int) status,(int) infoFlags);
        return;
    }
    if(!CMSampleBufferDataIsReady(sampleBuffer)){
        NSLog(@"samplebuffer is not ready");
        return;
    }
    
    VTEncoder * encoder = (__bridge VTEncoder*)userData;
    
    CFArrayRef array  = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    bool keyFrame  = !CFDictionaryContainsKey(CFArrayGetValueAtIndex(array,0), kCMSampleAttachmentKey_NotSync);
    if(keyFrame && encoder->_pps == NULL){
        size_t spsCount;
        size_t ppsCount;
        
        CMFormatDescriptionRef formatDes = CMSampleBufferGetFormatDescription(sampleBuffer);
        OSStatus err0 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDes, 0, &encoder->_sps, &(encoder->_spsSize), &spsCount, 0);
        OSStatus err1  = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDes, 1, &encoder->_pps, &(encoder->_ppsSize), &ppsCount, 0);
        
        if(err0 == noErr && err1 == noErr){
             NSLog(@"got sps/pps data. Length: sps=%zu, pps=%zu", encoder->_spsSize, encoder->_ppsSize);
        }
        
    }
    
    size_t dataLen,totalLen;
    char *dataPointer;
    
    CMBlockBufferRef dataBuffer  = CMSampleBufferGetDataBuffer(sampleBuffer);
     status = CMBlockBufferGetDataPointer(dataBuffer, 0, &dataLen, &totalLen, &dataPointer);
    
    if(status == noErr){
        size_t offset = 0;
        const int lenInfoSize = 4; /* 4字节表示的nal 数据长度大小.*/
        while (offset < totalLen - lenInfoSize) {
            uint32_t  naluLen  = 0;
            memcpy(&naluLen, dataPointer+offset, lenInfoSize);
            
            naluLen = CFSwapInt32BigToHost(naluLen);
               NSLog(@"got nalu data, length=%d, totalLength=%zu", naluLen, totalLen);
            
            // 读取下一个nalu，一次回调可能包含多个nalu
            offset += lenInfoSize + naluLen;
        }
    }
    
}

-(void) initEncoder:(int)width height:(int)height framerate:(int)fps bitrate:(int)bitrate{
    
    
    _width = width;
    _height = height;
    VTCompressionOutputCallback callback  = encodeOutputCallBack;
    
    OSStatus status = VTCompressionSessionCreate(kCFAllocatorDefault, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, callback, (__bridge void*)(self), &_encodeSession);
    if (status != noErr) {
        NSLog(@"VTCompressionSessionCreate failed ret  = %d",(int)status);
    }
    
    // 配置编码器.
    
    // 设置实时编码输出,降低编码延迟
    status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
     NSLog(@"set realtime  return: %d", (int)status);
    
    // 直播 一般设置 baseline 可以减少B帧带来的 延迟.
    status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        NSLog(@"set profile   return: %d", (int)status);
    
    // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
    status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bitrate));//bps
    
    status += VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bitrate*2/8),@1]); // Bps
        NSLog(@"set bitrate   return: %d", (int)status);
    
    
    //设置关键帧 间隔 //GOP
    status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(fps*2));
    //设置帧率, 只用于初始化session ,设置的时 期望的frameRate 不是 实现FPS.
    status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(fps));
      NSLog(@"set framerate return: %d", (int)status);
    
    // 开始编码
    status  = VTCompressionSessionPrepareToEncodeFrames(_encodeSession);
    NSLog(@"start encode  return: %d", (int)status);
    
}

//  CGImageRef => CVPixelBufferRef
// see videotoolboxenc.c (ffmpeg3.2).
-(void) encodeSample:(CMSampleBufferRef ) sampleBuffer
{
    CVImageBufferRef imageBuffer = (CVImageBufferRef) CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime pts  = CMTimeMake(_frameCount, 1000);
    CMTime duration = kCMTimeInvalid;
    
    VTEncodeInfoFlags  flags;
    
    // 送入编码器
    OSStatus status = VTCompressionSessionEncodeFrame(_encodeSession, imageBuffer, pts, duration, NULL, NULL, &flags);
    
    if(status != noErr){
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d",(int)status);
        [self clearEecoder];
        return;
    }
    
}

-(void) clearEecoder{
    if(_encodeSession){
        VTCompressionSessionCompleteFrames(_encodeSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_encodeSession);
        CFRelease(_encodeSession);
    }
 
    _encodeSession = NULL;
}

@end
