import { Heart, Sparkles, Users } from 'lucide-react'

export default function App() {
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
          <button className="primary" type="button">Create your room</button>
          <button className="secondary" type="button">Join with a code</button>
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
    </main>
  )
}
