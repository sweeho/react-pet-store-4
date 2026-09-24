## 1. Data model

- [ ] 1.1 Define the OrderApproval entity with its structure (Order entries containing OrderId and OrderStatus)
- [ ] 1.2 Define the ChangedOrder entity for representing order status changes in approval messages
- [ ] 1.3 Implement OrderApproval XML serialization and deserialization with DTD validation

## 2. Purchase order workflow integration

- [ ] 2.1 Implement JMS message listener to receive purchase orders from the PurchaseOrderQueue
- [ ] 2.2 Implement XML parsing and validation for incoming purchase order documents
- [ ] 2.3 Create PurchaseOrder EJB instance from parsed XML and persist to database
- [ ] 2.4 Initialize order fulfillment workflow in ProcessManager with PENDING status

## 3. Automatic approval logic

- [ ] 3.1 Implement auto-approval threshold check for US locale (< 500 USD)
- [ ] 3.2 Implement auto-approval threshold check for Japan locale (< 50000 JPY)
- [ ] 3.3 Generate OrderApproval message for automatically approved orders
- [ ] 3.4 Route auto-approval messages to OrderApprovalQueue for downstream processing

## 4. Admin approval interface

- [ ] 4.1 Implement XML request handling for retrieving orders by status
- [ ] 4.2 Implement order status update via XML requests with order ID and new status
- [ ] 4.3 Create OrderApproval documents from admin approval decisions
- [ ] 4.4 Route approval decisions to AsyncSender EJB for asynchronous processing

## 5. Order approval message processing

- [ ] 5.1 Implement JMS message listener for OrderApprovalQueue
- [ ] 5.2 Validate that only PENDING orders are processed (guard against reprocessing)
- [ ] 5.3 Update order workflow status to APPROVED or DENIED based on approval message
- [ ] 5.4 Collect approved orders for supplier integration
- [ ] 5.5 Collect all approval decisions for customer notification

## 6. Supplier order generation

- [ ] 6.1 For each approved order, retrieve PurchaseOrder EJB with all order details
- [ ] 6.2 Extract order ID, date, contact info, and shipping address from PurchaseOrder
- [ ] 6.3 Extract all line items with category ID, product ID, item ID, line number, quantity, and unit price
- [ ] 6.4 Construct TPA Supplier Order XML document with namespace and schema compliance

## 7. Order fulfillment workflow

- [ ] 7.1 Maintain order workflow states: PENDING, APPROVED, DENIED, SHIPPED_PART, COMPLETED
- [ ] 7.2 Enforce state transitions through ProcessManager with guard conditions
- [ ] 7.3 Ensure no duplicate processing via PENDING status validation
- [ ] 7.4 Support status queries to determine current order fulfillment state

## 8. XML document handling

- [ ] 8.1 Implement OrderApproval DTD schema with Order and OrderStatus elements
- [ ] 8.2 Configure XML validation with DTD public identifier
- [ ] 8.3 Support both serialization and deserialization of OrderApproval documents
- [ ] 8.4 Handle XML parsing errors and validation failures with appropriate exceptions

## 9. Integration with downstream services

- [ ] 9.1 Route approved orders to supplier queue for supplier order processing
- [ ] 9.2 Route approval/denial notifications to mail queue for customer notifications
- [ ] 9.3 Ensure transactional integrity of approval message processing
- [ ] 9.4 Handle JMS exceptions and message delivery failures

## 10. Testing and validation

- [ ] 10.1 Write tests for auto-approval thresholds in different locales
- [ ] 10.2 Write tests for order status transitions and guard conditions
- [ ] 10.3 Write tests for XML serialization/deserialization of OrderApproval documents
- [ ] 10.4 Write tests for admin XML request handling and response generation
- [ ] 10.5 Write integration tests for end-to-end order approval workflow
