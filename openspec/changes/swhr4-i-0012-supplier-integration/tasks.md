## 1. Data Model

- [ ] 1.1 Define the SupplierOrder entity with poId, poDate, poStatus fields and relationships
- [ ] 1.2 Define ContactInfo entity with shipping details (givenName, familyName, telephone, email)
- [ ] 1.3 Define LineItem entity with categoryId, productId, itemId, lineNumber, quantity, unitPrice, quantityShipped
- [ ] 1.4 Define the one-to-one relationship between SupplierOrder and ContactInfo with cascade-delete
- [ ] 1.5 Define the one-to-many relationship between SupplierOrder and LineItem with cascade-delete

## 2. Order Status Management

- [ ] 2.1 Implement order status lifecycle with PENDING, APPROVED, DENIED, COMPLETED states
- [ ] 2.2 Enforce valid state transitions: PENDING→APPROVED→COMPLETED or PENDING→DENIED
- [ ] 2.3 Initialize new orders with PENDING status
- [ ] 2.4 Implement findOrdersByStatus(String status) query method

## 3. Order Persistence and Retrieval

- [ ] 3.1 Implement SupplierOrder creation with transaction semantics (trans-attribute=Required)
- [ ] 3.2 Implement date conversion for storage (Date objects to/from milliseconds since epoch)
- [ ] 3.3 Implement findByPrimaryKey(String poId) finder method
- [ ] 3.4 Ensure all EJB methods execute within transactions with Required attribute
- [ ] 3.5 Apply unchecked security access to all SupplierOrder EJB methods

## 4. XML Serialization

- [ ] 4.1 Implement toXML() method for SupplierOrder with DTD conformance
- [ ] 4.2 Implement fromXML() method for SupplierOrder parsing
- [ ] 4.3 Format dates as yyyy-MM-dd strings in XML representation
- [ ] 4.4 Implement date parsing fallback to current date when parsing fails
- [ ] 4.5 Configure XML validation via environment entries (SupplierOrder validation, SupplierOrder XSD validation, Invoice XSD validation)

## 5. JMS Message Reception

- [ ] 5.1 Implement SupplierOrderMDB as message-driven bean listening to JMS Queue
- [ ] 5.2 Extract purchase order XML from TextMessage in onMessage() method
- [ ] 5.3 Delegate order processing to OrderFulfillmentFacade

## 6. Order Fulfillment

- [ ] 6.1 Implement processPO(String poXmlDoc) method to parse and persist orders
- [ ] 6.2 Implement inventory availability check before fulfillment
- [ ] 6.3 Implement inventory quantity reduction for fulfilled items
- [ ] 6.4 Support partial order fulfillment (ship available items, defer unavailable)
- [ ] 6.5 Track quantity shipped per line item

## 7. Invoice Generation and Publishing

- [ ] 7.1 Implement createInvoice() method with all required fields (orderId, userId, orderDate, shippingDate, lineItems)
- [ ] 7.2 Include only fulfilled line items in generated invoices
- [ ] 7.3 Implement invoice transmission to OPC via JMS Topic (jms/opc/InvoiceTopic)
- [ ] 7.4 Ensure invoices are only sent when items are fulfilled
- [ ] 7.5 Configure TopicConnectionFactory resource reference

## 8. Authentication and Authorization

- [ ] 8.1 Implement form-based authentication with /login.jsp and /error.jsp
- [ ] 8.2 Configure j_security_check form action in login.jsp
- [ ] 8.3 Pre-fill login form with default credentials (username: "supplier", password: "supplier")
- [ ] 8.4 Restrict RcvrRequestProcessor servlet access to administrator role
- [ ] 8.5 Implement role-based authorization checks in web pages

## 9. Web User Interface

- [ ] 9.1 Create home page at /index.jsp with navigation to inventory management and logout
- [ ] 9.2 Create login screen at /login.jsp with form-based authentication
- [ ] 9.3 Implement session management with 54-minute timeout
- [ ] 9.4 Implement logout functionality at /logout.jsp with session invalidation
- [ ] 9.5 Implement role-based visibility of admin-only functions

## 10. Request Handling and Routing

- [ ] 10.1 Implement RcvrRequestProcessor servlet with currentScreen parameter routing
- [ ] 10.2 Route displayinventory screen to show inventory list
- [ ] 10.3 Route logout screen to terminate session
- [ ] 10.4 Implement form submission handling in RcvrRequestProcessor
