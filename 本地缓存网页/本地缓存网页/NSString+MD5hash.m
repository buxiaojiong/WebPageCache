//
//  NSString+MD5hash.m
//  本地缓存网页
//
//  Created by jojojiong on 16/1/6.
//  Copyright © 2016年 jojojiong. All rights reserved.
//

#import "NSString+MD5hash.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5hash)

+ (NSString *)md5Hash:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    NSString *md5Result = [NSString stringWithFormat:
                           @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    return md5Result;
}

@end
