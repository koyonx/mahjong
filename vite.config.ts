import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/ws': {
        target: 'ws://localhost:8080',
        ws: true,
      },
    },
  },
  optimizeDeps: {
    // Melange出力のJSファイルをpre-bundleに含める
    include: ['./src/generated/**/*.js'],
    esbuildOptions: {
      // esbuildがMelangeのJSを正しく処理できるように
      target: 'es2020',
    },
  },
})
