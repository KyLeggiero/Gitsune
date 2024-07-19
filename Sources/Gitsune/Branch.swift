//
//  Branch.swift
//
//
//  Created by Ky on 2024-07-12.
//

import Foundation

import Clibgit2
import SimpleLogging



/// A Git branch
///
/// For information on what a Git branch is, see https://git-scm.com/docs/user-manual#what-is-a-branch
public struct Branch: ~Copyable {
    
    /// The low-level pointer to the Git branch, as consumed by libgit2
    internal let __pointer: OpaquePointer
    
    /// The name of this Git branch
    public let name: String
    
    
    deinit {
        git_reference_free(__pointer)
    }
}



internal extension Branch {
    
    init?(named name: String, in repo: borrowing Repo) throws(GitError) {
        
        // Get the branch pointer
        
        let branchPointer: OpaquePointer
        
        do {
            branchPointer = try GitCApiShim.call(apiName: "git_branch_lookup") { pointer in
                git_branch_lookup(&pointer, repo.__repositoryPointer, name, GIT_BRANCH_LOCAL)
            }
        }
        catch {
            if case GIT_ENOTFOUND = error.rawValue {
                return nil
            }
            else {
                throw error
            }
        }
        
        defer { git_reference_free(branchPointer) }
        
        
        // Init from the branch pointer
        
        do {
            try self.init(branchPointer: branchPointer)
        }
        catch {
            log(error: error, "Could not initialize a Git branch")
            
            switch error {
            case .pointerWasNull,
                    .nameWasNull:
                return nil
            }
        }
    }
    
    
    /// Uses the given pointer to find this branch in libgit2
    ///
    /// This assumes the given pointer is a value ``git_reference`` to a Git branch. If it isn't, then this returns `nil`
    ///
    /// - Parameter branchPointer: The C pointer to the brach, as used by libgit2
    init?(branchPointer: OpaquePointer) throws(InitError) {
        self.__pointer = branchPointer
        
        guard let cName = git_reference_name(branchPointer) else { return nil }
        self.name = String(cString: cName)
    }
    
    
    /// An error in initialization of a ``Branch``
    enum InitError: LocalizedError {
        
        /// The C branch pointer was null
        case pointerWasNull
        
        /// Attempted to find the name of the branch, but the C library returned null
        case nameWasNull
        
        
        var errorDescription: String? {
            String(localized: .init(localizationKey))
        }
        
        
        var localizationKey: String {
            switch self {
            case .pointerWasNull:
                "ERROR.\(Self.self).pointerWasNull"
            case .nameWasNull:
                "ERROR.\(Self.self).nameWasNull"
            }
        }
    }
}
