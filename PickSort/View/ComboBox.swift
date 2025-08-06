//
//  ComboBox.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 05/08/25.
//

import SwiftUI
import AppKit

/// A SwiftUI view that wraps an `NSComboBox`, providing a text field with a dropdown list of options.
/// Features filtering based on substring matching and restricts input to predetermined options only.
struct ComboBox: NSViewRepresentable {
    /// A binding to the text in the combo box's text field.
    @Binding var text: String
    /// The complete list of items available for selection.
    let items: [String]
    
    // MARK: - NSViewRepresentable Methods

    /// Creates and configures the `NSComboBox` instance.
    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.addItems(withObjectValues: items)
        comboBox.delegate = context.coordinator
        comboBox.stringValue = text
        
        // Enable completion and filtering
        comboBox.completes = true
        comboBox.hasVerticalScroller = true
        comboBox.intercellSpacing = NSSize(width: 0, height: 2)
        
        return comboBox
    }

    /// Updates the `NSComboBox` when the SwiftUI state changes.
    func updateNSView(_ nsView: NSComboBox, context: Context) {
        // Ensure the combo box's value is in sync with the binding.
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        
        // Update the item list if it has changed.
        let currentItems = nsView.objectValues as? [String] ?? []
        if currentItems != items {
            nsView.removeAllItems()
            nsView.addItems(withObjectValues: items)
        }
    }

    /// Creates the coordinator that acts as the delegate for the `NSComboBox`.
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    // MARK: - Coordinator

    /// The coordinator class handles delegate methods from the `NSComboBox`.
    class Coordinator: NSObject, NSComboBoxDelegate, NSComboBoxDataSource {
        var parent: ComboBox
        private var isUpdatingProgrammatically = false

        init(_ parent: ComboBox) {
            self.parent = parent
        }

        /// Called when the text in the combo box's text field changes.
        func controlTextDidChange(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox,
                  !isUpdatingProgrammatically else { return }
            
            let currentText = comboBox.stringValue
            
            // Filter items based on substring matching
            let filteredItems = parent.items.filter { item in
                item.localizedCaseInsensitiveContains(currentText)
            }
            
            // Update the combo box items with filtered results
            comboBox.removeAllItems()
            comboBox.addItems(withObjectValues: filteredItems)
            
            // Update the binding with the current text
            DispatchQueue.main.async {
                self.parent.text = currentText
            }
            
            // Show dropdown if there are matches and text is not empty
            if !filteredItems.isEmpty && !currentText.isEmpty {
                comboBox.numberOfVisibleItems = min(filteredItems.count, 10)
            }
        }
        
        /// Called when a selection is made from the dropdown list.
        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox,
                  let selectedValue = comboBox.objectValueOfSelectedItem as? String else {
                return
            }
            
            isUpdatingProgrammatically = true
            
            // Update the binding with the selected value
            DispatchQueue.main.async {
                self.parent.text = selectedValue
                self.isUpdatingProgrammatically = false
            }
            
            // Reset the items to show all options after selection
            comboBox.removeAllItems()
            comboBox.addItems(withObjectValues: parent.items)
        }
        
        /// Validates text input - only allows predetermined options
        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
            guard let comboBox = control as? NSComboBox else { return true }
            
            let currentText = fieldEditor.string
            
            // Check if the current text exactly matches one of the predetermined options
            let isValidOption = parent.items.contains { item in
                item.localizedCaseInsensitiveCompare(currentText) == .orderedSame
            }
            
            if !isValidOption {
                // If not a valid option, try to find the closest match or revert to previous value
                let closestMatch = parent.items.first { item in
                    item.localizedCaseInsensitiveContains(currentText)
                }
                
                if let match = closestMatch, !currentText.isEmpty {
                    // Set to the closest match
                    isUpdatingProgrammatically = true
                    comboBox.stringValue = match
                    DispatchQueue.main.async {
                        self.parent.text = match
                        self.isUpdatingProgrammatically = false
                    }
                } else {
                    // Revert to the previous valid value
                    isUpdatingProgrammatically = true
                    comboBox.stringValue = parent.text
                    self.isUpdatingProgrammatically = false
                }
                
                // Reset items to show all options
                comboBox.removeAllItems()
                comboBox.addItems(withObjectValues: parent.items)
            }
            
            return isValidOption
        }
        
        /// Called when the combo box loses focus
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            
            // Ensure only valid options are accepted
            let currentText = comboBox.stringValue
            let isValidOption = parent.items.contains { item in
                item.localizedCaseInsensitiveCompare(currentText) == .orderedSame
            }
            
            if !isValidOption {
                // Revert to previous valid value or first item if no valid previous value
                let fallbackValue = parent.items.contains(parent.text) ? parent.text : (parent.items.first ?? "")
                
                isUpdatingProgrammatically = true
                comboBox.stringValue = fallbackValue
                DispatchQueue.main.async {
                    self.parent.text = fallbackValue
                    self.isUpdatingProgrammatically = false
                }
            }
            
            // Reset items to show all options
            comboBox.removeAllItems()
            comboBox.addItems(withObjectValues: parent.items)
        }
    }
}

// MARK: - Example Usage

struct ComboBoxExampleView: View {
    @State private var selectedFruit = "Apple"
    private let fruitOptions = ["Apple", "Apricot", "Banana", "Blueberry", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Grapefruit"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Select a Fruit")
                .font(.headline)
            
            Text("Type to filter options (e.g., 'ap' for Apple/Apricot)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ComboBox(text: $selectedFruit, items: fruitOptions)
                .frame(width: 200)

            Text("Current Selection: \(selectedFruit)")
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            
            HStack {
                Button("Select Grape") {
                    selectedFruit = "Grape"
                }
                
                Button("Select Blueberry") {
                    selectedFruit = "Blueberry"
                }
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}

struct ComboBoxExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ComboBoxExampleView()
    }
}
