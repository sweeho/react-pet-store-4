## ADDED Requirements

### Requirement: Purchase order acceptance and workflow initialization

The system SHALL accept purchase orders from the Java Pet Store via JMS message queue, parse the XML purchase order document, create a PurchaseOrder EJB entity, and initialize the order fulfillment workflow with initial status PENDING.

#### Scenario: Purchase order received and stored

- **GIVEN** a purchase order XML message in the PurchaseOrderQueue
- **WHEN** the message is processed by PurchaseOrderMDB
- **THEN** the PurchaseOrder EJB is created with all order details (OrderId, UserId, EmailId, OrderDate, Locale, TotalPrice) and the workflow is initialized in PENDING status

### Requirement: Automatic approval for small US orders

The system SHALL automatically approve purchase orders originating from the US locale with a total price less than 500 USD during order receipt processing, generating an OrderApproval message for downstream processing.

#### Scenario: US order under threshold is auto-approved

- **GIVEN** a purchase order from US locale with total price 350 USD
- **WHEN** the order is processed by PurchaseOrderMDB
- **THEN** an OrderApproval message is generated with status APPROVED and sent to OrderApprovalQueue

#### Scenario: US order at or above threshold requires manual approval

- **GIVEN** a purchase order from US locale with total price 500 USD
- **WHEN** the order is processed by PurchaseOrderMDB
- **THEN** no OrderApproval message is generated and the order remains in PENDING status

### Requirement: Automatic approval for small Japan orders

The system SHALL automatically approve purchase orders originating from the Japan locale with a total price less than 50000 (assumed JPY) during order receipt processing, generating an OrderApproval message for downstream processing.

#### Scenario: Japan order under threshold is auto-approved

- **GIVEN** a purchase order from Japan locale with total price 40000 JPY
- **WHEN** the order is processed by PurchaseOrderMDB
- **THEN** an OrderApproval message is generated with status APPROVED and sent to OrderApprovalQueue

#### Scenario: Japan order at or above threshold requires manual approval

- **GIVEN** a purchase order from Japan locale with total price 50000 JPY
- **WHEN** the order is processed by PurchaseOrderMDB
- **THEN** no OrderApproval message is generated and the order remains in PENDING status

### Requirement: OrderApproval document structure

The system SHALL support OrderApproval XML documents containing one or more Order entries, each with an OrderId and OrderStatus, conforming to the OrderApproval DTD schema.

#### Scenario: OrderApproval document is created with multiple orders

- **GIVEN** an order approval batch containing three orders with different statuses
- **WHEN** the batch is serialized to XML
- **THEN** the XML contains an OrderApproval root element with three Order child elements, each containing OrderId and OrderStatus

### Requirement: OrderApproval XML validation

The system SHALL validate OrderApproval documents against the DTD on deserialization, throwing an XMLDocumentException if validation fails.

#### Scenario: OrderApproval document passes validation

- **GIVEN** a valid OrderApproval XML document conforming to the DTD
- **WHEN** deserialization is performed via OrderApproval.fromXML()
- **THEN** an in-memory OrderApproval object is created without errors

#### Scenario: OrderApproval document fails validation

- **GIVEN** an OrderApproval XML document missing required Order elements
- **WHEN** deserialization is performed via OrderApproval.fromXML()
- **THEN** an XMLDocumentException is thrown

### Requirement: Prevent reprocessing of approved orders

The system SHALL reject processing of approval messages for orders that are not in PENDING status, preventing duplicate processing of orders already APPROVED, DENIED, or COMPLETED.

#### Scenario: Only PENDING orders are processed

- **GIVEN** an OrderApproval message containing orders with mixed statuses (PENDING, APPROVED, DENIED)
- **WHEN** the message is processed by OrderApprovalMDB
- **THEN** only the PENDING order is processed; APPROVED and DENIED orders are skipped

### Requirement: Order status transition on approval

The system SHALL update the order fulfillment workflow status to match the approval decision (APPROVED or DENIED) when an order approval message is processed.

#### Scenario: Order status is updated to APPROVED

- **GIVEN** an OrderApproval message with an order in status APPROVED
- **WHEN** the message is processed by OrderApprovalMDB for a PENDING order
- **THEN** the order workflow status is updated to APPROVED

#### Scenario: Order status is updated to DENIED

- **GIVEN** an OrderApproval message with an order in status DENIED
- **WHEN** the message is processed by OrderApprovalMDB for a PENDING order
- **THEN** the order workflow status is updated to DENIED

### Requirement: Supplier purchase order generation

For each approved order in an order approval message, the system SHALL generate a TPA Supplier Purchase Order containing the order ID, order date, complete customer contact and shipping address information, and all line items with their category ID, product ID, item ID, line number, quantity, and unit price.

#### Scenario: Supplier PO is generated for approved orders

- **GIVEN** an order approval message with two orders (one APPROVED, one DENIED)
- **WHEN** the message is processed by OrderApprovalMDB
- **THEN** exactly one TPA Supplier Purchase Order XML is generated for the APPROVED order containing all order and line item details

### Requirement: Admin retrieval of orders by status

The system SHALL provide an interface for authenticated administrators to retrieve purchase orders filtered by status (PENDING, APPROVED, DENIED, COMPLETED, SHIPPED_PART) via XML-based requests, returning order ID, user ID, order date, order amount, and order status.

#### Scenario: Admin retrieves PENDING orders

- **GIVEN** an authenticated admin with administrator role submitting XML request with Status=PENDING
- **WHEN** ApplRequestProcessor processes the GETORDERS request
- **THEN** an XML response is returned containing all orders in PENDING status with their details

### Requirement: Admin order status update

The system SHALL allow authenticated administrators to update order statuses (approve or deny) via XML requests containing one or more orders with order ID and new status values, transmitting the update to the AsyncSender EJB for asynchronous processing.

#### Scenario: Admin updates multiple orders with new status

- **GIVEN** an XML request containing Order elements with OrderId and OrderStatus (e.g., APPROVED, DENIED)
- **WHEN** ApplRequestProcessor processes the UPDATESTATUS request
- **THEN** an OrderApproval XML document is created and sent to AsyncSender EJB for asynchronous processing

### Requirement: OrderApproval XML serialization with DTD metadata

The system SHALL serialize OrderApproval documents to XML with the DTD public identifier "-//Sun Microsystems, Inc. - J2EE Blueprints Group//DTD Order Approval 1.0//EN" and support validation via DTD.

#### Scenario: OrderApproval XML includes DTD public identifier

- **GIVEN** an OrderApproval object with multiple orders
- **WHEN** serialized to XML via OrderApproval.toXML()
- **THEN** the output XML declares the DTD public identifier and can be validated against the DTD
