## 1. Data Model

- [ ] 1.1 Define the Category entity with id (string, unique), name, and description attributes
- [ ] 1.2 Define the Product entity with id (string, unique), name, and description attributes
- [ ] 1.3 Define the Item entity with 13 attributes: category, productId, productName, itemId (unique), description, imageLocation, attribute1-5, listPrice (double), unitCost (double)
- [ ] 1.4 Define the Page entity as a pagination container with objects (list), start (int), and hasNext (boolean) fields
- [ ] 1.5 Implement Page.EMPTY_PAGE constant as immutable empty page with Collections.EMPTY_LIST, start=0, hasNext=false

## 2. Catalog Service Interface

- [ ] 2.1 Declare CatalogService with getCategory(String, Locale) returning Category or null
- [ ] 2.2 Declare getCategories(int start, int count, Locale) returning Page of categories with pagination
- [ ] 2.3 Declare getProduct(String, Locale) returning Product or null
- [ ] 2.4 Declare getProducts(String categoryId, int start, int count, Locale) returning paginated Product list
- [ ] 2.5 Declare getItem(String, Locale) returning Item or null with all 13 attributes
- [ ] 2.6 Declare getItems(String productId, int start, int count, Locale) returning paginated Item list
- [ ] 2.7 Declare searchItems(String query, int start, int count, Locale) returning paginated search results

## 3. Service Implementation

- [ ] 3.1 Implement CatalogService as a stateless service with dependency injection of DAO layer
- [ ] 3.2 Implement DAO access through data access object abstraction (not direct SQL)
- [ ] 3.3 Implement transaction management for all catalog queries using container-managed transactions
- [ ] 3.4 Implement all methods with Required transaction isolation level

## 4. Data Access Layer (DAO)

- [ ] 4.1 Implement CatalogDAO with JDBC DataSource obtained via JNDI lookup
- [ ] 4.2 Implement connection pooling and resource cleanup (ResultSet, PreparedStatement, Connection)
- [ ] 4.3 Implement scroll-insensitive read-only ResultSet for pagination operations
- [ ] 4.4 Implement locale-aware table routing (product_ja, product_zh for localized queries)
- [ ] 4.5 Implement pagination using ResultSet.absolute(start+1) for cursor positioning

## 5. Pagination Logic

- [ ] 5.1 Implement page boundary validation: return Page.EMPTY_PAGE for invalid start positions (negative or beyond results)
- [ ] 5.2 Implement hasNext flag calculation: hasNext=true if resultSet.next() returns true after reading count items
- [ ] 5.3 Implement pagination for all query methods: getCategories, getProducts, getItems, searchItems
- [ ] 5.4 Implement consistent Page construction across all paginated methods

## 6. Search Implementation

- [ ] 6.1 Implement query tokenization using whitespace delimiter (StringTokenizer semantics)
- [ ] 6.2 Implement empty query check: return Page.EMPTY_PAGE if query tokenizes to zero keywords
- [ ] 6.3 Implement OR semantics for multi-keyword search across name, description, and attribute fields
- [ ] 6.4 Implement wildcard pattern matching (%keyword%) for each search keyword
- [ ] 6.5 Implement paginated search results with consistent pagination logic

## 7. Localization

- [ ] 7.1 Implement locale parameter acceptance on all query methods
- [ ] 7.2 Implement locale-to-table-name mapping: US (default), ja_JP (\_ja suffix), zh_CN (\_zh suffix)
- [ ] 7.3 Implement default locale fallback to en_US when unsupported locale is requested
- [ ] 7.4 Implement locale parameter passing to SQL statement construction

## 8. Error Handling

- [ ] 8.1 Implement null return for single-item queries when item not found (not exception)
- [ ] 8.2 Implement database exception wrapping in CatalogException or similar checked exception
- [ ] 8.3 Implement connection failure handling with appropriate exception propagation
- [ ] 8.4 Implement ResultSet positioning failure handling (return empty page, not exception)

## 9. Authorization & Access Control

- [ ] 9.1 Implement unchecked (public) access control: no authentication required
- [ ] 9.2 Implement no role-based authorization checks on any catalog methods
- [ ] 9.3 Document that all catalog operations are read-only and safe for public access

## 10. UI Screens

- [ ] 10.1 Implement category listing screen displaying all categories in localized language sorted alphabetically
- [ ] 10.2 Implement category screen with navigation to product list per category
- [ ] 10.3 Implement search results screen displaying paginated item results with no-results message handling
- [ ] 10.4 Implement search results screen pagination controls (Previous/Next links)
- [ ] 10.5 Implement item detail screen displaying itemId, productName, description, image, unit cost formatted as currency
- [ ] 10.6 Implement item detail screen "Add to Cart" button linking to cart.do?action=purchase&itemId=<itemId>

## 11. Testing

- [ ] 11.1 Write unit tests for Category, Product, Item, and Page entity classes
- [ ] 11.2 Write integration tests for getCategory and getProduct single-item queries
- [ ] 11.3 Write integration tests for getCategories, getProducts, and getItems paginated queries
- [ ] 11.4 Write integration tests for searchItems keyword search with pagination
- [ ] 11.5 Write integration tests for pagination boundary conditions (start=0, start beyond results, negative start)
- [ ] 11.6 Write integration tests for empty search query handling
- [ ] 11.7 Write integration tests for locale-specific queries across three locales
- [ ] 11.8 Write functional tests for category, search results, and item detail screens
- [ ] 11.9 Write test coverage for null returns (single-item queries not found)
- [ ] 11.10 Write test coverage for hasNext flag accuracy in paginated results

## 12. Documentation

- [ ] 12.1 Document CatalogService public API signatures and transaction attributes
- [ ] 12.2 Document pagination semantics and Page.EMPTY_PAGE behavior
- [ ] 12.3 Document locale support and table routing
- [ ] 12.4 Document error handling and exception contract
- [ ] 12.5 Document authorization policy (unchecked public access)
