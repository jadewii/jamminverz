import { useState, useEffect } from 'react'
import { Plus, Download, Heart, Share2, Play } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { useAuthStore } from '../stores/authStore'
import PackGrid from '../components/PackGrid'

const SamplePacks = () => {
  const { user } = useAuthStore()
  const [activeTab, setActiveTab] = useState('my-packs')
  const [packs, setPacks] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedPack, setSelectedPack] = useState(null)

  const tabs = [
    { id: 'my-packs', label: 'My Packs' },
    { id: 'create', label: 'Create Pack' },
    { id: 'shared', label: 'Shared With Me' },
    { id: 'favorites', label: 'Favorites' },
  ]

  useEffect(() => {
    fetchPacks()
  }, [activeTab, user])

  const fetchPacks = async () => {
    if (!user) return

    setLoading(true)
    try {
      let query = supabase.from('sample_packs').select('*')

      switch (activeTab) {
        case 'my-packs':
          query = query.eq('user_id', user.id)
          break
        case 'shared':
          // TODO: Implement shared packs query
          break
        case 'favorites':
          // TODO: Implement favorites query
          break
      }

      const { data, error } = await query.order('created_at', { ascending: false })
      
      if (error) throw error
      setPacks(data || [])
    } catch (error) {
      console.error('Error fetching packs:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleAddToCollection = async (packId) => {
    // TODO: Implement add to collection
    console.log('Add to collection:', packId)
  }

  const handleFavorite = async (packId) => {
    if (!user) return

    try {
      const { error } = await supabase
        .from('favorites')
        .insert([{ user_id: user.id, pack_id: packId }])
      
      if (error) throw error
      // Update UI accordingly
    } catch (error) {
      console.error('Error favoriting pack:', error)
    }
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Sample Packs</h1>
        <p className="text-gray-400">Create, share, and discover sample packs</p>
      </div>

      {/* Tabs */}
      <div className="flex space-x-1 border-b border-gray-700 mb-6">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-6 py-3 font-medium transition-colors ${
              activeTab === tab.id
                ? 'text-jade-purple border-b-2 border-jade-purple'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="min-h-[400px]">
        {activeTab === 'create' ? (
          <CreatePackView />
        ) : (
          <>
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="text-jade-purple font-pixel animate-pulse">
                  LOADING PACKS...
                </div>
              </div>
            ) : packs.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-gray-400 mb-4">No packs found</p>
                {activeTab === 'my-packs' && (
                  <button
                    onClick={() => setActiveTab('create')}
                    className="px-6 py-3 bg-jade-purple hover:bg-purple-700 rounded font-bold transition-colors"
                  >
                    Create Your First Pack
                  </button>
                )}
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {packs.map((pack) => (
                  <PackCard
                    key={pack.id}
                    pack={pack}
                    onSelect={() => setSelectedPack(pack)}
                    onFavorite={() => handleFavorite(pack.id)}
                    onAddToCollection={() => handleAddToCollection(pack.id)}
                  />
                ))}
              </div>
            )}
          </>
        )}
      </div>

      {/* Pack Preview Modal */}
      {selectedPack && (
        <PackPreviewModal
          pack={selectedPack}
          onClose={() => setSelectedPack(null)}
        />
      )}
    </div>
  )
}

// Pack Card Component
const PackCard = ({ pack, onSelect, onFavorite, onAddToCollection }) => {
  return (
    <div className="bg-jade-dark rounded-lg overflow-hidden pixel-border hover:scale-105 transition-transform">
      <div 
        className="relative cursor-pointer"
        onClick={onSelect}
      >
        {pack.artwork_url ? (
          <img 
            src={pack.artwork_url} 
            alt={pack.title}
            className="w-full h-48 object-cover"
          />
        ) : (
          <div className="w-full h-48 bg-gradient-to-br from-jade-purple to-jade-pink flex items-center justify-center">
            <span className="font-pixel text-2xl">PACK</span>
          </div>
        )}
        <div className="absolute top-2 right-2 flex space-x-2">
          <button
            onClick={(e) => {
              e.stopPropagation()
              onFavorite()
            }}
            className="p-2 bg-jade-dark/80 rounded hover:bg-jade-dark transition-colors"
          >
            <Heart size={16} />
          </button>
        </div>
      </div>
      
      <div className="p-4">
        <h3 className="font-bold mb-1">{pack.title}</h3>
        <div className="flex flex-wrap gap-1 mb-3">
          {pack.tags?.slice(0, 3).map((tag, i) => (
            <span key={i} className="text-xs px-2 py-1 bg-jade-darker rounded">
              {tag}
            </span>
          ))}
        </div>
        
        <div className="flex items-center justify-between text-sm text-gray-400">
          <span>{pack.samples?.length || 0} samples</span>
          <span>{pack.download_count || 0} downloads</span>
        </div>
        
        <div className="mt-3 flex space-x-2">
          <button
            onClick={onAddToCollection}
            className="flex-1 py-2 bg-jade-purple hover:bg-purple-700 rounded text-sm font-medium transition-colors"
          >
            Add to Collection
          </button>
          <button
            className="p-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors"
          >
            <Download size={16} />
          </button>
        </div>
      </div>
    </div>
  )
}

// Create Pack View
const CreatePackView = () => {
  const [packData, setPackData] = useState({
    title: '',
    description: '',
    tags: [],
    samples: []
  })

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-jade-dark rounded-lg p-6 pixel-border">
        <h2 className="text-xl font-bold mb-6">Create New Sample Pack</h2>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm mb-2">Pack Title</label>
            <input
              type="text"
              value={packData.title}
              onChange={(e) => setPackData({ ...packData, title: e.target.value })}
              className="w-full px-4 py-2 bg-jade-darker border border-gray-700 rounded focus:border-jade-purple focus:outline-none"
              placeholder="My Awesome Pack"
            />
          </div>
          
          <div>
            <label className="block text-sm mb-2">Description</label>
            <textarea
              value={packData.description}
              onChange={(e) => setPackData({ ...packData, description: e.target.value })}
              className="w-full px-4 py-2 bg-jade-darker border border-gray-700 rounded focus:border-jade-purple focus:outline-none resize-none"
              rows={3}
              placeholder="Describe your pack..."
            />
          </div>
          
          <div>
            <label className="block text-sm mb-2">Upload Samples</label>
            <div className="border-2 border-dashed border-gray-700 rounded-lg p-8 text-center">
              <input
                type="file"
                multiple
                accept="audio/*"
                className="hidden"
                id="sample-upload"
              />
              <label htmlFor="sample-upload" className="cursor-pointer">
                <Plus className="mx-auto mb-2" size={32} />
                <p className="text-gray-400">Click to upload samples</p>
                <p className="text-xs text-gray-500 mt-1">WAV, MP3, FLAC supported</p>
              </label>
            </div>
          </div>
          
          {packData.samples.length > 0 && (
            <div>
              <h3 className="text-sm font-medium mb-2">Uploaded Samples ({packData.samples.length})</h3>
              <div className="space-y-1">
                {packData.samples.map((sample, i) => (
                  <div key={i} className="flex items-center justify-between p-2 bg-jade-darker rounded">
                    <span className="text-sm">{sample.name}</span>
                    <button className="text-red-400 hover:text-red-300">
                      <X size={16} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
          
          <button className="w-full py-3 bg-jade-purple hover:bg-purple-700 rounded font-bold transition-colors">
            Create Pack
          </button>
        </div>
      </div>
    </div>
  )
}

// Pack Preview Modal
const PackPreviewModal = ({ pack, onClose }) => {
  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50">
      <div className="bg-jade-dark rounded-lg max-w-4xl w-full max-h-[80vh] overflow-y-auto pixel-border">
        <div className="sticky top-0 bg-jade-dark border-b border-gray-700 p-4 flex items-center justify-between">
          <h2 className="text-xl font-bold">{pack.title}</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-jade-darker rounded transition-colors"
          >
            <X size={20} />
          </button>
        </div>
        
        <div className="p-6">
          <PackGrid samples={pack.samples || []} />
        </div>
      </div>
    </div>
  )
}

export default SamplePacks