# Email verification and recovery codes

Approved scope: signup confirmation and password recovery using Supabase-issued email codes. Gmail SMTP is a temporary demo sender; credentials remain in Supabase only. No landing deployment, migrations, account cleanup, or release build in this change.

## Implementation sequence
- [x] Operator/user configured Gmail SMTP; dashboard displayed “Successfully updated settings”. Actual delivery is unverified.
- [ ] Add token to signup/recovery templates while retaining existing confirmation links for older builds.
- [ ] Add code entry, server verification, resend cooldown, and invalid/expired/network error handling to VerifyEmailScreen.
- [ ] Route password recovery requests to code entry; recovery OTP must establish a recovery session before reset access.
- [ ] Run focused auth tests and analyzer; then offline suite if available.
- [ ] Verify delivery with the owner and a new app build before enabling required signup confirmation.

## Existing remote signup template (before change)
Subject: Confirm your email address

```html
<h2>Confirm your email address</h2>

<p>Follow the link below to confirm this email address and finish signing up.</p>
<p><a href="{{ .ConfirmationURL }}">Confirm email address</a></p>
```

The installed gotrue 2.27.2 verifyOTP implementation emits passwordRecovery for recovery tokens and signedIn for email tokens. No client-side comparison or hardcoded code is permitted.
