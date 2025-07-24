import { useState } from 'react'
import { Plus, Play, Heart } from 'lucide-react'

const Albums = () => {
  const [activeTab, setActiveTab] = useState('my-albums')
  
  const tabs = [
    { id: 'my-albums', label: 'My Albums' },
    { id: 'create-album', label: 'Create Album' },
    { id: 'favorites', label: 'Favorite Albums' },
  ]

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Albums</h1>
        <p className="text-gray-400">Create albums from your projects and share your music</p>
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
        {activeTab === 'create-album' ? (
          <CreateAlbumView />
        ) : (
          <div className="text-center py-12">
            <p className="text-gray-400 mb-4">No albums yet</p>
            <button
              onClick={() => setActiveTab('create-album')}
              className="px-6 py-3 bg-jade-purple hover:bg-purple-700 rounded font-bold transition-colors"
            >
              Create Your First Album
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

const CreateAlbumView = () => {
  const [albumData, setAlbumData] = useState({
    title: '',
    description: '',
    tracks: []
  })

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-jade-dark rounded-lg p-6 pixel-border">
        <h2 className="text-xl font-bold mb-6">Create New Album</h2>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm mb-2">Album Title</label>
            <input
              type="text"
              value={albumData.title}
              onChange={(e) => setAlbumData({ ...albumData, title: e.target.value })}
              className="w-full px-4 py-2 bg-jade-darker border border-gray-700 rounded focus:border-jade-purple focus:outline-none"
              placeholder="My Album"
            />
          </div>
          
          <div>
            <label className="block text-sm mb-2">Description</label>
            <textarea
              value={albumData.description}
              onChange={(e) => setAlbumData({ ...albumData, description: e.target.value })}
              className="w-full px-4 py-2 bg-jade-darker border border-gray-700 rounded focus:border-jade-purple focus:outline-none resize-none"
              rows={3}
              placeholder="Tell the story of your album..."
            />
          </div>
          
          <div>
            <label className="block text-sm mb-2">Album Cover</label>
            <div className="border-2 border-dashed border-gray-700 rounded-lg p-8 text-center">
              <Plus className="mx-auto mb-2" size={32} />
              <p className="text-gray-400">Upload cover art</p>
            </div>
          </div>
          
          <div>
            <label className="block text-sm mb-2">Add Tracks from Projects</label>
            <div className="space-y-2">
              <p className="text-sm text-gray-400">No projects available</p>
            </div>
          </div>
          
          <button className="w-full py-3 bg-jade-purple hover:bg-purple-700 rounded font-bold transition-colors">
            Create Album
          </button>
        </div>
      </div>
    </div>
  )
}

export default Albums