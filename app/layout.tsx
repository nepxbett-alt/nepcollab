import './globals.css'
export const metadata={title:'NepCollab — Nepal Creator Marketplace',description:'Nepal-first creator and brand collaboration marketplace.',manifest:'/manifest.json',icons:{icon:'/icons/icon-192.png',apple:'/icons/icon-192.png'}}
export const viewport={width:'device-width',initialScale:1,viewportFit:'cover',themeColor:'#5b22e8'}
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang='en'><body>{children}</body></html>}
