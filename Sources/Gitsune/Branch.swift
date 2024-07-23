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
    internal let __internallyManaged__pointer: OpaquePointer
    
    /// The name of this Git branch
    public let name: String
    
    
    deinit {
        git_reference_free(__internallyManaged__pointer)
    }
}



internal extension Branch {
    
    /// Performs a lookup for a branch of the given name in the given repo.
    ///
    /// If no branch of the given name can be found, this results in `nil`.
    ///
    /// - Parameters:
    ///   - name: The branch name to search for
    ///   - repo: The repo to search in
    ///
    /// - Throws: Any error that libgit throws
    init?(named name: String, in repo: borrowing Repo) throws(GitError) {
        
        // Get the branch pointer
        
        let branchPointer: OpaquePointer
        
        do {
            branchPointer = try GitCApiShim.call(apiName: "git_branch_lookup") { pointer in
                git_branch_lookup(&pointer, repo.__internallyManaged__repositoryPointer, name, GIT_BRANCH_LOCAL)
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
                
            case .failedToCopyPointer(gitError: let gitError):
                throw gitError
            }
        }
    }
    
    
    /// Uses the given pointer to find this branch in libgit2
    ///
    /// This assumes the given pointer is a value of type ``git_reference`` referencing a Git branch. If it isn't, then this returns `nil`
    ///
    /// - Parameter branchPointer: The C pointer to the brach, as used by libgit2
    init?(branchPointer: OpaquePointer) throws(InitError) {
        guard let cName = git_reference_name(branchPointer) else { throw .nameWasNull }
        
        self.__internallyManaged__pointer = try GitCApiShim.copy(pointer: branchPointer,
                                                                 orThrow: InitError.failedToCopyPointer)
        self.name = String(cString: cName)
    }
    
    
    /// An error in initialization of a ``Branch``
    enum InitError: LocalizedError {
        
        /// The C branch pointer was null
        case pointerWasNull
        
        /// Attempted to find the name of the branch, but the C library returned null
        case nameWasNull
        
        case failedToCopyPointer(gitError: GitError)
        
        
        var errorDescription: String? {
            String(localized: localizationKey)
        }
        
        
        var localizationKey: String.LocalizationValue {
            switch self {
            case .pointerWasNull:
                "ERROR.Branch.InitError.pointerWasNull"
            case .nameWasNull:
                "ERROR.Branch.InitError.nameWasNull"
                
            case .failedToCopyPointer(gitError: let gitError):
                "ERROR.Branch.InitError.nameWasNull+gitError: \(gitError.errorDescription ?? "No error description")"
            }
        }
    }
}
