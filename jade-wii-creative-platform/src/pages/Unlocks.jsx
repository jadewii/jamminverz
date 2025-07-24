import { useState, useEffect } from 'react'
import { Trophy, Lock, Unlock, Sparkles } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { useAuthStore } from '../stores/authStore'

const Unlocks = () => {
  const { user } = useAuthStore()
  const [unlockables, setUnlockables] = useState([])
  const [userUnlocks, setUserUnlocks] = useState([])
  const [loading, setLoading] = useState(true)

  const categories = [
    { id: 'themes', label: 'Themes', icon: '🎨' },
    { id: 'stickers', label: 'Stickers', icon: '🌟' },
    { id: 'visualizers', label: 'Visualizers', icon: '🌊' },
  ]

  useEffect(() => {
    fetchUnlockables()
  }, [user])

  const fetchUnlockables = async () => {
    if (!user) return

    try {
      // Fetch all unlockables
      const { data: unlockablesData } = await supabase
        .from('unlockables')
        .select('*')
        .order('type')

      // Fetch user's unlocks
      const { data: userUnlocksData } = await supabase
        .from('user_unlocks')
        .select('unlockable_id')
        .eq('user_id', user.id)

      setUnlockables(unlockablesData || [])
      setUserUnlocks(userUnlocksData?.map(u => u.unlockable_id) || [])
    } catch (error) {
      console.error('Error fetching unlockables:', error)
    } finally {
      setLoading(false)
    }
  }

  const getProgress = (condition) => {
    // This would check actual user stats
    return Math.floor(Math.random() * 100)
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Unlocks</h1>
        <p className="text-gray-400">Earn rewards by creating and sharing</p>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-jade-dark rounded-lg p-4 pixel-border text-center">
          <p className="text-2xl font-bold text-jade-purple">0</p>
          <p className="text-sm text-gray-400">Packs Created</p>
        </div>
        <div className="bg-jade-dark rounded-lg p-4 pixel-border text-center">
          <p className="text-2xl font-bold text-jade-purple">0</p>
          <p className="text-sm text-gray-400">Projects Made</p>
        </div>
        <div className="bg-jade-dark rounded-lg p-4 pixel-border text-center">
          <p className="text-2xl font-bold text-jade-purple">0</p>
          <p className="text-sm text-gray-400">Collabs</p>
        </div>
        <div className="bg-jade-dark rounded-lg p-4 pixel-border text-center">
          <p className="text-2xl font-bold text-jade-purple">0%</p>
          <p className="text-sm text-gray-400">Unlocked</p>
        </div>
      </div>

      {/* Unlockables by Category */}
      {categories.map(category => (
        <div key={category.id} className="mb-8">
          <h2 className="text-xl font-bold mb-4 flex items-center space-x-2">
            <span>{category.icon}</span>
            <span>{category.label}</span>
          </h2>
          
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {/* Mock unlockables */}
            {[1, 2, 3, 4].map(i => (
              <UnlockCard
                key={`${category.id}-${i}`}
                unlockable={{
                  id: `${category.id}-${i}`,
                  name: `${category.label} ${i}`,
                  description: `Unlock by completing milestone`,
                  type: category.id,
                  unlock_condition: { type: 'packs_shared', count: i * 3 }
                }}
                isUnlocked={i === 1}
                progress={i === 2 ? 60 : 0}
              />
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}

const UnlockCard = ({ unlockable, isUnlocked, progress }) => {
  return (
    <div className={`
      bg-jade-dark rounded-lg p-4 pixel-border transition-all
      ${isUnlocked ? 'ring-2 ring-jade-purple' : 'opacity-75'}
    `}>
      <div className="aspect-square bg-jade-darker rounded mb-3 flex items-center justify-center">
        {isUnlocked ? (
          <Unlock className="text-jade-purple" size={32} />
        ) : (
          <Lock className="text-gray-600" size={32} />
        )}
      </div>
      
      <h3 className="font-bold text-sm mb-1">{unlockable.name}</h3>
      <p className="text-xs text-gray-400 mb-2">{unlockable.description}</p>
      
      {!isUnlocked && progress > 0 && (
        <div className="w-full bg-jade-darker rounded-full h-2">
          <div 
            className="bg-jade-purple h-2 rounded-full transition-all"
            style={{ width: `${progress}%` }}
          />
        </div>
      )}
      
      {isUnlocked && (
        <div className="flex items-center justify-center text-xs text-jade-purple">
          <Sparkles size={12} className="mr-1" />
          Unlocked
        </div>
      )}
    </div>
  )
}

export default Unlocks