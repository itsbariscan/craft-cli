# Code Review Checklist

## Security (Critical — blocks merge)

### Authentication & Authorization
- [ ] All server actions verify session before mutating data
- [ ] Next.js middleware protects all authenticated routes
- [ ] No server-side data passed to client without explicit sanitization
- [ ] Supabase RLS policies exist for all accessed tables
- [ ] No `service_role` key usage in client-accessible code
- [ ] JWT validation on all API routes

### Data Validation
- [ ] All user input validated with Zod schemas at API boundaries
- [ ] File uploads validated (type, size, content)
- [ ] URL parameters sanitized before database queries
- [ ] No string concatenation in SQL — use parameterized queries
- [ ] Drizzle schema types match database constraints

### Injection & XSS
- [ ] No `dangerouslySetInnerHTML` without DOMPurify or equivalent
- [ ] Server component output properly escaped
- [ ] No `eval()`, `new Function()`, or dynamic code execution with user input
- [ ] Redirect URLs validated against allowlist
- [ ] No open redirects

### Secrets
- [ ] No API keys, tokens, or passwords in committed code
- [ ] Environment variables used for all secrets
- [ ] `NEXT_PUBLIC_` prefix only on truly public values
- [ ] `.env` files in `.gitignore`
- [ ] No secrets logged or included in error messages

### Concurrency
- [ ] Optimistic updates handle concurrent modifications
- [ ] Database operations that must be atomic use transactions
- [ ] No TOCTOU (time-of-check/time-of-use) vulnerabilities

## Data Integrity (Critical)
- [ ] Cascade deletes don't orphan critical records
- [ ] Unique constraints where business logic requires uniqueness
- [ ] Foreign key relationships enforced at database level
- [ ] Migrations are reversible or have documented rollback plan

## Error Handling (Critical at boundaries)
- [ ] API routes return appropriate status codes
- [ ] Database errors caught and surfaced meaningfully
- [ ] External API failures have fallback behavior
- [ ] User-facing errors are helpful, not technical

## Performance (Informational)
- [ ] No N+1 queries (sequential fetches that could be parallel/batched)
- [ ] Large lists paginated or virtualized
- [ ] Images optimized (Next.js Image component, appropriate sizes)
- [ ] No unnecessary client-side fetching (prefer server components)
- [ ] Bundle size impact considered for new dependencies

## Accessibility (Informational)
- [ ] Semantic HTML elements used correctly
- [ ] Form inputs have associated labels
- [ ] Interactive elements keyboard-accessible
- [ ] Color contrast meets WCAG AA
- [ ] ARIA attributes used correctly (not overused)
- [ ] Focus management on route changes and modals

## Code Quality (Informational)
- [ ] No `any` types in TypeScript
- [ ] No `console.log` in committed code
- [ ] No dead code or commented-out blocks
- [ ] No magic strings — use constants or enums
- [ ] Functions do one thing
- [ ] No premature abstractions

## SEO (Informational — critical for WHO domains)
- [ ] Pages have unique, descriptive `<title>` tags
- [ ] Meta descriptions present and compelling
- [ ] Open Graph / Twitter Card metadata set
- [ ] Canonical URLs set correctly
- [ ] Structured data (JSON-LD) valid
- [ ] Hreflang tags for multi-language pages
- [ ] No orphan pages (all pages linked from sitemap or navigation)
