// Copyright © 2022 Brian Dewey, Ky. Available under the MIT License, see LICENSE for details.

import Clibgit2
import Foundation

/// Represents an error from an internal Clibgit2 API call.
public struct GitError: Error, RawRepresentable, CustomStringConvertible, LocalizedError, Sendable {
    
    /// The numeric error code from the Git API.
    public let rawValue: RawValue
    
    /// The name of the API that returned the error.
    public let apiName: String?
    
    /// A human-readable error message.
    public let message: String?
    
    
    public init?(rawValue: RawValue) {
        self.init(errorCode: rawValue)
    }
    
    
    init(errorCode: RawValue.RawValue, apiName: String? = nil, customMessage: String? = nil) {
        self.init(errorCode: .init(errorCode), apiName: apiName, customMessage: customMessage)
    }
    
    
    /// Initializer. Must be called on the same thread as the API call that generated the error to properly get the error message.
    init(errorCode: RawValue, apiName: String? = nil, customMessage: String? = nil) {
        self.rawValue = errorCode
        self.apiName = apiName
        
        if let customMessage {
            self.message = customMessage
        }
        else if let message = errorCode.errorMessage {
            self.message = message
        }
        else if let lastErrorPointer = git_error_last() {
            self.message = String(validatingUTF8: lastErrorPointer.pointee.message)
        }
        // GIT_ERROR_OS handled in `errorCode.errorMessage`
        else {
            self.message = nil
        }
    }
    
    
    public var description: String {
        "Error #\(rawValue.rawValue) calling \(apiName ?? "an unspecified API"): \(message ?? "<no message provided>")"
    }
    
    
    public var errorDescription: String? {
        description
    }
    
    
    
    public typealias RawValue = git_error_code
}



extension git_error_code: @retroactive CustomStringConvertible {
    public var description: String {
        errorMessage ?? "No error (or unspecified error)"
    }
    
    
    public var errorMessage: String? {
        // These are from the doc comments in libgit2's `errors.h`
        switch self {
        case GIT_OK:              nil

        case GIT_ERROR:           "Generic error"
        case GIT_ENOTFOUND:       "Requested object could not be found"
        case GIT_EEXISTS:         "Object exists preventing operation"
        case GIT_EAMBIGUOUS:      "More than one object matches"
        case GIT_EBUFS:           "Output buffer too short to hold data"

        case GIT_EUSER:           "Unspecified developer-generated error. See log for details."

        case GIT_EBAREREPO:       "Operation not allowed on bare repository"
        case GIT_EUNBORNBRANCH:   "HEAD refers to branch with no commits"
        case GIT_EUNMERGED:       "Merge in progress prevented operation"
        case GIT_ENONFASTFORWARD: "Reference was not fast-forwardable"
        case GIT_EINVALIDSPEC:    "Name/ref spec was not in a valid format"
        case GIT_ECONFLICT:       "Checkout conflicts prevented operation"
        case GIT_ELOCKED:         "Lock file prevented operation"
        case GIT_EMODIFIED:       "Reference value does not match expected"
        case GIT_EAUTH:           "Authentication error"
        case GIT_ECERTIFICATE:    "Server certificate is invalid"
        case GIT_EAPPLIED:        "Patch/merge has already been applied"
        case GIT_EPEEL:           "The requested peel operation is not possible"
        case GIT_EEOF:            "Unexpected end of file"
        case GIT_EINVALID:        "Invalid operation or input"
        case GIT_EUNCOMMITTED:    "Uncommitted changes in index prevented operation"
        case GIT_EDIRECTORY:      "The operation is not valid for a directory"
        case GIT_EMERGECONFLICT:  "A merge conflict exists and cannot continue"

        case GIT_PASSTHROUGH:     "A user-configured callback refused to act"
        case GIT_ITEROVER:        "Signals end of iteration with iterator"
        case GIT_RETRY:           "Internal only"
        case GIT_EMISMATCH:       "Hashsum mismatch in object"
        case GIT_EINDEXDIRTY:     "Unsaved changes in the index would be overwritten"
        case GIT_EAPPLYFAIL:      "Patch application failed"
            
        default:
            if let cErrorMessage = strerror(self.rawValue) {
                String(validatingCString: cErrorMessage)
            }
            else if GIT_ERROR_OS.rawValue == self.rawValue {
                String(validatingCString: strerror(errno))
            }
            else {
                nil
            }
        }
    }
}



@available(macOS 13, iOS 16, *)
extension git_error_code: @retroactive CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        .init(stringLiteral: description)
    }
}



extension GitError {
    @available(*, unavailable, renamed: "rawValue", message: "`errorCode` is AsyncLibGit's approach; Gitsune uses `rawValue`")
    var errorCode: RawValue { rawValue }
}
