import { FormEvent, useCallback, useEffect, useState } from 'react'
import { BarChart3, Copy, Heart, LogOut, Smartphone, Sparkles, Users } from 'lucide-react'
import { supabase } from './lib/supabase'

type Mode = 'create' | 'join' | null
type View = 'compare' | 'rankings' | 'consensus'

type RoomSession = { roomToken: string; participantToken: string; participantName: string }
type Pair = { left_id: number; left_name: string; right_id: number; right_name: string; comparison_count: number }
type Ranking = { rank_position: number; name_id: number; display_name: string; rating: number; wins: number; losses: number; comparisons: number }
type DisplayRanking = Ranking & { displayRank: number; roundedScore: number }
type ConsensusRow = {
  name_id: number
  display_name: string
  participant_one_name: string
  participant_two_name: string
  participant_one_rank: number | null
  participant_two_rank: number | null
  participant_one_comparisons: number
  participant_two_comparisons: number
  consensus_score: number
  rank_gap: number
}

type RankingTier = { label: string; description: string; rows: DisplayRanking[] }

function loadSavedSession(): RoomSession | null {
  try {
    const saved = localStorage.getItem('name-duet-session')
    return saved ? JSON.parse(saved) : null
  } catch {
    localStorage.removeItem('name-duet-session')
    return null
  }
}

function getMessage(caught: unknown, fallback: string) {
  if (caught instanceof Error) return caught.message
  if (caught && typeof caught === 'object' && 'message' in caught && typeof caught.message === 'string') return caught.message
  return fallback
}

function splitNameDetails(value: string) {
  const [displayName, ...detailParts] = value.split('\n')
  return { displayName, details: detailParts.join(' ').trim() }
}

function getStability(comparisons: number) {
  if (comparisons >= 8) return 'Stable'
  if (comparisons >= 4) return 'Settling'
  return 'Emerging'
}

function formatPreferenceScore(rating: number) {
  const score = Math.round(rating - 1500)
  return score > 0 ? `+${score}` : `${score}`
}

function getProgressLabel(comparisons: number) {
  if (comparisons >= 600) return 'Optimized result reached'
  if (comparisons >= 400) return 'Optimizing your shortlist'
  if (comparisons >= 250) return 'Shortlist taking shape'
  if (comparisons >= 150) return 'Favorites emerging'
  return 'Learning your taste'
}

function getProgressPercent(comparisons: number) {
  if (comparisons <= 400) return Math.min(75, Math.round((comparisons / 400) * 75))
  return Math.min(100, Math.round(75 + ((comparisons - 400) / 200) * 25))
}

function getDisplayRankings(rankings: Ranking[]): DisplayRanking[] {
  let displayRank = 0
  let previousScore: number | null = null

  return rankings.map((item) => {
    const roundedScore = Math.round(item.rating - 1500)
    if (previousScore === null || roundedScore !== previousScore) {
      displayRank += 1
      previousScore = roundedScore
    }
    return { ...item, displayRank, roundedScore }
  })
}

function getRankingTiers(rankings: DisplayRanking[]): RankingTier[] {
  return [
    { label: 'Favorites', description: 'Your strongest current signals', rows: rankings.filter((item) => item.displayRank <= 5) },
    { label: 'Strong contenders', description: 'Names still pressing the leaders', rows: rankings.filter((item) => item.displayRank >= 6 && item.displayRank <= 15) },
    { label: 'Still in play', description: 'Promising names that need more matchups', rows: rankings.filter((item) => item.displayRank >= 16 && item.displayRank <= 25) },
  ].filter((tier) => tier.rows.length)
}

export default function App() {
  const initialParams = new URLSearchParams(window.location.search)
  const [mode, setMode] = useState<Mode>(null)
  const [name, setName] = useState('')
  const [roomCode, setRoomCode] = useState(() => initialParams.get('room') ?? '')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [session, setSession] = useState<RoomSession | null>(loadSavedSession)
  const [view, setView] = useState<View>('compare')
  const [pair, setPair] = useState<Pair | null>(null)
  const [rankings, setRankings] = useState<Ranking[]>([])
  const [consensus, setConsensus] = useState<ConsensusRow[]>([])
  const [copied, setCopied] = useState(false)
  const [deviceCopied, setDeviceCopied] = useState(false)

  const openForm = (nextMode: Exclude<Mode, null>) => { setError(''); setMode(nextMode) }

  const loadRankings = useCallback(async (participantToken: string) => {
    const { data, error: rankingError } = await supabase.rpc('get_my_rankings', { p_access_token: participantToken, p_limit: 50 })
    if (rankingError) throw rankingError
    setRankings((data ?? []) as Ranking[])
  }, [])

  const loadConsensus = useCallback(async (participantToken: string) => {
    const { data, error: consensusError } = await supabase.rpc('get_room_consensus', { p_access_token: participantToken, p_limit: 20 })
    if (consensusError) throw consensusError
    setConsensus((data ?? []) as ConsensusRow[])
  }, [])

  const loadPair = useCallback(async (participantToken: string) => {
    setLoading(true); setError('')
    try {
      const { data, error: pairError } = await supabase.rpc('get_next_pair', { p_access_token: participantToken })
      if (pairError) throw pairError
      setPair((data?.[0] as Pair | undefined) ?? null)
    } catch (caught) {
      setError(getMessage(caught, 'Could not load the next pair.'))
    } finally { setLoading(false) }
  }, [])

  useEffect(() => {
    if (session) return
    const params = new URLSearchParams(window.location.search)
    const deviceCode = params.get('device')
    const restoreRoom = params.get('room')
    if (!deviceCode || !restoreRoom) return

    const restore = async () => {
      setLoading(true); setError('')
      try {
        const { data, error: restoreError } = await supabase.rpc('redeem_device_link', {
          p_room_token: restoreRoom,
          p_device_code: deviceCode,
        })
        if (restoreError) throw restoreError
        const result = data?.[0]
        if (!result) throw new Error('This device link is invalid or expired.')
        const restoredSession = {
          roomToken: result.room_token,
          participantToken: result.participant_token,
          participantName: result.participant_name,
        }
        localStorage.setItem('name-duet-session', JSON.stringify(restoredSession))
        window.history.replaceState({}, document.title, window.location.pathname)
        setSession(restoredSession)
      } catch (caught) {
        setError(getMessage(caught, 'This device link could not be opened.'))
        setMode('join')
      } finally { setLoading(false) }
    }

    void restore()
  }, [session])

  useEffect(() => {
    if (!session) return
    void loadPair(session.participantToken)
    void loadRankings(session.participantToken)
    void loadConsensus(session.participantToken).catch(() => undefined)
  }, [session, loadPair, loadRankings, loadConsensus])

  useEffect(() => {
    if (!session || view !== 'consensus') return
    const refresh = () => void loadConsensus(session.participantToken).catch(() => undefined)
    refresh()
    const timer = window.setInterval(refresh, 8000)
    return () => window.clearInterval(timer)
  }, [session, view, loadConsensus])

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault(); setError('')
    const participantName = name.trim()
    if (!participantName) return setError('Please enter your name.')
    if (mode === 'join' && !roomCode.trim()) return setError('Please enter the room code.')
    setLoading(true)
    try {
      const rpc = mode === 'create'
        ? supabase.rpc('create_room', { owner_name: participantName })
        : supabase.rpc('join_room', { join_token: roomCode.trim().toUpperCase(), participant_name: participantName })
      const { data, error: rpcError } = await rpc
      if (rpcError) throw rpcError
      const result = data?.[0]
      if (!result) throw new Error('Something went wrong creating your room.')
      const nextSession = { roomToken: result.room_token, participantToken: result.participant_token, participantName }
      localStorage.setItem('name-duet-session', JSON.stringify(nextSession))
      setSession(nextSession); setMode(null)
    } catch (caught) {
      const message = getMessage(caught, 'We could not reach Name Duet.')
      if (message.includes('Room not found')) setError('We could not find that room. Check the code and try again.')
      else if (message.includes('duplicate key')) setError(`${participantName} is already in this room. Ask them for their private device link.`)
      else setError(message)
    } finally { setLoading(false) }
  }

  const vote = async (winnerId: number) => {
    if (!session || !pair || loading) return
    setLoading(true); setError('')
    try {
      const { error: voteError } = await supabase.rpc('record_vote', {
        p_access_token: session.participantToken,
        p_left_id: pair.left_id,
        p_right_id: pair.right_id,
        p_winner_id: winnerId,
      })
      if (voteError) throw voteError
      await Promise.all([loadPair(session.participantToken), loadRankings(session.participantToken)])
    } catch (caught) {
      setError(getMessage(caught, 'Your choice could not be saved.'))
      setLoading(false)
    }
  }

  const copyInvite = async () => {
    if (!session) return
    await navigator.clipboard.writeText(`${window.location.origin}/?room=${session.roomToken}`)
    setCopied(true); window.setTimeout(() => setCopied(false), 1800)
  }

  const copyDeviceLink = async () => {
    if (!session) return
    setError('')
    try {
      const { data, error: linkError } = await supabase.rpc('create_device_link', {
        p_access_token: session.participantToken,
      })
      if (linkError) throw linkError
      const code = data?.[0]?.device_code
      if (!code) throw new Error('Could not create a device link.')
      await navigator.clipboard.writeText(`${window.location.origin}/?room=${session.roomToken}&device=${code}`)
      setDeviceCopied(true); window.setTimeout(() => setDeviceCopied(false), 2200)
    } catch (caught) {
      setError(getMessage(caught, 'Could not create a device link.'))
    }
  }

  const leaveRoom = () => {
    localStorage.removeItem('name-duet-session')
    setSession(null); setPair(null); setRankings([]); setConsensus([]); setView('compare')
  }

  if (session) {
    const one = consensus[0]?.participant_one_name
    const two = consensus[0]?.participant_two_name
    const left = pair ? splitNameDetails(pair.left_name) : null
    const right = pair ? splitNameDetails(pair.right_name) : null
    const comparisonCount = pair?.comparison_count ?? 0
    const progressTarget = 600
    const progressPercent = getProgressPercent(comparisonCount)
    const progressLabel = getProgressLabel(comparisonCount)
    const displayRankings = getDisplayRankings(rankings)
    const visibleRankings = displayRankings.filter((item) => item.displayRank <= 25)
    const rankingTiers = getRankingTiers(visibleRankings)
    const topRating = visibleRankings[0]?.rating ?? 1500
    const fifthDistinctRating = visibleRankings.find((item) => item.displayRank === 5)?.rating ?? topRating
    const rankingStatus = visibleRankings[0]?.comparisons >= 8 ? 'Leaders are stabilizing' : 'Top ranking is still settling'

    return (
      <main className="shell appShell">
        <nav className="nav">
          <a className="brand" href="/" aria-label="Name Duet home"><span className="brandMark">N</span><span>Name Duet</span></a>
          <span className="status">Room {session.roomToken}</span>
        </nav>

        <section className="workspace">
          <header className="workspaceHeader">
            <div><span className="eyebrow"><Sparkles size={15} /> {session.participantName}'s duet</span><h1 className="workspaceTitle">Which name feels right?</h1><p>Trust your first reaction. The rankings get smarter with every choice.</p></div>
            <div className="roomActions">
              <button className="secondary compactButton" type="button" onClick={copyInvite}><Copy size={17} /> {copied ? 'Copied!' : 'Invite partner'}</button>
              <button className="secondary compactButton" type="button" onClick={copyDeviceLink}><Smartphone size={17} /> {deviceCopied ? 'Private link copied!' : `Open as ${session.participantName} elsewhere`}</button>
              <button className="ghostButton" type="button" onClick={leaveRoom} aria-label="Leave room"><LogOut size={18} /></button>
            </div>
          </header>

          <div className="viewTabs" role="tablist">
            <button className={view === 'compare' ? 'active' : ''} onClick={() => setView('compare')}><Heart size={17} /> Compare</button>
            <button className={view === 'rankings' ? 'active' : ''} onClick={() => setView('rankings')}><BarChart3 size={17} /> My ranking</button>
            <button className={view === 'consensus' ? 'active' : ''} onClick={() => setView('consensus')}><Users size={17} /> Together</button>
          </div>

          {error && <p className="formError appError">{error}</p>}

          {view === 'compare' && (
            <section className="comparisonStage">
              <div className="comparisonProgress" aria-label={`${comparisonCount} of ${progressTarget} comparisons`}>
                <div className="progressCopy"><strong>{progressLabel}</strong><span>{comparisonCount} / {progressTarget}</span></div>
                <div className="progressTrack"><span style={{ width: `${progressPercent}%` }} /></div>
              </div>
              <div className="comparisonMeta"><span>{comparisonCount} choices made</span><span>Tap the name you prefer</span></div>
              {pair && left && right ? <div className={`liveCards ${loading ? 'isLoading' : ''}`}>
                <button className="choiceCard" type="button" disabled={loading} onClick={() => vote(pair.left_id)}>
                  <strong className="choiceName">{left.displayName}</strong>
                  {left.details && <span className="choiceDetails">{left.details}</span>}
                </button>
                <button className="choiceCard alternate" type="button" disabled={loading} onClick={() => vote(pair.right_id)}>
                  <strong className="choiceName">{right.displayName}</strong>
                  {right.details && <span className="choiceDetails">{right.details}</span>}
                </button>
              </div> : <div className="loadingCard">{loading ? 'Finding two names…' : 'No pair available yet.'}</div>}
            </section>
          )}

          {view === 'rankings' && (
            <section className="rankingPanel">
              <div className="rankingHeader"><div><span className="kicker">Your current taste</span><h2>Top names</h2></div><span className="counter">{comparisonCount} votes</span></div>
              {visibleRankings.length ? <>
                <div className="resultSummary">
                  <div><strong>{visibleRankings.length}</strong><span>leaders shown</span></div>
                  <div><strong>{formatPreferenceScore(topRating)}</strong><span>top preference score</span></div>
                  <div><strong>{Math.max(0, Math.round(topRating - fifthDistinctRating))}</strong><span>points across top 5 ranks</span></div>
                </div>
                <p className="rankingStatus">{rankingStatus}. Equal displayed scores share the same rank and stay in the same tier.</p>
                {rankingTiers.map((tier) => (
                  <section className="tierSection" key={tier.label}>
                    <div className="tierHeading"><div><h3>{tier.label}</h3><p>{tier.description}</p></div></div>
                    {tier.rows.map((item) => (
                      <article className="rankingRow" key={item.name_id}>
                        <span className="rankNumber">{item.displayRank}</span>
                        <div className="rankingMain">
                          <strong>{item.display_name}</strong>
                          <span className="rankingMeta">{formatPreferenceScore(item.rating)} preference · {item.wins}–{item.losses} · {item.comparisons} matchups</span>
                        </div>
                        <span className={`stabilityBadge ${getStability(item.comparisons).toLowerCase()}`}>{getStability(item.comparisons)}</span>
                      </article>
                    ))}
                  </section>
                ))}
              </> : <p className="emptyState">Make a few choices and your ranking will appear here.</p>}
            </section>
          )}

          {view === 'consensus' && (
            <section className="rankingPanel consensusPanel">
              <div className="rankingHeader"><div><span className="kicker">Shared favorites</span><h2>{two ? `${one} + ${two}` : 'Waiting for your partner'}</h2></div><span className="counter">Live</span></div>
              {!two ? <div className="emptyState"><p>Invite your partner to join this room. Shared results appear after both of you make a few choices.</p><button className="primary compactButton" onClick={copyInvite}>{copied ? 'Copied!' : 'Copy invite link'}</button></div> : consensus.length ? consensus.map((item, index) => (
                <article className="consensusRow" key={item.name_id}>
                  <span className="rankNumber">{index + 1}</span>
                  <div className="consensusName"><strong>{item.display_name}</strong>{Math.min(item.participant_one_comparisons, item.participant_two_comparisons) < 2 && <small>Still emerging</small>}</div>
                  <div className="duetRanks"><span>{one} #{item.participant_one_rank ?? '—'}</span><span>{two} #{item.participant_two_rank ?? '—'}</span></div>
                </article>
              )) : <p className="emptyState">Both of you need a few overlapping comparisons before consensus can emerge.</p>}
            </section>
          )}
        </section>
      </main>
    )
  }

  return (
    <main className="shell">
      <nav className="nav"><a className="brand" href="/" aria-label="Name Duet home"><span className="brandMark">N</span><span>Name Duet</span></a><span className="status">Private beta</span></nav>
      <section className="hero">
        <div className="eyebrow"><Sparkles size={15} /> Find the name you both love</div>
        <h1>Two opinions.<br /><em>One perfect name.</em></h1>
        <p className="lede">Compare baby names independently, then watch Name Duet uncover the favorites you share.</p>
        <div className="actions"><button className="primary" type="button" onClick={() => openForm('create')}>Create your room</button><button className="secondary" type="button" onClick={() => openForm('join')}>Join with a code</button></div>
        <p className="finePrint">No account required. Your room stays private.</p>
        {mode && <section className="inlineRoomForm" aria-live="polite"><span className="kicker">{mode === 'create' ? 'Start a new duet' : 'Join your partner'}</span><h2>{mode === 'create' ? 'Create your room' : 'Enter your room code'}</h2><form onSubmit={handleSubmit}><label>Your name<input value={name} onChange={(event) => setName(event.target.value)} placeholder="Nathaniel" autoFocus /></label>{mode === 'join' && <label>Room code<input value={roomCode} onChange={(event) => setRoomCode(event.target.value.toUpperCase())} placeholder="ABC12345" maxLength={8} /></label>}{error && <p className="formError">{error}</p>}<button className="primary modalSubmit" type="submit" disabled={loading}>{loading ? 'One moment…' : mode === 'create' ? 'Create room' : 'Join room'}</button></form></section>}
      </section>
      <section className="preview" aria-label="Product preview"><div className="previewHeader"><div><span className="kicker">A little closer</span><h2>Which name feels right?</h2></div><span className="counter">24 compared</span></div><div className="cards"><article className="nameCard"><span className="origin">Latin · golden</span><strong>Aurelia</strong><button type="button">Choose Aurelia</button></article><div className="or">or</div><article className="nameCard accent"><span className="origin">Spanish · wise protector</span><strong>Ramona</strong><button type="button">Choose Ramona</button></article></div></section>
      <section className="features"><article><Users size={21} /><h3>Rank separately</h3><p>No influence, no negotiating. Just honest reactions.</p></article><article><Heart size={21} /><h3>Discover overlap</h3><p>See shared favorites, hidden gems, and meaningful differences.</p></article><article><Sparkles size={21} /><h3>Get smarter</h3><p>Adaptive comparisons reveal your preferences with fewer choices.</p></article></section>
    </main>
  )
}
