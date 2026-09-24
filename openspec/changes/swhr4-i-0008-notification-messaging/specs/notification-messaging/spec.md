## ADDED Requirements

### Requirement: Asynchronous email message processing

The system SHALL process email notifications asynchronously via a JMS queue-based message-driven bean that receives TextMessages containing XML-serialized mail content and decouples mail sending from the originating transaction.

#### Scenario: Mail message received and queued

- **GIVEN** an email notification message arrives on the JMS queue
- **WHEN** MailerMDB receives the message
- **THEN** the message is processed asynchronously without blocking the originating caller

#### Scenario: XML message parsing

- **GIVEN** a TextMessage containing XML-formatted mail data
- **WHEN** MailerMDB.onMessage processes the message
- **THEN** the XML is parsed via Mail.fromXML() and validated against the Mail DTD schema

### Requirement: Email message XML structure and validation

The system SHALL accept email notifications as XML documents containing exactly three required elements: Address (recipient), Subject (email subject), and Content (email body), validated against a DTD schema before processing.

#### Scenario: Valid XML mail message

- **GIVEN** an XML document with Address, Subject, and Content elements in the correct order
- **WHEN** Mail.fromXML() is invoked
- **THEN** the Mail object is constructed with all three fields populated

#### Scenario: Invalid XML structure

- **GIVEN** an XML document with missing or invalid elements
- **WHEN** Mail.fromXML() is invoked with DTD validation enabled
- **THEN** an XMLDocumentException is thrown and the message is redelivered by the container

### Requirement: SMTP email transmission via JavaMail

The system SHALL send email messages using the J2EE JavaMail API with container-managed Session obtained from JNDI resource java:comp/env/mail/MailSession and transmit via SMTP Transport.

#### Scenario: Email sent successfully

- **GIVEN** a valid Mail object with address, subject, and content
- **WHEN** MailHelper.createAndSendMail is invoked
- **THEN** a MIME message is created, formatted, and sent via Transport.send()

#### Scenario: JNDI lookup of mail session

- **GIVEN** MailHelper initializes mail sending
- **WHEN** InitialContext looks up JNDINames.MAIL_SESSION
- **THEN** the container provides the configured mail Session from java:comp/env/mail/MailSession

### Requirement: Mail message formatting and encoding

The system SHALL format email messages as MIME messages with text/html content type and UTF-8 character encoding, including X-Mailer header set to "JavaMailer" and sent-date set to the current system time.

#### Scenario: Email formatted with required headers and encoding

- **GIVEN** mail content provided to createAndSendMail
- **WHEN** the message is formatted
- **THEN** the content type is set to text/html, body is UTF-8 encoded, X-Mailer header is set to "JavaMailer", and sent-date is set to current time

#### Scenario: Email recipient parsing

- **GIVEN** an email address string parameter to createAndSendMail
- **WHEN** recipients are parsed
- **THEN** InternetAddress.parse(emailAddress, false) is invoked with non-strict RFC parsing to allow multiple comma-separated addresses

### Requirement: Email sender address configuration

The system SHALL set the sender address from the mail session configuration default, which the application server supplies via the Mail Session resource.

#### Scenario: Sender address from session default

- **GIVEN** a configured mail session with mail.from property set
- **WHEN** MailHelper creates an email message
- **THEN** msg.setFrom() is called with no arguments, using the session's configured sender

### Requirement: Container-managed transaction semantics

The system SHALL execute email message processing within container-managed transactions with Required attribute, ensuring message receipt and mail send are atomic and triggering message redelivery on exceptions.

#### Scenario: XML parsing failure triggers redelivery

- **GIVEN** MailerMDB receives a message with invalid XML
- **WHEN** Mail.fromXML() throws XMLDocumentException
- **THEN** the exception is re-thrown as EJBException, the container rolls back the transaction, and the message is redelivered

#### Scenario: JMS message exception triggers redelivery

- **GIVEN** MailerMDB receives a message that cannot be cast to TextMessage
- **WHEN** JMSException occurs during message processing
- **THEN** the exception is re-thrown as EJBException, the container rolls back the transaction, and the message is redelivered

### Requirement: Graceful degradation on mail server unavailability

The system SHALL catch MailerAppException when mail server is misconfigured or unavailable and continue processing without rolling back the transaction, allowing JMS message acknowledgment to proceed and preventing order processing impact.

#### Scenario: Mail server unavailable

- **GIVEN** the mail server is not configured or unreachable
- **WHEN** MailHelper.createAndSendMail fails with MailerAppException
- **THEN** MailerMDB.onMessage catches the exception, suppresses it, and completes normally, allowing the message to be acknowledged and processing to continue

### Requirement: Email notification workflow integration

The system SHALL receive email notifications asynchronously as part of order state machine transitions, with transition delegates queuing mail messages to the mail sender queue when order events occur.

#### Scenario: Order approval notification

- **GIVEN** an order state machine enters approval state
- **WHEN** MailOrderApprovalTransitionDelegate.doTransition() executes
- **THEN** mail messages from the transition context are queued to JNDINames.MAIL_SENDER_QUEUE via QueueHelper.sendMessage()
