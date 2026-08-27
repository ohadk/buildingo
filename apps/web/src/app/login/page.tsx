"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  RecaptchaVerifier,
  signInWithPhoneNumber,
  type ConfirmationResult,
} from "firebase/auth";
import { firebaseClientAuth } from "@/lib/firebase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input, Label } from "@/components/ui/input";
import { PhoneInput, isValidPhone } from "@/components/ui/phone-input";
import { formatPhoneDisplay } from "@/lib/format";

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [stage, setStage] = useState<"phone" | "otp">("phone");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const confirmationRef = useRef<ConfirmationResult | null>(null);
  const verifierRef = useRef<RecaptchaVerifier | null>(null);

  async function sendCode() {
    setBusy(true);
    setError(null);
    try {
      const auth = firebaseClientAuth();
      if (!verifierRef.current) {
        verifierRef.current = new RecaptchaVerifier(auth, "recaptcha-container", {
          size: "invisible",
        });
      }
      confirmationRef.current = await signInWithPhoneNumber(auth, phone, verifierRef.current);
      setStage("otp");
    } catch (e) {
      setError(e instanceof Error ? e.message : "שליחת הקוד נכשלה");
    } finally {
      setBusy(false);
    }
  }

  async function verifyCode(otp: string = code) {
    setBusy(true);
    setError(null);
    try {
      const credential = await confirmationRef.current!.confirm(otp);
      const idToken = await credential.user.getIdToken();

      // Token exchange: verify on the server, upsert the Supabase user
      // row, and mint the session cookie.
      const res = await fetch("/api/auth/session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ idToken }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "הכניסה נכשלה");

      if (data.user.role === "super_admin") {
        router.push("/admin");
      } else {
        setError("הממשק הזה מיועד למנהלי המערכת בלבד. דיירים וחברי ועד — היכנסו דרך אפליקציית דירה.");
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "קוד שגוי");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="hero-wash flex min-h-screen items-center justify-center px-6">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="text-2xl">כניסה לדירה</CardTitle>
          <p className="text-sm text-ink-600">נשלח לך קוד חד־פעמי ב-SMS.</p>
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
                {busy ? "שולח…" : "שלח קוד"}
              </Button>
            </>
          ) : (
            <>
              <div className="space-y-2">
                <Label htmlFor="otp">
                  הזינו את הקוד בן 6 הספרות שנשלח אל{" "}
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
                    // Verification continues automatically at 6 digits.
                    if (digits.length === 6 && !busy) verifyCode(digits);
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
              <Button variant="ghost" className="w-full" onClick={() => setStage("phone")}>
                שימוש במספר אחר
              </Button>
            </>
          )}
          {error && <p className="text-sm text-brick-600">{error}</p>}
          <div id="recaptcha-container" />
        </CardContent>
      </Card>
    </main>
  );
}
