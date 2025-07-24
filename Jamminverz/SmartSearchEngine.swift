//
//  SmartSearchEngine.swift
//  Jamminverz
//
//  Advanced natural language search engine for samples
//

import Foundation
import NaturalLanguage

// MARK: - Search Query Parser
class SmartSearchEngine: ObservableObject {
    static let shared = SmartSearchEngine()
    
    @Published var searchResults: [Sample] = []
    @Published var isSearching = false
    @Published var searchSuggestions: [String] = []
    
    private let nlProcessor = NaturalLanguageProcessor()
    private let queryParser = SearchQueryParser()
    
    private init() {
        setupSearchSuggestions()
    }
    
    // MARK: - Main Search Function
    func search(_ query: String, in samples: [Sample]) {
        guard !query.isEmpty else {
            searchResults = samples
            return
        }
        
        isSearching = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let parsedQuery = self.queryParser.parse(query)
            let filteredSamples = self.filterSamples(samples, with: parsedQuery)
            let rankedSamples = self.rankSearchResults(filteredSamples, query: parsedQuery)
            
            DispatchQueue.main.async {
                self.searchResults = rankedSamples
                self.isSearching = false
            }
        }
    }
    
    // MARK: - Query Parsing
    private func filterSamples(_ samples: [Sample], with query: ParsedSearchQuery) -> [Sample] {
        return samples.filter { sample in
            var matches = true
            
            // Text search
            if !query.textTerms.isEmpty {
                matches = matches && matchesTextTerms(sample, terms: query.textTerms)
            }
            
            // Instrument filter
            if let instrument = query.instrument {
                matches = matches && (sample.analyzedData?.instrument == instrument)
            }
            
            // Mood filter
            if let mood = query.mood {
                matches = matches && (sample.analyzedData?.mood == mood)
            }
            
            // BPM range
            if let bpmRange = query.bpmRange {
                if let sampleBPM = sample.analyzedData?.bpm {
                    matches = matches && bpmRange.contains(sampleBPM)
                } else {
                    matches = false
                }
            }
            
            // Key filter
            if let key = query.key {
                matches = matches && (sample.analyzedData?.key?.lowercased().contains(key.lowercased()) ?? false)
            }
            
            // Energy range
            if let energyRange = query.energyRange {
                let energy = sample.analyzedData?.energy ?? 5
                matches = matches && energyRange.contains(energy)
            }
            
            // Loop filter
            if let isLoop = query.isLoop {
                matches = matches && (sample.analyzedData?.isLoop == isLoop)
            }
            
            // Vocal filter
            if let hasVocals = query.hasVocals {
                matches = matches && (sample.analyzedData?.hasVocals == hasVocals)
            }
            
            // Duration range
            if let durationRange = query.durationRange {
                if let duration = sample.analyzedData?.duration {
                    matches = matches && durationRange.contains(duration)
                } else {
                    matches = false
                }
            }
            
            // Quality filters
            if let minSampleRate = query.minSampleRate {
                let sampleRate = sample.analyzedData?.quality.sampleRate ?? 0
                matches = matches && (sampleRate >= minSampleRate)
            }
            
            if let minBitDepth = query.minBitDepth {
                let bitDepth = sample.analyzedData?.quality.bitDepth ?? 0
                matches = matches && (bitDepth >= minBitDepth)
            }
            
            return matches
        }
    }
    
    private func matchesTextTerms(_ sample: Sample, terms: [String]) -> Bool {
        let searchableText = [
            sample.displayName,
            sample.fileName,
            sample.tags.joined(separator: " "),
            sample.analyzedData?.key ?? "",
            sample.analyzedData?.instrument.rawValue ?? "",
            sample.analyzedData?.mood.rawValue ?? ""
        ].joined(separator: " ").lowercased()
        
        return terms.allSatisfy { term in
            searchableText.contains(term.lowercased())
        }
    }
    
    // MARK: - Search Result Ranking
    private func rankSearchResults(_ samples: [Sample], query: ParsedSearchQuery) -> [Sample] {
        return samples.sorted { sample1, sample2 in
            let score1 = calculateRelevanceScore(sample1, query: query)
            let score2 = calculateRelevanceScore(sample2, query: query)
            return score1 > score2
        }
    }
    
    private func calculateRelevanceScore(_ sample: Sample, query: ParsedSearchQuery) -> Double {
        var score: Double = 0
        
        // Base score from analysis confidence
        if let confidence = sample.analyzedData?.confidence {
            score += confidence * 0.1
        }
        
        // Text relevance
        if !query.textTerms.isEmpty {
            score += calculateTextRelevance(sample, terms: query.textTerms) * 0.4
        }
        
        // Instrument match bonus
        if let queryInstrument = query.instrument,
           let sampleInstrument = sample.analyzedData?.instrument,
           queryInstrument == sampleInstrument {
            score += 0.3
        }
        
        // Mood match bonus
        if let queryMood = query.mood,
           let sampleMood = sample.analyzedData?.mood,
           queryMood == sampleMood {
            score += 0.2
        }
        
        // BPM proximity bonus
        if let queryBPMRange = query.bpmRange,
           let sampleBPM = sample.analyzedData?.bpm {
            let midpoint = (queryBPMRange.lowerBound + queryBPMRange.upperBound) / 2
            let proximity = 1.0 - min(abs(Double(sampleBPM - midpoint)) / 50.0, 1.0)
            score += proximity * 0.15
        }
        
        // Recent files bonus
        let daysSinceAdded = Date().timeIntervalSince(sample.dateAdded) / 86400
        if daysSinceAdded < 7 {
            score += 0.05 * (7 - daysSinceAdded) / 7
        }
        
        // Quality bonus
        if let quality = sample.analyzedData?.quality {
            if quality.sampleRate >= 44100 { score += 0.02 }
            if quality.bitDepth >= 24 { score += 0.02 }
            if quality.format == "wav" { score += 0.01 }
        }
        
        return score
    }
    
    private func calculateTextRelevance(_ sample: Sample, terms: [String]) -> Double {
        let searchableText = [
            sample.displayName,
            sample.fileName,
            sample.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        
        var relevance: Double = 0
        
        for term in terms {
            let lowercaseTerm = term.lowercased()
            
            // Exact match in display name (highest priority)
            if sample.displayName.lowercased().contains(lowercaseTerm) {
                relevance += 1.0
            }
            
            // Match in filename
            if sample.fileName.lowercased().contains(lowercaseTerm) {
                relevance += 0.8
            }
            
            // Match in tags
            if sample.tags.joined(separator: " ").lowercased().contains(lowercaseTerm) {
                relevance += 0.6
            }
            
            // Fuzzy matching
            let fuzzyScore = calculateFuzzyMatch(lowercaseTerm, in: searchableText)
            relevance += fuzzyScore * 0.3
        }
        
        return relevance / Double(terms.count)
    }
    
    private func calculateFuzzyMatch(_ term: String, in text: String) -> Double {
        // Simple fuzzy matching based on character overlap
        let termChars = Set(term.lowercased())
        let textChars = Set(text.lowercased())
        let intersection = termChars.intersection(textChars)
        
        return Double(intersection.count) / Double(termChars.count)
    }
    
    // MARK: - Search Suggestions
    private func setupSearchSuggestions() {
        searchSuggestions = [
            "dark trap kicks",
            "melodic loops in C major",
            "aggressive bass samples",
            "vocal chops under 5 seconds",
            "lofi drums 80-90 BPM",
            "bright synth leads",
            "ambient pads",
            "punchy snares",
            "sub bass 808s",
            "energetic melody loops",
            "chill vocal samples",
            "hard-hitting kicks",
            "atmospheric fx",
            "high-energy drops",
            "smooth jazz samples"
        ]
    }
    
    func getSuggestions(for partialQuery: String) -> [String] {
        guard !partialQuery.isEmpty else { return searchSuggestions }
        
        let lowercaseQuery = partialQuery.lowercased()
        return searchSuggestions.filter { suggestion in
            suggestion.lowercased().contains(lowercaseQuery)
        }
    }
}

// MARK: - Search Query Parser
struct ParsedSearchQuery {
    var textTerms: [String] = []
    var instrument: InstrumentType?
    var mood: MoodType?
    var bpmRange: ClosedRange<Int>?
    var key: String?
    var energyRange: ClosedRange<Int>?
    var isLoop: Bool?
    var hasVocals: Bool?
    var durationRange: ClosedRange<Double>?
    var minSampleRate: Int?
    var minBitDepth: Int?
}

class SearchQueryParser {
    private let nlTokenizer = NLTokenizer(unit: .word)
    
    func parse(_ query: String) -> ParsedSearchQuery {
        var parsedQuery = ParsedSearchQuery()
        
        // Tokenize the query
        nlTokenizer.string = query.lowercased()
        let tokens = nlTokenizer.tokens(for: query.startIndex..<query.endIndex).map {
            String(query[$0])
        }
        
        var remainingTokens = tokens
        
        // Parse BPM patterns
        parsedQuery.bpmRange = extractBPMRange(from: query, tokens: &remainingTokens)
        
        // Parse key signatures
        parsedQuery.key = extractKey(from: tokens, remainingTokens: &remainingTokens)
        
        // Parse instruments
        parsedQuery.instrument = extractInstrument(from: tokens, remainingTokens: &remainingTokens)
        
        // Parse moods
        parsedQuery.mood = extractMood(from: tokens, remainingTokens: &remainingTokens)
        
        // Parse special attributes
        parsedQuery.isLoop = extractBooleanAttribute(from: tokens, keywords: ["loop", "loops"], remainingTokens: &remainingTokens)
        parsedQuery.hasVocals = extractBooleanAttribute(from: tokens, keywords: ["vocal", "vocals", "voice"], remainingTokens: &remainingTokens)
        
        // Parse duration
        parsedQuery.durationRange = extractDurationRange(from: query, tokens: &remainingTokens)
        
        // Parse energy descriptors
        parsedQuery.energyRange = extractEnergyRange(from: tokens, remainingTokens: &remainingTokens)
        
        // Parse quality requirements
        (parsedQuery.minSampleRate, parsedQuery.minBitDepth) = extractQualityRequirements(from: tokens, remainingTokens: &remainingTokens)
        
        // Remaining tokens become text search terms
        parsedQuery.textTerms = remainingTokens.filter { !$0.isEmpty && $0.count > 1 }
        
        return parsedQuery
    }
    
    // MARK: - Extraction Methods
    private func extractBPMRange(from query: String, tokens: inout [String]) -> ClosedRange<Int>? {
        // Pattern: "85BPM", "80-100", "under 90", "over 120", etc.
        let bpmPatterns = [
            #"(\d+)\s*bpm"#,
            #"(\d+)\s*-\s*(\d+)\s*bpm"#,
            #"(\d+)\s*-\s*(\d+)"#,
            #"under\s+(\d+)"#,
            #"below\s+(\d+)"#,
            #"over\s+(\d+)"#,
            #"above\s+(\d+)"#,
            #"around\s+(\d+)"#
        ]
        
        for pattern in bpmPatterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: query.count)
            
            if let match = regex.firstMatch(in: query, options: [], range: range) {
                let matchedString = (query as NSString).substring(with: match.range)
                
                // Remove matched tokens
                let matchTokens = matchedString.lowercased().split(separator: " ").map(String.init)
                tokens.removeAll { matchTokens.contains($0) }
                
                if match.numberOfRanges == 2 {
                    // Single BPM or range endpoint
                    let bpmString = (query as NSString).substring(with: match.range(at: 1))
                    if let bpm = Int(bpmString) {
                        if matchedString.lowercased().contains("under") || matchedString.lowercased().contains("below") {
                            return 60...bpm
                        } else if matchedString.lowercased().contains("over") || matchedString.lowercased().contains("above") {
                            return bpm...200
                        } else if matchedString.lowercased().contains("around") {
                            return max(60, bpm-10)...min(200, bpm+10)
                        } else {
                            return max(60, bpm-5)...min(200, bpm+5)
                        }
                    }
                } else if match.numberOfRanges == 3 {
                    // BPM range
                    let bpm1String = (query as NSString).substring(with: match.range(at: 1))
                    let bpm2String = (query as NSString).substring(with: match.range(at: 2))
                    if let bpm1 = Int(bpm1String), let bpm2 = Int(bpm2String) {
                        return min(bpm1, bpm2)...max(bpm1, bpm2)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractKey(from tokens: [String], remainingTokens: inout [String]) -> String? {
        let keyPatterns = [
            "c major", "c minor", "c# major", "c# minor",
            "d major", "d minor", "d# major", "d# minor",
            "e major", "e minor", "f major", "f minor",
            "f# major", "f# minor", "g major", "g minor",
            "g# major", "g# minor", "a major", "a minor",
            "a# major", "a# minor", "b major", "b minor"
        ]
        
        let joinedTokens = tokens.joined(separator: " ")
        
        for pattern in keyPatterns {
            if joinedTokens.contains(pattern) {
                // Remove key tokens
                let keyTokens = pattern.split(separator: " ").map(String.init)
                for keyToken in keyTokens {
                    remainingTokens.removeAll { $0 == keyToken }
                }
                return pattern
            }
        }
        
        // Check for simple key patterns (just note names)
        let notes = ["c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"]
        for note in notes {
            if tokens.contains(note) {
                remainingTokens.removeAll { $0 == note }
                return note
            }
        }
        
        return nil
    }
    
    private func extractInstrument(from tokens: [String], remainingTokens: inout [String]) -> InstrumentType? {
        let instrumentMappings: [String: InstrumentType] = [
            "kick": .kick, "kicks": .kick, "bd": .kick,
            "snare": .snare, "snares": .snare, "sd": .snare, "clap": .snare,
            "bass": .bass, "sub": .bass, "808": .bass,
            "melody": .melody, "melodic": .melody, "synth": .melody,
            "lead": .lead, "leads": .lead,
            "pad": .pad, "pads": .pad,
            "fx": .fx, "effect": .fx, "effects": .fx,
            "vocal": .vocal, "vocals": .vocal, "voice": .vocal,
            "percussion": .percussion, "perc": .percussion, "hat": .percussion
        ]
        
        for (keyword, instrument) in instrumentMappings {
            if tokens.contains(keyword) {
                remainingTokens.removeAll { $0 == keyword }
                return instrument
            }
        }
        
        return nil
    }
    
    private func extractMood(from tokens: [String], remainingTokens: inout [String]) -> MoodType? {
        let moodMappings: [String: MoodType] = [
            "dark": .dark, "deep": .dark, "mysterious": .dark,
            "bright": .bright, "happy": .bright, "uplifting": .bright,
            "aggressive": .aggressive, "hard": .aggressive, "intense": .aggressive,
            "chill": .chill, "relaxed": .chill, "calm": .chill, "smooth": .chill,
            "melodic": .melodic, "beautiful": .melodic, "sweet": .melodic,
            "energetic": .energetic, "pumping": .energetic, "exciting": .energetic,
            "ambient": .ambient, "atmospheric": .ambient, "spacey": .ambient,
            "emotional": .emotional, "sad": .emotional, "melancholy": .emotional
        ]
        
        for (keyword, mood) in moodMappings {
            if tokens.contains(keyword) {
                remainingTokens.removeAll { $0 == keyword }
                return mood
            }
        }
        
        return nil
    }
    
    private func extractBooleanAttribute(from tokens: [String], keywords: [String], remainingTokens: inout [String]) -> Bool? {
        for keyword in keywords {
            if tokens.contains(keyword) {
                remainingTokens.removeAll { $0 == keyword }
                return true
            }
        }
        return nil
    }
    
    private func extractDurationRange(from query: String, tokens: inout [String]) -> ClosedRange<Double>? {
        let durationPatterns = [
            #"under\s+(\d+)\s+seconds?"#,
            #"over\s+(\d+)\s+seconds?"#,
            #"(\d+)\s*-\s*(\d+)\s+seconds?"#,
            #"short"#,
            #"long"#
        ]
        
        for pattern in durationPatterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: query.count)
            
            if let match = regex.firstMatch(in: query, options: [], range: range) {
                let matchedString = (query as NSString).substring(with: match.range)
                
                if matchedString.lowercased().contains("short") {
                    tokens.removeAll { $0 == "short" }
                    return 0...5
                } else if matchedString.lowercased().contains("long") {
                    tokens.removeAll { $0 == "long" }
                    return 10...60
                } else if match.numberOfRanges == 2 {
                    let durationString = (query as NSString).substring(with: match.range(at: 1))
                    if let duration = Double(durationString) {
                        if matchedString.lowercased().contains("under") {
                            return 0...duration
                        } else if matchedString.lowercased().contains("over") {
                            return duration...60
                        }
                    }
                } else if match.numberOfRanges == 3 {
                    let duration1String = (query as NSString).substring(with: match.range(at: 1))
                    let duration2String = (query as NSString).substring(with: match.range(at: 2))
                    if let duration1 = Double(duration1String), let duration2 = Double(duration2String) {
                        return min(duration1, duration2)...max(duration1, duration2)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractEnergyRange(from tokens: [String], remainingTokens: inout [String]) -> ClosedRange<Int>? {
        let energyMappings: [String: ClosedRange<Int>] = [
            "low-energy": 1...3,
            "medium-energy": 4...6,
            "high-energy": 7...10,
            "pumping": 8...10,
            "intense": 8...10,
            "calm": 1...3,
            "moderate": 4...6
        ]
        
        for (keyword, range) in energyMappings {
            if tokens.contains(keyword) {
                remainingTokens.removeAll { $0 == keyword }
                return range
            }
        }
        
        return nil
    }
    
    private func extractQualityRequirements(from tokens: [String], remainingTokens: inout [String]) -> (sampleRate: Int?, bitDepth: Int?) {
        var minSampleRate: Int? = nil
        var minBitDepth: Int? = nil
        
        let qualityKeywords = ["hi-res", "high-res", "hd", "24-bit", "16-bit", "44.1", "48", "96"]
        
        for keyword in qualityKeywords {
            if tokens.contains(keyword) {
                remainingTokens.removeAll { $0 == keyword }
                
                switch keyword {
                case "hi-res", "high-res", "hd":
                    minSampleRate = 48000
                    minBitDepth = 24
                case "24-bit":
                    minBitDepth = 24
                case "16-bit":
                    minBitDepth = 16
                case "44.1":
                    minSampleRate = 44100
                case "48":
                    minSampleRate = 48000
                case "96":
                    minSampleRate = 96000
                default:
                    break
                }
            }
        }
        
        return (minSampleRate, minBitDepth)
    }
}

// MARK: - Natural Language Processor
class NaturalLanguageProcessor {
    private let tokenizer = NLTokenizer(unit: .word)
    
    func extractKeywords(from text: String) -> [String] {
        tokenizer.string = text
        let range = text.startIndex..<text.endIndex
        
        var keywords: [String] = []
        
        tokenizer.enumerateTokens(in: range) { tokenRange, _ in
            let word = String(text[tokenRange])
            
            // Simple filtering for meaningful words
            if word.count > 2 && !isStopWord(word.lowercased()) {
                keywords.append(word.lowercased())
            }
            
            return true
        }
        
        return keywords
    }
    
    func lemmatizeText(_ text: String) -> String {
        tokenizer.string = text
        let range = text.startIndex..<text.endIndex
        
        var words: [String] = []
        
        tokenizer.enumerateTokens(in: range) { tokenRange, _ in
            let word = String(text[tokenRange])
            words.append(word.lowercased())
            return true
        }
        
        return words.joined(separator: " ")
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "this", "that", "these", "those"])
        return stopWords.contains(word)
    }
}

// MARK: - Search History Manager
@MainActor
class SearchHistoryManager: ObservableObject {
    @Published var searchHistory: [String] = []
    @Published var popularSearches: [String] = []
    
    private let maxHistoryItems = 50
    private let userDefaults = UserDefaults.standard
    private let historyKey = "sample_search_history"
    private let popularKey = "popular_searches"
    
    init() {
        loadSearchHistory()
        updatePopularSearches()
    }
    
    func addSearchQuery(_ query: String) {
        guard !query.isEmpty else { return }
        
        // Remove if already exists
        searchHistory.removeAll { $0 == query }
        
        // Add to beginning
        searchHistory.insert(query, at: 0)
        
        // Limit history size
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }
        
        saveSearchHistory()
        updatePopularSearches()
    }
    
    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        searchHistory = userDefaults.stringArray(forKey: historyKey) ?? []
    }
    
    private func saveSearchHistory() {
        userDefaults.set(searchHistory, forKey: historyKey)
    }
    
    private func updatePopularSearches() {
        // Count frequency of search terms
        var termCounts: [String: Int] = [:]
        
        for query in searchHistory {
            let words = query.lowercased().split(separator: " ").map(String.init)
            for word in words {
                if word.count > 2 { // Only meaningful words
                    termCounts[word, default: 0] += 1
                }
            }
        }
        
        // Get most popular terms
        popularSearches = termCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }
}