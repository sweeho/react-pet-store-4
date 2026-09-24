## ADDED Requirements

### Requirement: Add item to shopping cart with default quantity

The system SHALL add a single item to the shopping cart with a quantity of 1 when the addItem(itemId) method is invoked.

#### Scenario: Add new item to empty cart

- **GIVEN** a shopping cart in empty state
- **WHEN** addItem(itemId) is invoked with a valid item ID
- **THEN** the item is added to the cart with quantity 1

#### Scenario: Add item that already exists in cart

- **GIVEN** a shopping cart already containing an item with the specified itemId
- **WHEN** addItem(itemId) is invoked again
- **THEN** the existing item entry is overwritten with quantity 1

### Requirement: Add item to shopping cart with explicit quantity

The system SHALL add a single item to the shopping cart with an explicitly provided quantity when the addItem(itemId, quantity) method is invoked.

#### Scenario: Add item with explicit quantity

- **GIVEN** a shopping cart in any state
- **WHEN** addItem(itemId, quantity) is invoked with a valid item ID and quantity value
- **THEN** the item is added to the cart with the specified quantity

### Requirement: Remove item from shopping cart

The system SHALL remove an item from the shopping cart when deleteItem(itemId) is invoked.

#### Scenario: Remove existing item from cart

- **GIVEN** a shopping cart containing an item with the specified itemId
- **WHEN** deleteItem(itemId) is invoked
- **THEN** the item is removed from the cart

#### Scenario: Remove item not in cart

- **GIVEN** a shopping cart that does not contain an item with the specified itemId
- **WHEN** deleteItem(itemId) is invoked
- **THEN** no error is raised and the cart state is unchanged

### Requirement: Update item quantity in shopping cart

The system SHALL update the quantity of an item in the shopping cart. If the new quantity is greater than zero, the item SHALL remain with the updated quantity. If the new quantity is less than or equal to zero, the item SHALL be removed from the cart.

#### Scenario: Update quantity to positive value

- **GIVEN** a shopping cart containing an item with the specified itemId
- **WHEN** updateItemQuantity(itemId, newQty) is invoked with newQty > 0
- **THEN** the item quantity is updated to newQty

#### Scenario: Update quantity to zero or negative

- **GIVEN** a shopping cart containing an item with the specified itemId
- **WHEN** updateItemQuantity(itemId, newQty) is invoked with newQty <= 0
- **THEN** the item is removed from the cart

### Requirement: Retrieve shopping cart contents

The system SHALL retrieve the current contents of the shopping cart as a collection of CartItem objects, populated with current product details from the Catalog component using the configured locale for localization.

#### Scenario: Get items from populated cart

- **GIVEN** a shopping cart containing one or more items with valid product IDs
- **WHEN** getItems() is invoked
- **THEN** a collection of CartItem objects is returned with each item's current product details (name, category, cost, attribute) retrieved from the Catalog

#### Scenario: Get items from empty cart

- **GIVEN** a shopping cart in empty state
- **WHEN** getItems() is invoked
- **THEN** an empty collection is returned

### Requirement: Calculate shopping cart subtotal

The system SHALL calculate the cart subtotal as the sum of (unitCost × quantity) for all items currently in the shopping cart.

#### Scenario: Calculate subtotal with multiple items

- **GIVEN** a shopping cart containing items with the following prices and quantities:
  - Item A: $10.00 × 2 = $20.00
  - Item B: $5.00 × 3 = $15.00
- **WHEN** getSubTotal() is invoked
- **THEN** the subtotal $35.00 is returned

#### Scenario: Calculate subtotal for empty cart

- **GIVEN** a shopping cart in empty state
- **WHEN** getSubTotal() is invoked
- **THEN** a zero subtotal is returned

### Requirement: Get shopping cart item count

The system SHALL retrieve the count of distinct items currently in the shopping cart.

#### Scenario: Get count of items

- **GIVEN** a shopping cart containing 3 distinct items
- **WHEN** getCount() is invoked
- **THEN** 3 is returned

#### Scenario: Get count of empty cart

- **GIVEN** a shopping cart in empty state
- **WHEN** getCount() is invoked
- **THEN** 0 is returned

### Requirement: Empty shopping cart

The system SHALL remove all items from the shopping cart, leaving it in an empty state.

#### Scenario: Clear all items from cart

- **GIVEN** a shopping cart containing one or more items
- **WHEN** empty() is invoked
- **THEN** all items are removed and the cart is empty

### Requirement: Set shopping cart locale

The system SHALL set the locale for the shopping cart, which SHALL be used for localization of item descriptions and details retrieved from the Catalog component. The default locale SHALL be US English (Locale.US).

#### Scenario: Set locale to Japanese

- **GIVEN** a shopping cart with default locale (US English)
- **WHEN** setLocale(Locale.JAPAN) is invoked
- **THEN** the cart's locale is changed to Japanese and subsequent catalog lookups use this locale

#### Scenario: Default locale on cart initialization

- **GIVEN** a new shopping cart is initialized
- **WHEN** no locale is explicitly set
- **THEN** the cart's locale defaults to Locale.US

### Requirement: Shopping Cart Screen

The shopping cart screen SHALL display the current contents of the customer's shopping cart with options to view, modify, and remove items.

#### Scenario: Display populated shopping cart

- **GIVEN** a customer has added items to their shopping cart
- **WHEN** the shopping cart screen is displayed
- **THEN** the following are shown for each item:
  - Item name and product attribute
  - Unit cost formatted as currency
  - Current quantity with an input field to update
  - Remove button to delete the item from cart
  - Cart subtotal calculated and formatted as currency

#### Scenario: Display empty shopping cart

- **GIVEN** a customer's shopping cart is empty
- **WHEN** the shopping cart screen is displayed
- **THEN** a message is shown indicating the cart is empty
  - AND the customer is offered a link to continue shopping

### Requirement: Update multiple cart items atomically

The system SHALL support updating quantities for multiple items in the shopping cart in a single atomic transaction.

#### Scenario: Update quantities for multiple items

- **GIVEN** a shopping cart containing three items
- **WHEN** quantities are updated for items A, B, and C in a single transaction
- **THEN** either all three quantity updates succeed together, or none succeed

### Requirement: CartItem data model

The system SHALL maintain CartItem objects with the following attributes: itemId, productId, category, product name, attribute, quantity, and unitCost. CartItem SHALL provide a getTotalCost() method returning quantity × unitCost.

#### Scenario: CartItem total cost calculation

- **GIVEN** a CartItem with unitCost=$5.00 and quantity=3
- **WHEN** getTotalCost() is invoked
- **THEN** $15.00 is returned

### Requirement: Transaction semantics for shopping cart operations

The system SHALL execute all shopping cart operations (add, remove, update, retrieve, calculate) within a Required transaction context, ensuring atomicity and consistency of cart state.

#### Scenario: Transaction rollback on error

- **GIVEN** a shopping cart operation is in progress
- **WHEN** an error occurs during the operation
- **THEN** the transaction is rolled back and the cart state is restored to its prior state
