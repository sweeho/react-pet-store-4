# Admin Operations Design

## Architecture Overview

The admin-operations capability follows a three-tier J2EE architecture:

1. **Presentation Tier**: Web-based JSP pages for login/logout and Java Swing rich client for order management
2. **Business Logic Tier**: Servlets (AdminRequestProcessor, ApplRequestProcessor) and business delegates
3. **Data Access Tier**: EJB facades (OPCAdminFacade) with exception wrapping

The legacy implementation uses two parallel client channels:

- **Web channel**: Form-based authentication via login.jsp
- **Rich client channel**: Java Web Start (JNLP) deployment with XML-based requests/responses

## Authentication & Authorization Strategy

### Form-Based Login

The system uses J2EE container-managed form-based authentication:

- Login form posts to `j_security_check` (standard J2EE endpoint)
- Container validates credentials against its realm
- Successful authentication creates an HttpSession with administrator role
- Failed authentication displays error.jsp

**Design rationale**: Form-based login leverages J2EE container security, avoiding custom authentication logic. Role-based access control (RBAC) is enforced at the servlet container level via security-constraints in web.xml.

### Session Management

Session timeout is configured at the container level (54 minutes) rather than application level, ensuring consistency across all request types and reducing code complexity.

**Design rationale**: Declarative session management in web.xml allows container to handle timeout enforcement consistently for both web and rich client requests.

## Data Model

### Order-Related Entities

**OrderDetails**: Core order information passed between client and server

- `orderId`: Unique order identifier
- `userId`: User who placed the order
- `orderDate`: Date order was placed
- `orderValue`: Total order amount (also referred to as OrderAmount in responses)
- `orderStatus`: Current status (PENDING, APPROVED, DENIED, COMPLETED, SHIPPED_PART)

**OrdersTO** (Transfer Object): Collection wrapper for OrderDetails objects used in XML responses

**Supported Order Statuses**:

- PENDING: Order awaiting administrator review
- APPROVED: Administrator has approved the order for fulfillment
- DENIED: Administrator has rejected the order
- COMPLETED: Order fulfillment is complete
- SHIPPED_PART: Order has been partially shipped

### Sales Analytics Data Model

Sales data aggregates orders by product category and date range:

- Category: Product category from catalog
- OrderQuantity: Number of orders in category
- Revenue: Total revenue in category
- DateRange: User-selected time window for analysis

## Communication Patterns

### Web Channel (AdminRequestProcessor)

- Protocol: HTTP POST/GET with form data
- Request format: HTML form submission
- Response format: JSP page rendering or JNLP file
- Authentication: Container-managed via j_security_check
- Session tracking: HttpSession with container timeout

### Rich Client Channel (ApplRequestProcessor)

- Protocol: HTTP POST with XML body
- Request format: XML with elements like `<Status>`, `<OrderId>`
- Response format: XML with structure like `<Response><Type>GETORDERS</Type>...</Response>`
- Authentication: Session ID passed in JNLP arguments and validated per request
- Error response: XML `<Error>Session Timed Out; Please exit and login as admin from the login page</Error>`

## Java Web Start (JNLP) Implementation

### JNLP Generation Strategy

When user clicks "Launch Rich Client" on index.jsp, AdminRequestProcessor.buildJNLP() dynamically generates a JNLP file with:

**Dynamic elements** (from request):

- Codebase: Built from request.getServerName() and request.getServerPort()
- Session ID: From req.getSession().getId()
- Server host/port: Passed as arguments to PetStoreAdminClient

**Static elements**:

- J2SE versions: 1.3 and 1.4 (reflects legacy supported versions)
- JAR files: AdminApp.jar, jaxp.jar, crimson.jar
- Main class: com.sun.j2ee.blueprints.admin.client.PetStoreAdminClient

**Design rationale**: Dynamic JNLP generation enables:

- Multi-host deployment (codebase adjusts to requesting server)
- Session persistence across server restart (session ID in arguments)
- Client-side proxy class override (for different backend implementations)

Response header sets `Content-Type: application/x-java-jnlp-file` so browsers launch Java Web Start.

## Rich Client Application Architecture

### Component Structure

**PetStoreAdminClient** (extends JFrame):

- Main application window
- Creates two JTabbedPane instances: ordersTabbedPane, salesTabbedPane
- Implements default ordering (Orders tab displayed first)
- Manages menu and toolbar

**OrdersViewPanel** (extends JPanel):

- Displays OrdersViewTableModel in a JTable
- Shows all orders with their details
- Allows filtering/sorting by status

**OrdersApprovePanel** (extends JPanel):

- Displays OrdersApproveTableModel in a JTable
- Shows pending orders only (PENDING status)
- Provides JComboBox for status selection (APPROVED or DENIED)
- Implements PropertyChangeListener for dynamic data updates
- Buttons: Approve, Deny, Commit for status changes

**BarChartPanel** (extends JPanel):

- Visualizes order quantity or revenue by category
- Updates dynamically as date range changes
- Implements PropertyChangeListener

**PieChartPanel** (extends JPanel):

- Visualizes revenue distribution by category
- Updates dynamically as date range changes
- Implements PropertyChangeListener

### Client-Server Communication

Rich client communicates with server via ApplRequestProcessor:

**Order Retrieval Request**:

```xml
<Request>
  <Type>GETORDERS</Type>
  <Status>PENDING</Status>
</Request>
```

**Order Response**:

```xml
<Response>
  <Type>GETORDERS</Type>
  <Status>PENDING</Status>
  <TotalCount>5</TotalCount>
  <Order>
    <OrderId>1001</OrderId>
    <UserId>user1</UserId>
    <OrderDate>2024-01-15</OrderDate>
    <OrderAmount>599.99</OrderAmount>
    <OrderStatus>PENDING</OrderStatus>
  </Order>
  ...
</Response>
```

**Session Validation Error**:

```xml
<Response>
  <Error>Session Timed Out; Please exit and login as admin from the login page</Error>
</Response>
```

## Business Delegate Pattern

### AdminRequestBD (Business Delegate)

Wraps EJB calls and exception handling:

- Calls OPCAdminFacade EJB for order operations
- Catches RemoteException and OPCAdminFacadeException
- Rethrows as AdminBDException (application-level exception)
- Insulates servlets from EJB infrastructure details

**Design rationale**: Business delegate separates servlet logic from EJB complexity, making testing easier and allowing easier migration away from EJBs if needed.

## Error Handling Strategy

### Authentication Errors

- Invalid credentials: Display error.jsp with failure message
- Missing credentials: Redirect to login.jsp (container behavior)

### Session Errors

- Session expired: Container redirects to login.jsp (web channel)
- Session missing (rich client): XML error response with message

### Data Access Errors

- EJB communication failure: Wrapped in AdminBDException
- Database errors: Propagated through AdminBDException

## Technology Stack Notes

- **J2EE Version**: Targets J2SE 1.3+, built for J2EE 1.3/1.4 era
- **Web Framework**: Servlets + JSP (no modern framework)
- **Rich Client Framework**: Swing (JFrame, JPanel, JTabbedPane, JTable, JComboBox)
- **Data Transfer**: XML over HTTP
- **EJB Integration**: Remote EJB calls via RMI-IIOP
- **Security**: Container-managed form-based authentication + RBAC

## Data Integrity Considerations

### Order Status Transitions

Allowable status transitions are implicit in the UI:

- PENDING orders can transition to APPROVED or DENIED
- Other order statuses are display-only in the UI
- Backend validation should enforce allowed transitions

### Concurrency

- Multiple admins might approve/deny same orders simultaneously
- Last-write-wins (no optimistic locking visible in legacy code)
- UI refresh rate (PropertyChangeListener) determines update visibility

## Deployment Considerations

### WAR Artifact (admin.war)

- Contains login.jsp, index.jsp, error.jsp
- Contains AdminRequestProcessor servlet
- Contains ApplRequestProcessor servlet
- Security configuration in web.xml

### EAR Artifact (admin-ear)

- Includes admin.war
- Includes admin-client JAR (contains PetStoreAdminClient and Swing components)
- Includes shared JARs (jaxp.jar, crimson.jar)

### JNLP Deployment

- JNLP file served dynamically by AdminRequestProcessor
- Client JARs must be accessible at codebase URL
- AdminApp.jar contains Swing application code
- jaxp.jar and crimson.jar provide XML parsing for client

## Migration Strategy Notes

The legacy system's J2EE/Swing implementation should be considered for modernization:

- Form-based authentication could move to OAuth2/OpenID Connect
- JSP could be replaced with modern web framework (React, Vue, etc.)
- Rich client Swing UI could migrate to web-based SPA
- XML communication could adopt JSON + REST APIs
- JNLP deployment could become WebAssembly or native client

However, all current requirements are specified in terms of the existing J2EE/Swing patterns, ensuring compatibility during a rebuild phase.
