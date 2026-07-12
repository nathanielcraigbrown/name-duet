import { supabase } from './lib/supabase'

type Matchup = {
  opponent_name: string
  wins: number
  losses: number
  total: number
  opponent_score: number
}

type NameStats = {
  display_name: string
  ssa_rank: number | null
  origin: string | null
  meaning: string | null
  display_rank: number
  total_ranked: number
  preference_score: number
  wins: number
  losses: number
  comparisons: number
  win_rate: number
  best_win: string | null
  nemesis: string | null
  most_beaten: string | null
  matchups: Matchup[]
}

type ParticipantTogetherStats = {
  participant_id: number
  participant_name: string
  display_rank: number | null
  preference_score: number
  wins: number
  losses: number
  comparisons: number
  win_rate: number
  matchups: Matchup[]
}

type TogetherStats = {
  display_name: string
  ssa_rank: number | null
  origin: string | null
  meaning: string | null
  participants: ParticipantTogetherStats[]
  combined: {
    wins: number
    losses: number
    comparisons: number
    win_rate: number
    agreement_count: number
    disagreement_count: number
    matchups: Matchup[]
  }
}

function getParticipantToken() {
  try {
    const saved = localStorage.getItem('name-duet-session')
    if (!saved) return null
    return JSON.parse(saved)?.participantToken as string | null
  } catch {
    return null
  }
}

function scoreLabel(score: number) {
  return score > 0 ? `+${score}` : `${score}`
}

function escapeHtml(value: string | null | undefined) {
  return (value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
}

function renderMatchups(matchups: Matchup[], showOpponentScore = true) {
  return matchups.length
    ? matchups.map((matchup) => `
      <div class="nameMatchupRow">
        <div>
          <strong>${escapeHtml(matchup.opponent_name)}</strong>
          ${showOpponentScore ? `<span>${scoreLabel(matchup.opponent_score)} preference</span>` : ''}
        </div>
        <div class="nameMatchupRecord">
          <b>${matchup.wins}–${matchup.losses}</b>
          <span>${matchup.total} ${matchup.total === 1 ? 'meeting' : 'meetings'}</span>
        </div>
      </div>
    `).join('')
    : '<p class="nameStatsEmpty">No head-to-head history yet.</p>'
}

function renderStats(panel: HTMLElement, stats: NameStats) {
  panel.innerHTML = `
    <div class="nameStatsTopline">
      <div>
        <span class="kicker">Name deep dive</span>
        <h3>${escapeHtml(stats.display_name)}</h3>
        <p>${stats.ssa_rank ? `SSA #${stats.ssa_rank}` : 'SSA N/A'}${stats.origin ? ` · ${escapeHtml(stats.origin)}` : ''}${stats.meaning ? ` ◆ ${escapeHtml(stats.meaning)}` : ''}</p>
      </div>
      <button class="nameStatsClose" type="button" aria-label="Close name details">×</button>
    </div>

    <div class="nameStatsGrid">
      <div><strong>#${stats.display_rank}</strong><span>Your rank</span></div>
      <div><strong>${scoreLabel(stats.preference_score)}</strong><span>Preference</span></div>
      <div><strong>${stats.win_rate}%</strong><span>Win rate</span></div>
      <div><strong>${stats.wins}–${stats.losses}</strong><span>Record</span></div>
    </div>

    <div class="nameStatsHighlights">
      <div><span>Best win</span><strong>${escapeHtml(stats.best_win) || '—'}</strong></div>
      <div><span>Nemesis</span><strong>${escapeHtml(stats.nemesis) || '—'}</strong></div>
      <div><span>Most beaten</span><strong>${escapeHtml(stats.most_beaten) || '—'}</strong></div>
    </div>

    <div class="nameMatchups">
      <div class="nameMatchupsHeader">
        <h4>Head-to-head record</h4>
        <span>${stats.comparisons} total matchups</span>
      </div>
      ${renderMatchups(stats.matchups)}
    </div>
  `

  panel.querySelector<HTMLButtonElement>('.nameStatsClose')?.addEventListener('click', () => panel.remove())
}

function renderTogetherBody(container: HTMLElement, stats: TogetherStats, key: string) {
  if (key === 'combined') {
    const combined = stats.combined
    const sharedDecisions = combined.agreement_count + combined.disagreement_count
    const agreementRate = sharedDecisions > 0 ? Math.round((combined.agreement_count / sharedDecisions) * 100) : 0
    container.innerHTML = `
      <div class="nameStatsGrid togetherStatsGrid">
        <div><strong>${combined.win_rate}%</strong><span>Combined win rate</span></div>
        <div><strong>${combined.wins}–${combined.losses}</strong><span>Combined record</span></div>
        <div><strong>${agreementRate}%</strong><span>Agreement rate</span></div>
        <div><strong>${combined.disagreement_count}</strong><span>Split opponents</span></div>
      </div>
      <div class="nameStatsHighlights togetherHighlights">
        <div><span>Shared decisions</span><strong>${sharedDecisions}</strong></div>
        <div><span>Agreed opponents</span><strong>${combined.agreement_count}</strong></div>
        <div><span>Total matchups</span><strong>${combined.comparisons}</strong></div>
      </div>
      <div class="nameMatchups">
        <div class="nameMatchupsHeader"><h4>Combined head-to-head</h4><span>Both people together</span></div>
        ${renderMatchups(combined.matchups, false)}
      </div>
    `
    return
  }

  const participant = stats.participants.find((item) => String(item.participant_id) === key)
  if (!participant) return
  container.innerHTML = `
    <div class="nameStatsGrid togetherStatsGrid">
      <div><strong>${participant.display_rank ? `#${participant.display_rank}` : '—'}</strong><span>${escapeHtml(participant.participant_name)} rank</span></div>
      <div><strong>${scoreLabel(participant.preference_score)}</strong><span>Preference</span></div>
      <div><strong>${participant.win_rate}%</strong><span>Win rate</span></div>
      <div><strong>${participant.wins}–${participant.losses}</strong><span>Record</span></div>
    </div>
    <div class="nameMatchups">
      <div class="nameMatchupsHeader"><h4>${escapeHtml(participant.participant_name)} head-to-head</h4><span>${participant.comparisons} total matchups</span></div>
      ${renderMatchups(participant.matchups)}
    </div>
  `
}

function renderTogetherStats(panel: HTMLElement, stats: TogetherStats) {
  const tabs = [
    '<button type="button" class="togetherDetailTab active" data-detail-key="combined">Combined</button>',
    ...stats.participants.map((participant) => `<button type="button" class="togetherDetailTab" data-detail-key="${participant.participant_id}">${escapeHtml(participant.participant_name)}</button>`),
  ].join('')

  panel.innerHTML = `
    <div class="nameStatsTopline">
      <div>
        <span class="kicker">Together deep dive</span>
        <h3>${escapeHtml(stats.display_name)}</h3>
        <p>${stats.ssa_rank ? `SSA #${stats.ssa_rank}` : 'SSA N/A'}${stats.origin ? ` · ${escapeHtml(stats.origin)}` : ''}${stats.meaning ? ` ◆ ${escapeHtml(stats.meaning)}` : ''}</p>
      </div>
      <button class="nameStatsClose" type="button" aria-label="Close name details">×</button>
    </div>
    <div class="togetherDetailTabs" role="tablist">${tabs}</div>
    <div class="togetherDetailBody"></div>
  `

  const body = panel.querySelector<HTMLElement>('.togetherDetailBody')
  if (body) renderTogetherBody(body, stats, 'combined')

  panel.querySelectorAll<HTMLButtonElement>('.togetherDetailTab').forEach((button) => {
    button.addEventListener('click', () => {
      panel.querySelectorAll('.togetherDetailTab').forEach((tab) => tab.classList.remove('active'))
      button.classList.add('active')
      if (body) renderTogetherBody(body, stats, button.dataset.detailKey ?? 'combined')
    })
  })
  panel.querySelector<HTMLButtonElement>('.nameStatsClose')?.addEventListener('click', () => panel.remove())
}

async function openNameDetails(row: HTMLElement, displayName: string) {
  const existing = row.nextElementSibling as HTMLElement | null
  if (existing?.classList.contains('nameStatsPanel')) {
    existing.remove()
    return
  }

  document.querySelectorAll('.nameStatsPanel').forEach((panel) => panel.remove())

  const panel = document.createElement('section')
  panel.className = 'nameStatsPanel'
  panel.innerHTML = '<p class="nameStatsLoading">Loading name stats…</p>'
  row.insertAdjacentElement('afterend', panel)

  const participantToken = getParticipantToken()
  if (!participantToken) {
    panel.innerHTML = '<p class="formError">Your private session could not be found.</p>'
    return
  }

  const isTogether = row.classList.contains('consensusRow')
  const rpcName = isTogether ? 'get_together_name_detail_stats' : 'get_name_detail_stats'
  const { data, error } = await supabase.rpc(rpcName, {
    p_access_token: participantToken,
    p_display_name: displayName,
  })

  if (error) {
    panel.innerHTML = `<p class="formError">${escapeHtml(error.message)}</p>`
    return
  }

  if (isTogether) renderTogetherStats(panel, data as TogetherStats)
  else renderStats(panel, data as NameStats)
}

function enhanceRows() {
  document.querySelectorAll<HTMLElement>('.rankingRow, .consensusRow').forEach((row) => {
    if (row.dataset.nameDetailsReady === 'true') return

    const nameElement = row.querySelector<HTMLElement>('.rankingMain strong, .consensusName strong')
    if (!nameElement) return

    row.dataset.nameDetailsReady = 'true'
    row.classList.add('nameDetailsTrigger')
    row.setAttribute('role', 'button')
    row.setAttribute('tabindex', '0')
    row.setAttribute('aria-label', `View details for ${nameElement.textContent?.trim() ?? 'this name'}`)

    const open = () => {
      const displayName = nameElement.textContent?.trim()
      if (displayName) void openNameDetails(row, displayName)
    }

    row.addEventListener('click', open)
    row.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault()
        open()
      }
    })
  })
}

let scheduled = false
function scheduleEnhancement() {
  if (scheduled) return
  scheduled = true
  requestAnimationFrame(() => {
    scheduled = false
    enhanceRows()
  })
}

const observer = new MutationObserver(scheduleEnhancement)
observer.observe(document.body, { childList: true, subtree: true })
scheduleEnhancement()
