import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import './styles.css'
import './workspace.css'
import './app.css'
import './card-overrides.css'
import './ssa-tab.css'
import './ssa-tab'
import './progress-targets'
import './name-details.css'
import './name-details'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
