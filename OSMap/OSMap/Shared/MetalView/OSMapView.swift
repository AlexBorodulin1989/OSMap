//
//  OSMapView.swift
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

struct OSMapView: ViewRepresentable {
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
        let parent: OSMapView

        private var renderer: RenderEngine!

        init(_ parent: OSMapView) {
            self.parent = parent

            super.init()

            renderer = RenderEngine(mtkView: parent.metalView)
            renderer.addPrimitive(MapFrame(device: parent.metalView.device!, imageName: "0.png"))
        }
    }
}

struct MetalView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OSMapView()
        }
    }
}
