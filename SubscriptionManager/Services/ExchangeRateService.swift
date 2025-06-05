//
//  ExchangeRateService.swift
//  SubscriptionManager
//
//  Created on 2025/01/05.
//

import Foundation
import Combine

enum ExchangeRateError: LocalizedError {
    case networkError
    case invalidResponse
    case apiError(String)
    case cacheExpired
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .apiError(let message):
            return "APIエラー: \(message)"
        case .cacheExpired:
            return "キャッシュの有効期限が切れました"
        }
    }
}

struct ExchangeRateResponse: Codable {
    let success: Bool
    let base: String
    let date: String
    let rates: [String: Double]
}

struct CachedExchangeRate: Codable {
    let rate: Double
    let timestamp: Date
    let baseCurrency: String
    let targetCurrency: String
    
    var isExpired: Bool {
        // キャッシュは24時間有効
        return Date().timeIntervalSince(timestamp) > 86400
    }
}

class ExchangeRateService: ObservableObject {
    static let shared = ExchangeRateService()
    
    @Published var currentRate: Double?
    @Published var isLoading = false
    @Published var error: ExchangeRateError?
    
    private let baseURL = "https://api.fxratesapi.com/latest"
    private let cacheKey = "com.subscriptionmanager.exchangeRateCache"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func fetchExchangeRate(from baseCurrency: String = "USD", to targetCurrency: String = "JPY") -> AnyPublisher<Double, ExchangeRateError> {
        // まずキャッシュをチェック
        if let cachedRate = getCachedRate(from: baseCurrency, to: targetCurrency) {
            AppLogger.shared.info("Using cached exchange rate: \(cachedRate)")
            return Just(cachedRate)
                .setFailureType(to: ExchangeRateError.self)
                .eraseToAnyPublisher()
        }
        
        // キャッシュがない場合はAPIから取得、失敗時はフォールバック
        return fetchFromAPI(baseCurrency: baseCurrency, targetCurrency: targetCurrency)
            .catch { _ in
                // API失敗時は固定レートを使用（USD/JPY = 150.0）
                AppLogger.shared.info("Using fallback exchange rate: 150.0")
                return Just(150.0)
                    .setFailureType(to: ExchangeRateError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getExchangeRate(from baseCurrency: String = "USD", to targetCurrency: String = "JPY", completion: @escaping (Result<Double, ExchangeRateError>) -> Void) {
        isLoading = true
        error = nil
        
        fetchExchangeRate(from: baseCurrency, to: targetCurrency)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    if case .failure(let error) = result {
                        self?.error = error
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] rate in
                    self?.currentRate = rate
                    completion(.success(rate))
                }
            )
            .store(in: &cancellables)
    }
    
    func convertAmount(_ amount: Double, from baseCurrency: String, to targetCurrency: String) -> AnyPublisher<Double, ExchangeRateError> {
        if baseCurrency == targetCurrency {
            return Just(amount)
                .setFailureType(to: ExchangeRateError.self)
                .eraseToAnyPublisher()
        }
        
        return fetchExchangeRate(from: baseCurrency, to: targetCurrency)
            .map { rate in
                return amount * rate
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func fetchFromAPI(baseCurrency: String, targetCurrency: String) -> AnyPublisher<Double, ExchangeRateError> {
        guard let url = URL(string: "\(baseURL)/\(baseCurrency)") else {
            return Fail(error: ExchangeRateError.networkError)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                guard response.success else {
                    throw ExchangeRateError.apiError("API returned error status")
                }
                
                guard let rate = response.rates[targetCurrency] else {
                    throw ExchangeRateError.invalidResponse
                }
                
                // キャッシュに保存
                self.cacheRate(rate, from: baseCurrency, to: targetCurrency)
                
                AppLogger.shared.info("Fetched exchange rate from API: \(rate)")
                return rate
            }
            .mapError { error in
                if error is ExchangeRateError {
                    return error as! ExchangeRateError
                }
                AppLogger.shared.error("Exchange rate API error: \(error.localizedDescription)")
                return ExchangeRateError.networkError
            }
            .eraseToAnyPublisher()
    }
    
    private func getCachedRate(from baseCurrency: String, to targetCurrency: String) -> Double? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        
        do {
            let cachedRates = try JSONDecoder().decode([CachedExchangeRate].self, from: data)
            
            if let cached = cachedRates.first(where: {
                $0.baseCurrency == baseCurrency &&
                $0.targetCurrency == targetCurrency &&
                !$0.isExpired
            }) {
                return cached.rate
            }
        } catch {
            AppLogger.shared.error("Failed to decode cached rates: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func cacheRate(_ rate: Double, from baseCurrency: String, to targetCurrency: String) {
        var cachedRates: [CachedExchangeRate] = []
        
        // 既存のキャッシュを読み込む
        if let data = UserDefaults.standard.data(forKey: cacheKey) {
            do {
                cachedRates = try JSONDecoder().decode([CachedExchangeRate].self, from: data)
                // 期限切れのキャッシュを削除
                cachedRates = cachedRates.filter { !$0.isExpired }
            } catch {
                AppLogger.shared.error("Failed to decode existing cache: \(error.localizedDescription)")
            }
        }
        
        // 同じ通貨ペアの古いキャッシュを削除
        cachedRates.removeAll {
            $0.baseCurrency == baseCurrency && $0.targetCurrency == targetCurrency
        }
        
        // 新しいキャッシュを追加
        let newCache = CachedExchangeRate(
            rate: rate,
            timestamp: Date(),
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency
        )
        cachedRates.append(newCache)
        
        // 保存
        do {
            let data = try JSONEncoder().encode(cachedRates)
            UserDefaults.standard.set(data, forKey: cacheKey)
            AppLogger.shared.info("Cached exchange rate: \(rate) from \(baseCurrency) to \(targetCurrency)")
        } catch {
            AppLogger.shared.error("Failed to cache exchange rate: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Utility Methods
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        AppLogger.shared.info("Exchange rate cache cleared")
    }
    
    func getCachedRates() -> [CachedExchangeRate] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return [] }
        
        do {
            let cachedRates = try JSONDecoder().decode([CachedExchangeRate].self, from: data)
            return cachedRates.filter { !$0.isExpired }
        } catch {
            AppLogger.shared.error("Failed to get cached rates: \(error.localizedDescription)")
            return []
        }
    }
}