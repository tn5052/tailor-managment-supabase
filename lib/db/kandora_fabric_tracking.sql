-- Kandora Fabric Tracking Tables for Tailor Management System
-- This tracks which fabric is used for kandora orders and manages inventory deduction

-- Table to track kandora orders and their fabric consumption
CREATE TABLE public.kandora_orders (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  invoice_id uuid NOT NULL,
  kandora_product_id uuid NOT NULL,
  fabric_inventory_id uuid NOT NULL,
  fabric_yards_consumed numeric(4,2) NOT NULL,
  quantity integer NOT NULL DEFAULT 1,
  price_per_unit numeric(10,2) NOT NULL,
  total_price numeric(10,2) NOT NULL,
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT kandora_orders_pkey PRIMARY KEY (id),
  CONSTRAINT kandora_orders_kandora_product_fkey FOREIGN KEY (kandora_product_id) REFERENCES public.kandora_products(id),
  CONSTRAINT kandora_orders_invoice_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_kandora_orders_tenant_id ON public.kandora_orders USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_kandora_orders_invoice_id ON public.kandora_orders USING btree (invoice_id);
CREATE INDEX IF NOT EXISTS idx_kandora_orders_kandora_product_id ON public.kandora_orders USING btree (kandora_product_id);
CREATE INDEX IF NOT EXISTS idx_kandora_orders_fabric_inventory_id ON public.kandora_orders USING btree (fabric_inventory_id);

-- Enable Row Level Security
ALTER TABLE public.kandora_orders ENABLE ROW LEVEL SECURITY;

-- Create RLS Policy
CREATE POLICY kandora_orders_tenant_isolation ON public.kandora_orders
  FOR ALL
  USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

-- Create trigger for updating timestamps
CREATE TRIGGER update_kandora_orders_updated_at
  BEFORE UPDATE ON public.kandora_orders
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

-- Function to automatically deduct fabric from inventory when kandora is ordered
CREATE OR REPLACE FUNCTION public.deduct_fabric_for_kandora()
RETURNS TRIGGER AS $$
BEGIN
  -- Update fabric inventory by reducing the quantity
  UPDATE public.fabric_inventory 
  SET quantity_available = quantity_available - NEW.fabric_yards_consumed
  WHERE id = NEW.fabric_inventory_id 
  AND tenant_id = NEW.tenant_id;
  
  -- Check if update was successful
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Failed to deduct fabric from inventory. Fabric ID: %', NEW.fabric_inventory_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to restore fabric to inventory when kandora order is deleted
CREATE OR REPLACE FUNCTION public.restore_fabric_for_kandora()
RETURNS TRIGGER AS $$
BEGIN
  -- Restore fabric inventory by adding back the quantity
  UPDATE public.fabric_inventory 
  SET quantity_available = quantity_available + OLD.fabric_yards_consumed
  WHERE id = OLD.fabric_inventory_id 
  AND tenant_id = OLD.tenant_id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Triggers for automatic fabric inventory management
CREATE TRIGGER kandora_order_fabric_deduction
  AFTER INSERT ON public.kandora_orders
  FOR EACH ROW EXECUTE FUNCTION public.deduct_fabric_for_kandora();

CREATE TRIGGER kandora_order_fabric_restoration
  AFTER DELETE ON public.kandora_orders
  FOR EACH ROW EXECUTE FUNCTION public.restore_fabric_for_kandora();

-- View for easy kandora order reporting with fabric details
CREATE OR REPLACE VIEW public.kandora_orders_with_details AS
SELECT 
  ko.id,
  ko.invoice_id,
  ko.quantity,
  ko.price_per_unit,
  ko.total_price,
  ko.fabric_yards_consumed,
  ko.created_at,
  kp.name as kandora_name,
  kp.fabric_yards_required,
  fi.fabric_item_name,
  fi.shade_color,
  fi.fabric_code,
  i.invoice_number,
  i.customer_name
FROM public.kandora_orders ko
JOIN public.kandora_products kp ON ko.kandora_product_id = kp.id
JOIN public.fabric_inventory fi ON ko.fabric_inventory_id = fi.id
JOIN public.invoices i ON ko.invoice_id = i.id
WHERE ko.tenant_id = auth.uid();

COMMENT ON TABLE public.kandora_orders IS 'Tracks kandora orders and automatically manages fabric inventory deduction';
COMMENT ON COLUMN public.kandora_orders.fabric_yards_consumed IS 'Actual fabric yards consumed for this kandora order';
COMMENT ON VIEW public.kandora_orders_with_details IS 'Complete view of kandora orders with fabric and invoice details';
