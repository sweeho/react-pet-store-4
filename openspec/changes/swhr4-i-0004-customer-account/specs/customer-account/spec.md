## ADDED Requirements

### Requirement: Customer entity with unique identifier

The system SHALL maintain a Customer entity with a unique userId as the primary key and one-to-one relationships to Account and Profile entities with cascade-delete enabled.

#### Scenario: Customer is created with required fields

- **GIVEN** a request to create a new customer with a userId
- **WHEN** the customer entity is persisted
- **THEN** the userId is stored as the unique primary key and relationships to Account and Profile are established

### Requirement: Automatic account creation on customer registration

When a Customer is created, the system SHALL automatically create an associated Account with status set to "Active" and an associated Profile with documented default settings for preferredLanguage, favoriteCategory, myListPreference, and bannerPreference.

#### Scenario: Account and Profile are auto-created with customer

- **GIVEN** a new customer is registered with a userId
- **WHEN** the customer entity is created
- **THEN** an Account with "Active" status is automatically created and a Profile with default preferences is created, both linked to the customer

### Requirement: Account entity with status and cascading relationships

The system SHALL maintain an Account entity with a status field and one-to-one relationships to ContactInfo and CreditCard entities, with cascade-delete enabled for all relationships.

#### Scenario: Account can be created with or without contact information

- **GIVEN** a customer is created
- **WHEN** the system creates an Account
- **THEN** the Account can be created with only status, or with status plus ContactInfo and CreditCard; if ContactInfo and CreditCard are not provided, they are automatically created

### Requirement: Contact information entity with address relationship

The system SHALL maintain a ContactInfo entity with givenName, familyName, telephone, and email fields, with a one-to-one cascade-delete relationship to an Address entity.

#### Scenario: Contact information is stored with address

- **GIVEN** a customer account is created
- **WHEN** contact details are provided
- **THEN** ContactInfo fields (givenName, familyName, telephone, email) are stored along with an associated Address entity

### Requirement: Address entity with street-level details

The system SHALL maintain an Address entity with streetName1, streetName2, city, state, zipCode, and country fields, with a one-to-one cascade-delete relationship to ContactInfo.

#### Scenario: Address information is persisted

- **GIVEN** contact information includes address details
- **WHEN** address data is provided (streetName1, streetName2, city, state, zipCode, country)
- **THEN** all address fields are persisted in the Address entity

### Requirement: Credit card entity with expiry date parsing

The system SHALL maintain a CreditCard entity with cardNumber, cardType, and expiryDate fields stored as strings in MM/YYYY format, and provide methods to parse and return month and year components separately with default values "01" and "2010" when expiry date is null or malformed.

#### Scenario: Credit card expiry date is parsed into components

- **GIVEN** a credit card with expiryDate stored as "12/2025"
- **WHEN** getExpiryMonth() or getExpiryYear() is called
- **THEN** "12" is returned for month and "2025" is returned for year
- **WHEN** expiryDate is null or malformed
- **THEN** "01" is returned for month and "2010" is returned for year

### Requirement: Profile entity with user preferences

The system SHALL maintain a Profile entity with preferredLanguage, favoriteCategory, myListPreference, and bannerPreference fields, with a one-to-one cascade-delete relationship to Customer.

#### Scenario: User preferences are stored and retrieved

- **GIVEN** a customer is created
- **WHEN** profile preferences are set
- **THEN** preferredLanguage, favoriteCategory, myListPreference, and bannerPreference are stored and associated with the customer

### Requirement: Transactional consistency across entities

The system SHALL enforce transactional consistency with Required transaction attribute for all customer, account, profile, credit card, contact info, and address entity operations, ensuring ACID properties across all data modifications.

#### Scenario: Customer account modification is atomic

- **GIVEN** a customer account update that modifies multiple entities
- **WHEN** the update is processed
- **THEN** all changes are wrapped in a transaction with Required attribute and either all succeed or all fail

### Requirement: Customer account data propagation

When a customer account is created or updated, the system SHALL propagate contact information (givenName, familyName, telephone, email) to the Account's ContactInfo entity and address data (streetName1, streetName2, city, state, zipCode, country) to the associated Address entity.

#### Scenario: Customer account details are synchronized across entities

- **GIVEN** a customer account update with contact and address information
- **WHEN** the update is processed
- **WHEN** the customer data is persisted
- **THEN** ContactInfo and Address entities are updated with the provided values

### Requirement: Profile preference synchronization

When a customer account is created or updated, the system SHALL also update the associated Profile with preferredLanguage, favoriteCategory, myListPreference, and bannerPreference values from the customer request.

#### Scenario: Profile preferences are synchronized during account updates

- **GIVEN** a customer account update with profile preference data
- **WHEN** the update is processed
- **THEN** the Profile entity is updated with the provided preference values

### Requirement: User authentication verification

The system SHALL authenticate a user by verifying the provided password matches the stored password for the given username via case-sensitive string comparison.

#### Scenario: User credentials are verified during sign-in

- **GIVEN** a user submits username "alice" and password "secret123"
- **WHEN** the authenticate method is invoked
- **THEN** the password is compared case-sensitively against the stored password for username "alice"

### Requirement: Authentication session state management

The system SHALL maintain a session-scoped flag indicating whether the current user is authenticated, initialized to false for new sessions and set to true upon successful authentication.

#### Scenario: Authentication state persists across requests

- **GIVEN** a new HTTP session is created
- **WHEN** the session is first accessed
- **THEN** the SIGNED_ON_USER flag is initialized to false
- **WHEN** the user successfully authenticates
- **THEN** the flag is set to true and persists for the duration of the session

### Requirement: Access control to protected resources

The system SHALL enforce access control to protected resources, redirecting unauthenticated users to the sign-in page before allowing access to customer account, profile, and order-related screens.

#### Scenario: Unauthenticated user is redirected to sign-in

- **GIVEN** an unauthenticated user attempts to access a protected resource (e.g., customer.screen)
- **WHEN** the servlet filter intercepts the request
- **THEN** the original URL is stored in the session and the user is redirected to the sign-in page

### Requirement: Post-authentication redirect to original resource

The system SHALL redirect to the originally requested resource after successful authentication, retrieving the stored original URL from the session.

#### Scenario: User is returned to original page after sign-in

- **GIVEN** an unauthenticated user was redirected to sign-in while attempting to access /customer.screen
- **WHEN** the user successfully authenticates
- **THEN** the system retrieves the stored original URL (/customer.screen) from the session and redirects the user to it

### Requirement: Duplicate account prevention

The system SHALL prevent duplicate account creation by checking for existing username and raising DuplicateAccountException if an account with the provided username already exists.

#### Scenario: Account creation is rejected for duplicate username

- **GIVEN** a username "bob" already exists in the system
- **WHEN** a new account creation request is submitted with username "bob"
- **THEN** DuplicateAccountException is raised and the account is not created

### Requirement: Sign-in form display with dual-path options

The system SHALL display a sign-in form page with two sections: one for existing customers with username and password fields and a "Sign In" button, and one for new customer signup with username, password, and password confirmation fields and a "Create New Account" button.

#### Scenario: Sign-in page displays both authentication and registration options

- **GIVEN** the sign-in page is requested
- **WHEN** the page loads
- **THEN** the page displays a two-column layout with "Are you a returning customer?" title, left column with existing customer form (username, password, "Sign In" button), and right column with new customer form (username, password, repeat password, "Create New Account" button)

### Requirement: Sign-in error page display

The system SHALL display an error page when authentication fails, informing the user that the entered credentials were not found and inviting retry.

#### Scenario: Authentication failure displays error message

- **GIVEN** a user submits invalid credentials
- **WHEN** the authentication check fails
- **THEN** the system displays an error page with "Sign-in Error" title and message "There were errors signing you in. The user name and password you entered were not found in our records. Please try again."

### Requirement: Customer account information display

The system SHALL display a customer account information screen showing all contact information (first name, last name, street addresses, city, state/province, postal code, country, telephone, email), credit card information (card type, card number, expiry date), and profile information (preferred language, favorite category, MyList preference status, banner preference status).

#### Scenario: Account information is displayed

- **GIVEN** a logged-in customer accesses their account information
- **WHEN** the account information screen loads
- **THEN** the screen displays three sections: Contact Information (givenName, familyName, streetName1, streetName2, city, state, zipCode, country, telephone, email), Credit Card Information (cardType, cardNumber, expiryDate), and Profile Information (preferredLanguage, favoriteCategory, myListPreference, bannerPreference)

### Requirement: Customer creation form with default values

The system SHALL display a customer creation form allowing input of contact information, credit card details, and profile preferences with default values pre-populated for some fields (e.g., "Duke", "BluesPrints", "1234 Moon Way").

#### Scenario: Customer creation form is populated with defaults

- **GIVEN** a new customer is creating an account
- **WHEN** the customer creation form is displayed
- **THEN** the form shows three sections (Contact Information, Credit Card Information, Profile Information) with input fields for all attributes, and some fields are pre-populated with default values (e.g., given name "Duke", street "1234 Moon Way")

### Requirement: Customer account edit form with current values

The system SHALL display a customer account edit form allowing modification of all contact information, credit card details, and profile preferences, with current values pre-populated from the database.

#### Scenario: Customer account edit form displays current information

- **GIVEN** a customer accesses the edit account form
- **WHEN** the edit form loads
- **THEN** all form fields are pre-filled with current values from the database (current contact info, credit card details, profile preferences), allowing the customer to modify any field
