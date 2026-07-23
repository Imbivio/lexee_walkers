/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Google Maps JavaScript API key. Optional — without it the app falls
      back to the built-in stylized map. See .env.example. */
  readonly VITE_GOOGLE_MAPS_API_KEY?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
