//
//  OSMapViewModel.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 21.09.2022.
//

import SwiftUI
import Combine

class OSMapViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()

    init() {
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == .scrollWheel }
            .throttle(for: .milliseconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink {  event in
                print("Scroll ", event?.scrollingDeltaY ?? 0)
            }
            .store(in: &cancellables)
    }
}
