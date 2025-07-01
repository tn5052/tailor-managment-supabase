-- Kandora Products Table for Tailor Management System
-- This table stores predefined kandora types with their fabric requirements

CREATE TABLE public.kandora_products (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  name character varying(100) NOT NULL,
  fabric_yards_required numeric(3,1) NOT NULL,
  description text NULL,
  is_active boolean NOT NULL DEFAULT true,
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT kandora_products_pkey PRIMARY KEY (id),
  CONSTRAINT kandora_products_name_tenant_unique UNIQUE (name, tenant_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_kandora_products_tenant_id ON public.kandora_products USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_kandora_products_is_active ON public.kandora_products USING btree (is_active);
CREATE INDEX IF NOT EXISTS idx_kandora_products_name ON public.kandora_products USING btree (name);

-- Enable Row Level Security
ALTER TABLE public.kandora_products ENABLE ROW LEVEL SECURITY;

-- Create RLS Policy
CREATE POLICY kandora_products_tenant_isolation ON public.kandora_products
  FOR ALL
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

-- Create trigger for updating timestamps
CREATE TRIGGER update_kandora_products_updated_at
  BEFORE UPDATE ON public.kandora_products
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

-- Insert default kandora types
INSERT INTO public.kandora_products (name, fabric_yards_required, description, tenant_id) VALUES
('Adult Kandora', 3.5, 'Full size kandora for adults - requires 3.5 yards of fabric', '00000000-0000-0000-0000-000000000000'),
('Kids Kandora', 2.5, 'Kandora for children - requires 2.5 yards of fabric', '00000000-0000-0000-0000-000000000000');

COMMENT ON TABLE public.kandora_products IS 'Stores predefined kandora types with their fabric yard requirements for automatic fabric consumption calculation';
COMMENT ON COLUMN public.kandora_products.fabric_yards_required IS 'Amount of fabric in yards required to make this kandora type';
