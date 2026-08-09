import Link from 'next/link'

export default function NotFound(){
  return <main className="auth-page">
    <section className="auth-panel" style={{textAlign:'center'}}>
      <div className="brand-logo" style={{justifyContent:'center'}}><span className="logo-mark"><img src="/nepcollab-logo.svg" alt="NepCollab" /></span><span>NepCollab</span></div>
      <div className="auth-copy">
        <span className="eyebrow">404</span>
        <h1>Page not found.</h1>
        <p>The page you are looking for has moved or no longer exists.</p>
      </div>
      <Link href="/" className="cr-btn" style={{marginTop:24,width:'100%'}}>Back to NepCollab</Link>
    </section>
  </main>
}
