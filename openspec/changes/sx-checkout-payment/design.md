# Checkout-Payment Capability Design

## Architecture Overview

The checkout-payment capability is built on a layered J2EE architecture:

1. **Web Tier**: JSP forms (edit_customer.jsp, enter_order_information.jsp) collect credit card input
2. **Controller Tier**: Struts actions (CustomerHTMLAction) extract and validate form data
3. **Business Tier**: EJB session/entity beans process credit card data and create orders
4. **Persistence Tier**: CMP entity beans (CreditCardEJB) and database persist credit card state
5. **Integration Tier**: Credit card references appear in Account and PurchaseOrder entities

## Data Model Design

### Credit Card Entity Bean (CreditCardEJB)

**CMP Fields:**

- `cardNumber` (String): Card account number, max 30 characters (UI constraint only)
- `cardType` (String): Card issuer/brand, one of {Java(TM) Card, Duke Express, Meow Card}
- `expiryDate` (String): Expiry in MM/YYYY format, e.g., "03/2025"

**Methods:**

- `getExpiryMonth()`: Parses expiryDate, returns month (01-12), defaults to "01" if null/malformed
- `getExpiryYear()`: Parses expiryDate, returns year (YYYY), defaults to "2010" if null/malformed
- `getData()`: Returns fresh CreditCard POJO copy of entity state

**Lifecycle:**

- Three overloaded ejbCreate methods support flexible construction: no-args, three-arg, POJO-arg
- Relationships to Account and PurchaseOrder are One-to-One, established in ejbPostCreate
- All methods run with trans-attribute="Required" (container-managed transactions)
- Unchecked access (no role-based authorization at entity level)

**Primary Key:** Declared as java.lang.Object (atypical for CMP, delegated to container)

### Credit Card Transfer Object (POJO)

A lightweight serializable POJO used for data marshalling between tiers:

- Same three fields as entity (cardNumber, cardType, expiryDate)
- Constructor supports flexible initialization
- XML serialization via toDOM() / fromDOM() for document-based integration
- Used as parameter to CreditCardEJB.ejbCreate(CreditCard) overload
- Returned by CreditCardEJB.getData() for safe entity state exposure

### Relationships

**Account → CreditCard (One-to-One)**

- Created during account setup in AccountEJB.ejbPostCreate()
- Via JNDI lookup: "java:comp/env/ejb/CreditCard"
- Accessed by AccountEJB.getCreditCard() / setCreditCard()

**PurchaseOrder → CreditCard (One-to-One with Cascade Delete)**

- Created during order creation in PurchaseOrderEJB.ejbPostCreate()
- Via ServiceLocator lookup for CreditCardLocalHome
- Cascade-delete ensures card data is removed with order
- Accessed by PurchaseOrderEJB.getCreditCard() / setCreditCard()

## Form Design

### edit_customer.jsp

**Credit Card Section:**

- Card Number: `<waf:input name="credit_card_number" maxlength="30" validation="validation">`
- Card Type: `<waf:select name="credit_card_type">` with three options
- Expiry Month: `<waf:select name="credit_card_expiry_month">` with months 01-12
- Expiry Year: `<waf:select name="credit_card_expiry_year">` with years 2002-2005

**Form Action:** POST to customer.do with action parameter (create or update)

### enter_order_information.jsp

**Sections:**

1. Billing Information: First name, last name, street address (2 lines), city, state, postal code, country, telephone, email
2. Shipping Information: Identical fields as billing (user can copy or enter separately)
3. Credit Card Information: Card number, type, expiry month/year (from edit_customer.jsp pattern)
4. Order Summary: Display items in cart with quantities, unit costs, calculated total

**Form Action:** POST to order.do with order data

## Controller Implementation

### CustomerHTMLAction.extractCreditCard()

Extracts credit card from request parameters:

```
1. Extract credit_card_number parameter
2. Extract credit_card_type parameter
3. Extract credit_card_expiry_month parameter
4. Extract credit_card_expiry_year parameter
5. Validate all four are non-empty (raise MissingFormDataException if missing)
6. Concatenate month and year: expiryDate = month + "/" + year
7. Construct and return new CreditCard(number, type, expiryDate)
```

**Known Issues:**

- Lines 152, 160, 168 have copy-paste bug: all check creditCardNumber instead of the respective field
- Validation for card type, expiry month, expiry year is currently bypassed
- Should be fixed to check correct field in each branch

**Integration:**

- Called from CustomerHTMLAction.perform() during customer create/update flows
- CreditCard is bundled with ContactInfo and ProfileInfo in CustomerEvent
- Passed to business tier for persistence

## XML Serialization

### CreditCard.dtd Schema

```
<!ELEMENT CreditCard (CardNumber, CardType, ExpiryDate)>
<!ELEMENT CardNumber (#PCDATA)>
<!ELEMENT CardType (#PCDATA)>
<!ELEMENT ExpiryDate (#PCDATA)>
```

### CreditCard.toDOM() / fromDOM()

- **toDOM()**: Creates root CreditCard element, appends three child elements in order with field values as text content
- **fromDOM()**: Parses CreditCard element, extracts three children in order, creates new POJO with values
- Used for document-based messaging and order serialization

## Transaction Model

**Trans-Attribute: Required**

All CreditCard entity methods (getters, setters, lifecycle, finders) run with Required attribute:

- Method must run within an active transaction
- Container creates a new transaction if none exists
- Transaction is committed or rolled back based on method outcome
- Ensures ACID properties for financial data

**Implication:** Any operation on CreditCard data is atomic and consistent with surrounding account/order updates.

## Security Model

**Authorization:** Unchecked (no role-based access control at entity level)

- All callers can invoke any CreditCard method
- Access control is delegated to higher layers:
  - Only Account owner can modify their own credit card
  - Only customer who placed order can view/modify card details
  - Session bean or web action layer enforces these checks

**Concerns (Not Addressed):**

- Credit card data is stored in plaintext in persistent storage
- Network transmission not encrypted (handled by transport layer)
- No masking/truncation in logs or error messages
- No audit trail of card data access

## Known Issues and Gaps

### 1. Hardcoded Defaults (Medium Risk)

The defaults "01" and "2010" for null/malformed expiry dates are bare literals with no configuration or test:

- No comment explaining why 2010 was chosen
- May mask missing validation or data quality issues
- Suggest: Add configuration property for default year, add tests for null case, add logging for fallback triggers

### 2. Time-Bound Form Constraints (Low Risk)

Expiry year range 2002-2005 in form is hardcoded and time-bound:

- Form was authored around 2002
- Will become unusable as current year passes 2005
- Suggest: Make year range configurable or dynamic based on current year

### 3. Validation Bug (High Risk)

Form validation checks creditCardNumber instead of cardType/expiryMonth/expiryYear:

- Bug is in lines 152, 160, 168 of CustomerHTMLAction
- Allows card type and expiry to be empty without error
- Causes account creation to proceed with incomplete card data
- Suggest: Fix checks to validate correct field in each branch, add tests

### 4. Primary Key Type (Low Risk)

CreditCard entity declares prim-key-class as java.lang.Object:

- Atypical for CMP entity (usually a specific type like String, Integer)
- Indicates container-managed key with no explicit field
- May indicate auto-generated or composite key
- Unclear if entity can be queried by key independently

### 5. Card Number Validation (Medium Risk)

No server-side validation of card number format:

- Only maxlength="30" at HTML level
- No Luhn algorithm or digit-only validation
- Allows alphanumeric input up to 30 chars
- Suggest: Add server-side format validation, consider encryption

## Migration Notes

### For Rebuild

The following design decisions should be preserved:

- Three CMP fields (cardNumber, cardType, expiryDate) with same types and semantics
- MM/YYYY concatenated format for expiry date
- Three-value enumeration for card type
- One-to-One relationships with Account and PurchaseOrder
- Transactional consistency for all operations
- Transfer object pattern for data marshalling
- XML serialization capability

Consider resolving:

- Hardcoded defaults (01, 2010) → make configurable
- Time-bound year range (2002-2005) → make dynamic
- Validation bug in CustomerHTMLAction → correct field checks
- Card number format validation → add server-side checks
- Primary key type → document or clarify

## Related Capabilities

- **customer-account**: Account entity lifecycle, profile management, relationship to credit card
- **order-management**: PurchaseOrder entity, order creation workflow, relationship to credit card
- **product-catalog**: Shopping cart, item selection, cart-to-order transition
- **notification-messaging**: Email confirmation after order creation (separate from payment processing)
