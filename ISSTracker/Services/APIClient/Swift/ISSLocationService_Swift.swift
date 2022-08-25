//
//  ISSLocationServiceWrapper.swift
//  ISSTracker
//
//  Created by Valerii Lider on 8/25/22.
//

import Foundation
import Combine
import CoreLocation

final class ISSService {
    private let service: ISSLocationServiceProtocol

    init(_ service: ISSLocationServiceProtocol = ISSLocationService()) {
        self.service = service
    }

    func getLocation() -> AnyPublisher<CLLocationCoordinate2D, Error> {
        Future { [weak service] promise in
            guard let service = service else {
                promise(
                    .failure(
                        NSError(
                            domain: "ISSLocationServiceWrapper",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "ISSLocationService not initialized"]
                        )
                    )
                )
                return
            }

            service.getISSLocation { location, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }

                promise(.success(location?.coordinates ?? kCLLocationCoordinate2DInvalid))
            }
        }
        .eraseToAnyPublisher()
    }
}
