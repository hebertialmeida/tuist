import Foundation
import TSCBasic
import TuistSupport

public class ValueGraphTraverser: GraphTraversing {
    public var name: String { graph.name }
    public var hasPackages: Bool { !graph.packages.flatMap(\.value).isEmpty }
    public var path: AbsolutePath { graph.path }
    public var workspace: Workspace { graph.workspace }
    public var projects: [AbsolutePath: Project] { graph.projects }

    private let graph: ValueGraph

    public required init(graph: ValueGraph) {
        self.graph = graph
    }

    public func target(path: AbsolutePath, name: String) -> ValueGraphTarget? {
        guard let project = graph.projects[path], let target = graph.targets[path]?[name] else { return nil }
        return ValueGraphTarget(path: path, target: target, project: project)
    }

    public func targets(at path: AbsolutePath) -> Set<ValueGraphTarget> {
        guard let project = graph.projects[path] else { return Set() }
        guard let targets = graph.targets[path] else { return [] }
        return Set(targets.values.map { ValueGraphTarget(path: path, target: $0, project: project) })
    }

    public func directTargetDependencies(path: AbsolutePath, name: String) -> Set<ValueGraphTarget> {
        guard let dependencies = graph.dependencies[.target(name: name, path: path)] else { return [] }
        guard let project = graph.projects[path] else { return Set() }

        return Set(dependencies.flatMap { (dependency) -> [ValueGraphTarget] in
            guard case let ValueGraphDependency.target(dependencyName, dependencyPath) = dependency else { return [] }
            guard let projectDependencies = graph.targets[dependencyPath], let dependencyTarget = projectDependencies[dependencyName] else { return []
            }
            return [ValueGraphTarget(path: path, target: dependencyTarget, project: project)]
        })
    }

    public func resourceBundleDependencies(path: AbsolutePath, name: String) -> Set<ValueGraphTarget> {
        guard let project = graph.projects[path] else { return Set() }
        guard let target = graph.targets[path]?[name] else { return [] }
        guard target.supportsResources else { return [] }

        let canHostResources: (ValueGraphDependency) -> Bool = {
            self.target(from: $0)?.supportsResources == true
        }

        let isBundle: (ValueGraphDependency) -> Bool = {
            self.target(from: $0)?.product == .bundle
        }

        let bundles = filterDependencies(from: .target(name: name, path: path),
                                         test: isBundle,
                                         skip: canHostResources)
        let bundleTargets = bundles.compactMap(target(from:)).map { ValueGraphTarget(path: path, target: $0, project: project) }

        return Set(bundleTargets)
    }

    public func testTargetsDependingOn(path: AbsolutePath, name: String) -> Set<ValueGraphTarget> {
        guard let project = graph.projects[path] else { return Set() }

        return Set(graph.targets[path]?.values
            .filter { $0.product.testsBundle }
            .filter { graph.dependencies[.target(name: $0.name, path: path)]?.contains(.target(name: name, path: path)) == true }
            .map { ValueGraphTarget(path: path, target: $0, project: project) } ?? [])
    }

    public func target(from dependency: ValueGraphDependency) -> Target? {
        guard case let ValueGraphDependency.target(name, path) = dependency else {
            return nil
        }
        return graph.targets[path]?[name]
    }

    public func appExtensionDependencies(path: AbsolutePath, name: String) -> Set<ValueGraphTarget> {
        let validProducts: [Product] = [
            .appExtension, .stickerPackExtension, .watch2Extension, .messagesExtension,
        ]
        return Set(directTargetDependencies(path: path, name: name)
            .filter { validProducts.contains($0.target.product) })
    }

    public func appClipDependencies(path: AbsolutePath, name: String) -> ValueGraphTarget? {
        directTargetDependencies(path: path, name: name)
            .first { $0.target.product == .appClip }
    }

    public func directStaticDependencies(path: AbsolutePath, name: String) -> Set<GraphDependencyReference> {
        Set(graph.dependencies[.target(name: name, path: path)]?
            .compactMap { (dependency: ValueGraphDependency) -> (path: AbsolutePath, name: String)? in
                guard case let ValueGraphDependency.target(name, path) = dependency else {
                    return nil
                }
                return (path, name)
            }
            .compactMap { graph.targets[$0.path]?[$0.name] }
            .filter { $0.product.isStatic }
            .map { .product(target: $0.name, productName: $0.productNameWithExtension) } ?? [])
    }

    /// It traverses the depdency graph and returns all the dependencies.
    /// - Parameter path: Path to the project from where traverse the dependency tree.
    public func allDependencies(path: AbsolutePath) -> Set<ValueGraphDependency> {
        guard let targets = graph.targets[path]?.values else { return Set() }

        var references = Set<ValueGraphDependency>()

        targets.forEach { target in
            let dependency = ValueGraphDependency.target(name: target.name, path: path)
            references.formUnion(filterDependencies(from: dependency))
        }

        return references
    }

    public func embeddableFrameworks(path: AbsolutePath, name: String) -> Set<GraphDependencyReference> {
        guard let target = self.target(path: path, name: name), canEmbedProducts(target: target.target) else { return Set() }

        var references: Set<GraphDependencyReference> = Set([])

        /// Precompiled frameworks
        let precompiledFrameworks = filterDependencies(from: .target(name: name, path: path),
                                                       test: isDependencyDynamicAndLinkable,
                                                       skip: canDependencyEmbedProducts)
            .lazy
            .compactMap(dependencyReference)
        references.formUnion(precompiledFrameworks)

        /// Other targets' frameworks.
        let otherTargetFrameworks = filterDependencies(from: .target(name: name, path: path),
                                                       test: isDependencyFramework,
                                                       skip: canDependencyEmbedProducts)
            .lazy
            .compactMap(dependencyReference)
        references.formUnion(otherTargetFrameworks)

        // Exclude any products embed in unit test host apps
        if target.target.product == .unitTests {
            if let hostApp = hostApplication(path: path, name: name) {
                references.subtract(embeddableFrameworks(path: hostApp.path, name: hostApp.target.name))
            } else {
                references = Set()
            }
        }

        return references
    }

    public func linkableDependencies(path _: AbsolutePath, name _: String) throws -> Set<GraphDependencyReference> {
        Set()
//        guard let targetNode = findTargetNode(path: path, name: name) else {
//            return []
//        }
//
//        var references = Set<GraphDependencyReference>()
//
//        // System libraries and frameworks
//
//        if targetNode.target.canLinkStaticProducts() {
//            let transitiveSystemLibraries = transitiveStaticTargetNodes(for: targetNode).flatMap {
//                $0.sdkDependencies.map {
//                    GraphDependencyReference.sdk(path: $0.path, status: $0.status, source: $0.source)
//                }
//            }
//
//            references = references.union(transitiveSystemLibraries)
//        }
//
//        if targetNode.target.isAppClip {
//            let path = try SDKNode.appClip(status: .required).path
//            references.insert(GraphDependencyReference.sdk(path: path,
//                                                           status: .required,
//                                                           source: .system))
//        }
//
//        let directSystemLibrariesAndFrameworks = targetNode.sdkDependencies.map {
//            GraphDependencyReference.sdk(path: $0.path, status: $0.status, source: $0.source)
//        }
//
//        references = references.union(directSystemLibrariesAndFrameworks)
//
//        // Precompiled libraries and frameworks
//
//        let precompiledLibrariesAndFrameworks = targetNode.precompiledDependencies
//            .lazy
//            .map(GraphDependencyReference.init)
//
//        references = references.union(precompiledLibrariesAndFrameworks)
//
//        // Static libraries and frameworks / Static libraries' dynamic libraries
//
//        if targetNode.target.canLinkStaticProducts() {
//            var staticLibraryTargetNodes = transitiveStaticTargetNodes(for: targetNode)
//
//            // Exclude any static products linked in a host application
//            if targetNode.target.product == .unitTests {
//                if let hostApp = hostApplication(for: targetNode) {
//                    staticLibraryTargetNodes.subtract(transitiveStaticTargetNodes(for: hostApp))
//                }
//            }
//
//            let staticLibraries = staticLibraryTargetNodes.map(productDependencyReference)
//
//            let staticDependenciesDynamicLibraries = staticLibraryTargetNodes.flatMap {
//                $0.targetDependencies
//                    .filter(or(isFramework, isDynamicLibrary))
//                    .map(productDependencyReference)
//            }
//
//            references = references.union(staticLibraries + staticDependenciesDynamicLibraries)
//        }
//
//        // Link dynamic libraries and frameworks
//
//        let dynamicLibrariesAndFrameworks = targetNode.targetDependencies
//            .filter(or(isFramework, isDynamicLibrary))
//            .map(productDependencyReference)
//
//        references = references.union(dynamicLibrariesAndFrameworks)
//        return Array(references).sorted()
    }

    public func copyProductDependencies(path: AbsolutePath, name: String) -> Set<GraphDependencyReference> {
        guard let target = self.target(path: path, name: name) else { return Set() }

        var dependencies = Set<GraphDependencyReference>()

        if target.target.product.isStatic {
            dependencies.formUnion(directStaticDependencies(path: path, name: name))
        }

        dependencies.formUnion(resourceBundleDependencies(path: path, name: name).map(targetProductReference))

        return Set(dependencies)
    }

    public func librariesPublicHeadersFolders(path: AbsolutePath, name: String) -> Set<AbsolutePath> {
        let dependencies = graph.dependencies[.target(name: name, path: path), default: []]
        let libraryPublicHeaders = dependencies.compactMap { dependency -> AbsolutePath? in
            guard case let ValueGraphDependency.library(_, publicHeaders, _, _, _) = dependency else { return nil }
            return publicHeaders
        }
        return Set(libraryPublicHeaders)
    }

    public func librariesSearchPaths(path: AbsolutePath, name: String) -> Set<AbsolutePath> {
        let dependencies = graph.dependencies[.target(name: name, path: path), default: []]
        let libraryPaths = dependencies.compactMap { dependency -> AbsolutePath? in
            guard case let ValueGraphDependency.library(path, _, _, _, _) = dependency else { return nil }
            return path
        }
        return Set(libraryPaths.compactMap { $0.removingLastComponent() })
    }

    public func librariesSwiftIncludePaths(path: AbsolutePath, name: String) -> Set<AbsolutePath> {
        let dependencies = graph.dependencies[.target(name: name, path: path), default: []]
        let librarySwiftModuleMapPaths = dependencies.compactMap { dependency -> AbsolutePath? in
            guard case let ValueGraphDependency.library(_, _, _, _, swiftModuleMapPath) = dependency else { return nil }
            return swiftModuleMapPath
        }
        return Set(librarySwiftModuleMapPaths.compactMap { $0.removingLastComponent() })
    }

    public func runPathSearchPaths(path: AbsolutePath, name: String) -> Set<AbsolutePath> {
        guard let target = target(path: path, name: name),
            canEmbedProducts(target: target.target),
            target.target.product == .unitTests,
            hostApplication(path: path, name: name) == nil
        else {
            return Set()
        }

        var references: Set<AbsolutePath> = Set([])

        let from = ValueGraphDependency.target(name: name, path: path)
        let precompiledFramewoksPaths = filterDependencies(from: from,
                                                           test: isDependencyDynamicAndLinkable,
                                                           skip: canDependencyEmbedProducts)
            .lazy
            .compactMap { (dependency: ValueGraphDependency) -> AbsolutePath? in
                switch dependency {
                case let .xcframework(path, _, _, _): return path
                case let .framework(path, _, _, _, _, _, _, _): return path
                case .library: return nil
                case .packageProduct: return nil
                case .target: return nil
                case .sdk: return nil
                case .cocoapods: return nil
                }
            }
            .map(\.parentDirectory)

        references.formUnion(precompiledFramewoksPaths)
        return references
    }

    // MARK: - Internal

    /// The method collects the dependencies that are selected by the provided test closure.
    /// The skip closure allows skipping the traversing of a specific dependendency branch.
    /// - Parameters:
    ///   - from: Dependency from which the traverse is done.
    ///   - test: If the closure returns true, the dependency is included.
    ///   - skip: If the closure returns false, the traversing logic doesn't traverse the dependencies from that dependency.
    func filterDependencies(from rootDependency: ValueGraphDependency,
                            test: (ValueGraphDependency) -> Bool = { _ in true },
                            skip: (ValueGraphDependency) -> Bool = { _ in false }) -> Set<ValueGraphDependency>
    {
        var stack = Stack<ValueGraphDependency>()

        stack.push(rootDependency)

        var visited: Set<ValueGraphDependency> = .init()
        var references = Set<ValueGraphDependency>()

        while !stack.isEmpty {
            guard let node = stack.pop() else {
                continue
            }

            if visited.contains(node) {
                continue
            }

            visited.insert(node)

            if node != rootDependency, test(node) {
                references.insert(node)
            }

            if node != rootDependency, skip(node) {
                continue
            }

            graph.dependencies[node]?.forEach { nodeDependency in
                if !visited.contains(nodeDependency) {
                    stack.push(nodeDependency)
                }
            }
        }

        return references
    }

    func targetProductReference(target: ValueGraphTarget) -> GraphDependencyReference {
        .product(target: target.target.name, productName: target.target.productNameWithExtension)
    }

    func isDependencyFramework(dependency: ValueGraphDependency) -> Bool {
        switch dependency {
        case .xcframework: return true
        case .framework: return true
        case .library: return false
        case .packageProduct: return false
        case .target: return false
        case .sdk: return false
        case .cocoapods: return false
        }
    }

    func isDependencyDynamicAndLinkable(dependency: ValueGraphDependency) -> Bool {
        switch dependency {
        case let .xcframework(_, _, _, linking): return linking == .dynamic
        case let .framework(_, _, _, _, linking, _, _, _): return linking == .dynamic
        case .library: return false
        case .packageProduct: return false
        case .target: return false
        case .sdk: return false
        case .cocoapods: return false
        }
    }

    func canDependencyEmbedProducts(dependency: ValueGraphDependency) -> Bool {
        guard case let ValueGraphDependency.target(name, path) = dependency,
            let target = self.target(path: path, name: name) else { return false }
        return canEmbedProducts(target: target.target)
    }

    func hostApplication(path: AbsolutePath, name: String) -> ValueGraphTarget? {
        directTargetDependencies(path: path, name: name)
            .first(where: { $0.target.product == .app })
    }

    func canEmbedProducts(target: Target) -> Bool {
        let validProducts: [Product] = [
            .app,
            .unitTests,
            .uiTests,
            .watch2Extension,
        ]
        return validProducts.contains(target.product)
    }

    func dependencyReference(dependency: ValueGraphDependency) -> GraphDependencyReference? {
        switch dependency {
        case .cocoapods:
            return nil
        case let .framework(path, binaryPath, dsymPath, bcsymbolmapPaths, linking, architectures, product, isCarthage):
            return .framework(path: path,
                              binaryPath: binaryPath,
                              isCarthage: isCarthage,
                              dsymPath: dsymPath,
                              bcsymbolmapPaths: bcsymbolmapPaths,
                              linking: linking,
                              architectures: architectures,
                              product: product)
        case let .library(path, _, linking, architectures, _):
            return .library(path: path,
                            linking: linking,
                            architectures: architectures,
                            product: (linking == .static) ? .staticLibrary : .dynamicLibrary)
        case .packageProduct:
            return nil
        case let .sdk(_, path, status, source):
            return .sdk(path: path,
                        status: status,
                        source: source)
        case let .target(name, path):
            guard let target = self.target(path: path, name: name) else { return nil }
            return .product(target: target.target.name, productName: target.target.productNameWithExtension)
        case let .xcframework(path, infoPlist, primaryBinaryPath, _):
            return .xcframework(path: path,
                                infoPlist: infoPlist,
                                primaryBinaryPath: primaryBinaryPath,
                                binaryPath: primaryBinaryPath)
        }
    }
}
