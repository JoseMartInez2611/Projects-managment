import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { api } from '../lib/api'
import { Home } from './Home'

vi.mock('../lib/api', () => ({ api: { GET: vi.fn() } }))

const get = vi.mocked(api.GET)

function renderHome() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  render(
    <QueryClientProvider client={client}>
      <Home />
    </QueryClientProvider>,
  )
}

describe('Home', () => {
  beforeEach(() => {
    get.mockReset()
  })

  it('muestra API y DB en ok', async () => {
    get.mockResolvedValue({ data: { status: 'ok', db: 'ok' } } as never)
    renderHome()
    expect(await screen.findByText('API: ok')).toBeInTheDocument()
    expect(screen.getByText('DB: ok')).toBeInTheDocument()
  })

  it('muestra DB caída cuando la API responde 503', async () => {
    get.mockResolvedValue({ error: { status: 'degraded', db: 'down' } } as never)
    renderHome()
    expect(await screen.findByText('API: degraded')).toBeInTheDocument()
    expect(screen.getByText('DB: down')).toBeInTheDocument()
  })

  it('muestra error si la API no responde', async () => {
    get.mockRejectedValue(new Error('fetch failed'))
    renderHome()
    expect(await screen.findByText(/No se pudo contactar la API: fetch failed/)).toBeInTheDocument()
  })
})
