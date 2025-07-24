import { useState } from 'react'
import { Users, Plus } from 'lucide-react'

const Collabs = () => {
  const [collabs, setCollabs] = useState([])

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Collaborations</h1>
        <p className="text-gray-400">Work together with friends on albums, packs, and projects</p>
      </div>

      {collabs.length === 0 ? (
        <div className="bg-jade-dark rounded-lg p-12 pixel-border text-center">
          <Users className="mx-auto mb-4 text-gray-600" size={48} />
          <h2 className="text-xl font-bold mb-2">No Collaborations Yet</h2>
          <p className="text-gray-400 mb-6">
            Start collaborating by inviting friends to work on projects together
          </p>
          <button className="px-6 py-3 bg-jade-purple hover:bg-purple-700 rounded font-bold transition-colors">
            <Plus className="inline mr-2" size={16} />
            Start a Collaboration
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Collab cards would go here */}
        </div>
      )}

      {/* Featured Collabs Section */}
      <div className="mt-12">
        <h2 className="text-2xl font-bold mb-6">Featured On</h2>
        <div className="bg-jade-dark rounded-lg p-6 pixel-border">
          <p className="text-gray-400 text-center">
            Projects where you've been credited will appear here
          </p>
        </div>
      </div>
    </div>
  )
}

export default Collabs