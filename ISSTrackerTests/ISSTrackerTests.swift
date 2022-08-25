//
//  ISSTrackerTests.swift
//  ISSTrackerTests
//
//  Created by Valerii Lider on 8/25/22.
//

import XCTest
@testable import ISSTracker
import Combine

let centerOfNY = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)

final class ISSServiceAlwaysSuceedsMock: NSObject, ISSLocationServiceProtocol {
    func getISSLocation(_ completion: ((ISSLocation?, Error?) -> Void)!) {
        let location = ISSLocation()
        location.coordinates = centerOfNY
        location.message = "success"
        location.timestamp = Date()

        completion(location, nil)
    }
}

final class ISSServiceAlwaysFailsMock: NSObject, ISSLocationServiceProtocol {
    func getISSLocation(_ completion: ((ISSLocation?, Error?) -> Void)!) {
        completion(.none, NSError(domain: "Test", code: 0, userInfo: .none))
    }
}

class ISSTrackerTests: XCTestCase {

    private var sut: ViewModel!
    private var cancelables = Set<AnyCancellable>()

    private func setupSystemUnderTest(mock: ISSLocationServiceProtocol, refreshFrequency: Double = 1.0) {
        sut = ViewModel(issSservice: ISSService(mock), refreshFrequency: refreshFrequency)
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetLocation() throws {
        setupSystemUnderTest(mock: ISSServiceAlwaysSuceedsMock(), refreshFrequency: 1.0)

        let expectation = XCTestExpectation()

        sut.feedback
            .receive(on: DispatchQueue.main)
            .sink { feedback in
                switch feedback {
                case let .updateISSLocation(coordinates):
                    XCTAssertEqual(coordinates.latitude, centerOfNY.latitude)
                    XCTAssertEqual(coordinates.longitude, centerOfNY.longitude)
                case .noop:
                    XCTFail("Unexpected feedback: \(feedback)")
                }

                expectation.fulfill()
            }
            .store(in: &cancelables)

        sut.intent.send(.startTracking)

        wait(for: [expectation], timeout: 10)
    }

    func testGetLocationFailed() throws {
        setupSystemUnderTest(mock: ISSServiceAlwaysFailsMock(), refreshFrequency: 1.0)

        let expectation = XCTestExpectation()

        sut.feedback
            .receive(on: DispatchQueue.main)
            .sink { feedback in
                switch feedback {
                case let .updateISSLocation(coordinates):
                    XCTAssertEqual(coordinates.latitude, kCLLocationCoordinate2DInvalid.latitude)
                    XCTAssertEqual(coordinates.longitude, kCLLocationCoordinate2DInvalid.longitude)
                case .noop:
                    XCTFail("Unexpected feedback: \(feedback)")
                }

                expectation.fulfill()
            }
            .store(in: &cancelables)

        sut.intent.send(.startTracking)

        wait(for: [expectation], timeout: 10)
    }

    func testStopTracking() throws {
        setupSystemUnderTest(mock: ISSServiceAlwaysSuceedsMock(), refreshFrequency: 1.0)

        let locationExpectation = XCTestExpectation()
        locationExpectation.expectedFulfillmentCount = 3
        locationExpectation.assertForOverFulfill = true

        let noopExpectation = XCTestExpectation()

        sut.feedback
            .receive(on: DispatchQueue.main)
            .sink { feedback in
                switch feedback {
                case .updateISSLocation:
                    locationExpectation.fulfill()
                case .noop:
                    noopExpectation.fulfill()
                }
            }
            .store(in: &cancelables)

        sut.intent.send(.startTracking)

        wait(for: [locationExpectation], timeout: 10)
        sut.intent.send(.stopTracking)
        wait(for: [noopExpectation], timeout: 10)
    }
}
