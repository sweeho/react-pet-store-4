## ADDED Requirements

### Requirement: Catalog category retrieval

The system SHALL retrieve a single Category by categoryID and Locale, returning the category with id, name, and description, or null if not found. The operation SHALL execute within a Required transaction context.

#### Scenario: Category found

- **GIVEN** a category with ID "CATS" and locale en_US
- **WHEN** getCategory("CATS", en_US) is called
- **THEN** a Category object is returned with id="CATS", name populated from database, description populated from database

#### Scenario: Category not found

- **GIVEN** a category ID "NONEXISTENT" that does not exist
- **WHEN** getCategory("NONEXISTENT", en_US) is called
- **THEN** null is returned

### Requirement: Paginated categories list

The system SHALL retrieve a paginated list of all Categories for a given Locale, with pagination starting at a specified index and returning up to a specified count. Each page SHALL indicate whether additional pages are available. The operation SHALL execute within a Required transaction context.

#### Scenario: Categories page within range

- **GIVEN** a locale with 60 categories available
- **WHEN** getCategories(0, 25, en_US) is called
- **WHEN** pagination start index is valid (>= 0 and positioned within result set)
- **THEN** a Page object is returned with 25 Category objects, start=0, hasNext=true

#### Scenario: Categories page beyond the last

- **GIVEN** a locale with 60 categories available
- **WHEN** getCategories(100, 25, en_US) is called
- **THEN** Page.EMPTY_PAGE is returned with empty list, start=0, hasNext=false

#### Scenario: Invalid pagination position

- **GIVEN** a locale with 60 categories
- **WHEN** getCategories(-1, 25, en_US) is called with negative start index
- **THEN** Page.EMPTY_PAGE is returned

### Requirement: Product retrieval by ID

The system SHALL retrieve a single Product by productID and Locale, returning the product with id, name, and description, or null if not found. The operation SHALL execute within a Required transaction context.

#### Scenario: Product found

- **GIVEN** a product with ID "PROD1" in locale en_US
- **WHEN** getProduct("PROD1", en_US) is called
- **THEN** a Product object is returned with id="PROD1", name and description populated from database

#### Scenario: Product not found

- **GIVEN** a product ID "NONEXISTENT" that does not exist
- **WHEN** getProduct("NONEXISTENT", en_US) is called
- **THEN** null is returned

### Requirement: Paginated products by category

The system SHALL retrieve a paginated list of Products within a specified Category for a given Locale, with pagination starting at a specified index and returning up to a specified count. Each page SHALL indicate whether additional pages are available. The operation SHALL execute within a Required transaction context.

#### Scenario: Products page retrieved

- **GIVEN** category "CATS" with 30 products in locale en_US
- **WHEN** getProducts("CATS", 0, 10, en_US) is called
- **THEN** a Page object is returned with 10 Product objects, start=0, hasNext=true

#### Scenario: Products page beyond bounds

- **GIVEN** category "CATS" with 30 products
- **WHEN** getProducts("CATS", 50, 10, en_US) is called
- **THEN** Page.EMPTY_PAGE is returned

### Requirement: Item retrieval by ID

The system SHALL retrieve a single Item by itemID and Locale, returning an Item with all 13 attributes (category, productId, productName, itemId, description, imageLocation, five attributes, listPrice, unitCost), or null if not found. The operation SHALL execute within a Required transaction context.

#### Scenario: Item found

- **GIVEN** an item with ID "ITEM1" in locale en_US
- **WHEN** getItem("ITEM1", en_US) is called
- **THEN** an Item object is returned with all 13 attributes populated from database

#### Scenario: Item not found

- **GIVEN** an item ID "NONEXISTENT"
- **WHEN** getItem("NONEXISTENT", en_US) is called
- **THEN** null is returned

### Requirement: Paginated items by product

The system SHALL retrieve a paginated list of Items for a specific Product, using pagination parameters (start position and count). The result SHALL include a Page object indicating whether a next page is available. Each Item SHALL contain all 13 attributes. The operation SHALL execute within a Required transaction context.

#### Scenario: Items page retrieved

- **GIVEN** product "PROD1" with 20 items in locale en_US
- **WHEN** getItems("PROD1", 0, 10, en_US) is called
- **THEN** a Page object is returned with 10 Item objects, start=0, hasNext=true, each with all 13 attributes

#### Scenario: Invalid pagination position

- **GIVEN** product "PROD1" with 20 items
- **WHEN** getItems("PROD1", -1, 10, en_US) is called
- **THEN** Page.EMPTY_PAGE is returned

### Requirement: Item keyword search

The system SHALL search Items by a search query text tokenized by whitespace into individual keywords, matching any of the keywords across item names, descriptions, and attributes. Results SHALL be paginated using start position and count parameters. The operation SHALL execute within a Required transaction context.

#### Scenario: Search with matching results

- **GIVEN** a search query "blue widget" that matches 50 items
- **WHEN** searchItems("blue widget", 0, 10, en_US) is called
- **THEN** a Page object is returned with 10 matching Item objects, start=0, hasNext=true

#### Scenario: Search with empty query

- **GIVEN** a search query that is empty or contains only whitespace
- **WHEN** searchItems(" ", 0, 10, en_US) is called
- **THEN** Page.EMPTY_PAGE is returned without executing database query

#### Scenario: Search with no matches

- **GIVEN** a search query "xyznonexistent" that matches no items
- **WHEN** searchItems("xyznonexistent", 0, 10, en_US) is called
- **THEN** a Page object is returned with empty list, start=0, hasNext=false

### Requirement: Locale-aware data retrieval

The system SHALL support locale-aware product data retrieval with support for three locales: US (en_US, default), Japan (ja_JP), and China (zh_CN). Locale-specific database tables SHALL be used: product_ja, product_zh for Japan and China respectively, with default US tables for en_US.

#### Scenario: US locale retrieves default table

- **GIVEN** locale en_US is requested
- **WHEN** getCategory("CATS", en_US) is called
- **THEN** data is retrieved from default category table

#### Scenario: Japan locale retrieves localized table

- **GIVEN** locale ja_JP is requested
- **WHEN** getCategory("CATS", ja_JP) is called
- **THEN** data is retrieved from category_ja table

#### Scenario: China locale retrieves localized table

- **GIVEN** locale zh_CN is requested
- **WHEN** getCategory("CATS", zh_CN) is called
- **THEN** data is retrieved from category_zh table

### Requirement: Public access to catalog

The system SHALL enforce that all catalog operations (getCategory, getCategories, getProduct, getProducts, getItem, getItems, searchItems) are unauthenticated and unchecked - any caller may invoke these methods without authentication or role-based authorization.

#### Scenario: Unauthorized caller can access catalog

- **GIVEN** a caller with no authentication credentials
- **WHEN** getCategory("CATS", en_US) is invoked
- **THEN** the method succeeds and returns the category, no authorization check is performed

### Requirement: Category screen display

The system SHALL display a product category screen showing a localized list of available product categories with names and descriptions. Categories SHALL be displayed in the user's preferred language (en_US, ja_JP, or zh_CN) in alphabetical order by name.

#### Scenario: Category screen displays localized categories

- **GIVEN** the category list screen is loaded for locale en_US
- **WHEN** the page is displayed
- **THEN** all available categories are shown with names and descriptions in English, sorted alphabetically by category name

#### Scenario: Category screen displays Japanese categories

- **GIVEN** the category list screen is loaded for locale ja_JP
- **WHEN** the page is displayed
- **THEN** all available categories are shown with names and descriptions in Japanese from ja_JP localized tables

### Requirement: Search results screen

The system SHALL display a search results screen showing items matching search keywords with pagination controls. When search yields no items, a no-results message SHALL be displayed.

#### Scenario: Search results screen with matches

- **GIVEN** a search for "widget" yielding 25 matching items
- **WHEN** the search results screen is displayed with start=0, count=10
- **THEN** 10 items are shown with pagination controls showing Previous/Next links, and no-results message is not displayed

#### Scenario: Search results screen with no matches

- **GIVEN** a search for "xyznonexistent" yielding 0 items
- **WHEN** the search results screen is displayed
- **THEN** a no-results message is displayed and pagination controls are hidden or disabled

### Requirement: Item detail screen

The system SHALL display a product item detail screen showing item information including itemId, productName, description, image location, and unit cost. The screen SHALL provide an "Add to Cart" action linked to cart.do?action=purchase&itemId=<itemId>.

#### Scenario: Item detail screen displays item information

- **GIVEN** an item with ID "ITEM1" is selected
- **WHEN** the item detail screen is displayed
- **THEN** the screen shows itemId, productName, description, image, and unit cost formatted as currency

#### Scenario: Add to Cart action links correctly

- **GIVEN** the item detail screen is displayed for item "ITEM1"
- **WHEN** the Add to Cart button is clicked
- **THEN** navigation occurs to cart.do?action=purchase&itemId=ITEM1
