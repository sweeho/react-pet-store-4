# Order Approval Capability Proposal

## Problem statement

E-commerce systems must balance order processing speed with financial risk management. Small orders present minimal business risk and should proceed immediately; large orders require human review to prevent fraud and ensure policy compliance. The order approval capability solves this by implementing a workflow-based system that automatically approves small orders while routing large orders for administrator review.

## Solution overview

The order approval capability provides:

1. **Automatic approval for low-risk orders** — Orders below locale-specific monetary thresholds (< 500 USD for US, < 50000 JPY for Japan) are automatically approved during order intake, enabling fast fulfillment without administrator involvement.

2. **Manual approval for high-risk orders** — Orders exceeding thresholds are held in PENDING status for administrator review. Administrators can approve or deny orders via an XML-based approval interface.

3. **Workflow integration** — Order approval decisions are integrated into the order fulfillment workflow, triggering downstream actions (supplier purchase orders, customer notifications) only for approved orders.

4. **Message-driven architecture** — The capability is implemented using JMS message-driven beans, enabling asynchronous processing and loose coupling between order intake, approval, fulfillment, and notification systems.

## Scope

**Included:**

- Receiving purchase orders from the Java Pet Store via JMS
- Parsing and validating order XML documents
- Creating purchase order entities and initializing workflow
- Applying auto-approval thresholds based on locale and total price
- Processing administrator approval/denial decisions
- Updating order workflow status
- Generating supplier purchase orders for approved orders
- Routing notifications to customer relations system
- Preventing reprocessing of already-approved orders
- XML document modeling and serialization (OrderApproval)
- Admin API for retrieving orders by status and updating order statuses

**Out of scope:**

- Customer-facing UI for order tracking (provided by Java Pet Store)
- Admin console UI for order review (provided by admin operations system)
- Email delivery implementation (provided by notification/mailer system)
- Supplier order transmission (provided by supplier integration system)
- Financial risk assessment algorithms (uses hardcoded thresholds only)

## Key features

### Auto-approval by locale and amount

The system implements business rules that qualify orders for automatic approval:

- Orders from US locale with total price < 500 USD
- Orders from Japan locale with total price < 50000 (assumed JPY)

Auto-approved orders bypass administrator review, reducing processing latency. All other orders proceed to PENDING status for manual decision.

### Administrator approval workflow

Authenticated administrators can:

- Retrieve purchase orders filtered by status (PENDING, APPROVED, DENIED, COMPLETED, SHIPPED_PART)
- View order details (order ID, user ID, order date, amount, status)
- Approve or deny orders via XML requests
- Commit multiple approval/denial decisions in a single batch

### Order fulfillment workflow integration

The approval capability integrates with the broader order fulfillment workflow:

```
PENDING (new order)
  ↓
  ├→ auto-approval logic
  │   ├→ if eligible: generate APPROVED message → APPROVED status
  │   └→ if not eligible: remain PENDING for manual review
  │
  └→ manual approval (admin)
      ├→ approve → APPROVED status
      └→ deny → DENIED status

APPROVED (status)
  ↓
  generate supplier PO
  send customer notification
  ↓
SHIPPED_PART / COMPLETED (fulfillment MDB updates)
```

## Technical approach

**Message-driven beans** implement the workflow:

- **PurchaseOrderMDB** receives orders, applies auto-approval logic, and routes to approval queue
- **OrderApprovalMDB** processes approval batches, validates state, updates workflow, and generates outcomes
- **Transition delegates** route approved orders to supplier and notification systems

**XML document models** (OrderApproval, ChangedOrder) represent approval decisions and are passed between components via JMS.

**Database transactions** ensure atomicity: each MDB.onMessage() call is a complete transactional unit.

**Reprocessing guard** in OrderApprovalMDB prevents duplicate processing by checking that orders are in PENDING status before updating.

## Constraints and dependencies

1. **Depends on PurchaseOrder component** — Consumes PurchaseOrder entities created during order intake
2. **Depends on xmldocuments component** — Uses XML document models (PurchaseOrder DTD, OrderApproval DTD) and parsing utilities
3. **Depends on ProcessManager (workflow)** — Uses workflow state machine for order status tracking
4. **Depends on AsyncSender EJB** — Routes admin approval decisions asynchronously
5. **Depends on SupplierIntegration** — Sends approved orders to supplier queue
6. **Depends on Notification/Mailer** — Sends customer notifications via mail queue

## Acceptance criteria

1. Purchase orders are received via JMS, parsed, validated, and stored as PurchaseOrder EJBs
2. Auto-approval thresholds are applied correctly for US (500 USD) and Japan (50000 JPY) locales
3. Orders not auto-approved are placed in PENDING status for administrator review
4. Administrators can retrieve orders by status and update order statuses via XML API
5. Admin approval decisions update the order workflow status and trigger downstream outcomes
6. Approved orders generate TPA Supplier Purchase Order documents with complete order and address details
7. Only PENDING orders are processed from approval messages (no reprocessing of APPROVED/DENIED/COMPLETED orders)
8. OrderApproval XML documents are validated against DTD and properly serialized/deserialized
9. All order approval processing occurs within container-managed transactions with ACID semantics
10. End-to-end order approval workflow functions correctly from order intake through supplier routing and customer notification
