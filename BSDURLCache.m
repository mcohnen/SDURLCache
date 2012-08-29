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
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
+ (NSString *)cacheKeyForURL:(NSURL *)url;
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

+ (NSString *)clientCacheExpirationAge {
    return @"Brewster-Cache-Expiration-Age";
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

-(NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    
    SEL sel = @selector(cachedResponseForRequest:);
    IMP imp = [[[super class] superclass] instanceMethodForSelector:sel];
    
    if (disabled) return imp(self, sel, request);
    
    request = [SDURLCache canonicalRequestForRequest:request];
    
    float expirationAge = [[[request allHTTPHeaderFields] objectForKey:[BSDURLCache clientCacheExpirationAge]] floatValue];
    NSString *cacheKey = [SDURLCache cacheKeyForURL:request.URL];
    NSString *filePath = [diskCachePath stringByAppendingPathComponent:cacheKey];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if(expirationAge == -1 || fabs(([[self modificationDateForFile:filePath] timeIntervalSinceNow])) <= expirationAge) {
            SDCachedURLResponse *diskResponseWrapper = [NSKeyedUnarchiver unarchiveObjectWithFile:[diskCachePath stringByAppendingPathComponent:cacheKey]];
            NSCachedURLResponse *diskResponse = diskResponseWrapper.response;
            NSURLResponse* response = [[[NSURLResponse alloc] initWithURL:[[diskResponse response] URL]
                                                                MIMEType:[[diskResponse response] MIMEType]
                                                   expectedContentLength:[[diskResponse data] length]
                                                        textEncodingName:[[diskResponse response] textEncodingName]] autorelease];
            NSCachedURLResponse *cachedResponse = [[[NSCachedURLResponse alloc] initWithResponse:response data:[diskResponse data] userInfo:nil storagePolicy:NSURLCacheStorageAllowedInMemoryOnly] autorelease];
            return cachedResponse;
        }
        else {
            return nil;
        }
    }
    return [super cachedResponseForRequest:request];
}

@end
