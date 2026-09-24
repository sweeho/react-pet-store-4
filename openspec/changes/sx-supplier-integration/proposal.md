# Supplier Integration Capability Proposal

## Executive Summary

This specification defines the supplier integration capability for an e-commerce order management system. The supplier module enables suppliers to receive purchase orders from the Order Processing Center (OPC) via asynchronous JMS messaging, check inventory availability, fulfill orders to the extent possible, and return invoices for shipped items.

## Problem Statement

The existing supplier module integrates with the broader order processing system through two primary responsibilities:

1. **Inbound**: Receive purchase orders from OPC as XML documents over JMS Queue
2. **Outbound**: Process orders against inventory and send back invoices for fulfilled items via JMS Topic

Suppliers also need a web-based interface to authenticate and manage inventory levels, triggering re-fulfillment of pending orders when new stock arrives.

## Business Context

- **Order Workflow**: OPC sends POs to supplier queue; supplier app processes async and publishes invoices
- **Inventory Management**: Suppliers update quantities via web UI; system re-attempts fulfillment of pending orders
- **Partial Fulfillment**: Supplier may not have all items in stock; system ships what's available and creates invoice for those items only
- **Transactionality**: Inventory updates, fulfillment, and invoice sending must succeed or fail as a unit

## Proposed Solution

### Data Model

- **SupplierOrder**: Persistent entity storing purchase orders with ID, date, status, and relationships to contact info and line items
- **ContactInfo**: Shipping/contact information automatically created for each order
- **LineItem**: Individual line items with product identifiers, quantities, and shipment tracking
- **Status Lifecycle**: PENDING → (APPROVED → COMPLETED) or PENDING → DENIED

### Processing Pipeline

1. SupplierOrderMDB receives JMS TextMessage with XML purchase order
2. Message delegated to OrderFulfillmentFacade for processing
3. Order parsed from XML and persisted
4. Each line item checked against inventory
5. Available items marked as shipped, inventory reduced, invoice generated
6. Invoice returned to OPC via JMS Topic
7. Unavailable items remain pending for later fulfillment

### Web Interface

- Form-based login (/login.jsp) with pre-filled "supplier" credentials
- Home page (/index.jsp) with navigation to inventory management or logout
- Session-based authentication with 54-minute timeout
- Role-based access control (administrator role required for inventory operations)
- RcvrRequestProcessor servlet routes requests based on currentScreen parameter

### Integration Points

- **Inbound**: JMS Queue with SupplierOrderMDB listener
- **Outbound**: JMS Topic (jms/opc/InvoiceTopic) for invoice publication
- **Configuration**: XML validation parameters via environment entries (DTD and XSD validation for orders and invoices)

## Key Requirements

### Functional

1. Receive and persist purchase orders from JMS Queue
2. Query orders by status (PENDING, APPROVED, DENIED, COMPLETED)
3. Check inventory and reduce quantities atomically
4. Support partial fulfillment with accurate line-item tracking
5. Generate invoices for shipped items with all required metadata
6. Publish invoices back to OPC via JMS Topic
7. Retry fulfillment of pending orders when inventory is updated

### Non-Functional

1. All database operations transactional (trans-attribute=Required)
2. Atomic inventory updates and invoice sends
3. Configurable XML validation (DTD and XSD)
4. Session timeout enforcement (54 minutes)
5. Form-based authentication with container-managed credentials

## Out of Scope

- Inventory population (delegated to PopulateServlet)
- OPC order placement logic
- Invoice receipt and processing by OPC
- Supplier role or permission management beyond administrator flag
- High availability or disaster recovery
- Audit logging or detailed transaction history

## Success Criteria

- All purchase orders received via JMS are persisted with correct status
- Inventory quantities are reduced only for fulfilled items
- Invoices contain all required fields and are published to correct topic
- Pending orders are re-attempted when inventory is updated
- Users can authenticate, view inventory, update quantities, and logout
- All operations execute within transactions with no partial state persisted
