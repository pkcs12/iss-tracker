//
//  ViewModel.swift
//  ISSTracker
//
//  Created by Valerii Lider on 8/25/22.
//

import Foundation
import Combine

final class ViewModel {
    let intent = PassthroughSubject<Action, Never>()
    let feedback = PassthroughSubject<Feedback, Never>()

    private var cancelables = Set<AnyCancellable>()
    private lazy var timer = { Timer.publish(every: refreshFrequency, on: .main, in: .common).autoconnect() }()

    private let refreshFrequency: Double
    private let issSservice: ISSService

    init(
        issSservice: ISSService = .init(),
        refreshFrequency: Double = 3.0
    ) {
        self.issSservice = issSservice
        self.refreshFrequency = refreshFrequency
        observe()
    }
}

extension ViewModel {

    private func observe() {
        observeIntent()
    }

    private func observeIntent() {
        intent
            .receive(on: DispatchQueue.global(qos: .utility))
            .flatMap { [weak self, timer] action -> AnyPublisher<Feedback, Never> in
                guard let self = self else {
                    return Just(.noop).eraseToAnyPublisher()
                }

                switch action {
                case .startTracking:
                    return Publishers.Merge(
                        self.getLocation(),
                        timer
                            .flatMap { [weak self] _ -> AnyPublisher<CLLocationCoordinate2D, Never> in
                                guard let self = self else {
                                    return Just(kCLLocationCoordinate2DInvalid).eraseToAnyPublisher()
                                }
                                return self.getLocation()
                            }
                    )
                    .map { Feedback.updateISSLocation($0) }
                    .eraseToAnyPublisher()

                case .stopTracking:
                    timer.upstream.connect().cancel()
                    return Just(Feedback.noop)
                        .eraseToAnyPublisher()
                }
            }
            .subscribe(feedback)
            .store(in: &cancelables)
    }

    private func getLocation() -> AnyPublisher<CLLocationCoordinate2D, Never> {
        issSservice
            .getLocation()
            .catch { _ in Just(kCLLocationCoordinate2DInvalid) }
            .eraseToAnyPublisher()
    }
}
