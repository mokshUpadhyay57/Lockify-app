# Payment Flow Agent

Purpose:
Ensure payment → unlock flow is reliable

Flow:
User → Create Order → Payment → Webhook → Verify → Unlock

Rules:
- Webhook = source of truth
- Verify API = fallback
- Never trust frontend

Responsibilities:
- Handle duplicate webhook
- Handle app close cases
- Ensure correct order state