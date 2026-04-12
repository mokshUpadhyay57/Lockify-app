import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url));

// https://vite.dev/config/
export default defineConfig(({mode}) => ({
  plugins: [react()],
  build: {
    minify: "terser",
    terserOptions: {
      compress: {
        drop_console: mode === "production" ? true : false,
      },
    },
    rollupOptions: {
      input: {
        main: resolve(__dirname, "index.html"),
        lockedMessages: resolve(__dirname, "lockedMessages.html"),
      },
      output: {
        entryFileNames: "[name].js",
        chunkFileNames: "[name].js",
        assetFileNames: "[name].[ext]",
      },
    },
    cssCodeSplit: true,
    sourcemap: false,
    target: "esnext",
  },
}));
