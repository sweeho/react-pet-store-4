-- EXTRACTED FROM LEGACY SOURCE — evidence of what exists, not a build target. Where this disagrees with a capability delta spec, the delta spec wins.

-- Locale reference table for multi-language support
CREATE TABLE locale (
    locale_code VARCHAR(10) PRIMARY KEY,
    language VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL
);

INSERT INTO locale VALUES ('en_US', 'English', 'United States');
INSERT INTO locale VALUES ('ja_JP', 'Japanese', 'Japan');
INSERT INTO locale VALUES ('zh_CN', 'Chinese', 'China');

-- Customer core entity
CREATE TABLE customer (
    user_id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Customer account and authentication
CREATE TABLE account (
    account_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    FOREIGN KEY (user_id) REFERENCES customer(user_id)
);

-- Customer profile preferences
CREATE TABLE profile (
    profile_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL UNIQUE,
    preferred_language VARCHAR(10) DEFAULT 'en_US',
    favorite_category VARCHAR(50),
    my_list_preference BOOLEAN DEFAULT FALSE,
    banner_preference BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES customer(user_id),
    FOREIGN KEY (preferred_language) REFERENCES locale(locale_code)
);

-- Contact information (reusable for billing/shipping)
CREATE TABLE contact_info (
    contact_id VARCHAR(50) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    street1 VARCHAR(255),
    street2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100),
    phone_number VARCHAR(20)
);

-- Credit card storage
CREATE TABLE credit_card (
    card_id VARCHAR(50) PRIMARY KEY,
    account_id VARCHAR(50) NOT NULL,
    card_number VARCHAR(20) NOT NULL,
    card_type VARCHAR(20) NOT NULL CHECK (card_type IN ('Visa', 'MasterCard', 'AmEx', 'Discover')),
    expiry_date VARCHAR(5) NOT NULL,
    FOREIGN KEY (account_id) REFERENCES account(account_id)
);

-- Product catalog entities
CREATE TABLE category (
    category_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Localized category information
CREATE TABLE category_details (
    category_detail_id VARCHAR(50) PRIMARY KEY,
    category_id VARCHAR(50) NOT NULL,
    locale_code VARCHAR(10) NOT NULL,
    localized_name VARCHAR(255) NOT NULL,
    localized_description TEXT,
    FOREIGN KEY (category_id) REFERENCES category(category_id),
    FOREIGN KEY (locale_code) REFERENCES locale(locale_code),
    UNIQUE (category_id, locale_code)
);

-- Products within categories
CREATE TABLE product (
    product_id VARCHAR(50) PRIMARY KEY,
    category_id VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- Localized product information
CREATE TABLE product_details (
    product_detail_id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    locale_code VARCHAR(10) NOT NULL,
    localized_name VARCHAR(255) NOT NULL,
    localized_description TEXT,
    FOREIGN KEY (product_id) REFERENCES product(product_id),
    FOREIGN KEY (locale_code) REFERENCES locale(locale_code),
    UNIQUE (product_id, locale_code)
);

-- Inventory items (SKUs) within products
CREATE TABLE item (
    item_id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    category_id VARCHAR(50) NOT NULL,
    attribute VARCHAR(255),
    unit_cost DECIMAL(10, 2) NOT NULL,
    image_location VARCHAR(500),
    FOREIGN KEY (product_id) REFERENCES product(product_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- Shopping cart per session
CREATE TABLE shopping_cart (
    cart_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sub_total DECIMAL(12, 2) DEFAULT 0,
    item_count INTEGER DEFAULT 0,
    locale_code VARCHAR(10) DEFAULT 'en_US',
    FOREIGN KEY (user_id) REFERENCES customer(user_id),
    FOREIGN KEY (locale_code) REFERENCES locale(locale_code)
);

-- Shopping cart items
CREATE TABLE cart_item (
    cart_item_id VARCHAR(50) PRIMARY KEY,
    cart_id VARCHAR(50) NOT NULL,
    item_id VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (cart_id) REFERENCES shopping_cart(cart_id),
    FOREIGN KEY (item_id) REFERENCES item(item_id)
);

-- Purchase orders
CREATE TABLE purchase_order (
    order_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'DENIED', 'COMPLETED', 'SHIPPED_PART')),
    locale_code VARCHAR(10) DEFAULT 'en_US',
    total_price DECIMAL(12, 2) NOT NULL,
    billing_contact_id VARCHAR(50) NOT NULL,
    shipping_contact_id VARCHAR(50) NOT NULL,
    credit_card_id VARCHAR(50) NOT NULL,
    email_id VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES customer(user_id),
    FOREIGN KEY (billing_contact_id) REFERENCES contact_info(contact_id),
    FOREIGN KEY (shipping_contact_id) REFERENCES contact_info(contact_id),
    FOREIGN KEY (credit_card_id) REFERENCES credit_card(card_id),
    FOREIGN KEY (locale_code) REFERENCES locale(locale_code)
);

-- Line items within purchase orders
CREATE TABLE line_item (
    line_item_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    item_id VARCHAR(50) NOT NULL,
    line_number VARCHAR(10) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES purchase_order(order_id),
    FOREIGN KEY (item_id) REFERENCES item(item_id)
);

-- Order approval workflow
CREATE TABLE order_approval (
    approval_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'DENIED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    admin_id VARCHAR(50),
    reviewed_at TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES purchase_order(order_id),
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
);

-- Supplier management
CREATE TABLE supplier (
    supplier_id VARCHAR(50) PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255)
);

-- Supplier authentication
CREATE TABLE supplier_account (
    account_id VARCHAR(50) PRIMARY KEY,
    supplier_id VARCHAR(50) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
);

-- Inventory tracking by supplier
CREATE TABLE inventory (
    inventory_id VARCHAR(50) PRIMARY KEY,
    item_id VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    supplier_id VARCHAR(50) NOT NULL,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (item_id, supplier_id),
    FOREIGN KEY (item_id) REFERENCES item(item_id),
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
);

-- Admin users
CREATE TABLE admin (
    admin_id VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'administrator'
);

-- Indexes for common queries
CREATE INDEX idx_customer_email ON customer(email);
CREATE INDEX idx_account_user_id ON account(user_id);
CREATE INDEX idx_profile_user_id ON profile(user_id);
CREATE INDEX idx_product_category ON product(category_id);
CREATE INDEX idx_item_product ON item(product_id);
CREATE INDEX idx_item_category ON item(category_id);
CREATE INDEX idx_cart_user ON shopping_cart(user_id);
CREATE INDEX idx_cart_item_cart ON cart_item(cart_id);
CREATE INDEX idx_order_user ON purchase_order(user_id);
CREATE INDEX idx_order_status ON purchase_order(status);
CREATE INDEX idx_line_item_order ON line_item(order_id);
CREATE INDEX idx_line_item_item ON line_item(item_id);
CREATE INDEX idx_approval_order ON order_approval(order_id);
CREATE INDEX idx_inventory_item ON inventory(item_id);
CREATE INDEX idx_inventory_supplier ON inventory(supplier_id);
CREATE INDEX idx_credit_card_account ON credit_card(account_id);
