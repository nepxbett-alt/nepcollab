export type Session = { access_token: string; refresh_token: string; expires_in?: number; expires_at?: number; user: { id: string; email?: string; user_metadata?: Record<string, unknown>; created_at?: string } }

const URL = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
const KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
const SESSION_KEY = 'nepcollab_session'

export const supabaseConfigured = Boolean(URL && KEY)

function headers(token?: string, json = true) {
  const h: Record<string,string> = { apikey: KEY }
  if (json) h['Content-Type'] = 'application/json'
  if (token) h.Authorization = `Bearer ${token}`
  return h
}

export function getSession(): Session | null {
  if (typeof window === 'undefined') return null
  try { return JSON.parse(localStorage.getItem(SESSION_KEY) || 'null') } catch { return null }
}
export function setSession(s: Session | null) {
  if (typeof window === 'undefined') return
  if (s) localStorage.setItem(SESSION_KEY, JSON.stringify(s)); else localStorage.removeItem(SESSION_KEY)
}

export async function refreshSession(): Promise<Session|null> {
  const current=getSession(); if(!current?.refresh_token) return null
  const r=await fetch(`${URL}/auth/v1/token?grant_type=refresh_token`,{method:'POST',headers:headers(),body:JSON.stringify({refresh_token:current.refresh_token})})
  if(!r.ok){setSession(null);return null}
  const j=await r.json(); const next:Session={...j,user:{id:j.user?.id||current.user.id,email:j.user?.email||current.user.email,user_metadata:j.user?.user_metadata||current.user.user_metadata,created_at:j.user?.created_at||current.user.created_at}}; setSession(next); return next
}

export async function getValidSession():Promise<Session|null>{
  const s=getSession(); if(!s) return null
  const exp=s.expires_at || (s.expires_in ? Date.now()+s.expires_in*1000 : 0)
  if(exp && exp-Date.now()<60000) return refreshSession()
  return s
}

export async function signIn(email:string,password:string):Promise<Session>{
  const r=await fetch(`${URL}/auth/v1/token?grant_type=password`,{method:'POST',headers:headers(),body:JSON.stringify({email,password})})
  const j=await r.json(); if(!r.ok) throw new Error(j.msg||j.error_description||j.message||'Login failed')
  j.expires_at=j.expires_at || Math.floor(Date.now()/1000)+Number(j.expires_in||3600); setSession(j); return j
}
export async function signUp(email:string,password:string,full_name:string,role='creator'):Promise<Session|null>{
  const r=await fetch(`${URL}/auth/v1/signup`,{method:'POST',headers:headers(),body:JSON.stringify({email,password,data:{full_name,role}})})
  const j=await r.json(); if(!r.ok) throw new Error(j.msg||j.message||'Sign up failed')
  if(j.access_token){j.expires_at=j.expires_at || Math.floor(Date.now()/1000)+Number(j.expires_in||3600);setSession(j);return j}; return null
}
export function googleUrl(){return `${URL}/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(typeof window==='undefined'?'':window.location.origin)}`}
export async function signOut(){const s=getSession(); if(s) await fetch(`${URL}/auth/v1/logout`,{method:'POST',headers:headers(s.access_token)}).catch(()=>{}); setSession(null)}

export async function rest<T=any>(path:string, options:RequestInit & {token?:string} = {}):Promise<T>{
  const {token,...init}=options as any
  const current=token?null:await getValidSession()
  let r=await fetch(`${URL}/rest/v1/${path}`,{...init,headers:{...headers(token ?? current?.access_token),...(init.headers||{})}})
  if(r.status===401 && !token){const refreshed=await refreshSession(); if(refreshed) r=await fetch(`${URL}/rest/v1/${path}`,{...init,headers:{...headers(refreshed.access_token),...(init.headers||{})}})}
  if(!r.ok){let msg='Request failed'; try{const j=await r.json();msg=j.message||j.error||j.hint||msg}catch{};throw new Error(msg)}
  const text=await r.text(); return (text?JSON.parse(text):null) as T
}

export async function upload(bucket:string,path:string,file:File,token?:string){
  const s=token||getSession()?.access_token; if(!s) throw new Error('Not signed in')
  const r=await fetch(`${URL}/storage/v1/object/${bucket}/${path.split('/').map(encodeURIComponent).join('/')}`,{method:'POST',headers:{apikey:KEY,Authorization:`Bearer ${s}`,'x-upsert':'true','Content-Type':file.type||'application/octet-stream'},body:file})
  const j=await r.json().catch(()=>({})); if(!r.ok) throw new Error(j.message||'Upload failed')
  return path
}

export async function signedUrl(bucket:string,path:string,expiresIn=3600,token?:string){
  const s=token||getSession()?.access_token; if(!s) throw new Error('Not signed in')
  const r=await fetch(`${URL}/storage/v1/object/sign/${bucket}/${path.split('/').map(encodeURIComponent).join('/')}`,{method:'POST',headers:{...headers(s)},body:JSON.stringify({expiresIn})})
  const j=await r.json().catch(()=>({})); if(!r.ok) throw new Error(j.message||'Could not create signed URL')
  return `${URL}/storage/v1${j.signedURL}`
}

export function channelUrl(){ return URL }


export async function restoreOAuthSession(): Promise<Session|null> {
  if (typeof window === 'undefined' || !supabaseConfigured) return null
  const hash = window.location.hash.startsWith('#') ? window.location.hash.slice(1) : ''
  if (!hash || !hash.includes('access_token=')) return null
  const params = new URLSearchParams(hash)
  const access_token = params.get('access_token')
  if (!access_token) return null
  const refresh_token = params.get('refresh_token') || ''
  const expires_in = Number(params.get('expires_in') || 3600)
  const r = await fetch(`${URL}/auth/v1/user`, { headers: headers(access_token, false) })
  if (!r.ok) throw new Error('Google sign-in could not be completed')
  const user = await r.json()
  const session: Session = { access_token, refresh_token, expires_in, expires_at: Math.floor(Date.now()/1000)+expires_in, user: { id:user.id, email:user.email, user_metadata:user.user_metadata || {}, created_at:user.created_at } }
  setSession(session)
  window.history.replaceState({}, document.title, window.location.pathname + window.location.search)
  return session
}
