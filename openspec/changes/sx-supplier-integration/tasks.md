# Implementation Tasks

## 1. Data Model & Entities

- [ ] 1.1 Define SupplierOrder entity with fields: orderId, orderDate, orderStatus, and relationships to line items
- [ ] 1.2 Define LineItem entity with fields: lineId, itemId, quantity, quantityShipped, unitPrice, categoryId, productId, lineNumber
- [ ] 1.3 Define Inventory entity with fields: itemId (primary key), quantity
- [ ] 1.4 Implement order status lifecycle with states: PENDING, APPROVED, COMPLETED, DENIED
- [ ] 1.5 Add database constraints: non-negative quantities, valid status values, unique order IDs

## 2. Authentication & Authorization

- [ ] 2.1 Implement form-based authentication with username/password validation
- [ ] 2.2 Create login page with pre-filled default credentials (username: "supplier", password: "supplier")
- [ ] 2.3 Create login error page for failed authentication
- [ ] 2.4 Implement role-based authorization: restrict inventory operations to "administrator" role
- [ ] 2.5 Configure session timeout: 54 minutes with automatic re-authentication on expiry
- [ ] 2.6 Create logout endpoint that invalidates user session

## 3. Inventory Management UI & Operations

- [ ] 3.1 Create home page displaying navigation options: "View Inventory" and "Logout"
- [ ] 3.2 Create inventory display page showing all items with: itemId, current quantity, and input field for new quantity
- [ ] 3.3 Implement bulk quantity update with checkboxes to select items for update
- [ ] 3.4 Add role-based display restriction: show authorization error if user lacks administrator role
- [ ] 3.5 Implement inventory entity retrieval from persistent store
- [ ] 3.6 Implement inventory quantity update with positive integer validation

## 4. Purchase Order Reception & Parsing

- [ ] 4.1 Set up JMS message queue receiver (SupplierOrderMDB) to listen for inbound purchase orders
- [ ] 4.2 Parse purchase order XML documents to SupplierOrder objects via XML transformation handler
- [ ] 4.3 Validate incoming PO XML against schema (configurable, default enabled)
- [ ] 4.4 Handle XML parsing errors with structured logging

## 5. Purchase Order Persistence & Retrieval

- [ ] 5.1 Persist incoming purchase orders to database (SupplierOrderEJB equivalent)
- [ ] 5.2 Implement order status query: find all orders by status (used for pending order retry)
- [ ] 5.3 Implement order detail retrieval: fetch order with all line items
- [ ] 5.4 Implement order status update: transition order through states

## 6. Inventory Fulfillment Logic

- [ ] 6.1 Implement inventory availability check: verify stock >= requested quantity for each line item
- [ ] 6.2 Implement inventory reduction: decrement quantity by fulfilled amount in atomic operation
- [ ] 6.3 Implement partial fulfillment: process available items even if some cannot be fulfilled
- [ ] 6.4 Track fulfillment state: mark line items as shipped when fulfilled
- [ ] 6.5 Implement fulfillment retry: when inventory is updated, retry fulfillment of all pending orders
- [ ] 6.6 Wrap multi-step fulfillment operations in database transactions

## 7. Invoice Generation & Distribution

- [ ] 7.1 Generate invoice XML with order ID, user ID, order date, shipping date, and line items
- [ ] 7.2 Filter invoice to include only fulfilled line items (not pending items)
- [ ] 7.3 Validate generated invoice XML against schema (configurable, default enabled)
- [ ] 7.4 Set up JMS topic publisher to send invoices to Order Processing Center
- [ ] 7.5 Handle failed invoice generation with retry or escalation logic
- [ ] 7.6 Configure JMS topic connection factory for invoice distribution

## 8. Inventory Population & Initialization

- [ ] 8.1 Create servlet endpoint at /Populate to load initial inventory data
- [ ] 8.2 Parse inventory XML from /populate/Populate-UTF8.xml (UTF-8 encoded)
- [ ] 8.3 Create inventory entities from parsed XML during application initialization
- [ ] 8.4 Handle XML parsing errors and missing data file gracefully

## 9. Web Tier & Request Routing

- [ ] 9.1 Create request processor servlet to handle form submissions (currentScreen parameter routing)
- [ ] 9.2 Implement request parameter parsing: extract item IDs and quantities from request parameters
- [ ] 9.3 Route requests to appropriate handlers: displayinventory, updateinventory, logout
- [ ] 9.4 Add null check for required parameters to prevent NullPointerException
- [ ] 9.5 Implement request forwarding to JSP pages for rendering

## 10. Configuration & Integration Points

- [ ] 10.1 Configure XML validation settings: enable/disable for SupplierOrder and Invoice
- [ ] 10.2 Configure JMS queue for inbound purchase orders (connection factory and queue JNDI reference)
- [ ] 10.3 Configure JMS topic for outbound invoices (connection factory and topic JNDI reference)
- [ ] 10.4 Configure XML entity catalog URL for schema resolution
- [ ] 10.5 Configure default session timeout value: 54 minutes

## 11. Error Handling & Logging

- [ ] 11.1 Add structured logging for order reception and processing
- [ ] 11.2 Add error logging for inventory insufficient stock conditions
- [ ] 11.3 Add error logging for XML validation failures
- [ ] 11.4 Add error logging for database transaction rollbacks
- [ ] 11.5 Implement graceful error responses to UI (avoid exposing internal errors)

## 12. Testing & Validation

- [ ] 12.1 Unit test: Inventory reduction logic with various quantity scenarios
- [ ] 12.2 Unit test: Order status lifecycle and state transitions
- [ ] 12.3 Unit test: Partial fulfillment with multiple line items
- [ ] 12.4 Integration test: PO reception, persistence, and fulfillment workflow
- [ ] 12.5 Integration test: Inventory update and pending order retry
- [ ] 12.6 Integration test: Invoice generation with only fulfilled items
- [ ] 12.7 E2E test: Full supplier workflow from login through inventory update
- [ ] 12.8 E2E test: Session timeout and re-authentication
- [ ] 12.9 E2E test: Authorization check (non-admin users blocked from inventory operations)
