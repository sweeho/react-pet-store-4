# Customer Account Management - Design

## Data Model Architecture

### Entity Relationships

```
Customer (userId: PK)
  ├── Account (status)
  │   ├── ContactInfo (givenName, familyName, email, telephone)
  │   │   └── Address (streetName1, streetName2, city, state, zipCode, country)
  │   └── CreditCard (cardNumber, cardType, expiryDate)
  └── Profile (preferredLanguage, favoriteCategory, myListPreference, bannerPreference)
```

All relationships use cascade-delete for referential integrity.

### Entity Details

**Customer**

- Primary key: userId (String)
- Relationships: One-to-One with Account, One-to-One with Profile
- Multiplicity: One Customer has exactly one Account and one Profile
- Cascade behavior: When Customer is deleted, Account and Profile are automatically deleted

**Account**

- Foreign key: Linked to Customer via one-to-one relationship
- Status: "Active" (set automatically on creation), possibly other states for future extension
- Relationships: One-to-One with ContactInfo, One-to-One with CreditCard
- Optional creation: Can be created without ContactInfo/CreditCard; missing entities are auto-created
- Cascade behavior: Deleting Account cascades to ContactInfo and CreditCard

**ContactInfo**

- Fields: givenName, familyName, telephone, email (all String/required where used)
- Relationships: One-to-One with Account, One-to-One with Address
- Cascade behavior: Address cascades with ContactInfo

**Address**

- Fields: streetName1, streetName2, city, state, zipCode, country (all String)
- Relationships: One-to-One with ContactInfo
- Usage: Captured during customer creation and account updates

**CreditCard**

- Fields: cardNumber (String), cardType (String), expiryDate (String in MM/YYYY format)
- Parsing: getExpiryMonth() and getExpiryYear() methods parse MM/YYYY format
- Defaults: Month defaults to "01", Year defaults to "2010" when expiry is null/malformed
- Relationships: One-to-One with Account
- Security note: Legacy implementation stores plaintext; rebuild should use industry-standard encryption

**Profile**

- Fields:
  - preferredLanguage (String): Language code for UI localization
  - favoriteCategory (String): Product category preferred by user
  - myListPreference (Boolean): Enable/disable MyList feature
  - bannerPreference (Boolean): Show/hide promotional banners
- Default values: Set by ProfileLocalHome constants (not visible in source excerpts; values undetermined)
- Relationships: One-to-One with Customer

## Transaction Management

All entity operations run under EJB transaction attribute "Required", meaning:

- Each operation participates in an existing transaction or creates a new one
- ACID properties are guaranteed by the container
- On error, all changes are rolled back atomically

## Authentication & Session Management

### Authentication Flow

1. **Unauthenticated Request**: User attempts to access protected resource (e.g., customer.screen)
2. **Filter Interception**: SignOnFilter intercepts request and checks SIGNED_ON_USER session attribute
3. **Redirect to Sign-In**: If not authenticated, original URL is stored in session under ORIGINAL_URL and user is redirected to signon.jsp
4. **Form Submission**: User submits sign-in form (j_signon_check endpoint) with username and password
5. **Credential Verification**: SignOnFilter.validateSignOn calls authenticate service
6. **Password Comparison**: SignOnEJB.authenticate looks up user and calls matchPassword (case-sensitive String.equals)
7. **Session Update**: On success, SIGNED_ON_USER is set to true, USER_NAME is stored, and user is redirected to ORIGINAL_URL

### Session State

- **SIGNED_ON_USER**: Boolean flag indicating authentication status (initialized to false for new sessions)
- **USER_NAME**: String storing authenticated username
- **ORIGINAL_URL**: String storing the URL the user initially attempted to access

### Protected Resources

Resources protected by SignOnFilter are configured in signon-config.xml and include:

- customer.screen / customer.do (account information and updates)
- enter_order_information.screen (order checkout)
- signon_welcome.screen (post-login welcome page)

## User Interface Flows

### Sign-In Screen (signon.jsp)

Two-column layout:

- **Left Column ("Yes, I have an account")**:
  - Form action: j_signon_check (POST)
  - Fields: j_username, j_password
  - Optional: j_remember_username checkbox (sets/reads bp_signon cookie)
  - Button: "Sign In"
- **Right Column ("No, I would like to sign up")**:
  - Form action: createuser.do (POST)
  - Fields: Username, Password, Password Confirmation (j_password_2)
  - Button: "Create New Account"

Default values in sign-in form: username "j2ee", password "j2ee" (hardcoded in JSP; purpose/use undefined)

### Sign-In Error Screen (signon_failed.jsp)

Displays:

- Title: "Sign-in Error"
- Message: "There were errors signing you in. The user name and password you entered were not found in our records. Please try again."
- Implicit link/button to retry sign-in

### Customer Account Information Screen (customer.jsp)

Displays three sections:

**Contact Information**

- First Name (givenName)
- Last Name (familyName)
- Street Address Line 1 (streetName1)
- Street Address Line 2 (streetName2)
- City
- State/Province
- Postal Code (zipCode)
- Country
- Telephone
- Email

**Credit Card Information**

- Card Type (Visa, MasterCard, etc.)
- Card Number
- Expiry Date (MM/YYYY)

**Profile Information**

- Preferred Language
- Favorite Category
- MyList Preference Status (boolean, shown as enabled/disabled)
- Banner Preference Status (boolean, shown as enabled/disabled)

Uses JSP EL to bind to customer object properties: `${customer.account.contactInfo.givenName}`, etc.

Includes link to edit customer information (→ edit_customer.jsp).

### Customer Creation Form (create_customer.jsp)

Displays and accepts input for:

- All Contact Information fields (as above)
- All Credit Card Information fields (as above)
- All Profile Information fields (as above)

Default values are hardcoded (e.g., First Name = "Duke", Street = "1234 Moon Way").

Languages, categories, states, and countries are presented as `<select>` dropdowns with hardcoded option lists.

Form posts to createcustomer.do with action=create.

### Customer Edit Form (edit_customer.jsp)

Similar structure to create_customer.jsp but:

- Uses WAF framework tags for input rendering (waf:input, waf:select)
- Pre-populates all fields with current values via waf:value elements binding to EJB properties
- Form posts to customer.do with action=update

Allows modification of:

- All Contact Information fields
- All Credit Card Information fields
- All Profile Information fields

## Legacy Implementation Notes

### Technology Stack

The legacy implementation uses:

- **EJB 2.0**: Container-Managed Persistence (CMP) for entities, Session Beans for business logic
- **Servlet Filter**: SignOnFilter for centralized authentication and access control
- **JSP with JSTL and WAF**: Web tier rendering with custom WAF (Web Automation Framework) tags
- **HTTP Session**: State storage (not persistence)

### Design Patterns

1. **Session Bean as Facade**: CustomerEJBAction (Struts Action) wraps EJB operations with business logic
2. **Automatic Relationship Initialization**: ejbPostCreate methods create dependent entities on creation
3. **Deep Copy Pattern**: Customer updates perform field-by-field copy to ContactInfo and Address entities
4. **Configuration-Driven Access Control**: Protected resources configured in XML, matched at runtime

### Known Issues & Decisions

1. **Password Storage**: Passwords are stored in plaintext and compared with case-sensitive String.equals. Security implications should be addressed in rebuild.

2. **Expiry Date Defaults**: CreditCard.getExpiryMonth() and getExpiryYear() return hardcoded defaults ("01" and "2010") when expiry date is null/malformed. Reason for these specific values is undocumented.

3. **Profile Default Values**: Profile creation in CustomerEJB references ProfileLocalHome constants (DefaultPreferredLanguage, etc.) whose actual values are not visible in source excerpts. Default values must be determined during rebuild.

4. **Password Confirmation**: Sign-in form collects password confirmation (j_password_2) but CreateUserHTMLAction does not validate that both passwords match before creating user. Validation responsibility is unclear.

5. **Configuration Loading**: SignOnFilter loads protected resources from signon-config.xml with no error handling if file is missing or unparseable. Behavior on config error is undefined.

6. **Remember Username**: Sign-in form supports "Remember My User Name" via bp_signon cookie, but persistence mechanism and expiry are not visible in source excerpts.

### Considerations for Rebuild

1. **Password Security**: Use bcrypt, scrypt, or Argon2 with proper salting; never store plaintext
2. **Data Validation**: Implement comprehensive server-side validation for all form inputs
3. **Error Messages**: Consider more detailed error messages for debugging while protecting sensitive information
4. **Cascade Behavior**: Verify that cascade-delete is appropriate for all relationships; consider soft-delete or archive patterns for audit trails
5. **Transaction Isolation**: Test high-concurrency scenarios to ensure transaction isolation is sufficient
6. **Profile Defaults**: Document and make configurable the profile preference defaults
7. **Session Security**: Use HTTPS, secure cookies, appropriate session timeouts
8. **API Layer**: Consider if REST/GraphQL endpoints are needed for mobile or third-party integrations

## Dependencies

- **Signon Component**: Provides authentication service (SignOnEJB)
- **Profile Component**: Provides profile preference management (ProfileEJB)
- **Contact Information Component**: Provides address management (ContactInfoEJB, AddressEJB)
- **Credit Card Component**: Provides payment instrument management (CreditCardEJB)
