-- Drop the table if it exists to ensure a clean setup
DROP TABLE IF EXISTS public.new_complaints;

-- Create the new_complaints table with the correct tenant reference
CREATE TABLE public.new_complaints (
  id uuid not null default extensions.uuid_generate_v4 (),
  customer_id uuid not null,
  invoice_id uuid null,
  title text not null,
  description text null,
  status text not null default 'pending'::text,
  priority text not null default 'medium'::text,
  assigned_to text null,
  resolution_details text null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  resolved_at timestamp with time zone null,
  tenant_id uuid not null,
  constraint new_complaints_pkey primary key (id),
  constraint new_complaints_customer_id_fkey foreign KEY (customer_id) references customers (id) on delete CASCADE,
  constraint new_complaints_invoice_id_fkey foreign KEY (invoice_id) references invoices (id) on delete set null,
  constraint new_complaints_tenant_id_fkey foreign KEY (tenant_id) references auth.users (id)
) TABLESPACE pg_default;

-- Enable Row Level Security
ALTER TABLE public.new_complaints ENABLE ROW LEVEL SECURITY;

-- Create a policy to allow authenticated users to access their own data
CREATE POLICY "Allow all access for authenticated users"
ON public.new_complaints
FOR ALL
TO authenticated
USING (tenant_id = auth.uid())
WITH CHECK (tenant_id = auth.uid());

-- Grant permissions
GRANT ALL ON TABLE public.new_complaints TO authenticated, service_role;
