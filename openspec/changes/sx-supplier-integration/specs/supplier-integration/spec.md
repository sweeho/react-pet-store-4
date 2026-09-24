# Supplier Integration Specification

## ADDED Requirements

### Requirement: Supplier login screen display

The supplier module SHALL provide a login screen at `/login.jsp` that displays a form-based authentication interface with username and password input fields. The form SHALL post to the `j_security_check` endpoint for authentication processing.

#### Scenario: Login screen renders with default credentials

- **GIVEN** a user navigates to the supplier module for the first time
- **WHEN** the login page is displayed
- **THEN** the page contains a form with username and password input fields, each with default value `"supplier"` pre-filled

#### Scenario: Login form submission routes to j_security_check

- **GIVEN** a login page with populated username and password fields
- **WHEN** the user submits the form
- **THEN** the form posts to `j_security_check` with parameters `j_username` and `j_password`

### Requirement: Supplier home page display

The supplier module SHALL provide a home page at `/index.jsp` after successful authentication. The home page SHALL display navigation options to view current inventory or logout, with buttons that submit forms to the `RcvrRequestProcessor` servlet.

#### Scenario: Home page displays after successful login

- **GIVEN** a user has successfully authenticated as a supplier
- **WHEN** the home page is displayed after login
- **THEN** the page displays navigation options including "Display Inventory" and "Logout" buttons

#### Scenario: Display Inventory button routes to inventory page

- **GIVEN** a supplier on the home page
- **WHEN** the Display Inventory button is clicked
- **THEN** a form is submitted to `RcvrRequestProcessor` with `currentScreen=displayinventory` parameter

#### Scenario: Logout button routes to logout handler

- **GIVEN** a supplier on the home page
- **WHEN** the Logout button is clicked
- **THEN** a form is submitted to `RcvrRequestProcessor` with `currentScreen=logout` parameter

### Requirement: Form-based authentication mechanism

The supplier module SHALL authenticate users using form-based login with username and password credentials. The system SHALL use the container's form-based authentication mechanism via `j_security_check` endpoint. The login form endpoint SHALL be `/login.jsp` and the error page SHALL be `/error.jsp`.

#### Scenario: Valid credentials accepted

- **GIVEN** a user at the login page
- **WHEN** valid credentials are submitted to `j_security_check`
- **THEN** the user is authenticated and the session is established

#### Scenario: Invalid credentials rejected

- **GIVEN** a user at the login page
- **WHEN** invalid credentials are submitted to `j_security_check`
- **THEN** the user is redirected to the error page at `/error.jsp`

### Requirement: Session timeout enforcement

Session timeout for the supplier module SHALL be 54 minutes. Users whose session expires SHALL be required to re-authenticate at the login page on their next request.

#### Scenario: Session remains valid within timeout window

- **GIVEN** an authenticated user with a valid session
- **WHEN** the user makes a request within 54 minutes of the last activity
- **THEN** the request is processed and the session remains active

#### Scenario: Session expires after timeout

- **GIVEN** an authenticated user whose session has been inactive for more than 54 minutes
- **WHEN** the user makes a request
- **THEN** the user is redirected to the login page to re-authenticate

### Requirement: Role-based access control

Access to inventory operations (via `RcvrRequestProcessor` servlet) SHALL be restricted to users with the `administrator` role. Users without this role SHALL not be able to view or modify inventory.

#### Scenario: Administrator can access inventory operations

- **GIVEN** an authenticated user with the administrator role
- **WHEN** the user submits a form to `RcvrRequestProcessor`
- **THEN** the inventory operation is processed

#### Scenario: Non-administrator denied inventory access

- **GIVEN** an authenticated user without the administrator role
- **WHEN** the user attempts to submit a form to `RcvrRequestProcessor`
- **THEN** the request is denied and an authorization error is returned

### Requirement: Inventory entity persistence

The system SHALL maintain an Inventory entity with two core fields: `itemId` (string, primary key) and `quantity` (integer, representing available stock). Each inventory entry represents the available stock for a single item in the supplier's warehouse.

#### Scenario: Inventory entry created with initial stock

- **GIVEN** a new inventory item being registered
- **WHEN** an inventory entry is created with itemId and quantity
- **THEN** the entry is persisted and can be retrieved by itemId

#### Scenario: Inventory quantity retrieved

- **GIVEN** an existing inventory entry
- **WHEN** the quantity is queried
- **THEN** the current quantity value is returned

### Requirement: Inventory quantity reduction operation

The system SHALL provide an operation to reduce inventory quantity by a specified amount. Given an item in inventory and a quantity value, the system SHALL decrement the current quantity by the specified amount in an atomic transaction.

#### Scenario: Quantity reduced successfully

- **GIVEN** an inventory item with quantity 100
- **WHEN** a reduction operation with amount 30 is executed
- **THEN** the quantity is updated to 70 and the change is persisted atomically

#### Scenario: Reduction operation is transactional

- **GIVEN** an inventory reduction in progress
- **WHEN** the transaction is committed
- **THEN** the quantity change is durable and visible to all subsequent queries

### Requirement: Inventory availability check before fulfillment

The system SHALL check inventory availability before fulfilling a line item. Given a line item with a requested quantity, the system SHALL verify that the inventory quantity for that item is greater than or equal to the requested quantity. If insufficient stock exists, the system SHALL mark the check as failed and NOT reduce inventory.

#### Scenario: Sufficient inventory available

- **GIVEN** an inventory item with quantity 100 and a line item requesting 50 units
- **WHEN** availability is checked
- **THEN** the check succeeds and inventory is reduced

#### Scenario: Insufficient inventory available

- **GIVEN** an inventory item with quantity 30 and a line item requesting 50 units
- **WHEN** availability is checked
- **THEN** the check fails, inventory is not reduced, and the line item remains unfulfilled

#### Scenario: Inventory not found for item

- **GIVEN** a line item referencing an itemId with no corresponding inventory entry
- **WHEN** availability is checked
- **THEN** the check fails and the line item remains unfulfilled

### Requirement: Partial order fulfillment

The system SHALL support partial fulfillment of purchase orders. If some line items can be fulfilled from inventory and others cannot, the system SHALL ship the available items and create an invoice for only those items. The order status SHALL be marked COMPLETED only if all line items were fulfilled.

#### Scenario: Some line items fulfilled, others pending

- **GIVEN** a purchase order with 5 line items, where 3 have sufficient inventory and 2 do not
- **WHEN** the order is processed
- **THEN** the 3 available items are marked as shipped, invoiced, and sent; the 2 unavailable items remain in PENDING status

#### Scenario: Partial fulfillment does not mark order complete

- **GIVEN** an order with partial fulfillment (some items shipped, some pending)
- **WHEN** the fulfillment process completes
- **THEN** the order status remains PENDING, not COMPLETED

#### Scenario: All items fulfilled marks order complete

- **GIVEN** an order where all line items have sufficient inventory
- **WHEN** fulfillment completes
- **THEN** the order status is marked COMPLETED

### Requirement: Purchase order reception via JMS

The system SHALL receive purchase orders from the Order Processing Center (OPC) via a JMS message queue. The message handler SHALL listen to the queue, extract the purchase order XML from each `TextMessage`, and delegate processing to the order fulfillment handler.

#### Scenario: PO message received on queue

- **GIVEN** a purchase order message posted to the JMS queue
- **WHEN** the message is delivered to the listener
- **THEN** the message content (XML) is extracted and processing begins

#### Scenario: Invalid message type rejected

- **GIVEN** a non-TextMessage (e.g., BytesMessage or ObjectMessage) on the queue
- **WHEN** the message is received
- **THEN** the message is rejected with an error

### Requirement: Purchase order processing workflow

The system SHALL process each incoming purchase order by:

1. Parsing the XML document into a PO object
2. Persisting the order with initial status PENDING
3. Checking inventory availability for each line item
4. Reducing inventory for items that can be fulfilled
5. Marking fulfilled line items as shipped
6. Generating an invoice for items that were shipped

The processing method SHALL return the invoice XML if any items were shipped, or null if no items could be fulfilled.

#### Scenario: All line items can be fulfilled

- **GIVEN** a purchase order with all line items having sufficient inventory
- **WHEN** the order is processed
- **THEN** all inventory is reduced, all items marked shipped, an invoice is generated and returned

#### Scenario: No line items can be fulfilled

- **GIVEN** a purchase order with no line items having sufficient inventory
- **WHEN** the order is processed
- **THEN** no inventory is reduced, no items are marked shipped, null is returned (no invoice)

### Requirement: Order status lifecycle

The system SHALL enforce an order status lifecycle where orders transition through the following states: PENDING (initial state) → APPROVED or COMPLETED or back to PENDING if retrying on inventory update. Orders can transition to DENIED by external systems.

#### Scenario: New order starts in PENDING state

- **GIVEN** a new purchase order being created
- **WHEN** the order is persisted
- **THEN** the order status is initialized to PENDING

#### Scenario: Order transitions to COMPLETED after full fulfillment

- **GIVEN** an order in PENDING status with all line items fulfilled
- **WHEN** fulfillment completes
- **THEN** the order status is set to COMPLETED

#### Scenario: Pending order retried on inventory update

- **GIVEN** an order in PENDING status due to insufficient inventory
- **WHEN** new inventory arrives and the retry process runs
- **THEN** fulfillment is attempted again; if successful, status transitions to COMPLETED

### Requirement: Retry fulfillment of pending orders on inventory update

When inventory is updated via the supplier interface, the system SHALL query for all orders with status PENDING and attempt to fulfill them with the newly arrived stock. Generated invoices SHALL be sent back to the OPC for any newly fulfilled items.

#### Scenario: Pending orders fulfilled on inventory update

- **GIVEN** a PENDING order waiting on 50 units of item X, and new inventory adding 100 units
- **WHEN** inventory is updated
- **THEN** pending orders are queried, the order is retried, fulfilled, and invoice is generated

#### Scenario: No pending orders after inventory update

- **GIVEN** an inventory update occurring when no orders are in PENDING status
- **WHEN** the retry process runs
- **THEN** the process completes without processing any orders

### Requirement: Invoice XML generation

The system SHALL generate an invoice XML document for items that can be shipped. The invoice SHALL include:

- Order ID (from the purchase order)
- User ID ("Dear PetStore Customer")
- Order date (from the purchase order)
- Shipping date (current date when invoice is generated)
- Line items for all items that were fulfilled (containing: category ID, product ID, item ID, line number, quantity, unit price)

#### Scenario: Invoice generated for fulfilled items only

- **GIVEN** a purchase order with 5 line items, where 3 are fulfilled and 2 are pending
- **WHEN** an invoice is generated
- **THEN** the invoice contains the 3 fulfilled line items and excludes the pending items

#### Scenario: Invoice includes all required fields

- **GIVEN** fulfillment completing
- **WHEN** an invoice is generated
- **THEN** the invoice includes order ID, user ID, order date, shipping date, and complete line item details

### Requirement: Invoice transmission to Order Processing Center

The system SHALL send generated invoices back to the Order Processing Center. When an invoice is generated by the order processing handler, the invoice XML SHALL be sent via a JMS topic connection to the OPC invoice topic. If no items were shipped, no invoice SHALL be sent.

#### Scenario: Invoice sent for shipped items

- **GIVEN** a purchase order with some items fulfilled
- **WHEN** an invoice is generated
- **THEN** the invoice is published to the OPC invoice topic

#### Scenario: No invoice sent for unshipped orders

- **GIVEN** a purchase order with no items fulfilled
- **WHEN** processing completes
- **THEN** no invoice is published to the OPC

### Requirement: Logout endpoint

The system SHALL support supplier logout via the `/logout.jsp` endpoint. When a supplier submits a form with `currentScreen=logout` to `RcvrRequestProcessor`, the servlet SHALL forward to `/logout.jsp`, invalidating the user's session.

#### Scenario: Logout request invalidates session

- **GIVEN** an authenticated supplier on the home page
- **WHEN** the logout form is submitted to `RcvrRequestProcessor` with currentScreen=logout
- **THEN** the request is forwarded to `/logout.jsp` and the session is invalidated

#### Scenario: Logout redirects to login page

- **GIVEN** a supplier who has just logged out
- **WHEN** the supplier attempts to access protected pages
- **THEN** the user is redirected to the login page

### Requirement: Supplier order entity persistence

The system SHALL maintain a SupplierOrder entity as a persistent container for supplier orders with the following core attributes:

- Order ID (unique identifier)
- Order date (timestamp when order was received)
- Order status (current state: PENDING, APPROVED, COMPLETED, DENIED)
- Relationships to line items representing ordered products

#### Scenario: Purchase order persisted with metadata

- **GIVEN** a purchase order being processed
- **WHEN** the order is persisted
- **THEN** the order ID, date, and status are stored and retrievable

#### Scenario: Purchase order linked to line items

- **GIVEN** a purchase order with multiple line items
- **WHEN** the order is persisted
- **THEN** all line items are linked to the order and retrievable via the order

### Requirement: XML validation configuration

XML validation for both purchase order and invoice documents can be configured independently via system configuration. Validation can be enabled or disabled for:

- Supplier order parsing (basic validation)
- Supplier order XSD validation
- Invoice XSD validation

#### Scenario: XML validation enabled

- **GIVEN** XML validation configured as enabled
- **WHEN** a purchase order or invoice XML is parsed
- **THEN** the XML is validated against the schema and rejected if invalid

#### Scenario: XML validation disabled

- **GIVEN** XML validation configured as disabled
- **WHEN** a malformed purchase order or invoice XML is parsed
- **THEN** parsing is attempted without schema validation (may fail on structural issues)

### Requirement: Inventory population initialization

The system SHALL support initialization of inventory data from an XML file at the `/Populate` endpoint. The endpoint SHALL read inventory item data from `/populate/Populate-UTF8.xml` and populate the Inventory entity database.

#### Scenario: Inventory loaded from XML on startup

- **GIVEN** the supplier application being initialized
- **WHEN** the `/Populate` endpoint is called
- **THEN** inventory data is loaded from the XML file and persisted to the database

#### Scenario: Multiple inventory items created from XML

- **GIVEN** an XML file containing 100 inventory items
- **WHEN** the populate endpoint is called
- **THEN** all 100 items are inserted into the inventory database

### Requirement: JMS topic integration for invoice distribution

The system SHALL have access to a JMS Topic for publishing invoice notifications to the Order Processing Center at `jms/opc/InvoiceTopic`. The system SHALL have a TopicConnectionFactory for establishing connections to publish invoices back to the OPC.

#### Scenario: Topic connection configured

- **GIVEN** the supplier system initialization
- **WHEN** the system starts
- **THEN** the JMS topic connection factory is resolved and ready for use

#### Scenario: Invoice published to topic

- **GIVEN** an invoice ready for transmission
- **WHEN** the invoice transmission process runs
- **THEN** the invoice is published to the OPC invoice topic via the connection factory

### Requirement: Request parameter parsing for inventory updates

The supplier module SHALL parse inventory update requests with the following parameter patterns:

- `item_<itemId>` (checkbox indicating item selected for update)
- `qty_<itemId>` (text input with new quantity value)

The system SHALL only update items where the corresponding `item_<itemId>` checkbox is checked.

#### Scenario: Single item quantity updated

- **GIVEN** an inventory form with item_123 checked and qty_123="50"
- **WHEN** the form is submitted to the inventory update handler
- **THEN** only item 123 is updated to quantity 50

#### Scenario: Multiple items updated in bulk

- **GIVEN** an inventory form with multiple item checkboxes checked
- **WHEN** the form is submitted
- **THEN** all checked items are updated with their corresponding quantities

#### Scenario: Quantity value must be non-negative

- **GIVEN** an inventory update request with a negative quantity value
- **WHEN** the update is processed
- **THEN** the update is rejected and the quantity is not changed
