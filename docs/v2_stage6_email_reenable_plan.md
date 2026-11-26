# V2 Stage 6: Supabase Email Confirmation Re-Enable Plan

> **CRITICAL NOTICE**: **DO NOT CHANGE ANY PRODUCTION SUPABASE SETTINGS NOW.**
> This document is a strategic rollout plan only. No production or dashboard settings have been modified.
>
> **Prerequisite Blocker (Stage 0.1 Status)**:
> Stage 0.1 (*whether "Confirm email" is currently enabled or disabled in the remote Supabase project*) has remained unanswered since **2026-11-10**. **The current live state of "Confirm email" in the Supabase Dashboard MUST be inspected and verified by Alvin before anyone acts on this plan.**

---

## 1. Context & Trade-Off Analysis

### The Current State ("Confirm Email" Off / Unconfirmed)
When email confirmation is disabled:
- **Instant Onboarding**: Students can register and immediately log in without opening their inbox.
- **Major Security & Integrity Risks**:
  - **Unverified Identity**: Anyone can register using any email address (e.g. `dean@university.edu`, `president@umindanao.edu.ph`, or non-existent emails) without proving ownership.
  - **Account Takeover / Hijacking**: A malicious actor could register a real student's email address before they sign up, locking out the legitimate owner.
  - **Email Deliverability & Spam**: Password reset emails or notifications sent to invalid/unowned addresses hurt domain sender reputation and trigger bounce penalties.

### The Target State ("Confirm Email" On with Custom SMTP via Resend)
When email confirmation is re-enabled:
- **Verified Ownership**: Only users who control the registered email address can activate and access their StudyNest account.
- **Account Protection**: Prevents impersonation and unauthorized registration under third-party email addresses.
- **Smooth Delivery**: By using **Resend (free tier: 3,000 emails/month, 100 emails/day)** with a verified custom domain, transactional confirmation emails avoid spam folders and rate limiting imposed by Supabase's default built-in email service (which is strictly capped at 30 emails/hour for testing).
- **Onboarding Friction Trade-Off**: Requires users to click a confirmation link before initial sign-in. The app UI must clearly guide users to check their inbox.

---

## 2. Secrets & Credential Management (Zero-Leakage Guarantee)

> **MANDATORY SECURITY RULE**:
> The Resend API Key (`re_...`) grants sending privileges on behalf of your domain.
> **The Resend API key must NEVER be committed to this git repository, NEVER placed in client application code or configuration files, NEVER included in tests, and NEVER shared in chat.**
>
> The key is entered **exclusively into the Supabase Dashboard SMTP settings** via the web interface.

---

## 3. Step-by-Step Implementation Guide

### Step 1: Confirm Existing State (Resolving Stage 0.1)
1. Log in to [Supabase Dashboard](https://supabase.com/dashboard).
2. Select the StudyNest project.
3. Navigate to **Authentication** -> **Providers** -> **Email**.
4. Check the status of **"Confirm email"**:
   - Record whether it is currently toggled **ON** or **OFF**.
   - If already ON, verify what SMTP provider or default quota is currently configured.
   - If OFF, proceed with the rollout steps below.

---

### Step 2: Set Up Custom SMTP Provider (Resend - Free Tier)
1. Sign up or log in at [https://resend.com](https://resend.com).
2. **Add Domain**:
   - Go to **Domains** -> **Add Domain**.
   - Enter your domain (e.g. `studynest.app` or subdomain `mail.studynest.app`).
   - Add the generated DNS records (SPF, DKIM, DMARC, MX) at your DNS registrar/provider.
   - Wait until domain status displays **Verified**.
   *(Note: For staging/testing before domain purchase, Resend allows sending to the account owner's email address using `onboarding@resend.dev`)*.
3. **Generate API Key**:
   - Go to **API Keys** -> **Create API Key**.
   - Name: `StudyNest Supabase Auth SMTP`.
   - Permissions: `Sending access` (restricted to your verified domain).
   - Copy the API key (`re_...`) immediately.

---

### Step 3: Configure Custom SMTP in Supabase Dashboard
1. Go to **Supabase Dashboard** -> **Project Settings** (gear icon) -> **Authentication** (or **Authentication** -> **Email Templates / SMTP Settings**).
2. Scroll to **Custom SMTP**.
3. Toggle **Enable Custom SMTP** to **ON**.
4. Configure the SMTP fields:
   | Setting | Value |
   |---|---|
   | **Sender Email** | `noreply@<your-verified-domain>` (e.g. `noreply@studynest.app`) |
   | **Sender Name** | `StudyNest` |
   | **Host** | `smtp.resend.com` |
   | **Port Number** | `465` (SSL) or `587` (TLS) |
   | **Minimum Transfer Security** | `SSL/TLS` or `STARTTLS` (matches chosen port) |
   | **User** | `resend` |
   | **Password** | *(Paste your Resend API Key `re_...` here — NEVER commit this)* |
5. Click **Save Changes**.
6. Send a test email from the Supabase dashboard to verify connectivity and delivery.

---

### Step 4: Re-Enable "Confirm Email"
1. In the Supabase Dashboard, navigate to **Authentication** -> **Providers** -> **Email**.
2. Locate the toggle **"Confirm email"**.
3. Toggle **"Confirm email"** to **ON**.
4. Set **"Confirm email URL redirect"**:
   - Ensure the redirect URL matches the app's deep link or authentication callback:
     - Development: `io.supabase.studynest://login-callback/` or custom scheme `studynest://auth/confirm`
     - Production: `https://<your-domain>/auth/v1/verify` or configured mobile deep link.
5. Click **Save**.

---

### Step 5: Verify & Customize Email Confirmation Template
1. In Supabase Dashboard, navigate to **Authentication** -> **Email Templates** -> **Confirm signup**.
2. Review the email body and styling:
   - Ensure subject line is friendly (e.g., `Confirm your StudyNest account`).
   - Ensure the confirmation link button/token is clearly visible.
3. Save changes.

---

## 4. Verification & Testing Checklist (Human Verification Required)

Do not consider this feature complete until performing these live manual checks:

- [ ] **Stage 0.1 Resolution**: Documented the initial state of "Confirm email" before changes.
- [ ] **SMTP Test**: Test email sent from Supabase dashboard arrives in inbox with DKIM/SPF passing.
- [ ] **New Registration Verification**:
  1. Register a new user in StudyNest with a real test email address.
  2. Verify that `auth.users` row is created with `confirmed_at = null` and `email_confirmed_at = null`.
  3. Verify confirmation email arrives promptly in inbox (delivered via Resend).
  4. Attempting to log in before clicking confirmation shows appropriate feedback ("Email not confirmed").
  5. Click the confirmation link in the email.
  6. Verify in Supabase Dashboard that `email_confirmed_at` is now populated with a timestamp.
  7. Log in through the StudyNest app; verify sign-in succeeds and user accesses dashboard.
- [ ] **Resend Rate Limit Monitoring**: Monitor Resend dashboard metrics to ensure free tier quota (100 emails/day, 3,000/month) is sufficient during rollout.
