//
//  AudioAnalysisEngine.swift
//  Jamminverz
//
//  Advanced AI-powered audio analysis engine for sample organization
//

import Foundation
import AVFoundation
import Accelerate
import CoreML

// MARK: - Audio Analysis Engine
@MainActor
class AudioAnalysisEngine: ObservableObject {
    static let shared = AudioAnalysisEngine()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentAnalysisFile: String = ""
    
    private let audioEngine = AVAudioEngine()
    private var analysisQueue = DispatchQueue(label: "audio.analysis", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Main Analysis Function
    func analyzeSample(at url: URL) async throws -> SampleAnalysis {
        // Perform analysis on a background task
        return try performDeepAnalysis(url: url)
    }
    
    // MARK: - Deep Audio Analysis
    nonisolated private func performDeepAnalysis(url: URL) throws -> SampleAnalysis {
        // Load audio file
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioAnalysisError.bufferCreationFailed
        }
        
        try audioFile.read(into: buffer)
        
        // Extract audio features
        let audioData = extractAudioData(from: buffer)
        
        // Perform various analyses
        let bpmAnalysis = analyzeBPM(audioData: audioData, sampleRate: format.sampleRate)
        let keyAnalysis = analyzeKey(audioData: audioData, sampleRate: format.sampleRate)
        let instrumentAnalysis = classifyInstrument(audioData: audioData, fileName: url.lastPathComponent)
        let moodAnalysis = analyzeMood(audioData: audioData, instrument: instrumentAnalysis.instrument)
        let energyAnalysis = calculateEnergy(audioData: audioData)
        let loopAnalysis = detectLoop(audioData: audioData, duration: Double(frameCount) / format.sampleRate)
        let qualityAnalysis = analyzeQuality(format: format, url: url)
        let vocalAnalysis = detectVocals(audioData: audioData, sampleRate: format.sampleRate)
        
        return SampleAnalysis(
            bpm: bpmAnalysis.bpm,
            key: keyAnalysis.key,
            instrument: instrumentAnalysis.instrument,
            energy: energyAnalysis.energy,
            mood: moodAnalysis.mood,
            isLoop: loopAnalysis.isLoop,
            quality: qualityAnalysis,
            duration: Double(frameCount) / format.sampleRate,
            hasVocals: vocalAnalysis.hasVocals,
            confidence: calculateOverallConfidence(
                bpm: bpmAnalysis.confidence,
                key: keyAnalysis.confidence,
                instrument: instrumentAnalysis.confidence,
                mood: moodAnalysis.confidence,
                energy: energyAnalysis.confidence
            )
        )
    }
    
    // MARK: - Audio Data Extraction
    nonisolated private func extractAudioData(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        var audioData: [Float] = []
        
        // Convert to mono if stereo
        if channelCount == 2 {
            for frame in 0..<frameLength {
                let monoSample = (channelData[0][frame] + channelData[1][frame]) / 2.0
                audioData.append(monoSample)
            }
        } else {
            for frame in 0..<frameLength {
                audioData.append(channelData[0][frame])
            }
        }
        
        return audioData
    }
    
    // MARK: - BPM Analysis
    nonisolated private func analyzeBPM(audioData: [Float], sampleRate: Double) -> (bpm: Int?, confidence: Double) {
        let windowSize = 1024
        let hopSize = 512
        let maxBPM = 200.0
        let minBPM = 60.0
        
        // Calculate onset detection function
        let onsetStrength = calculateOnsetStrength(audioData: audioData, windowSize: windowSize, hopSize: hopSize)
        
        // Apply autocorrelation to find periodicity
        let autocorrelation = calculateAutocorrelation(signal: onsetStrength)
        
        // Find peaks in autocorrelation
        let peaks = findPeaks(in: autocorrelation, minDistance: 10)
        
        // Convert peaks to BPM candidates
        var bpmCandidates: [(bpm: Double, strength: Float)] = []
        
        for peak in peaks {
            let periodInFrames = Double(peak)
            let periodInSeconds = (periodInFrames * Double(hopSize)) / sampleRate
            let bpm = 60.0 / periodInSeconds
            
            if bpm >= minBPM && bpm <= maxBPM {
                bpmCandidates.append((bpm: bpm, strength: autocorrelation[peak]))
            }
        }
        
        // Find the strongest BPM candidate
        guard let bestCandidate = bpmCandidates.max(by: { $0.strength < $1.strength }) else {
            return (nil, 0.0)
        }
        
        let confidence = min(Double(bestCandidate.strength), 1.0)
        return (Int(bestCandidate.bpm.rounded()), confidence)
    }
    
    nonisolated private func calculateOnsetStrength(audioData: [Float], windowSize: Int, hopSize: Int) -> [Float] {
        var onsetStrength: [Float] = []
        var previousSpectrum: [Float] = Array(repeating: 0, count: windowSize / 2)
        
        for i in stride(from: 0, to: audioData.count - windowSize, by: hopSize) {
            let window = Array(audioData[i..<i + windowSize])
            let spectrum = calculateFFTMagnitude(signal: window)
            
            // Calculate spectral flux (difference between consecutive spectra)
            var flux: Float = 0
            for j in 0..<spectrum.count {
                let diff = spectrum[j] - previousSpectrum[j]
                flux += max(diff, 0) // Only positive differences (onsets)
            }
            
            onsetStrength.append(flux)
            previousSpectrum = spectrum
        }
        
        return onsetStrength
    }
    
    nonisolated private func calculateFFTMagnitude(signal: [Float]) -> [Float] {
        let count = signal.count
        let log2n = vDSP_Length(log2(Float(count)))
        
        guard let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2)) else {
            return []
        }
        
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        var realp = [Float](repeating: 0, count: count / 2)
        var imagp = [Float](repeating: 0, count: count / 2)
        
        return realp.withUnsafeMutableBufferPointer { realPtr in
            imagp.withUnsafeMutableBufferPointer { imagPtr in
                var output = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                
                signal.withUnsafeBytes {
                    vDSP_ctoz([DSPComplex]($0.bindMemory(to: DSPComplex.self)), 2, &output, 1, vDSP_Length(count / 2))
                }
                
                vDSP_fft_zrip(fftSetup, &output, 1, log2n, Int32(FFT_FORWARD))
                
                var magnitudes = [Float](repeating: 0, count: count / 2)
                vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(count / 2))
                
                return magnitudes
            }
        }
    }
    
    nonisolated private func calculateAutocorrelation(signal: [Float]) -> [Float] {
        let count = signal.count
        var result = [Float](repeating: 0, count: count)
        
        for lag in 0..<count {
            var sum: Float = 0
            for i in 0..<(count - lag) {
                sum += signal[i] * signal[i + lag]
            }
            result[lag] = sum / Float(count - lag)
        }
        
        return result
    }
    
    nonisolated private func findPeaks(in signal: [Float], minDistance: Int) -> [Int] {
        var peaks: [Int] = []
        
        for i in minDistance..<(signal.count - minDistance) {
            var isPeak = true
            
            // Check if current point is higher than neighbors
            for j in (i - minDistance)...(i + minDistance) {
                if j != i && signal[j] >= signal[i] {
                    isPeak = false
                    break
                }
            }
            
            if isPeak && signal[i] > 0.1 { // Threshold for peak detection
                peaks.append(i)
            }
        }
        
        return peaks
    }
    
    // MARK: - Key Analysis
    nonisolated private func analyzeKey(audioData: [Float], sampleRate: Double) -> (key: String?, confidence: Double) {
        let windowSize = 4096
        let hopSize = 2048
        
        // Calculate chromagram
        let chromagram = calculateChromagram(audioData: audioData, windowSize: windowSize, hopSize: hopSize, sampleRate: sampleRate)
        
        // Average chromagram over time
        let avgChroma = averageChromagram(chromagram)
        
        // Find the most prominent pitch class
        guard let maxIndex = avgChroma.enumerated().max(by: { $0.element < $1.element })?.offset else {
            return (nil, 0.0)
        }
        
        let pitchClasses = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let rootNote = pitchClasses[maxIndex]
        
        // Determine if major or minor
        let majorProfile: [Float] = [1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0]
        let minorProfile: [Float] = [1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0]
        
        let majorCorrelation = calculateCorrelation(avgChroma, majorProfile, shift: maxIndex)
        let minorCorrelation = calculateCorrelation(avgChroma, minorProfile, shift: maxIndex)
        
        let isMajor = majorCorrelation > minorCorrelation
        let mode = isMajor ? "major" : "minor"
        let confidence = Double(max(majorCorrelation, minorCorrelation))
        
        return ("\(rootNote) \(mode)", confidence)
    }
    
    nonisolated private func calculateChromagram(audioData: [Float], windowSize: Int, hopSize: Int, sampleRate: Double) -> [[Float]] {
        var chromagram: [[Float]] = []
        
        for i in stride(from: 0, to: audioData.count - windowSize, by: hopSize) {
            let window = Array(audioData[i..<i + windowSize])
            let spectrum = calculateFFTMagnitude(signal: window)
            let chroma = spectrumToChroma(spectrum: spectrum, sampleRate: sampleRate)
            chromagram.append(chroma)
        }
        
        return chromagram
    }
    
    nonisolated private func spectrumToChroma(spectrum: [Float], sampleRate: Double) -> [Float] {
        var chroma = [Float](repeating: 0, count: 12)
        let binWidth = sampleRate / Double(spectrum.count * 2)
        
        for (bin, magnitude) in spectrum.enumerated() {
            let frequency = Double(bin) * binWidth
            if frequency > 80 && frequency < 2000 { // Focus on musical range
                let pitchClass = frequencyToPitchClass(frequency)
                chroma[pitchClass] += magnitude
            }
        }
        
        // Normalize
        let sum = chroma.reduce(0, +)
        if sum > 0 {
            chroma = chroma.map { $0 / sum }
        }
        
        return chroma
    }
    
    nonisolated private func frequencyToPitchClass(_ frequency: Double) -> Int {
        let a4 = 440.0
        let c0 = a4 * pow(2, -4.75) // C0 frequency
        let semitones = 12 * log2(frequency / c0)
        return Int(semitones.rounded()) % 12
    }
    
    nonisolated private func averageChromagram(_ chromagram: [[Float]]) -> [Float] {
        guard !chromagram.isEmpty else { return [] }
        
        var avgChroma = [Float](repeating: 0, count: 12)
        
        for chroma in chromagram {
            for i in 0..<12 {
                avgChroma[i] += chroma[i]
            }
        }
        
        let count = Float(chromagram.count)
        avgChroma = avgChroma.map { $0 / count }
        
        return avgChroma
    }
    
    nonisolated private func calculateCorrelation(_ signal1: [Float], _ signal2: [Float], shift: Int) -> Float {
        var correlation: Float = 0
        
        for i in 0..<signal1.count {
            let j = (i + shift) % signal2.count
            correlation += signal1[i] * signal2[j]
        }
        
        return correlation / Float(signal1.count)
    }
    
    // MARK: - Instrument Classification
    nonisolated private func classifyInstrument(audioData: [Float], fileName: String) -> (instrument: InstrumentType, confidence: Double) {
        // Filename-based classification (fast heuristics)
        let fileClassification = classifyByFilename(fileName)
        
        // Audio-based classification
        let audioClassification = classifyByAudioFeatures(audioData)
        
        // Combine both approaches
        if fileClassification.confidence > 0.8 {
            return fileClassification
        } else {
            // Weight both approaches
            let combinedConfidence = (fileClassification.confidence * 0.3) + (audioClassification.confidence * 0.7)
            
            if audioClassification.confidence > 0.6 {
                return (audioClassification.instrument, combinedConfidence)
            } else {
                return (fileClassification.instrument, combinedConfidence)
            }
        }
    }
    
    nonisolated private func classifyByFilename(_ fileName: String) -> (instrument: InstrumentType, confidence: Double) {
        let lowercased = fileName.lowercased()
        
        let patterns: [(pattern: String, instrument: InstrumentType, confidence: Double)] = [
            ("kick", .kick, 0.9),
            ("bd", .kick, 0.85),
            ("snare", .snare, 0.9),
            ("sd", .snare, 0.85),
            ("clap", .snare, 0.8),
            ("bass", .bass, 0.85),
            ("sub", .bass, 0.8),
            ("808", .bass, 0.9),
            ("melody", .melody, 0.8),
            ("lead", .lead, 0.8),
            ("synth", .melody, 0.7),
            ("piano", .melody, 0.85),
            ("guitar", .melody, 0.85),
            ("fx", .fx, 0.9),
            ("effect", .fx, 0.85),
            ("sweep", .fx, 0.8),
            ("vocal", .vocal, 0.9),
            ("vox", .vocal, 0.85),
            ("voice", .vocal, 0.8),
            ("perc", .percussion, 0.8),
            ("hat", .percussion, 0.8),
            ("crash", .percussion, 0.8),
            ("pad", .pad, 0.8)
        ]
        
        for (pattern, instrument, confidence) in patterns {
            if lowercased.contains(pattern) {
                return (instrument, confidence)
            }
        }
        
        return (.unknown, 0.3)
    }
    
    nonisolated private func classifyByAudioFeatures(_ audioData: [Float]) -> (instrument: InstrumentType, confidence: Double) {
        // Calculate audio features for classification
        let spectralCentroid = calculateSpectralCentroid(audioData)
        let _ = calculateSpectralRolloff(audioData)
        let zeroCrossingRate = calculateZeroCrossingRate(audioData)
        let rms = calculateRMS(audioData)
        
        // Simple rule-based classification
        if spectralCentroid < 500 && rms > 0.1 {
            return (.kick, 0.7)
        } else if spectralCentroid > 2000 && zeroCrossingRate > 0.1 {
            return (.snare, 0.6)
        } else if spectralCentroid < 300 {
            return (.bass, 0.6)
        } else if spectralCentroid > 1000 && spectralCentroid < 3000 {
            return (.melody, 0.5)
        } else if spectralCentroid > 3000 {
            return (.fx, 0.5)
        }
        
        return (.unknown, 0.3)
    }
    
    // MARK: - Audio Feature Calculations
    nonisolated private func calculateSpectralCentroid(_ audioData: [Float]) -> Double {
        let spectrum = calculateFFTMagnitude(signal: audioData)
        var weightedSum: Double = 0
        var magnitudeSum: Double = 0
        
        for (i, magnitude) in spectrum.enumerated() {
            weightedSum += Double(i * Int(magnitude))
            magnitudeSum += Double(magnitude)
        }
        
        return magnitudeSum > 0 ? weightedSum / magnitudeSum : 0
    }
    
    nonisolated private func calculateSpectralRolloff(_ audioData: [Float]) -> Double {
        let spectrum = calculateFFTMagnitude(signal: audioData)
        let totalEnergy = spectrum.reduce(0) { $0 + Double($1) }
        let threshold = totalEnergy * 0.85
        
        var cumulativeEnergy: Double = 0
        for (i, magnitude) in spectrum.enumerated() {
            cumulativeEnergy += Double(magnitude)
            if cumulativeEnergy >= threshold {
                return Double(i)
            }
        }
        
        return Double(spectrum.count)
    }
    
    nonisolated private func calculateZeroCrossingRate(_ audioData: [Float]) -> Double {
        var crossings = 0
        
        for i in 1..<audioData.count {
            if (audioData[i] >= 0) != (audioData[i-1] >= 0) {
                crossings += 1
            }
        }
        
        return Double(crossings) / Double(audioData.count)
    }
    
    nonisolated private func calculateRMS(_ audioData: [Float]) -> Double {
        let sumOfSquares = audioData.reduce(0) { $0 + Double($1 * $1) }
        return sqrt(sumOfSquares / Double(audioData.count))
    }
    
    // MARK: - Mood Analysis
    nonisolated private func analyzeMood(audioData: [Float], instrument: InstrumentType) -> (mood: MoodType, confidence: Double) {
        let energy = calculateEnergy(audioData: audioData).energy
        let brightness = calculateBrightness(audioData)
        let roughness = calculateRoughness(audioData)
        
        // Rule-based mood classification
        if brightness < 0.3 && energy > 7 {
            return (.dark, 0.8)
        } else if brightness > 0.7 {
            return (.bright, 0.8)
        } else if roughness > 0.7 && energy > 6 {
            return (.aggressive, 0.7)
        } else if energy < 4 && roughness < 0.3 {
            return (.chill, 0.7)
        } else if brightness > 0.5 && energy > 5 {
            return (.energetic, 0.6)
        } else if instrument == .melody || instrument == .pad {
            return (.melodic, 0.6)
        } else {
            return (.ambient, 0.4)
        }
    }
    
    nonisolated private func calculateBrightness(_ audioData: [Float]) -> Double {
        let spectrum = calculateFFTMagnitude(signal: audioData)
        let totalEnergy = spectrum.reduce(0) { $0 + Double($1) }
        
        let highFreqStart = spectrum.count / 2
        let highFreqEnergy = spectrum[highFreqStart...].reduce(0) { $0 + Double($1) }
        
        return totalEnergy > 0 ? highFreqEnergy / totalEnergy : 0
    }
    
    nonisolated private func calculateRoughness(_ audioData: [Float]) -> Double {
        // Simplified roughness calculation based on spectral irregularity
        let spectrum = calculateFFTMagnitude(signal: audioData)
        var roughness: Double = 0
        
        for i in 1..<spectrum.count-1 {
            let diff = abs(Double(spectrum[i]) - (Double(spectrum[i-1]) + Double(spectrum[i+1])) / 2)
            roughness += diff
        }
        
        let totalEnergy = spectrum.reduce(0) { $0 + Double($1) }
        return totalEnergy > 0 ? roughness / totalEnergy : 0
    }
    
    // MARK: - Energy Analysis
    nonisolated private func calculateEnergy(audioData: [Float]) -> (energy: Int, confidence: Double) {
        let rms = calculateRMS(audioData)
        let peakAmplitude = audioData.map { abs($0) }.max() ?? 0
        let dynamicRange = Double(peakAmplitude) / max(rms, 0.001)
        
        // Convert to 1-10 scale
        let normalizedEnergy = min(max(rms * 10, 0), 1) // Normalize RMS to 0-1, then scale to 0-10
        let energyWithDynamics = normalizedEnergy * min(dynamicRange / 5, 1) // Factor in dynamic range
        
        let energy = Int((energyWithDynamics * 10).rounded())
        let confidence = min(rms * 5, 1.0) // Higher RMS = higher confidence
        
        return (max(1, min(energy, 10)), confidence)
    }
    
    // MARK: - Loop Detection
    nonisolated private func detectLoop(audioData: [Float], duration: Double) -> (isLoop: Bool, confidence: Double) {
        // Simple loop detection based on duration and repetition
        let isShort = duration < 8.0 // Loops are typically short
        let hasRepetition = detectRepetition(audioData)
        
        if isShort && hasRepetition.hasRepetition {
            return (true, hasRepetition.confidence)
        } else if isShort {
            return (true, 0.6) // Short samples are likely loops
        } else {
            return (false, 1.0 - hasRepetition.confidence)
        }
    }
    
    nonisolated private func detectRepetition(_ audioData: [Float]) -> (hasRepetition: Bool, confidence: Double) {
        // Simplified repetition detection using autocorrelation
        let sampleCount = min(audioData.count, 44100) // Analyze first second
        let samples = Array(audioData.prefix(sampleCount))
        let autocorr = calculateAutocorrelation(signal: samples)
        
        // Look for strong peaks in autocorrelation (indicating repetition)
        let peaks = findPeaks(in: autocorr, minDistance: 1000)
        let strongPeaks = peaks.filter { autocorr[$0] > 0.5 }
        
        let hasRepetition = !strongPeaks.isEmpty
        let confidence = strongPeaks.isEmpty ? 0.0 : Double(strongPeaks.map { autocorr[$0] }.max() ?? 0)
        
        return (hasRepetition, confidence)
    }
    
    // MARK: - Quality Analysis
    nonisolated private func analyzeQuality(format: AVAudioFormat, url: URL) -> AudioQuality {
        let sampleRate = Int(format.sampleRate)
        let bitDepth = Int(format.commonFormat.rawValue == AVAudioCommonFormat.pcmFormatInt16.rawValue ? 16 : 24)
        let fileExtension = url.pathExtension.lowercased()
        
        // Estimate bitrate for compressed formats
        var bitrate: Int? = nil
        if fileExtension == "mp3" || fileExtension == "aac" {
            // Estimate based on file size and duration
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64,
               let audioFile = try? AVAudioFile(forReading: url) {
                let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
                bitrate = Int((Double(fileSize * 8) / duration) / 1000) // kbps
            }
        }
        
        return AudioQuality(
            bitDepth: bitDepth,
            sampleRate: sampleRate,
            bitrate: bitrate,
            format: fileExtension
        )
    }
    
    // MARK: - Vocal Detection
    nonisolated private func detectVocals(audioData: [Float], sampleRate: Double) -> (hasVocals: Bool, confidence: Double) {
        // Analyze spectral characteristics typical of vocals
        let spectralCentroid = calculateSpectralCentroid(audioData)
        let spectralRolloff = calculateSpectralRolloff(audioData)
        let harmonicity = calculateHarmonicity(audioData)
        
        // Vocals typically have:
        // - Moderate spectral centroid (speech formants)
        // - Strong harmonics
        // - Spectral rolloff in vocal range
        
        var vocalScore: Double = 0
        
        if spectralCentroid > 500 && spectralCentroid < 2000 {
            vocalScore += 0.3
        }
        
        if harmonicity > 0.6 {
            vocalScore += 0.4
        }
        
        if spectralRolloff > 1000 && spectralRolloff < 4000 {
            vocalScore += 0.3
        }
        
        let hasVocals = vocalScore > 0.5
        return (hasVocals, vocalScore)
    }
    
    nonisolated private func calculateHarmonicity(_ audioData: [Float]) -> Double {
        // Simplified harmonicity calculation
        let spectrum = calculateFFTMagnitude(signal: audioData)
        
        var harmonicStrength: Double = 0
        var totalEnergy: Double = 0
        
        for (i, magnitude) in spectrum.enumerated() {
            let frequency = Double(i) * 44100.0 / Double(spectrum.count * 2)
            totalEnergy += Double(magnitude)
            
            // Check if frequency is a harmonic of common fundamentals
            for fundamental in stride(from: 80.0, through: 400.0, by: 10.0) {
                for harmonic in 1...8 {
                    let harmonicFreq = fundamental * Double(harmonic)
                    if abs(frequency - harmonicFreq) < 20 {
                        harmonicStrength += Double(magnitude)
                        break
                    }
                }
            }
        }
        
        return totalEnergy > 0 ? harmonicStrength / totalEnergy : 0
    }
    
    // MARK: - Confidence Calculation
    nonisolated private func calculateOverallConfidence(bpm: Double, key: Double, instrument: Double, mood: Double, energy: Double) -> Double {
        let confidences = [bpm, key, instrument, mood, energy]
        let validConfidences = confidences.filter { $0 > 0 }
        
        guard !validConfidences.isEmpty else { return 0.3 }
        
        let average = validConfidences.reduce(0, +) / Double(validConfidences.count)
        return min(max(average, 0.3), 0.95) // Clamp between 30% and 95%
    }
}

// MARK: - Error Types
enum AudioAnalysisError: Error {
    case bufferCreationFailed
    case fileReadError
    case unsupportedFormat
    case analysisTimeout
}

// MARK: - Batch Analysis Manager
@MainActor
class BatchAnalysisManager: ObservableObject {
    @Published var isAnalyzing = false
    @Published var progress: Double = 0.0
    @Published var currentFile: String = ""
    @Published var processedCount = 0
    @Published var totalCount = 0
    @Published var results: [URL: SampleAnalysis] = [:]
    @Published var errors: [URL: Error] = [:]
    
    func analyzeSamples(_ urls: [URL]) async {
        isAnalyzing = true
        progress = 0.0
        processedCount = 0
        totalCount = urls.count
        results.removeAll()
        errors.removeAll()
        
        let engine = AudioAnalysisEngine.shared
        
        for (index, url) in urls.enumerated() {
            currentFile = url.lastPathComponent
            
            do {
                let analysis = try await engine.analyzeSample(at: url)
                results[url] = analysis
            } catch {
                errors[url] = error
            }
            
            processedCount = index + 1
            progress = Double(processedCount) / Double(totalCount)
        }
        
        isAnalyzing = false
    }
    
    func cancelAnalysis() {
        isAnalyzing = false
    }
}

