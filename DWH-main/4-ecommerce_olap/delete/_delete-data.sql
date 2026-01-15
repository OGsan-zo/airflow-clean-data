-- Script pour vider ecommerce_dwh
DO $$
BEGIN
    -- Désactiver les contraintes temporairement
    SET CONSTRAINTS ALL DEFERRED;
    
    -- Vider les tables dans l'ordre inverse des dépendances
    TRUNCATE TABLE ecommerce_dwh.fact_sales RESTART IDENTITY CASCADE;
    TRUNCATE TABLE ecommerce_dwh.dim_customer RESTART IDENTITY CASCADE;
    TRUNCATE TABLE ecommerce_dwh.dim_payment_method RESTART IDENTITY CASCADE;
    TRUNCATE TABLE ecommerce_dwh.dim_product RESTART IDENTITY CASCADE;
    TRUNCATE TABLE ecommerce_dwh.dim_time RESTART IDENTITY CASCADE;
    TRUNCATE TABLE ecommerce_dwh.dim_date RESTART IDENTITY CASCADE;
    
    -- Comme ce schéma utilise SERIAL, RESTART IDENTITY suffit généralement,
    -- mais voici comment réinitialiser explicitement si nécessaire:
    PERFORM setval('ecommerce_dwh.dim_customer_customer_key_seq', 1, false);
    PERFORM setval('ecommerce_dwh.dim_payment_method_payment_method_key_seq', 1, false);
    PERFORM setval('ecommerce_dwh.dim_product_product_key_seq', 1, false);
    PERFORM setval('ecommerce_dwh.fact_sales_sale_key_seq', 1, false);
    
    RAISE NOTICE 'Toutes les tables du schéma ecommerce_dwh ont été vidées et les séquences réinitialisées';
END $$;