import Foundation

/// Fetches and caches fiat and crypto exchange rates
actor CurrencyService {
    static let shared = CurrencyService()

    private var rates: [String: Double] = [:]
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 300 // 5 min for crypto freshness

    // Fallback fiat rates (approximate, used when offline)
    private let fallbackFiatRates: [String: Double] = [
        "USD": 1.0, "EUR": 0.92, "GBP": 0.79, "JPY": 149.5,
        "CAD": 1.36, "AUD": 1.53, "CHF": 0.88, "CNY": 7.24,
        "KRW": 1330.0, "RUB": 92.0, "INR": 83.1, "BRL": 4.97,
        "MXN": 17.15, "ZAR": 18.8, "SEK": 10.45, "NOK": 10.5,
        "DKK": 6.87, "NZD": 1.63, "SGD": 1.34, "HKD": 7.82,
        "TRY": 30.2, "PLN": 4.0, "THB": 35.5, "IDR": 15600.0,
    ]

    // Fallback crypto prices in USD (approximate)
    private let fallbackCryptoPrices: [String: Double] = [
        "BTC": 97000, "ETH": 2700, "SOL": 195,
        "BNB": 650, "XRP": 2.6, "ADA": 0.78,
        "DOGE": 0.26, "DOT": 5.0, "AVAX": 26,
        "MATIC": 0.38, "LINK": 19, "UNI": 10.5,
        "LTC": 125, "ATOM": 6.5, "XLM": 0.37,
        "ALGO": 0.28, "NEAR": 3.5, "FTM": 0.55,
        "AAVE": 260, "ARB": 0.55, "OP": 1.3,
        "APT": 7, "SUI": 3.2, "SEI": 0.28,
        "SHIB": 0.000016, "PEPE": 0.0000095,
        "USDT": 1.0, "USDC": 1.0, "DAI": 1.0,
    ]

    // CoinGecko ID mapping for the crypto tickers we support
    private let coinGeckoIds: [String: String] = [
        "BTC": "bitcoin", "ETH": "ethereum", "SOL": "solana",
        "BNB": "binancecoin", "XRP": "ripple", "ADA": "cardano",
        "DOGE": "dogecoin", "DOT": "polkadot", "AVAX": "avalanche-2",
        "MATIC": "matic-network", "LINK": "chainlink", "UNI": "uniswap",
        "LTC": "litecoin", "ATOM": "cosmos", "XLM": "stellar",
        "ALGO": "algorand", "NEAR": "near", "FTM": "fantom",
        "AAVE": "aave", "ARB": "arbitrum", "OP": "optimism",
        "APT": "aptos", "SUI": "sui", "SEI": "sei-network",
        "SHIB": "shiba-inu", "PEPE": "pepe",
        "USDT": "tether", "USDC": "usd-coin", "DAI": "dai",
    ]

    func getRates() async -> [String: Double] {
        if let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < cacheInterval,
           !rates.isEmpty {
            return rates
        }

        // Fetch fiat and crypto in parallel
        async let fiatResult = fetchFiatRates()
        async let cryptoResult = fetchCryptoPrices()

        var merged: [String: Double] = [:]

        // Merge fiat rates
        if let fiat = try? await fiatResult {
            merged.merge(fiat) { _, new in new }
        } else {
            merged.merge(fallbackFiatRates) { _, new in new }
        }

        // Merge crypto — store as "price of 1 crypto in USD"
        // To fit the same system as fiat (rates relative to USD),
        // we store crypto as: rate = 1/priceInUSD
        // So 1 BTC = $97000 means rate["BTC"] = 1/97000
        // Then convertCurrency(1, from: "BTC", to: "USD") = 1 / (1/97000) * 1 = 97000 ✓
        // And convertCurrency(97000, from: "USD", to: "BTC") = 97000 / 1 * (1/97000) = 1 ✓
        let cryptoPrices: [String: Double]
        if let fetched = try? await cryptoResult {
            cryptoPrices = fetched
        } else {
            cryptoPrices = fallbackCryptoPrices
        }

        for (ticker, priceUSD) in cryptoPrices where priceUSD > 0 {
            merged[ticker] = 1.0 / priceUSD
        }

        // Ensure USD baseline
        merged["USD"] = 1.0

        self.rates = merged
        self.lastFetch = Date()
        return merged
    }

    // MARK: - Fiat

    private func fetchFiatRates() async throws -> [String: Double] {
        let url = URL(string: "https://open.er-api.com/v6/latest/USD")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CurrencyError.fetchFailed
        }

        let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        return decoded.rates
    }

    // MARK: - Crypto

    private func fetchCryptoPrices() async throws -> [String: Double] {
        let ids = coinGeckoIds.values.joined(separator: ",")
        let urlStr = "https://api.coingecko.com/api/v3/simple/price?ids=\(ids)&vs_currencies=usd"
        guard let url = URL(string: urlStr) else { throw CurrencyError.fetchFailed }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CurrencyError.fetchFailed
        }

        // Response: { "bitcoin": { "usd": 97000 }, "ethereum": { "usd": 2700 }, ... }
        let decoded = try JSONDecoder().decode([String: [String: Double]].self, from: data)

        // Reverse map: coinGeckoId -> ticker
        let idToTicker = Dictionary(uniqueKeysWithValues: coinGeckoIds.map { ($0.value, $0.key) })

        var prices: [String: Double] = [:]
        for (geckoId, priceData) in decoded {
            if let ticker = idToTicker[geckoId], let usdPrice = priceData["usd"] {
                prices[ticker] = usdPrice
            }
        }

        return prices
    }
}

private struct ExchangeRateResponse: Codable {
    let result: String
    let rates: [String: Double]
}

enum CurrencyError: Error {
    case fetchFailed
}
