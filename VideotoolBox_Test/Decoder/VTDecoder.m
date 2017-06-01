//
//  VTDecoder.m
//  VideotoolBox_Test
//
//  Created by huiti123 on 2017/5/26.
//  Copyright © 2017年 wtw. All rights reserved.
//

#import "VTDecoder.h"

//CMSampleBufferRef
@implementation VTDecoder{
    
    VTDecompressionSessionRef   _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    
    uint8_t *_pps;
    uint8_t *_sps;
    
    NSInteger _spsSize;
    NSInteger _ppsSize;
    
}


static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon; // 获取到传递 的pixelbuffer
    // 保存 转换后的pixelbuffer到 传递的buffer中.
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}


-(void) initDecoder
{
    const uint8_t *const parmeterSetPointers[2] = {_sps,_pps};
    const size_t parmeterSetSize[2] = {_spsSize,_ppsSize};
    
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parmeterSetPointers, parmeterSetSize, 4, &_decoderFormatDescription);
    
    if(status == noErr){
        CFDictionaryRef attrs = NULL;
        const void *keys[] = {kCVPixelBufferPixelFormatTypeKey};
        uint32_t  value  = kCVPixelFormatType_420YpCbCr8PlanarFullRange;
        
        const void *values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &value)};
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon =NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL,
                                              attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        
        CFRelease(attrs);
    }else {
        NSLog(@"IOSVT: reset decoder session failed satus = %d",status);
    }
    
    return YES;
    
    
}


-(void) decodeSample:(uint8_t *)buffer size:(NSInteger)size
{
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer  = NULL;
    OSStatus  status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void*)buffer, size, kCFAllocatorNull, NULL, 0, size, 0, &blockBuffer);
    
    if(status == kCMBlockBufferNoErr){
        CMSampleBufferRef sampleBuffer  = NULL;
        const size_t sampleSizeArray[] = {size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _decoderFormatDescription, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
        
        if(status == kCMBlockBufferNoErr && sampleBuffer){
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags  flagOut = 0;
            OSStatus decodeSatus = VTDecompressionSessionDecodeFrame(_deocderSession, sampleBuffer, flags, &outputPixelBuffer, &flagOut);
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
        }
        CFRelease(sampleBuffer);
    }
    CFRelease(blockBuffer);
    
}
-(void) clearDecoder
{
    if(_deocderSession){
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription){
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_pps);
    free(_sps);
    
    _spsSize = _ppsSize = 0;
    
}
@end
