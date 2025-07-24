# JAde Wii Creative Platform

A full-stack creative platform for music producers with no social media clutter. Tab-based interface with deep customization, official content marketplace, and community features.

## Features

### 🎯 Core Principles
- **No infinite scrolling** - Static tabbed layout
- **Profile-centric** - Your profile is the core experience
- **Curated marketplace** - Only JAde Wii sells premium content
- **Free community sharing** - Users create and share sample packs for free

### 📱 Main Sections

#### Profile
- Customizable avatar, banner, bio, profile song
- Theme customization (colors, fonts, backgrounds)
- Tabbed content: Albums, Sample Packs, Collabs, Projects
- Friend system

#### Sample Packs
- Create, share, and discover sample packs
- 4x4 preview grid for each pack
- Drag & drop to Studio
- Auto-licensing for remix/non-commercial use

#### Create (Pack Generator)
- Generate 16 random sounds instantly
- Play sounds on drum pads
- Export as zip or save to profile
- One-click pack creation

#### Studio
- Basic loop-based beat builder
- Drag & drop samples from packs
- Simple pattern sequencer
- Save projects and export audio

#### Albums
- Create albums from projects
- Custom cover art and mood tags
- Profile autoplay feature
- Track credits system

#### Collabs
- Joint projects with friends
- Auto-credit system
- "Featured On" section

#### Unlocks
- Gamified achievements
- Unlock themes, stickers, visualizers
- Milestone-based progression

#### Store (JAde Wii Marketplace)
- Official sample packs
- Albums and cover art
- Visual themes
- Stripe payment integration

## Tech Stack

- **Frontend**: React + Vite + Tailwind CSS
- **Audio**: Tone.js
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Payments**: Stripe
- **Icons**: Lucide React
- **State**: Zustand

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up Supabase:
   - Create a new Supabase project
   - Run the schema from `supabase/schema.sql`
   - Enable Authentication
   - Create storage buckets: `avatars`, `samples`, `covers`

4. Configure environment variables:
   ```bash
   cp .env.example .env
   ```
   Fill in your Supabase and Stripe credentials

5. Run the development server:
   ```bash
   npm run dev
   ```

## Database Schema

- **users** - Extended user profiles
- **sample_packs** - User-created sample packs
- **projects** - Studio projects
- **albums** - Music albums
- **collabs** - Collaboration records
- **unlockables** - Achievement system
- **store_items** - Marketplace products
- **friends** - Social connections

## Design System

- **Colors**: Purple (#9333ea) and Pink (#ec4899) gradients
- **Font**: Space Mono (main), Press Start 2P (accents)
- **Style**: Pixel-art inspired, GameBoy-like UI
- **Layout**: Tab-driven, no scrolling feeds

## Deployment

1. Build for production:
   ```bash
   npm run build
   ```

2. Deploy to your hosting service (Vercel, Netlify, etc.)

3. Set up environment variables on your hosting platform

4. Configure Supabase Row Level Security policies

5. Set up Stripe webhooks for payment processing

## License

All rights reserved. This is proprietary software for JAde Wii creative platform.