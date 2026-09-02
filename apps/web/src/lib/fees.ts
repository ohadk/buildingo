export type FeeRules = {
  fee_method: string | null;
  fixed_monthly_fee: number | null;
  price_per_sqm: number | null;
};

export type ApartmentFeeInput = {
  monthly_fee: number;
  size_sqm: number | null;
};

/** Monthly Vaad fee for one apartment — always rounded up to whole shekels. */
export function monthlyFeeAmount(
  building: FeeRules | null,
  apartment: ApartmentFeeInput,
): number | null {
  if (building?.fee_method === "per_sqm" && building.price_per_sqm != null && apartment.size_sqm != null) {
    return Math.ceil(apartment.size_sqm * building.price_per_sqm);
  }
  if (building?.fee_method === "fixed" && building.fixed_monthly_fee != null) {
    return Math.ceil(building.fixed_monthly_fee);
  }
  if (apartment.monthly_fee > 0) return Math.ceil(apartment.monthly_fee);
  return null;
}

export function formatFeeSummary(building: FeeRules): string {
  if (building.fee_method === "per_sqm" && building.price_per_sqm != null) {
    return `${building.price_per_sqm} ₪ למ"ר (מעוגל למעלה לפי גודל הדירה)`;
  }
  if (building.fee_method === "fixed" && building.fixed_monthly_fee != null) {
    return `${Math.ceil(building.fixed_monthly_fee)} ₪ לחודש לדירה`;
  }
  return "לא הוגדר";
}

export function feeChangeAnnouncementBody(
  buildingName: string,
  building: FeeRules,
): { title: string; body: string } {
  const title = "עדכון דמי ועד הבית";
  const fee = formatFeeSummary(building);
  const body =
    building.fee_method === "per_sqm"
      ? `דמי הוועד ב${buildingName} עודכנו: ${fee}.\n` +
        `גודל הדירה נקבע לפי חשבון הארנונה. לשאלות — פנו לוועד.`
      : `דמי הוועד ב${buildingName} עודכנו: ${fee}.\n` +
        `לשאלות — פנו לוועד.`;
  return { title, body };
}
