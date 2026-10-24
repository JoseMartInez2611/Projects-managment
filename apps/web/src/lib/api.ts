import { createApiClient } from '@subproyecto/api-client'

// Mismo origen: Vite (dev) y nginx (prod) proxean /api al backend.
export const api = createApiClient()
