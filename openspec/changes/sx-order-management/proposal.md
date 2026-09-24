# Order Management Specification

## Overview

This specification defines the core order management capabilities of the e-commerce system, extracted from the legacy J2EE application (Petstore 1.3.2). The order management capability encompasses:

- Unique order identifier generation
- Purchase order creation and persistence
- Order information collection (shipping, billing, credit card)
- Line item tracking with partial shipment fulfillment
- Order state queries and retrieval

## Problem Statement

The legacy application implements order management through a complex J2EE/EJB infrastructure with container-managed persistence, declarative transactions, and entity relationships. This specification captures the functional requirements and business rules to enable a modern rebuild without the J2EE framework constraints.

## Scope

This change specifies:

1. **Core Data Model**: PurchaseOrder, LineItem, and supporting entities
2. **Order Lifecycle**: Creation, fulfillment tracking, and querying
3. **ID Generation**: Unique, sequentially-numbered order identifiers
4. **User-Facing Screens**: Order information entry form
5. **Business Rules**: Fulfillment logic, date/timestamp handling, partial shipments

## Rationale

Order management is a foundational capability. The extraction focuses on:

- **Clarity**: Separating business rules from J2EE infrastructure
- **Completeness**: Capturing all validation rules, entity relationships, and workflows
- **Traceability**: Every requirement is tied to legacy source code
- **Auditability**: Recording the basis for each design decision

## Technical Approach

The specification distinguishes between:

- **Requirements** (`spec.md`): Behavioral contracts in GIVEN/WHEN/THEN form
- **Design** (`design.md`): Architecture notes, legacy implementation details, migration guidance
- **Tasks** (`tasks.md`): Grouped implementation work units

The rebuild will target a modern TypeScript/React stack (Vite + Nitro) with SQLite persistence via Drizzle ORM, removing all EJB and declarative XML configuration while preserving the functional behavior.

## Key Decisions

- **Date Representation**: Orders store date as epoch milliseconds (Java `Date.getTime()`) for timezone-safe querying
- **Fulfillment Model**: Line items track partial shipment; order is complete when all items are fully shipped
- **Entity Relationships**: One-to-many (Order→LineItem), one-to-one (Order→ContactInfo, Order→CreditCard) with cascade-delete semantics
- **ID Generation**: Sequential numbering via Counter entity, not UUID-based
- **Transaction Semantics**: All persistence operations require ACID isolation; original used EJB CMT with Required isolation

## Success Criteria

1. All acceptance criteria in `spec.md` are met
2. All scenarios in `spec.md` pass validation testing
3. Order information entry screen displays and validates per requirements
4. Order creation is atomic; all related entities (contacts, card, lines) persist or fail together
5. Date queries work correctly across timezones (epoch-based queries)
