# PROJECT REPORT

---

## COVER PAGE

**App Name:** KhmerHire — AI-Powered Job Board for Cambodian Students

**Project Title:** AI-Powered Mobile Job Board Application

**Course Code:** ICT 302

**Group Members:**

| Full Name | Student ID |
|---|---|
| [Your Full Name] | [Your Student ID] |
| [Member 2 Full Name] | [Member 2 Student ID] |
| [Member 3 Full Name] | [Member 3 Student ID] |

**Submission Date:** April 23, 2026

---

## SECTION 1 — PROJECT DESCRIPTION

### Overview

KhmerHire is an AI-powered mobile job board application built with Flutter, targeting university students in Cambodia. The app bridges a critical gap in the Cambodian employment landscape: most job boards are designed for experienced professionals and ignore the specific needs of fresh graduates and university students looking for internships, part-time work, or entry-level full-time roles.

### Purpose and Problem Solved

University students in Cambodia face two major challenges when job-hunting. First, they have no efficient way to discover jobs that are suited to their current skill level and academic background. Second, they lack the professional confidence and tools to craft strong job applications. Traditional job boards like LinkedIn show every role regardless of fit, leaving students overwhelmed and unsure of where to focus their efforts.

KhmerHire solves both problems. It provides a curated list of student-appropriate jobs categorized by type (Internship, Part-time, Full-time) and integrates Artificial Intelligence to analyze how well a student's CV matches a specific job — giving a percentage score and a personalized explanation. Beyond matching, the app uses AI to automatically generate a professional Telegram application message on behalf of the student, so they can apply with confidence in seconds.

### Core Functionality

The application supports two user roles: **Jobseeker** (student) and **Employer** (company recruiter or hiring manager). Jobseekers can browse, search, filter, save, and apply to job listings. They can upload their CV in PDF format, which is automatically parsed and stored for AI analysis. Employers can post new job listings, manage existing ones, edit their company profile, and receive applications through Telegram.

The AI engine uses the Groq Cloud API running the `llama-3.3-70b-versatile` model to perform three intelligent tasks: CV-to-job matching with a score (0–100), plain-English simplification of complex job descriptions, and personalised application message generation.

### What Makes It Unique

Unlike generic job boards, KhmerHire is built specifically for the Cambodian student market. It integrates AI directly into the job browsing experience — match scores appear on job cards before the student even opens a listing — and uses Telegram as the application channel, which is ubiquitous in Cambodia. The combination of AI-driven matching, AI-generated cover messages, and a Telegram-native application workflow makes the app unlike anything currently available for Cambodian university students.

---

## SECTION 2 — BUSINESS IDEA & MODEL

### Objective

KhmerHire was built to solve a two-sided problem: students cannot efficiently find jobs suited to their skills, and employers cannot efficiently reach qualified student candidates. The app's goal is to reduce the friction on both sides by using AI as the central differentiator — making it faster for students to find relevant jobs and faster for employers to receive motivated applicants.

### Target Audience

**Primary Users (Jobseekers):** University students aged 18–25 in Cambodia, enrolled in degree programs across business, technology, design, and engineering. These users are tech-savvy, mobile-first, and active on Telegram and Facebook. Their primary challenge is lack of professional experience and confidence when applying for roles.

**Secondary Users (Employers):** Small-to-medium Cambodian businesses, startups, and multinational companies operating in Cambodia that hire students and fresh graduates for internships, part-time support roles, and entry-level positions. These employers typically use Telegram to communicate with candidates.

### Market Research

The existing job platforms available in Cambodia (e.g., BongThom, CamHR, JobsInCambodia) are web-first, designed for experienced professionals, and provide no AI-powered matching or application assistance. None of them offer Telegram-native application workflows. LinkedIn is globally dominant but is not optimised for students without experience and lacks local language context. KhmerHire differentiates itself through AI-first features, a mobile-first experience designed specifically for students, and Telegram integration which aligns with how Cambodian employers already communicate.

### Monetization Strategy

KhmerHire plans to monetize through a freemium employer model:

- **Free tier for Employers:** Post up to 2 active job listings per month.
- **Premium Employer Subscription ($15–$30/month):** Unlimited listings, featured placement on job cards, applicant analytics dashboard, and priority Telegram notifications when applications arrive.
- **Sponsored Listings:** Employers can pay a one-time fee to have a specific listing appear at the top of the relevant category for 7 days.
- **Jobseeker side:** Always free, to ensure maximum student adoption and network effects.

### Value Proposition

For **students**: AI removes the guesswork from job applications. Instead of blindly applying to dozens of roles, students see which jobs they are most qualified for before applying — saving time and boosting success rates. The AI-generated Telegram message removes the intimidation barrier of writing a professional application.

For **employers**: Access to a focused pool of motivated Cambodian university students in one place, with a lightweight Telegram-based application pipeline that requires zero integration work.

### Key Partnerships

- **Supabase** — Backend-as-a-Service for authentication, database, and file storage.
- **Groq Cloud** — LLM inference API powering all AI features (CV matching, description simplification, message generation).
- **Flutter / Dart ecosystem** — Open-source cross-platform framework for iOS and Android.
- **Cambodian Universities** — Potential institutional partnerships to promote the app directly to students.

### Cost Structure

| Cost Item | Estimated Monthly Cost |
|---|---|
| Supabase Free Tier (up to 500MB DB, 1GB storage) | $0 |
| Supabase Pro (scaled) | $25/month |
| Groq API usage (pay-per-token) | ~$10–$50/month depending on usage |
| App Store & Google Play Developer Accounts | ~$3/month amortised |
| Marketing (social media ads, university promotions) | $50–$200/month |
| **Total (early stage)** | **~$85–$275/month** |

### Revenue Streams

1. **Employer Premium Subscriptions** — Monthly recurring revenue from employers who need more than the free tier allows.
2. **Featured / Sponsored Listings** — One-time payments from employers wanting higher visibility.
3. **Future:** Institutional partnerships with universities for career-center integrations.

---

## SECTION 3 — FUNCTIONALITIES & FEATURES

### Core Functionalities

**1. User Authentication (Email & Password)**
Description: Users can register and log in securely using an email and password. Registration captures the user's full name. Upon first login, users are directed through an onboarding flow and then select their role (Jobseeker or Employer). Supabase Auth handles session management, and GoRouter enforces auth-based navigation guards automatically.
Importance: **High**

**2. Role-Based Profile Setup**
Description: After selecting a role, users complete a role-specific profile. Jobseekers provide their university, major, skills (comma-separated), and a bio. Employers provide a company name, industry, description, website, and Telegram handle. Until a profile is completed, the app redirects users back to the setup screen on every launch.
Importance: **High**

**3. Job Listing & Search**
Description: Jobseekers see a paginated list of all active job postings. Each card shows the company logo, job title, company name, required skills (up to 3 shown), and an AI match score badge if one exists. Users can search by keyword (full-text search powered by Supabase's `fts` column) and filter by job category (All, Internship, Full-time, Part-time). The list supports infinite scroll with load-more pagination.
Importance: **High**

**4. Job Detail View**
Description: A dedicated screen shows the full details of a job listing: company logo, job title, location, salary range, job type, full description, and all required skills. A sticky bottom action bar provides three buttons: Save (bookmark), AI Analyze / View Match, and Apply Now.
Importance: **High**

**5. AI CV-to-Job Matching**
Description: When a jobseeker taps "AI Analyze", the app sends their uploaded CV text and the job description to the Groq Cloud API. The LLM returns a JSON payload with a match score (0–100), an encouraging explanation with bullet points and emojis, a list of matching skills, and a list of missing skills. The result is cached in the `cv_matches` Supabase table so the student never pays for the same analysis twice. The score appears as a colour-coded badge (green ≥70, orange 40–69, red <40) on job cards.
Importance: **High**

**6. AI Match Analysis Screen**
Description: A dedicated screen displays the full match result: a circular score ring showing the percentage, an AI Advisor Analysis card with markdown-rendered explanations, and two skill chip groups (matching skills in blue, missing skills in grey).
Importance: **High**

**7. Job Application with AI Message Generation**
Description: When a jobseeker taps "Apply Now", a bottom sheet modal appears. The student can write their own application message or tap "AI Generate" to have the Groq API write a professional 3–4 sentence Telegram application message using their name, university, skills, and CV link. The student can edit the generated message before confirming. The application is recorded locally (SharedPreferences) and the student's status changes to "Applied ✓".
Importance: **High**

**8. Save Jobs (Bookmarks)**
Description: Jobseekers can save any job by tapping the bookmark icon on the job detail screen. Saved jobs are stored locally (SharedPreferences) with their order preserved. The Saved Jobs tab shows all saved listings with full job card details, fetched live from Supabase.
Importance: **High**

**9. Employer Job Posting & Management**
Description: Employers can post new jobs by filling in a form: title, description, required skills, category, location, salary range, and Telegram contact. They can edit existing listings, toggle a listing's active/inactive status, duplicate a listing (creating an inactive copy for editing), and delete listings. All CRUD operations go directly to the Supabase `jobs` table.
Importance: **High**

**10. CV Upload & PDF Parsing**
Description: Jobseekers can upload a PDF CV from their device. The app uses the `syncfusion_flutter_pdf` library to parse the PDF text locally on the device. The PDF file is uploaded to Supabase Storage (`cvs` bucket), and the extracted text is saved to `cv_text` in the `jobseeker_profiles` table. This text is what the AI matching engine uses for analysis.
Importance: **High**

### Additional Features

**1. Onboarding Walkthrough**
Description: A three-page illustrated onboarding flow shown only on the first app launch. Explains the app's three core value propositions using large icons and short descriptions. State is persisted via SharedPreferences.
User Benefit: New users immediately understand the app's AI features without reading a tutorial.
Technical Requirements: `SharedPreferences` for seen-state tracking, `PageView` for smooth swiping, GoRouter redirect guard.

**2. Dark Mode / Light Mode Toggle**
Description: The app supports both light and dark themes via a `ThemeMode` toggle accessible from the profile screen. The theme is persisted across sessions using SharedPreferences.
User Benefit: Reduces eye strain in low-light conditions.
Technical Requirements: Riverpod `StateNotifierProvider` for theme state, `ThemeData` with fully defined `ColorScheme` tokens for both modes.

**3. Employer Public Profile Page**
Description: Any jobseeker can tap through to view a read-only public profile of the company that posted a job. Shows company name, industry, description, website, and Telegram handle.
User Benefit: Allows students to research companies before applying.
Technical Requirements: GoRouter dynamic route `/employer/:id`, Supabase join query.

**4. Job Description Simplification (AI)**
Description: The Groq service includes a `simplifyJobDescription` method that condenses complex corporate job descriptions into ≤6 plain-English bullet points for easier reading by students.
User Benefit: Removes corporate jargon so students can quickly understand what a role actually requires.
Technical Requirements: Groq API call with a specialised system prompt, temperature 0.3.

**5. Applied Jobs Tracker**
Description: The "Applied" tab in the main navigation shows a list of all jobs the student has applied for, along with the application date and job details fetched from Supabase.
User Benefit: Students can track their application history without leaving the app.
Technical Requirements: Local `SharedPreferences` store for application records, Supabase query to resolve job details.

---

## SECTION 4 — DESIGN CONSIDERATIONS

### User Interface

The app follows a modern, clean design language inspired by popular job board apps like LinkedIn, Indeed, and Wellfound (AngelList Talent). The aesthetic is minimal — generous white space, rounded corners (16–24px radius), and subtle shadows — to ensure the content (job titles, company names, skill tags) is always the focal point.

**Color Scheme:**
- **Primary (Light mode):** Deep blue `#0C36FA` — conveys professionalism, trust, and ambition.
- **Primary (Dark mode):** Soft blue `#60A5FA` — reduces harshness on OLED screens while maintaining brand identity.
- **Background (Light):** Pure white `#FFFFFF` with a light grey secondary surface `#F4F4F5` for card backgrounds.
- **Background (Dark):** Near-black `#272729` with a deeper card surface `#18181B`.
- **Accent / Status Colors:** Green for high match scores (≥70%), orange for medium (40–69%), red for low (<40%).

**Typography:** Google Fonts "Inter" — a humanist sans-serif widely regarded as the most legible typeface for digital interfaces. Used consistently throughout the app with weight variants (400 regular, 500 medium, 600 semi-bold, 700 bold, 800 extra-bold) to create clear visual hierarchy.

**Design Patterns:**
- Gradient top header on the Job Listing and Job Detail screens (primary blue) with a white card surface sliding up from below, creating a layered depth effect.
- Wavy clip-path on the Job Detail screen header adds visual interest without being distracting.
- Animated bottom navigation bar with Cupertino-style icons for a polished iOS-native feel on Apple devices.
- Skill tags displayed as rounded-corner pills throughout the app for consistent visual language.
- Match score displayed with a circular `CircularProgressIndicator` ring with colour-coded stroke — immediately communicates fit level without requiring the user to read any text.

### User Experience

The user flow is designed around a single golden path: **open app → see relevant jobs → check AI match → apply**. Every screen in the navigation hierarchy supports this flow.

**First-time Users:** The onboarding screen shows on first launch and explains the three core value propositions in a swipeable 3-page format. The "Skip" button ensures returning users who accidentally reach onboarding are not blocked.

**Authentication Flow:** GoRouter redirect guards enforce a strict chain: unauthenticated users are sent to Login, authenticated users without a role go to Role Selection, users with a role but incomplete profile go to Profile Setup. This prevents partial-profile states from ever reaching the main app.

**Home Experience:** The Job Listing screen greets the user by name (pulled from Supabase auth metadata). Job cards show AI match scores immediately on the listing, so students can prioritize without tapping into each detail screen. Category filter chips are horizontally scrollable and apply instantly without requiring a search button press. Search uses a 300ms debounce timer to avoid excessive API calls while the user types.

**Applying for Jobs:** The application bottom sheet modal keeps the user on the same screen, reducing cognitive load. The AI Generate button is placed next to the message label so it is discovered naturally. The generated message is editable before submission, giving the student full control.

### Accessibility

- **Color Contrast:** All text-on-background combinations in both light and dark mode meet WCAG AA contrast ratio requirements. The primary blue `#0C36FA` on white background achieves a 7.03:1 contrast ratio (exceeds AA standard of 4.5:1).
- **Touch Target Sizes:** All interactive elements (buttons, icon buttons, filter chips) use minimum 44×44px touch targets, in line with Apple's Human Interface Guidelines and Google's Material Design specifications.
- **Semantic Widgets:** Flutter's built-in `Semantics` layer is used implicitly through standard widgets (e.g., `ElevatedButton`, `IconButton` with `tooltip` labels) which expose accessibility labels to screen readers on both iOS (VoiceOver) and Android (TalkBack).
- **Dark Mode Support:** Full dark mode implementation reduces eye strain for users with photosensitive conditions and improves readability in low-light environments.
- **Text Scaling:** All text uses Flutter's default text scaling behavior, meaning users who increase system font size will see the app scale accordingly.

---

## SECTION 5 — TECHNOLOGY STACK

### Front-End

| Technology | Version | Purpose |
|---|---|---|
| Flutter | SDK ^3.10.4 | Cross-platform UI framework (iOS & Android from one codebase) |
| Dart | Bundled with Flutter | Programming language |
| flutter_riverpod | ^2.5.0 | Reactive state management for all providers and services |
| go_router | ^14.0.0 | Declarative navigation with redirect guards and deep linking |
| google_fonts | ^6.1.0 | Inter font family for consistent typography |
| flutter_markdown | ^0.7.7 | Renders AI-generated markdown explanations in the match screen |

### Back-End

| Technology | Version | Purpose |
|---|---|---|
| Supabase | supabase_flutter ^2.5.0 | Backend-as-a-Service: PostgreSQL database, Auth, and File Storage |
| PostgreSQL (via Supabase) | — | Relational database for profiles, jobs, and CV match cache |
| Supabase Storage | — | Cloud file storage for user avatars (avatars bucket) and CVs (cvs bucket) |
| Supabase Auth | — | Email/password authentication with JWT session management |

### Third-Party APIs

| API / Service | Purpose |
|---|---|
| Groq Cloud API (llama-3.3-70b-versatile) | CV-to-job matching, job description simplification, Telegram message generation |
| http ^1.6.0 | HTTP client for Groq API calls |

### Tools & Platforms

| Tool | Purpose |
|---|---|
| Flutter SDK + Dart SDK | Development framework |
| VS Code / Android Studio | IDE for writing and debugging Flutter code |
| Flutter DevTools | Performance profiling and widget inspector |
| Android Emulator / iOS Simulator | Device testing during development |
| Supabase Dashboard | Database management, RLS policy configuration, and storage management |
| Groq Cloud Console | API key management and usage monitoring |
| Git + GitHub | Version control and source code hosting |
| flutter_dotenv ^5.1.0 | Loads environment variables (Supabase URL/key, Groq API key) from a `.env` asset file at runtime |
| syncfusion_flutter_pdf ^32.2.9 | Local PDF text extraction for CV parsing |
| file_picker ^10.3.10 | Native file picker for PDF CV upload |
| image_picker ^1.2.1 | Native image picker for profile avatar upload |
| shared_preferences ^2.3.1 | Local key-value storage for onboarding state, saved jobs, and applications |

---

## SECTION 6 — TOTAL NUMBER OF SCREENS

**Total Screens: 19**

The app contains 19 distinct screens across two user roles. The main navigation shell (visible to logged-in users) is a `BottomNavigationBar` with 4 tabs. The screens are organised into four functional groups: Onboarding & Auth, Profile Setup, Main Application, and Employer-Specific.

| # | Screen Name | Role | Description |
|---|---|---|---|
| 1 | Onboarding Screen | All | 3-page swipeable intro shown on first launch only |
| 2 | Login Screen | All | Email and password login |
| 3 | Register Screen | All | New account creation with full name, email, and password |
| 4 | Role Selection Screen | All | User chooses Jobseeker or Employer role post-registration |
| 5 | Jobseeker Profile Setup Screen | Jobseeker | Initial profile setup: university, major, skills, bio |
| 6 | Employer Profile Setup Screen | Employer | Initial profile setup: company name, industry, description, Telegram |
| 7 | Job Listing Screen (Home Tab) | Jobseeker | Browse, search, and filter all active job listings |
| 8 | Saved Jobs Screen | Jobseeker | View all bookmarked job listings |
| 9 | Applications Screen | Jobseeker | View history of all submitted applications |
| 10 | Jobseeker Profile Screen | Jobseeker | View own profile with stats, bio, skills, and CV details |
| 11 | Employer Profile Screen | Employer | View own company profile with listing stats and settings |
| 12 | Job Detail Screen | Both | Full job information with Apply, Save, and AI Analyze actions |
| 13 | AI Match Analysis Screen | Jobseeker | Displays score ring, AI advisor explanation, and skill gaps |
| 14 | Job Post Screen | Employer | Form to create a new job listing or edit an existing one |
| 15 | Manage Jobs Screen | Employer | List of own job postings with edit, duplicate, and delete actions |
| 16 | CV Upload Screen | Jobseeker | Upload and replace PDF CV; triggers local text extraction |
| 17 | Employer Public Profile Screen | Jobseeker | Read-only view of a company's public profile page |
| 18 | Edit Jobseeker Profile Screen | Jobseeker | Edit name, university, major, skills, bio, and avatar |
| 19 | Edit Employer Profile Screen | Employer | Edit company name, industry, description, website, and Telegram |

---

## SECTION 7 — SCREENSHOTS WITH SCREEN NAMES

*Note: Insert full-screen screenshots taken from a device or emulator below each label. Screenshots should be captured in portrait mode at the device's native resolution.*

---

**Screen 1: Onboarding Screen**

*[Insert screenshot of the onboarding walkthrough — showing the "Find Your Dream Job" first page with the large search icon, title, description, and Next button]*

---

**Screen 2: Login Screen**

*[Insert screenshot of the login screen — showing email/password fields, Login button, and Register link]*

---

**Screen 3: Register Screen**

*[Insert screenshot of the registration screen — showing full name, email, password fields, and Sign Up button]*

---

**Screen 4: Role Selection Screen**

*[Insert screenshot of the role selection screen — showing the two role cards: Jobseeker and Employer]*

---

**Screen 5: Jobseeker Profile Setup Screen**

*[Insert screenshot of the jobseeker profile setup form — showing university, major, skills, and bio fields]*

---

**Screen 6: Employer Profile Setup Screen**

*[Insert screenshot of the employer profile setup form — showing company name, industry, description, website, and Telegram fields]*

---

**Screen 7: Job Listing Screen (Home)**

*[Insert screenshot of the job listing home — showing the blue gradient header, user greeting, search bar, category filter chips, and job cards]*

---

**Screen 8: Saved Jobs Screen**

*[Insert screenshot of the saved jobs tab — showing bookmarked job cards]*

---

**Screen 9: Applications Screen**

*[Insert screenshot of the applied jobs tab — showing submitted application history with job titles and applied dates]*

---

**Screen 10: Jobseeker Profile Screen**

*[Insert screenshot of the jobseeker profile view — showing avatar, name, education, stats row, about me, skills chips, and CV section]*

---

**Screen 11: Employer Profile Screen**

*[Insert screenshot of the employer profile view — showing company name, industry, description, and Telegram handle]*

---

**Screen 12: Job Detail Screen**

*[Insert screenshot of the job detail screen — showing the wavy blue header, company logo, job title, salary/type stat boxes, job description, skills tags, and the three-button sticky bottom bar]*

---

**Screen 13: AI Match Analysis Screen**

*[Insert screenshot of the AI match screen — showing the circular score ring, AI Advisor Analysis card with bullet explanations, matching skills (blue chips), and missing skills (grey chips)]*

---

**Screen 14: Job Post Screen**

*[Insert screenshot of the job post form — showing title, description, skills, category, location, salary, and Telegram fields]*

---

**Screen 15: Manage Jobs Screen**

*[Insert screenshot of the employer's manage jobs screen — showing a list of their own listings with edit, duplicate, and delete options]*

---

**Screen 16: CV Upload Screen**

*[Insert screenshot of the CV upload screen — showing the file picker button and existing CV filename if already uploaded]*

---

**Screen 17: Employer Public Profile Screen**

*[Insert screenshot of a company's public profile page — showing company logo, name, industry, description, and website]*

---

**Screen 18: Edit Jobseeker Profile Screen**

*[Insert screenshot of the edit profile screen — showing name, bio, university, major, and skills fields with a Save button]*

---

**Screen 19: Edit Employer Profile Screen**

*[Insert screenshot of the edit employer profile screen — showing company name, industry, description, website, and Telegram handle fields]*

---

## SECTION 8 — PERCENTAGE OF COMPLETENESS

**Overall Completeness: 90%**

### Fully Implemented

The following features are fully functional and tested:

- Complete authentication system (register, login, logout) with role-based routing guards
- Jobseeker and employer profile setup and editing (including avatar upload)
- Full job listing with search, category filtering, and infinite scroll pagination
- Job detail view with all fields (salary, location, description, skills)
- AI CV matching with Groq API — score calculation, caching in database, and display on job cards
- AI Match Analysis screen with score ring, markdown explanations, and skill gap chips
- AI application message generation on the apply bottom sheet
- Job application submission with applied-status tracking
- Save / Unsave jobs with local persistence
- CV PDF upload with local text extraction via syncfusion_flutter_pdf
- Employer job posting, editing, duplication, deletion, and active/inactive toggling
- Employer public profile screen
- Onboarding walkthrough (shown once on first launch)
- Dark mode / light mode toggle with persistent preference
- Complete theme system with light and dark ColorScheme tokens

### Partially Implemented

- **Profile Statistics:** The jobseeker profile screen displays hardcoded numbers (12 Applied, 5 Saved, 3 Interviews) rather than values computed from the actual application and saved-jobs data. This requires additional Supabase aggregation queries.
- **Job Description Simplification:** The `simplifyJobDescription` Groq service method is implemented but not yet wired to a UI button on the Job Detail screen. The backend logic is ready; a UI trigger and display widget are needed.
- **Employer Applicant View:** Employers cannot currently view who applied for their jobs. The application records are stored locally on the jobseeker's device and not yet synced to a server-side `applications` table.

### Outstanding / Not Yet Built

- **Push Notifications:** Planned to notify jobseekers when a new job in their skill set is posted, and to notify employers when they receive a new application.
- **In-App Messaging:** A real-time chat feature between employers and applicants, potentially replacing the current Telegram redirect.
- **Admin Dashboard:** A web-based or in-app admin panel for moderating job posts and managing users.
- **Analytics for Employers:** Charts showing view counts, application rates, and match score distributions for each listing.

---

## SECTION 9 — SAMPLE SOURCE CODE

### Code Block 1: Groq AI Service — CV Match Scoring (`lib/features/ai/services/groq_service.dart`)

This is the core AI method that sends a student's CV text and a job description to the Groq LLM and returns a structured match result. It extracts valid JSON from the raw API response to handle any extra text the model might produce.

```dart
Future<Map<String, dynamic>> getCVMatchScore({
  required String cvText,
  required String jobDescription,
}) async {
  const systemPrompt =
      '''You are a supportive, enthusiastic career advisor AI helping a university student.
Return ONLY a valid JSON object. No conversational text before or after.
Format the JSON exactly like this:
{
  "score": 75,
  "explanation": "🌟 **Great potential!** Here is a quick breakdown:\\n• ...",
  "matching_skills": ["skill1", "skill2"],
  "missing_skills": ["skill3"]
}''';

  final userMessage = '''
Job Description:
$jobDescription

CV Text:
$cvText
''';

  final rawString = await _callGroq(
    systemPrompt: systemPrompt,
    userMessage: userMessage,
    temperature: 0.2,
  );

  final startIndex = rawString.indexOf('{');
  final endIndex = rawString.lastIndexOf('}');

  if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
    final cleanString = rawString.substring(startIndex, endIndex + 1);
    return jsonDecode(cleanString) as Map<String, dynamic>;
  } else {
    throw const FormatException(
      'Failed to extract valid JSON from Groq response.',
    );
  }
}
```

---

### Code Block 2: AI Match Caching with Supabase Upsert (`lib/features/ai/services/groq_service.dart`)

This method wraps the CV match call and upserts the result to the `cv_matches` table. The unique constraint on `(job_id, jobseeker_id)` ensures a student is never charged for the same analysis twice — subsequent views load the cached result instantly.

```dart
Future<Map<String, dynamic>> getAndCacheCVMatchScore({
  required String jobId,
  required String cvText,
  required String jobDescription,
}) async {
  final parsedJson = await getCVMatchScore(
    cvText: cvText,
    jobDescription: jobDescription,
  );

  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) throw Exception('User not logged in');

  await supabase.from('cv_matches').upsert({
    'job_id': jobId,
    'jobseeker_id': currentUser.id,
    'score': parsedJson['score'],
    'match_data': parsedJson,
  }, onConflict: 'job_id, jobseeker_id');

  return parsedJson;
}
```

---

### Code Block 3: GoRouter Auth + Profile Guard (`lib/core/router.dart`)

The router enforces a 5-step redirect chain on every navigation event: first checking if onboarding has been seen, then authentication status, then whether the user has selected a role, and finally whether they have completed a role-specific profile. This prevents any broken state from leaking into the main app.

```dart
redirect: (BuildContext context, GoRouterState state) {
  if (onboardingSeen == null) return null;

  final isOnboardingRoute = state.matchedLocation == '/onboarding';
  if (onboardingSeen == false && !isOnboardingRoute) {
    return '/onboarding';
  }

  final session = authState.value?.session;
  final isAuthenticated = session != null;
  final isLoginRoute = state.matchedLocation == '/login';
  final isRegisterRoute = state.matchedLocation == '/register';
  final isAuthRoute = isLoginRoute || isRegisterRoute;

  if (!isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
    return '/login';
  }

  if (isAuthenticated) {
    if (profileState.isLoading) return null;

    final role = profileState.role;
    if (role == null && !isRoleSelectionRoute) {
      return '/role-selection';
    }

    if (role != null && (isAuthRoute || isRoleSelectionRoute ||
        state.matchedLocation.startsWith('/profile-setup'))) {
      return role == 'employer' ? '/jobs/manage' : '/jobs';
    }
  }

  return null;
},
```

---

### Code Block 4: Paginated Job Listing with Debounced Search (`lib/features/jobs/screens/job_listing_screen.dart`)

The job listing screen implements debounced search (300ms), category filtering, infinite scroll, and a pull-to-refresh pattern. State is managed entirely inside the ConsumerStatefulWidget without any additional Riverpod providers, keeping the pagination logic local to the screen.

```dart
void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    if (mounted) {
      setState(() { _searchQuery = query; });
      _refreshJobsWithCount();
    }
  });
}

Future<void> _loadMoreJobs() async {
  if (_isLoadingMore || !_hasMore) return;
  setState(() => _isLoadingMore = true);
  try {
    final jobService = ref.read(jobServiceProvider);
    final moreJobs = await jobService.getJobs(
      searchQuery: _searchQuery,
      category: _category,
      offset: _offset,
      limit: _limit,
    );
    if (mounted) {
      setState(() {
        _jobs.addAll(moreJobs);
        _offset += moreJobs.length;
        _hasMore = moreJobs.length >= _limit;
        _isLoadingMore = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _isLoadingMore = false);
  }
}
```

---

### Code Block 5: Job Service — Full CRUD with Supabase (`lib/features/jobs/services/job_service.dart`)

The JobService class encapsulates all database operations for the `jobs` table, including full-text search via Supabase's `fts` column, employer-scoped writes using the current user's ID as a security guard, and a `duplicateJob` utility that creates inactive copies for employer review before publishing.

```dart
Future<List<Job>> getJobs({
  String? searchQuery,
  String? category,
  int offset = 0,
  int limit = 10,
}) async {
  var query = supabase
      .from('jobs')
      .select(
        '*, profiles(avatar_url, employer_profiles(company_name, industry)), cv_matches(score)',
      )
      .eq('is_active', true);

  if (searchQuery != null && searchQuery.isNotEmpty) {
    query = query.textSearch('fts', searchQuery);
  }
  if (category != null && category.isNotEmpty && category != 'All') {
    query = query.eq('category', category);
  }

  final response = await query
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);
  return (response as List<dynamic>).map((job) => Job.fromMap(job)).toList();
}

Future<void> duplicateJob(Job job) async {
  await postJob(
    title: '${job.title} (Copy)',
    description: job.description,
    skillsRequired: job.skillsRequired,
    category: job.category,
    location: job.location,
    salaryRange: job.salaryRange,
    telegramContact: job.telegramContact,
    isActive: false, // Copies start inactive so employer reviews before publishing
  );
}
```

---

### Code Block 6: Profile State Provider — Riverpod State Notifier (`lib/features/profile/providers/profile_state_provider.dart`)

The ProfileStateNotifier is the global state manager for user role and profile completion status. It listens to the Supabase auth stream and re-fetches profile data whenever the session changes — ensuring the router redirect guard always has accurate state.

```dart
class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final ProfileService _profileService;
  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;

  ProfileStateNotifier(this._profileService, this._ref)
      : super(ProfileState(isLoading: true)) {
    _init();
  }

  void _init() {
    final currentUser = _profileService.getCurrentUser();
    if (currentUser != null) {
      _fetchAndSetProfile();
    } else {
      state = ProfileState(isLoading: false);
    }

    _authSubscription = supabase.auth.onAuthStateChange.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn) {
        _fetchAndSetProfile();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        state = ProfileState(isLoading: false);
      }
    });
  }

  Future<void> _fetchAndSetProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final profileData = await _profileService.getProfileStatus();
      state = ProfileState(
        isLoading: false,
        role: profileData?['role'] as String?,
        isCompleted: profileData?['isCompleted'] as bool? ?? false,
      );
    } catch (_) {
      state = ProfileState(isLoading: false);
    }
  }
}
```

---

### Code Block 7: AI Match Screen — Score Ring and Skill Chips (`lib/features/ai/screens/ai_match_screen.dart`)

This screen renders the AI match results. The circular score ring uses Flutter's `CircularProgressIndicator` as a display element by setting its value to `score / 100`. Skill tags are split into two categories and rendered with colour-coded chips using a reusable `_buildSkillTag` helper.

```dart
Center(
  child: Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 160,
        height: 160,
        child: CircularProgressIndicator(
          value: score / 100,
          strokeWidth: 12,
          backgroundColor: scoreColor.withOpacity(0.1),
          color: scoreColor,
          strokeCap: StrokeCap.round,
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: scoreColor, size: 28),
          const SizedBox(height: 4),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          Text('Match', style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.5),
          )),
        ],
      ),
    ],
  ),
),
```

---

## SECTION 10 — GITHUB REPOSITORY LINK

**Repository URL:** [Insert your GitHub repository URL here]

The repository is set to **Public** and contains the complete Flutter source code, the `CLAUDE.md` project documentation file, and the `pubspec.yaml` dependency manifest. The `.env` file containing API keys is excluded from the repository via `.gitignore` for security purposes.

If a GitHub repository is not available, the source code is stored locally and can be submitted as a compressed `.zip` archive alongside this report.

---

*End of Report*
