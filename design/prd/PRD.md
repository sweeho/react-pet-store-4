# React Pet Store 4 — Product Requirement Document

## Summary

React Pet Store is an online pet shop that takes customer orders through a web storefront, routes them through an approval workflow, and fulfils them against supplier inventory. The entire path from browsing to shipment is automated and asynchronous, so slow suppliers or busy administrators never block customers from ordering.

The product spans four independently deployable applications: a customer-facing storefront, an Order Processing Centre that decides whether orders are approved, an admin interface for reviewing high-value orders, and a supplier portal for inventory management. All communication between applications is asynchronous and durable—components can be down or slow without losing orders or breaking the flow.

## Context

An e-commerce order is not complete when the customer clicks Submit. It has to be checked for risk, matched against stock that may not exist yet, and released when inventory arrives. The current system (Java Pet Store 1.3.2) demonstrates a complete, working solution: customers can order at any time, high-value orders wait for a human decision, low-value orders approve automatically, and the supplier can fulfill whenever stock allows. Orders are never lost to outages, and customers stay informed at every step via email.

This PRD is reconstructed from the working system. It describes what the shipped product does, not what was originally specified. It serves as a baseline for a rebuild or modernisation in a modern technology stack.

## Goals

1. Let a customer browse, search and add items to a cart without signing in; require authentication only at checkout.
2. Hold high-value orders (≥$500) for human review while approving ordinary orders automatically, so review effort scales with risk.
3. Complete an approved order automatically the moment stock exists for it, with no one watching the queue.
4. Notify customers at every order status change via email, so they never need to return to the site to learn the outcome.
5. Serve the storefront in English, Japanese and Chinese, including product names and descriptions, not just interface labels.
6. Provide administrators with sales reporting broken down by pet category and date range.
7. Allow the supplier to be slow or offline without blocking checkout, and allow administrators to be offline without blocking fulfillment.

## Non-goals

- **Real payment processing**: Card details are captured and stored, but never authorized or charged. There is no decline path.
- **Customer order history**: After confirmation, customers have no way to look up an old order except the confirmation number sent by email.
- **Shipment tracking**: Completed is the final status; there is nothing after it.
- **Returns, refunds or cancellations**: Orders cannot be changed or cancelled once submitted.
- **Stock visibility before ordering**: Availability is resolved after the order is placed, never shown beforehand.
- **Self-service password recovery**: Lost passwords require an administrator to create a new account.
- **Multiple suppliers or sourcing logic**: One supplier fills all orders.
- **Mobile or responsive design**: All interfaces are fixed-width for desktop browsers.

## Users

### Shopper

Wants to find and buy a pet quickly with minimal steps. Happy to browse without signing in, but willing to create an account to complete a purchase. Needs the site in their own language.

Can only see and edit their own account. Has no order history view and relies on email for all status updates.

### Administrator

Reviews orders above the approval threshold and decides whether to honour them. Works through a queue in batches, staging several decisions and committing them together.

The only role with a view of sales performance. Cannot edit customers, orders or the catalogue—only change order status.

### Supplier staff

Keeps recorded inventory matching actual stock on hand. Their inventory updates are the event that releases orders waiting for stock, so they are on the critical path for fulfillment even though they never see orders or customers.

Has no view of orders or customer data at all.

## User journeys

### Shopper: Browse and buy without account

1. Home — browse featured categories or use search
2. Category listing — see products, browse or search
3. Product listing — view items with prices
4. Item detail — see full description, image, price
5. Shopping cart — review items, adjust quantities
6. Checkout form — enter shipping/billing address (sign in if not already)
7. Order confirmation — receive order number and confirmation email

### Shopper: Search for a specific pet

1. Home — search box in banner
2. Search results — see matching items with add-to-cart
3. Item detail or Shopping cart → Checkout → Confirmation

### Shopper: Manage account

1. Sign in — username and password
2. Account view — review contact info, card, language, preferences
3. Edit account — update any detail except username/password
4. Sign out — end session and clear cart

### Administrator: Review pending orders

1. Sign in to admin interface
2. Order review queue — see all pending orders in a table
3. Select orders and approve/deny
4. Commit decisions — send to server and email customers

### Administrator: View sales reporting

1. Open admin interface
2. Sales view — select date range
3. View pie chart or bar chart of sales by pet category

### Supplier: Update inventory

1. Sign in to supplier interface
2. Inventory list — view all items with quantities
3. Update quantities for changed items
4. Submit — notify Order Processing Centre of changes
5. (OPC automatically completes waiting orders if new stock covers them)

## Capability map

- **Product catalog**: Three-level hierarchy (category → product → item), search by keyword, paging through results
- **Shopping cart**: Add/remove items, update quantities, calculate subtotal, session-scoped, cleared on sign-out
- **Account management**: Sign in, create account, view profile, edit contact/card/preferences
- **Checkout & order placement**: Capture shipping and billing addresses, place order, receive confirmation number and email
- **Order approval workflow**: Automatic approval for orders under $500, human review for orders ≥$500
- **Order lifecycle**: Pending → Approved → Completed (or Denied terminal state)
- **Inventory fulfillment**: Match approved orders against inventory, complete orders when stock available, re-evaluate on stock changes
- **Supplier inventory management**: View and update quantities, trigger OPC re-evaluation
- **Notifications**: Email on order placement, approval, denial, and completion
- **Admin order review**: View pending and completed orders in separate queues, batch approve/deny with local staging
- **Sales reporting**: Charts by category and date range
- **Localization**: English, Japanese, Chinese site-wide including product content
- **Personalization**: Favourite category, optional MyList panel, optional pet tips banner

## Screens

### Storefront

| Screen             | Purpose                          | Key elements                                                                           |
| ------------------ | -------------------------------- | -------------------------------------------------------------------------------------- |
| Home               | Entry point, category navigation | Hero image map of 5 categories, search box, language flags                             |
| Category listing   | Browse products in a category    | Product name, description, paging, add-to-cart per item                                |
| Product listing    | Browse items within a product    | Item name, attribute, price, image, paging, add-to-cart                                |
| Item detail        | Full product view                | Image, name, attribute, list price, sale price, description, add-to-cart               |
| Search results     | Keyword search across items      | Item name, description, price, add-to-cart per result, paging                          |
| Shopping cart      | Review and edit order            | Item name, quantity editor, unit price, remove link, subtotal, checkout button         |
| Sign in            | Authentication                   | Username/password for returning customer, new account creation form                    |
| Create account     | New customer                     | Contact info (name, address, phone, email), credit card, language/category preferences |
| Account view       | Read-only profile                | All stored details, language/preference settings, edit link                            |
| Edit account       | Update profile                   | All fields from account creation except username/password                              |
| Checkout form      | Final order details              | Pre-filled billing and shipping address, card confirmation, submit button              |
| Order confirmation | Confirmation receipt             | Order number, confirmation email address, thank you message                            |

### Admin Client

| Screen             | Purpose                  | Key elements                                                   |
| ------------------ | ------------------------ | -------------------------------------------------------------- |
| Admin login        | Authentication           | Username/password                                              |
| Orders queue       | Pending order review     | Order number, customer, date, amount, status; sortable columns |
| Non-pending orders | Completed/denied history | Same columns as pending queue, read-only                       |
| Sales pie chart    | Sales by category        | Date range selector, pie chart showing category share          |
| Sales bar chart    | Sales volume by category | Date range selector, bar chart showing volume per category     |

### Supplier Interface

| Screen         | Purpose          | Key elements                                                                                  |
| -------------- | ---------------- | --------------------------------------------------------------------------------------------- |
| Supplier login | Authentication   | Username/password                                                                             |
| Inventory list | Stock management | Item identifier, current quantity, new quantity input, update checkbox per row, submit button |

## Constraints and assumptions

### Constraints

- **Approval threshold is fixed in code**: Cannot be tuned per market or season without a code change.
- **Admin client is a desktop application**: Requires Java runtime; cannot be used from unmanaged machines.
- **Admin and supplier sessions are mutually exclusive**: One person cannot hold both roles simultaneously in one browser.
- **Fixed-width table layouts**: Not usable on narrow screens.
- **Catalogue categories are fixed at five**: Adding a new category requires content and image work.

### Assumptions

- **One supplier fills every order**: No sourcing logic or multi-supplier choices.
- **Prices are single values**: Same price for all three locales; formatted per locale but never converted.
- **Customers accept email as the only status channel**: No SMS or in-app notifications.
- **Administrators work in batches, not one order at a time**: Batch commit is the primary workflow.
- **Inventory records are accurate because staff keep them so**: Nothing reconciles recorded inventory against physical stock.
- **The catalogue is small enough to fit on screen**: All five categories on homepage, pagination elsewhere.

### Explicitly stubbed (not implemented for production)

These capabilities exist but are non-functional and must be built before production use:

- **Payment processing**: Card details are captured and stored, but authorization, charging and decline handling do not exist.
- **Shipping logistics**: No carrier integration, shipping rates or tracking; "Completed" means the supplier said so.
- **Tax calculation**: Never applied; order total is the sum of line items.
- **Fraud and credit assessment**: The $500 threshold is the entire risk model.
- **Stock reservation**: Nothing is held at order time, so two concurrent orders can be promised the same unit.

## Open questions

1. **Approval threshold**: Should it stay a single order-total rule, or become a configurable rule set that can also consider customer age, destination, category, or item attributes?

2. **Back-order visibility**: Should orders waiting for stock become a distinct status, or stay "Approved" with a separate indicator in the admin queue?

3. **Back-order timeout**: How long may an approved order wait on stock before it is escalated, cancelled or refunded?

4. **Pre-order stock visibility**: Should customers see availability before ordering? This trades coupling to supplier data (the current design avoids it) against cart abandonment when items are out of stock.

5. **Admin interface platform**: Does the admin client need to stay a desktop application, or should the review queue move to a web browser?

6. **Pricing strategy**: Should prices be per-locale rather than one price formatted three ways?

7. **Inventory reconciliation**: Who is responsible for reconciling recorded inventory against physical stock, and how often?

8. **Order history**: Should customers be able to view past orders keyed to their account?

9. **Cancellation and refunds**: Should customers be able to cancel pending orders or receive refunds for completed ones?

10. **Password recovery**: Should customers have a self-service password reset, or continue to require admin intervention?

## Sources

| Section                     | Source                                                                                                                                                                                        |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Summary                     | design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md#p1-p7                                                                                                 |
| Context                     | design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md#p11-p15                                                                                               |
| Goals                       | design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md#p19-p27                                                                                               |
| Non-goals                   | design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md#p29-p40                                                                                               |
| Users                       | design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md#p42-p70                                                                                               |
| User journeys               | design/sources/markdown/java-pet-store-1-3-2-user-manual/extracted.md (sections 2-11)                                                                                                         |
| Capability map              | legacy-analysis/discovery/capabilities.csv, legacy-analysis/discovery/report.md (sections 4-9)                                                                                                |
| Screens                     | design/sources/markdown/java-pet-store-1-3-2-user-manual/extracted.md#p363-p383, design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md (data model section) |
| Constraints and assumptions | design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md#p384-p416                                                                                             |
| Open questions              | design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md#p434-p444                                                                                             |
