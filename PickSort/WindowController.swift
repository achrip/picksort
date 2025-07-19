//
//  WindowController.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 20/07/25.
//

import Cocoa

class WindowController: NSWindowController {
    
    convenience init() {
       
        // 1. Create View Controller for the application (harusnya global/root)
        let viewController = MainViewController()

        // 2. Create a Window and give it our View Controller from (1)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.miniaturizable, .closable, .resizable, .titled],
            backing: .buffered,
            defer: false)
        window.center()
        window.title = "PickSort"
        
        self.init(window: window)
        
        self.window?.contentViewController = viewController
    }
}
