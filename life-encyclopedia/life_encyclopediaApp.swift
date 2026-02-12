//
//  life_encyclopediaApp.swift
//  life-encyclopedia
//
//  Created by Eliot Chang on 2/4/26.
//

import SwiftUI

@main
struct life_encyclopediaApp: App {
    
    init() {
        #if DEBUG
        APIConfig.logConfiguration()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
