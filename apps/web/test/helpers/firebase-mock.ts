type Decoded = { uid: string; phone_number: string };

const tokens = new Map<string, Decoded>();

/** Issue a fake Firebase ID token for API tests (Bearer or session exchange). */
export function issueTestIdToken(phone: string, uid = `uid-${phone}`): string {
  const token = `test-id-token:${phone}:${uid}`;
  tokens.set(token, { uid, phone_number: phone });
  return token;
}

export function resetFirebaseTokens() {
  tokens.clear();
}

export function adminAuth() {
  return {
    async verifyIdToken(idToken: string, _checkRevoked?: boolean): Promise<Decoded> {
      const decoded = tokens.get(idToken);
      if (!decoded) {
        throw Object.assign(new Error("Firebase ID token has expired or is invalid."), {
          code: "auth/argument-error",
        });
      }
      return decoded;
    },
    async createSessionCookie(_idToken: string, _options: { expiresIn: number }) {
      return "test-session-cookie";
    },
  };
}
