# QA Issue Taxonomy

## Severity Levels

### Critical
- Page crashes or is inaccessible
- Data loss or corruption
- Security vulnerability exposed to user
- Core functionality completely broken
- Payment/auth flow broken

### Major
- Feature doesn't work as expected
- Significant visual breakage
- Poor performance (LCP > 4s, CLS > 0.25)
- Accessibility barrier (keyboard trap, missing labels on forms)
- Broken navigation paths

### Minor
- Cosmetic issues (alignment, spacing, color inconsistency)
- Minor performance issues (LCP 2.5-4s)
- Missing loading/empty states
- Console warnings (non-error)
- Minor accessibility issues (low contrast, missing alt text on decorative images)

### Info
- Enhancement suggestions
- Best practice recommendations
- SEO optimization opportunities
- Code quality observations

## Categories

| Category       | Covers                                              |
|----------------|------------------------------------------------------|
| Functional     | Features, forms, buttons, navigation, data flow      |
| Visual         | Layout, responsiveness, images, typography, styling   |
| Performance    | Load time, Core Web Vitals, bundle size, caching      |
| Accessibility  | Screen reader, keyboard, contrast, ARIA, semantics    |
| Content        | Text, headings, meta tags, structured data, i18n      |
| Console        | JS errors, warnings, deprecation notices              |
| Network        | Failed requests, 404s, CORS, mixed content            |
| Security       | Exposed data, insecure resources, missing headers     |
| UX             | Loading states, error states, empty states, feedback  |
| SEO            | Meta tags, OG, canonical, hreflang, structured data   |
