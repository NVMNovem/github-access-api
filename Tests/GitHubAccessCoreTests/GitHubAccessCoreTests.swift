import Foundation
import Testing
@testable import GitHubAccessCore

@Test func repositoryDecodesOwnerLogin() throws {
    let json = """
    {
        "id": 42,
        "name": "github-access-api",
        "full_name": "NVMNovem/github-access-api",
        "owner": { "login": "NVMNovem" },
        "private": true,
        "default_branch": "main",
        "clone_url": "https://github.com/NVMNovem/github-access-api.git",
        "html_url": "https://github.com/NVMNovem/github-access-api"
    }
    """.data(using: .utf8)!

    let repository = try JSONDecoder().decode(GitHubRepository.self, from: json)

    #expect(repository.owner == "NVMNovem")
    #expect(repository.fullName == "NVMNovem/github-access-api")
}
