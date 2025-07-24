import { useState } from 'react'
import { Play, Pause } from 'lucide-react'
import * as Tone from 'tone'

const PackGrid = ({ samples = [], editable = false, onSampleChange }) => {
  const [playing, setPlaying] = useState({})
  const [players, setPlayers] = useState({})

  // Initialize 4x4 grid (16 pads)
  const pads = Array(16).fill(null).map((_, i) => samples[i] || null)

  const handlePadClick = async (index) => {
    const sample = pads[index]
    if (!sample) return

    if (playing[index]) {
      // Stop playing
      if (players[index]) {
        players[index].stop()
        setPlaying(prev => ({ ...prev, [index]: false }))
      }
    } else {
      // Start playing
      try {
        await Tone.start()
        
        if (!players[index]) {
          const player = new Tone.Player(sample.url).toDestination()
          await player.load(sample.url)
          setPlayers(prev => ({ ...prev, [index]: player }))
          player.start()
        } else {
          players[index].start()
        }
        
        setPlaying(prev => ({ ...prev, [index]: true }))
        
        // Auto-stop after sample ends
        setTimeout(() => {
          setPlaying(prev => ({ ...prev, [index]: false }))
        }, sample.duration * 1000 || 2000)
      } catch (error) {
        console.error('Error playing sample:', error)
      }
    }
  }

  const handleDrop = (e, index) => {
    e.preventDefault()
    if (!editable || !onSampleChange) return

    const data = e.dataTransfer.getData('sample')
    if (data) {
      const sample = JSON.parse(data)
      onSampleChange(index, sample)
    }
  }

  const handleDragOver = (e) => {
    e.preventDefault()
  }

  return (
    <div className="grid grid-cols-4 gap-2">
      {pads.map((sample, index) => (
        <button
          key={index}
          onClick={() => handlePadClick(index)}
          onDrop={(e) => handleDrop(e, index)}
          onDragOver={handleDragOver}
          className={`
            aspect-square rounded-lg p-4 transition-all relative
            ${sample 
              ? 'bg-gradient-to-br from-jade-purple/20 to-jade-pink/20 hover:from-jade-purple/30 hover:to-jade-pink/30 border border-jade-purple/50' 
              : 'bg-jade-darker border border-gray-700 hover:border-gray-600'
            }
            ${playing[index] ? 'scale-95 animate-pulse' : ''}
            ${editable && !sample ? 'border-dashed' : ''}
          `}
        >
          {sample ? (
            <>
              <div className="absolute inset-0 flex items-center justify-center">
                {playing[index] ? (
                  <Pause size={24} className="text-white" />
                ) : (
                  <Play size={24} className="text-white" />
                )}
              </div>
              <div className="absolute bottom-2 left-2 right-2">
                <p className="text-xs text-white truncate">{sample.name}</p>
              </div>
            </>
          ) : (
            <div className="flex items-center justify-center h-full">
              <span className="text-xs text-gray-500">
                {editable ? 'Drop' : 'Empty'}
              </span>
            </div>
          )}
        </button>
      ))}
    </div>
  )
}

export default PackGrid