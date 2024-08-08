//
//  NavStack.NodeView.swift
//
//
//  Created by Frank van Boheemen on 24/05/2024.
//

import SwiftUI

extension NavStack {
    indirect enum NodeView {
        case root(
            root: () -> Root,
            allRoutes: Binding<[Route<Destination>]>,
            details: [Node.Detail],
            view: (Destination) -> DestinationView,
            next: NodeView
        )
        
        case destination(
            Route<Destination>,
            view: (Destination) -> DestinationView,
            allRoutes: Binding<[Route<Destination>]>,
            index: Int,
            details: [Node.Detail],
            next: NodeView
        )
        case end
    }
}

// MARK: - View

extension NavStack.NodeView: View {
    var body: some View {
        NavigationStack(path: path) {
            content
                .navigationDestination(for: NavStack.Node.Detail.self) {
                    view(for: $0.destination)
                }
        }
        .overlay(overlay)
        .sheet(isPresented: sheet, onDismiss: onDismiss) { next }
        .fullScreenCover(isPresented: cover, onDismiss: onDismiss) { next }
    }
    
    @ViewBuilder
    private var content: some View {
        switch self {
        case let .root(root, _, _, _, _):
            root()
            
        case let .destination(route, _, _, _, _, _):
            view(for: route.destination)
            
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var overlay: some View {
        if case .destination(.overlay, _, _, _, _, _) = next {
            next
        }
    }
    
    @ViewBuilder
    func view(for destination: Destination) -> some View {
        switch self {
        case let .root(_, _, _, view, _),
             let .destination(_, view, _, _, _, _):
            view(destination)

        default:
            EmptyView()
        }
    }
}

// MARK: - Bindings

private extension NavStack.NodeView {
    var isActive: Binding<Bool> {
        switch self {
        case let .root(_, allRoutes, _, _, .destination),
            let .destination(_, _, allRoutes, _, _, .destination):
            Binding(
                get: {
                    if case .end = next {
                        return false
                    } else {
                        return true
                    }
                },
                set: { isShowing in
                    guard !isShowing,
                          case .destination(_, _, _, let nextIndex, _, _) = next
                    else {
                        return
                    }
                    
                    allRoutes.wrappedValue = Array(allRoutes.wrappedValue.prefix(nextIndex))
                }
            )
            
        default:
                .constant(false)
        }
    }

    var sheet: Binding<Bool> {
        guard case .destination(.sheet, _, _, _, _, _) = next else {
            return .constant(false)
        }
        return isActive
    }
    
    var cover: Binding<Bool> {
        guard case .destination(.cover, _, _, _, _, _) = next else {
            return .constant(false)
        }
        return isActive
    }
    
    private var path: Binding<[NavStack.Node.Detail]> {
        Binding(
            get: {
                details
            },
            set: { newValue in
                guard newValue.count < details.count else { return }
                
                switch self {
                case let .root(_, allRoutes, _, _, _),
                    let .destination(_, _, allRoutes, _, _, _):
                    let difference = Array(Set(newValue).symmetricDifference(details))
                    
                    allRoutes.wrappedValue = allRoutes.wrappedValue
                        .enumerated()
                        .filter { !difference.map{ $0.index }.contains($0.offset) }
                        .map { $0.element }
                    
                case .end:
                    break
                }
            }
        )
    }
    
    private var details: [NavStack.Node.Detail] {
        switch self {
        case let .root(_, _, details, _, _),
             let .destination(_, _, _, _, details, _):
            return details
            
        case .end:
            return []
        }
    }
}

// MARK: - Convenience

private extension NavStack.NodeView {
    private var next: Self? {
        switch self {
        case let .root(_, _, _, _, next),
             let .destination(_, _, _, _, _, next):
            return next
            
        default:
            return nil
        }
    }
    
    private var onDismiss: (() -> Void)? {
        guard case let .destination(destination, _, _, _, _, _) = next else {
            return nil
        }
        
        return destination.onDismiss
    }
}
