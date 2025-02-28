-- Add tenant_id column to customers table
ALTER TABLE public.customers 
ADD COLUMN tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

CREATE INDEX idx_customers_tenant_id ON public.customers(tenant_id);

-- First drop the existing unique constraint that's causing conflicts
ALTER TABLE public.customers 
DROP CONSTRAINT customers_bill_number_key;

-- Create a new composite unique constraint including tenant_id
ALTER TABLE public.customers
ADD CONSTRAINT customers_bill_number_tenant_unique 
UNIQUE (bill_number, tenant_id);

-- Add tenant_id column to measurements table
ALTER TABLE public.measurements 
ADD COLUMN tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

CREATE INDEX idx_measurements_tenant_id ON public.measurements(tenant_id);

-- Add tenant_id column to invoices table
ALTER TABLE public.invoices 
ADD COLUMN tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

CREATE INDEX idx_invoices_tenant_id ON public.invoices(tenant_id);

-- Add tenant_id column to invoice_modifications table
ALTER TABLE public.invoice_modifications 
ADD COLUMN tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

CREATE INDEX idx_invoice_modifications_tenant_id ON public.invoice_modifications(tenant_id);

-- Add tenant_id column to complaints table
ALTER TABLE public.complaints 
ADD COLUMN tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

CREATE INDEX idx_complaints_tenant_id ON public.complaints(tenant_id);

-- Add tenant_id column to complaint_updates table
ALTER TABLE public.complaint_updates 
ADD COLUMN tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

CREATE INDEX idx_complaint_updates_tenant_id ON public.complaint_updates(tenant_id);

-- Create a row-level security policy for each table
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_modifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_updates ENABLE ROW LEVEL SECURITY;

-- Create policies that restrict access to only the tenant's data
CREATE POLICY customers_tenant_isolation ON public.customers
  USING (tenant_id = auth.uid());

CREATE POLICY measurements_tenant_isolation ON public.measurements
  USING (tenant_id = auth.uid());

CREATE POLICY invoices_tenant_isolation ON public.invoices
  USING (tenant_id = auth.uid());

CREATE POLICY invoice_modifications_tenant_isolation ON public.invoice_modifications
  USING (tenant_id = auth.uid());

CREATE POLICY complaints_tenant_isolation ON public.complaints
  USING (tenant_id = auth.uid());

CREATE POLICY complaint_updates_tenant_isolation ON public.complaint_updates
  USING (tenant_id = auth.uid());
