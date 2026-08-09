'use client'
import {useEffect} from 'react'

export default function Error({error,reset}:{error:Error & {digest?:string};reset:()=>void}){
  useEffect(()=>{console.error(error)},[error])
  return <main className="auth-page">
    <section className="auth-panel" style={{textAlign:'center'}}>
      <div className="brand-logo" style={{justifyContent:'center'}}><span className="logo-mark"><img src="/nepcollab-logo.svg" alt="NepCollab" /></span><span>NepCollab</span></div>
      <div className="auth-copy">
        <span className="eyebrow">Something went wrong</span>
        <h1>Let’s try that again.</h1>
        <p>The app hit an unexpected error. Your session and data are safe.</p>
      </div>
      <button className="cr-btn" style={{marginTop:24,width:'100%'}} onClick={()=>reset()}>Try again</button>
    </section>
  </main>
}
