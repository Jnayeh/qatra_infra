# Qatra Frontend - Angular Application

## Overview

Angular 20.3.x application using standalone components, modern Angular APIs (signals, computed, effect), NgRx Signal Store for state management, PrimeNG 20.4.0 + Tailwind CSS 4.3.1 for UI, MapLibre GL for maps, and Chart.js for analytics.

---

## Tech Stack

| Technology | Version | Purpose |
|---|---|---|
| Angular | 20.3.x | Framework (standalone components, OnPush) |
| NgRx Signals | 20.1.x | State management (signalStore) |
| PrimeNG | 20.4.0 | UI component library (custom "Qatra Aura" theme, red primary #cc0000) |
| Tailwind CSS | 4.3.1 | Utility-first CSS |
| PrimeIcons | 7.0.0 | Icon library |
| MapLibre GL JS | 5.24.0 | Interactive maps (RTL Arabic support) |
| Chart.js | 4.5.1 | Analytics dashboards |
| Zod | - | Schema validation (forms) |
| html5-qrcode | 2.3.8 | QR code scanning (camera-based) |
| PapaParse | 5.5.3 | CSV parsing/export |
| Inter font | - | Typography (Google Fonts) |

---

## Project Structure

```
src/app/
  core/
    auth/         -- AuthService, AuthStore, AuthInterceptor, Guards (auth, role)
    http/         -- ApiService, ErrorHandlerInterceptor, SocketService (WebSocket)
    geolocation/  -- GeolocationService (continuous GPS tracking)
  layouts/
    main-layout/  -- Sidebar + toolbar (admin/center staff portal)
    donor-layout/ -- Mobile-first donor portal shell
  shared/
    models/       -- 10 model files (User, Appointment, Center, Donor, Emergency, Notification, etc.)
    schemas/      -- 5 Zod schema files (auth, appointment, center, donor, emergency)
    utils/        -- 10 utility files (date, blood-type, geocoding, pagination, map, zod-to-validators)
    components/   -- 7 shared UI components
  features/
    landing/      -- Marketing landing page
    auth/         -- Login, Register, Forgot/Reset Password, Verify Email
    donor/        -- Dashboard, Profile, Onboarding, Health, Location, Availability, Impact, Certificates
    center/       -- CRUD, Dashboard, Slots, Staff, Analytics, Reports
    appointment/  -- Booking, Check-in (QR), Screening, Completion, Queue
    emergency/    -- Create, List, Detail, History
    notifications/-- Notification center + WebSocket store
    admin/        -- Dashboard, Users, Center Approval, Audit Logs, Config, GDPR, Health Restrictions
    staff/        -- Staff center analytics page
    contact/      -- Contact form
```

---

## Authentication Flow

### Auth Guard
- Checks AuthStore.isAuthenticated() or presence of localStorage.accessToken
- Redirects to `/` (landing) if not authenticated

### Role Guard
- Factory function: `roleGuard(...allowedRoles)` returns CanActivateFn
- Checks if user has at least one of the allowed roles
- Redirects to `/` if not authorized

### Auth Interceptor
- Attaches `Authorization: Bearer <token>` header to all requests
- On 401 error (not from refresh/login endpoints): auto-refreshes token using refresh token, then retries the original request

### Auth Store (NgRx Signal Store)
- State: user, accessToken, refreshToken, isAuthenticated, isLoading, error
- Persistence: localStorage for accessToken, refreshToken, and authUser JSON
- Role-based login: supports `intendedRole` parameter that maps roles to allowed role lists
- Computed signals: userRoles, isSuperAdmin, isCenterAdmin, isCenterStaff, isDonor
- Logout: calls API then clears localStorage and redirects to `/`

### Token Flow
1. User logs in -> API returns TokenPair (accessToken + refreshToken + roles + userId)
2. Tokens stored in localStorage
3. All subsequent HTTP requests carry Bearer token
4. On 401 -> interceptor auto-refreshes using refreshToken -> retries request
5. On refresh failure -> error propagates
6. Logout -> POST /api/v1/auth/logout -> clear localStorage -> redirect

---

## Routing Structure

```
/                                       -- LandingPageComponent (public)
/reset-password                         -- ResetPasswordPageComponent (public)
/verify-email                           -- VerifyEmailPageComponent (public)
/contact                                -- ContactPageComponent (public)
/auth/*                                 -- Lazy child routes (auth.routes.ts)

--- [authGuard protected] ---
/ (MainLayoutComponent)
  /center-management/*                  -- roleGuard('CENTER_ADMIN','CENTER_STAFF')
  /admin/*                              -- roleGuard('SUPER_ADMIN')

/donor/onboarding                       -- [authGuard] OnboardingPageComponent

--- [authGuard protected] ---
/ (DonorLayoutComponent)
  /donor/*                              -- roleGuard('DONOR')

/**                                     -- wildcard -> redirect to /
```

### Auth Routes
- `/auth/login` (intendedRole: DONOR)
- `/auth/center-login` (intendedRole: CENTER)
- `/auth/admin-login` (intendedRole: ADMIN)
- `/auth/register`
- `/auth/forgot-password` (+ center/admin variants)
- `/auth/reset-password` (+ center/admin variants)

### Center Management Routes
- Dashboard, Create, Manage, Slots, Staff, Activity Log, Analytics, Reports
- Appointments: List, Queue, Check-in (QR), Screening, Completion, Reschedule
- Emergencies: List, Create, Detail, History
- Notifications

### Admin Routes
- Dashboard, Users, User Detail, Centers, Audit Logs, Deletion Requests, Health Restrictions, Notifications

### Donor Routes
- Home, Profile, Health Questionnaire, Blood Type, Location, Availability, Notification Prefs, Impact, Certificates, Notifications
- My Appointments, Book, Donation History, Reschedule
- Emergencies: List, Detail
- Centers: List, Detail, Book

---

## Components

### Layouts

| Component | Purpose |
|---|---|
| MainLayoutComponent | Sidebar + toolbar shell for Center Staff/Admin and Super Admin portals |
| SidebarComponent | Role-filtered navigation sidebar (16 nav items, dynamically filtered by activeRole) |
| ToolbarComponent | Top bar with dynamic page title, user menu, notification bell |
| DonorLayoutComponent | Mobile-first donor portal with top nav, notification bell, profile-incomplete banner, email verification banner, bottom tab bar |

### Auth Components

| Component | Purpose |
|---|---|
| LoginPageComponent | Multi-portal login (Donor, Center, Super Admin) via intendedRole route data, distinct visual theme per portal |
| RegisterPageComponent | Donor registration (firstName, familyName, email, phone, password, confirmPassword) |
| ForgotPasswordPageComponent | Multi-portal forgot password, themed per intendedRole |
| ResetPasswordPageComponent | Multi-portal password reset with token from query params |
| VerifyEmailPageComponent | Auto-verifies email using token query param |

### Donor Components

| Component | Purpose |
|---|---|
| DonorDashboardPageComponent | Home dashboard with profile completion checklist, availability status, eligibility info, next milestone, greeting by time of day |
| OnboardingPageComponent | 3-step wizard: Blood type -> Health questionnaire + Location picker (MapLibre GPS) -> Notification preferences |
| Profile, Blood Type, Location, Availability, Notification Prefs, Health Questionnaire, Impact, Certificates | Self-service pages |

### Center Components

| Component | Purpose |
|---|---|
| CenterDashboardPageComponent | Dynamic dashboard: imports AdminCenterOverviewComponent or StaffCenterOverviewComponent based on role |
| AdminCenterOverviewComponent | Admin center overview with Chart.js bar chart (appointments by day) and pie chart (regular vs emergency) |
| StaffCenterOverviewComponent | Grid of 5 quick-link cards: Dashboard, Queue, Check-In, Emergencies, Today's Schedule |
| CenterCreatePageComponent | Form with LocationPickerComponent (MapLibre map) for center creation |

### Appointment Components

| Component | Purpose |
|---|---|
| StaffDashboardPageComponent | Today's donations, ml collected, active emergencies, current appointment queue |
| StaffQueuePageComponent | Real-time appointment queue with date filtering |
| CheckinPageComponent | QR code check-in using html5-qrcode (camera-based) or manual appointment ID entry |
| ScreeningPageComponent | Health screening form (temperature, hemoglobin, blood pressure, weight, eligibility) with Zod validation |
| AppointmentBookingPageComponent | Book appointment at a center slot |
| DonorAppointmentsPageComponent | View donor's own appointments with cancel/reschedule/QR view actions |
| CompletionPageComponent | Mark appointment as completed with outcome (COMPLETED/CANCELLED), ml collected, notes |
| DonationHistoryPageComponent | View past donation history |

### Emergency Components

| Component | Purpose |
|---|---|
| EmergencyCreatePageComponent | Create blood emergency request (blood type, units, urgency, contact phone, match radius) |
| EmergencyListPageComponent | List all emergencies with pagination |
| EmergencyDetailPageComponent | View emergency detail, donor responses, accept/decline |
| EmergencyHistoryPageComponent | View historical emergencies |

### Admin Components

| Component | Purpose |
|---|---|
| DashboardPageComponent | Admin dashboard with Chart.js bar chart (total metrics) and doughnut chart (completion rate) |
| UserManagementPageComponent | CRUD for users with status/role management |
| CenterApprovalPageComponent | Approve/reject center registrations |
| AuditLogsPageComponent | View audit logs with CSV export |
| HealthRestrictionPageComponent | Manage donor health restrictions |
| SystemHealthPageComponent | View system health (services, DB pool, API usage) |
| ConfigPageComponent | System configuration management |
| ReportsPageComponent | System-wide reports |
| DeletionRequestsPageComponent | GDPR data deletion requests |

### Notification Components

| Component | Purpose |
|---|---|
| NotificationCenterPageComponent | Full notification center page |
| NotificationBellComponent | Dropdown notification bell with unread count badge, recent 5 notifications, mark-all-read, click-to-navigate |

### Other Components

| Component | Purpose |
|---|---|
| LandingPageComponent | Animated stats counter (IntersectionObserver), 3 value proposition cards, 3 how-it-works steps, live emergency feed, testimonial carousel, MapLibre map with center markers (auto-centers on user GPS), CTA section, footer |
| ContactPageComponent | Contact form (name, email, org, subject dropdown, message) |
| StaffCenterAnalyticsPageComponent | Center analytics with custom canvas-rendered bar charts |

### Shared UI Components

| Component | Purpose |
|---|---|
| StatusBadgeComponent | Color-coded status pill (auto-maps status strings to Tailwind color classes) |
| LoadingSpinnerComponent | PrimeNG ProgressSpinner wrapper |
| EmptyStateComponent | Empty state placeholder with icon, title, message, optional action button |
| PublicNavbarComponent | Sticky top navbar for public/auth pages (login/signup or user dropdown) |
| LocationPickerComponent | Interactive MapLibre GL map with click-to-place-marker, GPS toggle, reverse geocoding (Nominatim), city/country auto-fill |
| AppointmentCardComponent | Appointment display card with status badge, date, type, action buttons |

---

## Services

### Core Services

**ApiService**: Base HTTP client wrapper with `environment.baseUrl` (default `http://localhost:5090`). Methods: get, getPage, post, put, patch, delete. All return Observable<ApiResponse<T>>.

**AuthService**: register, login, verifyEmail, forgotPassword, resetPassword, refreshToken, logout, changePassword, requestVerification

**SocketService**: WebSocket client connecting to `ws://localhost:5090/ws/notifications?token=<JWT>`. Auto-reconnects after 5 seconds. Listener pattern with subscribe/unsubscribe.

**GeolocationService**: Continuous GPS tracking for donors every 5 minutes. Only tracks if authenticated + isDonor + tracking preference enabled. Uses Haversine formula to skip updates if moved < 100 meters. Auto-updates donor location via DonorService.updateLocation().

### Feature Services

**DonorService**: getMyProfile, updateMyProfile, updateBloodType, updateLocation, updateAvailability, updateNotificationPrefs, getHealthQuestionnaire, updateHealthQuestionnaire, getEligibility, getImpact, getCertificates, requestAccountDeletion

**AppointmentService**: create, getList, getDetail, reschedule, cancel, checkIn, markNoShow, addScreening, complete, getMyAppointments, getMyDonations, getQueue

**CenterService**: getCenters, getPublicCenters, getCenter, createCenter, updateCenter, updateCenterStatus, getSlots, blockSlot, addClosure, getPendingCenters, approveCenter, getStaff, addStaff, removeStaff, getMyStaffProfile, getMyAdminProfile, getReport

**EmergencyService**: create, getList, getDetail, escalate, cancelEmergency, resolve, getResponses, accept, decline

**NotificationService**: getNotifications, markAsRead, markAllAsRead, getUnreadCount

**AdminService**: getMetrics, getUsers, getUser, updateUserStatus, updateUser, assignRole, revokeRole, deleteUser, createUser, getAuditLogs, exportAuditLogs, getDeletionRequests, processDeletionRequest, overrideRestriction, getRestrictedDonors, getCenterMetrics, getConfig, getReports, getSystemHealth

---

## State Management (NgRx Signal Stores)

| Store | Purpose |
|---|---|
| AuthStore | Authentication state, user roles, login/register/logout/refresh tokens |
| DonorStore | Donor profile, health questionnaire, eligibility, impact, certificates |
| AppointmentStore | Donor's appointments (my list, book, cancel). Computed: upcoming/past/cancelled |
| StaffStore | Staff/admin profile, center info, appointment queue |
| CenterStore | Centers list, selected center, slots |
| EmergencyStore | Emergencies list, selected emergency, pagination |
| NotificationStore | Notifications list, unread count, WebSocket integration |

All stores use signalStore() with withState(), withComputed(), withMethods(), and withHooks(). All are providedIn: 'root' (singleton global state).

---

## Models/Interfaces

| Model | Key Types/Interfaces |
|---|---|
| user.model.ts | UserStatus (6 states), Role (4 roles), User, UserSummary, UserDetail, RegisterRequest, LoginRequest, TokenPair |
| api-response.model.ts | ApiResponse<T>, Paginated |
| appointment.model.ts | AppointmentStatus (7 states), AppointmentType, DonationOutcome, Appointment (22 fields), HealthScreening, CompletionRequest |
| center.model.ts | FacilityType (5 values), CenterStatus (4 values), BloodDonationCenter, Slot (11 fields), ClosureRequest, StaffProfile |
| donor.model.ts | BloodType (9 values), AvailabilityStatus (4 values), DonorStatus (4 values), NotificationFrequency (4 values), DonorProfile (18 fields), ImpactSummary, HealthQuestionnaire (9 fields), Certificate, EligibilityStatus |
| emergency.model.ts | EmergencyUrgency (4 values), EmergencyStatus (4 values), ResponseStatus, Emergency (13 fields), DonorResponseDTO |
| notification.model.ts | NotificationType (7 values), NotificationChannel (3 values), NotificationStatus (5 values), Notification (12 fields) |
| config.model.ts | DataDeletionRequest, SystemConfigEntry |
| analytics.model.ts | AuditLogEntry, MetricsResponse, CenterMetrics (with DayCount[] charts), RestrictedUser, SystemHealth |
| operating-hours.model.ts | DaySchedule, ClosureWindow, OperatingHours |

---

## Validation Schemas (Zod)

| Schema | Purpose |
|---|---|
| LoginSchema | email + password (min 8 chars) |
| RegisterSchema | email, phone, password, confirmPassword, displayName, role=literal('DONOR'). Refined: passwords must match |
| ForgotPasswordSchema | email |
| ResetPasswordSchema | token, newPassword, confirmPassword. Refined: match |
| AppointmentBookingSchema | type, donorId, slotId, optional emergencyId |
| ScreeningSchema | temperature (34-42), hemoglobin (5-20), weight (30-200), bloodPressure (regex), eligible, optional notes |
| CompletionSchema | outcome, mlCollected (min 1), optional notes |
| CenterCreateSchema | Full center creation with OperatingHours, facilityType, lat/lng, capacity |
| OperatingHoursSchema | 7 day schedules (HH:mm format) + closedWindows array |
| BloodTypeSchema | 9 blood types |
| UpdateDonorProfileSchema | displayName, phone |
| HealthQuestionnaireSchema | chronic illness, surgery/travel/tattoo dates, medication |
| NotificationPreferencesSchema | frequency, quietHours, emergency flag, maxDistance |
| EmergencyCreateSchema | centerId, bloodType, units, urgency, phone, matchRadius |
| EmergencyRespondSchema | ACCEPTED/DECLINED + optional slotId |

### Zod-to-Angular Bridge
- `formControlFor(schema)`: creates Angular FormControl with validators derived from Zod schema
- `zodToFormGroup(shape)`: creates FormGroup from a Zod object shape
- Converts ZodString.min/max to Validators.minLength/maxLength, ZodNumber.min/max to Validators.min/max

---

## Utilities

| Utility | Purpose |
|---|---|
| date-utils.ts | nowUTC(), todayUTC(), formatDateTime(), formatDate(), formatTime(), isAfterNowUTC(), isBeforeNowUTC(), daysFromNow(), addDays(), diffInDays(), parseHHmm() |
| blood-type-utils.ts | BLOOD_TYPE_NAMES map, BLOOD_TYPE_COMPATIBILITY map, canDonateTo(), isRareBloodType(), formatBloodType() |
| geocoding.ts | reverseGeocode(lat, lng) via Nominatim OpenStreetMap API with 1.1s rate limiting |
| pagination-utils.ts | Signal-based pagination state factory |
| map-init.ts | MapLibre GL initialization with RTL text plugin support (Arabic) |

---

## Build & Deployment

### Environment Setup Script (scripts/set-env.js)
- Reads .env file (key=value format), falls back to process.env variables
- Generates both environment.ts and environment.prod.ts with baseUrl and wsBaseUrl

### npm Scripts
| Script | Command |
|---|---|
| start | `node scripts/set-env.js && ng serve` |
| build | `node scripts/set-env.js && ng build` |
| build:prod | `node scripts/set-env.js && ng build --configuration production` |
| test | `ng test` |

### Angular Build Config
- Builder: @angular/build:application
- Browser entry: src/main.ts
- Polyfills: zone.js
- Global styles: styles.css + maplibre-gl.css
- Assets: public/ directory (favicon.ico, blood-qatra.svg, 1-3.webp)
- Production: file replacements, budget warnings (600kB warn / 1MB error), output hashing

### CI Pipeline (.github/workflows/ci.yml)
- Trigger: Pull requests to master or qatra-pp branches
- Node.js 24, npm ci, ng test --browsers ChromeHeadless --watch=false

### Deployment Pipeline (.github/workflows/deploy.yml)
- Trigger: Push to master
- Steps: Node.js 24 + npm ci -> npm run build:prod with secret env vars -> SCP dist files to server at /var/www/qatra -> SSH to run nginx -t && systemctl reload nginx

---

## Additional Details

- **TypeScript**: Strict mode enabled, path alias `@/*` maps to `src/*`, ES2022 target
- **Component Architecture**: All standalone (no NgModules), all OnPush change detection
- **Modern Angular**: input(), output(), viewChild(), signal(), computed(), effect(), inject()
- **Map Integration**: MapLibre GL with RTL text plugin for Arabic, OpenFreeMap tile style
- **QR Code**: html5-qrcode library for camera-based QR scanning (appointment check-in)
- **Charts**: Chart.js 4.5.1 for analytics dashboards (admin, center admin, staff)
- **CSV Export**: PapaParse for audit logs export
- **Prettier**: 100 char print width, single quotes, Angular HTML parser
