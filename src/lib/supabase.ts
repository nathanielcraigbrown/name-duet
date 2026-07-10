import { createClient } from '@supabase/supabase-js'

const fallbackUrl = 'https://qobauughkvimlppuldc.supabase.co'
const fallbackKey = 'sb_publishable_nC3Uuhi-8ak5GwK9qwHAOA_6ll_vBxQ'

const configuredUrl = import.meta.env.VITE_SUPABASE_URL?.trim() || fallbackUrl
const supabaseUrl = configuredUrl
  .replace(/\/+$/, '')
  .replace(/\/rest\/v1$/i, '')

const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY?.trim() || fallbackKey

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
})
