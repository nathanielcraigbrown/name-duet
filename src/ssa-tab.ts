import { supabase } from './lib/supabase'

type SsaName = {
  id: number
  display_name: string
  ssa_rank: number | null
}

let namesCache: SsaName[] | null = null
let loadingPromise: Promise<SsaName[]> | null = null

async function loadNames() {
  if (namesCache) return namesCache
  if (loadingPromise) return loadingPromise

  loadingPromise = (async () => {
    const { data, error } = await supabase
      .from('names')
      .select('id, display_name, ssa_rank')

    if (error) throw error

    const sorted = ((data ?? []) as SsaName[]).sort((a, b) => {
      const aRanked = Number.isFinite(a.ssa_rank)
      const bRanked = Number.isFinite(b.ssa_rank)

      if (aRanked && bRanked) {
        const rankDifference = (a.ssa_rank as number) - (b.ssa_rank as number)
        return rankDifference || a.display_name.localeCompare(b.display_name)
      }
      if (aRanked) return -1
      if (bRanked) return 1
      return a.display_name.localeCompare(b.display_name)
    })

    namesCache = sorted
    return sorted
  })()

  try {
    return await loadingPromise
  } finally {
    loadingPromise = null
  }
}

function createPanel() {
  const panel = document.createElement('section')
  panel.className = 'rankingPanel ssaPanel'
  panel.dataset.ssaPanel = 'true'
  panel.innerHTML = `
    <div class="rankingHeader">
      <div>
        <span class="kicker">Popularity reference</span>
        <h2>SSA rankings</h2>
      </div>
      <span class="counter">Loading…</span>
    </div>
    <p class="rankingStatus">Current database names ordered by SSA popularity. Unranked names appear alphabetically at the end.</p>
    <div class="ssaList" aria-live="polite"><p class="emptyState">Loading names…</p></div>
  `
  return panel
}

async function renderPanel(panel: HTMLElement) {
  const list = panel.querySelector<HTMLElement>('.ssaList')
  const counter = panel.querySelector<HTMLElement>('.counter')
  if (!list || !counter) return

  try {
    const names = await loadNames()
    counter.textContent = `${names.length} names`
    list.innerHTML = ''

    names.forEach((name) => {
      const row = document.createElement('article')
      row.className = 'ssaRow'

      const rank = document.createElement('span')
      rank.className = `ssaRank${name.ssa_rank == null ? ' isUnranked' : ''}`
      rank.textContent = name.ssa_rank == null ? 'N/A' : `#${name.ssa_rank}`

      const displayName = document.createElement('strong')
      displayName.textContent = name.display_name

      row.append(rank, displayName)
      list.append(row)
    })
  } catch (error) {
    counter.textContent = 'Unavailable'
    list.innerHTML = `<p class="formError">${error instanceof Error ? error.message : 'Could not load SSA rankings.'}</p>`
  }
}

function activateSsaView(button: HTMLButtonElement, workspace: HTMLElement) {
  workspace.querySelectorAll<HTMLElement>('.comparisonStage, .rankingPanel').forEach((element) => {
    element.hidden = true
  })
  workspace.querySelectorAll<HTMLButtonElement>('.viewTabs button').forEach((tab) => tab.classList.remove('active'))
  button.classList.add('active')

  let panel = workspace.querySelector<HTMLElement>('[data-ssa-panel="true"]')
  if (!panel) {
    panel = createPanel()
    workspace.append(panel)
    void renderPanel(panel)
  }
  panel.hidden = false
}

function installSsaTab() {
  const workspace = document.querySelector<HTMLElement>('.workspace')
  const tabs = workspace?.querySelector<HTMLElement>('.viewTabs')
  if (!workspace || !tabs || tabs.querySelector('[data-ssa-tab="true"]')) return

  const button = document.createElement('button')
  button.type = 'button'
  button.dataset.ssaTab = 'true'
  button.innerHTML = '<span class="ssaTabIcon" aria-hidden="true">#</span> SSA list'
  button.addEventListener('click', () => activateSsaView(button, workspace))

  tabs.append(button)

  tabs.querySelectorAll<HTMLButtonElement>('button:not([data-ssa-tab="true"])').forEach((tab) => {
    tab.addEventListener('click', () => {
      workspace.querySelector<HTMLElement>('[data-ssa-panel="true"]')?.setAttribute('hidden', '')
      button.classList.remove('active')
    })
  })
}

const observer = new MutationObserver(() => installSsaTab())
observer.observe(document.body, { childList: true, subtree: true })
installSsaTab()
