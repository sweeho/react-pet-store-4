# Inventory Fulfillment Capability Proposal

## Executive Summary

This proposal documents the extraction and specification of the Inventory Fulfillment capability from the legacy Java Pet Store application. The capability enables suppliers to manage warehouse inventory, process purchase orders from the Order Processing Center, and fulfill customer orders based on available stock. The system supports partial fulfillment workflows where some items can ship immediately while others remain pending, and provides both programmatic APIs and a web-based management interface.

## What Is This Capability?

The Inventory Fulfillment capability encompasses the complete workflow for managing supplier inventory and fulfilling customer orders:

1. **Inventory Management**: Maintain stock records per item and provide APIs to query and reduce quantities
2. **Order Fulfillment**: Process purchase orders received from OPC, check inventory availability, and fulfill items that are in stock
3. **Partial Fulfillment Support**: Handle scenarios where only some items in an order can be fulfilled, shipping available items and marking others as pending
4. **Pending Order Retry**: When new inventory arrives, automatically reattempt fulfillment of previously pending orders
5. **Web Interface**: Provide suppliers with screens to view inventory, update quantities, and manage fulfillment operations

## Problem Statement

### Legacy Application Context

The Java Pet Store application is a 2000s-era J2EE reference implementation demonstrating enterprise Java patterns. The supplier module contains critical fulfillment logic scattered across:

- EJB entity beans (Inventory, LineItem)
- Session beans (OrderFulfillmentFacadeEJB)
- Message-driven beans (SupplierOrderMDB)
- JSP-based web screens
- Servlet controllers (RcvrRequestProcessor)

This logic must be preserved and migrated to a modern architecture while maintaining:

- Exact behavioral equivalence for inventory operations
- Support for partial fulfillment workflows
- Transactional consistency across order processing
- Role-based access control for inventory updates
- XML-based integration with the Order Processing Center

### Why Extraction Matters

Extracting this capability creates a clear specification for:

- **Rebuilding**: Implementing this capability in a modern stack without behavioral drift
- **Testing**: Verifying that replacement implementations handle all edge cases (insufficient inventory, missing items, partial shipments)
- **Documentation**: Capturing business rules that were previously implicit in code (e.g., how partial fulfillment decisions are made)
- **Integration**: Understanding the XML contracts and message flows that connect supplier systems to OPC

## Capability Scope

### In Scope

**Core Fulfillment Operations**:

- Inventory entity with item ID and quantity tracking
- Atomic inventory reduction on order fulfillment
- Inventory availability checking before fulfillment
- Purchase order processing (parsing, persistence, fulfillment)
- Partial fulfillment with selective shipping and invoice generation
- Pending order retry when new inventory arrives

**Web Management Interface**:

- Supplier login with administrator role enforcement
- Inventory list display with current quantities
- Quantity update interface with multi-item selection
- Home page with navigation to inventory and logout
- Form-based authentication and role-based access control

**Data Integration**:

- XML-based purchase order format (SupplierOrder)
- XML-based invoice format (with shipped line items)
- LineItem XML structure for order line items
- Inventory initialization from XML file

**Transactional Guarantees**:

- Atomic inventory reduction within fulfillment transactions
- Container-managed transactions for EJB operations
- User-managed transactions for web interface inventory updates

### Out of Scope

**Customer Order Processing** (handled by OPC module):

- Purchase order creation from customer checkout
- Order approval workflow
- Customer notification and delivery tracking

**Payment Processing**:

- Credit card validation
- Payment authorization (handled by checkout-payment capability)

**Catalog Management**:

- Product definitions
- Category hierarchies
- Pricing (unit prices are read from line items)

**Shipping & Logistics**:

- Carrier integration
- Shipping rate calculation
- Delivery tracking (beyond order status COMPLETED)

## Benefits of Migration

### For Operations

- **Predictable Behavior**: Clearly specified requirements eliminate ambiguity about partial fulfillment rules
- **Testability**: Comprehensive test scenarios (full fulfillment, partial fulfillment, no fulfillment) can be written upfront
- **Maintainability**: Modern architecture reduces cognitive load vs. J2EE patterns from 2000s

### For Development

- **Faster Onboarding**: New team members understand capability scope from specification
- **Safer Refactoring**: Golden set of requirements prevents accidental behavior changes
- **Modern Tools**: Leverage current frameworks (React, Vite, SQLite) vs. JSP/Struts patterns

### For Business

- **Feature Parity**: Ensures replacement implementation doesn't lose existing functionality
- **Risk Reduction**: Documented behavior reduces gaps when integrating with OPC
- **Flexibility**: Specification enables swapping implementations without changing interfaces

## Technical Approach

### Extraction Method

1. **Source Code Analysis**: Read legacy Java EJBs, servlets, and JSP files to understand workflows
2. **Declarative Configuration Review**: Examine web.xml, ejb-jar.xml for transaction attributes and security constraints
3. **XML Schema Analysis**: Identify required fields in SupplierOrder, LineItem, and Invoice documents
4. **Test Scenario Derivation**: Create GIVEN/WHEN/THEN scenarios from code logic
5. **Screen Documentation**: Document visible UI contracts without implementation details

### Requirements Specification

The capability specification includes:

- **14 Extracted Records** from legacy source code:
  - 3 Entity definitions (Inventory, LineItem, SupplierOrder)
  - 4 Business rules (inventory reduction, availability checking, partial fulfillment, data loading)
  - 3 Workflows (order processing, pending retry, inventory update)
  - 4 Screen requirements (login, inventory display, home page, and navigation)
  - 4 XML/document requirements (LineItem, SupplierOrder structures)

- **48 Test Scenarios** covering:
  - Happy path fulfillment (full, partial, none)
  - Error conditions (missing items, insufficient inventory)
  - UI interactions (display, update, navigation)
  - Authorization checks (role-based access)

### Migration Path

1. **Phase 1**: Implement data model (Inventory, LineItem entities)
2. **Phase 2**: Implement fulfillment APIs (inventory operations, order processing)
3. **Phase 3**: Implement web interface (JSP → React screens, servlet → Nitro routes)
4. **Phase 4**: Implement integration (JMS → modern messaging, XML → structured formats)
5. **Phase 5**: Validation (E2E tests against extracted requirements)

## Acceptance Criteria

The migration is successful when:

1. ✓ All 14 requirement records from legacy analysis are implemented
2. ✓ All 48 test scenarios pass (covering full/partial/no fulfillment, authorization, data formats)
3. ✓ Inventory reduction is atomic within transaction boundaries
4. ✓ Partial fulfillment correctly identifies shippable vs. pending items
5. ✓ Pending orders are retried when new inventory arrives
6. ✓ Web screens render with correct fields (item ID, quantity, checkboxes)
7. ✓ Role-based authorization prevents non-admin users from updating inventory
8. ✓ XML messages match SupplierOrder and Invoice DTD formats
9. ✓ No behavioral regressions vs. legacy implementation
10. ✓ Performance is acceptable for typical order volumes (< 1s per order fulfillment)

## Key Decisions

### Why Extract Now?

The legacy J2EE stack (JSP, EJB, Struts) is:

- Difficult to onboard new team members
- Hard to integrate with modern monitoring/observability tooling
- Incompatible with containerized deployment patterns

Extracting requirements upfront allows parallel development:

- Legacy system continues operating during migration
- New implementation tested against specification
- Confidence in behavioral equivalence before cutover

### Why This Scope?

The inventory fulfillment capability was chosen as an extraction candidate because:

- It is relatively self-contained (minimal dependencies on other modules except OPC integration)
- It includes both programmatic logic and web UI
- It has complex business logic (partial fulfillment state machine)
- It is critical to order delivery workflows

## Risks & Mitigation

| Risk                     | Impact                             | Mitigation                                                                                             |
| ------------------------ | ---------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Specification incomplete | Migrated system missing features   | Comprehensive IR analysis across multiple code paths; testing against extracted scenarios catches gaps |
| Ambiguous requirements   | Reimplementation misses edge cases | GIVEN/WHEN/THEN scenarios make expectations explicit; code comments for non-obvious logic              |
| Performance regression   | Orders process too slowly          | Benchmark legacy fulfillment; profile new implementation; optimize database queries                    |
| Authorization bypass     | Non-admins can update inventory    | Role checks in web layer + API layer; security-focused test scenarios                                  |

## Next Steps

1. Validate specification with subject matter experts (supplier operations team, OPC integration lead)
2. Begin implementation against extracted requirements
3. Write E2E tests covering all 48 scenarios
4. Run parallel testing with legacy system during cutover window
5. Monitor fulfillment metrics post-migration (latency, error rates)

## Appendix: Record Extraction Summary

**Sources**:

- `legacy-source/petstore1.3.2/src/apps/supplier/src/` (supplier module)
- `legacy-source/petstore1.3.2/src/apps/opc/src/` (OPC module, fulfillment initiation)
- `legacy-source/petstore1.3.2/src/components/xmldocuments/` (XML document formats)
- `legacy-source/petstore1.3.2/src/components/lineitem/` (LineItem entity)

**Record Breakdown**:

- Entities: SUPP-INV-0001, IF-ENTITY-0005, IF-ENTITY-0006
- Business Rules: SUPP-INV-REDUCE-0001, SUPP-INV-CHECK-0001, SUPP-INV-PARTIAL-FULFILL-0001, SUPP-DATA-POPULATE-0001
- Workflows: SUPP-PO-PROCESS-0001, SUPP-INV-RETRY-PENDING-0001, SUPP-INVENTORY-UPDATE-0001
- Screens: SI-SCREEN-0008, SI-SCREEN-0009, SI-SCREEN-0010, SUPP-SCREEN-INVENTORY-0001
- OPC Integration: inventory-fulfillment-req-0001, inventory-fulfillment-req-0002, inventory-fulfillment-req-0003

**Confidence Levels**:

- 12 records marked "high" confidence (declarative sources or multi-point confirmation)
- 2 records marked "medium" confidence (configuration-only or limited visibility)
