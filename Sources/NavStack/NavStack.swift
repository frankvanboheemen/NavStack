//
//  NavStack.swift
//
//
//  Created by Frank van Boheemen on 24/05/2024.
//

import SwiftUI

public struct NavStack<
    Root: View,
    Destination: Hashable,
    DestinationView: View
>: View {
    @Binding var routes: [Route<Destination>]
    
    @ViewBuilder
    private let root: () -> Root
    @ViewBuilder
    private let destination: (Destination) -> DestinationView
    
    public init(
        _ routes: Binding<[Route<Destination>]>,
        root: @escaping () -> Root,
        @ViewBuilder destination: @escaping (Destination) -> DestinationView
    ) {
        self._routes = routes
        self.root = root
        self.destination = destination
    }
    
    public var body: some View {
        routes
            .enumerated()
            .reduce(
                [Node.root(details: [])]
            ) { stack, route in
                var adjustedStack = stack

                switch route.element {
                case let .push(destination):
                    return adjustedStack.add(.init(destination: destination, index: route.offset))
                    
                default:
                    return adjustedStack.appending(.node(route.element, index: route.offset, details: []))
                }
            }
            .reversed()
            .reduce(NodeView.end) { (next, current) -> NodeView in
                switch current {
                case let .node(route, index, details):
                    return .destination(
                        route,
                        view: destination,
                        allRoutes: $routes,
                        index: index,
                        details: details,
                        next: next
                    )
                    
                case let .root(details):
                    return .root(
                        root: root,
                        allRoutes: $routes,
                        details: details,
                        view: destination,
                        next: next
                    )
                }
            }
    }
}

extension NavStack {
    enum Node: NodeDescribing {
        case root(details: [Detail])
        case node(
            _ destination: Route<Destination>,
            index: Int,
            details: [Detail]
        )
        
        var details: [Detail] {
            switch self {
            case let .root(details),
                let .node(_, _, details):
                return details
            }
        }
        
        mutating func add(_ detail: Detail) {
            switch self {
            case let .root(details):
                self = .root(details: details + [detail])
                
            case let .node(destination, index, details):
                self = .node(destination, index: index, details: details + [detail])
            }
        }
    }
}

extension NavStack.Node {
    struct Detail: DetailDescribing, Hashable {
        var destination: Destination
        var index: Int
    }
}

protocol NodeDescribing {
    associatedtype Destination
    associatedtype Detail: DetailDescribing
    
    var details: [Detail] { get }
    mutating func add(_ detail: Detail)
}

protocol DetailDescribing {
    associatedtype Destination: Hashable
}

extension Array where Element: NodeDescribing {
    mutating func appending(_ node: Element) -> Self {
        append(node)
        
        return self
    }
    
    mutating func add(_ detail: Element.Detail) -> Self {
        self[endIndex - 1].add(detail)
        
        return self
    }
}
