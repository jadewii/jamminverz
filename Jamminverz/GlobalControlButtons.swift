//
//  GlobalControlButtons.swift
//  Jamminverz
//
//  Global control buttons that appear on every page
//

import SwiftUI

struct GlobalControlButtons: View {
    @Binding var showSampleListView: Bool
    @Binding var isGridView: Bool
    @Binding var showAllSequencersView: Bool
    @Binding var showColorPicker: Bool
    @Binding var gridColorMode: String
    @Binding var selectedGridColor: Color
    
    var body: some View {
        HStack(spacing: 0) {
            // List view button
            Button(action: {
                showSampleListView.toggle()
            }) {
                Rectangle()
                    .fill(Color.white.opacity(showSampleListView ? 0.2 : 0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        VStack(spacing: 3) {
                            ForEach(0..<4) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 22, height: 2)
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Grid view toggle button
            Button(action: {
                isGridView.toggle()
            }) {
                Rectangle()
                    .fill(Color.white.opacity(isGridView ? 0.2 : 0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(6), spacing: 3), count: 4), spacing: 3) {
                            ForEach(0..<16) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(isGridView ? 1.0 : 0.6))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // All sequencers view button
            Button(action: {
                showAllSequencersView.toggle()
            }) {
                Rectangle()
                    .fill(Color.white.opacity(showAllSequencersView ? 0.2 : 0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        VStack(spacing: 3) {
                            ForEach(0..<3) { row in
                                HStack(spacing: 3) {
                                    ForEach(0..<3) { col in
                                        Circle()
                                            .fill(Color.white.opacity(showAllSequencersView ? 1.0 : 0.6))
                                            .frame(width: 5, height: 5)
                                    }
                                }
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Color picker button
            Button(action: {
                showColorPicker.toggle()
            }) {
                Rectangle()
                    .fill(
                        gridColorMode == "rainbow" ?
                        AnyShapeStyle(LinearGradient(
                            colors: [.red, .orange, .yellow, .green, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )) :
                        AnyShapeStyle(selectedGridColor)
                    )
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showColorPicker) {
                GlobalColorPickerPopover(
                    gridColorMode: $gridColorMode,
                    selectedGridColor: $selectedGridColor
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Global Color Picker Popover
struct GlobalColorPickerPopover: View {
    @Binding var gridColorMode: String
    @Binding var selectedGridColor: Color
    @Environment(\.dismiss) var dismiss
    
    let colors: [(name: String, color: Color)] = [
        ("rainbow", Color.clear), // Special case
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("blue", .blue),
        ("purple", .purple),
        ("pink", .pink),
        ("mint", Color(red: 0.2, green: 0.9, blue: 0.6)),
        ("teal", .teal),
        ("cyan", .cyan),
        ("indigo", .indigo),
        ("brown", .brown),
        ("gray", .gray),
        ("white", .white),
        ("black", .black),
        ("navy", Color(red: 0, green: 0, blue: 0.5)),
        ("forest", Color(red: 0.13, green: 0.37, blue: 0.13)),
        ("maroon", Color(red: 0.5, green: 0, blue: 0)),
        ("olive", Color(red: 0.5, green: 0.5, blue: 0)),
        ("lime", Color(red: 0.75, green: 1, blue: 0)),
        ("aqua", Color(red: 0, green: 1, blue: 1)),
        ("fuchsia", Color(red: 1, green: 0, blue: 1)),
        ("silver", Color(red: 0.75, green: 0.75, blue: 0.75)),
        ("coral", Color(red: 1, green: 0.5, blue: 0.31)),
        ("salmon", Color(red: 0.98, green: 0.5, blue: 0.45)),
        ("gold", Color(red: 1, green: 0.84, blue: 0)),
        ("plum", Color(red: 0.87, green: 0.63, blue: 0.87)),
        ("turquoise", Color(red: 0.25, green: 0.88, blue: 0.82)),
        ("violet", Color(red: 0.93, green: 0.51, blue: 0.93))
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("APP THEME COLOR")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(50), spacing: 10), count: 5), spacing: 10) {
                    ForEach(colors, id: \.name) { item in
                        Button(action: {
                            gridColorMode = item.name
                            if item.name != "rainbow" {
                                selectedGridColor = item.color
                            }
                            dismiss()
                        }) {
                            if item.name == "rainbow" {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(gridColorMode == "rainbow" ? Color.white : Color.clear, lineWidth: 3)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(item.color)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(gridColorMode == item.name ? Color.white : Color.gray.opacity(0.3), lineWidth: 3)
                                    )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .frame(maxHeight: 400)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        }
        .frame(width: 300)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}