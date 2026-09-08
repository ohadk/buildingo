export type UserRole = "super_admin" | "vaad" | "tenant";
export type AccountStatus = "active" | "suspended" | "deleted";
export type PaymentStatus = "pending" | "paid" | "overdue";
export type TicketStatus = "open" | "approved" | "in_progress" | "resolved" | "rejected";
export type InviteStatus = "pending" | "accepted" | "expired" | "revoked";
export type AgentExecutionStatus = "idle" | "triggered" | "communicating" | "resolved" | "failed";
export type DispatchChannel = "email" | "sms" | "whatsapp";

export interface AppUser {
  id: string;
  firebase_uid: string;
  phone_number: string;
  full_name: string;
  role: UserRole;
  building_id: string | null;
  apartment_id: string | null;
  num_occupants: number;
  lease_contract_path: string | null;
  avatar_path?: string | null;
  onboarded_at: string | null;
  is_active: boolean;
  account_status: AccountStatus;
  status_reason?: string | null;
  status_changed_at?: string | null;
  /** Soft-delete timestamp when account_status is deleted. */
  deleted_at?: string | null;
}

export type FeeMethod = "fixed" | "per_sqm";

export interface Building {
  id: string;
  name: string;
  address: string;
  city: string;
  country: string;
  postal_code: string | null;
  fee_method: FeeMethod;
  fixed_monthly_fee: number | null;
  price_per_sqm: number | null;
  bank_name: string | null;
  bank_branch: string | null;
  bank_account_number: string | null;
  is_active: boolean;
}

export interface Apartment {
  id: string;
  building_id: string;
  apartment_number: number;
  floor: number;
  parking_spots: string[];

  size_sqm: number | null;
  monthly_fee: number;
}

export interface Invitation {
  id: string;
  building_id: string;
  apartment_id: string;
  phone_number: string;
  role: UserRole;
  invite_code: string;
  status: InviteStatus;
  expires_at: string;
}

export interface VendorAgent {
  id: string;
  building_id: string;
  vendor_name: string;
  service_type: string;
  vendor_email: string | null;
  vendor_phone: string | null;
  preferred_channels: DispatchChannel[];
  contract_details: string | null;
  ai_instructions: string | null;
  is_active: boolean;
}

export interface Ticket {
  id: string;
  building_id: string;
  apartment_id: string | null;
  reported_by: string;
  title: string;
  description: string;
  image_path: string | null;
  status: TicketStatus;
  assigned_vendor_agent_id: string | null;
  agent_status: AgentExecutionStatus;
  agent_log: unknown[];
  created_at: string;
}

export interface TicketEvent {
  id: string;
  ticket_id: string;
  label: string;
  detail: string | null;
  created_at: string;
}
