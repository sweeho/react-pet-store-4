# Checkout-Payment Implementation Tasks

## 1. Data Model: Credit Card Entity

- [ ] 1.1 Define CreditCard entity with three fields: cardNumber (String, up to 30 chars), cardType (enum: Java Card/Duke Express/Meow Card), expiryDate (String, MM/YYYY format)
- [ ] 1.2 Set up CMP field definitions and container-managed persistence configuration
- [ ] 1.3 Define XML serialization structure (CreditCard > CardNumber, CardType, ExpiryDate)
- [ ] 1.4 Implement toDOM() method for CreditCard XML serialization
- [ ] 1.5 Implement fromDOM() method for CreditCard XML deserialization

## 2. Data Model: Relationships

- [ ] 2.1 Define One-to-One relationship between PurchaseOrder and CreditCard with cascade-delete
- [ ] 2.2 Define One-to-One relationship between Account and CreditCard
- [ ] 2.3 Configure CMR field accessors (getCreditCard/setCreditCard) on related entities

## 3. Credit Card Entity Bean Implementation

- [ ] 3.1 Create abstract getter/setter methods for cardNumber, cardType, expiryDate CMP fields
- [ ] 3.2 Implement overloaded ejbCreate methods: (no params), (cardNumber, cardType, expiryDate), (CreditCard transfer object)
- [ ] 3.3 Implement ejbPostCreate methods for each ejbCreate variant
- [ ] 3.4 Implement getExpiryMonth() with "/" parsing and "01" default for null/malformed
- [ ] 3.5 Implement getExpiryYear() with "/" parsing and "2010" default for null/malformed
- [ ] 3.6 Implement getData() method returning fresh CreditCard transfer object
- [ ] 3.7 Declare all methods with trans-attribute="Required" in ejb-jar.xml
- [ ] 3.8 Declare unchecked access for all methods in ejb-jar.xml method-permission

## 4. Credit Card Transfer Object (POJO)

- [ ] 4.1 Create CreditCard POJO with three fields: cardNumber, cardType, expiryDate
- [ ] 4.2 Implement constructor with no parameters
- [ ] 4.3 Implement constructor with three parameters (cardNumber, cardType, expiryDate)
- [ ] 4.4 Implement getter methods for all three fields
- [ ] 4.5 Implement setter methods for all three fields
- [ ] 4.6 Implement toDOM() method for XML serialization
- [ ] 4.7 Implement fromDOM() static method for XML deserialization
- [ ] 4.8 Define DTD schema for CreditCard XML structure

## 5. Validation and Input Processing

- [ ] 5.1 Implement form validation for card number non-empty requirement
- [ ] 5.2 Implement form validation for card type non-empty requirement
- [ ] 5.3 Implement form validation for expiry month non-empty requirement
- [ ] 5.4 Implement form validation for expiry year non-empty requirement
- [ ] 5.5 Implement MissingFormDataException raising for missing card fields
- [ ] 5.6 Add maxlength="30" constraint to card number form input
- [ ] 5.7 Implement card type dropdown with three options (Java Card, Duke Express, Meow Card)
- [ ] 5.8 Implement expiry year dropdown with range 2002-2005
- [ ] 5.9 Implement expiry month dropdown with months 01-12

## 6. Order Integration

- [ ] 6.1 Update PurchaseOrderEJB to include getCreditCard/setCreditCard accessors
- [ ] 6.2 Update PurchaseOrder value object to include creditCard field
- [ ] 6.3 Configure credit card lookup in PurchaseOrderEJB.ejbPostCreate via ServiceLocator
- [ ] 6.4 Ensure CreditCard entity is created and associated during order creation
- [ ] 6.5 Ensure cascade-delete removes credit card when purchase order is deleted

## 7. Account Integration

- [ ] 7.1 Update AccountEJB to include getCreditCard/setCreditCard accessors
- [ ] 7.2 Update Account value object to include creditCard field
- [ ] 7.3 Implement CreditCard instantiation in AccountEJB.ejbPostCreate
- [ ] 7.4 Configure JNDI reference "java:comp/env/ejb/CreditCard" in ejb-jar.xml

## 8. Web Forms and UI

- [ ] 8.1 Create/update edit_customer.jsp with card number text input (maxlength="30")
- [ ] 8.2 Add card type dropdown (select) with three options
- [ ] 8.3 Add expiry month dropdown (select) with months 01-12
- [ ] 8.4 Add expiry year dropdown (select) with years 2002-2005
- [ ] 8.5 Add validation="validation" attribute to required card fields
- [ ] 8.6 Create/update enter_order_information.jsp with billing information section
- [ ] 8.7 Add shipping information section (mirror of billing)
- [ ] 8.8 Add credit card information section (number, type, expiry)
- [ ] 8.9 Add order summary display
- [ ] 8.10 Implement form POST to order.do action

## 9. Request Handler / Controller

- [ ] 9.1 Implement extractCreditCard() method in CustomerHTMLAction
- [ ] 9.2 Parse credit card form parameters (credit_card_number, credit_card_type, credit_card_expiry_month, credit_card_expiry_year)
- [ ] 9.3 Validate non-empty values for all four parameters
- [ ] 9.4 Concatenate month and year with "/" separator
- [ ] 9.5 Construct CreditCard transfer object from extracted parameters
- [ ] 9.6 Raise MissingFormDataException if any required field is empty
- [ ] 9.7 Include extracted CreditCard in CustomerEvent for business tier processing

## 10. Configuration and Deployment

- [ ] 10.1 Declare CreditCard entity bean in ejb-jar.xml with correct entity configuration
- [ ] 10.2 Configure local-home and local interfaces in ejb-jar.xml
- [ ] 10.3 Configure ejb-local-ref for CreditCard in dependent components
- [ ] 10.4 Define all CMP fields in ejb-jar.xml persistence configuration
- [ ] 10.5 Define container-transaction entries for all methods with Required attribute
- [ ] 10.6 Define method-permission for unchecked access
- [ ] 10.7 Define ejb-relations for PurchaseOrder-CreditCard and Account-CreditCard

## 11. Testing and Verification

- [ ] 11.1 Write unit tests for CreditCard entity creation with three constructors
- [ ] 11.2 Write unit tests for getExpiryMonth() with valid and null/malformed inputs
- [ ] 11.3 Write unit tests for getExpiryYear() with valid and null/malformed inputs
- [ ] 11.4 Write unit tests for CreditCard XML serialization (toDOM/fromDOM)
- [ ] 11.5 Write integration tests for Account-CreditCard relationship lifecycle
- [ ] 11.6 Write integration tests for PurchaseOrder-CreditCard relationship with cascade delete
- [ ] 11.7 Write form validation tests for required field enforcement
- [ ] 11.8 Write E2E tests for customer account creation with credit card
- [ ] 11.9 Write E2E tests for order creation with credit card selection
- [ ] 11.10 Verify transaction isolation for Required trans-attribute

## 12. Documentation and Maintenance

- [ ] 12.1 Document hardcoded defaults (01, 2010) with rationale or migration notes
- [ ] 12.2 Document primary key handling for CreditCard entity (java.lang.Object)
- [ ] 12.3 Create migration guide for expiry year range update (2002-2005 to current/future range)
- [ ] 12.4 Document validation bug fix (card type/expiry fields checked for correctness)
