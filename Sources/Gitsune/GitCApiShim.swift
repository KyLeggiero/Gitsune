//
//  GitCApiShim.swift
//
//
//  Created by Ky on 2024-07-12.
//  Using code by Brian Dewey
//

import Foundation

import Clibgit2



public enum GitCApiShim {}



public extension GitCApiShim {
    
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



public extension GitCApiShim {
    /// Returns a copy of the given pointer.
    ///
    /// libgit2 calls this "dup" (``git_reference_dup``), presumably as short for "dupe" because 4 characters is far too long a word.
    ///
    /// The returned copy **must** eventually be manually freed with ``git_reference_free``.
    ///
    /// - Parameter pointer: The pointer to copy
    /// - Returns: The copy of the given pointer
    /// - Throws: Anything thrown by ``git_reference_dup``
    static func copy(pointer: OpaquePointer) throws(GitError) -> OpaquePointer {
        var dupe: OpaquePointer?
        
        do {
            try GitCApiShim.call(apiName: "git_reference_dup") {
                git_reference_dup(&dupe, pointer)
            }
        }
        catch {
            throw error
        }
        
        guard let dupe else {
            throw GitError(rawValue: GIT_ERROR)
        }
        
        return dupe
    }
    
    
    /// Returns a copy of the given pointer.
    ///
    /// libgit2 calls this "dup" (``git_reference_dup``), presumably as short for "dupe" because 4 characters is far too long a word.
    ///
    /// The returned copy **must** eventually be manually freed with ``git_reference_free``.
    /// 
    /// - Parameters:
    ///   - pointer:        The pointer to copy
    ///   - errorConverter: Converts a git error into a bespoke one for your needs at the callsite
    ///
    /// - Returns: The copy of the given pointer
    ///
    /// - Throws: Anything thrown by ``git_reference_dup``
    static func copy<FinalError>(
        pointer: OpaquePointer,
        orThrow errorConverter: (GitError) -> FinalError)
    throws(FinalError) -> OpaquePointer
    where FinalError: Error
    {
        do {
            return try GitCApiShim.copy(pointer: pointer)
        }
        catch {
            throw errorConverter(error)
        }
    }
}
