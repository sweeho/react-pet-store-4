# PetStore Legacy Specification - Rebuild Guidance

This document provides guidance for rebuilding the PetStore e-commerce application based on the extracted legacy specifications. The rebuilt system will be implemented using the vortex-boilerplate-ts-reactjs-vite-tailwindcss technology stack (Vite React SPA + Nitro server, SQLite/Drizzle ORM, TailwindCSS).

## Application Architecture Overview

### Technology Stack

- **Frontend**: React SPA built with Vite, client-side routing via react-router
- **Backend**: Nitro (H3) server running on a single Node.js process
- **Database**: SQLite with better-sqlite3 driver and Drizzle ORM
- **Styling**: TailwindCSS (CSS-first, no tailwind.config.ts)
- **Component Library**: shadcn/ui-style primitives (Radix, CVA, cn() utility)
- **Icons**: lucide-react and @heroicons/react
- **Testing**: Vitest (unit/integration) + Playwright (E2E)
- **Auto-imports**: unplugin-auto-import provides React and react-router APIs

### Repository Structure

```
├── src/
│   ├── pages/            # React Router file-based pages
│   ├── components/       # Reusable UI components
│   ├── utils/           # Utility functions
│   ├── App.tsx          # Main app component
│   └── ...
├── routes/              # Nitro/H3 file-based server routes
│   ├── api/             # API endpoints (exported as /api/*)
│   └── ...
├── db/
│   ├── schema.ts        # Drizzle ORM schema (defines tables)
│   └── client.ts        # SQLite client (uses bun:sqlite)
├── drizzle/             # Database migrations (auto-generated)
├── vite.config.ts       # Vite + Nitro + Pages configuration
├── vitest.config.ts     # Vitest unit/integration test config
├── playwright.config.ts # Playwright E2E config
└── ...
```

### Development Workflow

1. **Setup & Installation**

   ```bash
   bun install          # Install dependencies with Bun
   bun run build        # Full build (tsc + vite)
   bun run start        # Dev server on :5000
   ```

2. **Database Development**

   ```bash
   bun run db:generate  # Generate Drizzle migrations from schema changes
   bun run db:studio    # Open Drizzle Studio to inspect/edit data
   ```

3. **Testing**
   ```bash
   bun run test         # Unit/integration tests (Vitest)
   bun run test:e2e     # E2E tests (Playwright on :5178)
   bun run verify       # Full gate: lint + typecheck + unit tests
   bun run verify:full  # verify + E2E tier (preferred before finishing)
   ```

## Capability Rebuild Order

The 10 capabilities must be built in dependency order to ensure each feature's dependencies are available:

1. **Product Catalog** (order: 1, no dependencies)
   - Provides product browsing and search API
   - No database writes; read-only catalog views
   - Multi-locale support (en_US, ja_JP, zh_CN)
   - Pagination with configurable page size

2. **Shopping Cart** (order: 2, depends on Product Catalog)
   - Session-scoped cart for accumulating items
   - Add, remove, update operations
   - Subtotal calculation in user's preferred currency
   - Built on product catalog item references

3. **Checkout & Payment** (order: 3, depends on Shopping Cart + Customer Account)
   - Order entry form collecting billing/shipping addresses
   - Credit card information collection
   - Empty cart validation before order creation
   - Integration with shopping cart and customer profiles

4. **Order Management** (order: 4, depends on Checkout & Payment)
   - Purchase order persistence with unique sequential IDs
   - Line item tracking with partial fulfillment support
   - Order status tracking (PENDING → APPROVED → COMPLETED or DENIED → SHIPPED)
   - Locale preservation for order display

5. **Customer Account** (order: 5, no dependencies)
   - Form-based sign-in/sign-up authentication
   - Account creation with duplicate username prevention
   - Profile preferences (language, favorite category, display options)
   - 15-minute session timeout

6. **Notification & Messaging** (order: 6, depends on Order Management)
   - Asynchronous email notification queueing
   - Order XML serialization for message bus
   - Message-driven bean pattern (MailerMDB analog in modern stack)
   - SMTP integration for actual email transmission

7. **Order Approval** (order: 7, depends on Order Management)
   - Automatic approval for low-value orders (locale-specific thresholds)
   - Manual approval workflow for high-value orders
   - Administrator XML-based approval interface
   - Integration with order status transitions

8. **Inventory & Fulfillment** (order: 8, depends on Order Approval)
   - Supplier-facing inventory management
   - Item quantity tracking per supplier
   - Order fulfillment with partial shipment support
   - Automatic retry of pending orders when new inventory arrives
   - Invoice generation in XML format

9. **Admin Operations** (order: 9, no dependencies)
   - Form-based admin authentication (administrator role)
   - 54-minute session timeout
   - Order retrieval and status updates via XML
   - Sales analytics (revenue and order quantity by category/date range)
   - Rich client JNLP generation (adapt for modern browser-based UI)

10. **Supplier Integration** (order: 10, depends on Inventory & Fulfillment)
    - Supplier form-based login
    - Inventory view and update operations
    - Order fulfillment tracking
    - Invoice receipt and validation
    - 54-minute session timeout

## Key Implementation Patterns

### 1. File-Based Routing (Both SPA and Server)

**Frontend Pages** (React Router):

```typescript
// src/pages/products/index.tsx → /products
// src/pages/products/[id].tsx → /products/:id
// src/pages/cart.tsx → /cart
export default function CartPage() { ... }
```

**Server Routes** (Nitro/H3):

```typescript
// routes/api/catalog/categories.ts → GET /api/catalog/categories
export default defineEventHandler(async (event) => {
  return { ... }
})
```

### 2. Database Schema (Drizzle ORM)

All table definitions live in `db/schema.ts` using Drizzle's TypeScript-first API:

```typescript
import { sqliteTable, text, integer, real, timestamp } from 'drizzle-orm/sqlite-core'

export const category = sqliteTable('category', {
  categoryId: text('category_id').primaryKey(),
  name: text('name').notNull(),
})

export const item = sqliteTable('item', {
  itemId: text('item_id').primaryKey(),
  productId: text('product_id').notNull().references(() => product.productId),
  unitCost: real('unit_cost').notNull(),
  // ...
})
```

Migrations in `drizzle/` are auto-generated when you run `bun run db:generate` after schema changes.

### 3. Session Management

- **Session Scope**: Express/Nitro middleware manages session lifecycle
- **Timeouts**: Customer accounts (15 min), Admin/Supplier (54 min) configured in middleware
- **Session Data**: Persist user ID, locale preference, cart reference in session state
- **Cookie Management**: Remember-username cookie (bp_signon) is optional browser-side storage

### 4. Locale/Internationalization

- **Locale List**: en_US, ja_JP, zh_CN (no others; enforce in schema)
- **User Preference**: Stored in customer profile; applied to cart and order
- **Catalog Localization**: Categories and products have localized_name/description per locale
- **Currency Formatting**: Display prices in user's locale (implement via Intl.NumberFormat)

### 5. Multi-Supplier Inventory

- **Inventory Table**: item_id + supplier_id (composite unique constraint)
- **Fulfillment Logic**: For each line item in an order, query inventory for a supplier with available quantity
- **Partial Fulfillment**: If quantity < requested, fulfill what's available, mark rest as PENDING
- **Retry on Restock**: When inventory quantity increases, check PENDING order line items and retry fulfillment

### 6. Order Approval Threshold Logic

Per the specification:

- **Thresholds**: e.g., USD 500, JPY ¥50,000 (locale-specific)
- **Auto-Approval**: Total order price < threshold → status = APPROVED immediately
- **Manual Approval**: Total price ≥ threshold → status = PENDING, await admin review
- **Admin Decision**: Admin approves/denies via order approval workflow
- **Implementation**: Conditional logic in order creation endpoint (routes/api/order/create.ts)

### 7. Authentication & Authorization

**Form-Based Login** (Both Customer and Admin/Supplier):

- Customer: POST to `/api/auth/signon` with j_username, j_password
- Admin: POST to `/api/admin/login` with same fields
- Supplier: POST to `/api/supplier/login` with same fields
- Server validates credentials, creates session, returns user/role info

**Role-Based Access**:

- Customer routes: No explicit role check (authenticated customer)
- Admin routes: Check session role = 'administrator'
- Supplier routes: Check session role = 'supplier'
- Unauth → 401 Unauthorized; wrong role → 403 Forbidden

### 8. Error Handling & Validation

**Input Validation**:

- Address fields (ZIP, state, country): Basic format validation on server
- Credit card: Basic Luhn check; actual authorization is out-of-scope
- Cart operations: Ensure item exists before add; check quantity > 0 before update

**Business Rule Violations**:

- Empty cart at order creation → throw `ShoppingCartEmptyOrderException`
- Duplicate username at signup → throw `DuplicateAccountException`
- Inventory exhaustion at fulfillment → partial shipment (don't reject)
- Admin approval without admin role → 403 Forbidden

**Exception Mapping** (legacy pattern):

- Translate business exceptions to HTTP status codes
- Include user-friendly error messages in response

## Specific Rebuild Guidance by Capability

### Product Catalog

- **Read-Only API**: GET /api/catalog/categories, /api/catalog/products, /api/catalog/search
- **No Authentication**: Public access
- **Multi-Locale**: Query parameter locale={en_US,ja_JP,zh_CN}
- **Pagination**: Query parameters start (default 0), count (default 2), include hasNext in response
- **Frontend**: Category browse page, product search page with pagination controls
- **Testing**: Unit tests for pagination logic, E2E for category/search flow

### Shopping Cart

- **Session-Based**: Cart persists for a single session; no persistent cart across logins
- **API Endpoints**: POST /api/cart/add, /api/cart/remove, /api/cart/update, /api/cart/empty, GET /api/cart
- **Calculation**: Subtotal = Σ(quantity × unitCost) for all items; currency format per locale
- **Frontend**: Cart page with item list, quantity inputs, remove buttons, subtotal display
- **Testing**: Unit tests for subtotal calculation; E2E for add/remove/update flow

### Checkout & Payment

- **Form**: Single multipart form collecting billing address, shipping address, credit card
- **Validation**: All fields required; email format; ZIP/state/country basic format
- **Order Creation**: POST /api/order/create with OrderRequest payload (billing, shipping, card)
- **Response**: Returns order ID and confirmation details
- **Frontend**: Multi-step form or single form with sections
- **Post-Order**: Clear cart and redirect to order confirmation screen
- **Testing**: E2E for complete checkout flow, unit tests for validation

### Order Management

- **Storage**: Purchase order and line items persisted in database
- **ID Generation**: Unique sequential IDs via UniqueIdGenerator with seed "1001"
- **Query**: GET /api/order/{orderId} returns full order with line items
- **Status Tracking**: Initially PENDING or APPROVED (per order-approval logic)
- **Frontend**: Order confirmation page, order history/detail pages
- **Testing**: Unit tests for ID generation and total calculation, E2E for order creation/retrieval

### Customer Account

- **Sign-On**: POST /api/auth/signon with j_username, j_password → creates session
- **Sign-Up**: POST /api/auth/createuser with j_username, j_password, j_password_2 → new account
- **Profile**: GET/PUT /api/customer/profile for preferred language, favorite category, etc.
- **Session Timeout**: Middleware enforces 15-minute timeout
- **Remember Me**: Optional bp_signon cookie for username pre-fill
- **Frontend**: Sign-on page with dual sign-in/sign-up tabs, profile edit page
- **Testing**: Unit tests for password validation, E2E for sign-in/sign-up/logout flow

### Notification & Messaging

- **Trigger**: After successful order creation, enqueue notification via message bus
- **Payload**: Purchase order serialized to XML with order ID, customer email, line items
- **Processing**: Message-driven bean (or modern async queue: BullMQ, RabbitMQ, etc.)
- **Delivery**: Validate XML, format as MIME message, send via SMTP
- **Frontend**: No UI for this capability (backend-only); confirm email in order confirmation page
- **Testing**: Unit tests for XML serialization, integration tests with mock SMTP

### Order Approval

- **Auto-Approval**: If order total < threshold (locale-specific), set status = APPROVED
- **Manual Approval**: If order total ≥ threshold, set status = PENDING, halt fulfillment
- **Admin Workflow**: Admin views pending orders via GET /api/admin/orders?status=PENDING
- **Admin Decision**: POST /api/admin/orders/approve with orderId and new status (APPROVED or DENIED)
- **Frontend**: Admin-only order approval page with filter by status, action buttons
- **Testing**: Unit tests for threshold logic, E2E for admin approval flow

### Inventory & Fulfillment

- **Supplier Login**: POST /api/supplier/login with j_username, j_password
- **View Inventory**: GET /api/inventory/items returns current quantities per item
- **Update Inventory**: POST /api/inventory/update with map of itemId → new quantity (atomic)
- **Fulfillment**: When order approved, query inventory and fulfill line items; partial support
- **Pending Retry**: Message-driven bean on inventory update checks PENDING orders and retries
- **Invoice**: Generate XML invoice for fulfilled shipments, transmit to Order Processing Center
- **Frontend**: Supplier-only pages for inventory view, fulfillment tracking
- **Testing**: Integration tests for fulfillment logic, E2E for supplier inventory updates

### Admin Operations

- **Admin Login**: POST /api/admin/login with j_username, j_password (role = administrator)
- **Session Timeout**: 54 minutes (not 15 like customer)
- **Order Retrieval**: GET /api/admin/orders?status=PENDING (or other statuses)
- **Status Update**: POST /api/admin/orders/approve with orderId and new status
- **Analytics Revenue**: GET /api/admin/analytics/revenue?startDate=&endDate=&category= (optional)
- **Analytics Quantity**: GET /api/admin/analytics/orders?startDate=&endDate=&category= (optional)
- **Frontend**: Admin-only pages for login, order management, sales analytics dashboards
- **Rich Client Note**: Original app used Java Web Start JNLP; modern rebuild uses browser UI
- **Testing**: Integration tests for analytics aggregation, E2E for admin workflows

### Supplier Integration

- **Login**: Same form-based pattern as admin
- **Session Timeout**: 54 minutes
- **Inventory Ops**: View and update (covered in Inventory & Fulfillment)
- **Order Tracking**: Supplier can query orders assigned to them and fulfillment status
- **Frontend**: Supplier-only portal with inventory and order management
- **Testing**: E2E for supplier login and inventory update flow

## Deployment & Operations

### Development

```bash
bun install
bun run start          # :5000 (dev mode; reload on change)
bun run test:e2e       # :5178 (Playwright test server)
```

### Production

```bash
bun run build          # Outputs .output/server/index.mjs
# Deploy .output/server with .sqlite.db in same directory
# Set NODE_ENV=production, run with Node or Bun
```

### Database

- **Local Dev**: `sqlite.db` in working directory (created automatically)
- **Test Mode**: In-memory DB when VITEST=true (set by test runner)
- **Migrations**: Auto-generated in drizzle/ directory; apply on deploy via drizzle-kit push

### Monitoring & Logging

- Implement request/response logging middleware in Nitro
- Log all authentication attempts, order operations, and admin actions
- Track fulfillment state transitions for debugging
- Monitor session timeout and cleanup

## Known Constraints & Gotchas

1. **No `tailwind.config.ts`**: Tailwind is CSS-first; all customization via CSS variables
2. **`auto-imports.d.ts` Missing**: Run `bun run prebuild` or `bun run precheck` to generate
3. **Composite `tsconfig.node.json`**: Cannot set `noEmit`; has separate `outDir`
4. **Vitest Split Projects**: Routes tests run in server environment; others in jsdom
5. **`bun:sqlite` Builtin**: Must run under Bun; test runner uses `bun --bun vitest`
6. **Session State**: Middleware must attach session to request object before route handlers
7. **Multi-Locale Data**: Ensure locale tables are seeded before app start; validate locale codes
8. **Partial Fulfillment**: Complex state machine; unit test thoroughly before E2E
9. **Email Delivery**: Mock SMTP in test; real delivery in staging/prod requires MTA config
10. **Admin/Supplier Timeout (54 min vs 15 min customer)**: Middleware must differentiate by user role

## Testing Strategy

### Unit Tests (`src/**/*.test.ts`, `src/**/*.test.tsx`)

- Locale/currency formatting
- Pagination logic (hasNext, boundaries)
- Order total calculation
- Approval threshold evaluation
- Inventory fulfillment algorithm

### Integration Tests (`routes/**/*.test.ts`)

- API endpoint contracts
- Database state transitions
- Session management
- Auth/authz enforcement

### E2E Tests (`e2e/**/*.spec.ts`)

- Customer browsing → checkout → order flow
- Admin approval workflow
- Supplier inventory update & fulfillment retry
- Multi-locale product display
- Session timeouts

### Smoke Test (`e2e/smoke.spec.ts`)

- App loads on startup
- Home page renders
- Catalog accessible without auth

## Conclusion

This rebuild honors the legacy application's business logic while modernizing the technology stack. Key principle: **the delta spec wins** — where this extraction disagrees with a capability specification, implement the spec, not the legacy evidence.

Follow the capability rebuild order, ensure dependencies are satisfied, and validate each capability via unit tests before moving to the next. Integration across capabilities is tested in E2E; leverage Playwright for cross-capability workflows.
