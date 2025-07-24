import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import { Camera, Edit2, Music, Palette, Save, X } from 'lucide-react'
import { supabase, uploadFile } from '../lib/supabase'
import { useAuthStore } from '../stores/authStore'

const Profile = () => {
  const { username } = useParams()
  const { user, profile: currentUserProfile, updateProfile } = useAuthStore()
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)
  const [isEditing, setIsEditing] = useState(false)
  const [activeTab, setActiveTab] = useState('albums')
  const [editForm, setEditForm] = useState({
    display_name: '',
    bio: '',
    avatar_url: '',
    banner_url: '',
  })

  const isOwnProfile = !username || (currentUserProfile?.username === username)

  useEffect(() => {
    fetchProfile()
  }, [username])

  const fetchProfile = async () => {
    try {
      let query = supabase.from('users').select('*')
      
      if (username) {
        query = query.eq('username', username)
      } else if (user) {
        query = query.eq('id', user.id)
      }

      const { data, error } = await query.single()
      
      if (error) throw error
      
      setProfile(data)
      if (isOwnProfile) {
        setEditForm({
          display_name: data.display_name || '',
          bio: data.bio || '',
          avatar_url: data.avatar_url || '',
          banner_url: data.banner_url || '',
        })
      }
    } catch (error) {
      console.error('Error fetching profile:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleFileUpload = async (file, type) => {
    if (!file || !user) return

    try {
      const fileExt = file.name.split('.').pop()
      const fileName = `${user.id}/${type}_${Date.now()}.${fileExt}`
      
      const publicUrl = await uploadFile('avatars', fileName, file)
      
      setEditForm(prev => ({
        ...prev,
        [`${type}_url`]: publicUrl
      }))
    } catch (error) {
      console.error('Error uploading file:', error)
    }
  }

  const handleSave = async () => {
    if (!user) return

    try {
      await updateProfile(editForm)
      setProfile({ ...profile, ...editForm })
      setIsEditing(false)
    } catch (error) {
      console.error('Error updating profile:', error)
    }
  }

  const tabs = [
    { id: 'albums', label: 'Albums' },
    { id: 'packs', label: 'Sample Packs' },
    { id: 'collabs', label: 'Collabs' },
    { id: 'projects', label: 'Projects' },
  ]

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-jade-purple font-pixel animate-pulse">LOADING PROFILE...</div>
      </div>
    )
  }

  if (!profile) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-red-500">Profile not found</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen">
      {/* Banner */}
      <div className="relative h-64 bg-gradient-to-b from-jade-purple/20 to-transparent">
        {profile.banner_url && (
          <img 
            src={profile.banner_url} 
            alt="Banner" 
            className="absolute inset-0 w-full h-full object-cover"
          />
        )}
        {isEditing && (
          <label className="absolute top-4 right-4 cursor-pointer">
            <input
              type="file"
              accept="image/*"
              onChange={(e) => handleFileUpload(e.target.files[0], 'banner')}
              className="hidden"
            />
            <div className="bg-jade-dark/80 p-2 rounded hover:bg-jade-dark transition-colors">
              <Camera size={20} />
            </div>
          </label>
        )}
      </div>

      {/* Profile Info */}
      <div className="max-w-6xl mx-auto px-4 -mt-20 relative">
        <div className="bg-jade-dark rounded-lg p-6 pixel-border">
          <div className="flex items-start justify-between">
            <div className="flex items-start space-x-6">
              {/* Avatar */}
              <div className="relative">
                <img
                  src={profile.avatar_url || `https://api.dicebear.com/7.x/pixel-art/svg?seed=${profile.username}`}
                  alt={profile.username}
                  className="w-32 h-32 rounded-lg pixel-border"
                />
                {isEditing && (
                  <label className="absolute bottom-2 right-2 cursor-pointer">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={(e) => handleFileUpload(e.target.files[0], 'avatar')}
                      className="hidden"
                    />
                    <div className="bg-jade-dark/80 p-1 rounded hover:bg-jade-dark transition-colors">
                      <Camera size={16} />
                    </div>
                  </label>
                )}
              </div>

              {/* Info */}
              <div className="flex-1">
                {isEditing ? (
                  <input
                    type="text"
                    value={editForm.display_name}
                    onChange={(e) => setEditForm({ ...editForm, display_name: e.target.value })}
                    className="text-2xl font-bold bg-transparent border-b border-gray-700 focus:border-jade-purple outline-none mb-2"
                    placeholder="Display Name"
                  />
                ) : (
                  <h1 className="text-2xl font-bold mb-2">
                    {profile.display_name || profile.username}
                  </h1>
                )}
                
                <p className="text-gray-400 mb-4">@{profile.username}</p>
                
                {isEditing ? (
                  <textarea
                    value={editForm.bio}
                    onChange={(e) => setEditForm({ ...editForm, bio: e.target.value })}
                    className="w-full bg-jade-darker rounded p-2 border border-gray-700 focus:border-jade-purple outline-none resize-none"
                    rows={3}
                    placeholder="Tell us about yourself..."
                  />
                ) : (
                  profile.bio && <p className="text-gray-300">{profile.bio}</p>
                )}
              </div>
            </div>

            {/* Actions */}
            {isOwnProfile && (
              <div className="flex space-x-2">
                {isEditing ? (
                  <>
                    <button
                      onClick={handleSave}
                      className="flex items-center space-x-2 px-4 py-2 bg-jade-purple hover:bg-purple-700 rounded transition-colors"
                    >
                      <Save size={16} />
                      <span>Save</span>
                    </button>
                    <button
                      onClick={() => {
                        setIsEditing(false)
                        setEditForm({
                          display_name: profile.display_name || '',
                          bio: profile.bio || '',
                          avatar_url: profile.avatar_url || '',
                          banner_url: profile.banner_url || '',
                        })
                      }}
                      className="p-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors"
                    >
                      <X size={16} />
                    </button>
                  </>
                ) : (
                  <button
                    onClick={() => setIsEditing(true)}
                    className="flex items-center space-x-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded transition-colors"
                  >
                    <Edit2 size={16} />
                    <span>Edit Profile</span>
                  </button>
                )}
              </div>
            )}
          </div>

          {/* Profile Tabs */}
          <div className="mt-8">
            <div className="flex space-x-1 border-b border-gray-700">
              {tabs.map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`px-4 py-2 font-medium transition-colors ${
                    activeTab === tab.id
                      ? 'text-jade-purple border-b-2 border-jade-purple'
                      : 'text-gray-400 hover:text-white'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Tab Content */}
            <div className="mt-6">
              {activeTab === 'albums' && <ProfileAlbums userId={profile.id} />}
              {activeTab === 'packs' && <ProfilePacks userId={profile.id} />}
              {activeTab === 'collabs' && <ProfileCollabs userId={profile.id} />}
              {activeTab === 'projects' && <ProfileProjects userId={profile.id} />}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// Sub-components for profile tabs
const ProfileAlbums = ({ userId }) => {
  return (
    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      <div className="bg-jade-darker rounded-lg p-4 text-center">
        <div className="w-full h-32 bg-gray-800 rounded mb-2"></div>
        <p className="text-sm text-gray-400">No albums yet</p>
      </div>
    </div>
  )
}

const ProfilePacks = ({ userId }) => {
  return (
    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      <div className="bg-jade-darker rounded-lg p-4 text-center">
        <div className="w-full h-32 bg-gray-800 rounded mb-2"></div>
        <p className="text-sm text-gray-400">No sample packs yet</p>
      </div>
    </div>
  )
}

const ProfileCollabs = ({ userId }) => {
  return (
    <div className="text-center py-8">
      <p className="text-gray-400">No collaborations yet</p>
    </div>
  )
}

const ProfileProjects = ({ userId }) => {
  return (
    <div className="text-center py-8">
      <p className="text-gray-400">No projects yet</p>
    </div>
  )
}

export default Profile