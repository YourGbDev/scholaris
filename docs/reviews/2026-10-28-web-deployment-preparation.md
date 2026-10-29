# Website and portal deployment preparation

Status: local preparation only, 28 October 2026. No site has been published, no domain or DNS has been configured, and live CAPTCHA remains disabled. The domain name and registrar will be provided later.

A fresh release web build succeeded at `scratch/deployment-web` and includes the challenge page. A local browser opened its onboarding screen; authenticated workflows and hosted routing have not been verified. This build uses the default CAPTCHA-disabled configuration and must be rebuilt with the real public site key after setup.

The full Flutter test suite passed 1,110 tests with 9 skipped; focused security tests, the targeted analyzer and the two local database migration harnesses also passed. These checks do not establish live CAPTCHA, live migration compatibility, or device readiness.

## Suggested arrangement

Use the main domain for the static `landing/` website and a separate HTTPS subdomain such as `app.<domain>` for the Flutter portal. The portal must be served from the root of its host: the current CAPTCHA and password-recovery URLs use root-relative paths. Configure the host to return the Flutter `index.html` for application routes such as `/provider/login` and `/reset-password`, while serving real files, including `/captcha_challenge.html`, directly. Verify this behavior on the chosen host before use. Domain, hosting provider, and exact names remain decisions for the owner.

The landing page has hard-coded localhost links and a development script that can construct an HTTP URL. Replace and verify these when the portal address is known. Review public-facing claims, including AI, institutional affiliations, address, email, contact links and unavailable features before publication; the current page contains unverified examples. Confirm whether the concept video and sample data are appropriate for public viewing.

## Deployment order

1. Select the domain, DNS access and hosting, and review the final site content. Build the portal for the target environment, without exposing any Supabase service-role key or CAPTCHA secret. The browser-accessible Supabase anon key is public by design; authorization must be enforced by database policies.
2. Deploy the portal and challenge page on HTTPS, configure the landing page's portal links, and confirm direct routes, refresh, signup, login, recovery and role-specific portals on the actual host. Add the precise deployed recovery redirect URL to Supabase Auth URL configuration and test the email flow.
3. Create a real Cloudflare Turnstile widget for the authorized hostnames. Build the web and mobile clients with `SCHOLARIS_CAPTCHA_ENABLED=true`, the public `SCHOLARIS_CAPTCHA_SITE_KEY`, and for native builds the HTTPS `SCHOLARIS_CAPTCHA_PAGE_URL` pointing to the hosted challenge page. Do not put the secret in source, builds, logs, or chat. Test the real challenge and all auth flows on web and an iPhone; test failure and cancellation too.
4. Coordinate the release of all supported clients before enabling CAPTCHA in Supabase Auth. Old builds without a token can fail sign-in, signup and recovery once the server requires CAPTCHA. Enter the secret privately in the provider dashboard, enable protection, and repeat tests with controlled accounts. Test keys are for isolated testing only and do not provide production protection.
5. Rehearse the complete student/provider/reviewer/admin flow, including role boundaries, email verification and recovery, and record results. Check backup and restore, audit completeness, and server-side lockout separately; deployment and CAPTCHA alone do not establish these controls.

## Other outstanding security work

- Local migrations `0035_guard_profile_status.sql` and `0036_sync_confirmed_auth_email.sql` have local harness coverage but are not deployed. Review compatibility with the live schema, existing users and authorization policies, and arrange a recovery plan before any live application. Status checks do not automatically revoke every existing session.
- The student change-email interface requires compatible live Supabase email templates and real testing, including confirmation from both addresses where secure email change is enabled. Other role interfaces need review.
- The 15-minute timeout is app-side; Supabase server session inactivity controls were observed to be Pro-only on the current plan. Current bad-password lockout is not established as server-enforced. Backups and a safe isolated restoration test remain outstanding.
- A new iOS build must be installed to test current source changes. A previously built IPA does not include them.

## Useful references

- [Supabase CAPTCHA integration](https://supabase.com/docs/guides/auth/auth-captcha)
- [Cloudflare Turnstile mobile implementation](https://developers.cloudflare.com/turnstile/get-started/mobile-implementation/)
- [Cloudflare hostname management](https://developers.cloudflare.com/turnstile/additional-configuration/hostname-management/)
