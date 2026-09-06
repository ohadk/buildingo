import { redirect } from "next/navigation";

/** Alias for App Store / marketing links that prefer /contact. */
export default function ContactPage() {
  redirect("/support");
}
