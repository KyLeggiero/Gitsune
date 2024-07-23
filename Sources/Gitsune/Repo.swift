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
    internal let __internallyManaged__repositoryPointer: OpaquePointer

    /// The working directory of the repository, or `nil` if this is a bare repository.
    public nonisolated let workingDirectoryURL: URL?

    
    /// Creates a Git repository at the given location.
    ///
    /// - Parameters:
    ///   - url:               The location to create a Git repository at.
    ///   - defaultBranchName: _optional_ - The name of the default branch, which will be the first branch of th enew repo.
    ///                        Default is `"production"`
    ///   - bare:              _optional_ - Whether the repository should be "bare". A bare repository does not have a corresponding working directory.
    ///                        Default is `.default`
    /*public init*/
    public static func `init`(createAt url: URL, defaultBranchName: String = "production", options: Options = .default) throws(GitError) -> Self {
        try self.init(
            repositoryPointer: try GitCApiShim.call(apiName: "git_repository_init") { repositoryPointer in
                url.withUnsafeFileSystemRepresentation { fileSystemPath in
                    defaultBranchName.withCString { branchNamePointer in
                        var c_options = git_repository_init_options()
                        git_repository_init_options_init(&c_options, UInt32(GIT_REPOSITORY_INIT_OPTIONS_VERSION))
                        c_options.initial_head = branchNamePointer
                        c_options.set(with: options)
                        return git_repository_init_ext(&repositoryPointer, fileSystemPath, &c_options)
                    }
                }
            })
    }
    
    
    /// Opens a git repository at a specified location.
    /// - Parameter url: The location of the repository to open.
    /*public init*/
    public static func `init`(openAt url: URL) throws(GitError) -> Self {
        try self.init(
            repositoryPointer: try GitCApiShim.call(apiName: "git_repository_open") { pointer in
                url.withUnsafeFileSystemRepresentation { fileSystemPath in
                    git_repository_open(&pointer, fileSystemPath)
                }
            })
    }
    
    
    /// Uses the given C pointer from libgit2 to create an instance of this struct
    ///
    /// - Parameters:
    ///   - repositoryPointer: The C pointer to a branch from libgit2
    init(repositoryPointer: OpaquePointer) throws(GitError) {
        self.__internallyManaged__repositoryPointer = try GitCApiShim.copy(pointer: repositoryPointer) // maybe not the best idea. Will need to test and see how this plays out. If it turns out to thrash the memory too hard, then We might need to introduce a sort of SafePointer to re-introduce COW behavior
        
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
        git_repository_free(__internallyManaged__repositoryPointer)
    }
}



public extension Repo {
    
    /// Options for `Repo.init`
    struct Options: Sendable {
        
        var flags: InitFlags
        
        /// The file mode (like from `chmod`)
        var mode: Mode?
        
        /// The path to the working dir or `nil` for default (i.e. repo_path parent on non-bare repos).
        ///
        /// - Attention: If this is a relative path, it will be evaluated to the repo_path.
        ///              If this is not the "natural" working directory, a .git gitlink file will be created here linking to the repo_path.
        var workingDirectory: URL?
        
        /// When `.externalTemplate` is saved in ``flags``, this contains the path to use for the template directory.
        ///
        /// If this is `nil`, the config or default directory options will be used instead.
        var template: URL?
        
        /// If set, this will be used to initialize the "description" file in the repository, instead of using the template content.
        var description: String?
        
        /// If this is non-`nil`, then after the rest of the repository initialization is completed, an "origin" remote will be added pointing to this URL.
        var origin: URL?
    }
    
    
    
    /// Option flags for `Repo.init`.
    ///
    /// A Swifty version of ``git_repository_init_flag_t``.
    ///
    /// The best way to create one of these is as a collection of its ``Value`` subtype, like `[.bare, .makePathIfNeeded]`
    ///
    /// In every case, the default behavior is assuming you didn't choose that option.
    struct InitFlags: OptionSet, Sendable {
        
        public var rawValue: RawValue
        
        
        public enum Value: git_repository_init_flag_t.RawValue, CaseIterable {
            
            /// Create a bare repository with no working directory.
            case bare                  = 0b0_______1 //  1 << 0  ==  GIT_REPOSITORY_INIT_BARE
            
            /// Return an GIT_EEXISTS error if the repo_path appears to already be an git repository.
            case noReinit              = 0b0______10 //  1 << 1  ==  GIT_REPOSITORY_INIT_NO_REINIT
            
            /// Normally a "/.git/" will be appended to the repo path for non-bare repos (if it is not already there), but passing this flag prevents that behavior.
            case noDotGitDirectory     = 0b0_____100 //  1 << 2  ==  GIT_REPOSITORY_INIT_NO_DOTGIT_DIR
            
            /// Make the repo_path (and workdir_path) as needed. Init is always willing to create the ".git" directory even without this flag. This flag tells init to create the trailing component of the repo and workdir paths as needed.
            case makeDirectoryIfNeeded = 0b0____1000 //  1 << 3  ==  GIT_REPOSITORY_INIT_MKDIR
            
            /// Recursively make all components of the repo and workdir paths as necessary.
            case makePathIfNeeded      = 0b0___10000 //  1 << 4  ==  GIT_REPOSITORY_INIT_MKPATH
            
            /// The default behavior is to use internally-defined templates to initialize a new repo. This flags allows you to specify external templates, looking at the "template_path" from the options if set, or the `init.templatedir` global config if not, or falling back on "/usr/share/git-core/templates" if it exists.
            case externalTemplate      = 0b0__100000 //  1 << 5  ==  GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE
            
            /// If an alternate workdir is specified, use relative paths for the gitdir and core.worktree.
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
    
    
    
    /// The mode by which to initialize a repository.
    ///
    /// A Swifty version of ``git_repository_init_mode_t``.
    ///
    /// Set the `mode` field of ``Options`` either to the custom mode that you would like, or to one of these defined modes.
    enum PredefinedMode: git_repository_init_mode_t.RawValue, CaseIterable, Sendable {
        case umask = 0
        case group = 0002775
        case all   = 0002777
    }
    
    
    
    typealias Mode = PredefinedOrCustomRaw<PredefinedMode>
}



public extension Repo.Options {
    static let `default` = Self.init(flags: [.makeDirectoryIfNeeded])
}



public extension git_repository_init_options {
    
    /// Sets all fields of this to the corresponding fields of the given value
    ///
    /// - Parameter options: The Swifty options to use to set the fields in this object
    mutating func set(with options: Repo.Options) {
        self.flags |= options.flags.rawValue
        
        if let mode = options.mode?.rawValue {
            self.mode = mode
        }
        
        options.origin?.description.withCString { c_originUrl in
            self.origin_url = c_originUrl
        }
        
        options.template?.withUnsafeFileSystemRepresentation { c_templateFile in
            self.template_path = c_templateFile
        }
        
        options.workingDirectory?.description.withCString { c_workingDirectoryPath in
            self.workdir_path = c_workingDirectoryPath
        }
        
        options.description?.withCString { c_description in
            self.description = c_description
        }
    }
}



// MARK: - Branches

public extension Repo {
    
    /// Performs a lookup for a branch of the given name in the given repo.
    ///  
    /// If no branch of the given name can be found, this returns `nil`.
    ///
    /// - Parameters:
    ///   - name: The branch name to search for
    ///
    /// - Returns: The branch of the given name, or `nil` if none could be found
    ///
    /// - Throws: Any error that libgit throws
    func findBranch(named name: String) throws(GitError) -> Branch? {
        try .init(named: name, in: self)
    }
}
