## ADDED Requirements

### Requirement: Maintain inventory with item tracking

The system SHALL maintain inventory records for each item with an item ID (unique identifier) and quantity (available stock count).

#### Scenario: Inventory record creation

- **GIVEN** an item with a unique identifier
- **WHEN** an inventory record is created for that item
- **THEN** the system stores the item ID and its quantity

#### Scenario: Query inventory for fulfillment

- **GIVEN** an inventory database with multiple items
- **WHEN** the system queries for a specific item by ID
- **THEN** the item's current quantity is retrieved

### Requirement: Reduce inventory on fulfillment

The system SHALL support atomically reducing inventory quantity when an order is fulfilled, decrementing by a specified amount in a single transaction.

#### Scenario: Successful inventory reduction

- **GIVEN** an inventory item with 50 units in stock
- **WHEN** fulfillment requires 20 units
- **THEN** the inventory quantity is reduced by 20 to 30 units in a single atomic transaction

#### Scenario: Inventory reduction within transaction

- **GIVEN** an order being fulfilled
- **WHEN** inventory quantities are decremented
- **THEN** the reduction is wrapped in a container-managed transaction with Required attribute

### Requirement: Check inventory availability before fulfillment

The system SHALL verify that sufficient inventory exists for each line item before reducing quantities. If inventory is insufficient, the check SHALL fail and no inventory shall be reduced.

#### Scenario: Sufficient inventory available

- **GIVEN** a line item requesting 25 units
- **WHEN** inventory contains 50 units of that item
- **THEN** the check succeeds and inventory reduction proceeds

#### Scenario: Insufficient inventory

- **GIVEN** a line item requesting 25 units
- **WHEN** inventory contains only 10 units of that item
- **THEN** the check fails and no inventory is reduced

#### Scenario: Item not found in inventory

- **GIVEN** a line item requesting stock of a non-existent item
- **WHEN** the system attempts to check inventory
- **THEN** the check fails and no inventory is reduced

### Requirement: Support partial order fulfillment

The system SHALL support fulfilling only the line items for which inventory is available. When some items can be fulfilled and others cannot, the system SHALL ship available items, create an invoice for only those items, and mark the order status accordingly.

#### Scenario: Partial fulfillment with mixed availability

- **GIVEN** a purchase order with 3 line items (10 units each requested)
- **WHEN** inventory has 15 units of item 1, 5 units of item 2, and 0 units of item 3
- **THEN** items 1 and 2 are marked shipped, an invoice is generated with only items 1 and 2, and order status remains PENDING

#### Scenario: Complete fulfillment

- **GIVEN** a purchase order with 3 line items
- **WHEN** all requested quantities are available in inventory
- **THEN** all items are marked shipped, invoice includes all items, and order status is marked COMPLETED

#### Scenario: No items can be fulfilled

- **GIVEN** a purchase order with line items
- **WHEN** no inventory is available for any item
- **THEN** no invoice is generated and order status remains PENDING

### Requirement: Process purchase orders from OPC

The system SHALL receive purchase orders from the Order Processing Center as XML documents via JMS queue, parse them, persist the order, check inventory for each line item, reduce inventory for items that can be fulfilled, and generate an invoice for shipped items.

#### Scenario: Complete order fulfillment workflow

- **GIVEN** a supplier purchase order in XML format received via JMS queue
- **WHEN** the order is processed by the fulfillment system
- **THEN** the order is parsed and persisted, inventory is checked for each line item, quantities are reduced for items that can ship, and an invoice XML is generated if any items were shipped

#### Scenario: Return invoice on partial fulfillment

- **GIVEN** an order processing workflow where some but not all items can be fulfilled
- **WHEN** fulfillment completes
- **THEN** an invoice is returned containing only the items that were shipped

#### Scenario: Return null when no fulfillment possible

- **GIVEN** an order where no line items can be fulfilled due to insufficient inventory
- **WHEN** fulfillment completes
- **THEN** null is returned (no invoice generated)

### Requirement: Retry fulfillment when new inventory arrives

The system SHALL query for all pending orders and attempt to fulfill them when inventory quantities are updated. Generated invoices SHALL be sent to the Order Processing Center.

#### Scenario: Fulfill pending order with new inventory

- **GIVEN** a purchase order with status PENDING and a line item for 30 units
- **WHEN** inventory is updated with 30 units arriving
- **THEN** the pending order is attempted for fulfillment, an invoice is generated, and sent to OPC

#### Scenario: No pending orders to fulfill

- **GIVEN** an inventory update
- **WHEN** no orders with PENDING status exist
- **THEN** no fulfillment attempts are made

### Requirement: Update inventory from UI

The supplier user SHALL be able to update inventory quantities via a web interface. When a user selects an item and enters a new quantity, the system SHALL update the inventory database and then attempt to fulfill any pending orders with the newly available stock.

#### Scenario: Inventory quantity update

- **GIVEN** an inventory item with current quantity of 20
- **WHEN** a user enters new quantity of 50 and submits the update
- **THEN** the inventory quantity is updated to 50 in the database

#### Scenario: Fulfill pending orders after inventory update

- **GIVEN** an inventory update that increases stock
- **WHEN** the update is submitted
- **THEN** the system queries for pending orders and attempts to fulfill them

#### Scenario: Update within transaction

- **GIVEN** an inventory update operation
- **WHEN** the update is submitted
- **THEN** the update and pending fulfillment attempts are wrapped in a user-managed transaction

### Requirement: Initialize inventory from XML file

The system SHALL support loading initial inventory data from an XML file. The /Populate endpoint SHALL read inventory item data from /populate/Populate-UTF8.xml and populate the inventory database.

#### Scenario: Load inventory from file

- **GIVEN** an XML file at /populate/Populate-UTF8.xml containing inventory items
- **WHEN** the /Populate endpoint is invoked
- **THEN** inventory items are read from the file and persisted to the database

### Requirement: LineItem XML structure

The system SHALL support LineItem XML elements containing CategoryId, ProductId, ItemId, LineNum, Quantity, and UnitPrice for representing order line items in purchase orders and invoices.

#### Scenario: Parse LineItem from purchase order

- **GIVEN** a purchase order XML containing a LineItem element
- **WHEN** the order is parsed
- **THEN** all six fields are extracted and available for processing

#### Scenario: Create LineItem in invoice

- **GIVEN** an invoice being generated
- **WHEN** a line item is added to the invoice XML
- **THEN** CategoryId, ProductId, ItemId, LineNum, Quantity, and UnitPrice are included in the XML

### Requirement: SupplierOrder XML structure

The system SHALL support SupplierOrder XML documents containing OrderId, OrderDate, ShippingAddress with complete recipient details (FirstName, LastName, Street, City, State, Country, Zip), and one or more LineItems.

#### Scenario: Parse SupplierOrder XML

- **GIVEN** a supplier order XML document
- **WHEN** the order is deserialized
- **THEN** OrderId, OrderDate, all shipping address fields, and all line items are extracted

#### Scenario: Create SupplierOrder for transmission

- **GIVEN** an approved customer order
- **WHEN** a supplier purchase order is generated
- **THEN** the SupplierOrder XML contains all required elements with customer shipping information

### Requirement: Supplier login with administrator enforcement

The supplier system SHALL provide a login screen at /login.jsp that accepts username and password credentials and enforces administrator role-based access to inventory management functionality. Only authenticated users with the administrator role SHALL see the inventory update form.

#### Scenario: Administrator sees inventory management

- **GIVEN** a user logged in with administrator role
- **WHEN** navigating to the inventory management screen
- **THEN** the inventory update form with quantity fields and checkboxes is displayed

#### Scenario: Non-administrator denied access

- **GIVEN** a user logged in without administrator role
- **WHEN** attempting to access the inventory management screen
- **THEN** access is denied or the message "You are not authorised to update the status of orders" is shown

### Requirement: Inventory display and update interface

The supplier system SHALL provide an inventory management screen at /displayinventory.jsp that lists all inventory items with their item IDs and current quantities. For each item, the screen SHALL display an input field for entering new quantity and a checkbox for selecting items to update.

#### Scenario: Display inventory list

- **GIVEN** a database containing 20 inventory items
- **WHEN** the inventory management screen is loaded
- **THEN** all 20 items are displayed in a table with columns: Item ID, Existing Quantity, New Quantity input, Update checkbox

#### Scenario: Update selected items

- **GIVEN** the inventory display showing 20 items
- **WHEN** a user selects 3 items via checkboxes, enters new quantities, and submits the form
- **THEN** the selected items' quantities are updated in the database

#### Scenario: Iterate through items

- **GIVEN** a collection of inventory items retrieved from the database
- **WHEN** the inventory screen is rendered
- **THEN** each item is displayed in a table row with its current quantity and update controls

### Requirement: Supplier home page with navigation

The supplier system SHALL provide a home page at /index.jsp that displays the purpose of the supplier module and offers navigation options to display current inventory or logout. The home page SHALL contain two forms posting to RcvrRequestProcessor servlet.

#### Scenario: Display supplier home page

- **GIVEN** a user successfully authenticated
- **WHEN** navigating to the supplier application entry point
- **THEN** the home page displays a heading "Java Pet Store - Supplier Home Page" and explanatory text about inventory management capability

#### Scenario: Navigation to inventory

- **GIVEN** the supplier home page displayed
- **WHEN** the user clicks "Display Inventory" button
- **THEN** a form with currentScreen=displayinventory is submitted to RcvrRequestProcessor

#### Scenario: Logout from home page

- **GIVEN** the supplier home page displayed
- **WHEN** the user clicks "Logout" button
- **THEN** a form with currentScreen=logout is submitted to RcvrRequestProcessor
