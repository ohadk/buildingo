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
  get anthropicApiKey() {
    return required("ANTHROPIC_API_KEY");
  },
  get firebaseServiceAccountPath() {
    return required("FIREBASE_SERVICE_ACCOUNT_PATH");
  },
  /** Where "contact us" (subscription) requests are emailed. */
  get contactEmail() {
    return process.env.CONTACT_EMAIL || null;
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
  },
};
