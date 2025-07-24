//
//  SettingsView.swift
//  Jamminverz
//
//  Settings page for the music production app
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var taskStore: TaskStore
    
    // Audio Settings
    @State private var sampleRate = 44100
    @State private var bufferSize = 512
    @State private var enableMetronome = true
    
    // Export Settings  
    @State private var exportFormat = "WAV"
    @State private var normalizeOnExport = true
    
    // App Settings
    @State private var autoSave = true
    @State private var enableHaptics = true
    
    @State private var showingThemes = false
    @State private var showingClearData = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    Text("SETTINGS")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    // Audio Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("AUDIO")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        // Sample Rate
                        HStack {
                            Text("Sample Rate")
                                .foregroundColor(.white)
                            Spacer()
                            Menu {
                                Button("44.1 kHz") { sampleRate = 44100 }
                                Button("48 kHz") { sampleRate = 48000 }
                                Button("96 kHz") { sampleRate = 96000 }
                            } label: {
                                Text("\(sampleRate / 1000) kHz")
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        // Buffer Size
                        HStack {
                            Text("Buffer Size")
                                .foregroundColor(.white)
                            Spacer()
                            Menu {
                                Button("128") { bufferSize = 128 }
                                Button("256") { bufferSize = 256 }
                                Button("512") { bufferSize = 512 }
                                Button("1024") { bufferSize = 1024 }
                            } label: {
                                Text("\(bufferSize)")
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        // Metronome
                        Toggle(isOn: $enableMetronome) {
                            Text("Metronome")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    
                    // Export Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("EXPORT")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        // Format
                        HStack {
                            Text("Format")
                                .foregroundColor(.white)
                            Spacer()
                            Menu {
                                Button("WAV") { exportFormat = "WAV" }
                                Button("MP3") { exportFormat = "MP3" }
                                Button("AIFF") { exportFormat = "AIFF" }
                                Button("FLAC") { exportFormat = "FLAC" }
                            } label: {
                                Text(exportFormat)
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        // Normalize
                        Toggle(isOn: $normalizeOnExport) {
                            Text("Normalize on Export")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    
                    // App Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("APP")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Toggle(isOn: $autoSave) {
                            Text("Auto Save")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                        
                        Toggle(isOn: $enableHaptics) {
                            Text("Haptic Feedback")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                        
                        // Themes Button
                        Button(action: {
                            showingThemes = true
                        }) {
                            HStack {
                                Text("Themes")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Clear Data
                        Button(action: {
                            showingClearData = true
                        }) {
                            HStack {
                                Text("Clear All Data")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ABOUT")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Version")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Created by")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("JAde Wii")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showingThemes) {
            SimpleThemeView()
        }
        .alert("Clear All Data?", isPresented: $showingClearData) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            }
        } message: {
            Text("This will delete all your projects, samples, and settings.")
        }
    }
}

// Simple Theme Selection View
struct SimpleThemeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTheme = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Button(action: {
                        selectedTheme = 0
                        if ThemeManager.shared.themes.count > 0 {
                            ThemeManager.shared.setTheme(ThemeManager.shared.themes[0])
                        }
                    }) {
                        HStack {
                            Text("TODOMAI CLASSIC")
                                .foregroundColor(.white)
                            Spacer()
                            if selectedTheme == 0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        selectedTheme = 1
                        if ThemeManager.shared.themes.count > 1 {
                            ThemeManager.shared.setTheme(ThemeManager.shared.themes[1])
                        }
                    }) {
                        HStack {
                            Text("CYBERPUNK NEON")
                                .foregroundColor(.white)
                            Spacer()
                            if selectedTheme == 1 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        selectedTheme = 2
                        if ThemeManager.shared.themes.count > 2 {
                            ThemeManager.shared.setTheme(ThemeManager.shared.themes[2])
                        }
                    }) {
                        HStack {
                            Text("GLASS AURORA")
                                .foregroundColor(.white)
                            Spacer()
                            if selectedTheme == 2 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        selectedTheme = 3
                        if ThemeManager.shared.themes.count > 3 {
                            ThemeManager.shared.setTheme(ThemeManager.shared.themes[3])
                        }
                    }) {
                        HStack {
                            Text("RETRO WAVE")
                                .foregroundColor(.white)
                            Spacer()
                            if selectedTheme == 3 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TaskStore())
}