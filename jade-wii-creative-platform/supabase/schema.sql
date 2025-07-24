-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  banner_url TEXT,
  profile_song_id UUID,
  theme_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Visual themes for profiles
CREATE TABLE public.visual_themes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  primary_color TEXT NOT NULL,
  secondary_color TEXT NOT NULL,
  background_color TEXT NOT NULL,
  font_family TEXT,
  custom_css TEXT,
  is_premium BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sample packs
CREATE TABLE public.sample_packs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  artwork_url TEXT,
  tags TEXT[],
  samples JSONB NOT NULL, -- Array of sample metadata
  is_public BOOLEAN DEFAULT true,
  download_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Projects (from Studio)
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  bpm INTEGER DEFAULT 120,
  project_data JSONB NOT NULL, -- Stores loops, patterns, etc
  used_packs UUID[], -- Array of pack IDs used
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Albums
CREATE TABLE public.albums (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  cover_art_url TEXT,
  mood_tags TEXT[],
  tracks JSONB NOT NULL, -- Array of track metadata
  is_public BOOLEAN DEFAULT true,
  play_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Collabs
CREATE TABLE public.collabs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID,
  album_id UUID,
  pack_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT check_single_reference CHECK (
    (project_id IS NOT NULL)::int +
    (album_id IS NOT NULL)::int +
    (pack_id IS NOT NULL)::int = 1
  )
);

-- Collab participants
CREATE TABLE public.collab_participants (
  collab_id UUID REFERENCES public.collabs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT, -- 'creator', 'contributor', etc
  PRIMARY KEY (collab_id, user_id)
);

-- Unlockables
CREATE TABLE public.unlockables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL, -- 'theme', 'sticker', 'visualizer'
  name TEXT NOT NULL,
  description TEXT,
  asset_url TEXT,
  unlock_condition JSONB, -- e.g., {"type": "packs_shared", "count": 3}
  is_premium BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User unlocks
CREATE TABLE public.user_unlocks (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  unlockable_id UUID REFERENCES public.unlockables(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, unlockable_id)
);

-- Friends
CREATE TABLE public.friends (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  friend_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, friend_id)
);

-- Store items (only admin can create)
CREATE TABLE public.store_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL, -- 'sample_pack', 'album', 'theme', 'cover_art'
  title TEXT NOT NULL,
  description TEXT,
  price_cents INTEGER NOT NULL,
  preview_url TEXT,
  asset_url TEXT, -- Actual downloadable content
  metadata JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Purchases
CREATE TABLE public.purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  store_item_id UUID REFERENCES public.store_items(id),
  stripe_payment_intent_id TEXT,
  amount_cents INTEGER NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shared packs (when users share packs with specific friends)
CREATE TABLE public.shared_packs (
  pack_id UUID REFERENCES public.sample_packs(id) ON DELETE CASCADE,
  shared_with_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  shared_by_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (pack_id, shared_with_user_id)
);

-- Favorites
CREATE TABLE public.favorites (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  pack_id UUID REFERENCES public.sample_packs(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, pack_id)
);

-- Create indexes for performance
CREATE INDEX idx_sample_packs_user_id ON public.sample_packs(user_id);
CREATE INDEX idx_projects_user_id ON public.projects(user_id);
CREATE INDEX idx_albums_user_id ON public.albums(user_id);
CREATE INDEX idx_friends_user_id ON public.friends(user_id);
CREATE INDEX idx_friends_friend_id ON public.friends(friend_id);
CREATE INDEX idx_store_items_type ON public.store_items(type);
CREATE INDEX idx_purchases_user_id ON public.purchases(user_id);

-- Row Level Security policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sample_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.albums ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unlockables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_unlocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;

-- Users can view all profiles but only edit their own
CREATE POLICY "Users can view all profiles" ON public.users
  FOR SELECT USING (true);
  
CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Sample packs policies
CREATE POLICY "Public packs are viewable by all" ON public.sample_packs
  FOR SELECT USING (is_public = true OR user_id = auth.uid());
  
CREATE POLICY "Users can create own packs" ON public.sample_packs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
  
CREATE POLICY "Users can update own packs" ON public.sample_packs
  FOR UPDATE USING (auth.uid() = user_id);

-- Similar policies for other tables...

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  
CREATE TRIGGER update_sample_packs_updated_at BEFORE UPDATE ON public.sample_packs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  
CREATE TRIGGER update_albums_updated_at BEFORE UPDATE ON public.albums
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();