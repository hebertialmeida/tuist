import Foundation
import TSCBasic

public struct ValueGraphTarget: Equatable, Hashable, Comparable {
    /// Path to the directory that contains the project where the target is defined.
    public let path: AbsolutePath

    /// Target representation.
    public let target: Target

    /// Project that contains the target.
    public let project: Project

    public static func < (lhs: ValueGraphTarget, rhs: ValueGraphTarget) -> Bool {
        (lhs.path, lhs.target) < (rhs.path, rhs.target)
    }
}
