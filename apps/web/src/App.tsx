import AppBar from '@mui/material/AppBar'
import Container from '@mui/material/Container'
import Toolbar from '@mui/material/Toolbar'
import Typography from '@mui/material/Typography'
import { Route, Routes } from 'react-router'

import { Home } from './pages/Home'

export default function App() {
  return (
    <>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="h1">
            SubProyecto
          </Typography>
        </Toolbar>
      </AppBar>
      <Container component="main" sx={{ py: 4 }}>
        <Routes>
          <Route path="/" element={<Home />} />
        </Routes>
      </Container>
    </>
  )
}
