# Inventory Fulfillment System Design

## Overview

The inventory fulfillment system manages supplier inventory, processes purchase orders from the Order Processing Center (OPC), checks stock availability, reduces inventory on fulfillment, and supports partial order fulfillment. The system is built on a Java EE 2.x architecture with EJBs, JMS messaging, and JSP-based web interface.

## Architecture Components

### Entity Layer

**Inventory Entity Bean (CMP 2.x)**

- Container-Managed Persistence entity with two fields: `itemId` (primary key, String) and `quantity` (int)
- Provides abstract accessors: `getItemId()`, `setItemId()`, `getQuantity()`, `setQuantity()`
- Implements `reduceQuantity(int quantity)` method for atomic inventory reduction
- Transaction attribute: Required (container-managed)

**LineItem Entity Bean (CMP 2.x)**

- Seven persistent fields: `categoryId`, `productId`, `itemId`, `lineNumber`, `quantity`, `unitPrice`, `quantityShipped`
- Used within purchase orders to represent individual line items
- Supports two creation patterns: direct field initialization or via LineItem data object

### Session Beans

**OrderFulfillmentFacadeEJB (Stateless Session)**

- Coordinates order fulfillment workflow
- Key methods:
  - `processPO(String poXmlDoc)`: Parse purchase order XML, persist order, check inventory, reduce quantities, return invoice XML or null
  - `processAnOrder(SupplierOrderLocal po)`: Iterate through line items, check availability, reduce inventory, build invoice
  - `checkInventory(LineItemLocal item)`: Verify stock availability; reduces inventory if sufficient; returns boolean
  - `createInvoice(SupplierOrderLocal po, HashMap newLis)`: Generate invoice XML with shipped items only
  - `processPendingPO()`: Query for PENDING orders, attempt fulfillment, collect invoices
- Transaction attribute: Required

**DisplayInventoryBean (JSP Bean)**

- Session scope bean for inventory display
- Method: `getInventory()` returns Collection of InventoryLocal entities
- Used by displayinventory.jsp to render the inventory management interface

### Message-Driven Beans

**SupplierOrderMDB**

- Listens to JMS Queue for purchase order messages
- `onMessage(Message recvMsg)`: Receives TextMessage with XML purchase order
- Calls `doWork(String xmlText)` which invokes `OrderFulfillmentFacadeEJB.processPO()`
- Calls `doTransition(String invoice)` to send invoices to OPC via transition delegate
- Transaction attribute: Required

### Servlet

**RcvrRequestProcessor**

- Handles HTTP requests from inventory management UI
- Routes based on `currentScreen` parameter:
  - `displayinventory`: Display inventory list
  - `updateinventory`: Update inventory quantities and retry pending fulfillment
  - `logout`: Invalidate session and logout
- Methods:
  - `updateInventory(HttpServletRequest req)`: Parse qty*\* and item*\* parameters, update InventoryLocal entities
  - `sendInvoices(Collection invoices)`: Transition invoices to OPC
- Wraps update+fulfillment cycle in user-managed transaction (UserTransaction)

## Fulfillment Workflow

1. **Order Reception**: SupplierOrderMDB receives purchase order XML via JMS Queue
2. **Order Parsing & Persistence**: XML is converted to SupplierOrder object and persisted as SupplierOrderLocal entity
3. **Inventory Checking**: For each line item:
   - Query InventoryLocal by item ID
   - Compare requested quantity to available quantity
   - If insufficient: return false and skip to next item
   - If not found: catch FinderException and return false
4. **Inventory Reduction**: For items with sufficient stock, call `inventory.reduceQuantity(requestedQty)` atomically
5. **Shipment Marking**: Mark line item as shipped via `lineItem.setQuantityShipped(quantity)`
6. **Invoice Generation**: Collect shipped items and generate invoice XML with order ID, date, shipping date, and line items
7. **Partial Fulfillment**: Return null if no items shipped; return invoice XML if items were shipped

## Pending Fulfillment Retry

When inventory is updated via the web interface:

1. User selects items and enters new quantities via displayinventory.jsp form
2. RcvrRequestProcessor.updateInventory() processes each selected item:
   - Extracts item ID from parameter name (e.g., "item_ITEM001")
   - Retrieves new quantity from corresponding qty\_\* parameter
   - Validates quantity >= 0
   - Updates InventoryLocal.setQuantity(newQty)
3. Within same user-managed transaction:
   - Call `OrderFulfillmentFacadeEJB.processPendingPO()` to find orders with PENDING status
   - Attempt fulfillment for each pending order
   - Collect returned invoices
   - Call `sendInvoices(Collection)` to transition invoices to OPC

## XML Document Formats

### LineItem XML (reused in multiple document types)

```xml
<LineItem>
  <CategoryId>...</CategoryId>
  <ProductId>...</ProductId>
  <ItemId>...</ItemId>
  <LineNum>...</LineNum>
  <Quantity>...</Quantity>
  <UnitPrice>...</UnitPrice>
</LineItem>
```

### SupplierOrder XML

```xml
<SupplierOrder>
  <orderid>...</orderid>
  <orderdate>...</orderdate>
  <shipaddress>
    <firstname>...</firstname>
    <lastname>...</lastname>
    <street>...</street>
    <city>...</city>
    <state>...</state>
    <country>...</country>
    <zip>...</zip>
  </shipaddress>
  <lineitem>...</lineitem>
  ...
</SupplierOrder>
```

### Invoice XML

```xml
<Invoice locale="en_US">
  <OrderId>...</OrderId>
  <UserId>...</UserId>
  <OrderDate>...</OrderDate>
  <ShippingDate>...</ShippingDate>
  <LineItem>...</LineItem>
  ...
</Invoice>
```

## Web Interface Implementation

### Authentication & Authorization

**web.xml Configuration**:

- Authentication method: FORM
- Login page: /login.jsp
- Error page: /error.jsp
- Protected resource: /RcvrRequestProcessor
- Required role: administrator

### Screen: Login Page (/login.jsp)

**Layout**:

- Form heading: "Please sign into Java Pet Store Supplier Module"
- Form posts to j_security_check (container-managed login)
- Two input fields: j_username and j_password
- Default values: "supplier" for both

**Implementation Notes**:

- Standard JSP form-based authentication
- No application-level login handler required; container handles j_security_check

### Screen: Inventory Management (/displayinventory.jsp)

**Layout**:

- Table with columns: Item ID | Existing Quantity | New Quantity | Update (checkbox)
- One table row per inventory item

**Implementation**:

- Uses JSP bean: `<jsp:useBean id="displayInventory" class="com.sun.j2ee.blueprints.supplier.inventory.web.DisplayInventoryBean" scope="session"/>`
- Retrieves inventory: `Collection inventoryItems = displayInventory.getInventory()`
- Iterates through items with Iterator
- Displays: `anItem.getItemId()`, `anItem.getQuantity()`
- Input fields: `<input name="qty_<itemId>" type="text" size="6">`
- Checkboxes: `<input name="item_<itemId>" type="checkbox" value="false">`
- Form posts to RcvrRequestProcessor with `currentScreen=updateinventory`

**Authorization**:

- Authorization check: `<% if(request.isUserInRole("administrator")) %>`
- Message shown if not authorized: "You are not authorised to update the status of orders"

### Screen: Supplier Home Page (/index.jsp)

**Layout**:

- Page heading: "Java Pet Store - Supplier Home Page"
- Explanatory text: "This application of the Java Pet Store enables updating the inventory items. This will enable the supplier component fill the items that are marked Back Ordered"
- Two forms:
  1. "Display Inventory" button (currentScreen=displayinventory)
  2. "Logout" button (currentScreen=logout)

**Implementation**:

- Both forms post to RcvrRequestProcessor servlet
- Hidden input fields carry the currentScreen parameter
- Submit buttons trigger the forms

## Data Initialization

**PopulateServlet** (/Populate endpoint):

- Reads init-parameter `PopulateData` pointing to `/populate/Populate-UTF8.xml`
- Loads XML file and populates Inventory entities
- Called at deployment or manually to initialize test data

## Transaction Management

**Container-Managed Transactions (CMT)**:

- OrderFulfillmentFacadeEJB methods use transaction-type: Container
- Transaction attribute: Required for all fulfillment operations
- Ensures atomic inventory reduction and order persistence

**User-Managed Transactions (UMT)**:

- RcvrRequestProcessor.doPost() uses UserTransaction for inventory update flow:
  1. `ut.begin()` - Start transaction
  2. `updateInventory(req)` - Update selected items
  3. `processPendingPO()` - Attempt fulfillment of pending orders
  4. `sendInvoices(Collection)` - Transition invoices
  5. `ut.commit()` - Commit all changes atomically

## Error Handling

**Inventory Lookup Failures**:

- FinderException caught and handled by returning false from checkInventory()
- Order item remains unfulfilled if inventory record not found

**Fulfillment Failures**:

- XMLDocumentException caught in processPendingPO() and printed to System.out
- Invoice generation failures return null and order status remains unchanged
- No explicit error notification or retry mechanism documented

**Parameter Validation**:

- Quantity values validated to be >= 0
- Missing or null qty\_\* parameters are skipped
- currentScreen parameter missing results in no action (implicit behavior)

## Configuration & Extensibility

**XML Validation**:

- Configurable DTD/XSD validation via environment entries:
  - `param/xml/validation/SupplierOrder` (Boolean)
  - `param/xml/xsdvalidation/SupplierOrder` (Boolean)
  - `param/xml/xsdvalidation/Invoice` (Boolean)
- Passed to XML document handlers at EJB creation time

**JMS Resources**:

- Topic: `jms/opc/InvoiceTopic` for invoice publishing
- Connection Factory: `jms/TopicConnectionFactory`
- Queue: SupplierOrderQueue for receiving purchase orders

## Legacy Implementation Notes

### Java EE 1.3 Patterns Used

- CMP 2.x Entity Beans (declarative persistence)
- Container-managed transactions with explicit attributes
- JSP scriptlets for business logic and authorization checks
- Message-driven beans for asynchronous order processing
- Remote and Local interfaces with explicit home interfaces
- Form-based authentication via container

### Known Limitations (from IR analysis)

- XMLDocumentException in createInvoice swallowed silently (System.out print only)
- Quantity update lacks upper bound validation (MAX_INT possible)
- Missing null check on currentScreen parameter could cause NullPointerException
- Order completion logic in PurchaseOrderHelper not visible from supplier module perspective
- SupplierOrderLocal and LineItemLocal contracts not fully validated from supplier source

### Testing Considerations

- Inventory reduction must be tested within transaction boundaries
- Partial fulfillment scenarios with mixed item availability
- Pending order retry workflow with concurrent inventory updates
- JSP bean session scope persistence during multi-step workflows
- Role-based authorization checks at web resource level
