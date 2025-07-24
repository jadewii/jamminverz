import { useState, useEffect } from 'react'
import { UserPlus, Search, Check, X } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { useAuthStore } from '../stores/authStore'

const Friends = () => {
  const { user } = useAuthStore()
  const [friends, setFriends] = useState([])
  const [pendingRequests, setPendingRequests] = useState([])
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user) {
      fetchFriends()
    }
  }, [user])

  const fetchFriends = async () => {
    try {
      // Fetch accepted friends
      const { data: friendsData } = await supabase
        .from('friends')
        .select(`
          friend:friend_id(id, username, display_name, avatar_url)
        `)
        .eq('user_id', user.id)
        .eq('status', 'accepted')

      // Fetch pending requests
      const { data: pendingData } = await supabase
        .from('friends')
        .select(`
          user:user_id(id, username, display_name, avatar_url)
        `)
        .eq('friend_id', user.id)
        .eq('status', 'pending')

      setFriends(friendsData?.map(f => f.friend) || [])
      setPendingRequests(pendingData?.map(p => p.user) || [])
    } catch (error) {
      console.error('Error fetching friends:', error)
    } finally {
      setLoading(false)
    }
  }

  const searchUsers = async () => {
    if (!searchQuery.trim()) return

    try {
      const { data } = await supabase
        .from('users')
        .select('id, username, display_name, avatar_url')
        .ilike('username', `%${searchQuery}%`)
        .neq('id', user.id)
        .limit(10)

      setSearchResults(data || [])
    } catch (error) {
      console.error('Error searching users:', error)
    }
  }

  const sendFriendRequest = async (friendId) => {
    try {
      const { error } = await supabase
        .from('friends')
        .insert([
          { user_id: user.id, friend_id: friendId, status: 'pending' }
        ])

      if (!error) {
        setSearchResults(prev => prev.filter(u => u.id !== friendId))
      }
    } catch (error) {
      console.error('Error sending friend request:', error)
    }
  }

  const handleRequest = async (requesterId, accept) => {
    try {
      if (accept) {
        // Update existing request to accepted
        await supabase
          .from('friends')
          .update({ status: 'accepted' })
          .eq('user_id', requesterId)
          .eq('friend_id', user.id)

        // Create reverse friendship
        await supabase
          .from('friends')
          .insert([
            { user_id: user.id, friend_id: requesterId, status: 'accepted' }
          ])
      } else {
        // Delete the request
        await supabase
          .from('friends')
          .delete()
          .eq('user_id', requesterId)
          .eq('friend_id', user.id)
      }

      fetchFriends()
    } catch (error) {
      console.error('Error handling request:', error)
    }
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Friends</h1>
        <p className="text-gray-400">Connect with other producers</p>
      </div>

      {/* Search */}
      <div className="bg-jade-dark rounded-lg p-6 pixel-border mb-8">
        <h2 className="text-xl font-bold mb-4">Find Friends</h2>
        <div className="flex space-x-2">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && searchUsers()}
            placeholder="Search by username..."
            className="flex-1 px-4 py-2 bg-jade-darker border border-gray-700 rounded focus:border-jade-purple focus:outline-none"
          />
          <button
            onClick={searchUsers}
            className="px-4 py-2 bg-jade-purple hover:bg-purple-700 rounded transition-colors"
          >
            <Search size={20} />
          </button>
        </div>

        {searchResults.length > 0 && (
          <div className="mt-4 space-y-2">
            {searchResults.map(user => (
              <div key={user.id} className="flex items-center justify-between p-3 bg-jade-darker rounded">
                <div className="flex items-center space-x-3">
                  <img
                    src={user.avatar_url || `https://api.dicebear.com/7.x/pixel-art/svg?seed=${user.username}`}
                    alt={user.username}
                    className="w-10 h-10 rounded"
                  />
                  <div>
                    <p className="font-medium">{user.display_name || user.username}</p>
                    <p className="text-sm text-gray-400">@{user.username}</p>
                  </div>
                </div>
                <button
                  onClick={() => sendFriendRequest(user.id)}
                  className="p-2 bg-jade-purple hover:bg-purple-700 rounded transition-colors"
                >
                  <UserPlus size={16} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Pending Requests */}
      {pendingRequests.length > 0 && (
        <div className="bg-jade-dark rounded-lg p-6 pixel-border mb-8">
          <h2 className="text-xl font-bold mb-4">Friend Requests</h2>
          <div className="space-y-2">
            {pendingRequests.map(request => (
              <div key={request.id} className="flex items-center justify-between p-3 bg-jade-darker rounded">
                <div className="flex items-center space-x-3">
                  <img
                    src={request.avatar_url || `https://api.dicebear.com/7.x/pixel-art/svg?seed=${request.username}`}
                    alt={request.username}
                    className="w-10 h-10 rounded"
                  />
                  <div>
                    <p className="font-medium">{request.display_name || request.username}</p>
                    <p className="text-sm text-gray-400">@{request.username}</p>
                  </div>
                </div>
                <div className="flex space-x-2">
                  <button
                    onClick={() => handleRequest(request.id, true)}
                    className="p-2 bg-green-600 hover:bg-green-700 rounded transition-colors"
                  >
                    <Check size={16} />
                  </button>
                  <button
                    onClick={() => handleRequest(request.id, false)}
                    className="p-2 bg-red-600 hover:bg-red-700 rounded transition-colors"
                  >
                    <X size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Friends List */}
      <div className="bg-jade-dark rounded-lg p-6 pixel-border">
        <h2 className="text-xl font-bold mb-4">Your Friends ({friends.length})</h2>
        {friends.length === 0 ? (
          <p className="text-gray-400 text-center py-8">
            No friends yet. Search for users to connect!
          </p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {friends.map(friend => (
              <div key={friend.id} className="flex items-center space-x-3 p-3 bg-jade-darker rounded">
                <img
                  src={friend.avatar_url || `https://api.dicebear.com/7.x/pixel-art/svg?seed=${friend.username}`}
                  alt={friend.username}
                  className="w-12 h-12 rounded"
                />
                <div>
                  <p className="font-medium">{friend.display_name || friend.username}</p>
                  <p className="text-sm text-gray-400">@{friend.username}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default Friends