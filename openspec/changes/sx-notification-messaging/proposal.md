# Notification Messaging Capability Proposal

## Executive Summary

The notification-messaging capability provides an asynchronous email notification service that allows order processing workflows to send customer notifications without blocking transaction completion. Email messages are queued as XML documents, parsed and validated, and transmitted via SMTP in a non-blocking message-driven architecture.

## Problem Statement

The order processing system requires the ability to send email notifications to customers for significant order events (approval, invoice generation, completion). Synchronous email transmission would introduce external I/O latency into the order processing transaction, risking timeout failures and poor user experience. A decoupled, asynchronous notification system allows order processing to complete quickly while ensuring customers receive timely email notifications.

## Solution Overview

The notification-messaging system decouples email sending from order processing by:

1. **Queuing notifications**: Order state transition delegates serialize mail notifications as XML documents and queue them to a JMS queue
2. **Asynchronous processing**: A message-driven bean listens on the queue and processes messages without blocking the originating transaction
3. **XML validation**: Incoming messages are validated against a DTD schema to ensure well-formed content before processing
4. **SMTP transmission**: Validated messages are formatted as MIME messages and transmitted via the JavaMail API and SMTP

## Architecture

### Components

- **MailerMDB**: Message-driven bean that receives mail notifications from the JMS queue
- **Mail**: Entity class representing an email notification with three required fields: address, subject, and content
- **MailHelper**: Utility class that formats emails as MIME messages and sends via SMTP
- **Transition Delegates**: Order workflow components that queue notifications as part of state transitions
- **JMS Queue**: Messaging infrastructure for asynchronous notification delivery
- **JavaMail/SMTP**: External mail transmission service

### Key Design Decisions

1. **JMS Queue-Based Delivery**: Uses enterprise messaging for reliable, asynchronous notification processing with built-in message redelivery on failures
2. **XML Message Format**: Notifications are serialized as XML documents with DTD validation for structural integrity
3. **Container-Managed Transactions**: Uses J2EE container transaction management with Required attribute for atomic message receipt and mail sending
4. **Graceful Degradation on Mail Server Failure**: MailerAppException is silently caught to degrade gracefully when mail server is unavailable, preventing order processing impact
5. **Text/HTML Format**: All emails are sent as MIME messages with text/html content type to support rich formatting
6. **UTF-8 Encoding**: Content is encoded as UTF-8 to support international characters

## Dependencies

### External Services

- **SMTP Server**: External mail server for message transmission (configured via mail session properties)

### J2EE Framework Services

- **JMS Queue**: Message queue service for asynchronous message delivery
- **JavaMail**: Java API for message formatting and SMTP transmission
- **JNDI**: Service locator for obtaining mail session and queue connection factory resources

### Application Integration

- **Order Processing Center (OPC)**: Calls notification system via transition delegates when order state changes occur
- **Process Manager**: Provides TransitionDelegate framework that notification system integrates with

## Constraints and Assumptions

### Constraints

- Mail server must be reachable from the application server
- JNDI resource configuration must be in place at application server startup
- Mail server unavailability is considered non-fatal (messages are silently dropped)
- Content type is fixed to text/html (no support for text/plain or other formats)

### Assumptions

- Mail server is available during normal operation (failures are degraded-service edge case)
- Sender address is pre-configured at application server level (not per-message)
- XML message structure is validated and enforced at queue time by transition delegates
- Order workflows tolerate lost notifications (mail server failures do not cause order processing rollback)

## Success Criteria

1. Email notifications are sent asynchronously without blocking order processing
2. Invalid XML messages trigger redelivery via container transaction semantics
3. Mail server unavailability degrades gracefully without impacting order processing
4. Messages are formatted as MIME text/html with UTF-8 encoding
5. All notifications include required headers (From, To, Subject, Date, X-Mailer)
6. Recipient addresses support multiple comma-separated addresses
7. System integrates with OPC transition workflow for automatic notification on state changes

## Out of Scope

- User configuration of notification rules or templates
- Localization or internationalization of notification content
- Notification persistence or audit logging
- Dead-letter queue handling or explicit retry policies
- Configuration of mail server parameters per-message
- Support for different content types (plain text, multipart MIME) or attachments
- Message signing or encryption
- Bounce handling or email address validation

## Known Issues and Gaps

1. **Silent Failures**: Mail server failures result in silently dropped messages with no logging or retry mechanism
2. **Placeholder Configuration**: Reference implementation uses placeholder values that require production override
3. **Unvalidated Content**: Mail entity does not validate content for non-null or non-empty fields
4. **Legacy Parameter**: Locale parameter is accepted but never used (unclear if future localization is intended)
5. **Exception Suppression**: ByteArrayDataSource silently catches UTF-8 encoding exception with no recovery

## Implementation Phases

### Phase 1: Core Infrastructure (Tasks 1-3)

- Define Mail data model and XML schema
- Implement MailerMDB message-driven bean
- Implement message reception and parsing

### Phase 2: Mail Transmission (Tasks 4-5)

- Implement MailHelper mail formatting
- Implement SMTP transmission via Transport.send()
- Configure JNDI mail session resource

### Phase 3: Error Handling and Integration (Tasks 6-7)

- Implement container transaction semantics for message redelivery
- Implement graceful degradation on mail server failure
- Integrate with OPC transition workflow

### Phase 4: Deployment and Testing (Tasks 8-9)

- Configure application server resources (queue, connection factory, mail session)
- Implement comprehensive unit and integration tests
- Validate end-to-end notification flow
