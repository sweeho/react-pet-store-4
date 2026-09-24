## 1. Data model

- [ ] 1.1 Define the Inventory entity with itemId (primary key) and quantity fields
- [ ] 1.2 Define the LineItem entity with seven fields: categoryId, productId, itemId, lineNumber, quantity, unitPrice, quantityShipped
- [ ] 1.3 Define persistence mappings for Inventory and LineItem entities to database schema

## 2. Inventory operations

- [ ] 2.1 Implement inventory quantity retrieval by item ID
- [ ] 2.2 Implement atomic inventory quantity reduction with transactional semantics
- [ ] 2.3 Implement inventory availability checking that returns boolean success/failure
- [ ] 2.4 Handle inventory lookup failures (item not found) gracefully

## 3. Order fulfillment workflow

- [ ] 3.1 Implement XML parsing for supplier purchase orders (SupplierOrder format)
- [ ] 3.2 Implement order persistence (SupplierOrderLocal entity creation)
- [ ] 3.3 Implement line item iteration and inventory checking for each item
- [ ] 3.4 Implement partial fulfillment logic with item status tracking (shipped vs not shipped)
- [ ] 3.5 Implement invoice generation with only shipped items

## 4. Pending order fulfillment

- [ ] 4.1 Implement query to find all orders with PENDING status
- [ ] 4.2 Implement retry fulfillment for each pending order when inventory updates occur
- [ ] 4.3 Implement invoice collection and transmission to Order Processing Center
- [ ] 4.4 Wrap pending fulfillment logic in user-managed transactions

## 5. XML document handling

- [ ] 5.1 Implement LineItem XML serialization with all six required fields (CategoryId, ProductId, ItemId, LineNum, Quantity, UnitPrice)
- [ ] 5.2 Implement SupplierOrder XML serialization with OrderId, OrderDate, ShippingAddress, and LineItems
- [ ] 5.3 Implement XML document parsing utilities for deserialization
- [ ] 5.4 Implement invoice XML generation with line items

## 6. Inventory initialization

- [ ] 6.1 Implement PopulateServlet to read /populate/Populate-UTF8.xml
- [ ] 6.2 Implement XML to inventory object mapping for batch loading
- [ ] 6.3 Implement inventory entity creation from XML data

## 7. Web interface - screens

- [ ] 7.1 Create login screen (/login.jsp) with username and password fields
- [ ] 7.2 Implement form-based authentication with j_security_check action
- [ ] 7.3 Implement role-based authorization check for administrator role
- [ ] 7.4 Create inventory display screen (/displayinventory.jsp)
- [ ] 7.5 Implement inventory item listing with table display (Item ID, Existing Quantity columns)
- [ ] 7.6 Implement new quantity input fields (name pattern: qty\_<itemId>)
- [ ] 7.7 Implement item selection checkboxes (name pattern: item\_<itemId>)
- [ ] 7.8 Create home page (/index.jsp) with navigation links
- [ ] 7.9 Implement "Display Inventory" form button
- [ ] 7.10 Implement "Logout" form button

## 8. Web interface - backend

- [ ] 8.1 Implement RcvrRequestProcessor servlet to handle inventory display requests
- [ ] 8.2 Implement DisplayInventoryBean JSP bean with session scope
- [ ] 8.3 Implement getInventory() method to retrieve all inventory items
- [ ] 8.4 Implement inventory update request handler (currentScreen=updateinventory)
- [ ] 8.5 Parse qty*\* and item*\* parameters for quantity updates
- [ ] 8.6 Update selected inventory items in the database
- [ ] 8.7 Implement logout request handler (currentScreen=logout)
- [ ] 8.8 Implement session invalidation on logout

## 9. Transaction management

- [ ] 9.1 Configure container-managed transactions for order fulfillment operations
- [ ] 9.2 Configure transaction attribute "Required" for inventory operations
- [ ] 9.3 Implement user-managed transactions for inventory update + pending fulfillment flow
- [ ] 9.4 Implement transaction boundary management around fulfillment and invoice sending

## 10. Integration with Order Processing Center

- [ ] 10.1 Implement JMS queue connection for receiving supplier purchase orders
- [ ] 10.2 Implement message-driven bean (SupplierOrderMDB) for order reception
- [ ] 10.3 Implement transition delegate for sending invoices back to OPC
- [ ] 10.4 Implement invoice XML format for OPC ingestion

## 11. Business rule validation

- [ ] 11.1 Implement negative quantity prevention (quantity >= 0 validation)
- [ ] 11.2 Implement order status state machine (PENDING → COMPLETED transitions)
- [ ] 11.3 Implement partial fulfillment flag (invoiceReqd) logic
- [ ] 11.4 Implement order completion detection when all line items shipped
