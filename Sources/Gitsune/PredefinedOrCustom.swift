//
//  PredefinedOrCustom.swift
//  Gitsune
//
//  Created by Ky on 2024-07-21.
//

import Foundation



public typealias PredefinedOrCustomRaw<Predefined: RawRepresentable> = PredefinedOrCustom<Predefined, Predefined.RawValue>



/// Either a pre-defined case (usually hard-coded by the dev) or a custom case (usually loaded / user input)
public enum PredefinedOrCustom<Predefined, Custom> {
    case predefined(Predefined)
    case custom(Custom)
}



extension PredefinedOrCustom: CaseIterable where Predefined: CaseIterable {
    public static var allCases: [Self] {
        Predefined.allCases.map(Self.predefined)
    }
}



extension PredefinedOrCustom: RawRepresentable
where Predefined: RawRepresentable,
      Custom == Predefined.RawValue,
      Custom: Equatable,
      Predefined: CaseIterable
{
    
    /// Searches all predefined cases If any exactly match the given raw value then this creates a predefined value using that found case.
    /// If none exaxtly match the given raw value, then this creates a custom case using that value.
    public init(rawValue: RawValue) {
        if let predefined = Predefined.allCases.first(where: { $0.rawValue == rawValue }) {
            self = .predefined(predefined)
        }
        else {
            self = .custom(rawValue)
        }
    }
    
    
    /// The custom value, or the raw version of the predefined value
    public var rawValue: RawValue {
        switch self {
        case .predefined(let predefined): predefined.rawValue
        case .custom(let custom):         custom
        }
    }
    
    
    
    public typealias RawValue = Custom
}



extension PredefinedOrCustom: Sendable where Predefined: Sendable, Custom: Sendable {}
