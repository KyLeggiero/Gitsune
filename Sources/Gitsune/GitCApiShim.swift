//
//  GitCApiShim.swift
//
//
//  Created by Ky on 2024-07-12.
//

import Foundation

import Clibgit2



public enum GitCApiShim {
    
    /// Invokes a closure that invokes a Git API call and throws a `GitError` if the closure returns anything other than `GIT_OK`.
    static func call(apiName: String, closure: () -> git_error_code.RawValue) throws(GitError) {
        let result = closure()
        guard case GIT_OK.rawValue = result else {
            throw GitError(errorCode: result, apiName: apiName)
        }
    }
    
    static func call(apiName: String, closure: (inout OpaquePointer?) -> git_error_code.RawValue) throws(GitError) -> OpaquePointer {
        var pointer: OpaquePointer?
        let result = closure(&pointer)
        guard
            let returnedPointer = pointer,
            case GIT_OK.rawValue = result else {
            throw GitError(errorCode: result, apiName: apiName)
        }
        
        return returnedPointer
    }
    
    static func call(apiName: String, closure: (inout git_oid) -> git_error_code.RawValue) throws(GitError) -> ObjectID {
        var oid = git_oid()
        let result = closure(&oid)
        guard case GIT_OK.rawValue = result else {
            throw GitError(errorCode: result, apiName: apiName)
        }
        return ObjectID(oid)
    }
}
