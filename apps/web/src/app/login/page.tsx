"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  RecaptchaVerifier,
  signInWithCustomToken,
  signInWithPhoneNumber,
  type ConfirmationResult,
} from "firebase/auth";
import { firebaseClientAuth } from "@/lib/firebase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input, Label } from "@/components/ui/input";
import { PhoneInput, isValidPhone } from "@/components/ui/phone-input";
import { formatPhoneDisplay } from "@/lib/format";

type Delivery = "whatsapp" | "sms";
type Stage = "phone" | "otp";

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [stage, setStage] = useState<Stage>("phone");
  const [delivery, setDelivery] = useState<Delivery>("whatsapp");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const confirmationRef = useRef<ConfirmationResult | null>(null);
  const verifierRef = useRef<RecaptchaVerifier | null>(null);

  async function exchangeSession() {
    const auth = firebaseClientAuth();
    const idToken = await auth.currentUser!.getIdToken();
    const res = await fetch("/api/auth/session", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken }),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error ?? "הכניסה נכשלה");

    if (data.user.role === "super_admin") {
      router.push("/admin");
      return;
    }
    setError(
      "הממשק הזה מיועד למנהלי המערכת בלבד. דיירים וחברי ועד — היכנסו דרך אפליקציית Buildingo.",
    );
  }

  async function sendWhatsAppCode() {
    const res = await fetch("/api/auth/otp/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ phone, channel: "whatsapp" }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      if (res.status === 429) {
        throw new Error("יש להמתין לפני שליחת קוד נוסף");
      }
      throw new Error(data.error ?? "שליחת קוד בוואטסאפ נכשלה");
    }
    confirmationRef.current = null;
    setStage("otp");
  }

  async function sendSmsCode() {
    const auth = firebaseClientAuth();
    if (!verifierRef.current) {
      verifierRef.current = new RecaptchaVerifier(auth, "recaptcha-container", {
        size: "invisible",
      });
    }
    confirmationRef.current = await signInWithPhoneNumber(
      auth,
      phone,
      verifierRef.current,
    );
    setStage("otp");
  }

  async function sendCode() {
    setBusy(true);
    setError(null);
    try {
      if (delivery === "whatsapp") {
        await sendWhatsAppCode();
      } else {
        await sendSmsCode();
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "שליחת הקוד נכשלה");
      // Reset captcha so the next SMS attempt can recreate it.
      try {
        verifierRef.current?.clear();
      } catch {
        /* ignore */
      }
      verifierRef.current = null;
    } finally {
      setBusy(false);
    }
  }

  async function verifyWhatsApp(otp: string) {
    const res = await fetch("/api/auth/otp/verify", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ phone, code: otp }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new Error(data.error ?? "קוד שגוי");
    }
    if (!data.customToken) throw new Error("חסר אסימון התחברות");
    await signInWithCustomToken(firebaseClientAuth(), data.customToken);
    await exchangeSession();
  }

  async function verifySms(otp: string) {
    await confirmationRef.current!.confirm(otp);
    await exchangeSession();
  }

  async function verifyCode(otp: string = code) {
    if (otp.length !== 6 || busy) return;
    setBusy(true);
    setError(null);
    try {
      if (delivery === "whatsapp") {
        await verifyWhatsApp(otp);
      } else {
        await verifySms(otp);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "קוד שגוי");
    } finally {
      setBusy(false);
    }
  }

  function resetToPhone() {
    setStage("phone");
    setCode("");
    setError(null);
    confirmationRef.current = null;
  }

  return (
    <main className="hero-wash flex min-h-screen items-center justify-center px-6">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="text-2xl">כניסת מנהל מערכת</CardTitle>
          <p className="text-sm text-ink-600">
            {delivery === "whatsapp"
              ? "נשלח לך קוד חד־פעמי בוואטסאפ."
              : "נשלח לך קוד חד־פעמי ב-SMS."}
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          {stage === "phone" ? (
            <>
              <div className="space-y-2">
                <Label>מספר טלפון</Label>
                <PhoneInput autoFocus onChange={setPhone} />
              </div>
              <Button
                className="w-full"
                onClick={sendCode}
                disabled={busy || !isValidPhone(phone)}
              >
                {busy
                  ? "שולח…"
                  : delivery === "whatsapp"
                    ? "שלחו קוד בוואטסאפ"
                    : "שלחו קוד ב-SMS"}
              </Button>
              <Button
                type="button"
                variant="ghost"
                className="w-full text-sm"
                disabled={busy}
                onClick={() =>
                  setDelivery((d) => (d === "whatsapp" ? "sms" : "whatsapp"))
                }
              >
                {delivery === "whatsapp"
                  ? "שלחו ב-SMS במקום"
                  : "שלחו בוואטסאפ במקום"}
              </Button>
            </>
          ) : (
            <>
              <div className="space-y-2">
                <Label htmlFor="otp">
                  הזינו את הקוד בן 6 הספרות שנשלח{" "}
                  {delivery === "whatsapp" ? "בוואטסאפ" : "ב-SMS"} אל{" "}
                  <bdi dir="ltr">{formatPhoneDisplay(phone)}</bdi>
                </Label>
                <Input
                  id="otp"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  autoFocus
                  dir="ltr"
                  maxLength={6}
                  value={code}
                  onChange={(e) => {
                    const digits = e.target.value.replace(/\D/g, "").slice(0, 6);
                    setCode(digits);
                    if (digits.length === 6) void verifyCode(digits);
                  }}
                />
              </div>
              <Button
                className="w-full"
                onClick={() => verifyCode()}
                disabled={busy || code.length !== 6}
              >
                {busy ? "מאמת…" : "אימות וכניסה"}
              </Button>
              <Button variant="ghost" className="w-full" onClick={resetToPhone}>
                שימוש במספר אחר
              </Button>
            </>
          )}
          {error && <p className="text-sm text-brick-600">{error}</p>}
          {/* Required for Firebase SMS fallback only */}
          <div id="recaptcha-container" />
        </CardContent>
      </Card>
    </main>
  );
}
