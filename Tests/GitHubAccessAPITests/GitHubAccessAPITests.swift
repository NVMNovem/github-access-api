import Testing
import GitHubAccessAPI

@Suite("GitHubAccessAPI")
struct GitHubAccessAPITests {

    @Test("Re-exports GitHubAccessModels, so one import is enough")
    func reExportsModels() throws {
        let link = try GitHubInstallLink(appSlug: "octoapp", state: "s")

        #expect(link.url.absoluteString == "https://github.com/apps/octoapp/installations/new?state=s")
    }

    @Test("SetupResult and SetupError keep their public shape")
    func setupTypesAreUnchanged() {
        let success: SetupResult = .success(12_345_678)
        let failure: SetupResult = .failure(SetupError.invalidInstallationID)

        #expect((try? success.get()) == 12_345_678)
        #expect(throws: SetupError.self) { try failure.get() }

        switch SetupError.unknown {
        case .invalidInstallationID, .unknown:
            break
        }
    }
}
