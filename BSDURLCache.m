//
//  BSDURLCache.m
//  SDURLCache
//
//  Created by Sarah Lensing on 8/28/12.
//
//

#import "BSDURLCache.h"

static NSTimeInterval const kBSDURLCacheInfoDefaultMinCacheInterval = 0; // 0 minutes

@interface SDURLCache ()
+ (BOOL)validStatusCode:(NSInteger)status;
@end

@implementation BSDURLCache

- (id)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path
{
    if ((self = [super initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity diskPath:path]))
    {
        self.minCacheInterval = kBSDURLCacheInfoDefaultMinCacheInterval;
    }
    return self;
}

+ (NSString *)clientCacheExpirationKey {
    return @"Brewster-Cache-Expiration";
}

+ (NSDate *)expirationDateFromHeaders:(NSDictionary *)headers withStatusCode:(NSInteger)status
{
    if (![SDURLCache validStatusCode:status])
    {
        // Uncacheable response status code
        return nil;
    }
    
    //Client cache keys
    NSNumber *userExpiration = [headers objectForKey:[BSDURLCache clientCacheExpirationKey]];
    if (userExpiration) {
        double expiration = [userExpiration doubleValue];
        return [NSDate dateWithTimeIntervalSinceNow:expiration];
    }
    
    //Default SDURLCache
    return [[super class] expirationDateFromHeaders:headers withStatusCode:status];
}

@end
