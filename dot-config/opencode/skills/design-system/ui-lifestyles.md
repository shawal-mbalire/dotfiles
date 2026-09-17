# UI Lifestyles

UI Lifestyles categorize different types of web interfaces based on their primary purpose, key components, navigation patterns, and content hierarchy. Understanding these lifestyles helps apply the right design patterns and accessibility considerations.

## 1. Landing Page

**Purpose**: Conversion, marketing, lead generation

**Key Components**:
- Hero section with headline and CTA
- Social proof (testimonials, logos, case studies)
- Features/benefits grid
- FAQ section
- Newsletter signup

**Navigation**: Minimal - header with CTA, single-page scroll, sticky header

**Content Hierarchy**: Hero (primary) > Features (secondary) > Social proof (tertiary)

**Accessibility Considerations**:
- Skip link to main content
- Landmark regions for sections
- Heading hierarchy (h1 > h2 > h3)
- Image alt text for testimonials/logos

**Best For**: Product launches, marketing pages, event promotion

---

## 2. Dashboard

**Purpose**: Data visualization, monitoring, analytics

**Key Components**:
- Metrics cards (KPIs)
- Charts and graphs
- Data tables
- Filter panels
- Date range pickers

**Navigation**: Sidebar (collapsible), tabs, breadcrumbs for deep navigation

**Content Hierarchy**: Key metrics (primary) > Detailed data (secondary) > Actions (tertiary)

**Accessibility Considerations**:
- Data table alternatives for charts
- Chart descriptions (aria-describedby)
- Keyboard navigation for filters
- Live regions for real-time updates

**Best For**: Analytics tools, admin panels, monitoring systems

---

## 3. E-commerce

**Purpose**: Product sales, transactions

**Key Components**:
- Product grid/list
- Product cards with images
- Shopping cart (drawer or page)
- Checkout flow
- Search and filters

**Navigation**: Category navigation, search, breadcrumbs, cart icon with count

**Content Hierarchy**: Products (primary) > Filters (secondary) > Cart (persistent)

**Accessibility Considerations**:
- Product image alt text
- Price and availability announcements
- Cart total updates (live region)
- Form labels for checkout

**Best For**: Online stores, marketplaces, product catalogs

---

## 4. SaaS Application

**Purpose**: Subscription-based service delivery

**Key Components**:
- Dashboard/overview
- Feature modules
- Settings panels
- Billing/subscription management
- User/team management

**Navigation**: Sidebar with sections, breadcrumbs, user menu dropdown

**Content Hierarchy**: Primary feature (current context) > Settings (secondary) > Help (tertiary)

**Accessibility Considerations**:
- Form validation messages
- Status announcements (success/error)
- Keyboard shortcuts for power users
- Settings persistence feedback

**Best For**: CRM, project management, analytics tools, productivity apps

---

## 5. Content/Blog

**Purpose**: Reading, publishing, content distribution

**Key Components**:
- Article content (rich text)
- Comments section
- Categories/tags
- Search functionality
- Author bio
- Related articles

**Navigation**: Header with categories, search bar, sidebar (optional)

**Content Hierarchy**: Article content (primary) > Related articles (secondary) > Sidebar (tertiary)

**Accessibility Considerations**:
- Heading hierarchy for article structure
- Reading order for multi-column layouts
- Image captions and alt text
- Comment form labels

**Best For**: Blogs, news sites, documentation, publishing platforms

---

## 6. Portfolio

**Purpose**: Showcase work, creative presentation

**Key Components**:
- Project galleries
- Case studies
- About section
- Contact form
- Skills/services

**Navigation**: Minimal - header links, horizontal scroll, lightbox for images

**Content Hierarchy**: Featured project (primary) > Gallery (secondary) > About (tertiary)

**Accessibility Considerations**:
- Project image descriptions
- Case study structure (headings)
- Contact form labels
- Keyboard navigation for galleries

**Best For**: Creative professionals, agencies, personal brands

---

## 7. Documentation

**Purpose**: Reference, learning, technical guidance

**Key Components**:
- Table of contents (sidebar)
- Code blocks with syntax highlighting
- Search functionality
- Version selector
- API references
- Callout boxes (tips, warnings)

**Navigation**: Sidebar TOC, breadcrumbs, search, code language tabs

**Content Hierarchy**: Current topic (primary) > Related topics (secondary) > Code examples (tertiary)

**Accessibility Considerations**:
- Code block copy buttons with announcements
- Anchor links for headings
- Keyboard navigation for TOC
- Search result announcements

**Best For**: Developer documentation, API references, technical guides

---

## 8. Social/Messaging

**Purpose**: Communication, real-time interaction

**Key Components**:
- Feed/timeline
- Message threads
- Notifications
- User profiles
- Search/discover

**Navigation**: Bottom navigation (mobile), tabs, notification badges

**Content Hierarchy**: New content (primary) > Messages (secondary) > Profile (tertiary)

**Accessibility Considerations**:
- Live regions for new messages
- Notification announcements
- Keyboard shortcuts for actions
- Message read/unread states

**Best For**: Social networks, chat apps, community platforms

---

## 9. Admin/CMS

**Purpose**: Content management, backend operations

**Key Components**:
- Content lists (tables)
- Edit/create forms
- Media library
- User management
- Settings

**Navigation**: Sidebar with sections, breadcrumbs, search, bulk actions

**Content Hierarchy**: Content list (primary) > Edit form (secondary) > Settings (tertiary)

**Accessibility Considerations**:
- Form validation with error summaries
- Bulk action confirmations
- Drag-and-drop alternatives
- Status/success messages

**Best For**: WordPress-style CMS, admin panels, content management

---

## 10. Onboarding

**Purpose**: User activation, feature introduction

**Key Components**:
- Step indicators
- Progress bars
- Tooltips/popovers
- Tutorial overlays
- Checklist widgets

**Navigation**: Step-by-step wizard, progress indicator, skip/back options

**Content Hierarchy**: Current step (primary) > Progress (secondary) > Help (tertiary)

**Accessibility Considerations**:
- Progress announcements (aria-live)
- Keyboard navigation for steps
- Skip/onboarding completion
- Tooltip focus management

**Best For**: New user flows, feature tutorials, setup wizards

---

## UI Lifestyle Quick Reference

| Lifestyle | Primary Purpose | Key Navigation | Pattern 1 | Pattern 2 | Pattern 3 |
|-----------|-----------------|----------------|-----------|-----------|-----------|
| Landing Page | Conversion | Single-page scroll | ✓ | | ✓ |
| Dashboard | Analytics | Sidebar, tabs | ✓ | ✓ | ✓ |
| E-commerce | Sales | Category nav, search | ✓ | | ✓ |
| SaaS App | Service delivery | Sidebar, breadcrumbs | ✓ | ✓ | ✓ |
| Content/Blog | Reading | Header, sidebar | ✓ | | ✓ |
| Portfolio | Showcase | Minimal, horizontal | ✓ | | ✓ |
| Documentation | Reference | Sidebar TOC, search | ✓ | ✓ | ✓ |
| Social/Messaging | Communication | Bottom nav, tabs | ✓ | ✓ | ✓ |
| Admin/CMS | Content management | Sidebar, breadcrumbs | ✓ | ✓ | ✓ |
| Onboarding | Activation | Step-by-step wizard | ✓ | | ✓ |
