//
//  ViewController.swift
//  ISSTracker
//
//  Created by Valerii Lider on 8/25/22.
//

import UIKit
import MapKit
import Combine

class ViewController: UIViewController {
    private var mapView: MKMapView!
    private var startStopButton: UIButton!

    private let cameraDistance: Double = 25000000
    private var issAnnotation: MKPointAnnotation!

    private let viewModel = ViewModel()
    private var cancelables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        observe()
    }
}

extension ViewController {

    private func setup() {
        setupMapView()
        setupStartStopButton()

        setupAnnotation()

        view.addSubview(mapView)
        view.addSubview(startStopButton)

        NSLayoutConstraint.activate(
            [
                mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                mapView.topAnchor.constraint(equalTo: view.topAnchor),
                mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                startStopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                startStopButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -44)
            ]
        )
    }

    private func setupMapView() {
        mapView = .init(frame: .zero)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.mapType = .satelliteFlyover
        mapView.isUserInteractionEnabled = false
        mapView.showsTraffic = false
        mapView.delegate = self
    }

    private func setupStartStopButton() {
        startStopButton = .init(type: .custom)
        startStopButton.translatesAutoresizingMaskIntoConstraints = false
        startStopButton.setTitle("Start tracking", for: .normal)
        startStopButton.setTitle("Stop tracking", for: .selected)
    }

    private func setupAnnotation() {
        issAnnotation = MKPointAnnotation()
        issAnnotation.title = "ISS"
        issAnnotation.coordinate = kCLLocationCoordinate2DInvalid
    }

    private func observe() {
        observeFeedback()
        observeStartStopButtonTap()
    }

    private func observeFeedback() {
        viewModel.feedback
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] feedback in

                switch feedback {
                case let .updateISSLocation(coordinate):
                    self?.setCameraWithCoordinate(coordinate)

                case .noop:
                    break
                }
            }
            .store(in: &cancelables)
    }

    private func setCameraWithCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let camera = MKMapCamera(
            lookingAtCenter: coordinate,
            fromDistance: cameraDistance,
            pitch: 0,
            heading: 0
        )
        mapView.setCamera(camera, animated: true)

        issAnnotation.coordinate = coordinate
        mapView.addAnnotation(issAnnotation)
    }

    private func observeStartStopButtonTap() {
        startStopButton.addTarget(
            self,
            action: #selector(onStartStopButtonTapped(_:)),
            for: .touchUpInside
        )
    }

    @objc private func onStartStopButtonTapped(_ sender: UIControl) {
        viewModel.intent.send(sender.isSelected ? .stopTracking : .startTracking)
        sender.isSelected.toggle()
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "ISS"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)

        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
}
