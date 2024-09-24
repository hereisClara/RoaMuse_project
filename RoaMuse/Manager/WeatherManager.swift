//
//  WeatherManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/13.
//

//import WeatherKit
//import CoreLocation
//
//class WeatherManager {
//    private let weatherService = WeatherService.shared
//
//    func fetchWeather(for location: CLLocation, completion: @escaping (CurrentWeather?) -> Void) {
//        Task {
//            do {
//                let weather = try await weatherService.weather(for: location)
//                completion(weather.currentWeather)
//            } catch {
//                print("Error fetching weather: \(error.localizedDescription)")
//                completion(nil)
//            }
//        }
//    }
//}
