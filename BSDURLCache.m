//
//  BSDURLCache.m
//  SDURLCache
//
//  Created by Sarah Lensing on 8/28/12.
//
//

#import "BSDURLCache.h"
#import "SDCachedURLResponse.h"

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

- (NSData *)dataForURL:(NSURL*)URL expires:(NSTimeInterval)expirationAge {
    NSCachedURLResponse *response = [self cachedResponseForRequest:[NSURLRequest requestWithURL:URL]];
    if (response) {
        NSString *cacheKey = [SDURLCache cacheKeyForURL:URL];
        NSString *filePath = [diskCachePath stringByAppendingPathComponent:cacheKey];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && fabs(([[self modificationDateForFile:filePath] timeIntervalSinceNow])) < expirationAge) {
            NSCachedURLResponse *diskResponse = (SDCachedURLResponse *)[[NSKeyedUnarchiver unarchiveObjectWithFile:[diskCachePath stringByAppendingPathComponent:cacheKey]] response];
            return diskResponse.data;
        }
    }
    return nil;
}

- (NSDate *)modificationDateForFile:(NSString *)filePath {
    NSError *attributesRetrievalError = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                             error:&attributesRetrievalError];
    
    if (!attributes) {
        NSLog(@"Error for file at %@: %@", filePath, attributesRetrievalError);
        return nil;
    }
    return [attributes fileModificationDate];
}

@end
