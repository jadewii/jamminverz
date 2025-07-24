import { create } from 'zustand'
import { supabase } from '../lib/supabase'

export const useAuthStore = create((set, get) => ({
  user: null,
  profile: null,
  loading: true,
  
  setUser: (user) => set({ user }),
  setProfile: (profile) => set({ profile }),
  setLoading: (loading) => set({ loading }),
  
  fetchProfile: async () => {
    const { user } = get()
    if (!user) return
    
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single()
    
    if (data) {
      set({ profile: data })
    }
    
    return { data, error }
  },
  
  updateProfile: async (updates) => {
    const { user } = get()
    if (!user) return
    
    const { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', user.id)
      .select()
      .single()
    
    if (data) {
      set({ profile: data })
    }
    
    return { data, error }
  },
  
  signOut: async () => {
    const { error } = await supabase.auth.signOut()
    if (!error) {
      set({ user: null, profile: null })
    }
    return { error }
  }
}))