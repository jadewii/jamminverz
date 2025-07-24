import { useState, useEffect } from 'react'
import { ShoppingCart, Play, Download, Sparkles } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { useAuthStore } from '../stores/authStore'
import { loadStripe } from '@stripe/stripe-js'

// Initialize Stripe (use your publishable key)
const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY || '')

const Store = () => {
  const { user } = useAuthStore()
  const [activeCategory, setActiveCategory] = useState('all')
  const [storeItems, setStoreItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [purchases, setPurchases] = useState([])

  const categories = [
    { id: 'all', label: 'All Items', icon: '🛍️' },
    { id: 'sample_pack', label: 'Sample Packs', icon: '🎵' },
    { id: 'album', label: 'Albums', icon: '💿' },
    { id: 'theme', label: 'Themes', icon: '🎨' },
    { id: 'cover_art', label: 'Cover Art', icon: '🖼️' },
  ]

  useEffect(() => {
    fetchStoreItems()
    if (user) {
      fetchUserPurchases()
    }
  }, [activeCategory, user])

  const fetchStoreItems = async () => {
    try {
      let query = supabase.from('store_items').select('*').eq('is_active', true)
      
      if (activeCategory !== 'all') {
        query = query.eq('type', activeCategory)
      }

      const { data } = await query.order('created_at', { ascending: false })
      setStoreItems(data || [])
    } catch (error) {
      console.error('Error fetching store items:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchUserPurchases = async () => {
    try {
      const { data } = await supabase
        .from('purchases')
        .select('store_item_id')
        .eq('user_id', user.id)
        .eq('status', 'completed')

      setPurchases(data?.map(p => p.store_item_id) || [])
    } catch (error) {
      console.error('Error fetching purchases:', error)
    }
  }

  const handlePurchase = async (item) => {
    if (!user) {
      alert('Please sign in to make purchases')
      return
    }

    try {
      // Create checkout session (this would call your backend)
      const response = await fetch('/api/create-checkout-session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          item_id: item.id,
          user_id: user.id,
          price_cents: item.price_cents
        })
      })

      const { sessionId } = await response.json()
      
      // Redirect to Stripe Checkout
      const stripe = await stripePromise
      await stripe.redirectToCheckout({ sessionId })
    } catch (error) {
      console.error('Error creating checkout:', error)
      alert('Error processing payment')
    }
  }

  const isPurchased = (itemId) => purchases.includes(itemId)

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8 text-center">
        <h1 className="text-4xl font-pixel mb-2">
          <span className="glow-purple text-jade-purple">JAde Wii</span> Store
        </h1>
        <p className="text-gray-400">Official sample packs, themes, and exclusive content</p>
      </div>

      {/* Categories */}
      <div className="flex flex-wrap justify-center gap-2 mb-8">
        {categories.map(category => (
          <button
            key={category.id}
            onClick={() => setActiveCategory(category.id)}
            className={`
              px-4 py-2 rounded-full font-medium transition-all
              ${activeCategory === category.id
                ? 'bg-jade-purple text-white'
                : 'bg-jade-dark text-gray-400 hover:text-white'
              }
            `}
          >
            <span className="mr-2">{category.icon}</span>
            {category.label}
          </button>
        ))}
      </div>

      {/* Store Items */}
      {loading ? (
        <div className="text-center py-12">
          <div className="text-jade-purple font-pixel animate-pulse">
            LOADING STORE...
          </div>
        </div>
      ) : storeItems.length === 0 ? (
        <div className="text-center py-12">
          <p className="text-gray-400">No items available in this category</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {storeItems.map(item => (
            <StoreItemCard
              key={item.id}
              item={item}
              isPurchased={isPurchased(item.id)}
              onPurchase={() => handlePurchase(item)}
            />
          ))}
        </div>
      )}

      {/* Footer */}
      <div className="mt-16 text-center text-sm text-gray-400">
        <p>All content created and curated by JAde Wii</p>
        <p>Instant download after purchase • Lifetime access</p>
      </div>
    </div>
  )
}

const StoreItemCard = ({ item, isPurchased, onPurchase }) => {
  const formatPrice = (cents) => `$${(cents / 100).toFixed(2)}`
  
  const getItemIcon = (type) => {
    switch (type) {
      case 'sample_pack': return '🎵'
      case 'album': return '💿'
      case 'theme': return '🎨'
      case 'cover_art': return '🖼️'
      default: return '📦'
    }
  }

  return (
    <div className="bg-jade-dark rounded-lg overflow-hidden pixel-border hover:scale-105 transition-transform">
      {/* Preview */}
      <div className="relative h-48 bg-gradient-to-br from-jade-purple to-jade-pink flex items-center justify-center">
        <span className="text-6xl">{getItemIcon(item.type)}</span>
        {isPurchased && (
          <div className="absolute top-2 right-2 bg-green-600 text-white px-2 py-1 rounded text-xs font-bold">
            OWNED
          </div>
        )}
      </div>

      {/* Info */}
      <div className="p-4">
        <h3 className="font-bold text-lg mb-1">{item.title}</h3>
        <p className="text-sm text-gray-400 mb-3">{item.description}</p>
        
        {/* Metadata */}
        {item.metadata && (
          <div className="flex flex-wrap gap-2 mb-3 text-xs">
            {item.metadata.sample_count && (
              <span className="px-2 py-1 bg-jade-darker rounded">
                {item.metadata.sample_count} samples
              </span>
            )}
            {item.metadata.duration && (
              <span className="px-2 py-1 bg-jade-darker rounded">
                {item.metadata.duration}
              </span>
            )}
          </div>
        )}

        {/* Price & Action */}
        <div className="flex items-center justify-between">
          <span className="text-2xl font-bold text-jade-purple">
            {formatPrice(item.price_cents)}
          </span>
          
          {isPurchased ? (
            <button className="px-4 py-2 bg-green-600 rounded font-medium">
              <Download size={16} className="inline mr-1" />
              Download
            </button>
          ) : (
            <button
              onClick={onPurchase}
              className="px-4 py-2 bg-jade-purple hover:bg-purple-700 rounded font-medium transition-colors"
            >
              <ShoppingCart size={16} className="inline mr-1" />
              Buy Now
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

export default Store