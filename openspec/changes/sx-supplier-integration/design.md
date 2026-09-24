# Supplier Integration Design

## Overview

The supplier integration capability enables the supplier module to receive purchase orders from the Order Processing Center via JMS messaging, process those orders against inventory, fulfill what's available, and send back invoices for shipped items. The module includes both backend processing (EJBs and JMS) and a web-based frontend for supplier staff to manage inventory and authenticate.

## Architecture

### Backend Components

**Message-Driven Bean (SupplierOrderMDB)**

- Listens to JMS Queue for incoming purchase order XML messages
- Extracts TextMessage content and delegates to OrderFulfillmentFacade
- Handles invoice transmission after fulfillment
- Transaction type: Container-managed

**Order Fulfillment Facade (OrderFulfillmentFacadeEJB)**

- Parses purchase order XML via TPASupplierOrderXDE
- Persists orders to the SupplierOrder entity
- Implements fulfillment logic: inventory checks, quantity reduction, line item tracking
- Generates invoice XML for shipped items via TPAInvoiceXDE
- Transaction attribute: Required (all methods)
- Queries pending orders for retry fulfillment when inventory is updated

**Entity Beans**

- **SupplierOrderEJB**: CMP Entity bean with poId (String, primary key), poDate (long), poStatus (String), plus relationships to ContactInfo and LineItems
- **ContactInfoEJB**: Stores shipping/contact information (givenName, familyName, telephone, email)
- **LineItemEJB**: Stores individual line items with categoryId, productId, itemId, lineNumber, quantity, unitPrice, quantityShipped
- All use two-phase creation: ejbCreate for CMP field initialization, ejbPostCreate for relationship setup

### Data Model

**SupplierOrder CMP Entity**

- Primary Key: poId (java.lang.String)
- Fields: poDate (long, milliseconds since epoch), poStatus (String)
- One-to-One with ContactInfo: unidirectional, cascade-delete on ContactInfo side
- One-to-Many with LineItem: unidirectional, cascade-delete on LineItem side
- Finder methods: findByPrimaryKey(String), findOrdersByStatus(String status)

**Status Lifecycle**

- PENDING: newly created orders
- APPROVED: order approved for fulfillment
- COMPLETED: all line items shipped
- DENIED: order rejected
- Valid transitions: PENDING→APPROVED→COMPLETED or PENDING→DENIED

**Date Handling**

- Orders store dates as long (milliseconds since epoch) in the database
- XML representation uses yyyy-MM-dd format (SimpleDateFormat pattern)
- Conversion occurs at persistence boundaries (ejbCreate) and retrieval (getData)
- Fallback to current date if XML parsing fails (logged to stderr)

**XML Processing**

- Validation parameters configured via environment entries:
  - param/xml/validation/SupplierOrder
  - param/xml/xsdvalidation/SupplierOrder
  - param/xml/xsdvalidation/Invoice
- Supplier order documents validated per SupplierOrder.dtd
- Invoice documents validated per schema configuration

### JMS Integration

**Incoming Queue**

- Message type: TextMessage containing XML purchase order
- Listener: SupplierOrderMDB
- Processing: one-way conversion to order objects and persistence

**Outgoing Topic**

- Topic name: jms/opc/InvoiceTopic
- Message type: TextMessage containing XML invoice
- Publisher: SupplierOrderMDB via TransitionDelegate
- Trigger: Only sent when items were fulfilled (non-null invoice)

### Web Tier

**Authentication**

- Method: Form-based via web.xml login-config
- Form endpoint: /login.jsp posting to j_security_check
- Error page: /error.jsp
- Realm: default (container-managed)

**Navigation**

- Entry point: /index.jsp (welcome file)
- Logout: /logout.jsp (invalidates session)
- Protected resource: RcvrRequestProcessor servlet (administrator role required)
- Session timeout: 54 minutes (web.xml session-config)

**Servlet Routing**

- RcvrRequestProcessor handles currentScreen parameter:
  - currentScreen=displayinventory → forward to displayinventory.jsp
  - currentScreen=logout → forward to logout.jsp
  - currentScreen=updateinventory → call updateInventory(), processPendingPO(), sendInvoices() within UserTransaction

**Login JSP**

- Location: /login.jsp
- Form: posts to j_security_check with j_username and j_password fields
- Pre-fills username and password with "supplier"

**Home JSP**

- Location: /index.jsp
- Displays purpose of supplier inventory module
- Two forms: one to display inventory, one to logout
- Both submit to RcvrRequestProcessor via POST

## Implementation Notes

### Legacy Stack Metadata

- Framework: EJB 2.x (CMP), JSP, Servlet, JMS, Container-managed transactions
- Authentication: Form-based (j_security_check)
- Authorization: Role-based (administrator role for RcvrRequestProcessor)
- Transaction model: Container-managed (trans-attribute=Required) for EJBs, UserTransaction for servlet-level coordination
- XML processing: DOM-based serialization/deserialization with custom DTD/XSD validation

### Known Constraints

1. **Date Parsing Fallback**: XML parsing errors default to current date with stderr logging only. No retry or validation of fallback behavior documented.

2. **Partial Fulfillment Semantics**: Line items can be partially shipped. The order transitions to COMPLETED only if ALL line items are fulfilled (allItemsAvailable flag). Unclear whether partial COMPLETED at line level affects order status.

3. **Inventory Not Found**: FinderException when inventory doesn't exist is swallowed and treated same as insufficient quantity. No distinction between "never populated" and "insufficient stock".

4. **Invoice Generation Failures**: XMLDocumentException in createInvoice is caught and null returned, printed to System.out. No alerting or retry mechanism specified.

5. **Quantity Validation**: updateInventory() accepts any non-negative integer. No upper bounds or sanity checks for large values.

6. **Missing Parameter Handling**: RcvrRequestProcessor.doPost() assumes currentScreen parameter exists; NullPointerException possible if missing.

7. **Silent Inventory Update Failures**: updateInventory() catches FinderException and silently continues. User receives no feedback on which updates succeeded or failed.

## Screen Behavior

### Login Screen (/login.jsp)

- Rendered when unauthenticated user accesses protected resources
- Form posts username and password to j_security_check
- Pre-filled with "supplier" credentials
- Error page (/error.jsp) shown on auth failure
- Form-based mechanism: container handles credential validation

### Home Page (/index.jsp)

- Accessible after successful authentication
- Displays two navigation options:
  1. "Display Inventory" button → submits form with currentScreen=displayinventory
  2. "Logout" button → submits form with currentScreen=logout
- Both forms POST to RcvrRequestProcessor servlet
- No direct page display of inventory; delegated to servlet routing
