//
//  Route.swift
//
//
//  Created by Frank van Boheemen on 24/05/2024.
//

import Foundation

public enum Route<Destination>: RouteDescribing {
    case push(Destination)
    case overlay(Destination)
    case sheet(Destination, onDismiss: (() -> Void)?)
    case cover(Destination, onDismiss: (() -> Void)?)
}

public extension Route {
    var destination: Destination {
        switch self {
        case let .push(destination),
             let .overlay(destination),
             let .sheet(destination, _),
             let .cover(destination, _):
            return destination
        }
    }

    var onDismiss: (() -> Void)? {
        switch self {
        case let .sheet(_, onDismiss),
             let .cover(_, onDismiss):
            return onDismiss
        case .push, .overlay:
            return nil
        }
    }
}

extension Route: Equatable where Destination: Equatable {
    public static func == (
        lhs: Route<Destination>,
        rhs: Route<Destination>
    ) -> Bool {
        lhs.destination == rhs.destination
    }
}

public protocol RouteDescribing {
    associatedtype Destination

    static func push(_ route: Destination) -> Self
    static func overlay(_ route: Destination) -> Self
    static func sheet(_ route: Destination, onDismiss: (() -> Void)?) -> Self
    static func cover(_ route: Destination, onDismiss: (() -> Void)?) -> Self
}
