-- Add family-related columns to customers table
alter table customers 
add column family_id uuid references customers(id),
add column family_relation text check (family_relation in ('parent', 'spouse', 'child', 'sibling', 'other')),
-- Add index for faster family queries
create index idx_customers_family_id on customers(family_id);

-- Add trigger to ensure valid family relations
create or replace function validate_family_relation()
returns trigger as $$
begin
  -- Prevent self-referential family links
  if NEW.family_id = NEW.id then
    raise exception 'A customer cannot be their own family member';
  end if;
  
  -- Ensure reciprocal family relationships
  if NEW.family_id is not null and NEW.family_relation = 'spouse' then
    -- For spouses, ensure bidirectional relationship
    update customers 
    set family_id = NEW.id,
        family_relation = 'spouse'
    where id = NEW.family_id
      and (family_id is null or family_id = NEW.id);
  end if;
  
  return NEW;
end;
$$ language plpgsql;

create trigger check_family_relation
before insert or update on customers
for each row
execute function validate_family_relation();
