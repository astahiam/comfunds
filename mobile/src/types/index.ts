/**
 * TypeScript Type Definitions
 */

export interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  address?: string;
  cooperative_id?: string;
  roles: string[];
  kyc_status?: 'pending' | 'verified' | 'rejected';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Cooperative {
  id: string;
  name: string;
  registration_number: string;
  address: string;
  phone: string;
  email: string;
  bank_account: string;
  profit_sharing_policy?: any;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Business {
  id: string;
  name: string;
  business_type: string;
  description?: string;
  owner_id: string;
  cooperative_id: string;
  registration_documents?: any;
  approval_status: 'pending' | 'approved' | 'rejected';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Project {
  id: string;
  title: string;
  description: string;
  business_id: string;
  funding_goal: number;
  minimum_funding?: number;
  current_funding: number;
  funding_deadline?: string;
  profit_sharing_ratio?: {
    investor: number;
    business: number;
  };
  project_type?: 'startup' | 'expansion' | 'equipment';
  status: 'draft' | 'submitted' | 'approved' | 'active' | 'funded' | 'closed';
  milestones?: any[];
  documents?: any[];
  created_at: string;
  updated_at: string;
}

export interface Investment {
  id: string;
  project_id: string;
  investor_id: string;
  amount: number;
  investment_date: string;
  profit_sharing_percentage?: number;
  status: 'pending' | 'confirmed' | 'refunded';
  transaction_ref?: string;
  created_at: string;
  updated_at: string;
}

export interface AuthResponse {
  status: string;
  message: string;
  data: {
    access_token: string;
    refresh_token?: string;
    user: User;
  };
}

export interface ApiResponse<T> {
  status: string;
  message: string;
  data?: T;
  error?: string;
}

