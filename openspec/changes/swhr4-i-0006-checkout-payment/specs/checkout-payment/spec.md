# Checkout-Payment Capability Specification

## ADDED Requirements

### Requirement: Credit Card Entity Persistence

The system SHALL persist credit card information comprising card number, card type, and expiry date as a Container-Managed Persistence Entity Bean with declared CMP fields.

#### Scenario: Credit card is created with customer account

- **GIVEN** a new customer account creation request with credit card details
- **WHEN** the account entity is created via ejbCreate
- **THEN** a CreditCard entity is instantiated with three CMP fields (cardNumber, cardType, expiryDate) and persisted by the container

#### Scenario: Credit card data is accessed from persistent storage

- **GIVEN** a persisted CreditCard entity with known card details
- **WHEN** the account's credit card is retrieved
- **THEN** the three CMP fields return their persisted values unchanged

### Requirement: Credit Card Number Input

The system SHALL accept credit card numbers as alphanumeric strings of up to 30 characters in length at the form input level.

#### Scenario: Card number is entered within length constraint

- **GIVEN** the edit customer form with a card number input field
- **WHEN** a user enters a card number of 30 characters or less
- **THEN** the field accepts the input and does not reject it

#### Scenario: Card number exceeds form-level constraint

- **GIVEN** the edit customer form with maxlength="30" on the card number field
- **WHEN** a user attempts to type beyond 30 characters
- **THEN** the HTML form element prevents entry of additional characters

### Requirement: Credit Card Type Selection

The system SHALL restrict credit card type selection to exactly three predefined values: "Java(TM) Card", "Duke Express", and "Meow Card".

#### Scenario: User selects from card type dropdown

- **GIVEN** the edit customer form with a card type dropdown
- **WHEN** a user views the card type options
- **THEN** exactly three options are displayed: Java(TM) Card, Duke Express, and Meow Card

#### Scenario: Card type is stored with purchase order

- **GIVEN** a purchase order is being created with a selected card type
- **WHEN** the customer selects one of the three valid card types
- **THEN** the selected value is stored in the CreditCard entity's cardType field

### Requirement: Credit Card Expiry Date Format

The system SHALL store and format credit card expiry date as a string in MM/YYYY format, where MM is a two-digit month (01-12) and YYYY is a four-digit year. The month and year components are captured separately in the form, then concatenated with a "/" delimiter.

#### Scenario: User provides separate month and year

- **GIVEN** the edit customer form with separate month and year dropdowns
- **WHEN** a user selects month "05" and year "2004"
- **THEN** these values are concatenated into the string "05/2004" and stored in the expiryDate field

#### Scenario: Expiry date is parsed for display

- **GIVEN** a CreditCard entity with expiryDate "03/2003"
- **WHEN** the getExpiryMonth() method is called
- **THEN** the method returns "03"

#### Scenario: Expiry date is parsed for year display

- **GIVEN** a CreditCard entity with expiryDate "07/2004"
- **WHEN** the getExpiryYear() method is called
- **THEN** the method returns "2004"

### Requirement: Credit Card Expiry Month Default

WHEN credit card expiry month is null or missing in stored card data, the system SHALL default to month "01" when displaying or retrieving the month via getExpiryMonth().

#### Scenario: Expiry date is null

- **GIVEN** a CreditCard entity with expiryDate set to null
- **WHEN** getExpiryMonth() is called
- **THEN** the method returns "01"

#### Scenario: Expiry date is malformed without slash

- **GIVEN** a CreditCard entity with expiryDate "05" (no "/" separator)
- **WHEN** getExpiryMonth() is called
- **THEN** the method returns "01" as the default fallback

### Requirement: Credit Card Expiry Year Default

WHEN credit card expiry year is null or missing in stored card data, the system SHALL default to year "2010" when displaying or retrieving the year via getExpiryYear().

#### Scenario: Expiry date is null

- **GIVEN** a CreditCard entity with expiryDate set to null
- **WHEN** getExpiryYear() is called
- **THEN** the method returns "2010"

#### Scenario: Expiry date is malformed without slash

- **GIVEN** a CreditCard entity with expiryDate "03" (no "/" separator)
- **WHEN** getExpiryYear() is called
- **THEN** the method returns "2010" as the default fallback

### Requirement: Credit Card Required Field Validation

The system SHALL require credit card number, card type, and expiry date (month and year) when a customer creates or updates their account. All four fields SHALL be validated as non-empty and the system SHALL reject submissions with missing values.

#### Scenario: All credit card fields are provided

- **GIVEN** the customer edit form with all card fields populated
- **WHEN** the form is submitted
- **THEN** validation passes and the account is created/updated

#### Scenario: Credit card number is empty

- **GIVEN** the customer edit form with empty card number
- **WHEN** the form is submitted
- **THEN** the system raises MissingFormDataException with "Credit Card" in the missing fields list

#### Scenario: Card type is empty

- **GIVEN** the customer edit form with empty card type
- **WHEN** the form is submitted
- **THEN** the system rejects the submission (note: validation bug in legacy code checks cardNumber instead)

### Requirement: Credit Card Expiry Year Range

The system SHALL present credit card expiry years in the range 2002-2005 as selectable options to users in the account profile form.

#### Scenario: User views expiry year options

- **GIVEN** the edit customer form with expiry year dropdown
- **WHEN** a user views the year options
- **THEN** exactly four options are displayed: 2002, 2003, 2004, 2005

### Requirement: Credit Card XML Serialization Format

The system SHALL enforce that CreditCard XML documents contain exactly three required child elements in order: CardNumber, CardType, and ExpiryDate, each with character data content (PCDATA). The DTD defines these as required, non-repeating elements.

#### Scenario: CreditCard object is serialized to XML

- **GIVEN** a CreditCard object with cardNumber "4111111111111111", cardType "Visa", expiryDate "12/2025"
- **WHEN** toDOM() is called to serialize to XML
- **THEN** the resulting XML contains elements CreditCard > (CardNumber, CardType, ExpiryDate) in that order

#### Scenario: CreditCard XML is deserialized to object

- **GIVEN** a valid CreditCard XML document with three elements in order
- **WHEN** fromDOM() is called to deserialize
- **THEN** a CreditCard object is created with the three field values extracted in order

### Requirement: Purchase Order Credit Card Association

Every Purchase Order SHALL have exactly one associated CreditCard entity containing cardNumber, cardType, and expiryDate. The credit card SHALL be associated one-to-one with a purchase order and cascade-deleted when the order is removed.

#### Scenario: Purchase order is created with credit card

- **GIVEN** order creation request with purchase order and credit card details
- **WHEN** PurchaseOrderEJB.ejbPostCreate() is invoked
- **THEN** a CreditCard entity is created via the CreditCardLocalHome factory and associated with the order via setCreditCard()

#### Scenario: Purchase order is deleted

- **GIVEN** a purchase order with an associated credit card
- **WHEN** the purchase order is removed
- **THEN** the associated CreditCard entity is cascade-deleted by the container per the relationship definition

### Requirement: Credit Card Transactional Consistency

The system SHALL enforce transactional consistency with Required transaction attribute for all CreditCard entity operations, including all getter/setter methods, create operations, remove operations, and primary key finder methods.

#### Scenario: Credit card getter is invoked

- **GIVEN** a method invocation on CreditCard entity (e.g., getCardNumber())
- **WHEN** the getter is called
- **THEN** the method runs within an active transaction with trans-attribute="Required"

#### Scenario: Credit card modification in transaction

- **GIVEN** an active transaction context
- **WHEN** setCardType() is called to modify the credit card
- **THEN** the modification is part of the same transaction and rolled back if the transaction fails

### Requirement: Credit Card Data Transfer Object

The system SHALL provide a CreditCard transfer object (non-EJB POJO) that supports construction with cardNumber, cardType, and expiryDate parameters, getter/setter methods for all three fields, and XML serialization/deserialization via toDOM() and fromDOM() methods.

#### Scenario: CreditCard transfer object is constructed

- **GIVEN** values for card number, type, and expiry date
- **WHEN** new CreditCard(cardNumber, cardType, expiryDate) is called
- **THEN** a new POJO instance is created with all three fields set

#### Scenario: CreditCard transfer object is used in EJB method

- **GIVEN** a CreditCard transfer object with populated fields
- **WHEN** it is passed as a parameter to CreditCardEJB.ejbCreate(CreditCard cc)
- **WHEN** the entity copies field values from the transfer object
- **THEN** the entity fields are populated with the transfer object's values

### Requirement: Credit Card getData Method

The system SHALL provide a getData() method on the CreditCard entity that constructs and returns a fresh CreditCard transfer object (POJO) containing copies of the current cardNumber, cardType, and expiryDate values.

#### Scenario: Entity state is retrieved as transfer object

- **GIVEN** a persisted CreditCard entity with cardNumber "4111", cardType "Duke", expiryDate "08/2005"
- **WHEN** getData() is called
- **THEN** a new CreditCard transfer object is returned with copies of the three field values

### Requirement: Credit Card Security Access Control

The system SHALL allow unchecked access to all CreditCard entity methods, meaning no role-based authorization is enforced at the method level. Access control is delegated to a higher layer.

#### Scenario: CreditCard entity is accessed

- **GIVEN** any caller attempting to invoke a CreditCard entity method
- **WHEN** the method is invoked
- **THEN** no EJB-level role check is performed (unchecked authorization)

### Requirement: Credit Card Integration with Account

The system SHALL make credit card data accessible to the Account EJB via a local EJB reference ("java:comp/env/ejb/CreditCard") at account creation time. The CreditCard entity is local-only with no remote interface.

#### Scenario: Account creates associated credit card

- **GIVEN** AccountEJB.ejbCreate() is invoked during account creation
- **WHEN** the account looks up the CreditCard home via JNDI "java:comp/env/ejb/CreditCard"
- **THEN** the lookup succeeds and a CreditCard bean can be created and associated with the account

### Requirement: Credit Card Account Lifecycle

The system SHALL create a new CreditCardLocal bean when a new account is created via AccountEJB.ejbCreate(), and associate that bean instance with the Account.

#### Scenario: Account is created with credit card

- **GIVEN** a new customer account creation
- **WHEN** AccountEJB.ejbCreate() or AccountEJB.ejbPostCreate() is called with a CreditCardLocal parameter
- **THEN** the credit card is set on the account via setCreditCard()

### Requirement: Order Entry Screen

The Order Entry Screen SHALL collect billing and shipping address information, credit card details, and display order summary for confirmation before placement. The screen SHALL present form fields for all required information and accept a POST submission to the order.do endpoint.

#### Scenario: Order entry form is displayed

- **GIVEN** a customer at the checkout step with items in cart
- **WHEN** the enter_order_information.jsp screen is rendered
- **THEN** the screen displays sections for billing information (first name, last name, street address, city, state, postal code, country, telephone, email) and shipping information with the same fields, plus credit card fields and order summary

#### Scenario: Order entry form is submitted

- **GIVEN** the order entry form with all fields completed
- **WHEN** the user clicks submit/checkout
- **THEN** the form POSTs to order.do action with all collected data (billing, shipping, credit card, order items)

#### Scenario: Order is confirmed after entry

- **GIVEN** valid order information submitted via the entry form
- **WHEN** server-side processing completes successfully
- **THEN** a confirmation screen (order_complete.screen) is displayed with order details and confirmation number
