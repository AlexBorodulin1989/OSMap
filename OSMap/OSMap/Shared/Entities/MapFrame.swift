//
//  MapFrame.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit
import Combine

extension MapFrame {
    enum Constants {
        static let initialZoom: Int = 1
        static let epsilon: Decimal = 0.0000001
    }
}

final class MapFrame: RenderItem {
    
    private var tiles = [[TileFrame]]()

    private let pipelineState: MTLRenderPipelineState

    private var cancellables = Set<AnyCancellable>()

    let initialCameraDist: Float = 1

    private var cameraOffset: Float = 0

    private var zoom: Int = MapFrame.Constants.initialZoom

    private var x: Float = 0
    private var y: Float = 0

    private var renderScreenSize: CGSize = .zero

    var mouseWeelEvent: NSEvent? {
        didSet {
            let cameraDistance = 1 - cameraOffset
            cameraOffset += Float(mouseWeelEvent?.scrollingDeltaY ?? 0) * cameraDistance * 0.01
            if cameraOffset < 0 {
                cameraOffset = 0
            }
        }
    }

    var leftMouseDragged: NSEvent? {
        didSet {
            if renderScreenSize.width > renderScreenSize.height {

                let ratio = 2 / renderScreenSize.width

                x += Float((leftMouseDragged?.deltaX ?? 0) * ratio)
                y -= Float((leftMouseDragged?.deltaY ?? 0) * ratio)
            }
        }
    }

    required init(device: MTLDevice, params: Any...) {
        if Constants.initialZoom < 1 {
            fatalError("zoom of 0 not supported")
        }

        let visibleTilesCountPerDim = NSDecimalNumber(decimal: pow(2.0, Constants.initialZoom) + Constants.epsilon).intValue

        pipelineState = TileFrame.pipelineState(device: device, pixelColorFormat: .bgra8Unorm)

        let dimSize: Float = 2 / Float(visibleTilesCountPerDim)

        for column in 0..<visibleTilesCountPerDim {
            var columnTiles = [TileFrame]()
            for row in 0..<visibleTilesCountPerDim {
                let tile = TileFrame(device: device, params: [1, column - visibleTilesCountPerDim / 2, row - visibleTilesCountPerDim / 2])

                let leftPointX = (Float(column) * dimSize) - 1
                let rightPointX = (Float(column) * dimSize + dimSize) - 1
                let topPointY = 1 - Float(row) * dimSize
                let bottomPointY = 1 - (Float(row) * dimSize) - dimSize

                let leftTop = SIMD3<Float>(leftPointX, topPointY, 1)
                let rightTop = SIMD3<Float>(rightPointX, topPointY, 1)
                let rightBottom = SIMD3<Float>(rightPointX, bottomPointY, 1)
                let leftBottom = SIMD3<Float>(leftPointX, bottomPointY, 1)

                let verts: [TileFrame.Point] = [
                    TileFrame.Point(pos: leftTop, texUV: SIMD2<Float>(0, 0)),
                    TileFrame.Point(pos: rightTop, texUV: SIMD2<Float>(1, 0)),
                    TileFrame.Point(pos: rightBottom, texUV: SIMD2<Float>(1, 1)),
                    TileFrame.Point(pos: leftBottom, texUV: SIMD2<Float>(0, 1))
                ]

                tile.setVertices(verts: verts, device: device)

                columnTiles.append(tile)
            }

            tiles.append(columnTiles)
        }

        setScrollWeelListener()
        setLeftMouseDraggedListener()
    }
}

// MARK: - Events
extension MapFrame {
    func setScrollWeelListener() {
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == .scrollWheel }
            .throttle(for: .milliseconds(1), scheduler: DispatchQueue.main, latest: true)
            .assign(to: \.mouseWeelEvent, on: self)
            .store(in: &cancellables)
    }

    func setLeftMouseDraggedListener() {
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == .leftMouseDragged }
            .throttle(for: .milliseconds(1), scheduler: DispatchQueue.main, latest: true)
            .assign(to: \.leftMouseDragged, on: self)
            .store(in: &cancellables)
    }
}

extension MapFrame: RenderingRectSizeListener {
    func rectDidChange(size: CGSize) {
        self.renderScreenSize = size
    }
}

extension MapFrame {
    func draw(engine: RenderEngine, encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(pipelineState)
        tiles.flatMap{$0}.forEach {[weak self] tile in
            tile.cameraOffset = self?.cameraOffset ?? 0
            tile.x = x
            tile.y = y
            tile.draw(engine: engine, encoder: encoder)
        }
    }
}
