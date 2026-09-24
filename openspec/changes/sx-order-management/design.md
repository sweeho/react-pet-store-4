# Order Management Design

## Architecture Overview

The order management subsystem is built on J2EE/EJB 2.x with container-managed persistence (CMP) and container-managed transactions. The core architecture consists of:

### Components

1. **UniqueIdGeneratorEJB** (Stateless Session Bean)
   - Provides unique ID generation via `getUniqueId(String prefix)` method
   - Delegates to Counter entity bean for state management
   - Local interface only (no remote access)
   - JNDI lookup at `java:comp/env/ejb/Counter`

2. **CounterEJB** (Entity Bean, CMP 2.x)
   - Maintains counter state (name as primary key, counter as integer)
   - Implements auto-increment logic in `getNextValue()` method
   - Non-reentrant; reentrancy flag explicitly set to False
   - Creates new counter records on first request for a prefix

3. **PurchaseOrderEJB** (Entity Bean, CMP 2.x)
   - Central entity for order state
   - CMP fields: poId, poUserId, poEmailId, poDate, poLocale, poValue
   - Relationships: One-to-Many to LineItem, One-to-One to ContactInfo (shipping), One-to-One to ContactInfo (billing), One-to-One to CreditCard
   - ejbPostCreate() handles creation of related entities

4. **LineItemEJB** (Entity Bean, CMP 2.x)
   - CMP fields: categoryId, productId, itemId, lineNumber, quantity, unitPrice, quantityShipped
   - Provides read-only `getData()` method returning LineItem value object
   - Related to PurchaseOrder via CMR field `lineItems` (Collection)

5. **ContactInfoEJB** (Entity Bean, implied from PurchaseOrder)
   - Stores shipping and billing address information
   - Two separate instances per order (billing and shipping)
   - One-to-One relationship with PurchaseOrder with cascade-delete

6. **CreditCardEJB** (Entity Bean, implied from PurchaseOrder)
   - CMP fields: cardNumber, cardType, expiryDate
   - One-to-One relationship with PurchaseOrder with cascade-delete

### Data Model

**Counter Table**

```
name VARCHAR(255) PRIMARY KEY
counter INT
```

**PurchaseOrder Table**

```
poId VARCHAR(255) PRIMARY KEY
poUserId VARCHAR(255)
poEmailId VARCHAR(255)
poDate BIGINT (milliseconds since epoch)
poLocale VARCHAR(20)
poValue FLOAT
```

**LineItem Table**

```
lineItemId VARCHAR(255) PRIMARY KEY (generated)
poId VARCHAR(255) FOREIGN KEY -> PurchaseOrder
categoryId VARCHAR(255)
productId VARCHAR(255)
itemId VARCHAR(255)
lineNumber INT (0-based)
quantity INT
unitPrice FLOAT
quantityShipped INT (default 0)
```

**ContactInfo Table** (used for both shipping and billing)

```
contactInfoId VARCHAR(255) PRIMARY KEY
given_name VARCHAR(30)
family_name VARCHAR(30)
address_1 VARCHAR(255)
address_2 VARCHAR(255)
city VARCHAR(30)
state_prov VARCHAR(30)
postal_code VARCHAR(30)
country VARCHAR(30)
telephone VARCHAR(30)
email VARCHAR(255)
```

**CreditCard Table**

```
creditCardId VARCHAR(255) PRIMARY KEY
cardNumber VARCHAR(20)
cardType VARCHAR(30)
expiryDate VARCHAR(10)
```

## Key Implementation Patterns

### Transaction Management

- All operations use Container-Managed Transactions (CMT)
- All public methods have `trans-attribute = Required`
- This ensures ACID semantics for complex operations like order creation that involve multiple entity creations

### ID Generation Strategy

- Uses prefix-based sequential numbering, not UUID
- Prefix "1001" is hardcoded in OrderEJBAction for order IDs
- Counter auto-creates on first request; subsequent calls increment
- Thread-safe via EJB container transaction isolation

### Order Creation Workflow

The OrderEJBAction performs the order creation:

1. Generate orderId via UniqueIdGenerator.getUniqueId("1001")
2. Create PurchaseOrder entity with ejbCreate()
3. Create ContactInfo entities for shipping and billing in ejbPostCreate()
4. Create CreditCard entity in ejbPostCreate()
5. Create LineItem entities for each cart item in ejbPostCreate()
6. All within a single Required transaction

### Fulfillment Tracking

The PurchaseOrderHelper class implements business logic:

- `processInvoice(PurchaseOrderLocal po, Map lineItemIds)` accumulates shipped quantities
- Compares quantity vs quantityShipped for each line item
- Returns boolean indicating complete fulfillment
- Line items are updated in a loop; each update is transactional

### Date/Timezone Handling

- Order dates are stored as `java.util.Date.getTime()` → milliseconds since epoch
- This is query-safe: EJB-QL queries use BETWEEN on long values
- Locale preference stored as String (e.g., "en_US", "ja_JP")
- Date calculations safe across timezones since epoch is UTC-based

## JSP Implementation Details

### Order Entry Form (`enter_order_information.jsp`)

- Uses WAF (Web Application Framework) custom tags: `<waf:form>`, `<waf:input>`
- Billing section spans lines 48-189
- Shipping section spans lines 191-330
- Separate input fields for each section with naming convention: `given_name_a` (billing), etc.
- Form submission action: "order.do" (Struts action)
- Fields: First Name, Last Name, Street Address 1, Street Address 2, City, State/Province, Postal Code, Country, Telephone
- Email field included in billing section; appears to be used as order contact email
- Validation attribute on input fields triggers WAF validation framework

### Security

- No role-based restrictions on order operations
- LineItem methods use `<unchecked/>` security constraint
- Authentication assumed to be handled at servlet/filter layer

## Migration Considerations

### Removing EJB Infrastructure

1. **UniqueIdGenerator** → TypeScript service with SQLite counter table
2. **PurchaseOrder EJB** → TypeScript data model with Drizzle ORM schema
3. **LineItem EJB** → TypeScript data model, line items as related records
4. **Transaction Management** → SQLite transactions via Drizzle + Nitro request context
5. **JNDI Lookup** → Direct dependency injection or module-level singletons

### Date Handling

- Continue using milliseconds since epoch for database storage
- Convert to/from JavaScript Date objects in the API
- Ensure all date queries use epoch-based comparisons

### ContactInfo and CreditCard

- These are currently separate entity beans
- In the rebuild, consider whether to denormalize into PurchaseOrder or keep as separate tables
- Original uses one-to-one cascade-delete; preserve this in foreign key constraints

### ID Generation

- Prefix-based sequential IDs should be preserved
- Can use database AUTOINCREMENT with prefix string, or maintain a separate counter table
- Must ensure atomicity: ID is generated and reserved before order creation begins

### Validation

- WAF custom tag validation logic is implicit in JSP form
- Extract validation rules: required fields, field lengths (maxlength in markup)
- Implement in new form validation framework (e.g., Zod schema)

## Ambiguities and Known Issues

### Billing/Shipping Address Duplication

- PurchaseOrderEJB.java line 268 contains a XXX comment indicating this is a known issue
- Code currently sets both billingInfo and shippingInfo to the same ContactInfo object
- This may be intentional (customers must ship to billing address) or a bug (separate addresses should be supported)
- **Decision needed**: Can customers specify different shipping vs. billing addresses?

### ContactInfo Entity Definition

- ContactInfo is referenced in PurchaseOrder relationships but not directly visible in purchaseorder component
- The fields and entity definition are inferred from JSP form and relationship declarations
- **Recommendation**: Verify ContactInfo schema and entity bean definition in the contactinfo component

### Order Persistence Mechanism

- OrderEJBAction creates PurchaseOrder but actual persistence call is redacted in source
- Assumed to use standard EJB create() method, but should be verified
- **Recommendation**: Confirm the exact persistence API used

### Email Field Usage

- Email is extracted from billingInfo.getEmail()
- Set on order as poEmailId
- Unclear whether this is customer email, order contact email, or both
- **Recommendation**: Clarify email usage in order correspondence/notifications

## Related Capabilities

- **Checkout/Payment**: Integrates with order creation, handles credit card validation
- **Inventory Management**: Consumes order line items for stock deduction (not in this spec)
- **Supplier Integration**: Processes invoices to update quantityShipped (partially visible in IR)
- **Notifications**: Sends order confirmations; uses order email and details
