import RefreshIcon from '@mui/icons-material/Refresh'
import Alert from '@mui/material/Alert'
import Button from '@mui/material/Button'
import Card from '@mui/material/Card'
import CardActions from '@mui/material/CardActions'
import CardContent from '@mui/material/CardContent'
import Chip from '@mui/material/Chip'
import CircularProgress from '@mui/material/CircularProgress'
import Stack from '@mui/material/Stack'
import Typography from '@mui/material/Typography'
import { useQuery } from '@tanstack/react-query'

import { api } from '../lib/api'

export function Home() {
  const { data, error, isPending, isFetching, refetch } = useQuery({
    queryKey: ['health'],
    queryFn: async () => {
      const { data, error } = await api.GET('/api/v1/health')
      if (data) return data
      if (error) return error
      throw new Error('Respuesta vacía de la API')
    },
    retry: false,
  })

  return (
    <Card>
      <CardContent>
        <Typography variant="h5" component="h2" gutterBottom>
          Estado de la API
        </Typography>
        {isPending && <CircularProgress size={24} aria-label="Cargando" />}
        {error && <Alert severity="error">No se pudo contactar la API: {error.message}</Alert>}
        {data && (
          <Stack direction="row" spacing={1}>
            <Chip
              label={`API: ${data.status}`}
              color={data.status === 'ok' ? 'success' : 'warning'}
            />
            <Chip label={`DB: ${data.db}`} color={data.db === 'ok' ? 'success' : 'error'} />
          </Stack>
        )}
      </CardContent>
      <CardActions>
        <Button startIcon={<RefreshIcon />} onClick={() => refetch()} disabled={isFetching}>
          Reintentar
        </Button>
      </CardActions>
    </Card>
  )
}
