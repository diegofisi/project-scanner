# Scan Checklist

For each category: read 2-3 representative files, extract the pattern, classify as **architectural** (agnostic) or **implementation** (framework-specific).

---

## 1. Project Foundation

| What to check | How |
|---|---|
| Directory structure | `find src/ -type d` — identify organization strategy (flat, feature-based, vertical slices) |
| Dependencies | Full `package.json` — note exact versions for API compatibility |
| Build config | vite.config / webpack.config / next.config — path aliases, plugins |
| TypeScript config | tsconfig.json — strict mode, path aliases, compiler options |
| CSS config | tailwind.config / postcss.config — theme tokens, custom utilities |
| Lint/format | eslint.config + .prettierrc — code style enforcement |
| Entry point | main.tsx + App.tsx — provider hierarchy, bootstrap order |
| Global styles | index.css — CSS variables, theme system, resets |

**Architectural patterns to extract:** Directory organization strategy, separation of concerns boundaries, dependency management approach.

**Implementation patterns to extract:** Specific build tool config, path alias syntax, provider wrapping order.

---

## 2. Components

| What to check | Read example of |
|---|---|
| Component structure | A simple component, a complex one, and one with forwardRef |
| Props typing | interface vs type, inline vs separate, optional patterns |
| Composition | children, render props, compound components, variant switching |
| Container/Presentational split | How smart components connect to dumb components |
| Layout primitives | Stack, Box, Grid, Flex — or raw divs? |
| Typography primitives | H1-H6, P, Span — or raw HTML text elements? |
| **Component API design** | How they design the prop interface of reusable components |
| Variant/size props | `variant`, `size`, `color` as typed unions? |
| Slot props | `header`, `footer`, `icon` as ReactNode props? Or only `children`? |
| Polymorphic `as` prop | `<Button as="a" href="...">` pattern? |
| HOCs / wrappers | `withAuth()`, `withLayout()` — or only hooks? |
| Render props vs hooks | Which pattern do they prefer for sharing logic? |

**Extract as architectural:**
```
- Components are split into containers (logic) and presentational (pure JSX)
- Layout uses abstracted primitives, never raw HTML divs
- Typography uses typed primitives with color/weight props
- Reusable components use typed variant/size props (not strings)
- Composition via children + slot props, not render props
```

**Extract as implementation (example):**
```typescript
// Container pattern
export const {Entity}Container = ({ id }: Props) => {
  const { data } = useGet{Entity}(id);
  return <{Entity}View data={data} />;
};

// Presentational pattern
export const {Entity}View = forwardRef<HTMLDivElement, {Entity}ViewProps>(
  ({ data, ...props }, ref) => (
    <Stack gap="md" ref={ref}>
      <H4>{data.name}</H4>
      <P color="muted">{data.description}</P>
    </Stack>
  ),
);
{Entity}View.displayName = '{Entity}View';

// Component API pattern (if present)
interface {Component}Props {
  variant?: 'default' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  icon?: ReactNode;
  as?: ElementType;
}
```

---

## 3. Data Layer

| What to check | Read example of |
|---|---|
| HTTP client | Axios/fetch instance — interceptors, base URL, token injection |
| API hook (query) | A GET hook — query key structure, DTO mapping, enabled conditions |
| API hook (mutation) | A POST/PUT hook — cache invalidation, onSuccess/onError |
| DTO layer | A .dto.ts file — DTO interface + mapper function |
| Domain models | A .model.ts file — clean interface, enum patterns |
| Response handling | Envelope unwrapping, error transformation, refresh logic |

**Extract as architectural:**
```
- Each endpoint: own folder with `{action}.dto.ts` + `use{Action}.ts`
- DTO → Domain Model via mapper function (never use DTOs in components)
- Queries: `select` transforms DTO → Model at query level
- Mutations: `onSuccess` invalidates related query keys
- HTTP client: request interceptor (auth token), response interceptor (error handling + token refresh)
```

**Extract as implementation (example):**
```typescript
// Query hook template
export function useGet{Resource}(id: string, options?) {
  return useQuery<{Resource}DTO, Error, {Resource}>({
    queryKey: ['{resource}', id],
    queryFn: () => get{Resource}(id),
    select: to{Resource},
    enabled: !!id,
    ...options,
  });
}

// Mutation hook template
export function useCreate{Resource}() {
  const qc = useQueryClient();
  return useMutation<{Resource}, Error, Create{Resource}DTO>({
    mutationFn: async (params) => {
      const dto = await create{Resource}(params);
      return to{Resource}(dto);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['{resource}'] });
    },
  });
}
```

---

## 4. State Management

| What to check | Read example of |
|---|---|
| Client state library | Zustand/Redux/Context/Jotai — which and why |
| Store structure | A store file — shape, actions, reset pattern |
| Server state config | QueryClient config — staleTime, retry, refetchOnWindowFocus |
| State access | How components consume state (hooks, selectors) |

**Extract as architectural:**
```
- Client state: {library} for UI state (selections, view modes, dialogs)
- Server state: {library} for API data (cached, auto-refreshed)
- No React Context for state (only for dependency injection if used)
- Every store has a reset() method
```

---

## 5. Forms & Validation

| What to check | Read example of |
|---|---|
| Form library | react-hook-form / Formik / native |
| Validation library | Zod / Yup / Joi |
| Schema location | Same file or separate .schema.ts |
| Form → Component flow | How form state connects to UI |
| Error display | How validation errors render |
| Submit pattern | form.handleSubmit → mutation.mutate → onSuccess/onError |

**Extract as implementation (example):**
```typescript
// Schema (separate file: {action}.schema.ts)
export const create{Entity}Schema = z.object({
  name: z.string().min(1, 'Required').max(255),
});
export type Create{Entity}Form = z.infer<typeof create{Entity}Schema>;

// Container
const form = useForm<Create{Entity}Form>({
  resolver: zodResolver(create{Entity}Schema),
});
const onSubmit = form.handleSubmit((data) => {
  mutation.mutate(data, {
    onSuccess: () => { onClose(); form.reset(); },
    onError: (err) => toast.error(err.message),
  });
});

// Presentational dialog receives: form, onSubmit, isPending
```

---

## 6. Routing & Auth

| What to check | Read example of |
|---|---|
| Router setup | Main router file — route definition style |
| Route guards | Auth wrapper, role-based guards |
| Lazy loading | React.lazy / dynamic import patterns |
| Path constants | How paths are defined (enum, const object, inline) |
| Auth flow | Login mechanism, token storage, refresh logic |
| Auth state | Store/context for user + auth status |
| Logout flow | Cleanup, redirect |

**Extract as architectural:**
```
- Paths defined as const objects: `{Feature}Path.ROOT`, `{Feature}Path.DETAIL`
- Route guards as wrapper components: <Auth />, <Admin />, <User />
- All pages lazy-loaded with Suspense + loading fallback
- Auth: OAuth/credentials → tokens in localStorage → interceptor injects
- Token refresh: de-duplicated (single promise for concurrent 401s)
```

---

## 7. UI & Styling

| What to check | Read example of |
|---|---|
| CSS approach | Tailwind / CSS Modules / styled-components / CSS-in-JS |
| Theme system | CSS variables, dark mode toggle mechanism |
| Class utility | cn() / clsx / classnames |
| Design tokens | Spacing, radius, colors, shadows |
| Responsive patterns | Mobile-first, breakpoints, hide/show |

---

## 8. Error Handling & UX

| What to check | Read example of |
|---|---|
| Error boundaries | Where placed, fallback UI |
| Loading states | Page-level (Suspense), component-level (skeleton/spinner) |
| Empty states | Empty state component pattern |
| Notifications | Toast library, variants (success, error, undo action) |

---

## 9. Naming Conventions

Extract as a table — this is critical for the generated skill:

| Element | Convention | Example |
|---------|-----------|---------|
| Feature folder | ? | |
| Component file | ? | |
| Hook file | ? | |
| Store file | ? | |
| Schema file | ? | |
| DTO file | ? | |
| Model file | ? | |
| API folder | ? | |
| Types/Enums | ? | |
| CSS classes | ? | |

---

## 10. Testing

| What to check | Read example of |
|---|---|
| Test runner | vitest / jest / cypress / playwright |
| File location | Colocated (`.test.tsx` next to source) or `__tests__/` directory? |
| Mocking pattern | MSW for API? `vi.mock` / `jest.mock`? Manual mocks? |
| What they test | Unit hooks? Integration components? E2E flows? |
| Setup files | `setupTests.ts`, custom render with providers, test utils |
| Assertion style | `expect().toBe()`, `screen.getByRole()`, `toHaveBeenCalledWith()` |
| Data builders | Factories/fixtures for test data? Inline objects? |

**Extract as architectural:**
```
- Tests colocated with source / in __tests__ directory
- API mocking via MSW / manual mocks
- Custom render wraps providers: QueryClient, Router, Theme
- Test data via factory functions / inline fixtures
```

**Extract as implementation (example):**
```typescript
// Hook test
const { result } = renderHook(() => useGet{Resource}('1'), {
  wrapper: createTestWrapper(),
});
await waitFor(() => expect(result.current.data).toBeDefined());

// Component test
render(<{Entity}Container id="1" />, { wrapper: createTestWrapper() });
expect(screen.getByText('{entity} name')).toBeInTheDocument();
```

---

## 11. Coding Style Fingerprint

This section captures the **personal coding style** of the team — not WHAT they build but HOW they write code. Read 5-6 diverse files to extract these signals.

| Signal | What to look for |
|---|---|
| Arrow vs function declarations | `const Comp = () =>` or `function Comp()`? |
| Export style | `export default` or named exports? Barrel re-exports? |
| Destructuring depth | Props destructured inline `({ name, age })` or separate `const { name } = props`? |
| Conditional rendering | Ternaries, `&&`, early returns, or wrapper `<Show when={}>` ? |
| Async patterns | `async/await` + try/catch or `.then().catch()`? Where do they handle errors? |
| Comment style | JSDoc? `// TODO`? Inline comments? No comments at all? |
| Import order | React first → third-party → local? Separator lines between groups? |
| Type definitions | `interface` or `type`? Same file or in `types/`? |
| Callback handling | Inline `onClick={() => doX()}` or named `onClick={handleClick}`? |
| Optional chaining | `data?.name` or `data && data.name`? |
| String style | Template literals always or only when interpolating? |
| Null handling | `null`, `undefined`, or non-null assertions `!`? |
| Guard clauses | Early returns at top of function or nested if/else? |
| File length | Short focused files (<100 lines) or large files (300+ lines)? |

**Extract as a style profile:**
```
CODING STYLE PROFILE:
- Components: arrow functions with named exports
- Props: destructured inline, typed with interface
- Conditionals: early returns for guards, ternary for inline JSX
- Async: async/await everywhere, errors in onError callbacks
- Comments: minimal — only for non-obvious business logic
- Imports: React → external → @shared/ → relative, no separators
- Callbacks: named handlers (handleClick, handleSubmit) — never inline
- Null: optional chaining, no non-null assertions
- Files: short (<150 lines), split into multiple files when growing
```

---

## 12. Inconsistencies & Anti-patterns

Look for places where the team does NOT follow their own patterns. These are critical to document so the generated skill avoids reproducing mistakes.

| What to look for | Why it matters |
|---|---|
| Components mixing container + presentational logic | Some files may break the separation — mark as legacy |
| Direct fetch in components (bypassing hooks) | Inconsistent data layer |
| Forms without validation schema | Not all forms may follow the schema-first pattern |
| Inline styles mixed with utility classes | Styling inconsistency |
| Raw `console.log` left in production code | Debug artifacts |
| Inconsistent naming (camelCase folder, PascalCase folder) | Naming drift over time |
| Different error handling strategies in different features | No unified approach |

**Document as:**
```
INCONSISTENCIES FOUND:
- ❌ src/features/legacy-dashboard/ — mixes container + presentational in single file
  → AVOID: follow container/presentational split from core/ features
- ❌ src/core/reports/ReportPage.tsx — fetches API directly without hook
  → AVOID: always use query/mutation hooks
- ❌ 3 of 12 forms lack Zod schema
  → RULE: every form MUST have a .schema.ts file

DECISION: When inconsistency found, follow the MAJORITY pattern (the one used most).
```

---

## 13. Advanced (if present)

Only scan these if they exist in the project:
- Drag & drop, file uploads, keyboard shortcuts
- Real-time (WebSocket/SSE), i18n
- Performance: React.memo, useMemo, useCallback, virtualization, lazy loading, Suspense boundaries
- Accessibility: ARIA, focus management
- Image optimization: next/image, lazy loading, responsive images
