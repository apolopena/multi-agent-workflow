# Email Setup Guide - Catalytic Customer

**Purpose:** Complete configuration guide for production email delivery with SPF, DKIM, Gmail SMTP, and deliverability testing.

---

## Overview

The Catalytic Customer system sends invitation emails automatically from the public registration form. Proper email configuration is **critical** to prevent invitations from being flagged as spam.

**Delivery Pipeline:** FastAPI-Mail → Gmail SMTP → Recipient's inbox

**Risk:** Without SPF/DKIM configuration, 30-50% of emails may be flagged as spam or rejected.

---

## Part 1: Gmail SMTP Setup

### Step 1: Create Gmail App Password

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable **2-Step Verification** (required for app passwords)
3. Go to **App Passwords** section
4. Select:
   - App: **Mail**
   - Device: **Other (Custom name)** → "Catalytic Customer"
5. Click **Generate**
6. Copy the 16-character password (format: `xxxx xxxx xxxx xxxx`)

**Important:** This password is shown only once. Store it securely.

### Step 2: Configure Environment Variables

Add to `.env.dev` and `.env.prod`:

```bash
# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=noreply@learnstream.tech
MAIL_PASSWORD=xxxx xxxx xxxx xxxx  # App password from Step 1
MAIL_FROM=noreply@learnstream.tech
```

**Recommendations:**
- Use a dedicated email address (not personal Gmail)
- Format: `noreply@learnstream.tech` or `invitations@learnstream.tech`
- Never commit `.env` files to version control

### Step 3: Verify SMTP Connection

Test connection from backend container:

```bash
docker exec -it catalytic-backend python3 << EOF
import smtplib
from email.mime.text import MIMEText

# Test connection
smtp = smtplib.SMTP('smtp.gmail.com', 587)
smtp.starttls()
smtp.login('noreply@learnstream.tech', 'your-app-password')
print("✅ SMTP connection successful")
smtp.quit()
EOF
```

If successful, proceed to DNS configuration.

---

## Part 2: DNS Configuration (SPF & DKIM)

### Why SPF and DKIM Matter

**SPF (Sender Policy Framework):** Tells receiving mail servers which IP addresses are allowed to send email from your domain.

**DKIM (DomainKeys Identified Mail):** Adds a cryptographic signature to emails to verify they weren't tampered with.

**Without these:** Gmail/Outlook/Yahoo may flag your emails as spam or reject them entirely.

### Step 1: Configure SPF Record

Add a TXT record to your DNS for `learnstream.tech`:

**Record Type:** TXT
**Name:** `@` (or `learnstream.tech`)
**Value:** `v=spf1 include:_spf.google.com ~all`

**Explanation:**
- `v=spf1` - SPF version 1
- `include:_spf.google.com` - Allow Gmail servers to send email
- `~all` - Soft fail for other servers (marks as suspicious but doesn't reject)

**Testing SPF:**
```bash
dig txt learnstream.tech +short
# Expected output:
# "v=spf1 include:_spf.google.com ~all"
```

### Step 2: Configure DKIM

DKIM requires generating a key pair and adding the public key to DNS.

#### Option A: Use Gmail's DKIM (Recommended for Google Workspace)

If using Google Workspace:
1. Go to [Google Admin Console](https://admin.google.com)
2. Navigate to **Apps → Google Workspace → Gmail → Authenticate email**
3. Click **Generate new record**
4. Copy the generated DKIM TXT record
5. Add to DNS:
   - **Name:** `google._domainkey.learnstream.tech`
   - **Type:** TXT
   - **Value:** (paste from Google Admin)

#### Option B: Use Third-Party DKIM Service

If using standard Gmail (not Workspace), use a service like:
- [Mailgun DKIM](https://www.mailgun.com/)
- [SendGrid DKIM](https://sendgrid.com/)
- [Amazon SES](https://aws.amazon.com/ses/)

These services provide SMTP relay with automatic DKIM signing.

**Example with SendGrid:**
1. Sign up for SendGrid free tier (100 emails/day)
2. Create API key
3. Update `.env`:
   ```bash
   MAIL_SERVER=smtp.sendgrid.net
   MAIL_PORT=587
   MAIL_USERNAME=apikey
   MAIL_PASSWORD=<your-sendgrid-api-key>
   MAIL_FROM=noreply@learnstream.tech
   ```
4. Add SendGrid's DKIM records to DNS (provided in their dashboard)

**Testing DKIM:**
```bash
dig txt google._domainkey.learnstream.tech +short
# Should return the public key TXT record
```

### Step 3: Configure DMARC (Optional but Recommended)

DMARC tells receiving servers what to do with emails that fail SPF/DKIM.

Add TXT record:
- **Name:** `_dmarc.learnstream.tech`
- **Type:** TXT
- **Value:** `v=DMARC1; p=quarantine; rua=mailto:dmarc@learnstream.tech`

**Explanation:**
- `p=quarantine` - Treat suspicious emails as spam (not reject entirely)
- `rua=mailto:...` - Send aggregate reports to this email

**Testing DMARC:**
```bash
dig txt _dmarc.learnstream.tech +short
# "v=DMARC1; p=quarantine; rua=mailto:dmarc@learnstream.tech"
```

---

## Part 3: Email Deliverability Testing

### Step 1: Send Test Email

Use the backend API or admin dashboard to send a test invitation:

```bash
curl -X POST http://localhost:8000/api/public/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "email": "your-test-email@gmail.com"
  }'
```

### Step 2: Check Inbox and Spam Folder

1. **Gmail Account:**
   - Check inbox
   - Check spam folder
   - If in spam, click "Not spam" and note the reason given

2. **Outlook/Hotmail Account:**
   - Check inbox
   - Check junk folder
   - If in junk, move to inbox

3. **Yahoo Account:**
   - Check inbox
   - Check spam folder

### Step 3: Use Mail-Tester.com

Send a test email to the address provided by [Mail-Tester](https://www.mail-tester.com):

1. Go to https://www.mail-tester.com
2. Copy the test email address (e.g., `test-abc123@mail-tester.com`)
3. Send invitation to that address via your system
4. Click "Then check your score"

**Target Score:** 8/10 or higher

**Common Issues:**
- Missing SPF record → Add SPF TXT record
- Missing DKIM signature → Configure DKIM or use relay service
- No reverse DNS → Use Gmail/SendGrid (they handle this)
- High spam complaint rate → Ensure you're only sending to opted-in users

### Step 4: Test Email Headers

View email headers to verify SPF/DKIM authentication:

**Gmail:**
1. Open the email
2. Click **More** (⋮) → **Show original**
3. Look for:
   ```
   spf=pass (google.com: domain of noreply@learnstream.tech designates ... as permitted sender)
   dkim=pass header.i=@learnstream.tech
   dmarc=pass (p=QUARANTINE sp=QUARANTINE dis=NONE)
   ```

**All three should show `pass`.**

If any show `fail`, review DNS configuration.

---

## Part 4: Production Email Template

Ensure invitation emails follow best practices:

### Email Content Best Practices

```python
# backend/services/email.py

async def send_invite_email(email: str, first_name: str, token: str):
    """Send invitation email with proper formatting"""
    invite_url = f"https://{os.getenv('DOMAIN')}/session?token={token}"

    # Use HTML template with plain text fallback
    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f4f4f4; padding: 20px; border-radius: 5px;">
            <h2 style="color: #2563eb; margin-top: 0;">Your Catalytic Customer Invitation</h2>
            <p>Hi {first_name},</p>
            <p>You've been invited to participate in Catalytic Customer!</p>
            <p style="margin: 30px 0;">
                <a href="{invite_url}"
                   style="background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                    Start Your Session
                </a>
            </p>
            <p style="color: #666; font-size: 14px;">
                Or copy and paste this link into your browser:<br>
                <a href="{invite_url}" style="color: #2563eb; word-break: break-all;">{invite_url}</a>
            </p>
            <p style="color: #666; font-size: 14px;">
                This link is valid for 30 days.
            </p>
            <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
            <p style="color: #999; font-size: 12px; text-align: center;">
                Catalytic Customer by LearnStream<br>
                If you didn't request this invitation, you can safely ignore this email.
            </p>
        </div>
    </body>
    </html>
    """

    plain_text_body = f"""
Hi {first_name},

You've been invited to participate in Catalytic Customer!

Click here to start your session:
{invite_url}

This link is valid for 30 days.

Best regards,
Catalytic Customer Team

---
If you didn't request this invitation, you can safely ignore this email.
    """

    message = MessageSchema(
        subject="Your Catalytic Customer Invitation",
        recipients=[email],
        body=plain_text_body,
        html=html_body,
        subtype="html"
    )

    await fm.send_message(message)
```

**Key Elements:**
- HTML + plain text fallback
- Clear call-to-action button
- Link also in plain text (for email clients that block buttons)
- Unsubscribe/ignore message (reduces spam complaints)
- Professional footer with organization name

---

## Part 5: Monitoring & Troubleshooting

### Key Metrics to Track

1. **Bounce Rate:** Emails that fail to deliver (target: <2%)
2. **Spam Placement Rate:** Emails landing in spam folder (target: <5%)
3. **Open Rate:** Users opening the email (target: >30%)
4. **Click Rate:** Users clicking the invite link (target: >20%)

### Monitoring Tools

**Option 1: SendGrid Analytics** (if using SendGrid)
- Real-time delivery tracking
- Bounce/spam reports
- Engagement metrics

**Option 2: Custom Logging** (if using Gmail SMTP)

```python
# backend/services/email.py

import logging
logger = logging.getLogger("email")

async def send_invite_email(email: str, first_name: str, token: str):
    try:
        await fm.send_message(message)
        logger.info(f"✅ Invitation sent: {email}")
    except Exception as e:
        logger.error(f"❌ Failed to send invitation to {email}: {e}")
        raise
```

### Common Issues & Solutions

#### Issue: "Authentication failed" error

**Cause:** Incorrect Gmail app password or 2FA not enabled

**Solution:**
1. Verify 2-Step Verification is enabled
2. Generate new app password
3. Update `.env` with correct password (remove spaces)

#### Issue: Emails landing in spam folder

**Cause:** Missing SPF/DKIM or content triggers

**Solution:**
1. Verify SPF/DKIM records: `dig txt learnstream.tech`
2. Remove spam trigger words: "free", "urgent", "click now"
3. Ensure HTML is valid and not image-heavy
4. Use Mail-Tester.com to identify issues

#### Issue: High bounce rate

**Cause:** Invalid email addresses or domain reputation issues

**Solution:**
1. Validate email addresses before sending (check MX records)
2. Use double opt-in (not applicable for invitations)
3. Monitor bounce logs and remove invalid addresses

#### Issue: Rate limiting

**Cause:** Gmail free tier limits (500 emails/day)

**Solution:**
1. Upgrade to Google Workspace (2,000 emails/day per user)
2. Use SendGrid/Mailgun (much higher limits)
3. Implement queuing system for bulk invitations

---

## Part 6: Production Deployment Checklist

Before launching:

- [ ] Gmail app password generated and stored in `.env.prod`
- [ ] SPF TXT record added to DNS and verified
- [ ] DKIM configured (via Google Workspace or SendGrid)
- [ ] DMARC TXT record added (optional but recommended)
- [ ] Test email sent to Gmail, Outlook, Yahoo accounts
- [ ] Mail-Tester.com score ≥ 8/10
- [ ] Email headers show `spf=pass`, `dkim=pass`, `dmarc=pass`
- [ ] HTML email template tested in multiple clients
- [ ] Fallback manual invitation process documented (copy/paste URL)
- [ ] Monitoring/logging enabled for email delivery tracking
- [ ] Rate limits understood and queuing system in place (if needed)

---

## Appendix: Alternative SMTP Providers

If Gmail SMTP proves unreliable, consider:

### SendGrid
- **Free Tier:** 100 emails/day
- **Paid:** $20/month for 50,000 emails/month
- **Pros:** Excellent deliverability, built-in DKIM, real-time analytics
- **Cons:** Requires account verification (can take 24-48 hours)

### Mailgun
- **Free Tier:** 5,000 emails/month (first 3 months)
- **Paid:** $35/month for 50,000 emails/month
- **Pros:** Developer-friendly API, good deliverability
- **Cons:** Higher pricing than SendGrid

### Amazon SES
- **Pricing:** $0.10 per 1,000 emails
- **Pros:** Extremely cheap, integrates with AWS
- **Cons:** Requires AWS account, harder to set up

### Resend
- **Free Tier:** 3,000 emails/month
- **Paid:** $20/month for 50,000 emails/month
- **Pros:** Modern API, great for transactional emails
- **Cons:** Newer service (less established reputation)

**Recommendation for Alpha:** Start with Gmail SMTP. If deliverability issues occur, migrate to SendGrid.

---

**Status:** Ready for production deployment once DNS records are configured and tested.
