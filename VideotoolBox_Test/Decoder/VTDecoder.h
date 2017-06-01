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


-(void) initDecoder;

-(void) decodeSample:(uint8_t *)buffer size:(NSInteger)size;

-(void) clearDecoder;



@end
