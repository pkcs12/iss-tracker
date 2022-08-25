//
//  ISSLocationService.h
//  ISSTracker
//
//  Created by Valerii Lider on 8/25/22.
//

@import Foundation;
@import CoreLocation;

@interface ISSLocation : NSObject
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic) CLLocationCoordinate2D coordinates;
@end

@protocol ISSLocationServiceProtocol <NSObject>
- (void)getISSLocation: (void (^)(ISSLocation *, NSError *))completion;
@end

@interface ISSLocationService: NSObject <ISSLocationServiceProtocol>

- (instancetype)init;
- (instancetype)init:(NSURL *)serviceUrl;
- (void)getISSLocation: (void (^)(ISSLocation *, NSError *))completion;
@end
