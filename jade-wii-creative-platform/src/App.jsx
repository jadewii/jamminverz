import { useState, useEffect } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import Navigation from './components/Navigation'
import Profile from './pages/Profile'
import SamplePacks from './pages/SamplePacks'
import Create from './pages/Create'
import Albums from './pages/Albums'
import Studio from './pages/Studio'
import Collabs from './pages/Collabs'
import Unlocks from './pages/Unlocks'
import Friends from './pages/Friends'
import Store from './pages/Store'
import Auth from './pages/Auth'
import { supabase } from './lib/supabase'
import { useAuthStore } from './stores/authStore'
import './App.css'

function App() {
  const { user, setUser, loading, setLoading } = useAuthStore()

  useEffect(() => {
    // Check active sessions and sets the user
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null)
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
    })

    return () => subscription.unsubscribe()
  }, [setUser, setLoading])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-jade-purple font-pixel text-xl animate-pulse">
          LOADING...
        </div>
      </div>
    )
  }

  return (
    <Router>
      <div className="min-h-screen bg-jade-darker">
        {user ? (
          <>
            <Navigation />
            <main className="pt-16">
              <Routes>
                <Route path="/" element={<Navigate to="/profile" replace />} />
                <Route path="/profile/:username?" element={<Profile />} />
                <Route path="/packs" element={<SamplePacks />} />
                <Route path="/create" element={<Create />} />
                <Route path="/albums" element={<Albums />} />
                <Route path="/studio" element={<Studio />} />
                <Route path="/collabs" element={<Collabs />} />
                <Route path="/unlocks" element={<Unlocks />} />
                <Route path="/friends" element={<Friends />} />
                <Route path="/store" element={<Store />} />
              </Routes>
            </main>
          </>
        ) : (
          <Routes>
            <Route path="*" element={<Auth />} />
          </Routes>
        )}
      </div>
    </Router>
  )
}

export default App