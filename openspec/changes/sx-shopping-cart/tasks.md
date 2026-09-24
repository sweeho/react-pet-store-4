## 1. Data model

- [ ] 1.1 Define the CartItem entity with itemId, productId, category, name, attribute, quantity, and unitCost fields
- [ ] 1.2 Define the ShoppingCart entity as a stateful session bean with HashMap-based storage and Locale support
- [ ] 1.3 Implement CartItem.getTotalCost() method for line-level cost calculation

## 2. Core cart operations

- [ ] 2.1 Implement addItem(String itemId) to add items with default quantity of 1
- [ ] 2.2 Implement addItem(String itemId, int quantity) to add items with explicit quantity
- [ ] 2.3 Implement deleteItem(String itemId) to remove items from cart
- [ ] 2.4 Implement updateItemQuantity(String itemId, int newQty) with conditional removal for qty <= 0
- [ ] 2.5 Implement empty() method to clear all items from cart

## 3. Cart queries and state

- [ ] 3.1 Implement getItems() to retrieve CartItem collection with current product details from Catalog
- [ ] 3.2 Implement getSubTotal() to calculate sum of (unitCost × quantity) for all items
- [ ] 3.3 Implement getCount() to return count of distinct items in cart
- [ ] 3.4 Implement setLocale(Locale locale) with default Locale.US initialization

## 4. Integration with catalog

- [ ] 4.1 Wire shopping cart to Catalog component via local EJB reference
- [ ] 4.2 Implement catalog item lookup with locale-aware product details retrieval
- [ ] 4.3 Implement exception handling for catalog lookup failures (catch and log, not propagate)

## 5. Transaction and security

- [ ] 5.1 Configure Required transaction attribute for all public cart methods
- [ ] 5.2 Configure unchecked security access for all public cart methods
- [ ] 5.3 Ensure use-caller-identity for security context propagation

## 6. Shopping cart screen

- [ ] 6.1 Implement shopping cart display showing item details (name, cost, quantity)
- [ ] 6.2 Implement quantity input controls for each cart item
- [ ] 6.3 Implement remove item action for each cart item
- [ ] 6.4 Implement subtotal display with currency formatting
- [ ] 6.5 Implement empty cart message when no items present

## 7. Web tier cart operations

- [ ] 7.1 Implement add-to-cart action (action=purchase with itemId parameter)
- [ ] 7.2 Implement remove-from-cart action (action=remove with itemId parameter)
- [ ] 7.3 Implement update-quantities action (action=update with itemQuantity\_<itemId> parameters)
- [ ] 7.4 Implement form mapping from HTTP parameters to CartEvent objects

## 8. Atomic multi-item updates

- [ ] 8.1 Implement batch update capability for multiple cart items in single transaction
- [ ] 8.2 Ensure all-or-nothing semantics for multi-item quantity updates
