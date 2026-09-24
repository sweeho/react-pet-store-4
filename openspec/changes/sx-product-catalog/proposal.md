# Product Catalog Specification Extraction

## Overview

This specification documents the product catalog capability extracted from the legacy Java EE PetStore application. The catalog provides read-only access to hierarchical product data organized by categories, products, and inventory items (SKUs), with support for pagination and full-text search across multiple languages (US English, Japanese, Chinese).

## Capability Summary

The product catalog is a stateless EJB service providing unchecked (public) access to product information. All operations are read-only and support locale-specific data retrieval. The system manages four primary entity types: Category, Product, Item, and Page (pagination container).

## Scope

### Included

- Hierarchical product browsing (categories → products → items)
- Paginated query results with `hasNext` indicators
- Full-text keyword search across items
- Locale-aware data retrieval (en_US, ja_JP, zh_CN)
- JDBC DataSource access with connection pooling
- EJB transaction management (Container-Managed, Required transaction context)

### Not Included

- Product catalog administration (add, modify, delete)
- Role-based access control (all methods are unchecked/public)
- Search result ranking or relevance scoring
- Caching policy (application-level)

## Key Characteristics

- **Architecture**: Stateless Session EJB with DAO abstraction
- **Data Access**: JDBC with scroll-insensitive result sets
- **Pagination**: Absolute positioning via `ResultSet.absolute(start+1)`
- **Entities**: POJO model with 4 core classes (Category, Product, Item, Page)
- **Localization**: Locale-to-table-name routing at database layer
- **Transactions**: All operations use Required transaction context
- **Authorization**: Unchecked access (no authentication or role requirements)

## Extracted Entities

1. **Category** - Represents a product category with id, name, description
2. **Product** - Represents a product within a category with id, name, description
3. **Item** - Represents an inventory item (SKU) with 13 attributes including price and image location
4. **Page** - Pagination container with result list, start index, and hasNext flag

## Screen Interfaces

Three user-facing screens were identified:

1. Category listing screen showing localized category names and descriptions
2. Search results screen displaying matching items with pagination controls
3. Item detail screen linking to shopping cart functions
