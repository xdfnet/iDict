import Foundation
import Testing
@testable import iDict

struct TranslationServiceTests {

    // MARK: - TranslationResult Tests

    @Test("TranslationResult success case - isEmpty returns false for non-empty text")
    func translationResultSuccessIsNotEmpty() {
        let result = TranslationResult.success("Hello")
        #expect(result.isEmpty == false)
    }

    @Test("TranslationResult success case - isEmpty returns true for empty text")
    func translationResultSuccessEmptyIsEmpty() {
        let result = TranslationResult.success("")
        #expect(result.isEmpty == true)
    }

    @Test("TranslationResult success case - isFailure returns false")
    func translationResultSuccessIsNotFailure() {
        let result = TranslationResult.success("Hello")
        #expect(result.isFailure == false)
    }

    @Test("TranslationResult success case - text returns the translated string")
    func translationResultSuccessText() {
        let result = TranslationResult.success("你好")
        #expect(result.text == "你好")
    }

    @Test("TranslationResult success case - errorMessage returns nil")
    func translationResultSuccessErrorMessageIsNil() {
        let result = TranslationResult.success("你好")
        #expect(result.errorMessage == nil)
    }

    @Test("TranslationResult failed case - isEmpty returns true")
    func translationResultFailedIsEmpty() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.isEmpty == true)
    }

    @Test("TranslationResult failed case - isFailure returns true")
    func translationResultFailedIsFailure() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.isFailure == true)
    }

    @Test("TranslationResult failed case - text returns nil")
    func translationResultFailedTextIsNil() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.text == nil)
    }

    @Test("TranslationResult failed case - errorMessage returns error string")
    func translationResultFailedErrorMessage() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.errorMessage == "Network error")
    }

    // MARK: - TranslationServiceManager Tests

    @Test("TranslationServiceManager init creates instance")
    func translationServiceManagerInit() {
        let manager = TranslationServiceManager()
        #expect(manager != nil)
    }

    // MARK: - TranslationConfigStore Tests

    @Test("TranslationConfigStore prepares full Google default config on first install")
    func configStorePreparesFullGoogleDefaultConfigOnFirstInstall() throws {
        let store = TranslationConfigStore(configURL: temporaryConfigURL())
        let config = try store.loadOrCreate()
        let savedData = try Data(contentsOf: store.configURL)
        let savedJSON = try #require(String(data: savedData, encoding: .utf8))

        #expect(config == TranslationConfig.defaultConfig)
        #expect(config.provider == .google)
        #expect(FileManager.default.fileExists(atPath: store.configURL.path))
        #expect(savedJSON.contains("\"provider\""))
        #expect(savedJSON.contains("\"baseURL\""))
        #expect(savedJSON.contains("\"apiKey\""))
        #expect(savedJSON.contains("\"model\""))
        #expect(savedJSON.contains("\"systemPrompt\""))
        #expect(savedJSON.contains("\"userPromptTemplate\""))
        #expect(savedJSON.contains("\"timeoutSeconds\""))
        #expect(savedJSON.contains("\"speechEnabled\""))
        #expect(savedJSON.contains("\"speechCommand\""))
        #expect(!savedJSON.contains("\\/"))
        #expect(fieldOrder(in: savedJSON) == [
            "provider",
            "baseURL",
            "apiKey",
            "model",
            "systemPrompt",
            "userPromptTemplate",
            "timeoutSeconds",
            "speechEnabled",
            "speechCommand"
        ])
    }

    @Test("TranslationConfigStore default config path uses current user home")
    func configStoreDefaultConfigPathUsesCurrentUserHome() {
        let expectedURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("idict")
            .appendingPathComponent("config.json")

        #expect(TranslationConfigStore.defaultConfigURL == expectedURL)
    }

    @Test("TranslationConfigStore reads existing config")
    func configStoreReadsExistingConfig() throws {
        let store = TranslationConfigStore(configURL: temporaryConfigURL())
        let config = TranslationConfig(
            provider: .openai,
            baseURL: "https://example.com/v1",
            apiKey: "test-key",
            model: "test-model",
            systemPrompt: "Translate only.",
            userPromptTemplate: "翻译成{{target}}：\n{{text}}",
            timeoutSeconds: 7
        )

        try store.save(config)

        #expect(try store.loadOrCreate() == config)
    }

    @Test("TranslationConfigStore updateProvider preserves other fields")
    func configStoreUpdateProviderPreservesOtherFields() throws {
        let store = TranslationConfigStore(configURL: temporaryConfigURL())
        let config = TranslationConfig(
            provider: .google,
            baseURL: "https://example.com/v1",
            apiKey: "test-key",
            model: "test-model",
            systemPrompt: "Translate only.",
            userPromptTemplate: "翻译成{{target}}：\n{{text}}",
            timeoutSeconds: 7
        )

        try store.save(config)
        try store.updateProvider(.openai)
        let updated = try store.loadOrCreate()

        #expect(updated.provider == .openai)
        #expect(updated.baseURL == config.baseURL)
        #expect(updated.apiKey == config.apiKey)
        #expect(updated.model == config.model)
        #expect(updated.systemPrompt == config.systemPrompt)
        #expect(updated.userPromptTemplate == config.userPromptTemplate)
        #expect(updated.timeoutSeconds == config.timeoutSeconds)
        #expect(updated.speechEnabled == config.speechEnabled)
        #expect(updated.speechCommand == config.speechCommand)
    }

    @Test("TranslationConfigStore fills missing fields")
    func configStoreFillsMissingFields() throws {
        let configURL = temporaryConfigURL()
        try FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let oldJSON = """
        {
          "provider": "google",
          "baseURL": "https://example.com/v1",
          "apiKey": "test-key",
          "model": "test-model",
          "timeoutSeconds": 7
        }
        """
        try Data(oldJSON.utf8).write(to: configURL)

        let store = TranslationConfigStore(configURL: configURL)
        let config = try store.loadOrCreate()
        let savedData = try Data(contentsOf: configURL)
        let savedJSON = try #require(String(data: savedData, encoding: .utf8))

        #expect(config.systemPrompt == TranslationConfig.defaultConfig.systemPrompt)
        #expect(config.userPromptTemplate == TranslationConfig.defaultConfig.userPromptTemplate)
        #expect(config.speechEnabled == TranslationConfig.defaultConfig.speechEnabled)
        #expect(config.speechCommand == TranslationConfig.defaultConfig.speechCommand)
        #expect(savedJSON.contains("\"systemPrompt\""))
        #expect(savedJSON.contains("\"userPromptTemplate\""))
        #expect(savedJSON.contains("\"speechEnabled\""))
        #expect(savedJSON.contains("\"speechCommand\""))
    }

    @Test("TranslationConfigStore reads speech config")
    func configStoreReadsSpeechConfig() throws {
        let store = TranslationConfigStore(configURL: temporaryConfigURL())
        let config = TranslationConfig(
            provider: .google,
            baseURL: "https://example.com/v1",
            apiKey: "",
            model: "test-model",
            systemPrompt: "Translate only.",
            userPromptTemplate: "翻译：\n{{text}}",
            timeoutSeconds: 7,
            speechEnabled: false,
            speechCommand: "/usr/local/bin/ispeak {{text}}"
        )

        try store.save(config)

        let savedConfig = try store.loadOrCreate()
        #expect(savedConfig.speechEnabled == false)
        #expect(savedConfig.speechCommand == "/usr/local/bin/ispeak {{text}}")
    }

    // MARK: - GoogleTranslationService Tests

    @Test("GoogleTranslationService translate handles empty string")
    func translateHandlesEmptyString() async {
        let result = await GoogleTranslationService.translate("")
        // Empty string should result in failed or empty success
        #expect(result.isFailure || result.isEmpty)
    }

    @Test("GoogleTranslationService translate returns TranslationResult")
    func translateReturnsTranslationResult() async {
        let result = await GoogleTranslationService.translate("test")
        #expect(result != nil)
        #expect(result is TranslationResult)
    }

    // MARK: - OpenAICompatibleTranslationService Tests

    @Test("OpenAICompatibleTranslationService builds chat completions URL")
    func openAICompatibleBuildsChatCompletionsURL() {
        let url = OpenAICompatibleTranslationService.chatCompletionsURL(baseURL: "https://example.com/v1/")
        #expect(url?.absoluteString == "https://example.com/v1/chat/completions")
    }

    @Test("OpenAICompatibleTranslationService parses translation response")
    func openAICompatibleParsesTranslationResponse() throws {
        let json = """
        {
          "choices": [
            {
              "message": {
                "content": "你好"
              }
            }
          ]
        }
        """
        let result = OpenAICompatibleTranslationService.parseTranslation(
            Data(json.utf8),
            originalText: "Hello"
        )

        #expect(result.text == "你好")
    }

    @Test("OpenAICompatibleTranslationService renders user prompt template")
    func openAICompatibleRendersUserPromptTemplate() {
        let rendered = OpenAICompatibleTranslationService.renderUserPrompt(
            "将下面的文本翻译为{{target}}：\n{{text}}",
            text: "Hello"
        )

        #expect(rendered == "将下面的文本翻译为简体中文：\nHello")
    }

    @Test("OpenAICompatibleTranslationService fails when api key is missing")
    func openAICompatibleFailsWhenAPIKeyIsMissing() async {
        var config = TranslationConfig.defaultConfig
        config.provider = .openai
        config.apiKey = ""

        let result = await OpenAICompatibleTranslationService.translate("Hello", config: config)

        #expect(result.isFailure)
        #expect(result.errorMessage?.contains("API Key") == true)
    }

    private func fieldOrder(in json: String) -> [String] {
        json
            .split(separator: "\n")
            .compactMap { line -> String? in
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                guard trimmedLine.hasPrefix("\""),
                      let endQuote = trimmedLine.dropFirst().firstIndex(of: "\"") else {
                    return nil
                }
                return String(trimmedLine[trimmedLine.index(after: trimmedLine.startIndex)..<endQuote])
            }
    }

    private func temporaryConfigURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("config.json")
    }
}
