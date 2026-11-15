import FitFlowData
import FitFlowDomain
import Foundation
import Testing

struct RecommendationAPIClientTests {
  @Test
  func decodesPythonForecastIntoRecommendation() async throws {
    let responseBody = #"""
      {
        "title": "Нагрузка постепенно растёт",
        "message": "Продолжай постепенно.",
        "reason": "Есть рост.",
        "confidence": "moderate",
        "basedOnWorkoutCount": 5,
        "exerciseId": null,
        "forecast": {
          "model": "linear_regression_v1",
          "estimatedOneRepMax": 58.33,
          "changePercent": 4.17,
          "sessionsUsed": 5,
          "unit": "kg"
        }
      }
      """#
    StubURLProtocol.responseData = Data(responseBody.utf8)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let baseURL = try #require(URL(string: "https://fitflow.test/"))
    let client = RecommendationAPIClient(
      baseURL: baseURL,
      session: session
    )

    let recommendation = try await client.recommendation(for: [])

    #expect(recommendation.forecast?.estimatedOneRepMax == 58.33)
    #expect(recommendation.forecast?.changePercent == 4.17)
    #expect(recommendation.forecast?.sessionsUsed == 5)
    #expect(recommendation.forecast?.unit == "kg")
    #expect(recommendation.source == .pythonService)
    session.invalidateAndCancel()
  }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var responseData = Data()

  override class func canInit(with request: URLRequest) -> Bool { true }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard let url = request.url,
      let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Self.responseData)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
