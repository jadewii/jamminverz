import { useState, useEffect, useRef } from 'react'
import { Play, Pause, Stop, Save, Plus, Trash2 } from 'lucide-react'
import * as Tone from 'tone'
import { supabase } from '../lib/supabase'
import { useAuthStore } from '../stores/authStore'

const STEPS = 16
const DEFAULT_BPM = 120

const Studio = () => {
  const { user } = useAuthStore()
  const [isPlaying, setIsPlaying] = useState(false)
  const [currentStep, setCurrentStep] = useState(-1)
  const [bpm, setBpm] = useState(DEFAULT_BPM)
  const [tracks, setTracks] = useState([
    { id: 1, name: 'Kick', sample: null, pattern: Array(STEPS).fill(false), volume: 0 },
    { id: 2, name: 'Snare', sample: null, pattern: Array(STEPS).fill(false), volume: 0 },
    { id: 3, name: 'HiHat', sample: null, pattern: Array(STEPS).fill(false), volume: 0 },
    { id: 4, name: 'Melody', sample: null, pattern: Array(STEPS).fill(false), volume: 0 },
  ])
  const [projectName, setProjectName] = useState('Untitled Project')
  const sequencerRef = useRef(null)
  const playersRef = useRef({})

  // Initialize Tone.js transport
  useEffect(() => {
    Tone.Transport.bpm.value = bpm
    return () => {
      Tone.Transport.stop()
      Tone.Transport.cancel()
    }
  }, [])

  // Update BPM
  useEffect(() => {
    Tone.Transport.bpm.value = bpm
  }, [bpm])

  // Toggle pattern step
  const toggleStep = (trackId, stepIndex) => {
    setTracks(prev => prev.map(track => 
      track.id === trackId 
        ? { ...track, pattern: track.pattern.map((step, i) => i === stepIndex ? !step : step) }
        : track
    ))
  }

  // Add new track
  const addTrack = () => {
    const newTrack = {
      id: Date.now(),
      name: `Track ${tracks.length + 1}`,
      sample: null,
      pattern: Array(STEPS).fill(false),
      volume: 0
    }
    setTracks(prev => [...prev, newTrack])
  }

  // Remove track
  const removeTrack = (trackId) => {
    setTracks(prev => prev.filter(track => track.id !== trackId))
    if (playersRef.current[trackId]) {
      playersRef.current[trackId].dispose()
      delete playersRef.current[trackId]
    }
  }

  // Handle sample drop
  const handleSampleDrop = async (e, trackId) => {
    e.preventDefault()
    const data = e.dataTransfer.getData('sample')
    if (data) {
      const sample = JSON.parse(data)
      
      // Load sample into player
      try {
        const player = new Tone.Player(sample.url).toDestination()
        await player.load(sample.url)
        playersRef.current[trackId] = player
        
        setTracks(prev => prev.map(track => 
          track.id === trackId ? { ...track, sample } : track
        ))
      } catch (error) {
        console.error('Error loading sample:', error)
      }
    }
  }

  // Play/Pause
  const togglePlayback = async () => {
    await Tone.start()
    
    if (isPlaying) {
      Tone.Transport.stop()
      setIsPlaying(false)
      setCurrentStep(-1)
    } else {
      // Schedule pattern playback
      const sequence = new Tone.Sequence((time, step) => {
        setCurrentStep(step)
        
        // Play samples for active steps
        tracks.forEach(track => {
          if (track.pattern[step] && track.sample && playersRef.current[track.id]) {
            playersRef.current[track.id].start(time)
          }
        })
      }, [...Array(STEPS).keys()], '16n')
      
      sequence.start(0)
      sequencerRef.current = sequence
      
      Tone.Transport.start()
      setIsPlaying(true)
    }
  }

  // Stop playback
  const stopPlayback = () => {
    Tone.Transport.stop()
    if (sequencerRef.current) {
      sequencerRef.current.dispose()
      sequencerRef.current = null
    }
    setIsPlaying(false)
    setCurrentStep(-1)
  }

  // Save project
  const saveProject = async () => {
    if (!user) return

    try {
      const projectData = {
        user_id: user.id,
        title: projectName,
        bpm,
        project_data: {
          tracks: tracks.map(track => ({
            ...track,
            sample: track.sample ? { id: track.sample.id, name: track.sample.name } : null
          }))
        },
        used_packs: [], // TODO: Track which packs samples came from
        is_public: false
      }

      const { error } = await supabase
        .from('projects')
        .insert([projectData])

      if (error) throw error
      alert('Project saved!')
    } catch (error) {
      console.error('Error saving project:', error)
      alert('Error saving project')
    }
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Studio</h1>
        <p className="text-gray-400">Create beats with drag & drop simplicity</p>
      </div>

      {/* Transport Controls */}
      <div className="bg-jade-dark rounded-lg p-4 pixel-border mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <button
              onClick={togglePlayback}
              className="p-3 bg-jade-purple hover:bg-purple-700 rounded-full transition-colors"
            >
              {isPlaying ? <Pause size={24} /> : <Play size={24} />}
            </button>
            
            <button
              onClick={stopPlayback}
              className="p-3 bg-gray-700 hover:bg-gray-600 rounded-full transition-colors"
            >
              <Stop size={24} />
            </button>
            
            <div className="flex items-center space-x-2">
              <label className="text-sm">BPM:</label>
              <input
                type="number"
                value={bpm}
                onChange={(e) => setBpm(Number(e.target.value))}
                min="60"
                max="200"
                className="w-16 px-2 py-1 bg-jade-darker border border-gray-700 rounded text-center"
              />
            </div>
          </div>
          
          <div className="flex items-center space-x-4">
            <input
              type="text"
              value={projectName}
              onChange={(e) => setProjectName(e.target.value)}
              className="px-3 py-1 bg-jade-darker border border-gray-700 rounded focus:border-jade-purple focus:outline-none"
            />
            
            <button
              onClick={saveProject}
              disabled={!user}
              className="flex items-center space-x-2 px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed rounded transition-colors"
            >
              <Save size={16} />
              <span>Save</span>
            </button>
          </div>
        </div>
      </div>

      {/* Sequencer */}
      <div className="bg-jade-dark rounded-lg p-6 pixel-border">
        <div className="space-y-4">
          {tracks.map((track) => (
            <div key={track.id} className="flex items-center space-x-4">
              {/* Track Info */}
              <div className="w-32 flex items-center space-x-2">
                <input
                  type="text"
                  value={track.name}
                  onChange={(e) => {
                    setTracks(prev => prev.map(t => 
                      t.id === track.id ? { ...t, name: e.target.value } : t
                    ))
                  }}
                  className="flex-1 px-2 py-1 bg-jade-darker border border-gray-700 rounded text-sm"
                />
                <button
                  onClick={() => removeTrack(track.id)}
                  className="p-1 text-red-400 hover:text-red-300"
                >
                  <Trash2 size={16} />
                </button>
              </div>
              
              {/* Sample Drop Zone */}
              <div
                onDrop={(e) => handleSampleDrop(e, track.id)}
                onDragOver={(e) => e.preventDefault()}
                className="w-32 px-3 py-1 bg-jade-darker border border-dashed border-gray-600 rounded text-xs text-center"
              >
                {track.sample ? track.sample.name : 'Drop sample'}
              </div>
              
              {/* Pattern Grid */}
              <div className="flex-1 flex space-x-1">
                {track.pattern.map((active, stepIndex) => (
                  <button
                    key={stepIndex}
                    onClick={() => toggleStep(track.id, stepIndex)}
                    className={`
                      flex-1 h-10 rounded transition-all
                      ${active 
                        ? 'bg-jade-purple hover:bg-purple-600' 
                        : 'bg-jade-darker hover:bg-gray-700'
                      }
                      ${currentStep === stepIndex ? 'scale-110 ring-2 ring-white' : ''}
                      ${stepIndex % 4 === 0 ? 'border-l-2 border-gray-600' : ''}
                    `}
                  />
                ))}
              </div>
              
              {/* Volume */}
              <div className="w-24">
                <input
                  type="range"
                  min="-20"
                  max="0"
                  value={track.volume}
                  onChange={(e) => {
                    const volume = Number(e.target.value)
                    setTracks(prev => prev.map(t => 
                      t.id === track.id ? { ...t, volume } : t
                    ))
                    if (playersRef.current[track.id]) {
                      playersRef.current[track.id].volume.value = volume
                    }
                  }}
                  className="w-full"
                />
              </div>
            </div>
          ))}
        </div>
        
        {/* Add Track Button */}
        <button
          onClick={addTrack}
          className="mt-4 flex items-center space-x-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors"
        >
          <Plus size={16} />
          <span>Add Track</span>
        </button>
      </div>

      {/* Instructions */}
      <div className="mt-8 text-center text-sm text-gray-400">
        <p>🎵 Drag samples from your packs onto tracks</p>
        <p>⬜ Click grid squares to create patterns</p>
        <p>▶️ Press play to hear your beat</p>
      </div>
    </div>
  )
}

export default Studio