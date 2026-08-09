# NepCollab Launch Checklist

## Assistant-completed in this build

- Unified creator, brand and admin UI/UX around the shared design system.
- Official NepCollab logo remains the single brand asset.
- Creator and brand social verification gate is enforced until at least one page/account is admin-verified.
- Admin verification requests create admin notifications.
- Campaign lifecycle supports free launch and an optional future `pending_payment` state.
- Optional manual QR payment infrastructure is included but disabled by default.
- QR payment proof upload accepts PNG/JPG/WEBP and is stored privately.
- Payment submissions notify admins through the database trigger.
- Admin can approve/reject payment proofs; approval makes the campaign live.
- Private payment proofs are opened with signed URLs.
- Campaign-linked messaging now creates conversations, sends messages and refreshes messages periodically.
- PWA shell/cache and shared loading/error/not-found states are included from the unified build.

## You must do before public launch

1. Create the production Supabase project.
2. Run `supabase/schema.sql` in Supabase SQL Editor.
3. Configure Google OAuth in Supabase Authentication.
4. Set the production Site URL and redirect URLs in Supabase.
5. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in Vercel.
6. Create your first account, then grant it admin using the protected SQL function in the README.
7. Change `social_verification_admin` to your real Instagram/TikTok/Facebook verification destination.
8. Test creator verification using a real social account.
9. Test brand verification using a real page/account.
10. Test creator → application → acceptance → remarks → submission → brand approval → admin verification → manual creator payout → review.
11. Confirm the creator wallet and transaction ledger update correctly after an admin payout.
12. Test notifications on both sides.
13. Test messaging between a creator and brand.
14. Test the PWA on your Android phone using the deployed HTTPS URL.
15. Test logout, refresh, expired session, rejected verification, rejected submission, revision, duplicate application and duplicate payout scenarios.
16. Only after all tests pass, switch the production domain to public launch.

## Optional QR-payment launch later

The current launch is free: `payment_enabled=false` and `platform_fee_npr=0`.

When you decide to charge a platform fee, configure:

```sql
update platform_settings set value='true' where key='payment_enabled';
update platform_settings set value='YOUR_FEE' where key='platform_fee_npr';
update platform_settings set value='YOUR_QR_IMAGE_URL' where key='payment_qr_url';
```

Then test the full path with a real payment:

`Brand creates paid campaign → QR appears → pays → uploads screenshot + reference → admin notification → admin opens proof → approve → campaign becomes active.`

Do not enable this until the real QR image and payment destination are correct.
