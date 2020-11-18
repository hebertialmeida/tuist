import Foundation
import TSCBasic
@testable import TuistCore

final class MockGraphTraverser: GraphTraversing {
    var invokedNameGetter = false
    var invokedNameGetterCount = 0
    var stubbedName: String! = ""

    var name: String {
        invokedNameGetter = true
        invokedNameGetterCount += 1
        return stubbedName
    }

    var invokedHasPackagesGetter = false
    var invokedHasPackagesGetterCount = 0
    var stubbedHasPackages: Bool! = false

    var hasPackages: Bool {
        invokedHasPackagesGetter = true
        invokedHasPackagesGetterCount += 1
        return stubbedHasPackages
    }

    var invokedPathGetter = false
    var invokedPathGetterCount = 0
    var stubbedPath: AbsolutePath!

    var path: AbsolutePath {
        invokedPathGetter = true
        invokedPathGetterCount += 1
        return stubbedPath
    }

    var invokedWorkspaceGetter = false
    var invokedWorkspaceGetterCount = 0
    var stubbedWorkspace: Workspace!

    var workspace: Workspace {
        invokedWorkspaceGetter = true
        invokedWorkspaceGetterCount += 1
        return stubbedWorkspace
    }

    var invokedProjectsGetter = false
    var invokedProjectsGetterCount = 0
    var stubbedProjects: [AbsolutePath: Project]! = [:]

    var projects: [AbsolutePath: Project] {
        invokedProjectsGetter = true
        invokedProjectsGetterCount += 1
        return stubbedProjects
    }

    var invokedTarget = false
    var invokedTargetCount = 0
    var invokedTargetParameters: (path: AbsolutePath, name: String)?
    var invokedTargetParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedTargetResult: ValueGraphTarget!

    func target(path: AbsolutePath, name: String) -> ValueGraphTarget? {
        invokedTarget = true
        invokedTargetCount += 1
        invokedTargetParameters = (path, name)
        invokedTargetParametersList.append((path, name))
        return stubbedTargetResult
    }

    var invokedTargets = false
    var invokedTargetsCount = 0
    var invokedTargetsParameters: (path: AbsolutePath, Void)?
    var invokedTargetsParametersList = [(path: AbsolutePath, Void)]()
    var stubbedTargetsResult: Set<ValueGraphTarget>! = []

    func targets(at path: AbsolutePath) -> Set<ValueGraphTarget> {
        invokedTargets = true
        invokedTargetsCount += 1
        invokedTargetsParameters = (path, ())
        invokedTargetsParametersList.append((path, ()))
        return stubbedTargetsResult
    }

    var invokedDirectTargetDependencies = false
    var invokedDirectTargetDependenciesCount = 0
    var invokedDirectTargetDependenciesParameters: (path: AbsolutePath, name: String)?
    var invokedDirectTargetDependenciesParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedDirectTargetDependenciesResult: Set<ValueGraphTarget>! = []

    func directTargetDependencies(path: AbsolutePath, name: String) -> Set<ValueGraphTarget> {
        invokedDirectTargetDependencies = true
        invokedDirectTargetDependenciesCount += 1
        invokedDirectTargetDependenciesParameters = (path, name)
        invokedDirectTargetDependenciesParametersList.append((path, name))
        return stubbedDirectTargetDependenciesResult
    }

    var invokedAppExtensionDependencies = false
    var invokedAppExtensionDependenciesCount = 0
    var invokedAppExtensionDependenciesParameters: (path: AbsolutePath, name: String)?
    var invokedAppExtensionDependenciesParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedAppExtensionDependenciesResult: Set<ValueGraphTarget>! = []

    func appExtensionDependencies(path: AbsolutePath, name: String) -> Set<ValueGraphTarget> {
        invokedAppExtensionDependencies = true
        invokedAppExtensionDependenciesCount += 1
        invokedAppExtensionDependenciesParameters = (path, name)
        invokedAppExtensionDependenciesParametersList.append((path, name))
        return stubbedAppExtensionDependenciesResult
    }

    var invokedResourceBundleDependencies = false
    var invokedResourceBundleDependenciesCount = 0
    var invokedResourceBundleDependenciesParameters: (path: AbsolutePath, name: String)?
    var invokedResourceBundleDependenciesParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedResourceBundleDependenciesResult: Set<ValueGraphTarget>! = []

    func resourceBundleDependencies(path: AbsolutePath, name: String) -> Set<ValueGraphTarget> {
        invokedResourceBundleDependencies = true
        invokedResourceBundleDependenciesCount += 1
        invokedResourceBundleDependenciesParameters = (path, name)
        invokedResourceBundleDependenciesParametersList.append((path, name))
        return stubbedResourceBundleDependenciesResult
    }

    var invokedTestTargetsDependingOn = false
    var invokedTestTargetsDependingOnCount = 0
    var invokedTestTargetsDependingOnParameters: (path: AbsolutePath, name: String)?
    var invokedTestTargetsDependingOnParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedTestTargetsDependingOnResult: Set<ValueGraphTarget>! = []

    func testTargetsDependingOn(path: AbsolutePath, name: String) -> Set<ValueGraphTarget> {
        invokedTestTargetsDependingOn = true
        invokedTestTargetsDependingOnCount += 1
        invokedTestTargetsDependingOnParameters = (path, name)
        invokedTestTargetsDependingOnParametersList.append((path, name))
        return stubbedTestTargetsDependingOnResult
    }

    var invokedDirectStaticDependencies = false
    var invokedDirectStaticDependenciesCount = 0
    var invokedDirectStaticDependenciesParameters: (path: AbsolutePath, name: String)?
    var invokedDirectStaticDependenciesParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedDirectStaticDependenciesResult: Set<GraphDependencyReference>! = []

    func directStaticDependencies(path: AbsolutePath, name: String) -> Set<GraphDependencyReference> {
        invokedDirectStaticDependencies = true
        invokedDirectStaticDependenciesCount += 1
        invokedDirectStaticDependenciesParameters = (path, name)
        invokedDirectStaticDependenciesParametersList.append((path, name))
        return stubbedDirectStaticDependenciesResult
    }

    var invokedAppClipDependencies = false
    var invokedAppClipDependenciesCount = 0
    var invokedAppClipDependenciesParameters: (path: AbsolutePath, name: String)?
    var invokedAppClipDependenciesParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedAppClipDependenciesResult: ValueGraphTarget!

    func appClipDependencies(path: AbsolutePath, name: String) -> ValueGraphTarget? {
        invokedAppClipDependencies = true
        invokedAppClipDependenciesCount += 1
        invokedAppClipDependenciesParameters = (path, name)
        invokedAppClipDependenciesParametersList.append((path, name))
        return stubbedAppClipDependenciesResult
    }

    var invokedEmbeddableFrameworks = false
    var invokedEmbeddableFrameworksCount = 0
    var invokedEmbeddableFrameworksParameters: (path: AbsolutePath, name: String)?
    var invokedEmbeddableFrameworksParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedEmbeddableFrameworksResult: Set<GraphDependencyReference>! = []

    func embeddableFrameworks(path: AbsolutePath, name: String) -> Set<GraphDependencyReference> {
        invokedEmbeddableFrameworks = true
        invokedEmbeddableFrameworksCount += 1
        invokedEmbeddableFrameworksParameters = (path, name)
        invokedEmbeddableFrameworksParametersList.append((path, name))
        return stubbedEmbeddableFrameworksResult
    }

    var invokedLinkableDependencies = false
    var invokedLinkableDependenciesCount = 0
    var invokedLinkableDependenciesParameters: (path: AbsolutePath, name: String)?
    var invokedLinkableDependenciesParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedLinkableDependenciesError: Error?
    var stubbedLinkableDependenciesResult: Set<GraphDependencyReference>! = []

    func linkableDependencies(path: AbsolutePath, name: String) throws -> Set<GraphDependencyReference> {
        invokedLinkableDependencies = true
        invokedLinkableDependenciesCount += 1
        invokedLinkableDependenciesParameters = (path, name)
        invokedLinkableDependenciesParametersList.append((path, name))
        if let error = stubbedLinkableDependenciesError {
            throw error
        }
        return stubbedLinkableDependenciesResult
    }

    var invokedCopyProductDependencies = false
    var invokedCopyProductDependenciesCount = 0
    var invokedCopyProductDependenciesParameters: (path: AbsolutePath, name: String)?
    var invokedCopyProductDependenciesParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedCopyProductDependenciesResult: Set<GraphDependencyReference>! = []

    func copyProductDependencies(path: AbsolutePath, name: String) -> Set<GraphDependencyReference> {
        invokedCopyProductDependencies = true
        invokedCopyProductDependenciesCount += 1
        invokedCopyProductDependenciesParameters = (path, name)
        invokedCopyProductDependenciesParametersList.append((path, name))
        return stubbedCopyProductDependenciesResult
    }

    var invokedLibrariesPublicHeadersFolders = false
    var invokedLibrariesPublicHeadersFoldersCount = 0
    var invokedLibrariesPublicHeadersFoldersParameters: (path: AbsolutePath, name: String)?
    var invokedLibrariesPublicHeadersFoldersParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedLibrariesPublicHeadersFoldersResult: Set<AbsolutePath>! = []

    func librariesPublicHeadersFolders(path: AbsolutePath, name: String) -> Set<AbsolutePath> {
        invokedLibrariesPublicHeadersFolders = true
        invokedLibrariesPublicHeadersFoldersCount += 1
        invokedLibrariesPublicHeadersFoldersParameters = (path, name)
        invokedLibrariesPublicHeadersFoldersParametersList.append((path, name))
        return stubbedLibrariesPublicHeadersFoldersResult
    }

    var invokedLibrariesSearchPaths = false
    var invokedLibrariesSearchPathsCount = 0
    var invokedLibrariesSearchPathsParameters: (path: AbsolutePath, name: String)?
    var invokedLibrariesSearchPathsParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedLibrariesSearchPathsResult: Set<AbsolutePath>! = []

    func librariesSearchPaths(path: AbsolutePath, name: String) -> Set<AbsolutePath> {
        invokedLibrariesSearchPaths = true
        invokedLibrariesSearchPathsCount += 1
        invokedLibrariesSearchPathsParameters = (path, name)
        invokedLibrariesSearchPathsParametersList.append((path, name))
        return stubbedLibrariesSearchPathsResult
    }

    var invokedLibrariesSwiftIncludePaths = false
    var invokedLibrariesSwiftIncludePathsCount = 0
    var invokedLibrariesSwiftIncludePathsParameters: (path: AbsolutePath, name: String)?
    var invokedLibrariesSwiftIncludePathsParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedLibrariesSwiftIncludePathsResult: Set<AbsolutePath>! = []

    func librariesSwiftIncludePaths(path: AbsolutePath, name: String) -> Set<AbsolutePath> {
        invokedLibrariesSwiftIncludePaths = true
        invokedLibrariesSwiftIncludePathsCount += 1
        invokedLibrariesSwiftIncludePathsParameters = (path, name)
        invokedLibrariesSwiftIncludePathsParametersList.append((path, name))
        return stubbedLibrariesSwiftIncludePathsResult
    }

    var invokedRunPathSearchPaths = false
    var invokedRunPathSearchPathsCount = 0
    var invokedRunPathSearchPathsParameters: (path: AbsolutePath, name: String)?
    var invokedRunPathSearchPathsParametersList = [(path: AbsolutePath, name: String)]()
    var stubbedRunPathSearchPathsResult: Set<AbsolutePath>! = []

    func runPathSearchPaths(path: AbsolutePath, name: String) -> Set<AbsolutePath> {
        invokedRunPathSearchPaths = true
        invokedRunPathSearchPathsCount += 1
        invokedRunPathSearchPathsParameters = (path, name)
        invokedRunPathSearchPathsParametersList.append((path, name))
        return stubbedRunPathSearchPathsResult
    }
}
