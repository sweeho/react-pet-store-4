# SX-0001 Discovery Report: Java Pet Store 1.3.2

**Date**: 2026-09-24  
**Version**: SX-0001  
**Status**: Discovery Phase Complete

---

## Executive Summary

This legacy J2EE application is a complete e-commerce platform implementing the Sun Microsystems Java Blueprints Pet Store reference architecture (v1.3.2). The system spans 22 modules across 4 application tiers and 18 components, totaling approximately 84,000 lines of code.

**Key Findings**:

- **Architecture**: Multi-tier J2EE monolith with Struts front-end, EJB business logic, and database persistence
- **Scope**: Complete e-commerce platform (catalog browsing, shopping cart, checkout, order fulfillment, supplier management)
- **Technology Stack**: Java 1.4+, JSP, Struts, EJB 2.1, Message Queues (JMS), XML/XSLT
- **Data Model**: Relational database with XML document interchange
- **Integration**: Supplier integration via B2B XML, Asynchronous order processing via JMS
- **Criticality**: Payment processing, order approval workflows, inventory fulfillment — all business-critical

---

## Module Inventory

### High-Risk Modules (Must Extract)

**apps/petstore** (18,460 LOC, 67 JSP screens)

- Primary customer-facing web application
- Entry point for all user interactions: catalog browsing, shopping cart, checkout
- Integrates with core business components: cart, customer, orders, payments
- Risk Score: 10/10 (highest criticality, largest code surface, most user-exposed)
- Flows: Browse → Add to Cart → Checkout → Payment → Confirmation

**components/purchaseorder** (2,366 LOC, EJB entity)

- Core order domain model and orchestration
- Manages order state, items, addresses, payment info
- Critical to every business transaction
- Risk Score: 9/10 (foundational business logic, no alternative path)

**components/customer** (2,385 LOC, EJB session)

- Customer account management and profiles
- User authentication state and preferences
- Risk Score: 8/10 (authentication and personalization)

**components/cart** (829 LOC, EJB stateful session)

- Shopping cart manipulation (add/remove/update items)
- Price calculation, tax, shipping
- Risk Score: 7/10 (critical transaction entry point)

**components/creditcard** (769 LOC, EJB entity)

- Credit card validation and payment processing
- Payment method management
- Risk Score: 7/10 (security and financial compliance critical)

**components/signon** (1,559 LOC, web filter + DAO)

- User authentication and session management
- Access control enforcement
- Risk Score: 8/10 (security-critical authentication path)

**apps/opc** (5,212 LOC, 1 screen + backend)

- Order Processing Center: order approval and fulfillment workflows
- Asynchronous order validation and state transitions
- Supplier coordination entry point
- Risk Score: 8/10 (critical approval and fulfillment workflows)

### Medium-Risk Modules (Dependent on High-Risk)

**apps/admin** (5,497 LOC, 4 screens)

- System administration interface
- OPC monitoring and management
- Risk Score: 7/10 (operational controls, audit trail)

**apps/supplier** (4,097 LOC, 7 screens)

- Supplier portal for order fulfillment and inventory
- Risk Score: 6/10 (B2B integration point)

**components/catalog** (2,866 LOC, DAO)

- Product catalog management and search
- Inventory visibility
- Risk Score: 6/10 (core business data)

**components/supplierpo** (1,924 LOC, EJB entity)

- Supplier-side purchase orders
- Risk Score: 6/10 (B2B fulfillment dependency)

**components/processmanager** (1,322 LOC, EJB session)

- Workflow engine for order state transitions
- Risk Score: 5/10 (process orchestration, medium complexity)

**components/contactinfo** (1,266 LOC, EJB entity)

- Address and contact information storage
- Used by orders and customers
- Risk Score: 5/10 (data reference, lower logic complexity)

**components/xmldocuments** (2,042 LOC, XML utilities)

- XML document generation and parsing (orders, approvals, invoices)
- Risk Score: 5/10 (integration format, medium complexity)

### Low-Risk Modules (Infrastructure & Utilities)

**components/address** (992 LOC) - Address validation and formatting  
**components/lineitem** (820 LOC) - Order line item management  
**components/mailer** (840 LOC) - Email notification system  
**components/asyncsender** (549 LOC) - Asynchronous message dispatch  
**components/uidgen** (756 LOC) - Unique ID generation (sequence generators)  
**components/servicelocator** (758 LOC) - JNDI service lookup patterns  
**components/util** (181 LOC) - Common utilities  
**components/encodingfilter** (180 LOC) - Request encoding filter

**Risk Rationale**: These provide supporting functionality or infrastructure services with limited business logic. Extraction is straightforward; no complex state or approval workflows.

---

## Architectural Patterns

### Three-Tier Architecture

1. **Presentation Tier** (JSP/Struts): `apps/petstore`, `apps/opc`, `apps/admin`, `apps/supplier`
2. **Business Logic Tier** (EJB): Customer, Cart, Order, Catalog, Supplier components
3. **Persistence Tier** (DAO, Entity EJBs): Direct database access or entity bean mappings

### Key Architectural Components

**Front Controller Pattern** (Struts)

- `MainServlet` dispatches all web requests
- Action classes implement business logic per screen
- Separate `*HTMLAction` (web) and `*EJBAction` (EJB) pairs

**Service Locator**

- Centralized JNDI lookups via `ServiceLocator` component
- Reduces coupling to EJB locations

**Message-Driven Beans (MDB)**

- Asynchronous order processing (JMS queues)
- `MailOrderApprovalMDB`: Processes order approvals, queues email
- `SupplierOrderMDB`: Processes supplier notifications

**XML Document Exchange**

- Purchase orders, approvals, invoices as XML
- XSLT for presentation formatting
- DTD validation (Cloudscape/Derby database schemas also referenced)

---

## Data Model Overview

### Entity Relationships (Inferred from Code)

- **PurchaseOrder** (order header): 1 → M **LineItem** (order lines)
- **PurchaseOrder** → **CreditCard** (payment), **ContactInfo** (shipping, billing)
- **Customer** (account) → M **PurchaseOrder** (order history)
- **Customer** → M **ContactInfo** (stored addresses)
- **SupplierOrder** → M **LineItem** (fulfillment lines)
- **Catalog** (products) → **LineItem** (order composition)

### Key Tables (J2EE Blueprints Convention)

- `ORDERS`, `ORDERLINE`, `ORDERLINEPRICE` (purchase orders)
- `CUSTOMER`, `PROFILE` (accounts)
- `CARTITEM`, `CARTPRICE` (shopping cart snapshots)
- `CREDITCARD` (payment methods)
- `ADDRESS` (contact info)
- `ITEM`, `ITEMATTR` (catalog products)
- `SUPPLIER`, `SUPPLIERSORDER` (B2B fulfillment)

---

## Business Capabilities

### 1. Product Catalog (`components/catalog`)

**Behavior**: Product browsing, search, filtering by category/attribute
**Ownership**: `apps/petstore` (UI), `components/catalog` (DAO + search)
**User Flows**: Home → Browse Categories → Search/Filter → Product Detail
**State**: Read-only reference data (inventory levels sourced here)

### 2. Shopping Cart (`components/cart`)

**Behavior**: Add items, update quantities, remove items, calculate totals (price + tax + shipping)
**Ownership**: `components/cart` (EJB stateful session per user)
**Persistence**: Session-scoped (lost on logout) or persisted in database
**Rules**: Price recalculation on each item change; tax computed based on shipping address

### 3. Checkout & Payment (`components/creditcard`, `apps/petstore`)

**Behavior**: Order creation, payment processing, credit card validation
**Flows**:

1. Enter shipping/billing address → stored in `components/contactinfo`
2. Select or enter payment method → validated in `components/creditcard`
3. Confirm order → `components/purchaseorder` created → async approval
   **State**: Order moves from PENDING_APPROVAL → APPROVED/REJECTED

### 4. Order Approval (`apps/opc`, `components/processmanager`)

**Behavior**: Order validation, fraud checks, fulfillment routing
**Trigger**: Asynchronous (JMS queue) after order creation
**Workflow**: Validate → Risk assess → Approve/Reject → Notify customer (email)
**Rules** (inferred, not yet extracted):

- Payment authorization validation
- Fraud scoring (not visible in code review)
- Supplier inventory check (coordinated with `apps/supplier`)

### 5. Order Fulfillment (`apps/supplier`, `components/supplierpo`)

**Behavior**: Supplier receives orders, manages fulfillment, updates status
**Flows**: OPC sends `SupplierOrder` → Supplier portal shows pending → Supplier marks shipped
**State Transitions**: PENDING → PROCESSING → SHIPPED → DELIVERED
**Integration**: Via XML documents over JMS or web services

### 6. Customer Account (`components/customer`)

**Behavior**: Registration, login, profile maintenance, order history
**Flows**: Sign up → Verify email → Login → View orders → Edit profile
**Scope**: Account creation, password management, notification preferences

### 7. Supplier Management (`apps/supplier`)

**Behavior**: B2B vendor portal for fulfillment and inventory
**Screens**: Order queue, inventory updates, shipment tracking
**Integration**: Receives POs from OPC, sends fulfillment updates

### 8. Admin Operations (`apps/admin`)

**Behavior**: System administration, OPC monitoring, configuration
**Screens**: Order review, approval override, system status
**Scope**: Limited to trusted admins; order approvals can be overridden

### 9. Notifications (`components/mailer`, `components/asyncsender`)

**Behavior**: Email confirmations, order status updates, approval decisions
**Trigger**: Asynchronously via MDB after state transitions
**Template System**: XSLT transforms XML orders to HTML emails

### 10. Inventory & Stock (Inferred from Catalog & Supplier Integration)

**Behavior**: Product inventory tracking, supplier stock replenishment
**Data**: Stored in `ITEM` table with quantity fields
**Coordination**: Supplier orders triggered when stock low; OPC approves based on availability

---

## Dependency Graph

### Critical Paths (Extraction Order Constraints)

1. **Customer Registration**: `signon` → `customer` → `contactinfo`
2. **Shopping**: `petstore` → `catalog` (read), `cart` (read/write), `customer` (read)
3. **Checkout**: `petstore` → `cart`, `customer`, `purchaseorder`, `creditcard`, `contactinfo`
4. **Order Approval**: `opc` → `purchaseorder`, `processmanager`, `xmldocuments`, `mailer`
5. **Supplier Fulfillment**: `supplier` → `supplierpo`, `processmanager`, `lineitem`, `xmldocuments`
6. **Admin Management**: `admin` → `opc`, `xmldocuments`

### Reverse Dependencies (What Can Be Extracted First)

- `util`, `encodingfilter`, `uidgen`, `servicelocator` — no business logic dependencies
- `address`, `lineitem` — support entities, low business logic
- `contactinfo`, `creditcard` — data entities, depend only on `util`
- `catalog` — read-only reference data, self-contained
- `mailer`, `asyncsender` — support services, low business logic

### Extraction Sequence (Recommended)

1. **Infrastructure/Utilities**: `util`, `encodingfilter`, `uidgen`, `servicelocator` (no dependencies)
2. **Entities**: `address`, `lineitem`, `contactinfo`, `creditcard` (low dependency)
3. **Services**: `catalog`, `uidgen` (self-contained)
4. **Core Domain**: `customer`, `cart`, `purchaseorder` (interdependent, foundational)
5. **Orchestration**: `processmanager`, `xmldocuments`, `mailer`, `asyncsender`
6. **Applications**: `signon` → `petstore` → `opc` → `admin` → `supplier` (layered dependencies)

---

## Exclusions & Notes

### Not Extracted (Out of Scope for SX-0001)

- **WAF Framework** (`src/waf/`): Generic web framework reusable across multiple apps; extracted separately if needed
- **Build System** (`*.xml`, `build.xml`): Ant-based compilation; preserved as reference but not analyzed
- **Third-Party Libraries** (`src/lib/`): JARs and pre-compiled components; dependencies documented only
- **Configuration Files** (JNDI names, datasource configs): Environment-specific; not business logic

### Reachability Concerns (Flag for Clarification)

1. **Dead Code**: No unreachable actions detected in initial scan. All Struts actions are mapped in `web.xml`.
2. **Backward Compatibility**: Two separate action classes per operation (`*HTMLAction` web-facing, `*EJBAction` remote), suggesting possible legacy refactoring in progress
3. **Message-Driven Beans**: Order approval flow is entirely asynchronous (JMS) — must verify all entry points are wired correctly

### Ambiguities for Next Stage

1. **Order Approval Rules**: Fraud scoring and approval thresholds are in OPC MDB but not visible in review. Source unknown (configuration, database, closed-source component?)
2. **Tax Calculation**: Assumed in cart component but not visible in code sample. Needs verification.
3. **Payment Authorization**: Credit card validation logic present, but actual payment gateway integration (authorization, capture) not visible. Possible delegation to external service (Verifone, etc.).
4. **Supplier Inventory Sync**: Stock replenishment trigger not visible in code. May be batch job or scheduled task.

---

## Risk Assessment Summary

| Module                    | Risk         | Rationale                                                                                |
| ------------------------- | ------------ | ---------------------------------------------------------------------------------------- |
| apps/petstore             | **CRITICAL** | Largest codebase, all user-facing, entry point for all transactions, payment integration |
| components/purchaseorder  | **CRITICAL** | Foundational order model, used in every checkout flow, no alternative                    |
| apps/opc                  | **HIGH**     | Order approval state machine, asynchronous execution, integration hub                    |
| components/cart           | **HIGH**     | Transaction entry point, price calculations, session management                          |
| components/creditcard     | **HIGH**     | Payment validation, financial compliance, security-critical                              |
| components/customer       | **HIGH**     | Authentication state, personalization, account management                                |
| components/signon         | **HIGH**     | Authentication mechanism, access control enforcement                                     |
| apps/admin                | **MEDIUM**   | Administrative interface, lower transaction volume                                       |
| apps/supplier             | **MEDIUM**   | B2B partner portal, integration point but not critical path                              |
| components/catalog        | **MEDIUM**   | Product reference data, read-only, lower complexity                                      |
| components/supplierpo     | **MEDIUM**   | Supplier-side orders, fulfillment workflow coordination                                  |
| components/processmanager | **MEDIUM**   | Workflow orchestration, moderate complexity                                              |
| components/contactinfo    | **MEDIUM**   | Address data, referenced by multiple entities                                            |
| components/xmldocuments   | **MEDIUM**   | XML utilities for document interchange, integration layer                                |
| components/mailer         | **LOW**      | Email notification, infrastructure service                                               |
| components/asyncsender    | **LOW**      | Async messaging dispatcher, infrastructure                                               |
| components/address        | **LOW**      | Address formatting/validation, support utility                                           |
| components/lineitem       | **LOW**      | Order line items, simple entity                                                          |
| components/uidgen         | **LOW**      | ID generation, infrastructure                                                            |
| components/servicelocator | **LOW**      | JNDI lookup pattern, infrastructure                                                      |
| components/util           | **LOW**      | Common utilities, minimal business logic                                                 |
| components/encodingfilter | **LOW**      | Request encoding, infrastructure filter                                                  |

---

## Extraction Feasibility

### High Confidence (Well-Defined Boundaries)

- **Catalog Module**: Self-contained, read-only, clear DAO pattern
- **Address Component**: Standalone entity, minimal dependencies
- **Utilities & Infrastructure**: No business logic, clear service interfaces
- **Email/Async**: Clear separation of concerns, event-driven

### Medium Confidence (Some Interdependencies)

- **Cart**: Depends on customer session and catalog
- **Customer**: Depends on authentication (signon)
- **Supplier**: Depends on order processing and fulfillment
- **Process Manager**: Orchestrates multiple domain objects

### Low Confidence (Complex Interdependencies)

- **Purchase Order**: Central to multiple flows, many references
- **Petstore App**: Orchestrates all client-facing operations
- **OPC**: Asynchronous order processing, state machine complexity
- **Payment Processing**: Depends on credit card, order, customer — integration points unclear

---

## Next Steps (Stage: Extraction)

1. **Extract High-Risk, High-Confidence Modules First**
   - Start with infrastructure components (util, encodingfilter, uidgen, servicelocator)
   - Move to data entities (address, creditcard, contactinfo)
   - Extract catalog (read-only, self-contained)

2. **Core Domain Extraction**
   - Customer (auth + profile)
   - Cart (session-scoped, price calculation)
   - PurchaseOrder (foundational entity)

3. **Workflow & Integration**
   - ProcessManager (state machine)
   - XMLDocuments (interchange format)
   - Mailer + AsyncSender (notification system)

4. **Applications**
   - Signon (auth filter)
   - Petstore (UI orchestration)
   - OPC (order approval)
   - Admin (administrative controls)
   - Supplier (B2B portal)

5. **Validation & Ambiguity Resolution**
   - Trace payment authorization flow end-to-end
   - Verify tax calculation logic
   - Identify fraud scoring rules (OPC approval logic)
   - Document supplier inventory synchronization mechanism

---

## Conclusion

The Java Pet Store is a well-structured, reference-architecture-based e-commerce application. Its modular design and clear separation between presentation, business logic, and persistence layers make it suitable for requirement extraction. The primary challenge is understanding asynchronous workflows (JMS order approval) and external integrations (payment gateways, supplier coordination). The dependency graph is relatively clean, enabling phased extraction starting with infrastructure components and building toward core domain logic and applications.

**Recommendation**: Proceed with extraction. Begin with utility and infrastructure modules (Phase 1), advance to core domain entities (Phase 2), then tackle complex workflows (Phase 3).
