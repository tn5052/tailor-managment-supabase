Here are the SQL queries Examples (jes se m ne Supabase m Tables bnay):

1. complaint_updates Table
Create complaint_updates Table

CREATE TABLE public.complaint_updates (
  id uuid NOT NULL,
  complaint_id uuid NOT NULL,
  comment text NOT NULL,
  timestamp timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_by text NOT NULL,
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT complaint_updates_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS complaint_updates_complaint_id_idx ON public.complaint_updates USING btree (complaint_id);
CREATE INDEX IF NOT EXISTS idx_complaint_updates_tenant_id ON public.complaint_updates USING btree (tenant_id);

2. complaints Table
Create complaints Table

CREATE TABLE public.complaints (
  id uuid NOT NULL,
  customer_id uuid NOT NULL,
  invoice_id uuid NULL,
  title text NOT NULL,
  description text NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text,
  priority text NOT NULL DEFAULT 'medium'::text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  resolved_at timestamp with time zone NULL,
  assigned_to text NOT NULL,
  updates jsonb[] NULL DEFAULT ARRAY[]::jsonb[],
  attachments text[] NULL DEFAULT ARRAY[]::text[],
  refund_amount numeric(10,2) NULL,
  refunded_at timestamp with time zone NULL,
  refund_reason text NULL,
  refund_status text NULL,
  refund_requested_at timestamp with time zone NULL,
  refund_completed_at timestamp with time zone NULL,
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT complaints_pkey PRIMARY KEY (id),
  CONSTRAINT complaints_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT complaints_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id),
  CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  CONSTRAINT fk_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS complaints_customer_id_idx ON public.complaints USING btree (customer_id);
CREATE INDEX IF NOT EXISTS complaints_status_idx ON public.complaints USING btree (status);
CREATE INDEX IF NOT EXISTS complaints_assigned_to_idx ON public.complaints USING btree (assigned_to);
CREATE INDEX IF NOT EXISTS idx_complaints_tenant_id ON public.complaints USING btree (tenant_id);

3. customers Table
Create customers Table

CREATE TABLE public.customers (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  bill_number character varying NOT NULL,
  name character varying NOT NULL,
  phone character varying NOT NULL,
  whatsapp character varying NULL,
  address character varying NOT NULL,
  gender character varying NOT NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  referred_by uuid NULL,
  referral_count integer NULL DEFAULT 0,
  family_id uuid NULL,
  family_relation text NULL,
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT customers_pkey PRIMARY KEY (id),
  CONSTRAINT customers_bill_number_tenant_unique UNIQUE (bill_number, tenant_id),
  CONSTRAINT customers_family_id_fkey FOREIGN KEY (family_id) REFERENCES customers(id),
  CONSTRAINT customers_referred_by_fkey FOREIGN KEY (referred_by) REFERENCES customers(id),
  CONSTRAINT customers_family_relation_check CHECK ((family_relation = ANY (ARRAY['parent'::text, 'spouse'::text, 'child'::text, 'sibling'::text, 'other'::text]))),
  CONSTRAINT customers_gender_check CHECK (((gender)::text = ANY ((ARRAY['male'::character varying, 'female'::character varying])::text[])))
);
CREATE INDEX IF NOT EXISTS idx_customer_referrals ON public.customers USING btree (referred_by);
CREATE INDEX IF NOT EXISTS idx_customers_family_id ON public.customers USING btree (family_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_id ON public.customers USING btree (tenant_id);

4. invoice_modifications Table
Create invoice_modifications Table

CREATE TABLE public.invoice_modifications (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  invoice_id uuid NULL,
  modified_at timestamp with time zone NULL,
  reason text NULL,
  previous_status jsonb NULL,
  changes jsonb NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT invoice_modifications_pkey PRIMARY KEY (id),
  CONSTRAINT invoice_modifications_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id)
);
CREATE INDEX IF NOT EXISTS idx_invoice_modifications_tenant_id ON public.invoice_modifications USING btree (tenant_id);

5. invoices Table
Create invoices Table

CREATE TABLE public.invoices (
  id uuid NOT NULL,
  invoice_number character varying NOT NULL,
  date timestamp with time zone NOT NULL,
  delivery_date timestamp with time zone NOT NULL,
  amount numeric NOT NULL,
  vat numeric NOT NULL,
  amount_including_vat numeric NOT NULL,
  net_total numeric NOT NULL,
  advance numeric NOT NULL,
  balance numeric NOT NULL,
  customer_id uuid NOT NULL,
  customer_name character varying NOT NULL,
  customer_phone character varying NOT NULL,
  details text NULL,
  customer_bill_number character varying NOT NULL,
  measurement_id uuid NULL,
  measurement_name character varying NULL,
  delivery_status character varying NOT NULL,
  payment_status character varying NOT NULL,
  delivered_at timestamp with time zone NULL,
  paid_at timestamp with time zone NULL,
  notes text[] NULL,
  payments jsonb[] NULL DEFAULT '{}'::jsonb[],
  is_delivered boolean NOT NULL DEFAULT false,
  products jsonb[] NULL DEFAULT '{}'::jsonb[],
  last_modified_at timestamp with time zone NULL,
  last_modified_reason text NULL,
  refund_amount numeric(10,2) NULL,
  refunded_at timestamp with time zone NULL,
  refund_reason text NULL,
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT invoices_pkey PRIMARY KEY (id),
  CONSTRAINT invoices_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_id ON public.invoices USING btree (tenant_id);

6. measurements Table
Create measurements Table

CREATE TABLE public.measurements (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  customer_id uuid NULL,
  bill_number character varying(255) NOT NULL,
  style character varying(50) NOT NULL,
  design_type character varying(50) NOT NULL DEFAULT 'Aadi'::character varying,
  tarboosh_type character varying(50) NOT NULL DEFAULT 'Fixed'::character varying,
  fabric_name text NULL,
  length_arabi numeric(10,2) NULL DEFAULT 0,
  length_kuwaiti numeric(10,2) NULL DEFAULT 0,
  chest numeric(10,2) NULL DEFAULT 0,
  width numeric(10,2) NULL DEFAULT 0,
  sleeve numeric(10,2) NULL DEFAULT 0,
  collar numeric(10,2) NULL DEFAULT 0,
  under numeric(10,2) NULL DEFAULT 0,
  back_length numeric(10,2) NULL DEFAULT 0,
  neck numeric(10,2) NULL DEFAULT 0,
  shoulder numeric(10,2) NULL DEFAULT 0,
  seam character varying(255) NULL,
  adhesive character varying(255) NULL,
  under_kandura character varying(255) NULL,
  tarboosh character varying(255) NULL,
  open_sleeve character varying(255) NULL,
  stitching character varying(255) NULL,
  pleat character varying(255) NULL,
  button character varying(255) NULL,
  cuff character varying(255) NULL,
  embroidery character varying(255) NULL,
  neck_style character varying(255) NULL,
  notes text NULL,
  date timestamp with time zone NULL DEFAULT CURRENT_TIMESTAMP,
  last_updated timestamp with time zone NULL DEFAULT CURRENT_TIMESTAMP,
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT measurements_pkey1 PRIMARY KEY (id),
  CONSTRAINT measurements_customer_id_fkey1 FOREIGN KEY (customer_id) REFERENCES customers(id)
);
CREATE INDEX IF NOT EXISTS idx_measurements_tenant_id ON public.measurements USING btree (tenant_id);

-- Row Level Security Policies
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_modifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaint_updates ENABLE ROW LEVEL SECURITY;

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


services files :
 - lib/services/customer_service.dart
 - lib/services/measurement_service.dart
 - lib/services/invoice_service.dart
 - lib/services/complaint_service.dart
