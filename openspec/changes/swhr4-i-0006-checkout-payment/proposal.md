# Checkout-Payment Capability Specification Proposal

## Overview

The `checkout-payment` capability consolidates credit card management and order payment processing across the legacy PetStore application. This capability spans:

- **Credit Card Entity Management**: Persistent storage and lifecycle of credit card information (card number, type, expiry date)
- **Credit Card Validation**: Input validation for card fields with required field enforcement
- **Order Payment Integration**: Association of credit cards with purchase orders during checkout
- **Payment Data Integrity**: Transactional consistency and data format constraints (MM/YYYY expiry format)

## Scope

This specification extracts requirements from the following sources:

- Credit card component (EJB entities, validation logic, XML serialization)
- Purchase order component (credit card association, order lifecycle)
- PetStore application (user-facing forms, order entry flow)

The capability does NOT include:

- Payment processing/authorization (card validation against payment networks)
- Notification/messaging (handled by separate messaging capability)
- Security/encryption of card data in transit or at rest
- Complete order workflow (just the payment/card-related portions)

## Key Findings

### High-Confidence Requirements

- Credit card entity persistence with three fields: cardNumber, cardType, expiryDate
- Expiry date format: MM/YYYY (month/year concatenated with "/" separator)
- Card type enumeration: Java(TM) Card, Duke Express, Meow Card
- Required field validation for all card fields
- One-to-one relationship between purchase order and credit card with cascade delete
- Transactional consistency with Required attribute for all credit card operations

### Medium-Confidence Findings

- Card number maximum length: 30 characters (UI-level constraint, no server-side validation)
- Expiry year range: 2002-2005 (form-level, time-bound, likely outdated)
- Default expiry month "01" and year "2010" for null/malformed dates (bare literals, no documented rationale)

### Ambiguities and Conflicts Discovered

- Form validation bug: creditCardNumber checked instead of cardType/expiryMonth/expiryYear (lines 152, 160, 168 of CustomerHTMLAction)
- CreditCard primary key declared as java.lang.Object (atypical for CMP entity)
- Hardcoded defaults (01, 2010) lack configuration or test evidence

## Related Capabilities

- `order-management`: Purchase order entity and order creation workflow
- `customer-account`: Customer account lifecycle and profile management
- `notification-messaging`: Email notifications after order creation
- `product-catalog`: Shopping cart and item management
