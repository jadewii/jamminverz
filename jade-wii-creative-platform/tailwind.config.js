/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'jade-purple': '#9333ea',
        'jade-pink': '#ec4899',
        'jade-dark': '#1a1a1a',
        'jade-darker': '#0f0f0f',
      },
      fontFamily: {
        'pixel': ['Press Start 2P', 'monospace'],
        'mono': ['Space Mono', 'monospace'],
      },
      animation: {
        'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-slow': 'bounce 3s infinite',
      }
    },
  },
  plugins: [],
}