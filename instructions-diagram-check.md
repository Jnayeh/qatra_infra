# USE CASES:
````

1. DONOR
Authentication & Onboarding
UC-D01 Register with email or phone

UC-D02 Verify email address

UC-D03 Login

UC-D04 Logout

UC-D05 Reset password

UC-D06 Complete health profile & questionnaire

UC-D07 Set blood type (or mark unknown)

UC-D08 Set notification preferences (including quiet hours via JSON)

UC-D09 Set location (manual or GPS)

UC-D10 Set availability status

UC-D11 Request account deletion (GDPR)

Profile Management
UC-D12 View donor dashboard

UC-D13 Update personal information

UC-D14 Update health questionnaire

UC-D15 Update location & availability

UC-D16 View eligibility status & next eligible date

UC-D17 View reliability score

UC-D18 View impact dashboard (lives saved, milestones)

UC-D19 Download donation certificates

Emergency Response
UC-D20 Receive emergency notification

UC-D21 View emergency details (center, distance, blood type, urgency)

UC-D22 Accept emergency request

UC-D23 Decline emergency request (with optional reason)

Appointment Management
UC-D24 Browse nearby donation centers

UC-D25 View center details and operating hours

UC-D26 Schedule appointment (regular or emergency)

UC-D27 Reschedule or cancel appointment

UC-D28 Check in at donation center (QR scan â†’ staff views appointment details, or staff selects from list)

UC-D29 View appointment & donation history

UC-D30 Receive appointment & eligibility reminders

2. CENTER STAFF
Authentication
UC-CS01 Login, logout & reset password

Emergency Management
UC-CS02 Create emergency (blood type, units, urgency, deadline)

UC-CS03 Track emergency progress (escalate, extend, cancel)

UC-CS04 Resolve emergency

UC-CS05 View emergency history

Appointment & Donor Operations
UC-CS06 View daily schedule & own task queue

UC-CS07 Check in donor on arrival (QR scan shows appointment details; otherwise select from list)

UC-CS08 View donor eligibility & health profile

UC-CS09 Conduct & record health screening

UC-CS10 Complete appointment (record ml collected)

UC-CS11 Mark donor as no-show

3. CENTER ADMIN
Authentication
UC-CA01 Login, logout & reset password

Center Management
UC-CA02 Submit center registration request (approved by super admin)

UC-CA03 Update center info (address, hours, contact)

UC-CA04 Configure Center capacity & appointment slots

UC-CA05 Set special closures & operating hour exceptions

Staff Management
UC-CA06 Add or remove center staff

UC-CA07 View staff activity log

Reporting & Oversight

UC-CA09 View analytics (trends, peak hours, blood type inventory)

UC-CA10 Generate & export center report

4. SUPER ADMIN
Authentication
UC-SA01 Login, logout & reset password

User Management
UC-SA02 View, search & filter all users

UC-SA03 Activate, suspend or delete accounts

UC-SA04 Approve or reject center registration requests

UC-SA05 Assign & revoke roles

UC-SA06 Process GDPR data deletion requests

UC-SA07 Review & override permanent health restrictions



Monitoring & Reporting
UC-SA10 View system dashboard (emergencies, response rates, donor stats)

UC-SA11 Monitor system health (services, error logs, API usage)

UC-SA12 View & export audit logs

UC-SA13 Generate platform reports

5. SYSTEM (Automated)
Authentication & Sessions
UC-SYS01 Issue, refresh & expire sessions

UC-SYS02 Issue & expire verification tokens

Matching Engine
UC-SYS03 Scan & filter eligible donors on emergency creation

UC-SYS04 Score & rank matched donors (reliability, distance, history)

UC-SYS05 Execute tiered matching & escalate radius if needed

Notification Engine
UC-SYS06 Send emergency alert (channel routing, quiet hours, frequency limits)

UC-SYS07 Track delivery & retry failed notifications

UC-SYS08 Send appointment, eligibility & profile nudge reminders

Eligibility Management
UC-SYS09 Mark ineligible after donation & set eligible-from date

UC-SYS10 Auto-restore eligibility when cooldown passes

UC-SYS11 Flag permanent restrictions from health questionnaire

Reliability Scoring
UC-SYS12 Adjust reliability score (0â€“100) on donation completed, no-show, or repeated emergency declines while available

Three consecutive declines with no accept in between â†’ soft flag for manual review

Accept resets the consecutive decline counter

Declining alone carries no penalty

Slot Management
UC-SYS13 Release, block or free slots automatically

UC-SYS14 Expire unresolved emergencies past deadline

Analytics
UC-SYS15 Record real-time metrics & run batch analytics

UC-SYS16 Forecast blood type demand by region

UC-SYS17 Generate audit log on every state-changing action


````
# CLASS DIAGRAM:
````
---
config:
  layout: elk
---
classDiagram
direction LR
class User {
+Long id
+String email
+boolean emailVerified
+String phone
+String hashedPassword
+String displayName
+String firstName
+String familyName
+UserStatus status
+Instant createdAt
+Instant lastActiveAt
+Instant deletedAt
+Instant deletionRequestedAt
+verifyEmail()

    }
    class UserStatus {
		<<enumeration>>
	    ACTIVE
	    INACTIVE
	    SUSPENDED
	    PENDING_VERIFICATION
		PENDING_DELETION
	    DELETED
    }

    class UserRole {
	    +Long id
	    +Long userId
	    +Role role
	    +Instant assignedAt
    }

    class Role {
		<<enumeration>>
	    SUPER_ADMIN
	    CENTER_ADMIN
	    CENTER_STAFF
	    DONOR
    }

    class Session {
	    +Long id
	    +Long userId
	    +String accessTokenHash
	    +String refreshTokenHash
	    +String ipAddress
	    +String userAgent
	    +Instant expiresAt
	    +Instant createdAt
	    +validate()
	    +refresh()
	    +revoke()
    }

    class VerificationToken {
	    +Long id
	    +Long userId
	    +String tokenHash
	    +VerificationTokenType type
	    +Instant expiresAt
	    +Instant createdAt
	    +validate()
	    +consume()
    }

    class VerificationTokenType {
		<<enumeration>>
	    EMAIL_VERIFICATION
	    PASSWORD_RESET
    }
	class GDPRDeletionRequest {
		+Long id
		+Long userId
		+String reason
		+GDPRDeletionStatus status
		+Instant requestedAt
		+Instant processedAt
		+complete()
	}

	class GDPRDeletionStatus {
		<<enumeration>>
		IN_PROGRESS
		CANCELED
		COMPLETED
	}

    class AuditLog {
	    +Long id
	    +Long userId
	    +String action
	    +String entityType
	    +Long entityId
	    +JSON oldValue
	    +JSON newValue
	    +String ipAddress
	    +Instant timestamp
    }

    class DonorProfile {
	    +Long id
	    +Long userId
	    +BloodType bloodType
	    +Boolean bloodTypeVerified
	    +Boolean profileComplete
    	+DonorStatus status
	    +Double latitude
	    +Double longitude
	    +String city
	    +AvailabilityStatus availability
	    +LocalDate lastDonationDate
	    +LocalDate eligibleFromDate
	    +NotificationPreferences notificationPreferences
	    +Boolean allowEmergencyNotifications
	    +Integer consecutiveEmergencyDeclines
	    +Boolean flaggedForManualReview
	    +Boolean permanentlyRestricted
	    +String restrictionReason
	    +Double reliabilityScore
    	+int totalDonations
	    +Instant createdAt
	    +Instant updatedAt
	    +Instant lastAcceptAt
        +Instant deletedAt
        +Instant deletionRequestedAt
	    +canDonate()
	    +calculateEligibility()
	    +updateLocation()
	    +resetConsecutiveDeclinesOnAccept()
    }

	class QuietHours {
		+LocalTime start
		+LocalTime end
	}
    class NotificationFrequency {
		<<enumeration>>
	    IMMEDIATE
	    DAILY_DIGEST
	    EMERGENCY_ONLY
	    DISABLED
    }

	class NotificationPreferences {
		+NotificationFrequency frequency
		+QuietHours quietHours
		+boolean allowEmergencyNotifications
		+int maxNotificationDistanceKm
		+isQuietNow() boolean
	}

    class BloodType {
		<<enumeration>>
	    A_POSITIVE
	    A_NEGATIVE
	    B_POSITIVE
	    B_NEGATIVE
	    AB_POSITIVE
	    AB_NEGATIVE
	    O_POSITIVE
	    O_NEGATIVE
	    UNKNOWN
    }
    
	class DonorStatus {
		<<enumeration>>
		ACTIVE
		PENDING_DELETION
		INACTIVE
		DELETED
	}
    
	class AvailabilityStatus {
		<<enumeration>>
	    AVAILABLE
	    TEMPORARILY_UNAVAILABLE
	    VACATION_MODE
	    PERMANENTLY_RESTRICTED
    }
    
    class HealthQuestionnaire {
	    +Long id
	    +Long donorId
	    +Boolean hasChronicIllness
	    +Instant lastSurgeryAt
	    +Instant lastTravelAt
	    +Instant lastTattooOrPiercingAt
	    +Boolean onMedication
		+String medicalConditionsDetails
		+String medicationDetails
	    +Instant createdAt
	    +Instant updatedAt
    }

    class CenterStaffProfile {
	    +Long id
	    +Long userId
	    +Long centerId
	    +Boolean verified
	    +Instant createdAt
    }

    class CenterAdminProfile {
	    +Long id
	    +Long userId
	    +Long centerId
	    +Instant createdAt
    }

    class DonationCenter {
	    +Long id
	    +Long createdByUserId
	    +String name
	    +Double latitude
	    +Double longitude
	    +String address
	    +String city
	    +String country
	    +String postalCode
	    +String phone
	    +String email
	    +OperatingHours operatingHours
	    +Integer totalCapacity
	    +Integer maxRegular
	    +Integer slotPeriod
	    +FacilityType facilityType
	    +CenterStatus status
	    +Instant createdAt
    	+Instant updatedAt
	    +isOperatingNow()
	    +getAvailableSlots()
    }
	class OperatingHours {
		+DaySchedule monday
		+DaySchedule tuesday
		+DaySchedule wednesday
		+DaySchedule thursday
		+DaySchedule friday
		+DaySchedule saturday
		+DaySchedule sunday
		+List~ClosureWindow~ closedWindows
	}

	class DaySchedule {
		+LocalTime opens
		+LocalTime closes
	}
	class ClosureWindow {
		+LocalDate date
		+LocalTime startTime
		+LocalTime endTime
		+boolean allDay
		+String reason
	}
	 
    class CenterStatus {
		<<enumeration>>
	    PENDING_APPROVAL
	    ACTIVE
	    SUSPENDED
	    CLOSED
    }
	
    class FacilityType {
		<<enumeration>>
	    HOSPITAL
	    BLOOD_BANK
	    MOBILE_UNIT
	    COMMUNITY_CENTER
	    CLINIC
    }

    class Slot {
	    +Long id
	    +Long centerId
	    +LocalDate date
	    +LocalTime startTime
	    +LocalTime endTime
	    +Integer maxBookings
	    +Integer maxRegularBookings
	    +Integer bookedCount
	    +Integer regularBookedCount
	    +Boolean isBlocked
	    +Instant createdAt
	    +isAvailable()
    	+isAvailableForRegular() boolean
    }

    class Appointment {
	    +Long id
	    +Long slotId
	    +Long donorId
	    +Long centerId
	    +Long emergencyId
	    +Long completedByStaffId
	    +AppointmentStatus status
	    +AppointmentType appointmentType
	    +BloodType bloodType
	    +Integer mlCollected
	    +String notes
	    +String qrCode
	    +Instant createdAt
    	+Instant updatedAt
	    +Instant checkedInAt
    	+Instant startedAt
	    +Instant completedAt
	    +Instant cancelledAt
	    +String cancellationReason
    	+DonationOutcome outcome
		+checkIn()
		+startScreening()
	    +complete()
	    +cancel()
	    +reschedule()
    }

    class AppointmentStatus {
		<<enumeration>>
	    SCHEDULED
	    CHECKED_IN
		IN_SCREENING
	    COMPLETED
	    CANCELLED
	    NO_SHOW
	    RESCHEDULED
    }

    class AppointmentType {
		<<enumeration>>
	    REGULAR
	    EMERGENCY
    }
	class DonationOutcome {
		<<enumeration>>
		COMPLETED
		CANCELLED
	}
    class HealthScreening {
	    +Long id
	    +Long appointmentId
	    +Long donorId
		+Double weight
		+String bloodPressure
		+Double hemoglobin
	    +Long   screenedByStaffId
	    +Double temperature
	    +String notes
    	+Boolean eligible
	    +Instant screenedAt
    }

    class EmergencyRequest {
	    +Long id
	    +Long centerId
	    +Long createdByStaffId
	    +BloodType bloodType
	    +Integer unitsNeeded
	    +EmergencyUrgency urgency
	    +String contactPhone
	    +EmergencyStatus status
	    +Integer matchRadius
	    +Integer escalationLevel
	    +Instant expiresAt
	    +Instant createdAt
	    +Instant updatedAt
	    +Instant resolvedAt
	    +Long resolvedByUserId
	    +matchDonors()
	    +updateStatus()
	    +resolve()
		+cancel()
		+fulfill()
    }

    class MatchResult {
	    +Long id
	    +Long emergencyId
	    +Long centerId
	    +Long donorId
	    +Long radius
	    +MatchStatus status
	    +BloodType bloodType
	    +Integer escalationLevel
	    +Instant createdAt
	    +Instant respondedAt
    }

	class MatchStatus {
		<<enumeration>>
		PENDING
		RESPONDED
		EXPIRED
	}
	
	class EmergencyUrgency {
		<<enumeration>>
		CRITICAL
		HIGH
		MEDIUM
		LOW
	}

    class EmergencyStatus {
		<<enumeration>>
	    OPEN
		FULFILLED
		CANCELLED
		EXPIRED
    }

	class DonorResponse {
		+Long id
		+Long emergencyId
		+Long donorId
		+Long slotId
		+ResponseStatus status
		+String reason
		+Instant respondedAt
		+accept(Long slotId)
		+decline()
	}


	class ResponseStatus {
		<<enumeration>>
		ACCEPTED
		DECLINED
	}

    class Notification {
	    +Long id
	    +Long userId
	    +Long emergencyId
	    +Long appointmentId
	    +String email
	    +NotificationType type
	    +String title
	    +String body
	    +JSON data
    	+String correlationId
	    +NotificationChannel channel
	    +NotificationStatus status
	    +Instant createdAt
	    +Instant sentAt
	    +Instant readAt
		+markSent()
		+markRead()
		+markFailed()
    }
    class NotificationType {
		<<enumeration>>
	    EMERGENCY_ALERT
	    APPOINTMENT_REMINDER
	    ELIGIBILITY_REMINDER
	    PROFILE_COMPLETION
	    PASSWORD_RESET
	    GENERAL
    }

    class NotificationChannel {
		<<enumeration>>
	    IN_APP
	    PUSH
	    EMAIL
    }
	

    class NotificationStatus {
		<<enumeration>>
	    PENDING
	    SENT
	    DELIVERED
	    READ
	    FAILED
    }


    User "1" -- "*" Session : has
    User "1" -- "*" VerificationToken : has
    User "1" -- "*" UserRole : has
    User "1" -- "*" AuditLog : generates
    User "1" *-- "0..1" DonorProfile : has
    User "1" *-- "0..1" CenterStaffProfile : has
    User "1" *-- "0..1" CenterAdminProfile : has
    User "1" -- "0..1" GDPRDeletionRequest : requests
    DonorProfile "1" *-- "0..1" HealthQuestionnaire : has
    DonorProfile "1" -- "*" Appointment : makes
    DonorProfile "1" -- "*" DonorResponse : sends
    CenterStaffProfile "*" -- "1" DonationCenter : belongs to
    CenterStaffProfile "1" -- "*" EmergencyRequest : creates
    CenterStaffProfile "1" -- "*" Appointment : manages
    CenterAdminProfile "*" -- "1" DonationCenter : manages
    DonationCenter "1" -- "*" EmergencyRequest : handles
    DonationCenter "1" -- "*" Slot : offers
    Slot "1" -- "*" Appointment : fills
    Appointment "1" -- "0..1" HealthScreening : has
    EmergencyRequest "0..1" -- "*" Appointment : results in
    EmergencyRequest "1" *-- "*" MatchResult : triggers
    EmergencyRequest "0..1" -- "*" Notification : triggers
````

USER FLOWS:

**Donor Registration & Onboarding Flow**
â”ƒ - User signs up via email/phone, creating a `User` record in `PENDING_VERIFICATION` status and creating a `DonorProfile` in INACTIVE status.
â”ƒ - System generates an `EMAIL_VERIFICATION` token and sends a notification.
â”ƒ - User verifies email, transitioning `User` and `DonorProfile` status to `ACTIVE`.
â”ƒ - User completes their health profile, creating a `HealthQuestionnaire` and setting blood type/location.
â”ƒ - System checks the questionnaire; if safe, marks `DonorProfile.profileComplete` as true.

**Donor Scheduling Flow**
â”ƒ - Donor browses nearby `DonationCenter`s and views available `Slot`s.
â”ƒ - Donor books a slot, creating an `Appointment` in `SCHEDULED` status,  of type `REGULAR`,  and incrementing the `Slot.bookedCount` and the `Slot.regularBookedCount`.
â”ƒ - System schedules automated `APPOINTMENT_REMINDER` notifications based on the donor's `NotificationPreferences`.
â”ƒ - On arrival, staff scans the QR code or selects the donor, calling `Appointment.checkIn()` to set status to `CHECKED_IN`.
â”ƒ - Staff conducts a `HealthScreening`, calling `Appointment.startScreening()`.
â”ƒ - Staff records the volume drawn, calling `Appointment.complete()` which sets status to `COMPLETED`.
â”ƒ - System automatically recalculates the donor's `reliabilityScore`, increments `totalDonations`, and sets `eligibleFromDate` (e.g., 56 days out), temporarily making `canDonate()` false.

**Emergency Creation & Matching Flow**
â”ƒ - Staff creates an `EmergencyRequest` with required blood type, units, and urgency.
â”ƒ - System scans for `DonorProfile`s where blood type matches, `canDonate()` is true, and location is within the initial `matchRadius`, and is active.
â”ƒ - System scores and ranks donors by reliability and distance, creating `MatchResult` records.
â”ƒ - System generates `EMERGENCY_ALERT` notifications for matched donors, respecting `quietHours` and routing rules.
â”ƒ - Donor views alert and submits a `DonorResponse` (accept or decline).
â”ƒ - If accepted, system links a `Slot`, creates an `Appointment` of type `EMERGENCY`, and resets the donor's `consecutiveEmergencyDeclines` counter.
â”ƒ - If declined, system increments the decline counter; if it hits 3 consecutively, system sets `flaggedForManualReview` to true.

**Emergency Escalation & Resolution Flow**
â”ƒ - System monitors the emergency deadline and fulfilled unit count.
â”ƒ - If units are not met within a set timeframe (e.g., 30 mins), system increments `escalationLevel` and widens the `matchRadius`.
â”ƒ - System runs the matching engine again for the new radius, skipping donors with existing `MatchResult`s for this emergency.
â”ƒ - If staff manually fulfills the request or enough appointments are completed, system calls `EmergencyRequest.resolve()`, setting status to `FULFILLED`.
â”ƒ - If the deadline passes without enough units, system automatically sets status to `EXPIRED`.

**Staff No-Show & Penalty Flow**
â”ƒ - If a scheduled appointment time passes without a `checkIn()`, staff marks it as a `NO_SHOW`.
â”ƒ - System detects the `NO_SHOW` status and deducts points from the donor's `reliabilityScore`.

**Center Registration & Admin Approval Flow**
â”ƒ - User with `CENTER_ADMIN` role submits a `DonationCenter` registration, setting status to `PENDING_APPROVAL`.
â”ƒ - Super Admin views pending requests and approves, changing center status to `ACTIVE`.
â”ƒ - Center Admin configures `OperatingHours`, `Slot` generation rules, and adds `CENTER_STAFF` users.

**GDPR Account Deletion Flow**
â”ƒ - Donor requests deletion, creating a `GDPRDeletionRequest` in `IN_PROGRESS`.
â”ƒ - System automatically changes DonorProfile status to `PENDING_DELETION` and sets `User.status` to `PENDING_DELETION`, and logs the actions in `AuditLog`.
â”ƒ - After 30 days, system anonymizes PII in `User` and `DonorProfile`, sets status to `DELETED`, sets `GDPRDeletionRequest` to `COMPLETED`, and logs the actions in `AuditLog`.
â”ƒ - If donor logins again before 30 days, system resets `User.status` to `ACTIVE` and `DonorProfile.status` to `ACTIVE`, sets `GDPRDeletionRequest` to `CANCELLED` , and logs the action in `AuditLog`.

**System Audit & Health Flow**
â”ƒ - Every state-changing action (create, update, delete) across all entities automatically triggers an `AuditLog` entry.
â”ƒ - System aggregates real-time data into `MetricsSnapshot` for dashboard views.
â”ƒ - System runs batch jobs to generate `DemandForecast` records by region and blood type based on historical emergency data.



**Authentication & Session Management Flow**
â”ƒ - If donor logins again before 30 days, system resets `User.status` to `ACTIVE` and `DonorProfile.status` to `ACTIVE`, sets `GDPRDeletionRequest` to `CANCELLED` , and logs the action in `AuditLog`.
â”ƒ - User submits credentials; system verifies against `User.hashedPassword` and checks `User.status` is not `SUSPENDED` nor `DELETED`.
â”ƒ - System creates a `Session`, generates access/refresh tokens, and hashes them before storing.
â”ƒ - User makes requests; system validates `Session.accessTokenHash` and checks `expiresAt`.
â”ƒ - If the access token expires, system validates the `refreshTokenHash` and calls `Session.refresh()`.
â”ƒ - User logs out or system revokes the session, calling `Session.revoke()`.

**Password Reset Flow**
â”ƒ - User requests a password reset; system creates a `PASSWORD_RESET` `VerificationToken` and sends a notification.
â”ƒ - User clicks the secure link; system calls `VerificationToken.validate()` and `consume()`.
â”ƒ - User submits a new password; system updates `User.hashedPassword` and invalidates all existing `Session`s for that user.

**Donor Profile & Settings Update Flow**
â”ƒ - Donor updates personal info, location, or `AvailabilityStatus`; system updates `DonorProfile` and logs old/new values in `AuditLog`.
â”ƒ - Donor updates `NotificationPreferences` (frequency, `QuietHours`, max distance); system saves the JSON preferences, which are subsequently referenced by the notification engine.
â”ƒ - Donor updates their `HealthQuestionnaire`; system saves changes and re-evaluates `permanentlyRestricted` and `profileComplete` flags.

**Donor Dashboard & Impact Flow**
â”ƒ - Donor accesses dashboard; system fetches `DonorProfile.reliabilityScore`, `eligibleFromDate`, and `canDonate()` status.
â”ƒ - System calculates impact metrics (milestones) by querying the donor's `Appointment` history where status is `COMPLETED`.
â”ƒ - Donor requests a certificate; system generates a downloadable document for a specific completed `Appointment`.

**Permanent Health Restriction Flow**
â”ƒ - During onboarding or a `HealthQuestionnaire` update, system detects a disqualifying condition (UCâ€‘SYS11).
â”ƒ - System sets `DonorProfile.permanentlyRestricted` to true, sets `restrictionReason`, and changes `AvailabilityStatus` to `PERMANENTLY_RESTRICTED`.
â”ƒ - System flags the profile for Super Admin review and creates a notification/alert for the admin team.

**Super Admin Override Flow**
â”ƒ - Super Admin reviews the flagged permanent restriction (UCâ€‘SA07) and checks the donor's medical details.
â”ƒ - If deemed safe or in error, Super Admin overrides the restriction, setting `permanentlyRestricted` to false and restoring `AvailabilityStatus`.
â”ƒ - System logs the override action, reason, and actor in the `AuditLog`.

**Appointment Reschedule & Cancellation Flow**
â”ƒ - Donor calls `Appointment.cancel()` or `Appointment.reschedule()`, providing an optional `cancellationReason`.
â”ƒ - System sets `Appointment.status` to `CANCELLED` or `RESCHEDULED`, and records `cancelledAt`.
â”ƒ - System automatically decrements `Slot.bookedCount` (and `regularBookedCount` if applicable), freeing up the capacity (UCâ€‘SYS13).
â”ƒ - If rescheduling, system finds a new available `Slot`, links it to the `Appointment`, and increments the new slot's counts.

**Failed Health Screening Flow**
â”ƒ - During `Appointment.startScreening()`, staff records vitals in `HealthScreening` and marks `eligible` as false.
â”ƒ - System automatically calls `Appointment.cancel()` with the screening failure as the reason.
â”ƒ - System releases the reserved `Slot` capacity and logs the deferral in the `AuditLog`.
â”ƒ - If the condition is temporary, system sets `DonorProfile.eligibleFromDate`; if permanent, triggers the Permanent Health Restriction Flow.

**Emergency Slot Allocation Flow**
â”ƒ - When a donor accepts an emergency (`DonorResponse.accept()`), system searches for an available `Slot` at the requesting `DonationCenter`.
â”ƒ - If no slots are available locally, system searches nearby centers within a reasonable radius.
â”ƒ - System creates the emergency `Appointment`, links the `Slot`, and increments booking counts.
â”ƒ - If absolutely no slots are found, system alerts center staff to manually create capacity or handle the walk-in.

**Emergency Fulfillment Tracking Flow**
â”ƒ - As emergency `Appointment`s are completed, system sums the `mlCollected` from all linked appointments for that `EmergencyRequest`.
â”ƒ - System converts the total milliliters into standard blood units and compares against `unitsNeeded`.
â”ƒ - Once the collected units meet or exceed the target, system automatically triggers `EmergencyRequest.resolve()`, setting status to `FULFILLED`.

**Manual Emergency Management Flow**
â”ƒ - Center staff extends the deadline or widens the radius manually via UCâ€‘CS03; system updates `expiresAt` or `matchRadius` and logs the change.
â”ƒ - Center staff cancels the emergency early (e.g., blood secured from another source); system calls `EmergencyRequest.cancel()`, setting status to `CANCELLED` and invalidating any pending `DonorResponse`s.

**Staff Donor Intake Flow**
â”ƒ - Before screening, staff views the donor's `HealthQuestionnaire`, `DonorProfile.permanentlyRestricted` flag, and `eligibleFromDate` (UCâ€‘CS08).

**Center Admin Ongoing Management Flow**
â”ƒ - Center Admin updates center info, hours, or adds `ClosureWindow`s to `OperatingHours` (UCâ€‘CA03, CA05).
â”ƒ - System automatically blocks or releases `Slot`s that fall within newly added closure windows (UCâ€‘SYS13).
â”ƒ - Center Admin adjusts capacity settings; system regenerates or updates future `Slot` max bookings accordingly (UCâ€‘CA04).
â”ƒ - Center Admin views `AuditLog` filtered by their center's staff to review staff activity (UCâ€‘CA07).

**Super Admin User Management Flow**
â”ƒ - Super Admin searches and filters all `User`s (UCâ€‘SA02).
â”ƒ - Super Admin suspends, activates, or deletes accounts (UCâ€‘SA03), updating `User.status` and revoking active `Session`s.
â”ƒ - Super Admin assigns or revokes `UserRole`s (UCâ€‘SA05), granting or removing access to specific system features.

**Super Admin System Monitoring Flow**
â”ƒ - Super Admin views the system dashboard populated by `MetricsSnapshot` data (UCâ€‘SA10).
â”ƒ - Super Admin monitors API usage, error rates, and service health.
â”ƒ - Super Admin queries and exports `AuditLog` records for compliance (UCâ€‘SA12) and generates platform-wide reports (UCâ€‘SA13).

**Automated Eligibility Restoration Flow**
â”ƒ - A scheduled system job scans for `DonorProfile`s where `eligibleFromDate` has passed.
â”ƒ - System automatically clears the `eligibleFromDate` (or sets it to the past), restoring `canDonate()` to true (UCâ€‘SYS10).
â”ƒ - System sends an `ELIGIBILITY_REMINDER` notification to the donor to schedule a new appointment.
---
