//
//  ISSLocationService.m
//  ISSTracker
//
//  Created by Valerii Lider on 8/25/22.
//

#import "ISSLocationService.h"
@import Foundation;

@implementation ISSLocation
@synthesize message, timestamp, coordinates;
@end

@interface ISSLocationService ()
@property (nonatomic, readwrite, retain) NSURL *serviceUrl;
@property (nonatomic, readwrite, retain) NSURLSession *urlSession;
@property (nonatomic, readwrite, retain) NSURLSessionDataTask *task;
@end

@implementation ISSLocationService

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        [self setupSession: [[NSURL alloc] initWithString: @"http://api.open-notify.org/iss-now.json"]];
    }

    return  self;
}

- (instancetype)init:(NSURL *)serviceUrl {
    self = [super init];
    if (self != nil) {
        [self setupSession: serviceUrl];
    }

    return  self;
}

- (void)setupSession:(NSURL *)serviceUrl {
    [self setServiceUrl: serviceUrl];
    [self setUrlSession: [NSURLSession sharedSession]];
}

- (void)getISSLocation: (void (^)(ISSLocation *, NSError *))completion {

    if (self.task != nil) {
        [self.task cancel];
        self.task = nil;
    }

    __block ISSLocationService *this = self;
    self.task = [self.urlSession dataTaskWithURL: self.serviceUrl
                               completionHandler: ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            completion(nil, error);
            return;
        }
        if (data == nil) {
            completion(nil, [[NSError alloc] initWithDomain: NSURLErrorDomain
                                                       code: NSURLErrorBadServerResponse
                                                   userInfo: @{@"response": response}]);
            return;
        }

        [this decodeISSLocation:data completion:completion];
    }];
    [self.task resume];
}

- (void)decodeISSLocation:(NSData *)data completion: (void (^)(ISSLocation *, NSError *))completion {
    NSError *serializationError = nil;
    id object = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &serializationError];
    if (![object isKindOfClass:[NSDictionary class]]) {
        completion(nil, [[NSError alloc] initWithDomain: NSURLErrorDomain
                                                   code: NSURLErrorCannotParseResponse
                                               userInfo: nil]);
        return;
    }

    NSDictionary *result = object;
    ISSLocation *location = [[ISSLocation alloc] init];
    location.message = [result valueForKey:@"message"];
    id value = [result valueForKey:@"timestamp"];
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *timestamp = value;
        location.timestamp = [NSDate dateWithTimeIntervalSince1970:[timestamp longLongValue]];
    }
    value = [result valueForKey:@"iss_position"];
    if (![value isKindOfClass:[NSDictionary class]]) {
        completion(nil, [[NSError alloc] initWithDomain: NSURLErrorDomain
                                                   code: NSURLErrorCannotParseResponse
                                               userInfo: nil]);
        return;
    }

    NSDictionary *position = value;
    id latValue = [position valueForKey:@"latitude"];
    id lngValue = [position valueForKey:@"longitude"];
    if ([latValue isKindOfClass:[NSString class]] && [lngValue isKindOfClass:[NSString class]]) {
        NSScanner *scanner = [[NSScanner alloc] initWithString: latValue];

        double lat = 0;
        [scanner scanDouble:&lat];
        scanner = [[NSScanner alloc] initWithString: lngValue];
        double lng = 0;
        [scanner scanDouble:&lng];
        location.coordinates = CLLocationCoordinate2DMake(lat , lng);
    }

    completion(location, nil);
}

@end
