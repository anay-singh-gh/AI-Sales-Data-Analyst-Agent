-- ============================================================
-- VENDOR SALES DATABASE — SCHEMA
-- Compatible with PostgreSQL / Supabase
-- ============================================================


-- ─────────────────────────────────────────────
-- DROP TABLES (for clean re-runs)
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS returns CASCADE;


-- ─────────────────────────────────────────────
-- 1. VENDORS
-- ─────────────────────────────────────────────
CREATE TABLE vendors (
    vendor_id     SERIAL PRIMARY KEY,
    vendor_name   VARCHAR(100) NOT NULL,
    contact_name  VARCHAR(100),
    email         VARCHAR(150) UNIQUE,
    phone         VARCHAR(20),
    address       TEXT,
    city          VARCHAR(80),
    country       VARCHAR(80) DEFAULT 'India',
    gstin         VARCHAR(20),
    created_at    TIMESTAMP DEFAULT NOW()
);

INSERT INTO vendors (vendor_name, contact_name, email, phone, address, city, country, gstin) VALUES
('TechMart Supplies Pvt. Ltd.', 'Rajesh Kumar',   'rajesh@techmart.in',    '+91-9800001111', '12, MG Road, Connaught Place',   'New Delhi',  'India', '07AABCT3518Q1ZV'),
('QuickShip Traders',           'Priya Sharma',   'priya@quickship.in',    '+91-9900002222', '45, Anna Salai',                  'Chennai',    'India', '33AADCQ2416H1ZX'),
('GlobalEdge Distributors',     'Amit Verma',     'amit@globaledge.in',    '+91-9700003333', '78, Linking Road, Bandra',        'Mumbai',     'India', '27AABCG1234K1ZP');


-- ─────────────────────────────────────────────
-- 2. EMPLOYEES (Sales Reps)
-- ─────────────────────────────────────────────
CREATE TABLE employees (
    employee_id   SERIAL PRIMARY KEY,
    vendor_id     INT REFERENCES vendors(vendor_id),
    first_name    VARCHAR(60) NOT NULL,
    last_name     VARCHAR(60) NOT NULL,
    email         VARCHAR(150) UNIQUE,
    phone         VARCHAR(20),
    role          VARCHAR(50) DEFAULT 'Sales Representative',
    hire_date     DATE,
    salary        NUMERIC(10,2),
    is_active     BOOLEAN DEFAULT TRUE
);

INSERT INTO employees (vendor_id, first_name, last_name, email, phone, role, hire_date, salary) VALUES
(1, 'Arjun',   'Mehta',   'arjun.mehta@techmart.in',    '+91-9811001111', 'Sales Manager',         '2020-03-15', 75000),
(1, 'Sneha',   'Joshi',   'sneha.joshi@techmart.in',    '+91-9811002222', 'Sales Representative',  '2021-07-01', 45000),
(1, 'Rohan',   'Das',     'rohan.das@techmart.in',      '+91-9811003333', 'Sales Representative',  '2022-01-10', 42000),
(2, 'Divya',   'Nair',    'divya.nair@quickship.in',    '+91-9911001111', 'Sales Manager',         '2019-06-20', 70000),
(2, 'Kiran',   'Pillai',  'kiran.pillai@quickship.in',  '+91-9911002222', 'Sales Representative',  '2021-11-05', 44000),
(3, 'Meera',   'Iyer',    'meera.iyer@globaledge.in',   '+91-9711001111', 'Sales Manager',         '2018-09-01', 80000),
(3, 'Siddharth','Rao',    'sid.rao@globaledge.in',      '+91-9711002222', 'Sales Representative',  '2022-05-15', 43000);


-- ─────────────────────────────────────────────
-- 3. CATEGORIES
-- ─────────────────────────────────────────────
CREATE TABLE categories (
    category_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    description   TEXT,
    parent_id     INT REFERENCES categories(category_id)
);

INSERT INTO categories (name, description, parent_id) VALUES
('Electronics',       'Electronic devices and accessories',  NULL),
('Computers',         'Laptops, desktops, and accessories',  1),
('Mobile Phones',     'Smartphones and accessories',         1),
('Peripherals',       'Keyboards, mice, monitors',           1),
('Office Supplies',   'Stationery and office equipment',     NULL),
('Furniture',         'Office furniture and fixtures',       NULL),
('Networking',        'Routers, switches, cables',           1);


-- ─────────────────────────────────────────────
-- 4. PRODUCTS
-- ─────────────────────────────────────────────
CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    vendor_id     INT REFERENCES vendors(vendor_id),
    category_id   INT REFERENCES categories(category_id),
    product_name  VARCHAR(200) NOT NULL,
    sku           VARCHAR(50) UNIQUE,
    description   TEXT,
    unit_price    NUMERIC(10,2) NOT NULL,
    cost_price    NUMERIC(10,2),
    tax_rate      NUMERIC(5,2) DEFAULT 18.00,  -- GST %
    unit          VARCHAR(20) DEFAULT 'piece',
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT NOW()
);


-- ─────────────────────────────────────────────
-- 5. INVENTORY
-- ─────────────────────────────────────────────
CREATE TABLE inventory (
    inventory_id     SERIAL PRIMARY KEY,
    product_id       INT REFERENCES products(product_id) UNIQUE,
    quantity_on_hand INT DEFAULT 0,
    reorder_level    INT DEFAULT 10,
    reorder_quantity INT DEFAULT 50,
    last_restocked   DATE,
    warehouse        VARCHAR(100)
);


-- ─────────────────────────────────────────────
-- 6. CUSTOMERS
-- ─────────────────────────────────────────────
CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    company_name  VARCHAR(150),
    contact_name  VARCHAR(100) NOT NULL,
    email         VARCHAR(150) UNIQUE,
    phone         VARCHAR(20),
    address       TEXT,
    city          VARCHAR(80),
    state         VARCHAR(80),
    pincode       VARCHAR(10),
    gstin         VARCHAR(20),
    customer_type VARCHAR(30) DEFAULT 'Business',  -- Business / Individual
    created_at    TIMESTAMP DEFAULT NOW()
);


-- ─────────────────────────────────────────────
-- 7. ORDERS
-- ─────────────────────────────────────────────
CREATE TABLE orders (
    order_id        SERIAL PRIMARY KEY,
    customer_id     INT REFERENCES customers(customer_id),
    employee_id     INT REFERENCES employees(employee_id),
    vendor_id       INT REFERENCES vendors(vendor_id),
    order_date      TIMESTAMP DEFAULT NOW(),
    expected_date   DATE,
    shipped_date    DATE,
    status          VARCHAR(30) DEFAULT 'Pending',
    -- Pending / Confirmed / Shipped / Delivered / Cancelled
    shipping_address TEXT,
    payment_terms   VARCHAR(50) DEFAULT 'Net 30',
    notes           TEXT,
    discount_pct    NUMERIC(5,2) DEFAULT 0,
    created_at      TIMESTAMP DEFAULT NOW()
);


-- ─────────────────────────────────────────────
-- 8. ORDER ITEMS
-- ─────────────────────────────────────────────
CREATE TABLE order_items (
    item_id       SERIAL PRIMARY KEY,
    order_id      INT REFERENCES orders(order_id),
    product_id    INT REFERENCES products(product_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL,
    discount_pct  NUMERIC(5,2) DEFAULT 0,
    tax_rate      NUMERIC(5,2) DEFAULT 18.00,
    -- Computed columns (stored for reporting)
    subtotal      NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    tax_amount    NUMERIC(12,2) GENERATED ALWAYS AS (ROUND(quantity * unit_price * tax_rate / 100, 2)) STORED,
    total_amount  NUMERIC(12,2) GENERATED ALWAYS AS (ROUND(quantity * unit_price * (1 + tax_rate/100), 2)) STORED
);


-- ─────────────────────────────────────────────
-- 9. PAYMENTS
-- ─────────────────────────────────────────────
CREATE TABLE payments (
    payment_id     SERIAL PRIMARY KEY,
    order_id       INT REFERENCES orders(order_id),
    payment_date   TIMESTAMP,
    amount         NUMERIC(12,2),
    payment_method VARCHAR(50),
    -- Bank Transfer / UPI / Credit Card / Cheque / Cash
    reference_no   VARCHAR(100),
    status         VARCHAR(30) DEFAULT 'Completed',
    -- Completed / Pending / Failed / Refunded
    notes          TEXT
);


-- ─────────────────────────────────────────────
-- 10. RETURNS
-- ─────────────────────────────────────────────
CREATE TABLE returns (
    return_id      SERIAL PRIMARY KEY,
    order_id       INT REFERENCES orders(order_id),
    product_id     INT REFERENCES products(product_id),
    quantity       INT NOT NULL,
    return_date    TIMESTAMP DEFAULT NOW(),
    reason         VARCHAR(200),
    status         VARCHAR(30) DEFAULT 'Initiated',
    -- Initiated / Approved / Refunded / Rejected
    refund_amount  NUMERIC(12,2),
    notes          TEXT
);


-- ─────────────────────────────────────────────
-- USEFUL VIEWS
-- ─────────────────────────────────────────────

-- View: Order Summary with totals
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    c.company_name,
    c.contact_name      AS customer,
    v.vendor_name,
    CONCAT(e.first_name, ' ', e.last_name) AS sales_rep,
    o.order_date::DATE,
    o.status,
    COUNT(oi.item_id)   AS line_items,
    SUM(oi.subtotal)    AS subtotal,
    SUM(oi.tax_amount)  AS total_tax,
    SUM(oi.total_amount)AS grand_total,
    o.discount_pct
FROM orders o
JOIN customers  c ON o.customer_id  = c.customer_id
JOIN vendors    v ON o.vendor_id    = v.vendor_id
JOIN employees  e ON o.employee_id  = e.employee_id
JOIN order_items oi ON o.order_id   = oi.order_id
GROUP BY o.order_id, c.company_name, c.contact_name,
         v.vendor_name, e.first_name, e.last_name,
         o.order_date, o.status, o.discount_pct;

-- View: Product sales performance
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT
    p.product_id,
    p.product_name,
    cat.name           AS category,
    p.unit_price,
    COALESCE(SUM(oi.quantity),   0) AS total_units_sold,
    COALESCE(SUM(oi.subtotal),   0) AS total_revenue,
    COALESCE(SUM(oi.tax_amount), 0) AS total_tax_collected,
    i.quantity_on_hand AS stock_remaining
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders      o  ON oi.order_id  = o.order_id AND o.status != 'Cancelled'
LEFT JOIN categories  cat ON p.category_id = cat.category_id
LEFT JOIN inventory   i  ON p.product_id = i.product_id
GROUP BY p.product_id, p.product_name, cat.name, p.unit_price, i.quantity_on_hand;

-- View: Monthly revenue
CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT
    TO_CHAR(o.order_date, 'YYYY-MM') AS month,
    v.vendor_name,
    COUNT(DISTINCT o.order_id)        AS total_orders,
    SUM(oi.subtotal)                  AS revenue,
    SUM(oi.tax_amount)                AS tax_collected,
    SUM(oi.total_amount)              AS gross_total
FROM orders o
JOIN vendors     v  ON o.vendor_id = v.vendor_id
JOIN order_items oi ON o.order_id  = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Pending')
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM'), v.vendor_name
ORDER BY month DESC;


-- ─────────────────────────────────────────────
-- QUICK VERIFY
-- ─────────────────────────────────────────────
SELECT 'vendors'     AS table_name, COUNT(*) AS rows FROM vendors
UNION ALL
SELECT 'employees',    COUNT(*) FROM employees
UNION ALL
SELECT 'categories',   COUNT(*) FROM categories
UNION ALL
SELECT 'products',     COUNT(*) FROM products
UNION ALL
SELECT 'inventory',    COUNT(*) FROM inventory
UNION ALL
SELECT 'customers',    COUNT(*) FROM customers
UNION ALL
SELECT 'orders',       COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',  COUNT(*) FROM order_items
UNION ALL
SELECT 'payments',     COUNT(*) FROM payments
UNION ALL
SELECT 'returns',      COUNT(*) FROM returns;
