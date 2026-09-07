function required(name: string): string {
  const v = process.env[name];
  if (!v || v.startsWith("REPLACE_WITH")) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return v;
}

export const env = {
  get supabaseUrl() {
    return required("SUPABASE_URL");
  },
  get supabaseSecretKey() {
    return required("SUPABASE_SECRET_KEY");
  },
  /** Client-safe key for Supabase Realtime (anon / publishable). */
  get supabasePublishableKey() {
    return (
      process.env.SUPABASE_PUBLISHABLE_KEY ||
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      process.env.SUPABASE_ANON_KEY ||
      null
    );
  },
  get anthropicApiKey() {
    return required("ANTHROPIC_API_KEY");
  },
  get firebaseServiceAccountPath() {
    return required("FIREBASE_SERVICE_ACCOUNT_PATH");
  },
  /** Where "contact us" (subscription) requests are emailed. */
  get contactEmail() {
    return (
      process.env.CONTACT_EMAIL ||
      process.env.SENDGRID_TO_EMAIL ||
      null
    );
  },
  sendgrid: {
    get apiKey() {
      return process.env.SENDGRID_API_KEY || null;
    },
    get fromEmail() {
      return process.env.SENDGRID_FROM_EMAIL || "dispatch@dira.app";
    },
  },
  twilio: {
    get accountSid() {
      return process.env.TWILIO_ACCOUNT_SID || null;
    },
    get authToken() {
      return process.env.TWILIO_AUTH_TOKEN || null;
    },
    get fromNumber() {
      return process.env.TWILIO_FROM_NUMBER || null;
    },
    get whatsappFrom() {
      return process.env.TWILIO_WHATSAPP_FROM || null;
    },
    /** WhatsApp Content Template SID for OTP (Twilio Content API). */
    get whatsappOtpTemplateSid() {
      return (
        process.env.TWILIO_WHATSAPP_OTP_TEMPLATE_SID ||
        process.env.TWILIO_PAYMENT_TEMPLATE_SID ||
        null
      );
    },
  },
  waha: {
    get url() {
      const raw = process.env.WAHA_URL?.trim() || null;
      return raw?.replace(/\/$/, "") ?? null;
    },
    get apiKey() {
      return process.env.WAHA_API_KEY || null;
    },
    /** Fallback session for outbound messages when building session is unknown. */
    get defaultSession() {
      return process.env.WAHA_SESSION || "buildingo";
    },
    get webhookSecret() {
      return process.env.WAHA_WEBHOOK_SECRET || null;
    },
  },
  /** Public origin for webhooks + shareable join links. */
  get publicWebUrl() {
    const raw = process.env.PUBLIC_WEB_URL?.replace(/\/$/, "") || null;
    if (!raw) return null;
    // Old Netlify marketing site — /join and the API are not hosted there.
    try {
      const host = new URL(raw).hostname.toLowerCase();
      if (host === "buildingo.com" || host === "www.buildingo.com") return null;
    } catch {
      return null;
    }
    return raw;
  },
};
