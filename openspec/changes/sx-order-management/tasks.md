## 1. Data Model & Schema

- [ ] 1.1 Define Counter entity with name (primary key) and counter (integer) fields
- [ ] 1.2 Define PurchaseOrder entity with poId, poUserId, poEmailId, poDate (epoch millis), poLocale, poValue
- [ ] 1.3 Define LineItem entity with categoryId, productId, itemId, lineNumber, quantity, unitPrice, quantityShipped
- [ ] 1.4 Define ContactInfo entity with given_name, family_name, address_1, address_2, city, state_prov, postal_code, country, telephone, email
- [ ] 1.5 Define CreditCard entity with cardNumber, cardType, expiryDate
- [ ] 1.6 Define relationships: PurchaseOrder one-to-many LineItem (cascade delete), PurchaseOrder one-to-one ContactInfo (shipping, cascade delete), PurchaseOrder one-to-one ContactInfo (billing, cascade delete), PurchaseOrder one-to-one CreditCard (cascade delete)
- [ ] 1.7 Create Drizzle schema files and migrations for all entities and relationships

## 2. ID Generation Service

- [ ] 2.1 Implement Counter repository with findByName() and create() methods
- [ ] 2.2 Implement UniqueIdGeneratorService with getUniqueId(prefix) method that auto-creates Counter on first call
- [ ] 2.3 Ensure getUniqueId() is transactional and atomic; concurrent calls return unique values
- [ ] 2.4 Implement Counter.getNextValue() to return formatted string "prefixN"
- [ ] 2.5 Write tests for ID generation: first call, subsequent calls, concurrent calls

## 3. Order Creation

- [ ] 3.1 Implement PurchaseOrderRepository with create() method
- [ ] 3.2 Implement ContactInfoRepository with create() method
- [ ] 3.3 Implement CreditCardRepository with create() method
- [ ] 3.4 Implement LineItemRepository with create() method
- [ ] 3.5 Implement OrderCreationService that coordinates creation of order, contacts, card, and line items
- [ ] 3.6 Implement transaction wrapper to ensure atomicity: all-or-nothing creation
- [ ] 3.7 Implement validation: order must have at least one line item
- [ ] 3.8 Implement timestamp capture: orderDate set to current system time in epoch millis
- [ ] 3.9 Write integration tests for full order creation workflow

## 4. Order Entry Screen

- [ ] 4.1 Design React component structure for order information form
- [ ] 4.2 Implement form with separate Billing section collecting: given name, family name, street address 1, street address 2, city, state/province, postal code, country, telephone
- [ ] 4.3 Implement form with separate Shipping section with identical fields
- [ ] 4.4 Implement form validation: all fields required, field length limits (given_name max 30)
- [ ] 4.5 Implement form submission handling to create ContactInfo and CreditCard entities
- [ ] 4.6 Implement error display for validation failures
- [ ] 4.7 Write UI tests for form display, validation, and submission

## 5. Line Item Management

- [ ] 5.1 Implement LineItem.getData() method returning data transfer object with all 6 fields
- [ ] 5.2 Implement LineItem.setQuantityShipped() setter with transaction isolation
- [ ] 5.3 Implement LineItemRepository.findByOrder(orderId) to retrieve all line items for an order
- [ ] 5.4 Write tests for line item CRUD operations and transaction isolation

## 6. Partial Shipment Fulfillment

- [ ] 6.1 Implement FulfillmentService.processInvoice(orderId, itemShipmentMap) method
- [ ] 6.2 Implement invoice line item parsing: Map[itemId] → shippedQuantity
- [ ] 6.3 Implement accumulation logic: quantityShipped += shippedQuantity for each item
- [ ] 6.4 Implement fulfillment check: order complete when all items have quantity == quantityShipped
- [ ] 6.5 Write tests for partial shipment scenarios and fulfillment status

## 7. Order Querying

- [ ] 7.1 Implement PurchaseOrderRepository.findById(orderId) method
- [ ] 7.2 Implement PurchaseOrderRepository.findByDateRange(beginEpoch, endEpoch) method using BETWEEN query
- [ ] 7.3 Implement order retrieval that includes all related entities (contacts, card, line items)
- [ ] 7.4 Implement proper error handling for non-existent orders
- [ ] 7.5 Write tests for retrieval by ID and date range queries

## 8. Transaction & Isolation

- [ ] 8.1 Configure transaction middleware for all order operations
- [ ] 8.2 Implement transaction wrapper for order creation (atomic multi-entity operation)
- [ ] 8.3 Implement transaction wrapper for invoice processing (line item updates)
- [ ] 8.4 Test concurrent operations: simultaneous ID generation, simultaneous invoice processing
- [ ] 8.5 Verify no lost updates or dirty reads in concurrent scenarios

## 9. API Routes

- [ ] 9.1 Implement POST /api/orders/create endpoint (order creation)
- [ ] 9.2 Implement GET /api/orders/:id endpoint (order retrieval)
- [ ] 9.3 Implement GET /api/orders/range endpoint with begin and end query parameters
- [ ] 9.4 Implement POST /api/orders/:id/invoice endpoint (process supplier invoice)
- [ ] 9.5 Implement GET /api/orders/:id/fulfillment endpoint (check fulfillment status)
- [ ] 9.6 Add proper error responses (400 for validation, 404 for not found, 500 for server errors)

## 10. Documentation & Verification

- [ ] 10.1 Document API request/response shapes for each endpoint
- [ ] 10.2 Document validation error codes and messages
- [ ] 10.3 Create postman collection or equivalent for API testing
- [ ] 10.4 Verify all acceptance criteria from spec.md are met
- [ ] 10.5 Verify all scenarios in spec.md pass E2E tests
- [ ] 10.6 Document migration guide from legacy J2EE to new implementation
