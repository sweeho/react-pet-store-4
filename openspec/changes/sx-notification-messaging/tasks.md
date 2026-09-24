# Notification Messaging Tasks

## 1. Data model and XML schema

- [ ] 1.1 Define Mail entity with three required string fields: address, subject, content
- [ ] 1.2 Define Mail.dtd DTD schema with structure: Mail(Address, Subject, Content)
- [ ] 1.3 Implement Mail.fromXML() with DTD validation (VALIDATING=true)
- [ ] 1.4 Implement Mail.fromDOM() parser to extract fields from DOM tree
- [ ] 1.5 Define DTD constants: DTD_PUBLIC_ID and DTD_SYSTEM_ID

## 2. Message-driven bean infrastructure

- [ ] 2.1 Implement MailerMDB as MessageDrivenBean and MessageListener
- [ ] 2.2 Configure MailerMDB in ejb-jar.xml with message-driven-destination javax.jms.Queue
- [ ] 2.3 Configure container-managed transaction attribute Required for onMessage method
- [ ] 2.4 Configure resource-ref for mail/MailSession (javax.mail.Session) in ejb-jar.xml
- [ ] 2.5 Map MailerMDB JNDI name to jms/opc/MailQueue in sun-j2ee-ri.xml

## 3. Message reception and parsing

- [ ] 3.1 Implement MailerMDB.onMessage(Message) to receive TextMessages asynchronously
- [ ] 3.2 Cast received message to TextMessage and extract XML string via getText()
- [ ] 3.3 Invoke Mail.fromXML() to parse and validate XML payload
- [ ] 3.4 Handle XMLDocumentException by re-throwing as EJBException for message redelivery
- [ ] 3.5 Handle JMSException by re-throwing as EJBException for message redelivery

## 4. Mail formatting and composition

- [ ] 4.1 Implement MailHelper.createAndSendMail() method signature
- [ ] 4.2 Implement JNDI lookup of javax.mail.Session from java:comp/env/mail/MailSession
- [ ] 4.3 Create MimeMessage from Session and set FROM address via msg.setFrom()
- [ ] 4.4 Parse recipient addresses using InternetAddress.parse(emailAddress, false)
- [ ] 4.5 Set email subject via msg.setSubject()
- [ ] 4.6 Implement ByteArrayDataSource for content encoding to UTF-8
- [ ] 4.7 Set content type to text/html via DataHandler and ByteArrayDataSource
- [ ] 4.8 Set X-Mailer header to "JavaMailer" via msg.setHeader()
- [ ] 4.9 Set sent-date to current time via msg.setSentDate(new Date())

## 5. SMTP transmission

- [ ] 5.1 Implement Transport.send(msg) to transmit formatted email via SMTP
- [ ] 5.2 Wrap all exceptions from mail API as MailerAppException with message "Failure while sending mail"
- [ ] 5.3 Configure JNDI resource binding for javax.mail.Session with container authentication

## 6. Error handling and exception semantics

- [ ] 6.1 Implement MailerAppException wrapping for mail API failures
- [ ] 6.2 Add catch block for MailerAppException in MailerMDB.onMessage() for graceful degradation
- [ ] 6.3 Ensure XMLDocumentException triggers EJBException and message redelivery
- [ ] 6.4 Ensure JMSException triggers EJBException and message redelivery
- [ ] 6.5 Verify container-managed transaction rollback on EJBException triggers message redelivery

## 7. Order workflow integration

- [ ] 7.1 Implement MailOrderApprovalTransitionDelegate implementing TransitionDelegate
- [ ] 7.2 Configure MailOrderApprovalTransitionDelegate.setup() to initialize QueueConnectionFactory and Queue
- [ ] 7.3 Implement MailOrderApprovalTransitionDelegate.doTransition() to queue mail messages
- [ ] 7.4 Use QueueHelper.sendMessage() to send XML mail strings to jms/opc/MailQueue
- [ ] 7.5 Integrate transition delegate into order state machine workflow
- [ ] 7.6 Bind queue connection factory to JNDI name jms/QueueConnectionFactory

## 8. Configuration and deployment

- [ ] 8.1 Configure mail session JNDI resource at application server with smtp server hostname
- [ ] 8.2 Configure mail session property mail.from to customerservice@javapetstoredemo.com
- [ ] 8.3 Configure mail session property mail.host to actual SMTP server hostname
- [ ] 8.4 Create JMS queue destination jms/opc/MailQueue in application server
- [ ] 8.5 Configure queue connection factory jms/QueueConnectionFactory in application server
- [ ] 8.6 Configure message redelivery policy for failed message delivery

## 9. Testing and validation

- [ ] 9.1 Unit test Mail.fromXML() with valid XML documents
- [ ] 9.2 Unit test Mail.fromXML() with invalid XML to verify DTD validation
- [ ] 9.3 Unit test MailHelper.createAndSendMail() message formatting
- [ ] 9.4 Integration test MailerMDB.onMessage() with mocked JMS queue
- [ ] 9.5 Integration test error handling: XMLDocumentException redelivery
- [ ] 9.6 Integration test error handling: JMSException redelivery
- [ ] 9.7 Integration test graceful degradation: MailerAppException handling
- [ ] 9.8 End-to-end test: order state transition queues mail to mail receiver
