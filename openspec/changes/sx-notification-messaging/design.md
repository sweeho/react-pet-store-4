# Notification Messaging Design

## Overview

The notification-messaging capability implements an asynchronous email notification system that decouples email sending from synchronous transaction boundaries. Messages are queued by order processing workflows and processed independently by a message-driven bean that handles SMTP transmission.

## Architecture

### Message Flow

1. **Enqueue**: Order state transitions (via `MailOrderApprovalTransitionDelegate` and similar delegates) queue XML-serialized mail messages to `jms/opc/MailQueue`
2. **Receive**: `MailerMDB` (message-driven bean) listens on the queue and receives `TextMessage` objects
3. **Parse**: XML payload is parsed via `Mail.fromXML()` with DTD validation
4. **Format**: `MailHelper.createAndSendMail()` formats the message as MIME with text/html content type and UTF-8 encoding
5. **Send**: `javax.mail.Transport.send()` transmits the message via SMTP

### Core Components

#### MailerMDB

- Message-driven bean implementing `MessageDrivenBean` and `MessageListener` interfaces
- Entry point: `onMessage(Message recvMsg)` for asynchronous processing
- Container-managed transactions with `Required` attribute for atomicity
- Configured via `ejb-jar.xml` to listen on `javax.jms.Queue`
- Delegates parsing to `Mail.fromXML()` and sending to `MailHelper.createAndSendMail()`
- Error handling:
  - `XMLDocumentException` and `JMSException` are re-thrown as `EJBException` to trigger message redelivery
  - `MailerAppException` is silently caught to degrade gracefully when mail server is unavailable

#### Mail Entity

- Three required fields: `address` (recipient), `subject` (email subject), `content` (email body)
- XML serialization/deserialization via `fromXML()` and `fromDOM()` methods
- DTD validation enforced via `Mail.dtd` schema with elements: `Mail(Address, Subject, Content)`
- Constants: `DTD_PUBLIC_ID`, `DTD_SYSTEM_ID`, `VALIDATING=true`

#### MailHelper

- Utility class for mail formatting and transmission
- `createAndSendMail(String emailAddress, String subject, String mailContent, Locale locale)` method performs:
  - JNDI lookup of `javax.mail.Session` at `java:comp/env/mail/MailSession`
  - `MimeMessage` creation and configuration
  - Recipient parsing via `InternetAddress.parse(emailAddress, false)` with non-strict RFC mode
  - Content encoding to UTF-8 via `ByteArrayDataSource`
  - Message headers: `X-Mailer: JavaMailer`, sent-date to current time
  - Sender via `msg.setFrom()` using session default from configuration
  - Transmission via `javax.mail.Transport.send()`
- Exception handling: wraps all mail API exceptions as `MailerAppException`

#### ByteArrayDataSource

- MIME data source wrapper for message content
- Encodes string data to UTF-8 bytes in constructor
- Sets content type for MIME message formatting

### Integration Points

#### Order Processing Center (OPC)

- `MailOrderApprovalTransitionDelegate` and similar transition delegates queue mail messages as part of order state transitions
- Delegates receive `TransitionInfo` containing XML mail message batch
- Use `QueueHelper` to send messages to `jms/opc/MailQueue` via JNDI lookup of `javax.jms.QueueConnectionFactory`

#### J2EE Container

- Container-managed transactions for `MailerMDB.onMessage()` with `Required` attribute
- Message redelivery on `EJBException` (parsing, JMS errors)
- Silent acknowledgment on `MailerAppException` (mail server unavailability) without rollback
- JNDI resource management for mail session and queue connection factory

#### SMTP Server

- External SMTP server configured via mail session properties in application server
- Default sender address: `customerservice@javapetstoredemo.com` (configured via `mail-from` in server config)
- Mail server hostname configured via `mail-host` property (placeholder: `mymailserver`)

## Data Model

### Mail DTD Schema

```
<!ELEMENT Mail (Address, Subject, Content)>
<!ELEMENT Address (#PCDATA)>
<!ELEMENT Subject (#PCDATA)>
<!ELEMENT Content (#PCDATA)>
```

### Mail Object

- `address`: String (required) - recipient email address, parsed via `InternetAddress.parse()` supporting multiple comma-separated addresses
- `subject`: String (required) - email subject line
- `content`: String (required) - email body, formatted as HTML text

## Configuration Requirements

### JNDI Resources

- `java:comp/env/mail/MailSession`: JavaMail Session resource with container authentication
- `jms/opc/MailQueue`: JMS Queue destination for mail message queue
- `jms/QueueConnectionFactory`: JMS queue connection factory for message sending

### Mail Session Properties

- `mail.from`: Default sender address (default: `customerservice@javapetstoredemo.com`)
- `mail.host`: SMTP server hostname (required for actual mail transmission)
- Additional standard JavaMail properties as needed by SMTP provider

## Error Handling and Recovery

### Expected Failures

- **XML Parsing**: Invalid XML triggers `XMLDocumentException`, rethrown as `EJBException`, message is redelivered by container
- **JMS Errors**: Message casting or JMS API errors trigger `JMSException`, rethrown as `EJBException`, message is redelivered
- **Mail Server Unavailable**: `MailerAppException` is caught silently; message is acknowledged without transmission or retry

### Edge Cases

- Empty or null recipient address: parsed by `InternetAddress.parse()`, behavior undefined
- Empty subject or content: accepted by Mail entity, sent as-is
- Locale parameter passed to `sendMail()` but not used in mail formatting (legacy parameter)
- `ByteArrayDataSource` silently catches `UnsupportedEncodingException` for UTF-8, leaving data uninitialized if exception occurs (should never happen)

## User Interface

No screen records were extracted for this capability; its user interface is unspecified. This is a backend/API capability with no direct user-facing screens. Email notifications are received by external recipients via their mail clients.

## Deployment Considerations

- Mail session must be configured at application server startup with valid SMTP server and sender address
- Queue destination must be bound to the JNDI name `jms/opc/MailQueue`
- Queue connection factory must be bound to JNDI name `jms/QueueConnectionFactory`
- Mail server must be reachable from application server; unavailability degrades gracefully without impacting order processing
- Message redelivery behavior is controlled by container and queue configuration (retry count, dead-letter queue handling)

## Known Ambiguities and Risks

1. **Silent Mail Failures**: MailerAppException is suppressed without logging or retry mechanism. If mail server is down, notifications are permanently lost.
2. **Placeholder Configuration**: Sun reference implementation uses placeholder values (`mymailserver`, `yourname`) that require production override.
3. **Empty Fields**: Mail entity does not validate non-null content; empty or null values are parsed but behavior is undefined.
4. **Locale Unused**: Locale parameter is passed but never used; unclear if future localization is intended.
5. **UTF-8 Exception Handling**: ByteArrayDataSource silently catches UTF-8 encoding exception in a catch block that leaves data uninitialized.
