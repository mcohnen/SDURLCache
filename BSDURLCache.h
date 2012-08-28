//
//  BSDURLCache.h
//  SDURLCache
//
//  Created by Sarah Lensing on 8/28/12.
//
//

#import "SDURLCache.h"

@interface BSDURLCache : SDURLCache
+ (NSString *)clientCacheExpirationKey;
- (NSData *)dataForURL:(NSURL*)URL expires:(NSTimeInterval)expirationAge;
@end
