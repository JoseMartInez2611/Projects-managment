import { createTheme } from '@mui/material/styles'

export const theme = createTheme({
  cssVariables: { colorSchemeSelector: 'media' },
  colorSchemes: { light: true, dark: true },
})
