/** +972547760683 → 054-776-0683 (Israeli numbers); others stay E.164. */
export function formatPhoneDisplay(e164: string) {
  const il = e164.match(/^\+972(\d{2})(\d{3})(\d{4})$/);
  return il ? `0${il[1]}-${il[2]}-${il[3]}` : e164;
}

export function formatDateHe(iso: string) {
  return new Date(iso).toLocaleDateString("he-IL", { day: "numeric", month: "short", year: "numeric" });
}
