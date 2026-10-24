import createClient from 'openapi-fetch'

import type { paths } from './schema'

export type { components, paths } from './schema'

export const createApiClient = (baseUrl = '') => createClient<paths>({ baseUrl })
