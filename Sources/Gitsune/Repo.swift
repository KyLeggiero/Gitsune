//
//  Repo.swift
//
//
//  Created by Ky on 2024-07-12.
//

import Foundation

import Clibgit2



public struct Repo : ~Copyable {
    
    /// The Clibgit2 repository pointer managed by this actor.
    internal let __repositoryPointer: OpaquePointer

    /// If true, this class is the owner of `repositoryPointer` and should free it on deinit.
    private let isOwner: Bool

    /// The working directory of the repository, or `nil` if this is a bare repository.
    public nonisolated let workingDirectoryURL: URL?

    
    /// Creates a Git repository at the given location.
    ///
    /// - Parameters:
    ///   - url:               The location to create a Git repository at.
    ///   - defaultBranchName: _optional_ - The name of the default branch, which will be the first branch of th enew repo.
    ///                        Default is `"production"`
    ///   - bare:              _optional_ - Whether the repository should be "bare". A bare repository does not have a corresponding working directory.
    ///                        Default is `[.makeDirectoryIfNeeded]`
    public init(createAt url: URL, defaultBranchName: String = "production", options: InitOptions = [.makeDirectoryIfNeeded]) throws {
        let repositoryPointer = try GitCApiShim.call(apiName: "git_repository_init") { pointer in
            url.withUnsafeFileSystemRepresentation { fileSystemPath in
                defaultBranchName.withCString { branchNamePointer in
                    var cOptions = git_repository_init_options()
                    git_repository_init_options_init(&cOptions, UInt32(GIT_REPOSITORY_INIT_OPTIONS_VERSION))
                    cOptions.initial_head = branchNamePointer
                    cOptions.flags |= options.rawValue
                    return git_repository_init_ext(&pointer, fileSystemPath, &cOptions)
                }
            }
        }
        self.init(repositoryPointer: repositoryPointer, isOwner: true)
    }
    
    
    /// Opens a git repository at a specified location.
    /// - Parameter url: The location of the repository to open.
    public init(openAt url: URL) throws {
        let repositoryPointer = try GitCApiShim.call(apiName: "git_repository_open") { pointer in
            url.withUnsafeFileSystemRepresentation { fileSystemPath in
                git_repository_open(&pointer, fileSystemPath)
            }
        }
        self.init(repositoryPointer: repositoryPointer, isOwner: true)
    }
    
    
    init(repositoryPointer: OpaquePointer, isOwner: Bool) {
        self.__repositoryPointer = repositoryPointer
        self.isOwner = isOwner
        
        if let pathPointer = git_repository_workdir(repositoryPointer),
           let path = String(validatingCString: pathPointer)
        {
            self.workingDirectoryURL = URL(fileURLWithPath: path, isDirectory: true)
        }
        else {
            self.workingDirectoryURL = nil
        }
    }
    
    
    deinit {
        if isOwner {
            git_repository_free(__repositoryPointer)
        }
    }
}



public extension Repo {
    struct InitOptions: OptionSet {
        
        public var rawValue: RawValue
        
        
        public enum Value: git_repository_init_flag_t.RawValue, CaseIterable {
            case bare                  = 0b0_______1 //  1 << 0  ==  GIT_REPOSITORY_INIT_BARE
            case noReinit              = 0b0______10 //  1 << 1  ==  GIT_REPOSITORY_INIT_NO_REINIT
            case noDotGitDirectory     = 0b0_____100 //  1 << 2  ==  GIT_REPOSITORY_INIT_NO_DOTGIT_DIR
            case makeDirectoryIfNeeded = 0b0____1000 //  1 << 3  ==  GIT_REPOSITORY_INIT_MKDIR
            case makePathIfNeeded      = 0b0___10000 //  1 << 4  ==  GIT_REPOSITORY_INIT_MKPATH
            case externalTemplate      = 0b0__100000 //  1 << 5  ==  GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE
            case userRelativeLinks     = 0b0_1000000 //  1 << 6  ==  GIT_REPOSITORY_INIT_RELATIVE_GITLINK
        }
        
        
        public init(_ old: git_repository_init_flag_t) {
            self.init(rawValue: old.rawValue)
        }
        
        
        public init(arrayLiteral elements: Value...) {
            self.init(rawValue: elements
                .reduce(into: RawValue()) { rawValue, element in
                    rawValue |= element.rawValue
                }
            )
        }
        
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        
        
        public typealias RawValue = Value.RawValue
    }
}



extension git_repository_init_flag_t: @retroactive OptionSet {
    
}



public extension Repo {
    func findBranch(named name: String) throws(GitError) -> Branch? {
        try .init(named: name, in: self)
//        do {
//            let branchPointer = try GitCApiShim.call(apiName: "git_branch_lookup") { pointer in
//                git_branch_lookup(&pointer, __repositoryPointer, name, GIT_BRANCH_LOCAL)
//            }
//            
//            defer { git_reference_free(branchPointer) }
//            return try .init(branchPointer: branchPointer)
//        }
//        catch let error as GitError {
//            if error.rawValue == GIT_ENOTFOUND {
//                return nil
//            }
//            else {
//                throw error
//            }
//        }
//        catch let error as Branch.InitError {
//            switch error {
//            case .pointerWasNull:
//                return nil
//            case .nameWasNull:
//                return nil
//            }
//        }
    }
}
