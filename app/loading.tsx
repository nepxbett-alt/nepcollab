import { Logo } from './loading-logo'

export default function Loading(){
  return <main className="splash" aria-label="Loading NepCollab">
    <span className="splash-orb one" aria-hidden="true" />
    <span className="splash-orb two" aria-hidden="true" />
    <div className="splash-center">
      <Logo />
      <p>Create. Collab. Grow.</p>
    </div>
    <div className="splash-spinner" aria-hidden="true" />
  </main>
}
