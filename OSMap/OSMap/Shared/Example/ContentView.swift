//
//  ContentView.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            OSMapView()
            Rectangle()
                .frame(width: 5, height: 5)
                .foregroundColor(.red)
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
