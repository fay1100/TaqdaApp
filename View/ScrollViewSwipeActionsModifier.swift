//
//  ScrollViewSwipeActionsModifier.swift
//  TaqdaAppTests
//
//  Created by Faizah Almalki on 18/05/1446 AH.
//

import Foundation
import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct ScrollViewSwipeActionsModifier: ViewModifier {
    @State private var size: CGSize = .init(width: 1, height: 1)
    
    func body(content: Content) -> some View {
        SwiftUI.List { // تحديد أنك تقصد SwiftUI.List
            LazyVStack {
                content
            }
            .frame(minHeight: 44)
            .readSize { size in
                self.size = size
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .scrollDisabled(true)
        .listStyle(.plain)
        .frame(height: size.height)
        .contentMargins(.vertical, EdgeInsets(), for: .scrollContent)
    }
}

extension View {
    func enableScrollViewSwipeActions() -> some View {
        self.modifier(ScrollViewSwipeActionsModifier())
    }
}
