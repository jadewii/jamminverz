import { Link, useLocation } from 'react-router-dom'
import { 
  User, 
  Package, 
  Wand2, 
  Disc3, 
  Music4, 
  Users, 
  Trophy, 
  UserPlus, 
  ShoppingCart,
  LogOut
} from 'lucide-react'
import { useAuthStore } from '../stores/authStore'

const Navigation = () => {
  const location = useLocation()
  const { profile, signOut } = useAuthStore()
  
  const tabs = [
    { path: '/profile', label: 'Profile', icon: User },
    { path: '/packs', label: 'Sample Packs', icon: Package },
    { path: '/create', label: 'Create', icon: Wand2 },
    { path: '/albums', label: 'Albums', icon: Disc3 },
    { path: '/studio', label: 'Studio', icon: Music4 },
    { path: '/collabs', label: 'Collabs', icon: Users },
    { path: '/unlocks', label: 'Unlocks', icon: Trophy },
    { path: '/friends', label: 'Friends', icon: UserPlus },
    { path: '/store', label: 'Store', icon: ShoppingCart },
  ]
  
  const isActive = (path) => {
    if (path === '/profile' && location.pathname.startsWith('/profile')) return true
    return location.pathname === path
  }
  
  return (
    <nav className="fixed top-0 left-0 right-0 bg-jade-darker border-b border-gray-800 z-50">
      <div className="flex items-center justify-between px-4 h-16">
        <div className="flex items-center space-x-1">
          {/* Logo */}
          <Link to="/" className="flex items-center space-x-2 px-4">
            <span className="font-pixel text-jade-purple text-sm glow-purple">JAde Wii</span>
          </Link>
          
          {/* Tab Navigation */}
          <div className="flex space-x-0">
            {tabs.map((tab) => {
              const Icon = tab.icon
              return (
                <Link
                  key={tab.path}
                  to={tab.path}
                  className={`tab-button flex items-center space-x-2 ${
                    isActive(tab.path) ? 'active' : ''
                  }`}
                >
                  <Icon size={16} />
                  <span className="text-sm hidden lg:inline">{tab.label}</span>
                </Link>
              )
            })}
          </div>
        </div>
        
        {/* User Menu */}
        <div className="flex items-center space-x-4">
          {profile && (
            <div className="flex items-center space-x-2 text-sm">
              <img 
                src={profile.avatar_url || `https://api.dicebear.com/7.x/pixel-art/svg?seed=${profile.username}`} 
                alt={profile.username}
                className="w-8 h-8 rounded pixel-border"
              />
              <span className="hidden md:inline">{profile.display_name || profile.username}</span>
            </div>
          )}
          <button
            onClick={signOut}
            className="p-2 hover:bg-jade-dark rounded transition-colors"
            title="Sign Out"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </nav>
  )
}

export default Navigation