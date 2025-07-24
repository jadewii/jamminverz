//
//  TaskListModel.swift
//  Shared between iOS, watchOS, and macOS
//
//  Task list model for organizing tasks
//

import Foundation
import SwiftUI

// MARK: - Task List Model
public struct TaskList: Identifiable, Codable {
    public let id: String
    public var name: String
    public var color: Color.RGBValues
    
    public var swiftUIColor: Color {
        Color(rgbValues: color)
    }
    
    public init(id: String, name: String, color: Color.RGBValues) {
        self.id = id
        self.name = name
        self.color = color
    }
}

// MARK: - Color Extensions
extension Color {
    public struct RGBValues: Codable {
        public let red: Double
        public let green: Double
        public let blue: Double
        
        public init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }
    
    public init(rgbValues: RGBValues) {
        self.init(red: rgbValues.red, green: rgbValues.green, blue: rgbValues.blue)
    }
    
    public var rgbValues: RGBValues {
        #if os(macOS)
        // macOS color handling
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor.gray
        return RGBValues(
            red: Double(nsColor.redComponent),
            green: Double(nsColor.greenComponent),
            blue: Double(nsColor.blueComponent)
        )
        #else
        // iOS/watchOS color handling
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGBValues(red: Double(red), green: Double(green), blue: Double(blue))
        #endif
    }
}

// MARK: - List Color Presets
public extension TaskList {
    static let presetColors: [Color.RGBValues] = [
        Color.RGBValues(red: 1.0, green: 0.8, blue: 0.8),
        Color.RGBValues(red: 0.8, green: 0.9, blue: 1.0),
        Color.RGBValues(red: 0.8, green: 1.0, blue: 0.8),
        Color.RGBValues(red: 1.0, green: 1.0, blue: 0.8),
        Color.RGBValues(red: 0.9, green: 0.8, blue: 1.0),
        Color.RGBValues(red: 1.0, green: 0.9, blue: 0.8),
        Color.RGBValues(red: 0.8, green: 1.0, blue: 0.95),
        Color.RGBValues(red: 1.0, green: 0.8, blue: 0.95),
        Color.RGBValues(red: 1.0, green: 0.95, blue: 1.0),
        Color.RGBValues(red: 0.95, green: 1.0, blue: 1.0)
    ]
    
    static func createList(id: String = UUID().uuidString, name: String, colorIndex: Int) -> TaskList {
        let color = presetColors[colorIndex % presetColors.count]
        return TaskList(id: id, name: name, color: color)
    }
}