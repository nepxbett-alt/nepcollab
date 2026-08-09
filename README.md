# NepCollab — Production Launch Build

NepCollab is a Nepal-first creator/brand collaboration marketplace designed to feel like a polished mobile app while running as a PWA.

## Launch model

Everything is **free at launch** from the platform side.

There is **no NPR 700 publishing fee, no merchant payment gateway, no QR payment gate, and no hardcoded creator payout**.

Brands create campaigns and publish them immediately. A brand chooses the creator reward, deliverables, platforms, deadline, minimum followers, brief, requirements and brand remarks. Creators discover live campaigns and apply.

The collaboration lifecycle is:

`Google sign-in → profile → social verification → marketplace → apply → brand accepts → brand remarks → creator submits work → brand approves/request revision → admin final verification → creator reward recorded → both sides review each other`

Creator rewards are paid manually by the admin through the chosen real-world method (eSewa/bank/etc.) and recorded in the transaction ledger. The platform does not process merchant payments at launch.

## Social verification

Creators and brands can connect:

- Instagram
- TikTok
- Facebook

NepCollab does **not** request their social passwords and does not require social API tokens for launch.

The app generates a one-time verification code. The user sends that code from the claimed account/page to the NepCollab admin social account. The app creates a `verification_requests` row and the database trigger creates notifications for every admin.

The admin checks the real social account manually and approves/rejects the request. Approved accounts receive a verified badge. Creators must have at least one verified social account before the marketplace unlocks.

The UI defaults to `@nepcollab.app` as the verification destination. Change the `social_verification_admin` value in the `platform_settings` table if your real admin handle is different.

## Core production features

- Google OAuth first-login flow for creator and brand roles
- Email/password fallback
- Persistent session + refresh handling
- Mobile-first PWA / standalone app experience
- Offline shell/service worker
- Creator onboarding and niche matching
- Social verification workflow for Instagram/TikTok/Facebook
- Verified creator discovery
- Live marketplace
- Search and category filters
- Saved campaigns
- Brand campaign builder
- Campaign briefs, requirements, deliverables, revisions and deadlines
- Creator applications
- Brand accept/reject workflow
- Per-creator brand remarks
- Creator content submission
- Brand approve/request-revision workflow
- Admin final work verification
- Manual creator reward recording
- Creator wallet/lifetime earnings ledger
- Brand and creator profiles
- Ratings/reviews after completed collaborations
- Campaign-linked messaging with message sending and polling refresh
- Notifications
- Disputes/reports/audit log schema
- Supabase RLS
- Admin verification queue
- No platform fee at launch (QR payment infrastructure is optional and disabled by default)


## Unified UI/UX system

The launch build now uses one shared visual language across creator, brand and admin surfaces. The official `public/nepcollab-logo.svg` is the single source of truth for the brand mark. Shared design tokens and interaction rules live in `app/globals.css`, covering color, gradients, typography, spacing, radii, shadows, controls, cards, navigation, overlays, focus states, motion, safe-area handling and responsive behavior.

The build also includes shared loading, error and not-found states so navigation never drops users into an unstyled screen. The service-worker shell version is bumped whenever the app shell changes to prevent stale UI from being served after deployment.

## 1. Supabase project

Create a Supabase project.

Open **SQL Editor → New query** and run the entire file:

`supabase/schema.sql`

Run it once on a fresh project. The SQL is written to be rerunnable with `IF NOT EXISTS` / `DROP POLICY` patterns where appropriate.

### Storage buckets

Create these buckets in Supabase Storage:

`avatars` — public

`campaign-media` — public

`submissions` — private

`verification-docs` — private

`payment-proofs` — private. This is prewired for an optional manual QR-payment model. It is **disabled by default** at launch with `payment_enabled=false` and `platform_fee_npr=0`, so the current launch remains free. If you later enable a platform fee, the app shows the configured QR, collects a screenshot/reference, notifies admins, and keeps the campaign hidden until approval.

## 2. Google login

In Supabase:

**Authentication → Providers → Google → Enable**

Create a Google OAuth application in Google Cloud Console and put the Google client ID/secret into Supabase's Google provider settings.

Use Supabase's displayed OAuth callback URL as the Google Authorized redirect URI.

Then in:

**Authentication → URL Configuration**

set your production Site URL, for example:

`https://your-domain.com`

and add the same production origin to the allowed redirect URLs.

For local development also allow your local origin, normally:

`http://localhost:3000`

The app stores the selected role (`creator` or `brand`) before redirecting to Google. On the first OAuth-created account, the role is applied to the new profile.

## 3. Environment variables

Copy:

`.env.example` → `.env.local`

Set:

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Do **not** put a Supabase service-role key in this browser application.

## 4. Create the first admin

Create your own account through Google first.

Find your profile UUID in Supabase:

**Table Editor → profiles**

Then run this from the Supabase SQL Editor:

```sql
select public.grant_admin('YOUR_PROFILE_UUID');
```

The function is intentionally not executable by normal `anon`/`authenticated` clients.

After that, sign out and sign in again. The admin Control/Verify screens will appear.

## 5. Configure your verification destination

The current UI tells users to send the code to the `social_verification_admin` value from `platform_settings` (default `@nepcollab.app`). Change that setting if your real admin social account is different.

The admin does not need a social API integration for this launch model. The code is simply checked manually against the real account/page.

## 6. Run locally

```bash
npm install
npm run build
npm start
```

For development:

```bash
npm run dev
```

Open:

`http://localhost:3000`

## 7. Test the complete launch path

### Creator

1. Click **Continue as Creator with Google**.
2. Complete creator niches.
3. Connect Instagram, TikTok or Facebook.
4. Copy the generated verification code.
5. Send it from that real account/page to your admin account.
6. Return to NepCollab and submit the verification.
7. Admin receives a notification.
8. Admin opens Verify → Social accounts.
9. Admin checks the real account/page and approves.
10. Creator marketplace unlocks.
11. Creator opens a campaign and applies.

### Brand

1. Click **Continue as Brand with Google**.
2. Complete the brand profile.
3. Optionally verify the brand's social pages using the same code workflow.
4. Create a campaign.
5. Set reward, category, platforms, deliverable, deadline, minimum followers, objective, brief and requirements.
6. Publish.
7. The campaign is immediately live because launch platform fee is NPR 0.
8. Review incoming creator applications.
9. Accept a creator.
10. Add creator-specific remarks/requirements.
11. Creator submits the work URL.
12. Brand approves or requests revision.
13. Approved work moves to the admin final-verification queue.

### Admin

1. Open **Verify**.
2. Approve/reject social verification requests.
3. Open **Control**.
4. Review brand-approved work.
5. Click **Verify & reward**.
6. Manually pay the creator through your real payout method.
7. The transaction ledger records the creator reward and the creator wallet/lifetime earnings update.
8. Both sides can then rate each other.

## 8. Optional manual QR payment mode

The launch build is configured for **NPR 0 platform fee**, matching the current free launch decision. The payment infrastructure is nevertheless included so you do not need to rebuild the app later if you decide to introduce a publishing fee.

Set these rows in `platform_settings` only when you are ready:

```sql
update platform_settings set value='true' where key='payment_enabled';
update platform_settings set value='YOUR_FEE' where key='platform_fee_npr';
update platform_settings set value='YOUR_QR_IMAGE_URL' where key='payment_qr_url';
```

When enabled, a paid campaign enters `pending_payment`. The brand sees the QR, uploads a payment screenshot and transaction/reference ID, and submits it. Admins receive a database notification. Admin opens **Payments**, views the private proof through a signed URL, and either approves (campaign becomes active) or rejects (brand is notified).

Do not turn this on until your real QR image URL is configured and you have tested the complete flow with a small real transaction.

## 9. Vercel deployment

Push the project to GitHub or upload it to Vercel.

Set these Vercel environment variables:

`NEXT_PUBLIC_SUPABASE_URL`

`NEXT_PUBLIC_SUPABASE_ANON_KEY`

Deploy.

Then update Supabase Authentication URL Configuration with the production domain.

## PWA

The app includes:

- `public/manifest.json`
- `public/sw.js`
- 192px and 512px icons
- standalone display mode
- service-worker registration
- responsive mobile-first UI

On Android Chrome, open the deployed site and use **Install app / Add to home screen**. The app opens in standalone mode with the browser chrome removed.

## Important launch rule

Do not advertise the product until you personally test these four flows on the deployed production URL:

1. Google creator sign-in → social verification → marketplace unlock.
2. Google brand sign-in → campaign creation → campaign visible to creators.
3. Creator application → brand acceptance → creator submission → brand approval → admin verification → reward ledger.
4. Creator review of brand + brand review of creator.

The launch architecture intentionally keeps payment-provider integrations out of the first release. This lets NepCollab prove the marketplace loop before adding transaction automation.
