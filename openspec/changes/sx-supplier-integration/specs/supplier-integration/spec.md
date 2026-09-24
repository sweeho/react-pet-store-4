## ADDED Requirements

### Requirement: SupplierOrder entity structure

The system SHALL maintain a SupplierOrder entity with the following attributes: poId (String, primary key), poDate (long, milliseconds since epoch), poStatus (String), contactInfo (one-to-one relationship), and lineItems (one-to-many collection).

#### Scenario: SupplierOrder is created with all required attributes

- **GIVEN** a SupplierOrder creation request with order ID, order date, and line items
- **WHEN** the order is persisted
- **THEN** the entity stores all fields and establishes relationships to ContactInfo and LineItems

### Requirement: Order status lifecycle

The system SHALL enforce an order status lifecycle where orders transition through states in the following pattern: PENDING → (APPROVED → COMPLETED) OR PENDING → DENIED.

#### Scenario: Order progresses through valid state transitions

- **GIVEN** a newly created order in PENDING status
- **WHEN** the order is approved and then fulfilled
- **THEN** the order transitions to APPROVED then to COMPLETED

### Requirement: Initial order status

The system SHALL initialize newly created purchase orders in the PENDING status.

#### Scenario: New order starts in PENDING

- **GIVEN** a purchase order creation request
- **WHEN** the ejbCreate method is invoked
- **THEN** the order is assigned PENDING status by default

### Requirement: ContactInfo relationship

Each supplier purchase order SHALL reference exactly one contact information record containing shipping details (given name, family name, telephone, email) and one associated address record. When an order is deleted, its associated ContactInfo SHALL be automatically deleted (cascade delete).

#### Scenario: Order has required ContactInfo

- **GIVEN** a purchase order with associated shipping information
- **WHEN** the order is created
- **THEN** exactly one ContactInfo entity is created and linked to the order

### Requirement: Line items collection

Each supplier purchase order SHALL contain one or more line items, where each line item specifies: category identifier, product identifier, item identifier, line number, ordered quantity, unit price, and tracked quantity shipped.

#### Scenario: Order contains required line items

- **GIVEN** a purchase order with multiple line items
- **WHEN** the order is created
- **THEN** each line item stores all required fields and is linked to the order

### Requirement: Query orders by status

The system SHALL support querying purchase orders by their status field, returning all orders matching a specified status value.

#### Scenario: Retrieve orders by status

- **GIVEN** multiple orders with different status values
- **WHEN** a query for orders with PENDING status is executed
- **THEN** only orders with PENDING status are returned

### Requirement: Order date representation

The system SHALL store purchase order creation dates as numeric timestamps (milliseconds from epoch), converting Date objects to/from this representation during object construction and retrieval.

#### Scenario: Date conversion during persistence

- **GIVEN** a Java Date object for an order
- **WHEN** the order is created
- **THEN** the date is stored as milliseconds since epoch

### Requirement: XML serialization with date format

The system SHALL support XML serialization and deserialization of purchase orders with date values formatted as yyyy-MM-dd strings within the XML representation.

#### Scenario: Date is serialized in yyyy-MM-dd format

- **GIVEN** an order with a date value
- **WHEN** the order is serialized to XML
- **THEN** the order date appears in the XML as yyyy-MM-dd format

#### Scenario: Date parsing fallback

- **GIVEN** a purchase order creation request with an unparseable order date in XML
- **WHEN** the order date cannot be parsed from the incoming XML
- **THEN** the system SHALL default to the current date and log the parsing error

### Requirement: Transaction semantics for all operations

All SupplierOrder EJB methods SHALL execute within a transaction context with trans-attribute=Required. This ensures all operations (create, read, update, delete, finder) are transactional.

#### Scenario: Methods execute within transactions

- **GIVEN** any SupplierOrder EJB method invocation
- **WHEN** the method executes
- **THEN** it SHALL participate in a container-managed transaction with Required semantics

### Requirement: Unchecked security access

All SupplierOrder EJB methods SHALL have unchecked security access. No role-based security restrictions apply to supplier order operations.

#### Scenario: Methods have no role restrictions

- **GIVEN** a call to any SupplierOrder EJB method
- **WHEN** the method is invoked
- **THEN** no role-based authorization check is performed

### Requirement: Message-driven order reception

The supplier system SHALL receive purchase orders from the Order Processing Center (OPC) via a JMS message queue. The SupplierOrderMDB message-driven bean SHALL listen to the queue, extract the purchase order XML from each TextMessage, and delegate processing to the OrderFulfillmentFacade.

#### Scenario: Order is received via JMS Queue

- **GIVEN** a purchase order XML message on the JMS Queue
- **WHEN** the SupplierOrderMDB receives the message
- **THEN** the order XML is extracted and passed to the OrderFulfillmentFacade for processing

### Requirement: Order fulfillment workflow

When a purchase order is received via JMS Queue, the supplier system SHALL process the order by checking inventory availability, reducing inventory quantities for items that can be fulfilled, and generating an invoice for any items shipped.

#### Scenario: Order is processed and invoice is generated

- **GIVEN** a purchase order with line items that can be fulfilled from inventory
- **WHEN** the order fulfillment workflow is executed
- **THEN** inventory quantities are reduced and an invoice is generated for shipped items

### Requirement: Invoice generation

The system SHALL generate an invoice XML document for items that can be shipped. The invoice SHALL include: order ID, user ID ("Dear PetStore Customer"), order date (from purchase order), current shipping date, and line items for all items that were fulfilled (category, product, item ID, line number, quantity, unit price).

#### Scenario: Invoice is created with all required fields

- **GIVEN** a purchase order with items that were fulfilled
- **WHEN** the invoice is generated
- **THEN** the invoice contains order ID, user ID, dates, and all shipped line items

### Requirement: Invoice return to OPC

The system SHALL send generated invoices back to the Order Processing Center. When an invoice is generated by the SupplierOrderMDB, the invoice XML SHALL be sent via a transition delegate that queues the invoice for delivery to the OPC. If no items were shipped, no invoice SHALL be sent.

#### Scenario: Invoice is sent when items are shipped

- **GIVEN** a generated invoice for fulfilled items
- **WHEN** the invoice is created
- **THEN** the invoice is queued for delivery to the OPC

#### Scenario: No invoice is sent when no items are fulfilled

- **GIVEN** a purchase order with no available inventory
- **WHEN** no items can be fulfilled
- **THEN** no invoice is generated or sent

### Requirement: Form-based authentication

The supplier module SHALL authenticate users using form-based login with username and password. The login form is at /login.jsp and the error page is /error.jsp. Authentication SHALL use the container's form-based login mechanism (j_security_check).

#### Scenario: User logs in with credentials

- **GIVEN** the supplier module login screen
- **WHEN** a user enters username and password and submits the form
- **THEN** the form is submitted to j_security_check for container-managed authentication

### Requirement: Login screen interface

The supplier module SHALL provide a login screen at /login.jsp that displays form-based authentication interface with username and password fields. Default values of "supplier" for both username and password SHALL be pre-filled.

#### Scenario: Login form displays with default credentials

- **GIVEN** a user accessing the supplier module without authentication
- **WHEN** the login page is rendered
- **THEN** the login form displays with username and password fields pre-filled with "supplier"

### Requirement: Home page after authentication

The supplier module SHALL provide a home page at /index.jsp after successful authentication. The home page SHALL display options to view current inventory or logout, with buttons that submit forms to RcvrRequestProcessor.

#### Scenario: Home page displays navigation options

- **GIVEN** a successfully authenticated user
- **WHEN** the home page is rendered
- **THEN** the page displays buttons to view inventory and logout, each submitting forms to RcvrRequestProcessor

### Requirement: Supplier logout workflow

The system SHALL support supplier logout via the /logout.jsp endpoint. When a supplier submits a form with currentScreen=logout to RcvrRequestProcessor, the servlet SHALL forward to /logout.jsp, invalidating the user's session.

#### Scenario: User logs out

- **GIVEN** an authenticated supplier user
- **WHEN** the logout button is clicked
- **THEN** the session is invalidated and the user is forwarded to the logout page

### Requirement: Session timeout

Session timeout for supplier module SHALL be 54 minutes. Users whose session expires must re-authenticate at the login page.

#### Scenario: Session expires after inactivity

- **GIVEN** a logged-in user with no activity for 54 minutes
- **WHEN** the timeout period is reached
- **THEN** the session is automatically invalidated and re-authentication is required

### Requirement: XML validation configuration

The system MUST validate purchase order XML documents and invoice XML documents. XML validation MUST be enabled/disabled via configuration parameters. Supplier order validation, Supplier order XSD validation, and Invoice XSD validation MUST each be configurable independently via environment entries.

#### Scenario: XML validation is enabled for supplier orders

- **GIVEN** XML validation configuration parameters
- **WHEN** OrderFulfillmentFacadeEJB is initialized
- **THEN** the validation parameters are read from environment entries and applied to XML processing

### Requirement: JMS Topic for invoice publishing

The system SHALL publish invoice notifications to a JMS Topic at jms/opc/InvoiceTopic. The SupplierOrderMDB and OrderFulfillmentFacadeEJB SHALL have access to a TopicConnectionFactory for publishing invoices back to the Order Processing Center.

#### Scenario: Invoices are published to the Topic

- **GIVEN** a generated invoice for fulfilled items
- **WHEN** the invoice is ready to send
- **THEN** the invoice is published to jms/opc/InvoiceTopic via TopicConnectionFactory
