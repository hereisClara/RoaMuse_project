import WeatherKit
import CoreLocation

class WeatherKitManager {
    
    static let shared = WeatherKitManager()
    
    // 獲取天氣資訊
    func fetchWeather(for location: CLLocation) async throws -> CurrentWeather {
        let weatherService = WeatherService()
        let weather = try await weatherService.weather(for: location)
        return weather.currentWeather
    }
}
