// 📁 Domain/Interfaces/LocationServiceProtocol.swift
import Foundation
import CoreLocation
import Combine

protocol LocationServiceProtocol {
    var currentLocation: CLLocation? { get }
    var safeHeading: Double { get }
    
    // ท่ามาตรฐาน: ใช้ AnyPublisher เพื่อให้ ViewModel เอาไป .sink ต่อได้
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    var headingPublisher: AnyPublisher<Double, Never> { get }
    
    func requestPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}
