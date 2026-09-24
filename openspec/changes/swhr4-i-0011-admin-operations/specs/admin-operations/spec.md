# Admin Operations Specification

## ADDED Requirements

### Requirement: Administrator authentication

The admin system SHALL require users to authenticate via form-based login using username and password credentials before accessing any admin functionality. The authentication mechanism SHALL use standard J2EE form-based login with j_security_check endpoint.

#### Scenario: Valid credentials accepted

- **GIVEN** an unauthenticated user at the login page
- **WHEN** valid administrator credentials are submitted
- **THEN** the user is authenticated and redirected to the welcome page

#### Scenario: Invalid credentials rejected

- **GIVEN** an unauthenticated user at the login page
- **WHEN** invalid credentials are submitted
- **THEN** the error page is displayed with an authentication failure message

### Requirement: Administrator role enforcement

The system SHALL restrict access to all admin operations to users with the "administrator" role. GET and POST methods to protected admin endpoints MUST be enforced by role-based authorization.

#### Scenario: Authorized administrator accesses admin operations

- **GIVEN** an authenticated user with the "administrator" role
- **WHEN** the user accesses an admin endpoint
- **THEN** the request is processed

#### Scenario: Non-administrator access is denied

- **GIVEN** an authenticated user without the "administrator" role
- **WHEN** the user attempts to access an admin endpoint
- **THEN** access is denied and an authorization error is returned

### Requirement: Session timeout enforcement

User sessions in the admin system SHALL expire after 54 minutes of inactivity. When a session expires, the user SHALL be redirected to the login page for re-authentication.

#### Scenario: Active session continues

- **GIVEN** an authenticated admin user with an active session
- **WHEN** the user makes a request within 54 minutes of the last activity
- **THEN** the request is processed and the session timeout is extended

#### Scenario: Inactive session expires

- **GIVEN** an authenticated admin user whose session has been inactive for 54 minutes or more
- **WHEN** the user attempts to make a request
- **THEN** the session is invalidated and the user is redirected to the login page

### Requirement: Login screen interface

The admin system SHALL provide a login screen that accepts username and password input with form fields named j_username and j_password, and displays login errors when authentication fails.

#### Scenario: Login screen displayed with input fields

- **GIVEN** an unauthenticated user navigating to the admin login URL
- **WHEN** the login page is rendered
- **THEN** the screen displays a form with j_username and j_password input fields, and a submit button

#### Scenario: Login error displayed on failed authentication

- **GIVEN** a user who has submitted invalid credentials
- **WHEN** the login error page is rendered
- **THEN** the screen displays an authentication failure message

### Requirement: Welcome screen and navigation

After successful authentication, the admin system SHALL display a welcome screen with two primary actions: "Launch Rich Client" to access the admin client application, and "logout" to end the session.

#### Scenario: Welcome screen displayed after login

- **GIVEN** a user who has successfully authenticated
- **WHEN** the welcome page is rendered
- **THEN** the screen displays the welcome message, a "Launch Rich Client" button, and a "logout" button

#### Scenario: Rich Client launch button initiates JNLP download

- **GIVEN** an authenticated user on the welcome screen
- **WHEN** the "Launch Rich Client" button is clicked
- **THEN** a JNLP file is generated and downloaded to launch the rich client application

### Requirement: Session invalidation on logout

When user logs out, the admin system SHALL invalidate the session and redirect to the home page, preventing further use of the invalidated session.

#### Scenario: Session invalidated after logout

- **GIVEN** an authenticated user at the welcome screen
- **WHEN** the logout button is clicked
- **THEN** the user's session is invalidated and the user is redirected to the home page

#### Scenario: Invalidated session cannot be reused

- **GIVEN** a user whose session has been invalidated
- **WHEN** the user attempts to make a request with the invalidated session
- **THEN** access is denied and the user is redirected to the login page

### Requirement: Java Web Start (JNLP) deployment support

The system SHALL support launching the admin rich client via Java Web Start (JNLP). When an authenticated admin accesses the welcome page and clicks "Launch Rich Client", the AdminRequestProcessor servlet SHALL dynamically generate and return a JNLP file that specifies J2SE versions 1.3 or 1.4, lists required JAR files (AdminApp.jar, jaxp.jar, crimson.jar), and passes the session ID as an argument to the client main class (PetStoreAdminClient).

#### Scenario: JNLP file generated with server-specific codebase

- **GIVEN** an authenticated admin user clicking "Launch Rich Client"
- **WHEN** the AdminRequestProcessor generates the JNLP file
- **THEN** the JNLP file includes the server's hostname and port in the codebase URL, and specifies the correct JAR files and main class

#### Scenario: Session ID passed to rich client

- **GIVEN** the JNLP file generation for a specific authenticated session
- **WHEN** the rich client is launched from the JNLP file
- **THEN** the session ID is passed as an argument to PetStoreAdminClient for authentication persistence

### Requirement: Rich client session validation

The rich client SHALL validate that a session exists before processing requests. If a rich client request is received without an active session, the system SHALL return an XML error response: "Session Timed Out; Please exit and login as admin from the login page".

#### Scenario: Session validation on rich client request

- **GIVEN** a rich client request with an active session
- **WHEN** ApplRequestProcessor receives the request
- **THEN** the request is processed normally

#### Scenario: Session timeout error returned

- **GIVEN** a rich client request without an active session
- **WHEN** ApplRequestProcessor receives the request
- **THEN** an XML error response is returned: "Session Timed Out; Please exit and login as admin from the login page"

### Requirement: Order retrieval by status

The system SHALL retrieve and display orders filtered by status. Given a status (PENDING, APPROVED, DENIED, COMPLETED, SHIPPED_PART), the admin client SHALL fetch all orders matching that status, including OrderId, UserId, OrderDate, OrderAmount, and OrderStatus.

#### Scenario: Orders retrieved for specified status

- **GIVEN** a request to retrieve orders with status PENDING
- **WHEN** the getOrders request is processed
- **THEN** all orders with PENDING status are returned with their OrderId, UserId, OrderDate, OrderAmount, and OrderStatus

#### Scenario: No orders found for status

- **GIVEN** a request to retrieve orders for a status with no matching orders
- **WHEN** the getOrders request is processed
- **THEN** an empty collection is returned without error

### Requirement: Order status update

The admin system SHALL allow authorized administrators to change pending order statuses to APPROVED or DENIED, persisting the status change in the system.

#### Scenario: Pending order approved

- **GIVEN** a pending order selected in the Orders tab
- **WHEN** an administrator selects APPROVED status and commits the change
- **THEN** the order status is changed to APPROVED in the system

#### Scenario: Pending order denied

- **GIVEN** a pending order selected in the Orders tab
- **WHEN** an administrator selects DENIED status and commits the change
- **THEN** the order status is changed to DENIED in the system

### Requirement: Rich client Orders tab interface

The rich client application SHALL display an Orders tab with the ability to view orders by status and an Approve/Deny tab for administrators to change pending order statuses. The interface SHALL display a table of orders with columns for OrderId, UserId, OrderDate, OrderAmount, and OrderStatus, with a status dropdown for approved orders and action buttons (Approve, Deny, Commit) for pending orders.

#### Scenario: Orders displayed in tab with status filtering

- **GIVEN** an authenticated administrator with the rich client running
- **WHEN** the Orders tab is selected
- **THEN** the system displays a table with orders, filterable by status, showing OrderId, UserId, OrderDate, OrderAmount, and OrderStatus

#### Scenario: Order status changed via dropdown and committed

- **GIVEN** a pending order displayed in the Orders tab
- **WHEN** an administrator selects a new status from the dropdown and clicks Commit
- **THEN** the order status is updated in the system

### Requirement: Web interface screens

The admin module SHALL provide a web interface with a login page (/login.jsp), a welcome page (/index.jsp) showing options to launch the rich client or logout, and an error handling page (/error.jsp) for authentication failures.

#### Scenario: Login page accessible

- **GIVEN** an unauthenticated user accessing the admin URL
- **WHEN** the login page is requested
- **THEN** the login.jsp page is displayed with username and password fields

#### Scenario: Welcome page accessible after authentication

- **GIVEN** an authenticated user
- **WHEN** the welcome page is requested
- **WHEN** the index.jsp page is displayed with Rich Client launch and logout buttons

#### Scenario: Error page displayed on authentication failure

- **GIVEN** a failed login attempt
- **WHEN** the error page is requested
- **THEN** the error.jsp page is displayed with an authentication failure message

### Requirement: Rich client tabbed interface

The rich client interface SHALL display tabbed panels for order management and sales reporting. The order management tab SHALL provide OrdersViewPanel for listing all orders and OrdersApprovePanel for approving or denying pending orders. The sales tab SHALL display PieChartPanel and BarChartPanel for revenue and order quantity visualization by category.

#### Scenario: Rich client window displays tabbed interface

- **GIVEN** the rich client application launched via JNLP
- **WHEN** the main window is rendered
- **THEN** the application displays a tabbed interface with an Orders tab (showing OrdersViewPanel and OrdersApprovePanel) and a Sales tab (showing PieChartPanel and BarChartPanel)

#### Scenario: Switching between tabs updates display

- **GIVEN** the rich client application with Orders tab active
- **WHEN** the user clicks the Sales tab
- **THEN** the Sales tab displays bar and pie charts showing order quantity and revenue data by product category

#### Scenario: Sales data filtered by date range

- **GIVEN** the Sales tab with chart data displayed
- **WHEN** an administrator selects a date range
- **THEN** the charts update to show data for the selected date range only
