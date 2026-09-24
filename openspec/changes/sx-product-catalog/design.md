# Product Catalog Design Notes

## Architecture Overview

The product catalog is implemented as a **stateless EJB service** with **DAO abstraction layer**, backed by **JDBC DataSource** connection pooling. All data operations use **container-managed transactions** with **Required isolation level**.

### Architectural Components

1. **CatalogEJB (Stateless Session Bean)** - Service entry point, delegates to DAO
2. **CatalogDAO (Abstract Base)** - JDBC data access operations
3. **GenericCatalogDAO (Implementation)** - SQL statement construction and ResultSet iteration
4. **CatalogDAOFactory** - Factory pattern for database-specific DAO selection
5. **JNDINames** - Centralized JNDI lookup paths for DataSource and EJB references

### Data Access Pattern

Each operation follows the same pattern:

1. Obtain DataSource via JNDI lookup
2. Build parameterized SQL statement from XML configuration
3. Execute PreparedStatement with explicit parameter binding
4. Iterate ResultSet and construct entity objects
5. Close ResultSet, PreparedStatement, Connection in finally block

### Transaction Model

- **Transaction Type**: Container-Managed
- **Isolation Level**: Required (JTA semantics: if caller has transaction, use it; else create new)
- **Scope**: Entire EJB method execution
- **Rollback Handling**: Exception propagation to container for automatic rollback

### JDBC Configuration

- **ResultSet Type**: TYPE_SCROLL_INSENSITIVE (supports absolute positioning)
- **Concurrency**: CONCUR_READ_ONLY (no updates allowed)
- **Connection Pooling**: Via JNDI DataSource (likely JDBC connection pool managed by app server)
- **Resource Cleanup**: Explicit close() calls in finally blocks, always closes in order: ResultSet → PreparedStatement → Connection

### Pagination Implementation Details

#### Cursor Positioning

- Uses `resultSet.absolute(start + 1)` for 1-based JDBC positioning
- Negative start or out-of-bounds position: `absolute()` returns false, Page.EMPTY_PAGE returned
- Valid position: absolute() returns true, iteration proceeds

#### hasNext Calculation

- After reading `count` items from result set, attempts one more `resultSet.next()`
- If next() succeeds: hasNext = true (additional pages exist)
- If next() fails: hasNext = false (end of results reached)
- hasNext value stored in Page object for client pagination control

#### Empty Page Handling

- Search with empty query: checked and returns Page.EMPTY_PAGE before DB access
- Paginated query with invalid position: Page.EMPTY_PAGE returned instead of throwing exception
- This provides graceful degradation for out-of-bounds pagination

### Localization Strategy

#### Locale-to-Table Mapping

The system uses **table-level routing** for locale support, not query-level filtering:

| Locale | Table Prefix | Example     |
| ------ | ------------ | ----------- |
| en_US  | (default)    | category    |
| ja_JP  | \_ja suffix  | category_ja |
| zh_CN  | \_zh suffix  | category_zh |

#### Implementation

- `DatabaseNames.getTableName(tableName, Locale)` performs mapping
- Locale is always first parameter in parameterized SQL queries
- SQL statement loading defers to configuration file (CatalogDAOSQL.xml)
- Locale parameter used in buildSQLStatement() to construct table name dynamically

### Item Attribute Semantics

The Item entity contains **5 indexed attributes** (attribute1 through attribute5) accessed via `getAttribute(int index)` method with 1-based indexing:

```
getAttribute(1) → attribute1
getAttribute(2) → attribute2
getAttribute(3) → attribute3
getAttribute(4) → attribute4
getAttribute(5) → attribute5
default fallback → attribute1
```

The domain semantics of these attributes are not documented in legacy source (whether they represent size, color, variants, or metadata). This extraction preserves the container structure; semantic interpretation is deferred to implementation planning.

### Search Query Processing

#### Tokenization

- Uses `StringTokenizer` with default whitespace delimiters (space, tab, newline, etc.)
- No other delimiters (comma, semicolon) are recognized
- Empty query or whitespace-only: produces empty keywordSet

#### Keyword-to-SQL Parameter Mapping

- Each keyword generates 3 SQL parameters (wildcard-wrapped versions)
- Total parameters = 1 (locale) + 3 × (number of keywords)
- Each keyword searches 3 fields: likely name, description, and one attribute field
- OR semantics: a match on any keyword includes the item

#### Empty Query Optimization

- Checked BEFORE database access: `if (keywordSet.isEmpty()) return Page.EMPTY_PAGE`
- Prevents unnecessary connection, statement, and query execution

### String Trimming Behavior

The DAO selectively applies `String.trim()` to database result set values:

**Trimmed** (identifier and location fields):

- category
- productId
- itemId
- imageLocation

**Not Trimmed** (user-visible text fields):

- name
- description
- attributes

This preserves leading/trailing whitespace in user-entered text while removing formatting noise from IDs and paths.

### Error Handling Strategy

1. **Not Found**: Returns null for single-item queries (getCategory, getProduct, getItem)
2. **Invalid Pagination**: Returns Page.EMPTY_PAGE instead of throwing exception
3. **Empty Search**: Returns Page.EMPTY_PAGE before DB access
4. **Database Failure**: Wrapped in CatalogDAOSysException (checked exception)
5. **EJB Exception**: CatalogDAOSysException converted to EJBException by service layer

### Legacy Findings & Ambiguities

The following aspects could not be fully determined from the legacy source and require implementation decisions:

1. **SQL Statements**: The SQL configuration file (CatalogDAOSQL.xml) was not fully readable. Exact SQL queries, field ordering, and sorting behavior cannot be verified against actual schema.

2. **Item Construction Mismatch**: GenericCatalogDAO.getItems() passes `productId` where the Item constructor expects `category`. This may indicate a defect or may be intentional field aliasing. Future implementation must verify against actual schema and Item usage.

3. **Attribute Semantics**: The five Item attributes lack documented domain meaning. Implementation should clarify whether these represent product variants, specifications, or generic metadata.

4. **Decimal Precision**: listPrice and unitCost are stored as `double` in the Java model. No rounding rules, tax handling, or currency conversion logic was found. Default rounding or precision requirements should be documented.

## Screen Implementation Notes

### Category Listing Screen

**Legacy Implementation**: Multiple locale-specific JSP files (en_US/category.jsp, ja_JP/category.jsp, zh_CN/category.jsp) dynamically included based on locale.

**Visible Contract** (from spec.md):

- Display all categories for selected locale, sorted alphabetically by name
- Show category id, name, and description
- Provide navigation to product list for selected category

**Legacy Context**:

- Locale selection handled in TemplateServlet wrapper (web.xml init-params list supported locales)
- Category display cached for 5 minutes per legacy JSP directive
- Category list obtained via getCategories() with default pagination (start=0, count=25)
- Category names rendered directly from database; no HTML escaping noted

### Search Results Screen

**Legacy Implementation**: search.jsp with form accepting keywords parameter, displays matching items with pagination.

**Visible Contract** (from spec.md):

- Display items matching search keywords with pagination controls
- Show no-results message when search yields zero items
- Provide Previous/Next pagination links
- Display item name, description, unit cost per row

**Legacy Context**:

- Search form posts to search.jsp with keywords parameter
- searchItems() called with default pagination (start=0, count=2 in tests)
- Item properties rendered: itemId, attribute, productName, description, unitCost
- unitCost formatted via fmt:formatNumber tag (currency type, likely locale-aware)
- Empty search query handled by Java code (StringTokenizer check) before rendering
- No-results message appears at line 79 of search.jsp when result list is empty

### Item Detail Screen

**Legacy Implementation**: item.jsp displays single item details with Add to Cart button.

**Visible Contract** (from spec.md):

- Display item information: itemId, productName, description, image location, unit cost as currency
- Provide "Add to Cart" action linking to cart.do?action=purchase&itemId=<itemId>
- Navigation back to search results or category

**Legacy Context**:

- Item accessed via item.jsp?item_id=<itemId> URL parameter
- Item details obtained via getItem(itemId, locale) returning all 13 attributes
- Image location rendered as img src attribute
- Unit cost formatted as currency via fmt:formatNumber
- Add to Cart button constructs URL: cart.do?action=purchase&itemId=<itemId>
- Cart action processes ADD_ITEM event, adding item to session-based shopping cart

## Implementation Considerations

### Database Schema Expectations

Based on legacy queries, the implementation should expect:

- **category table**: catid (PK), name, description (and locale-specific variants)
- **product table**: productid (PK), name, description, category_fk (and locale-specific variants)
- **item table**: itemid (PK), productid (FK), name, description, imageLocation, attributes (5 columns), listPrice, unitCost, category_fk (and locale-specific variants)

### Performance Notes

1. **Pagination**: ResultSet.absolute() is efficient for DBMS with server-side cursor support; performance degrades if DBMS requires client-side iteration.

2. **Search**: OR semantics across multiple keywords and three fields may produce full table scans without proper indexing. The parameterized pattern `%keyword%` prevents use of index prefixes.

3. **Locale Routing**: Table-level routing avoids query-level filtering but requires separate table maintenance for each locale.

### Security Notes

- All catalog operations are unchecked (no authentication/authorization)
- All queries are read-only (no data modification)
- Parameterized queries protect against SQL injection
- No user input validation beyond empty search query check

### Future Extensibility

The DAO abstraction layer allows:

- Database-specific implementations (Oracle, MySQL, PostgreSQL)
- Caching layer insertion (e.g., ResultSet caching by DAO)
- Search implementation switching (e.g., full-text search engine integration)
- Pagination strategy modification (cursor-based vs. offset-based)

Locale support is table-routed and would require schema changes to add new locales.
