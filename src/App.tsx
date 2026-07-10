import { FormEvent, useState } from 'react'
import { Heart, Sparkles, Users, X } from 'lucide-react'
import { supabase } from './lib/supabase'

type Mode = 'create' | 'join' | null

type RoomSession = {
  roomToken: string
  participantToken: string
  participantName: string
}

export default function App() {
  const [mode, setMode] = useState<Mode>(null)
  const [name, setName] = useState('')
  const [roomCode, setRoomCode] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [session, setSession] = useState<RoomSession | null>(() => {
    const saved = localStorage.getItem('name-duet-session')
    return saved ? JSON.parse(saved) : null
  })

  const closeModal = () => {
    setMode(null)
    setError('')
  }

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError('')

    const participantName = name.trim()
    if (!participantName) {
      setError('Please enter your name.')
      return
    }

    if (mode === 'join' && !roomCode.trim()) {
      setError('Please enter the room code.')
      return
    }

    setLoading(true)

    const rpc = mode === 'create'
      ? supabase.rpc('create_room', { owner_name: participantName })
      : supabase.rpc('join_room', {
          join_token: roomCode.trim().toUpperCase(),
          participant_name: participantName,
        })

    const { data, error: rpcError } = await rpc
    setLoading(false)

    if (rpcError) {
      setError(rpcError.message.includes('Room not found')
        ? 'We could not find that room. Check the code and try again.'
        : rpcError.message)
      return
    }

    const result = data?.[0]
    if (!result) {
      setError('Something went wrong creating your room.')
      return
    }

    const nextSession = {
      roomToken: result.room_token,
      participantToken: result.participant_token,
      participantName,
    }

    localStorage.setItem('name-duet-session', JSON.stringify(nextSession))
    setSession(nextSession)
    closeModal()
  }

  const copyInvite = async () => {
    if (!session) return
    const inviteUrl = `${window.location.origin}/?room=${session.roomToken}`
    await navigator.clipboard.writeText(inviteUrl)
  }

  if (session) {
    return (
      <main className="shell">
        <nav className="nav">
          <a className="brand" href="/" aria-label="Name Duet home">
            <span className="brandMark">N</span>
            <span>Name Duet</span>
          </a>
          <span className="status">Room {session.roomToken}</span>
        </nav>

        <section className="roomWelcome">
          <div className="eyebrow"><Sparkles size={15} /> Your duet has begun</div>
          <h1>Welcome, <em>{session.participantName}.</em></h1>
          <p className="lede">Your private room is ready. Invite Laura, then you can begin comparing names independently.</p>
          <div className="inviteCard">
            <span>Room code</span>
            <strong>{session.roomToken}</strong>
            <button className="primary" type="button" onClick={copyInvite}>Copy invite link</button>
          </div>
          <p className="finePrint">The comparison experience is the next build step.</p>
        </section>
      </main>
    )
  }

  return (
    <main className="shell">
      <nav className="nav">
        <a className="brand" href="/" aria-label="Name Duet home">
          <span className="brandMark">N</span>
          <span>Name Duet</span>
        </a>
        <span className="status">Private beta</span>
      </nav>

      <section className="hero">
        <div className="eyebrow"><Sparkles size={15} /> Find the name you both love</div>
        <h1>Two opinions.<br /><em>One perfect name.</em></h1>
        <p className="lede">
          Compare baby names independently, then watch Name Duet uncover the favorites you share.
        </p>
        <div className="actions">
          <button className="primary" type="button" onClick={() => setMode('create')}>Create your room</button>
          <button className="secondary" type="button" onClick={() => setMode('join')}>Join with a code</button>
        </div>
        <p className="finePrint">No account required. Your room stays private.</p>
      </section>

      <section className="preview" aria-label="Product preview">
        <div className="previewHeader">
          <div>
            <span className="kicker">A little closer</span>
            <h2>Which name feels right?</h2>
          </div>
          <span className="counter">24 compared</span>
        </div>
        <div className="cards">
          <article className="nameCard">
            <span className="origin">Latin · golden</span>
            <strong>Aurelia</strong>
            <button type="button">Choose Aurelia</button>
          </article>
          <div className="or">or</div>
          <article className="nameCard accent">
            <span className="origin">Spanish · wise protector</span>
            <strong>Ramona</strong>
            <button type="button">Choose Ramona</button>
          </article>
        </div>
      </section>

      <section className="features">
        <article><Users size={21} /><h3>Rank separately</h3><p>No influence, no negotiating. Just honest reactions.</p></article>
        <article><Heart size={21} /><h3>Discover overlap</h3><p>See shared favorites, hidden gems, and meaningful differences.</p></article>
        <article><Sparkles size={21} /><h3>Get smarter</h3><p>Adaptive comparisons reveal your preferences with fewer choices.</p></article>
      </section>

      {mode && (
        <div className="modalBackdrop" role="presentation" onMouseDown={closeModal}>
          <section className="modal" role="dialog" aria-modal="true" aria-labelledby="room-title" onMouseDown={(event) => event.stopPropagation()}>
            <button className="modalClose" type="button" aria-label="Close" onClick={closeModal}><X size={20} /></button>
            <span className="kicker">{mode === 'create' ? 'Start a new duet' : 'Join your partner'}</span>
            <h2 id="room-title">{mode === 'create' ? 'Create your room' : 'Enter your room code'}</h2>
            <form onSubmit={handleSubmit}>
              <label>
                Your name
                <input value={name} onChange={(event) => setName(event.target.value)} placeholder="Nathaniel" autoFocus />
              </label>
              {mode === 'join' && (
                <label>
                  Room code
                  <input value={roomCode} onChange={(event) => setRoomCode(event.target.value.toUpperCase())} placeholder="ABC12345" maxLength={8} />
                </label>
              )}
              {error && <p className="formError">{error}</p>}
              <button className="primary modalSubmit" type="submit" disabled={loading}>
                {loading ? 'One moment…' : mode === 'create' ? 'Create room' : 'Join room'}
              </button>
            </form>
          </section>
        </div>
      )}
    </main>
  )
}
