//
//  AppDelegate.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 19/07/25.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var windowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.windowController = WindowController()
        windowController?.showWindow(self)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }
}
