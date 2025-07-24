import { useState, useEffect } from 'react'
import { Shuffle, Download, Save, Volume2 } from 'lucide-react'
import * as Tone from 'tone'
import PackGrid from '../components/PackGrid'
import { supabase } from '../lib/supabase'
import { useAuthStore } from '../stores/authStore'

// Sound generation parameters
const SOUND_TYPES = ['kick', 'snare', 'hihat', 'clap', 'bass', 'lead', 'fx', 'perc']
const WAVEFORMS = ['sine', 'square', 'sawtooth', 'triangle']

const Create = () => {
  const { user } = useAuthStore()
  const [samples, setSamples] = useState(Array(16).fill(null))
  const [packName, setPackName] = useState('Generated Pack ' + Date.now())
  const [isGenerating, setIsGenerating] = useState(false)
  const [isSaving, setIsSaving] = useState(false)

  // Generate a single sound
  const generateSound = async (type) => {
    const synth = new Tone.Synth({
      oscillator: {
        type: WAVEFORMS[Math.floor(Math.random() * WAVEFORMS.length)]
      },
      envelope: {
        attack: Math.random() * 0.1,
        decay: Math.random() * 0.3,
        sustain: Math.random() * 0.5,
        release: Math.random() * 0.5
      }
    }).toDestination()

    // Generate different sounds based on type
    const frequencies = {
      kick: [40, 60, 80],
      snare: [200, 300, 400],
      hihat: [800, 1200, 1600],
      clap: [1000, 1500, 2000],
      bass: [80, 100, 120],
      lead: [400, 600, 800],
      fx: [Math.random() * 2000 + 200],
      perc: [Math.random() * 1000 + 300]
    }

    const freq = frequencies[type][Math.floor(Math.random() * frequencies[type].length)]
    const duration = Math.random() * 0.5 + 0.1

    // Create a simple sound blob (in real app, this would be actual audio data)
    const soundData = {
      id: `${type}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name: `${type}_${Math.floor(Math.random() * 999)}`,
      type: type,
      frequency: freq,
      duration: duration,
      waveform: synth.oscillator.type,
      url: 'data:audio/wav;base64,placeholder' // In real app, generate actual audio
    }

    return soundData
  }

  // Generate 16 random sounds
  const generatePack = async () => {
    setIsGenerating(true)
    await Tone.start()

    const newSamples = []
    for (let i = 0; i < 16; i++) {
      const type = SOUND_TYPES[Math.floor(Math.random() * SOUND_TYPES.length)]
      const sound = await generateSound(type)
      newSamples.push(sound)
      
      // Add slight delay for visual effect
      setSamples(prev => {
        const updated = [...prev]
        updated[i] = sound
        return updated
      })
      
      await new Promise(resolve => setTimeout(resolve, 100))
    }

    setIsGenerating(false)
  }

  // Save pack to profile
  const savePack = async () => {
    if (!user || samples.filter(s => s).length === 0) return

    setIsSaving(true)
    try {
      const { data, error } = await supabase
        .from('sample_packs')
        .insert([{
          user_id: user.id,
          title: packName,
          description: 'Generated with Pack Creator',
          tags: ['generated', 'random', ...new Set(samples.filter(s => s).map(s => s?.type))],
          samples: samples.filter(s => s),
          is_public: true
        }])
        .select()
        .single()

      if (error) throw error

      // Show success message
      alert('Pack saved successfully!')
    } catch (error) {
      console.error('Error saving pack:', error)
      alert('Error saving pack')
    } finally {
      setIsSaving(false)
    }
  }

  // Export pack as zip
  const exportPack = () => {
    // In a real app, this would create actual WAV files and zip them
    const packData = {
      name: packName,
      samples: samples.filter(s => s),
      created: new Date().toISOString()
    }

    const blob = new Blob([JSON.stringify(packData, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${packName.replace(/\s+/g, '_')}.json`
    a.click()
    URL.revokeObjectURL(url)
  }

  // Initialize with empty pack
  useEffect(() => {
    generatePack()
  }, [])

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Pack Generator</h1>
        <p className="text-gray-400">Generate 16 random sounds and create instant sample packs</p>
      </div>

      {/* Controls */}
      <div className="bg-jade-dark rounded-lg p-6 pixel-border mb-8">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex-1 w-full sm:w-auto">
            <input
              type="text"
              value={packName}
              onChange={(e) => setPackName(e.target.value)}
              className="w-full px-4 py-2 bg-jade-darker border border-gray-700 rounded focus:border-jade-purple focus:outline-none"
              placeholder="Pack Name"
            />
          </div>
          
          <div className="flex flex-wrap gap-2">
            <button
              onClick={generatePack}
              disabled={isGenerating}
              className="flex items-center space-x-2 px-4 py-2 bg-jade-purple hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed rounded font-medium transition-colors"
            >
              <Shuffle size={16} />
              <span>{isGenerating ? 'Generating...' : 'Generate New'}</span>
            </button>
            
            <button
              onClick={savePack}
              disabled={isSaving || !user}
              className="flex items-center space-x-2 px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed rounded font-medium transition-colors"
            >
              <Save size={16} />
              <span>{isSaving ? 'Saving...' : 'Save to Profile'}</span>
            </button>
            
            <button
              onClick={exportPack}
              className="flex items-center space-x-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded font-medium transition-colors"
            >
              <Download size={16} />
              <span>Export</span>
            </button>
          </div>
        </div>
      </div>

      {/* 4x4 Pad Grid */}
      <div className="bg-jade-dark rounded-lg p-6 pixel-border">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold">Sound Pads</h2>
          <p className="text-sm text-gray-400">Click pads to play</p>
        </div>
        
        <PackGrid samples={samples} />
        
        {/* Sound Info */}
        <div className="mt-6 grid grid-cols-2 sm:grid-cols-4 gap-4">
          {SOUND_TYPES.map(type => {
            const count = samples.filter(s => s?.type === type).length
            return count > 0 ? (
              <div key={type} className="text-center">
                <p className="text-xs text-gray-400 uppercase">{type}</p>
                <p className="text-lg font-bold">{count}</p>
              </div>
            ) : null
          })}
        </div>
      </div>

      {/* Instructions */}
      <div className="mt-8 text-center text-sm text-gray-400">
        <p>🎲 Click "Generate New" to create random sounds</p>
        <p>🎹 Click any pad to play the sound</p>
        <p>💾 Save to your profile or export as files</p>
      </div>
    </div>
  )
}

export default Create