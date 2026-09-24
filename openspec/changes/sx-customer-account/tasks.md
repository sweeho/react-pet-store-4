## 1. Data Model - Core Entities

- [ ] 1.1 Define Customer entity with userId as primary key and relationships to Account and Profile
- [ ] 1.2 Define Account entity with status field and relationships to ContactInfo and CreditCard
- [ ] 1.3 Define ContactInfo entity with name, phone, email fields and relationship to Address
- [ ] 1.4 Define Address entity with street, city, state, zip, country fields
- [ ] 1.5 Define CreditCard entity with cardNumber, cardType, expiryDate fields
- [ ] 1.6 Define Profile entity with preferredLanguage, favoriteCategory, myListPreference, bannerPreference fields
- [ ] 1.7 Implement cascade-delete relationships between all entities
- [ ] 1.8 Set up database schema with proper constraints and indexes

## 2. Entity Lifecycle Management

- [ ] 2.1 Implement Customer creation with automatic Account and Profile generation
- [ ] 2.2 Implement Account creation with optional ContactInfo and CreditCard auto-creation
- [ ] 2.3 Implement cascade-delete behavior for Customer removal
- [ ] 2.4 Implement Account update with propagation to ContactInfo and Address
- [ ] 2.5 Implement Profile update with preference synchronization
- [ ] 2.6 Implement CreditCard expiry date parsing methods (getExpiryMonth, getExpiryYear)

## 3. Transaction Management

- [ ] 3.1 Configure transaction attributes (Required) for all customer operations
- [ ] 3.2 Ensure ACID compliance for multi-entity updates
- [ ] 3.3 Implement rollback behavior on transaction failure
- [ ] 3.4 Test transaction isolation across concurrent operations

## 4. Authentication & Access Control

- [ ] 4.1 Implement password verification with case-sensitive comparison
- [ ] 4.2 Implement session-scoped authentication flag (SIGNED_ON_USER)
- [ ] 4.3 Implement servlet filter for protected resource access control
- [ ] 4.4 Implement original URL storage and retrieval for post-auth redirect
- [ ] 4.5 Implement duplicate username detection (DuplicateAccountException)
- [ ] 4.6 Implement sign-in form with dual-path (existing customer / new signup)
- [ ] 4.7 Implement sign-in error page display

## 5. User Interface - Sign-In

- [ ] 5.1 Create sign-in form component with two-column layout
- [ ] 5.2 Implement existing customer form (username, password, remember checkbox)
- [ ] 5.3 Implement new customer signup form (username, password, password confirmation)
- [ ] 5.4 Create sign-in error page with user-friendly message
- [ ] 5.5 Implement form submission and validation

## 6. User Interface - Account Management

- [ ] 6.1 Create customer account information display screen
- [ ] 6.2 Implement display of contact information section
- [ ] 6.3 Implement display of credit card information section
- [ ] 6.4 Implement display of profile information section
- [ ] 6.5 Create customer creation form with three sections
- [ ] 6.6 Implement default values in creation form
- [ ] 6.7 Create customer account edit form with pre-populated values
- [ ] 6.8 Implement edit form submission and validation

## 7. API / Service Layer

- [ ] 7.1 Implement customer lookup by userId
- [ ] 7.2 Implement customer creation service
- [ ] 7.3 Implement customer update service
- [ ] 7.4 Implement authenticate service (username + password)
- [ ] 7.5 Implement account information retrieval service
- [ ] 7.6 Implement duplicate username check service
- [ ] 7.7 Implement profile preference update service
- [ ] 7.8 Define exception contract (DuplicateAccountException, etc.)

## 8. Integration & Workflows

- [ ] 8.1 Implement unauth-user-to-signin workflow (filter redirection)
- [ ] 8.2 Implement signin-to-protected-resource workflow (post-auth redirect)
- [ ] 8.3 Integrate authentication with session management
- [ ] 8.4 Integrate account creation with profile defaults
- [ ] 8.5 Integrate customer update with contact and profile sync
- [ ] 8.6 Wire sign-in form to authentication service
- [ ] 8.7 Wire account info display to data retrieval service
- [ ] 8.8 Wire edit form to account update service

## 9. Testing & Validation

- [ ] 9.1 Write unit tests for entity creation and relationships
- [ ] 9.2 Write unit tests for authentication logic
- [ ] 9.3 Write unit tests for expiry date parsing
- [ ] 9.4 Write integration tests for customer account workflows
- [ ] 9.5 Write integration tests for authentication and access control
- [ ] 9.6 Write UI tests for sign-in and account management forms
- [ ] 9.7 Test cascade-delete behavior
- [ ] 9.8 Test transaction rollback scenarios
- [ ] 9.9 Test duplicate account prevention
- [ ] 9.10 End-to-end test: user creation → signin → account view → edit → update
