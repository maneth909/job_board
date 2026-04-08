# CLAUDE.md — Job Board Project Context

This file documents everything needed to understand and continue working on this Flutter project.

---

## Project Summary

An **AI-powered job board mobile app** built in Flutter, targeting university students in Cambodia. Two user roles: **Jobseeker** (students) and **Employer** (companies). Core differentiator is AI-powered CV matching via the Groq LLM API.

---

## Tech Stack

| Layer | Library / Service |
|---|---|
| Framework | Flutter (Dart), SDK `^3.10.4` |
| Backend / DB / Auth / Storage | Supabase (`supabase_flutter ^2.5.0`) |
| State Management | Riverpod (`flutter_riverpod ^2.5.0`) |
| Navigation | GoRouter (`go_router ^14.0.0`) |
| AI / LLM | Groq Cloud API — model `llama-3.3-70b-versatile` |
| PDF parsing | `syncfusion_flutter_pdf ^32.2.9` |
| File / image picking | `file_picker ^10.3.10`, `image_picker ^1.2.1` |
| HTTP | `http ^1.6.0` |
| Env vars | `flutter_dotenv ^5.1.0` — loaded from `.env` asset |

---

## Environment Variables (`.env`)

The `.env` file is in the project root and is declared as a Flutter asset. Required keys:

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
GROQ_API_KEY=
```

Access pattern: `dotenv.env['KEY_NAME']`

---

## Project Structure

```
lib/
├── main.dart                        # Entry point — initialises dotenv, Supabase, ProviderScope
├── core/
│   ├── router.dart                  # GoRouter with auth/onboarding redirect guards
│   ├── supabase_client.dart         # Global singleton: `final SupabaseClient supabase = Supabase.instance.client;`
│   └── theme.dart                   # Light + dark ThemeData; ThemeMode.system
├── features/
│   ├── auth/
│   │   ├── screens/                 # login_screen, register_screen, role_selection_screen
│   │   └── services/
│   │       └── auth_service.dart    # authStateProvider (Stream<AuthState>), currentUserProvider
│   ├── profile/
│   │   ├── providers/
│   │   │   └── profile_state_provider.dart  # ProfileState + ProfileStateNotifier + profileStateProvider
│   │   ├── screens/                 # jobseeker_profile_screen, employer_profile_screen,
│   │   │                            # cv_upload_screen, employer_public_profile_screen
│   │   └── services/
│   │       ├── profile_service.dart       # profileServiceProvider — DB reads/writes for profiles
│   │       └── file_upload_service.dart   # fileUploadServiceProvider — avatar + CV upload to Supabase Storage
│   ├── jobs/
│   │   ├── models/
│   │   │   └── job_model.dart       # Job class with fromMap / toMap / copyWith
│   │   ├── screens/                 # job_listing_screen, job_detail_screen, job_post_screen, manage_jobs_screen
│   │   └── services/
│   │       └── job_service.dart     # jobServiceProvider, jobsProvider, myJobsProvider, jobDetailsProvider
│   └── ai/
│       ├── screens/
│       │   └── ai_match_screen.dart # Displays score circle, advisor explanation, matching/missing skills chips
│       └── services/
│           └── groq_service.dart    # groqServiceProvider — all Groq API calls
└── shared/
    └── widgets/
        ├── custom_button.dart       # Reusable primary button widget
        └── custom_app_bar.dart      # Shared AppBar widget
```

---

## Routing (`lib/core/router.dart`)

Routing is done with GoRouter. The router has a **redirect guard** that enforces this chain:

1. Not authenticated → `/login`
2. Authenticated, no role → `/role-selection`
3. Has role, profile **not** completed → `/profile-setup/jobseeker` or `/profile-setup/employer`
4. Profile completed, tries to visit auth/setup routes → redirected to home (`/jobs` or `/jobs/manage`)

### All Routes

| Path | Screen | Notes |
|---|---|---|
| `/login` | `LoginScreen` | |
| `/register` | `RegisterScreen` | |
| `/role-selection` | `RoleSelectionScreen` | |
| `/jobs` | `JobListingScreen` | Jobseeker home |
| `/jobs/:id` | `JobDetailScreen(jobId)` | |
| `/jobs/:id/match` | `AiMatchScreen(matchResult)` | Receives `Map<String,dynamic>` via `extra` |
| `/jobs/post` | `JobPostScreen(job?)` | `job` via `extra` — null = create, non-null = edit |
| `/jobs/manage` | `ManageJobsScreen` | Employer home |
| `/profile-setup/jobseeker` | `JobseekerProfileScreen` | |
| `/profile-setup/employer` | `EmployerProfileScreen` | |
| `/profile/cv-upload` | `CvUploadScreen` | |
| `/profile` | `JobseekerProfileScreen` or `EmployerProfileScreen` | Role-branched |
| `/employer/:id` | `EmployerPublicProfileScreen(employerId)` | |

---

## Supabase Database Schema

### Tables

**`profiles`** (linked to `auth.users` by `id`)
- `id` uuid PK
- `role` text — `'jobseeker'` or `'employer'` (null until role selected)
- `avatar_url` text

**`jobseeker_profiles`**
- `id` uuid PK (same as `profiles.id`)
- `university` text
- `major` text
- `skills` text[] (comma-split from a text field, stored as array)
- `bio` text
- `cv_url` text (public Supabase Storage URL with cache-busting `?t=` param)
- `cv_filename` text
- `cv_text` text (extracted from PDF by `syncfusion_flutter_pdf`)

**`employer_profiles`**
- `id` uuid PK (same as `profiles.id`)
- `company_name` text
- `industry` text
- `description` text
- `website` text
- `telegram_handle` text (stored without `@`)

**`jobs`**
- `id` uuid PK
- `employer_id` uuid FK → `profiles.id`
- `title` text
- `description` text
- `skills_required` text[]
- `category` text
- `is_active` bool
- `location` text
- `salary_range` text
- `telegram_contact` text
- `created_at`, `updated_at` timestamps
- Full-text search via `fts` column (used with `.textSearch('fts', query)`)

**`cv_matches`**
- `job_id` uuid FK
- `jobseeker_id` uuid FK
- `score` int (0–100)
- `match_data` jsonb — full Groq response `{ score, explanation, matching_skills, missing_skills }`
- Unique constraint: `(job_id, jobseeker_id)` — used with `.upsert(..., onConflict: 'job_id, jobseeker_id')`

### Supabase Storage Buckets

| Bucket | Content | Path pattern |
|---|---|---|
| `avatars` | User profile pictures | `{userId}/profile_pic.jpg` |
| `cvs` | Jobseeker PDF CVs | `{userId}/cv.pdf` |

Both use `upsert: true` on upload (overwrite existing).

---

## State Management Patterns

All providers use **Riverpod**. Key providers:

| Provider | Type | Purpose |
|---|---|---|
| `authStateProvider` | `StreamProvider<AuthState>` | Supabase auth stream |
| `currentUserProvider` | `Provider<User?>` | Current Supabase user |
| `profileStateProvider` | `StateNotifierProvider<ProfileStateNotifier, ProfileState>` | Role + completion status; re-fetches on auth change |
| `profileServiceProvider` | `Provider<ProfileService>` | DB profile operations |
| `fileUploadServiceProvider` | `Provider<FileUploadService>` | Storage upload operations |
| `jobServiceProvider` | `Provider<JobService>` | Job CRUD |
| `jobsProvider` | `FutureProvider.family<List<Job>, JobFilters>` | Paginated job list |
| `myJobsProvider` | `FutureProvider<List<Job>>` | Employer's own jobs |
| `jobDetailsProvider` | `FutureProvider.family<Job, String>` | Single job by ID |
| `groqServiceProvider` | `Provider<GroqService>` | All Groq API calls |

### `ProfileState` shape:
```dart
class ProfileState {
  final bool isLoading;
  final String? role;      // 'jobseeker' | 'employer' | null
  final bool isCompleted;  // true if role-specific profile row exists
}
```

---

## AI Features (`groq_service.dart`)

All calls go to `https://api.groq.com/openai/v1/chat/completions` using model `llama-3.3-70b-versatile`.

### Three methods:

**1. `getCVMatchScore({ cvText, jobDescription })` → `Map<String, dynamic>`**
Returns JSON: `{ score: int, explanation: String, matching_skills: [...], missing_skills: [...] }`
- Explanation uses emojis, bullet points (`•`), `\n` newlines — optimised for mobile display
- Temperature: `0.2` (deterministic)

**2. `getAndCacheCVMatchScore({ jobId, cvText, jobDescription })` → `Map<String, dynamic>`**
Same as above but also upserts result into `cv_matches` table.

**3. `generateApplicationMessage({ jobseekerName, university, skills, jobTitle, companyName, cvUrl })` → `String`**
Generates a short Telegram application message (3–4 sentences, no emojis, no letter format).
- Temperature: `0.5`

**4. `simplifyJobDescription(String jobDescription)` → `String`**
Returns ≤6 plain-English bullet points summarising a job description.
- Temperature: `0.3`

### JSON extraction pattern (used after getCVMatchScore):
```dart
final startIndex = rawString.indexOf('{');
final endIndex = rawString.lastIndexOf('}');
final cleanString = rawString.substring(startIndex, endIndex + 1);
return jsonDecode(cleanString);
```

---

## Theme System (`lib/core/theme.dart`)

Supports light and dark mode (`ThemeMode.system`).

| Token | Light | Dark |
|---|---|---|
| Primary | `#0C36FA` (blue) | `#60A5FA` (light blue) |
| Background | `#FFFFFF` | `#272729` |
| Secondary (card bg) | `#F4F4F5` | `#18181B` |
| Text | `#09090B` | `#FAFAFA` |
| Muted | `#71717A` | `#A1A1AA` |
| Border | `#E4E4E7` | `#38383F` |
| Error | `#EF4444` | `#F87171` |

Always use `Theme.of(context).colorScheme.*` — never hardcode colours.

---

## Job Model Key Notes

- `Job.fromMap()` handles nested Supabase joins:
  - `profiles.avatar_url` → `companyLogo`
  - `profiles.employer_profiles[0].company_name` → `companyName`
  - `cv_matches[0].score` → `cachedMatchScore`
- `skillsRequired` is `List<String>` (stored as `text[]` in Supabase)
- Duplicating a job sets `isActive = false` so employer can review before publishing

---

## Shared Widgets

- `CustomButton` — `lib/shared/widgets/custom_button.dart` — primary action button
- `CustomAppBar` — `lib/shared/widgets/custom_app_bar.dart` — consistent app bar

---

## Common Patterns & Conventions

1. **Supabase client access**: Always import from `lib/core/supabase_client.dart`:
   ```dart
   import '../../../core/supabase_client.dart';
   // Use: supabase.from(...), supabase.auth, supabase.storage
   ```

2. **Guards before mutations**: Always check `currentUser != null` before any write operation; throw `Exception('User not logged in')` if null.

3. **Telegram handle storage**: Strip leading `@` before storing — `telegram_handle` in DB has no `@`.

4. **CV URL cache busting**: CV public URLs are stored with `?t={timestamp}` appended to force cache invalidation.

5. **Skills input**: Entered as a comma-separated string in UI, split and trimmed before storing as `text[]`.

6. **Navigation with data**: Use GoRouter `extra` for passing objects between screens (e.g., `Job` to edit screen, `Map<String,dynamic>` to AI match screen).

7. **Profile completion check**: Done by checking if a role-specific profile row exists (`jobseeker_profiles` or `employer_profiles`) — not a boolean flag.

8. **`ref.read` vs `ref.watch`**: Services use `ref.read` inside async methods (e.g., `ref.read(currentUserProvider)`) to avoid rebuilds from within service calls.
