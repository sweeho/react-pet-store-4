# Supplier Integration Design

## Legacy Implementation Notes

### Authentication & Session Management

The legacy supplier module uses Java EE form-based authentication via FORM auth-method in web.xml. Login is processed through `j_security_check` endpoint. Session timeout is configured at the container level (54 minutes).

**Sources:**

- `web.xml` login-config: FORM auth with `/login.jsp` and `/error.jsp`
- Session timeout declared in `web.xml` session-config

### Inventory Management

Inventory is modeled as a CMP 2.x Entity EJB (`InventoryEJB`) with two core fields:

- `itemId` (String, primary key)
- `quantity` (integer)

The `reduceQuantity(int)` method is wrapped in container-managed transactions (trans-attribute: Required). Inventory lookups use finder methods by primary key. Queries for all inventory items are available via home interface.

**Sources:**

- `ejb-jar.xml`: InventoryEJB entity definition (CMP 2.x)
- `InventoryEJB.java`: Core inventory operations

### Purchase Order Workflow

Purchase orders are received from the Order Processing Center via JMS message queue (`SupplierOrderMDB`). The message-driven bean extracts XML from `TextMessage` and delegates to `OrderFulfillmentFacadeEJB`.

**Order Processing Flow:**

1. Receive PO XML via JMS
2. Parse XML to SupplierOrder object via `TPASupplierOrderXDE`
3. Persist order via `SupplierOrderEJB` (CMP entity)
4. Check inventory for each line item
5. If sufficient stock exists, reduce inventory and mark item as shipped
6. Generate invoice for fulfilled items via `TPAInvoiceXDE`
7. Send invoice back to OPC via transition delegate

**Partial Fulfillment:**
Orders support partial fulfillment. Only items with available inventory are shipped; pending items remain unfulfilled and can be fulfilled on subsequent retries.

**Sources:**

- `SupplierOrderMDB.java`: JMS message receiver
- `OrderFulfillmentFacadeEJB.java`: Core fulfillment logic
- `SupplierOrderEJB.java`: PO entity definition

### Order Status Lifecycle

Orders transition through states defined in `OrderStatusNames`:

- `PENDING`: Initially created or awaiting inventory
- `APPROVED`: Order has been accepted (set by OPC, not supplier module)
- `COMPLETED`: All line items fulfilled and shipped
- `DENIED`: Order cannot be fulfilled

**Sources:**

- `OrderStatusNames.java`: Status constant definitions

### Invoice Generation

Invoices are XML documents created via `TPAInvoiceXDE` and include:

- Order ID
- User ID ("Dear PetStore Customer")
- Order date (from purchase order)
- Current shipping date
- Line items for all fulfilled items (category, product, item ID, line number, quantity, unit price)

Invoices are filtered to include only items that were actually shipped (tracked in a map during partial fulfillment).

**Sources:**

- `OrderFulfillmentFacadeEJB.createInvoice()`: Invoice generation logic
- `TPAInvoiceXDE`: XML document handler

### Inventory Update & Pending Order Retry

When inventory is updated via the UI, the system:

1. Updates selected inventory items with new quantities
2. Queries for all pending orders
3. Attempts fulfillment on each pending order with the new stock
4. Generates and sends invoices for any newly fulfilled items

All operations are wrapped in a user-managed transaction (`UserTransaction`).

**Sources:**

- `RcvrRequestProcessor.updateInventory()`: Parses request parameters (item*\*, qty*\*)
- `RcvrRequestProcessor.processPendingPO()`: Retry fulfillment
- `OrderFulfillmentFacadeEJB.processPendingPO()`: Query pending orders

### Web Application Structure

The supplier module is a servlet-based application:

- **Login**: `/login.jsp` - form-based authentication with pre-filled credentials
- **Home**: `/index.jsp` - navigation page after login
- **Display Inventory**: `/displayinventory.jsp` - lists all inventory with update controls
- **Request Processing**: `RcvrRequestProcessor` servlet - handles form submissions
- **Logout**: `/logout.jsp` - session invalidation endpoint

Authorization is controlled via `web.xml` security-constraint on `/RcvrRequestProcessor` (requires administrator role).

**Sources:**

- `web.xml`: Security configuration and servlet mappings
- JSP files under `/docroot/`

### XML Document Validation

XML validation for both purchase orders and invoices can be configured independently via environment entries:

- `param/xml/validation/SupplierOrder`
- `param/xml/xsdvalidation/SupplierOrder`
- `param/xml/xsdvalidation/Invoice`

These are read during bean creation and passed to XML document handlers.

**Sources:**

- `ejb-jar.xml`: Environment entry declarations
- `OrderFulfillmentFacadeEJB.ejbCreate()`: Configuration loading

### Inventory Population

Initial inventory data is loaded via `PopulateServlet` at the `/Populate` endpoint, which reads from `/populate/Populate-UTF8.xml`.

**Sources:**

- `web.xml`: PopulateServlet configuration
- `PopulateServlet.java`: Initialization logic

### Known Limitations

1. **Quantity Validation**: `updateInventory()` accepts any non-negative integer without upper bounds validation. No tests or configuration visible for maximum quantity limits.

2. **Error Handling**: Failed invoice generation in `processAnOrder()` prints to System.out but does not trigger retry, notification, or order status update. No logging framework is configured.

3. **Missing Parameter Handling**: `RcvrRequestProcessor.doPost()` does not explicitly handle missing or null `currentScreen` parameter; would throw `NullPointerException` under this condition.

4. **Entity References**: The order and line item entities are referenced but not fully visible in supplier module source (they reside in separate components). Cross-component entity contracts are not fully documented.

## Implementation Guidance

When implementing this capability in the target system:

1. **Data Model**: Create persistent entities for SupplierOrder, LineItem, and Inventory with the fields described above. Use database transactions for all multi-step operations.

2. **Message Integration**: Implement JMS message receiver for incoming purchase orders. Use a queue for inbound POs and a topic for outbound invoices.

3. **XML Handling**: Parse purchase order XML and generate invoice XML with the field structure described. Support configurable validation.

4. **UI Implementation**: Build web forms for login, inventory display, and inventory updates. Enforce role-based access control at the route level.

5. **Session Management**: Configure session timeout to 54 minutes. Invalidate sessions on logout.

6. **Error Handling**: Add structured logging for invoice generation failures and order processing exceptions. Consider implementing a retry queue for failed fulfillments.

7. **Validation**: Add quantity upper bounds validation. Validate required form parameters before processing.
