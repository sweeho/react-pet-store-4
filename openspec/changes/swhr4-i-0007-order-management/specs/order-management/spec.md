## ADDED Requirements

### Requirement: Order information entry screen

The order information entry screen SHALL collect and validate billing information including first name, last name, street address (two lines), city, state/province, postal code, country, and telephone. The screen SHALL collect identical shipping information fields separately. Both sections SHALL be marked as required fields with validation enforced at the form level.

#### Scenario: Billing and shipping information form

- **GIVEN** a customer ready to proceed to checkout
- **WHEN** the customer accesses the order information entry screen
- **THEN** the screen displays separate billing and shipping sections, each with required fields for given name, family name, street address line 1, street address line 2, city, state/province, postal code, and country

#### Scenario: Required field validation

- **GIVEN** an order information entry form with empty required fields
- **WHEN** the customer attempts to submit without completing all required fields
- **THEN** the form rejects submission and displays validation errors for each empty required field

### Requirement: Unique order identifier generation

The system SHALL generate unique order identifiers by concatenating a prefix with an auto-incrementing integer counter, returning identifiers in the format `prefixN` where N is the incremented counter value.

#### Scenario: Generate first order ID with prefix

- **GIVEN** no existing order ID counter for prefix "1001"
- **WHEN** the system requests a unique ID with prefix "1001"
- **THEN** a new counter is created with initial value 0, incremented to 1, and the ID "10011" is returned

#### Scenario: Generate subsequent order IDs

- **GIVEN** an existing counter for prefix "1001" with current value 42
- **WHEN** the system requests another unique ID with the same prefix
- **THEN** the counter is incremented to 43 and the ID "100143" is returned

#### Scenario: Counter persistence and atomicity

- **GIVEN** concurrent requests for unique IDs with the same prefix
- **WHEN** multiple requests are processed simultaneously
- **THEN** each request receives a unique, strictly increasing ID value; no two requests return the same identifier

### Requirement: Purchase order creation

The system SHALL support creating a purchase order with the following required fields: orderId (generated), userId, emailId, orderDate (captured as current system time), shippingInfo (ContactInfo), billingInfo (ContactInfo), creditCard, localePreference, lineItems collection, and totalPrice.

#### Scenario: Create order with all required fields

- **GIVEN** a shopping cart containing items and customer contact information
- **WHEN** order creation is initiated with userId, email, shipping contact, billing contact, and credit card
- **THEN** the system generates a unique orderId, captures the current date/time, creates associated ContactInfo entities for shipping and billing, creates a CreditCard entity, creates LineItem entities for each cart item, and persists the complete order atomically

#### Scenario: Order creation fails if cart is empty

- **GIVEN** a shopping cart with no items
- **WHEN** order creation is initiated
- **THEN** the system rejects the order with an exception; no partial order is created

#### Scenario: Order creation with line items

- **GIVEN** an order being created with 3 items in the cart
- **WHEN** order creation processes the cart items
- **THEN** each cart item is converted to a LineItem with category, productId, itemId, 0-based lineItemSequence (0, 1, 2), quantity, and unitCost, and all LineItems are persisted with the order

### Requirement: Order date storage

The system SHALL store purchase order date as milliseconds since epoch (long value) to enable date range queries and support multiple locale/timezone contexts without ambiguity.

#### Scenario: Capture and store order date

- **GIVEN** order creation at a specific moment in time
- **WHEN** the order is created
- **THEN** the orderDate is captured using the system's current time and stored as milliseconds since Unix epoch (January 1, 1970 00:00:00 UTC)

#### Scenario: Query orders by date range

- **GIVEN** multiple orders created on different dates
- **WHEN** the system queries for orders with orderDate between two epoch timestamps (inclusive)
- **THEN** all orders whose orderDate falls within the range are returned in the result set

### Requirement: Line item tracking

The system SHALL create line items for each product in the order, including category, productId, itemId, lineItemSequence (0-based), quantity, and unitCost. Each line item SHALL support reading its state via a data accessor.

#### Scenario: Line item data access

- **GIVEN** a created purchase order with 2 line items
- **WHEN** the system retrieves the state of a line item
- **THEN** the system returns a data transfer object containing all six fields: categoryId, productId, itemId, lineNumber (0-based), quantity, and unitPrice

### Requirement: Partial shipment fulfillment tracking

The system SHALL track partial shipment fulfillment on each line item such that quantityShipped can be incremented as supplier invoices are received. A purchase order is considered completely fulfilled only when all line items have quantityShipped equal to their ordered quantity.

#### Scenario: Process supplier invoice for partial shipment

- **GIVEN** a purchase order with 3 line items each with quantity 10, and initial quantityShipped = 0 for all
- **WHEN** a supplier invoice arrives with shipped quantities: itemId1=5, itemId2=10, itemId3=3
- **THEN** quantityShipped is incremented for each item: itemId1 becomes 5, itemId2 becomes 10, itemId3 becomes 3

#### Scenario: Check fulfillment completeness

- **GIVEN** an order where line item 1 has quantity=10 and quantityShipped=10, line item 2 has quantity=5 and quantityShipped=4
- **WHEN** the system checks if the order is completely fulfilled
- **THEN** the system determines the order is NOT complete because line item 2 still has 1 unit unshipped

#### Scenario: Order fully fulfilled

- **GIVEN** an order where all line items have quantityShipped equal to their ordered quantity
- **WHEN** the system checks fulfillment status
- **THEN** the system confirms that the order is completely fulfilled and ready for delivery

### Requirement: Order retrieval by ID

The system SHALL support retrieving a purchase order by its primary key (orderId) via a finder method.

#### Scenario: Retrieve existing order

- **GIVEN** a purchase order with orderId "100142"
- **WHEN** the system retrieves the order by its orderId
- **THEN** the complete purchase order is returned with all fields and related line items, contact info, and credit card

#### Scenario: Retrieve non-existent order

- **GIVEN** a request to retrieve an order with orderId that does not exist
- **WHEN** the retrieval is attempted
- **THEN** the system raises a not-found exception

### Requirement: Order-to-line item relationship

The system SHALL enforce a one-to-many relationship between PurchaseOrder and LineItem, such that every purchase order MUST have at least one line item, and line items SHALL be deleted when their purchase order is deleted.

#### Scenario: Delete order cascades to line items

- **GIVEN** a purchase order with 3 line items
- **WHEN** the purchase order is deleted
- **THEN** all 3 line items are automatically deleted as well; no orphaned line items remain

#### Scenario: Order creation requires at least one line item

- **GIVEN** an order creation request with an empty line items collection
- **WHEN** the system attempts to persist the order
- **THEN** the creation fails; at least one line item is required

### Requirement: Order-to-contact relationship

The system SHALL store contact information (shipping and billing) as separate ContactInfo entities with one-to-one relationships to the PurchaseOrder. ContactInfo entities SHALL be deleted when the order is deleted.

#### Scenario: Create order with billing and shipping contact

- **GIVEN** order creation with distinct billing contact (John, 123 Main St) and shipping contact (Jane, 456 Oak Ave)
- **WHEN** the order is created
- **THEN** two separate ContactInfo entities are created and associated with the order; each stores the provided information

#### Scenario: Order creation failure cascades properly

- **GIVEN** order creation that fails after ContactInfo entity creation but before persistence
- **WHEN** the transaction rolls back
- **THEN** the partially-created ContactInfo entities are also rolled back; no incomplete data persists

### Requirement: Credit card one-to-one relationship

The system SHALL store credit card information (card number, card type, expiry date) as a separate CreditCard entity with a one-to-one relationship to the PurchaseOrder. The CreditCard entity SHALL be deleted when the order is deleted.

#### Scenario: Create order with credit card

- **GIVEN** order creation with credit card details (card number, type, expiry)
- **WHEN** the order is created
- **THEN** a separate CreditCard entity is created, associated one-to-one with the order, and persisted

### Requirement: Order transaction isolation

All order-related operations including order creation, line item creation, line item shipment updates, and order queries SHALL execute within atomic transactions with Required isolation level to ensure data consistency.

#### Scenario: Atomic order creation

- **GIVEN** order creation with multiple related entities (ContactInfo, CreditCard, LineItems)
- **WHEN** order creation is executed
- **THEN** either all entities are created and committed together, or the entire transaction rolls back; no partial orders are persisted

#### Scenario: Transactional line item update

- **GIVEN** multiple threads updating quantityShipped for different line items in the same order
- **WHEN** supplier invoices are processed concurrently
- **THEN** each update is atomic; no values are lost and all changes are durable
