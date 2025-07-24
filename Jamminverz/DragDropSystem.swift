//
//  DragDropSystem.swift
//  Jamminverz
//
//  Advanced drag & drop system with visual feedback for sample organization
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drag & Drop Data Types
struct SampleDropItem: Transferable, Codable {
    let sample: Sample
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .jamminverzSample)
    }
}

extension UTType {
    static let jamminverzSample = UTType(exportedAs: "com.jadewii.jamminverz.sample")
}

// MARK: - Drop Zone Manager
@MainActor
class DropZoneManager: ObservableObject {
    @Published var activeDropZone: InstrumentType?
    @Published var draggedSample: Sample?
    @Published var dropFeedback: DropFeedback?
    @Published var isReorganizing = false
    @Published var reorganizationProgress: Double = 0.0
    
    private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    func startDrag(sample: Sample) {
        draggedSample = sample
        hapticGenerator.prepare()
    }
    
    func endDrag() {
        draggedSample = nil
        activeDropZone = nil
        dropFeedback = nil
    }
    
    func enterDropZone(_ instrument: InstrumentType) {
        guard draggedSample != nil else { return }
        activeDropZone = instrument
        
        // Haptic feedback on zone entry
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show drop feedback
        dropFeedback = DropFeedback(
            targetInstrument: instrument,
            isCompatible: checkCompatibility(draggedSample, targetInstrument: instrument),
            estimatedSamples: estimateTargetSamples(instrument)
        )
    }
    
    func exitDropZone() {
        activeDropZone = nil
        dropFeedback = nil
    }
    
    func performDrop(sample: Sample, targetInstrument: InstrumentType, onComplete: @escaping (Bool) -> Void) {
        // Strong haptic feedback on drop
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Start reorganization animation
        isReorganizing = true
        reorganizationProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate reorganization process
            for i in 1...10 {
                Thread.sleep(forTimeInterval: 0.1)
                DispatchQueue.main.async {
                    self.reorganizationProgress = Double(i) / 10.0
                }
            }
            
            DispatchQueue.main.async {
                self.isReorganizing = false
                self.reorganizationProgress = 0.0
                onComplete(true)
            }
        }
    }
    
    private func checkCompatibility(_ sample: Sample?, targetInstrument: InstrumentType) -> Bool {
        guard let sample = sample,
              let sampleInstrument = sample.analyzedData?.instrument else {
            return false
        }
        
        // Perfect match
        if sampleInstrument == targetInstrument {
            return true
        }
        
        // Compatible instruments
        let compatibilityMap: [InstrumentType: [InstrumentType]] = [
            .kick: [.percussion, .bass],
            .snare: [.percussion, .kick],
            .bass: [.kick, .melody],
            .melody: [.lead, .pad, .bass],
            .lead: [.melody, .pad],
            .pad: [.melody, .lead, .fx],
            .fx: [.pad, .vocal],
            .vocal: [.fx, .melody],
            .percussion: [.kick, .snare]
        ]
        
        return compatibilityMap[targetInstrument]?.contains(sampleInstrument) ?? false
    }
    
    private func estimateTargetSamples(_ instrument: InstrumentType) -> Int {
        // Mock data - in real app would query actual sample counts
        let counts: [InstrumentType: Int] = [
            .kick: 247,
            .snare: 89,
            .bass: 156,
            .melody: 234,
            .fx: 67,
            .vocal: 23,
            .percussion: 45,
            .lead: 98,
            .pad: 34
        ]
        
        return counts[instrument] ?? 0
    }
}

// MARK: - Drop Feedback Data
struct DropFeedback {
    let targetInstrument: InstrumentType
    let isCompatible: Bool
    let estimatedSamples: Int
    
    var feedbackColor: Color {
        isCompatible ? .green : .orange
    }
    
    var feedbackMessage: String {
        if isCompatible {
            return "Perfect match! Drop to organize"
        } else {
            return "Close match - AI will verify"
        }
    }
}

// MARK: - Enhanced Genre Bucket with Drag & Drop
struct EnhancedGenreBucketView: View {
    let instrument: InstrumentType
    let count: Int
    let isSelected: Bool
    let isActiveDropZone: Bool
    let dropFeedback: DropFeedback?
    let onTap: () -> Void
    let onDrop: (Sample) -> Void
    @ObservedObject private var dropManager = DropZoneManager()
    
    @State private var isHighlighted = false
    @State private var scaleEffect: CGFloat = 1.0
    @State private var rotationEffect: Double = 0.0
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Instrument emoji with animation
                Text(instrument.emoji)
                    .font(.system(size: isActiveDropZone ? 32 : 24))
                    .scaleEffect(scaleEffect)
                    .rotationEffect(.degrees(rotationEffect))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scaleEffect)
                    .animation(.easeInOut(duration: 0.5), value: rotationEffect)
                
                // Count with growth animation
                Text("\(count)")
                    .font(.system(size: isActiveDropZone ? 20 : 18, weight: .heavy))
                    .foregroundColor(.white)
                    .animation(.spring(), value: count)
                
                // Instrument name
                Text(instrument.rawValue.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white)
                
                // "samples" label
                Text("samples")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                // Drop indicator
                if isActiveDropZone, let feedback = dropFeedback {
                    dropIndicatorView(feedback)
                }
            }
            .frame(width: isActiveDropZone ? 100 : 80, height: isActiveDropZone ? 120 : 100)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(overlayView)
            .scaleEffect(isActiveDropZone ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActiveDropZone)
        }
        .buttonStyle(PlainButtonStyle())
        .dropDestination(for: SampleDropItem.self) { items, location in
            guard let item = items.first else { return false }
            
            withAnimation(.spring()) {
                onDrop(item.sample)
            }
            
            return true
        } isTargeted: { isTargeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHighlighted = isTargeted
            }
            
            if isTargeted {
                // Pulse animation
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    scaleEffect = 1.05
                }
                
                // Gentle rotation
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotationEffect = 360
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    scaleEffect = 1.0
                    rotationEffect = 0
                }
            }
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
            
            // Animated glow effect for active drop zone
            if isActiveDropZone {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        RadialGradient(
                            colors: [
                                dropFeedback?.feedbackColor.opacity(0.3) ?? Color.white.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .scaleEffect(1.2)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActiveDropZone)
            }
            
            // Particle effect for compatibility
            if isActiveDropZone && dropFeedback?.isCompatible == true {
                ParticleEffectView()
            }
        }
    }
    
    private var backgroundColor: Color {
        if isActiveDropZone {
            return dropFeedback?.feedbackColor.opacity(0.4) ?? Color.white.opacity(0.3)
        } else if isSelected {
            return Color.white.opacity(0.3)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(strokeColor, lineWidth: strokeWidth)
    }
    
    private var strokeColor: Color {
        if isActiveDropZone {
            return dropFeedback?.feedbackColor ?? Color.white
        } else if isSelected {
            return Color.white
        } else {
            return Color.clear
        }
    }
    
    private var strokeWidth: CGFloat {
        if isActiveDropZone {
            return 3
        } else if isSelected {
            return 2
        } else {
            return 0
        }
    }
    
    @ViewBuilder
    private func dropIndicatorView(_ feedback: DropFeedback) -> some View {
        VStack(spacing: 2) {
            // Compatibility indicator
            HStack(spacing: 2) {
                Image(systemName: feedback.isCompatible ? "checkmark.circle.fill" : "questionmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(feedback.feedbackColor)
                
                Text(feedback.isCompatible ? "MATCH" : "CHECK")
                    .font(.system(size: 6, weight: .heavy))
                    .foregroundColor(feedback.feedbackColor)
            }
            
            // Quick stats
            Text("→ \(feedback.estimatedSamples)")
                .font(.system(size: 6, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(feedback.feedbackColor.opacity(0.2))
        )
        .overlay(
            Capsule()
                .stroke(feedback.feedbackColor, lineWidth: 1)
        )
    }
}

// MARK: - Particle Effect View
struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            startParticleAnimation()
        }
        .onDisappear {
            stopParticleAnimation()
        }
    }
    
    private func startParticleAnimation() {
        // Create initial particles
        for _ in 0..<10 {
            particles.append(createParticle())
        }
        
        // Start animation timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func stopParticleAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func createParticle() -> Particle {
        Particle(
            position: CGPoint(
                x: CGFloat.random(in: 10...70),
                y: CGFloat.random(in: 10...90)
            ),
            velocity: CGPoint(
                x: CGFloat.random(in: -2...2),
                y: CGFloat.random(in: -3...1)
            ),
            size: CGFloat.random(in: 2...4),
            color: [Color.green, Color.yellow, Color.blue].randomElement()!,
            opacity: Double.random(in: 0.3...0.8),
            scale: CGFloat.random(in: 0.5...1.0),
            life: Double.random(in: 1...3)
        )
    }
    
    private func updateParticles() {
        withAnimation(.linear(duration: 0.1)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].life -= 0.1
                particles[i].opacity = max(0, particles[i].life / 3.0)
                particles[i].scale *= 0.99
            }
        }
        
        // Remove dead particles and add new ones
        particles.removeAll { $0.life <= 0 }
        
        while particles.count < 10 {
            particles.append(createParticle())
        }
    }
}

// MARK: - Particle Data
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
    var scale: CGFloat
    var life: Double
}

// MARK: - Enhanced Sample Card with Drag Support
struct DraggableSampleCardView: View {
    let sample: Sample
    let isPlaying: Bool
    let isDragging: Bool
    let onTap: () -> Void
    let onSelect: (Bool) -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    
    @State private var isSelected = false
    @State private var dragOffset = CGSize.zero
    @State private var isDragActive = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Waveform visualization
                waveformView
                
                // Sample info
                sampleInfoView
                
                // Status indicators
                statusIndicatorsView
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(overlayView)
            .scaleEffect(isDragActive ? 0.95 : 1.0)
            .offset(dragOffset)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragActive)
        }
        .buttonStyle(PlainButtonStyle())
        .draggable(SampleDropItem(sample: sample)) {
            // Drag preview
            DragPreviewView(sample: sample)
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            isSelected.toggle()
            onSelect(isSelected)
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private var waveformView: some View {
        HStack(spacing: 1) {
            ForEach(0..<20, id: \.self) { _ in
                Rectangle()
                    .fill(waveformColor)
                    .frame(width: 2, height: CGFloat.random(in: 4...20))
                    .animation(.easeInOut(duration: Double.random(in: 0.5...1.5)).repeatForever(autoreverses: true), value: isPlaying)
            }
        }
        .frame(height: 20)
    }
    
    private var waveformColor: Color {
        if isPlaying {
            return Color.white
        } else if let mood = sample.analyzedData?.mood {
            return mood.color.opacity(0.8)
        } else {
            return Color.white.opacity(Double.random(in: 0.3...1.0))
        }
    }
    
    private var sampleInfoView: some View {
        VStack(spacing: 4) {
            Text(sample.displayName)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            if let analysis = sample.analyzedData {
                HStack(spacing: 4) {
                    Text(analysis.instrument.emoji)
                        .font(.system(size: 12))
                    
                    if let bpm = analysis.bpm {
                        Text("\(bpm)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Confidence indicator
                    Circle()
                        .fill(confidenceColor(analysis.confidence))
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
    
    private var statusIndicatorsView: some View {
        HStack(spacing: 4) {
            // Duplicate indicator
            if !sample.duplicates.isEmpty {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
            }
            
            // Similar samples indicator
            if !sample.similarSamples.isEmpty {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
            }
            
            // Loop indicator
            if sample.analyzedData?.isLoop == true {
                Image(systemName: "repeat")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
            }
            
            // Vocal indicator
            if sample.analyzedData?.hasVocals == true {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            }
            
            // Quality indicator
            if let quality = sample.analyzedData?.quality {
                if quality.sampleRate >= 48000 && quality.bitDepth >= 24 {
                    Image(systemName: "hifispeaker.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                }
            }
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
    }
    
    private var backgroundColor: Color {
        if isDragActive {
            return Color.white.opacity(0.3)
        } else if isPlaying {
            return Color.white.opacity(0.2)
        } else if let mood = sample.analyzedData?.mood {
            return mood.color.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(strokeColor, lineWidth: strokeWidth)
    }
    
    private var strokeColor: Color {
        if isPlaying {
            return Color.white
        } else if isSelected {
            return Color.blue
        } else {
            return Color.clear
        }
    }
    
    private var strokeWidth: CGFloat {
        if isPlaying || isSelected {
            return 2
        } else {
            return 0
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Drag Preview View
struct DragPreviewView: View {
    let sample: Sample
    
    var body: some View {
        VStack(spacing: 4) {
            Text(sample.analyzedData?.instrument.emoji ?? "🎵")
                .font(.system(size: 24))
            
            Text(sample.displayName)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            if let analysis = sample.analyzedData {
                HStack(spacing: 4) {
                    if let bpm = analysis.bpm {
                        Text("\(bpm) BPM")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let key = analysis.key {
                        Text(key)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(8)
        .frame(width: 80, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(sample.analyzedData?.mood.color.opacity(0.8) ?? Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

// MARK: - Bulk Operations View
struct BulkOperationsView: View {
    let selectedSamples: [Sample]
    let onOrganize: ([Sample], InstrumentType) -> Void
    let onDelete: ([Sample]) -> Void
    let onExport: ([Sample]) -> Void
    @State private var showingTargetPicker = false
    @State private var targetInstrument: InstrumentType = .unknown
    
    var body: some View {
        if !selectedSamples.isEmpty {
            VStack(spacing: 12) {
                Text("\(selectedSamples.count) samples selected")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    BulkActionButton(
                        title: "ORGANIZE",
                        icon: "folder.fill",
                        color: .blue
                    ) {
                        showingTargetPicker = true
                    }
                    
                    BulkActionButton(
                        title: "EXPORT",
                        icon: "square.and.arrow.up",
                        color: .green
                    ) {
                        onExport(selectedSamples)
                    }
                    
                    BulkActionButton(
                        title: "DELETE",
                        icon: "trash.fill",
                        color: .red
                    ) {
                        onDelete(selectedSamples)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .sheet(isPresented: $showingTargetPicker) {
                InstrumentPickerView(selectedInstrument: $targetInstrument) {
                    onOrganize(selectedSamples, targetInstrument)
                    showingTargetPicker = false
                }
            }
        }
    }
}

struct BulkActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InstrumentPickerView: View {
    @Binding var selectedInstrument: InstrumentType
    let onConfirm: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Choose Target Category")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(InstrumentType.allCases, id: \.self) { instrument in
                        Button(action: {
                            selectedInstrument = instrument
                        }) {
                            VStack(spacing: 8) {
                                Text(instrument.emoji)
                                    .font(.system(size: 32))
                                
                                Text(instrument.rawValue)
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                selectedInstrument == instrument
                                    ? Color.white.opacity(0.3)
                                    : Color.white.opacity(0.1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedInstrument == instrument
                                            ? Color.white
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Button(action: {
                    onConfirm()
                }) {
                    Text("ORGANIZE SAMPLES")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(selectedInstrument == .unknown)
                
                Spacer()
            }
            .padding(24)
            .background(Color.black)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    EnhancedGenreBucketView(
        instrument: .kick,
        count: 247,
        isSelected: false,
        isActiveDropZone: true,
        dropFeedback: DropFeedback(
            targetInstrument: .kick,
            isCompatible: true,
            estimatedSamples: 247
        ),
        onTap: {},
        onDrop: { _ in }
    )
}