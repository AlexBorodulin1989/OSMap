//
//  MetalView.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import SwiftUI
import MetalKit

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
typealias UniversalView = NSView
#elseif os(iOS)
typealias ViewRepresentable = UIViewRepresentable
typealias UniversalView = UIView
#endif

struct MetalView: ViewRepresentable {
    @State private var metalView = MTKView()

#if os(macOS)
    func makeNSView(context: Context) -> some NSView {
        makeView()
    }
    func updateNSView(_ uiView: NSViewType, context: Context) {
    }
#elseif os(iOS)
    func makeUIView(context: Context) -> MTKView {
        makeView() as! MTKView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
    }
#endif

    func makeView() -> UniversalView {

        return metalView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: MetalView

        private var renderer: Renderer!

        init(_ parent: MetalView) {
            self.parent = parent

            super.init()

            renderer = Renderer(metalView: parent.metalView)
        }
    }
}

struct MetalView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MetalView()
        }
    }
}
