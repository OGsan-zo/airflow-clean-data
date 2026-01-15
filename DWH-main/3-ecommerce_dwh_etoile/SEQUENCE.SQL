CREATE SCHEMA IF NOT EXISTS ecommerce_dwh_star;

-- Séquence pour dim_payment_method
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_payment_method_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Séquence pour dim_product
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_product_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Séquence pour dim_category
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_category_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Séquence pour dim_client
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_client_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Séquence pour dim_date
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_date_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Séquence pour dim_inventory
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_inventory_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Séquence pour dim_sales
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_sales_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Séquence pour dim_payment
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_payment_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Séquence pour dim_customer (ajoutée ici pour corriger l'erreur récente)
CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_dim_customer_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

CREATE SEQUENCE IF NOT EXISTS ecommerce_dwh_star.seq_fact_sales_key
  START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
