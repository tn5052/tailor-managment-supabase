-- 1. Fabric Inventory Table
CREATE TABLE public.fabric_inventory (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  fabric_code character varying(100) NOT NULL,
  brand_id uuid NULL, -- ADDED
  fabric_item_name character varying(255) NOT NULL, -- RENAMED for clarity from fabric_name
  category_id uuid NULL, -- ADDED (references inventory_categories.id for fabric type)
  shade_color character varying(100) NOT NULL,
  color_code character varying(50) NULL,
  unit_type character varying(20) NOT NULL DEFAULT 'meter'::character varying,
  quantity_available numeric(10,2) NOT NULL DEFAULT 0,
  minimum_stock_level numeric(10,2) NOT NULL DEFAULT 0,
  cost_per_unit numeric(10,2) NOT NULL DEFAULT 0,
  selling_price_per_unit numeric(10,2) NOT NULL DEFAULT 0,
  supplier_id uuid NULL, -- CHANGED to supplier_id
  purchase_date timestamp with time zone NULL,
  expiry_date timestamp with time zone NULL,
  storage_location character varying(255) NULL,
  fabric_width numeric(10,2) NULL,
  fabric_weight numeric(10,2) NULL,
  notes text NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT fabric_inventory_pkey PRIMARY KEY (id),
  CONSTRAINT fabric_inventory_fabric_code_tenant_unique UNIQUE (fabric_code, tenant_id),
  CONSTRAINT fabric_inventory_unit_type_check CHECK ((unit_type = ANY (ARRAY['meter'::character varying, 'gaz'::character varying, 'yard'::character varying, 'piece'::character varying]))) -- Added 'piece'
  -- Foreign key constraints will be added after brands table is created
);

-- 2. Accessories Inventory Table
CREATE TABLE public.accessories_inventory (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  accessory_code character varying(100) NOT NULL,
  accessory_item_name character varying(255) NOT NULL, -- RENAMED for clarity from accessory_name
  category_id uuid NULL, -- ADDED (references inventory_categories.id for accessory type)
  brand_id uuid NULL, -- ADDED
  color character varying(100) NULL,
  color_code character varying(50) NULL, -- ADDED for consistency
  size_specification character varying(100) NULL,
  unit_type character varying(50) NOT NULL DEFAULT 'piece'::character varying,
  quantity_available integer NOT NULL DEFAULT 0,
  minimum_stock_level integer NOT NULL DEFAULT 0,
  cost_per_unit numeric(10,2) NOT NULL DEFAULT 0,
  selling_price_per_unit numeric(10,2) NOT NULL DEFAULT 0,
  supplier_id uuid NULL, -- CHANGED to supplier_id
  purchase_date timestamp with time zone NULL,
  expiry_date timestamp with time zone NULL,
  storage_location character varying(255) NULL,
  notes text NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT accessories_inventory_pkey PRIMARY KEY (id),
  CONSTRAINT accessories_inventory_accessory_code_tenant_unique UNIQUE (accessory_code, tenant_id)
  -- Foreign key constraints will be added after brands table is created
);

-- 3. Inventory Transactions Table (Track stock movements)
CREATE TABLE public.inventory_transactions (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  transaction_type character varying(50) NOT NULL, -- purchase, sale, adjustment, transfer
  inventory_type character varying(20) NOT NULL, -- fabric, accessory
  inventory_item_id uuid NOT NULL,
  quantity_change numeric(10,2) NOT NULL, -- Positive for stock in, negative for stock out
  unit_cost numeric(10,2) NULL,
  total_amount numeric(10,2) NULL,
  reference_number character varying(100) NULL, -- Invoice number, order number, etc.
  reference_type character varying(50) NULL, -- invoice, order, adjustment, etc.
  reference_id uuid NULL, -- Link to invoice, order, etc.
  notes text NULL,
  transaction_date timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  created_by character varying(255) NOT NULL,
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT inventory_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT inventory_transactions_transaction_type_check CHECK ((transaction_type = ANY (ARRAY['purchase'::character varying, 'sale'::character varying, 'adjustment'::character varying, 'transfer'::character varying, 'return'::character varying]))),
  CONSTRAINT inventory_transactions_inventory_type_check CHECK ((inventory_type = ANY (ARRAY['fabric'::character varying, 'accessory'::character varying])))
);

-- 4. Inventory Categories Table (Optional for better organization)
CREATE TABLE public.inventory_categories (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  category_name character varying(255) NOT NULL,
  category_type character varying(20) NOT NULL, -- fabric, accessory
  description text NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT inventory_categories_pkey PRIMARY KEY (id),
  CONSTRAINT inventory_categories_name_type_tenant_unique UNIQUE (category_name, category_type, tenant_id),
  CONSTRAINT inventory_categories_category_type_check CHECK ((category_type = ANY (ARRAY['fabric'::character varying, 'accessory'::character varying])))
);

-- 5. Suppliers Table - FIXED
CREATE TABLE public.suppliers (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  supplier_name character varying(255) NOT NULL, -- ADDED missing column
  contact_person character varying(255) NULL,
  phone character varying(100) NULL,
  email character varying(255) NULL,
  address text NULL,
  supplier_type character varying(50) NOT NULL DEFAULT 'general'::character varying, -- fabric, accessory, general
  notes text NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  CONSTRAINT suppliers_pkey PRIMARY KEY (id),
  CONSTRAINT suppliers_name_tenant_unique UNIQUE (supplier_name, tenant_id)
);

-- NEW: Brands Table
CREATE TABLE public.brands (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  name character varying(255) NOT NULL,
  brand_type character varying(20) NOT NULL DEFAULT 'general'::character varying, -- fabric, accessory, general
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT brands_pkey PRIMARY KEY (id),
  CONSTRAINT brands_name_type_tenant_unique UNIQUE (name, brand_type, tenant_id),
  CONSTRAINT brands_brand_type_check CHECK ((brand_type = ANY (ARRAY['fabric'::character varying, 'accessory'::character varying, 'general'::character varying])))
);

-- Create Indexes for better performance - FIXED
CREATE INDEX IF NOT EXISTS idx_fabric_inventory_tenant_id ON public.fabric_inventory USING btree (tenant_id);
-- CREATE INDEX IF NOT EXISTS idx_fabric_inventory_brand_name ON public.fabric_inventory USING btree (brand_name); -- REMOVED - column doesn't exist
-- CREATE INDEX IF NOT EXISTS idx_fabric_inventory_fabric_type ON public.fabric_inventory USING btree (fabric_type); -- REMOVED - column doesn't exist
CREATE INDEX IF NOT EXISTS idx_fabric_inventory_is_active ON public.fabric_inventory USING btree (is_active);
CREATE INDEX IF NOT EXISTS idx_fabric_inventory_quantity ON public.fabric_inventory USING btree (quantity_available);

CREATE INDEX IF NOT EXISTS idx_accessories_inventory_tenant_id ON public.accessories_inventory USING btree (tenant_id);
-- CREATE INDEX IF NOT EXISTS idx_accessories_inventory_accessory_type ON public.accessories_inventory USING btree (accessory_type); -- REMOVED - column doesn't exist
CREATE INDEX IF NOT EXISTS idx_accessories_inventory_is_active ON public.accessories_inventory USING btree (is_active);
CREATE INDEX IF NOT EXISTS idx_accessories_inventory_quantity ON public.accessories_inventory USING btree (quantity_available);

CREATE INDEX IF NOT EXISTS idx_inventory_transactions_tenant_id ON public.inventory_transactions USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item_id ON public.inventory_transactions USING btree (inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_type ON public.inventory_transactions USING btree (transaction_type);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_date ON public.inventory_transactions USING btree (transaction_date);
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_reference ON public.inventory_transactions USING btree (reference_id);

CREATE INDEX IF NOT EXISTS idx_inventory_categories_tenant_id ON public.inventory_categories USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_categories_type ON public.inventory_categories USING btree (category_type);

CREATE INDEX IF NOT EXISTS idx_suppliers_tenant_id ON public.suppliers USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_type ON public.suppliers USING btree (supplier_type);

-- Create Foreign Key constraints for brands and categories to inventory tables
ALTER TABLE public.fabric_inventory
  ADD CONSTRAINT fabric_inventory_brand_id_fkey FOREIGN KEY (brand_id)
  REFERENCES public.brands(id) ON DELETE SET NULL,
  ADD CONSTRAINT fabric_inventory_category_id_fkey FOREIGN KEY (category_id)
  REFERENCES public.inventory_categories(id) ON DELETE SET NULL;

ALTER TABLE public.accessories_inventory
  ADD CONSTRAINT accessories_inventory_brand_id_fkey FOREIGN KEY (brand_id)
  REFERENCES public.brands(id) ON DELETE SET NULL,
  ADD CONSTRAINT accessories_inventory_category_id_fkey FOREIGN KEY (category_id)
  REFERENCES public.inventory_categories(id) ON DELETE SET NULL;

-- Add Foreign Key constraints for suppliers
ALTER TABLE public.fabric_inventory
  ADD CONSTRAINT fabric_inventory_supplier_id_fkey FOREIGN KEY (supplier_id)
  REFERENCES public.suppliers(id) ON DELETE SET NULL;

ALTER TABLE public.accessories_inventory
  ADD CONSTRAINT accessories_inventory_supplier_id_fkey FOREIGN KEY (supplier_id)
  REFERENCES public.suppliers(id) ON DELETE SET NULL;

-- Create Indexes for brands table
CREATE INDEX IF NOT EXISTS idx_brands_tenant_id ON public.brands USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_brands_name ON public.brands USING btree (name);
CREATE INDEX IF NOT EXISTS idx_brands_type ON public.brands USING btree (brand_type);

-- Index for new FKs in inventory tables
CREATE INDEX IF NOT EXISTS idx_fabric_inventory_brand_id ON public.fabric_inventory USING btree (brand_id);
CREATE INDEX IF NOT EXISTS idx_fabric_inventory_category_id ON public.fabric_inventory USING btree (category_id);
CREATE INDEX IF NOT EXISTS idx_accessories_inventory_brand_id ON public.accessories_inventory USING btree (brand_id);
CREATE INDEX IF NOT EXISTS idx_accessories_inventory_category_id ON public.accessories_inventory USING btree (category_id);

-- Remove the problematic foreign key constraints that were causing the error
-- ALTER TABLE public.fabric_inventory 
-- ADD CONSTRAINT fabric_inventory_category_fkey 
-- FOREIGN KEY (fabric_type) REFERENCES inventory_categories(category_name) ON DELETE SET NULL;

-- ALTER TABLE public.accessories_inventory 
-- ADD CONSTRAINT accessories_inventory_category_fkey 
-- FOREIGN KEY (accessory_type) REFERENCES inventory_categories(category_name) ON DELETE SET NULL;

-- Enable Row Level Security
ALTER TABLE public.fabric_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accessories_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
CREATE POLICY fabric_inventory_tenant_isolation ON public.fabric_inventory
  USING (tenant_id = auth.uid());

CREATE POLICY accessories_inventory_tenant_isolation ON public.accessories_inventory
  USING (tenant_id = auth.uid());

CREATE POLICY inventory_transactions_tenant_isolation ON public.inventory_transactions
  USING (tenant_id = auth.uid());

CREATE POLICY inventory_categories_tenant_isolation ON public.inventory_categories
  USING (tenant_id = auth.uid());

CREATE POLICY suppliers_tenant_isolation ON public.suppliers
  USING (tenant_id = auth.uid());

CREATE POLICY brands_tenant_isolation ON public.brands
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid()); -- Added WITH CHECK for inserts/updates

-- Fix RLS Policies to allow INSERT operations
DROP POLICY IF EXISTS brands_tenant_isolation ON public.brands;
CREATE POLICY brands_tenant_isolation ON public.brands
  FOR ALL
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

DROP POLICY IF EXISTS inventory_categories_tenant_isolation ON public.inventory_categories;
CREATE POLICY inventory_categories_tenant_isolation ON public.inventory_categories
  FOR ALL
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

DROP POLICY IF EXISTS suppliers_tenant_isolation ON public.suppliers;
CREATE POLICY suppliers_tenant_isolation ON public.suppliers
  FOR ALL
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

DROP POLICY IF EXISTS fabric_inventory_tenant_isolation ON public.fabric_inventory;
CREATE POLICY fabric_inventory_tenant_isolation ON public.fabric_inventory
  FOR ALL
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

DROP POLICY IF EXISTS accessories_inventory_tenant_isolation ON public.accessories_inventory;
CREATE POLICY accessories_inventory_tenant_isolation ON public.accessories_inventory
  FOR ALL
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

DROP POLICY IF EXISTS inventory_transactions_tenant_isolation ON public.inventory_transactions;
CREATE POLICY inventory_transactions_tenant_isolation ON public.inventory_transactions
  FOR ALL
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

-- Create triggers for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_fabric_inventory_updated_at 
  BEFORE UPDATE ON fabric_inventory 
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_accessories_inventory_updated_at 
  BEFORE UPDATE ON accessories_inventory 
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- CREATE TRIGGER for brands table
CREATE TRIGGER update_brands_updated_at
  BEFORE UPDATE ON public.brands
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

-- Insert some default categories
INSERT INTO public.inventory_categories (category_name, category_type, description, tenant_id) VALUES
('Cotton', 'fabric', 'Cotton fabrics', '00000000-0000-0000-0000-000000000000'),
('Silk', 'fabric', 'Silk fabrics', '00000000-0000-0000-0000-000000000000'),
('Polyester', 'fabric', 'Polyester fabrics', '00000000-0000-0000-0000-000000000000'),
('Linen', 'fabric', 'Linen fabrics', '00000000-0000-0000-0000-000000000000'),
('Wool', 'fabric', 'Wool fabrics', '00000000-0000-0000-0000-000000000000'),
('Button', 'accessory', 'Buttons and fasteners', '00000000-0000-0000-0000-000000000000'),
('Zipper', 'accessory', 'Zippers and closures', '00000000-0000-0000-0000-000000000000'),
('Thread', 'accessory', 'Sewing threads', '00000000-0000-0000-0000-000000000000'),
('Elastic', 'accessory', 'Elastic bands and materials', '00000000-0000-0000-0000-000000000000'),
('Lace', 'accessory', 'Lace and trims', '00000000-0000-0000-0000-000000000000');

-- Insert some default brands for each type
INSERT INTO public.brands (name, brand_type, tenant_id) VALUES
('Premium Cotton Co.', 'fabric', '00000000-0000-0000-0000-000000000000'),
('Silk Masters', 'fabric', '00000000-0000-0000-0000-000000000000'),
('Polyester Plus', 'fabric', '00000000-0000-0000-0000-000000000000'),
('ButtonCraft', 'accessory', '00000000-0000-0000-0000-000000000000'),
('ZipperPro', 'accessory', '00000000-0000-0000-0000-000000000000'),
('ThreadMaster', 'accessory', '00000000-0000-0000-0000-000000000000');
