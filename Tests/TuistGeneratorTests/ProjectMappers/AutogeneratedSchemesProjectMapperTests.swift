import Foundation
import TSCBasic
import TuistCore
import XCTest

@testable import TuistGenerator
@testable import TuistSupport
@testable import TuistSupportTesting

final class AutogeneratedSchemesProjectMapperTests: TuistUnitTestCase {
    var subject: AutogeneratedSchemesProjectMapper!

    override func setUp() {
        super.setUp()
        subject = AutogeneratedSchemesProjectMapper(enableCodeCoverage: false)
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    func test_map() throws {
        // Given
        let targetB = Target.test(name: "B")
        let targetBTests = Target.test(
            name: "BTests",
            product: .unitTests,
            dependencies: [.target(name: "B")]
        )
        let targetA = Target.test(
            name: "A",
            dependencies: [
                .target(name: "B"),
            ]
        )
        let targetATests = Target.test(
            name: "ATests",
            product: .unitTests,
            dependencies: [.target(name: "A")]
        )
        let projectPath = try temporaryPath()
        let project = Project.test(
            path: projectPath,
            targets: [
                targetA,
                targetATests,
                targetB,
                targetBTests,
            ]
        )

        // When
        let (got, sideEffects) = try subject.map(project: project)

        // Then
        XCTAssertEmpty(sideEffects)

        XCTAssertEqual(
            got.schemes,
            [
                testScheme(
                    target: targetA,
                    projectPath: projectPath,
                    testTargetName: "ATests"
                ),
                testScheme(
                    target: targetATests,
                    projectPath: projectPath,
                    testTargetName: "ATests"
                ),
                testScheme(
                    target: targetB,
                    projectPath: projectPath,
                    testTargetName: "BTests"
                ),
                testScheme(
                    target: targetBTests,
                    projectPath: projectPath,
                    testTargetName: "BTests"
                ),
            ]
        )
    }

    func test_map_doesnt_override_user_schemes() throws {
        // Given
        let targetA = Target.test(name: "A")
        let aScheme = Scheme.test(name: "A",
                                  shared: true,
                                  buildAction: nil,
                                  testAction: nil,
                                  runAction: nil,
                                  archiveAction: nil,
                                  profileAction: nil,
                                  analyzeAction: nil)
        let project = Project.test(targets: [targetA],
                                   schemes: [aScheme])

        // When
        let (got, sideEffects) = try subject.map(project: project)

        // Then
        XCTAssertEmpty(sideEffects)
        XCTAssertEqual(got.schemes.count, 1)

        // Then: A
        let gotAScheme = got.schemes.first!
        XCTAssertNil(gotAScheme.buildAction)
    }

    func test_map_appExtensions() throws {
        // Given
        let path = AbsolutePath("/test")
        let app = Target.test(name: "App",
                              product: .app,
                              dependencies: [
                                  .target(name: "AppExtension"),
                                  .target(name: "MessageExtension"),
                              ])
        let appExtension = Target.test(name: "AppExtension", product: .appExtension)
        let messageExtension = Target.test(name: "MessageExtension", product: .messagesExtension)

        let project = Project.test(path: path, targets: [app, appExtension, messageExtension])

        // When
        let (got, _) = try subject.map(project: project)

        // Then
        let buildActions = got.schemes.map(\.buildAction?.targets)
        XCTAssertEqual(buildActions, [
            [TargetReference(projectPath: path, name: "App")],
            [TargetReference(projectPath: path, name: "AppExtension"), TargetReference(projectPath: path, name: "App")],
            [TargetReference(projectPath: path, name: "MessageExtension"), TargetReference(projectPath: path, name: "App")],
        ])

        let runActions = got.schemes.map(\.runAction?.executable)
        XCTAssertEqual(runActions, [
            TargetReference(projectPath: path, name: "App"),
            TargetReference(projectPath: path, name: "App"), // Extensions set their host app as the runnable target
            TargetReference(projectPath: path, name: "App"), // Extensions set their host app as the runnable target
        ])
    }

    func test_map_enables_test_coverage_on_generated_schemes() throws {
        // Given
        subject = AutogeneratedSchemesProjectMapper(enableCodeCoverage: true)

        let targetA = Target.test(
            name: "A",
            dependencies: [
                .target(name: "B"),
            ]
        )
        let targetATests = Target.test(
            name: "ATests",
            product: .unitTests,
            dependencies: [.target(name: "A")]
        )
        let projectPath = try temporaryPath()
        let project = Project.test(
            path: projectPath,
            targets: [
                targetA,
                targetATests,
            ]
        )

        // When
        let (got, sideEffects) = try subject.map(project: project)

        // Then
        XCTAssertEmpty(sideEffects)
        XCTAssertEqual(got.schemes.count, 2)

        // Then: A Tests
        let gotAScheme = got.schemes.first!
        XCTAssertTrue(gotAScheme.testAction?.coverage != nil)
        XCTAssertEqual(gotAScheme.testAction?.codeCoverageTargets.count, 1)
    }

    // MARK: - Helpers

    private func testScheme(
        target: TuistCore.Target,
        projectPath: AbsolutePath,
        testTargetName: String
    ) -> TuistCore.Scheme {
        Scheme(
            name: target.name,
            shared: true,
            buildAction: BuildAction(
                targets: [
                    TargetReference(projectPath: projectPath, name: target.name),
                ]
            ),
            testAction: TestAction.test(
                targets: [
                    TestableTarget(target: TargetReference(projectPath: projectPath, name: testTargetName)),
                ],
                arguments: nil
            ),
            runAction: RunAction.test(
                executable: TargetReference(projectPath: projectPath, name: target.name),
                arguments: Arguments(environment: target.environment, launchArguments: target.launchArguments)
            )
        )
    }
}
