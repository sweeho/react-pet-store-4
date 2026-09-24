# Shopping Cart Design

## Overview

The shopping cart capability manages a customer's collection of items during a shopping session. It maintains session-scoped state through a stateful EJB, integrates with the product catalog for current item details, and supports full CRUD operations on cart contents.

## Architecture

### Session-based State Management

The shopping cart is implemented as a stateful session bean (ShoppingCartLocalEJB) that maintains session-scoped state. This design choice ensures:

- **Per-user isolation**: Each customer's cart is independent within their session
- **Automatic cleanup**: Session timeout automatically clears the cart when the session expires
- **Transaction safety**: Container-managed transactions ensure atomicity of cart operations

The cart maintains an internal HashMap keyed by itemId with Integer quantities as values, plus a Locale instance for localization.

### Catalog Integration

The shopping cart integrates with the Catalog component via local EJB reference to retrieve current product details (name, category, cost, attribute) when items are retrieved. This integration pattern:

- Ensures cart displays current product information without redundant storage
- Uses locale-aware lookups for multilingual product descriptions
- Handles catalog lookup failures gracefully by logging exceptions without propagating them

### CartItem Data Model

CartItem is a serializable POJO that represents a single line item in the cart. It carries the following information:

- Item identification: itemId, productId, category
- Product metadata: name, attribute
- Purchase details: quantity, unitCost
- Calculated field: getTotalCost() = quantity × unitCost

## Key Design Decisions

### Quantity Semantics on Update

When updateItemQuantity is called with newQty ≤ 0, the item is removed from the cart rather than raising an error. This design treats quantity updates as idempotent operations and allows quantity reduction to zero as a valid way to delete items. It simplifies the API and reduces special-case error handling.

### Locale Propagation

The cart stores a Locale instance set by setLocale(). This locale is passed to every catalog lookup so product descriptions are retrieved in the customer's preferred language. The default is Locale.US (English, United States) for backward compatibility.

### Transaction Boundaries

All cart operations execute with Required transaction attribute. This ensures each cart operation is atomic at the EJB tier. The application layer (order processing) wraps multiple cart operations in a single logical transaction using container-managed semantics.

### Catalog Lookup Error Handling

CatalogException raised during getItems() is caught and logged to System.out without re-throwing. This permits the cart to return a partial collection if some catalog lookups fail (e.g., a product has been deleted since it was added to the cart). The alternative—failing the entire getItems()—would be more disruptive to the user experience during a browsing session.

## User Interface

One screen record was extracted for this capability: the Shopping Cart Screen (SCREEN-0002). This screen is specified as a requirement in the delta spec, not as narrative design here. See specs/shopping-cart/spec.md for the screen requirement and its scenarios.

## Deployment Considerations

- The shopping cart is accessed via local EJB interface (ShoppingCartLocal/ShoppingCartLocalHome only)
- Remote access is not supported; the cart is session-local to each application server instance
- In a clustered environment, session replication is required to maintain cart state across server failover

## API Surface

All public methods on ShoppingCartLocal are accessible without role-based access control (unchecked security-permission). The application layer is responsible for enforcing authentication and authorization rules.
