## Summary

React Pet Store is an online pet shop. Customers order through a web storefront. Each order goes through an approval workflow and is then filled from supplier inventory. Nobody re-keys an order between the storefront, order processing, administration and the supplier, and no step blocks the customer: a slow supplier, a busy administrator or a mail outage delays an order but never stops customers ordering or loses an order.

The product covers four areas of responsibility. The storefront handles the catalogue, accounts, the cart and order capture. Order processing handles approval rules, the order lifecycle, fulfilment tracking and customer e-mail. Administration covers the review of held orders and sales reporting. The supplier area holds the inventory of record and fills orders from it.

This is a rebuild of Java Pet Store 1.3.2. The PRD states what the shipped system does as requirements for its successor. Where the legacy code contradicts its own documentation, the disagreement is recorded in `design/prd/divergences.yaml`, and the choice this PRD makes is listed under Open questions.

## Context

An e-commerce order is not finished when the customer clicks Submit. It has to be checked for risk, matched against stock that may not exist yet, and released when stock arrives. Java Pet Store 1.3.2 covers that whole path. Customers can order at any time. Orders over a locale-specific value wait for a human decision, and smaller ones are approved automatically. The supplier fills orders whenever stock allows, and customers are e-mailed as their order moves on.

This PRD was reconstructed from the legacy source (`legacy-source/petstore1.3.2`), the 1.3.2 user manual, a reconstructed 1.3.2 product requirements document and a set of screen mockups. It serves as the baseline for rebuilding the product on this repository's stack. Where the legacy demo takes a shortcut a real store could not take (payment, tax, stock reservation), the shortcut is flagged under Constraints and assumptions rather than written up as a requirement.

## Goals

1. Let a customer find a pet, buy it and get a confirmation without signing in until checkout.
2. Hold high-value orders for human review while approving ordinary ones automatically, so review effort scales with risk rather than volume.
3. Complete an approved order automatically once stock exists for it, with no one watching the queue, and ship what is in stock when only part of an order can be filled.
4. Keep the customer informed by e-mail as their order is decided, shipped and completed, without them returning to the site.
5. Serve the storefront in English, Japanese and Chinese, including catalogue content and per-locale prices, not just interface labels.
6. Give administrators a view of what is selling, broken down by pet category over a chosen period.
7. Keep taking orders while the supplier or the review queue is slow or unavailable. Neither may stop a customer from ordering, and no order may be lost.

## Non-goals

- Real payment processing. Card details are captured and stored but never authorised or charged, and there is no decline path.
- Customer order history. The order number shown on the confirmation screen and the e-mails are the customer's only record.
- Shipment tracking. Completed is the final status and nothing follows it.
- Returns, refunds or cancellations. An order cannot be changed once submitted.
- Customer-facing stock levels. Availability is resolved after ordering and never shown before.
- Self-service password reset. There is no recovery path for a lost password.
- Multiple suppliers or sourcing choices. One supplier fills everything.
- Catalogue administration. Categories, products and items are reference data loaded at install and never edited through the product.
- Currency conversion. Each locale carries its own price and nothing is converted between locales.

## Users

Shopper. Wants to find a specific pet quickly, see what it costs and buy it in as few steps as possible. Willing to create an account to complete a purchase but not just to look around. Needs the site in their own language. Can see and change only their own account. After the confirmation screen they have no view of the order and rely on e-mail for its status.

Administrator. Reviews orders that carry real money risk and decides whether the store honours them. Works in batches, so several decisions can be staged and committed together. The only role with a view of trading performance. Cannot edit orders, customers or the catalogue. The only change an administrator can make is an approve or deny decision on a pending order.

Supplier staff. Keep recorded stock matching real stock. Their updates release orders that could not be filled before, so the role is on the critical path for fulfilment even though it never handles an order screen. The documents say supplier staff have no view of orders or customers. In the legacy code the supplier receives the shipping name, address, e-mail and telephone with each order, and supplier and administrator share one sign-in role (see Open questions).

## User journeys

Shopper browses and buys:

1. Home
2. Category listing
3. Product listing
4. Item detail
5. Shopping cart
6. Sign in (only if not already signed in; returns to Checkout afterwards)
7. Checkout
8. Order confirmation

Shopper searches and buys from results:

1. Home
2. Search results
3. Shopping cart
4. Sign in (only if not already signed in)
5. Checkout
6. Order confirmation

Shopper creates an account:

1. Home
2. Sign in
3. Create account
4. Home

Shopper reviews and edits their account:

1. Sign in
2. Account overview
3. Edit account
4. Account overview

Shopper changes quantities before ordering:

1. Shopping cart
2. Shopping cart (after Update Cart; a zero quantity removes the line)
3. Checkout
4. Order confirmation

Administrator reviews held orders:

1. Admin sign in
2. Admin welcome
3. Admin — order review, Process pending orders tab
4. Admin — order review, View non-pending orders tab

Administrator checks sales:

1. Admin sign in
2. Admin welcome
3. Admin — sales reporting

Supplier staff restock:

1. Supplier sign in
2. Supplier home
3. Supplier — inventory
4. Supplier home (after Submit)

## Capability map

- product-catalog: Locale-aware, read-only catalogue of category, product and item with per-locale prices, paged listings and any-keyword search, open to anonymous visitors.
- customer-account: Sign-in, account creation with duplicate-name rejection, remembered user name, protected account screens with view and edit of contact, card and profile preferences.
- shopping-cart: Session-scoped cart with add, remove, batch quantity update (zero removes), locale-priced subtotal, emptied on sign-out or session expiry.
- checkout-payment: Checkout form capturing separate billing and shipping addresses pre-filled from the account, the stored account card, empty-cart rejection and hand-off of the order without waiting on processing.
- order-management: Purchase order record with a generated order number, copied addresses and card, per-line unit price and quantity shipped, order total and locale.
- notification-messaging: Queued customer e-mail on approval, denial, each shipment and completion, where a mail outage never blocks order processing.
- order-approval: Automatic approval below a locale-specific order-total threshold, otherwise Pending until an administrator decision, which releases the order to the supplier or ends it.
- inventory-fulfillment: Supplier inventory of record, filling each order line from stock with partial shipment, retrying waiting orders when stock is updated, and an invoice back to order processing for what shipped.
- admin-operations: Authenticated administrator area with the order review queues (batch approve or deny, committed together) and sales charts by category over a date range.
- supplier-integration: Authenticated supplier area where staff view inventory and replace quantities for the rows they flag, with each commit triggering fulfilment of waiting orders.

## Screens

Storefront. Every page carries a banner with the search box, Account, Cart and Sign in or Sign out links and language switches for English, Japanese and Chinese. A Pets panel lists the five categories, and a My List panel appears when enabled.

- Home: picture of the five categories as the entry to browsing, plus a pet-tips banner when enabled.
- Category listing: products in a category with short descriptions, paged, with Previous and Next shown only when a page exists in that direction.
- Product listing: items for a product with description, price and Add to Cart, paged.
- Item detail: photograph, list price, customer price, description and Add to Cart, with a note that availability is confirmed after ordering.
- Search results: matching items with description, price and Add to Cart, paged with the keywords preserved, and an explicit no-results message for an empty query or no matches.
- Shopping cart: one line per item with a link to the item, Remove, an editable quantity and the unit price, plus the total, Update Cart and Check Out. When empty it shows "Your Shopping Cart is Empty." and offers no checkout.
- Sign in: returning-customer form (user name remembered on request, password never) beside a new-customer form (user name, password, password repeated).
- Sign-in failed: states the credentials were not found and invites a retry.
- Create account: contact information, credit card information and profile information (language, favourite category, MyList, pet tips) in one form.
- Duplicate account: states the user name is taken, and no account is created.
- Account overview: read-only view of contact details, card and profile preferences, with a link to Edit account.
- Edit account: the account form with current values, where the user name and password cannot be changed.
- Checkout: billing information and shipping information, both pre-filled from the account and required except the second address line, plus the card that will be used and the order total.
- Empty-cart checkout error: shown when an order is submitted with nothing in the cart.
- Order confirmation: "Your order is complete" with the order number, the e-mail address notifications go to and the total.
- General error: a server failure, with a way back to Home.

Administration.

- Admin sign in: user name and password, with an error on failure.
- Admin welcome: entry to order review and sales reporting, and sign-out.
- Admin — order review: a Process pending orders tab, where each pending order is set to Approved or Denied and all decisions are sent together on Commit, and a read-only View non-pending orders tab. Both tabs show order number, customer, date, amount and status, sortable by any column. Data is loaded on Refresh, and refreshing with uncommitted decisions asks for confirmation.
- Admin — sales reporting: start and end date with a fetch action, a pie chart of each category's share of revenue and a bar chart of quantity per category. An unreadable date is reported and nothing is fetched.

Supplier.

- Supplier sign in: user name and password, with an error on failure.
- Supplier home: purpose of the area, Display inventory and sign-out.
- Supplier — inventory: every item with its current quantity, a new-quantity field and an Update flag per row, and one Submit. Only flagged rows are saved, and an entered quantity replaces the stored figure.

## Constraints and assumptions

Constraints:

- The rebuild targets this repository's pinned stack: a Vite React single-page app with a Nitro server, and SQLite through Drizzle. Legacy mechanisms (JMS queues, EJBs, XML documents with DTDs, a Java Web Start desktop client) are not requirements. The behaviour they carry is: order hand-off must not wait on processing, and work must survive a component being unavailable.
- Authentication: the storefront requires sign-in only for checkout and account screens, and the administration and supplier areas require it on every screen.
- A customer can read and write only their own account.
- Values rendered into pages are escaped, so user-supplied text cannot inject markup.
- Card numbers must not be stored or shown in full. The legacy system stores and displays them in full, which is not acceptable now: tokenise and show only the last four digits.
- English, Japanese and Chinese are supported end to end, including catalogue content. Request and response encoding must round-trip non-Latin input. Prices and dates are formatted per locale.
- Listings are paged rather than returning whole result sets.
- Legacy session idle timeouts are 15 minutes for the storefront and 54 minutes for the administration and supplier areas.
- Every order carries exactly one status: Pending, Approved, Denied, Partly shipped or Completed. Denial is terminal, and an order is Completed only when every line has shipped in full.
- A line item keeps the unit price at the time of ordering and tracks quantity shipped separately from quantity ordered. An order keeps its own copy of the addresses and card, so later account changes do not rewrite it.

Assumptions:

- One supplier fills every order, and there is no sourcing decision.
- Customers accept e-mail as the only channel for order status.
- Administrators work through the review queue in batches, not one order at a time.
- Recorded inventory is accurate because staff keep it so, and nothing reconciles it against physical stock.
- The catalogue is small: five categories (Birds, Cats, Dogs, Fish, Reptiles) fit in a sidebar and on the home page.

Explicitly stubbed in the legacy system. These appear to work but do nothing, and each must be built for real before production use or kept out of scope:

- Payment: card details are captured and stored, with no authorisation, no charge and no decline path.
- Shipping: no carrier, no rates, no tracking. Completed means the supplier said so.
- Tax: never calculated. The order total is the sum of the line items.
- Fraud and credit checks: the order-total threshold is the entire risk model.
- Stock reservation: nothing is held at order time, so two orders can be promised the same unit. This is a real defect rather than a simplification.

## Open questions

1. Approval threshold. The documents describe a single $500 rule. The code auto-approves only en_US orders under 500 and ja_JP orders under 50,000, so a zh_CN order is always held for review. This PRD keeps the locale-specific behaviour (order-approval) as current. Should zh_CN get a threshold of its own? Should the rule become configurable, or a rule set that can also consider customer age, destination and item category?
2. Partly shipped orders. The code has a fifth status for an order where only some lines shipped, and the admin client never loads orders in that status. This PRD keeps the status and shows it in View non-pending orders. Should a back-ordered order also become a distinct status, instead of looking identical to a fresh approval?
3. Prices. The documents say one price serves all locales. The catalogue data holds a separate price per locale (for example 10.00, 1551 and 86 for the same item). This PRD treats per-locale prices as current. Is that the intended pricing model?
4. Confirmation e-mail. The confirmation screen promises an e-mail "soon", but no e-mail is sent when an order is placed. A held order produces nothing until an administrator decides it. Should placement send an e-mail?
5. Supplier access to customer data. The documents say the supplier sees only line items. The code sends the shipping name, address, e-mail and telephone. This PRD keeps the shipping details the supplier needs to ship. Should e-mail and telephone be withheld?
6. Roles. The administration and supplier areas both admit the same administrator role in the code. The documents describe separate roles with no overlap. This PRD assumes two separate roles. Confirm.
7. Adding an item already in the cart. The documents say the quantity increases. The code resets the line to a quantity of one. This PRD follows the documents.
8. Sales figures. Charts count every order placed in the period, including pending and denied ones. The bar chart measures units ordered, not number of orders. Should denied orders be excluded?
9. How long may an approved order wait on stock before it is escalated or cancelled?
10. Should customers see availability before ordering, accepting the coupling to supplier data that the current design deliberately avoids?
11. Administrator client. The admin-operations spec describes a desktop client launched through Java Web Start. The pinned stack is a browser app, so this PRD places order review and sales reporting in the browser. Confirm that no desktop client is required.
12. Who owns reconciling recorded inventory against physical stock, and how often?
13. Should supplier staff see what their inventory commit released (for example, "12 orders completed")? Today they get no feedback.
14. Capability boundaries. All ten manifest slugs are kept one-for-one. Localisation and personalisation (favourite category, MyList, pet-tips banners) have no manifest capability of their own. They are folded into product-catalog and customer-account. Supplier sign-in and the inventory screen appear in both inventory-fulfillment and supplier-integration. This PRD gives the screen and sign-in to supplier-integration and the fulfilment logic to inventory-fulfillment. The admin approve and deny interface appears in both order-approval and admin-operations. This PRD gives the rule and state change to order-approval and the screens to admin-operations.
15. Card expiry years. The legacy forms offer only 2001–2004 (create) and 2002–2005 (edit). The mockups show 2026–2029. This PRD assumes a rolling window starting at the current year.

## Sources

See `design/prd/sources.yaml` for the files each section was drawn from, and `design/prd/divergences.yaml` for every point where the documents and the legacy code disagree.
