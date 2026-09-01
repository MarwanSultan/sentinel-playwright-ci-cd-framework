# VA.gov Critical Functionality Test Plan

## Overview

This comprehensive test plan covers the five most critical veteran-facing functionalities of VA.gov. It is structured for direct implementation using Playwright test automation.

---

## Test Plan Summary

| #   | Functionality Name                 | Priority | Description                                                                 |
| --- | ---------------------------------- | -------- | --------------------------------------------------------------------------- |
| 1   | VA Benefits Application Submission | High     | Allows veterans to apply for benefits (e.g., disability, education) online. |
| 2   | Appointment Scheduling             | High     | Enables veterans to schedule, view, and cancel medical appointments.        |
| 3   | Claims Status Tracking             | High     | Lets veterans view the status and details of their benefit claims.          |
| 4   | Profile & Account Management       | High     | Allows veterans to update personal info, contact details, and preferences.  |
| 5   | Secure Messaging with VA Providers | High     | Enables veterans to send/receive secure messages with healthcare providers. |

---

## Detailed Test Plan

### 1. VA Benefits Application Submission

#### Functionality Description

Allows veterans to apply for benefits (e.g., disability, education) online through an end-to-end application submission form.

#### Priority Level

**HIGH**

#### Test Objectives

- Validate end-to-end application submission workflow
- Verify field validation and error handling
- Ensure confirmation and data persistence
- Validate multi-step form navigation

#### Test Scenarios / Cases

##### Positive Cases

| Case ID | Description                                       | Steps                                                                                                                                 | Expected Result                                                                         |
| ------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| BEN-01  | Submit valid application with all required fields | 1. Navigate to benefits application<br>2. Fill all required fields with valid data<br>3. Upload required documents<br>4. Click Submit | Application submitted successfully, confirmation page displayed, reference number shown |
| BEN-02  | Submit application with optional fields           | 1. Fill required fields<br>2. Fill optional fields<br>3. Submit                                                                       | Application accepted, optional fields stored with main record                           |
| BEN-03  | Resume incomplete application                     | 1. Start application<br>2. Save as draft<br>3. Navigate away and return<br>4. Resume and complete                                     | Saved data restored, application completed and submitted                                |

##### Negative Cases

| Case ID | Description                         | Steps                                                    | Expected Result                                                       |
| ------- | ----------------------------------- | -------------------------------------------------------- | --------------------------------------------------------------------- |
| BEN-04  | Submit with missing required fields | 1. Leave required field empty<br>2. Attempt submission   | Form validation error, specific field highlighted, submission blocked |
| BEN-05  | Submit with invalid email format    | 1. Enter invalid email<br>2. Attempt submission          | Error message: "Invalid email format", field marked in red            |
| BEN-06  | Submit with invalid phone number    | 1. Enter invalid phone<br>2. Attempt submission          | Error message: "Invalid phone format", submission blocked             |
| BEN-07  | Submit with oversized file          | 1. Attempt to upload file >10MB<br>2. Attempt submission | Error: "File exceeds maximum size", recommendation to compress        |
| BEN-08  | Submit with unsupported file type   | 1. Upload non-PDF/image file<br>2. Attempt submission    | Error: "Unsupported file type", list of allowed types shown           |

##### Edge Cases

| Case ID | Description                                     | Steps                                                               | Expected Result                                                                       |
| ------- | ----------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| BEN-09  | Submit with maximum length text input           | 1. Fill text field with 5000+ characters<br>2. Submit               | Form accepts input, no truncation or data loss, submission succeeds                   |
| BEN-10  | Submit with special characters in text fields   | 1. Enter special chars: !@#$%^&\*()<br>2. Submit                    | Special characters preserved correctly in database                                    |
| BEN-11  | Submit application and immediately submit again | 1. Submit application<br>2. Quick re-submission attempt             | Duplicate prevention, error: "Application already submitted", only one record created |
| BEN-12  | Network timeout during submission               | 1. Submit application<br>2. Simulate network timeout mid-submission | Graceful error, retry option, no duplicate data                                       |
| BEN-13  | Session timeout during form fill                | 1. Fill form for >30 mins without action<br>2. Attempt submission   | User redirected to login, option to resume with saved data                            |

##### Data-Driven Scenarios

| Case ID | Benefit Type                 | Veteran Status    | Expected Behavior                                            |
| ------- | ---------------------------- | ----------------- | ------------------------------------------------------------ |
| BEN-14  | Disability Compensation      | Active Duty       | Form shows disability-specific fields, submission successful |
| BEN-15  | Education Benefits (GI Bill) | Veteran           | Form shows education-specific fields, submission successful  |
| BEN-16  | Dependent Survivor Benefits  | Survivor          | Form shows survivor-specific fields, submission successful   |
| BEN-17  | Housing Benefits             | Homeless Veteran  | Form shows housing-specific fields, submission successful    |
| BEN-18  | Vocational Rehabilitation    | Service-Connected | Form shows voc rehab fields, submission successful           |

#### Test Data Requirements

- Valid veteran account with authentication
- Sample PDF and image files for upload (max 10MB each)
- Invalid file types (executable, video)
- Valid/invalid email addresses and phone numbers
- Test data for each benefit type
- Mock API responses for benefit eligibility checks
- Mock confirmation IDs for success responses

#### Preconditions

- User authenticated with valid VA account
- User has required eligibility for benefits
- Backend services available and responsive
- Test data has been reset to clean state
- All dependent APIs mocked for testing

#### Expected Results

- Application successfully submitted with confirmation
- Confirmation email sent to provided email address
- Reference number generated and displayed
- Data persisted in test database
- Validation errors shown for invalid inputs
- No duplicate applications created
- Session maintained throughout workflow

#### Security Tests

| Test Case  | Description             | Validation Points                                             |
| ---------- | ----------------------- | ------------------------------------------------------------- |
| SEC-BEN-01 | Authentication required | Unauthenticated user cannot access application form           |
| SEC-BEN-02 | Authorization checks    | User can only submit benefits they're eligible for            |
| SEC-BEN-03 | CSRF protection         | CSRF token validated on form submission                       |
| SEC-BEN-04 | XSS prevention          | Special characters in text fields not executed as code        |
| SEC-BEN-05 | PII protection          | Social Security Number masked in UI, never logged             |
| SEC-BEN-06 | Session timeout         | Session invalidates after 15 mins of inactivity               |
| SEC-BEN-07 | Secure file upload      | File upload validates file type server-side, no execution     |
| SEC-BEN-08 | Data encryption         | Form data transmitted over HTTPS, at-rest encryption verified |

#### Performance Considerations

| Metric           | Target     | Notes                                     |
| ---------------- | ---------- | ----------------------------------------- |
| Form load time   | <2 seconds | Initial form should render quickly        |
| Field validation | <500ms     | Real-time validation should be responsive |
| File upload      | <3 seconds | For typical 2-5MB files                   |
| Form submission  | <3 seconds | Submit button to confirmation page        |
| API response     | <2 seconds | Backend eligibility/verification APIs     |
| Database insert  | <1 second  | Application record creation               |

#### Automation Suitability

- **Fully Automatable**: All positive, negative, and edge cases
- **Data-Driven**: Best suited for parameterized tests with different benefit types
- **Special Handling**:
  - File uploads require real test files
  - API mocking for external eligibility services
  - Database state cleanup between runs
  - Session management for timeout tests

#### Playwright Considerations

- Use `page.fill()` for form field inputs
- Implement `page.waitForNavigation()` for page redirects after submission
- Mock API endpoints using `route.abort()` for failure scenarios
- Use `page.screenshot()` for result validation on confirmation page
- Capture network requests with `page.on('request')` for CSRF token validation
- Implement `page.context.setDefaultNavigationTimeout(5000)` for timeout tests
- Use test fixtures for user authentication state
- Generate trace files on failure with `context.tracing`
- Validate success via both UI confirmation and database query

---

### 2. Appointment Scheduling

#### Functionality Description

Enables veterans to schedule, view, reschedule, and cancel medical appointments with VA facilities and providers.

#### Priority Level

**HIGH**

#### Test Objectives

- Validate appointment scheduling workflow
- Verify calendar slot availability and booking logic
- Ensure appointment rescheduling and cancellation
- Validate double-booking prevention
- Verify time zone handling across regions

#### Test Scenarios / Cases

##### Positive Cases

| Case ID | Description                                         | Steps                                                                                                  | Expected Result                                                            |
| ------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| APT-01  | Schedule new appointment                            | 1. Navigate to appointments<br>2. Select clinic<br>3. Choose available date/time<br>4. Confirm booking | Appointment created, confirmation shown, calendar updated                  |
| APT-02  | Schedule appointment and receive confirmation email | 1. Complete appointment scheduling<br>2. Verify email                                                  | Confirmation email received with appointment details, cancellation link    |
| APT-03  | Reschedule existing appointment                     | 1. View upcoming appointments<br>2. Select appointment<br>3. Choose new date/time<br>4. Confirm change | Appointment moved to new time, old slot released, confirmation sent        |
| APT-04  | Cancel appointment                                  | 1. View upcoming appointments<br>2. Select appointment<br>3. Click Cancel<br>4. Confirm cancellation   | Appointment removed, user notified, slot available for others              |
| APT-05  | View appointment details                            | 1. Select scheduled appointment<br>2. View details dialog                                              | Full appointment details displayed: provider, location, time, instructions |

##### Negative Cases

| Case ID | Description                            | Steps                                                                               | Expected Result                                                                   |
| ------- | -------------------------------------- | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| APT-06  | Attempt to book past-dated appointment | 1. Select clinic<br>2. Choose past date<br>3. Attempt booking                       | Past dates disabled/error message: "Cannot book appointments in the past"         |
| APT-07  | Attempt to double-book same time slot  | 1. Book appointment at 2:00 PM<br>2. In new session, attempt same time<br>3. Submit | Error: "Slot no longer available", user offered alternatives                      |
| APT-08  | Attempt to cancel past appointment     | 1. Select past appointment<br>2. Click Cancel                                       | Cancel option disabled, error: "Cannot cancel past appointments"                  |
| APT-09  | Attempt to reschedule within 24 hours  | 1. Reschedule appointment in <24hrs<br>2. Submit                                    | Error: "Cannot reschedule within 24 hours of appointment", option to call instead |
| APT-10  | No available appointments at clinic    | 1. Select clinic with no open slots<br>2. Attempt to book                           | Message: "No appointments available", recommendation to call or try other clinic  |

##### Edge Cases

| Case ID | Description                                           | Steps                                                                                | Expected Result                                                              |
| ------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| APT-11  | Schedule back-to-back appointments                    | 1. Book 2:00 PM appointment<br>2. Book 2:30 PM appointment<br>3. Verify both created | Both appointments created, UI allows back-to-back bookings (system decision) |
| APT-12  | Timezone boundary: schedule across timezone change    | 1. Schedule appointment during DST change<br>2. Verify displayed time                | Correct time displayed, no confusion from DST transition                     |
| APT-13  | Schedule from multiple timezones                      | 1. User in EST books appointment<br>2. Appointment displayed in Pacific time zone    | Times correctly adjusted, stored in UTC                                      |
| APT-14  | Rapid rescheduling attempts                           | 1. Reschedule appointment 5 times rapidly<br>2. Verify final state                   | Only last reschedule persists, no data corruption                            |
| APT-15  | Schedule appointment with special characters in notes | 1. Add notes: !@#$%^&\*()<br>2. Schedule                                             | Special characters preserved, no issues with display or storage              |

##### Data-Driven Scenarios

| Case ID | Clinic                     | Provider  | Availability  | Expected Result                                    |
| ------- | -------------------------- | --------- | ------------- | -------------------------------------------------- |
| APT-16  | Primary Care - Boston MA   | Dr. Smith | High          | Appointment booked successfully                    |
| APT-17  | Mental Health - Remote     | Dr. Jones | Medium        | Appointment booked, remote format                  |
| APT-18  | Cardiology - Houston TX    | Dr. Brown | Low (2 slots) | Appointment booked, limited availability warning   |
| APT-19  | Orthopedic Surgery - NYC   | Dr. Davis | None          | Error "No availability", next available date shown |
| APT-20  | Telehealth - All locations | Multiple  | Varied        | Booking works across all providers                 |

#### Test Data Requirements

- Clinic master data (locations, providers, hours, capacity)
- Calendar availability mock data
- Multiple provider schedules (high/medium/low availability)
- Time zone configurations for various US regions (EST, CST, MST, PST, AKT, HST)
- Veteran accounts in different time zones
- Appointment confirmation email templates
- Mock API responses for availability and booking

#### Preconditions

- User authenticated and verified as veteran
- Clinics and providers configured in test environment
- Calendar system operational and responsive
- Email service mocked for confirmation testing
- User browser timezone setting controllable for testing

#### Expected Results

- Appointments created and persisted in calendar system
- Confirmation emails sent for scheduled/rescheduled/cancelled appointments
- Calendar reflects all changes immediately
- Time zones handled correctly across US regions
- Double-booking prevention enforced
- Past and imminent appointments protected from inappropriate actions
- User can view all upcoming appointments in one place

#### Security Tests

| Test Case  | Description             | Validation Points                                                   |
| ---------- | ----------------------- | ------------------------------------------------------------------- |
| SEC-APT-01 | Authentication required | Unauthenticated user cannot book appointments                       |
| SEC-APT-02 | Authorization checks    | User can only view/modify own appointments                          |
| SEC-APT-03 | Provider legitimacy     | Cannot schedule with non-existent or unauthorized providers         |
| SEC-APT-04 | PII in confirmation     | PII not exposed in email subjects or unencrypted logs               |
| SEC-APT-05 | CSRF protection         | Appointment cancellation requires valid CSRF token                  |
| SEC-APT-06 | Session management      | Session invalidates, pending appointments require re-authentication |
| SEC-APT-07 | API spoofing            | Direct API calls with manipulated clinic IDs rejected               |

#### Performance Considerations

| Metric                  | Target     | Notes                             |
| ----------------------- | ---------- | --------------------------------- |
| Calendar load time      | <2 seconds | Initial calendar view             |
| Time slot selection     | <1 second  | UI responsiveness for slot clicks |
| API for availability    | <2 seconds | Backend query for available slots |
| Booking submission      | <2 seconds | Appointment creation confirmation |
| Confirmation email send | <3 seconds | Email delivered after booking     |
| Rescheduling action     | <2 seconds | Reschedule form processing        |

#### Automation Suitability

- **Fully Automatable**: All positive, negative, and edge cases
- **Highly Data-Driven**: Different clinics, providers, availability states
- **Time-Dependent**: Requires date/time manipulation for testing
- **Special Handling**:
  - Time zone simulation and validation
  - Email capture and verification
  - Calendar state management between tests
  - Parallel execution requires isolated clinic/slot data

#### Playwright Considerations

- Use `page.setDefaultNavigationTimeout()` and `page.setDefaultTimeout()` for reliability
- Mock calendar API with `route.continue()` for controlled availability
- Implement date/time picker handling with `page.fill()` and `page.selectOption()`
- Capture calendar state with `page.screenshot()` after each booking
- Validate confirmation email via API call or mock SMTP
- Use `page.context.clearCookies()` between user scenarios
- Implement custom fixtures for rapid timezone testing
- Mock time with `beforeEach()` hooks using `Date` manipulation
- Set up network interception for availability API validation
- Trace file capture on failed rescheduling attempts

---

### 3. Claims Status Tracking

#### Functionality Description

Lets veterans view the status and detailed progress of their benefit claims, including pending actions, required documentation, and estimated decision dates.

#### Priority Level

**HIGH**

#### Test Objectives

- Validate accurate status display for various claim types
- Verify claim details and timeline completeness
- Ensure secure access control for claims
- Validate error handling for missing/invalid claims
- Verify status update accuracy in real-time

#### Test Scenarios / Cases

##### Positive Cases

| Case ID | Description                       | Steps                                                                          | Expected Result                                                                    |
| ------- | --------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
| CLM-01  | View open claim status            | 1. Navigate to claims<br>2. Select open claim<br>3. View status                | Current status displayed, timeline shown, estimated decision date visible          |
| CLM-02  | View closed claim with decision   | 1. Select completed claim<br>2. View full details                              | Status: "Approved/Denied", decision letter available, benefit amount shown         |
| CLM-03  | View claim with pending documents | 1. Select claim needing docs<br>2. View status                                 | Status: "Pending Review", required documents listed, submission instructions shown |
| CLM-04  | View claim timeline and updates   | 1. Open claim with history<br>2. Expand timeline<br>3. View all status changes | Complete timeline displayed chronologically, dates and status changes shown        |
| CLM-05  | Download claim decision letter    | 1. Open closed claim<br>2. Click download decision<br>3. Verify PDF            | Decision letter downloaded as PDF, contains full decision details                  |

##### Negative Cases

| Case ID | Description                             | Steps                                                                  | Expected Result                                                             |
| ------- | --------------------------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| CLM-06  | Attempt to view another user's claim    | 1. User A tries to access User B's claim<br>2. Attempt direct API call | 403 Forbidden error, "You do not have access to this claim"                 |
| CLM-07  | Request non-existent claim ID           | 1. Manually input invalid claim ID<br>2. Navigate to URL               | 404 Not Found error, "Claim not found"                                      |
| CLM-08  | View claim with no status updates       | 1. Select claim with minimal history<br>2. View timeline               | Message: "No updates yet. We'll notify you when your claim status changes." |
| CLM-09  | View claim with malformed API response  | 1. Simulate API error<br>2. User navigates to claims                   | Error message: "Unable to load claim details", retry option shown           |
| CLM-10  | Attempt to modify claim status directly | 1. Intercept API call<br>2. Attempt to change status<br>3. Submit      | API rejects modification, status remains unchanged in database              |

##### Edge Cases

| Case ID | Description                                           | Steps                                                                 | Expected Result                                                      |
| ------- | ----------------------------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------- |
| CLM-11  | View claim with very long processing time             | 1. Open 5+ year old claim<br>2. View status and timeline              | All historical data displayed, no truncation, performance maintained |
| CLM-12  | View claim with multiple status updates on same day   | 1. Open claim with 10+ updates in one day<br>2. View timeline         | All updates displayed in order, no duplicate/missing entries         |
| CLM-13  | View claim with special characters in notes/documents | 1. Open claim with special chars in decision notes<br>2. View details | Special characters rendered correctly, no display issues             |
| CLM-14  | View claim with >100MB decision document              | 1. Select claim with large attachment<br>2. View document link        | Document link available, loads in reasonable time                    |
| CLM-15  | Claims list pagination with 100+ claims               | 1. User with extensive claim history<br>2. Navigate through pages     | Pagination works, all claims accessible, no memory issues            |

##### Data-Driven Scenarios

| Case ID | Claim Type                | Status         | Documents Required              | Expected Result                    |
| ------- | ------------------------- | -------------- | ------------------------------- | ---------------------------------- |
| CLM-16  | Disability Compensation   | Pending Review | Birth Certificate, DD214        | Status shown, documents listed     |
| CLM-17  | Dependency/Indemnity Comp | Approved       | Original Award Letter           | Approved status, benefit amount    |
| CLM-18  | Education Benefits        | Under Review   | College Enrollment Verification | Review status, timeline shown      |
| CLM-19  | Housing Assistance        | Denied         | Previous Housing Documentation  | Denial reason shown, appeal option |
| CLM-20  | Vocational Rehabilitation | In Progress    | Training Plan Agreement         | Progress status, milestones        |

#### Test Data Requirements

- Multiple test veteran accounts with various claim histories
- Mock claims data with different statuses: Pending, Under Review, Approved, Denied, Appealed
- Claim timelines with historical status updates
- Decision letters in PDF format
- Mock API responses for claims listing and details
- Claims with missing/pending documents
- Claims with very long processing histories
- Claims with multiple status updates in short timeframes

#### Preconditions

- User authenticated with valid veteran account
- Claims data loaded in test database
- Claims API available and responsive
- PDF download capability enabled
- User permissions configured correctly
- Date/time mocking for relative dates ("Updated 3 days ago")

#### Expected Results

- Claims list displays all relevant claims with status summaries
- Individual claim details show complete information
- Timeline displays in chronological order
- Status indicators are accurate and current
- Decision documents are accessible and downloadable
- Unauthorized access attempts are blocked
- Error states handled gracefully with user guidance

#### Security Tests

| Test Case  | Description              | Validation Points                                     |
| ---------- | ------------------------ | ----------------------------------------------------- |
| SEC-CLM-01 | Authentication required  | Unauthenticated user cannot view claims               |
| SEC-CLM-02 | Authorization checks     | User can only view own claims, not others'            |
| SEC-CLM-03 | PII in claim details     | SSN, addresses masked or not displayed                |
| SEC-CLM-04 | PDF download security    | Downloads over HTTPS, no unencrypted transmission     |
| SEC-CLM-05 | API rate limiting        | Claim list API rate-limited to prevent scraping       |
| SEC-CLM-06 | Sensitive fields masking | Medical information redacted appropriately            |
| SEC-CLM-07 | Session timeout          | Session invalidates, claims require re-authentication |

#### Performance Considerations

| Metric                  | Target       | Notes                         |
| ----------------------- | ------------ | ----------------------------- |
| Claims list load        | <2 seconds   | Load all user's claims        |
| Claim detail page       | <1.5 seconds | Display individual claim      |
| Timeline rendering      | <1 second    | Render historical updates     |
| PDF download initiation | <2 seconds   | Start PDF generation/transfer |
| API response for claims | <1.5 seconds | Backend claim query           |
| Pagination              | <500ms       | Load next page of claims      |

#### Automation Suitability

- **Fully Automatable**: All views, filters, and data access scenarios
- **Data-Driven**: Multiple claim types and statuses
- **Special Handling**:
  - PDF validation and parsing
  - Date-relative assertions ("Updated 3 days ago")
  - Large dataset pagination testing
  - Timeline rendering verification

#### Playwright Considerations

- Mock claims API with `route.continue()` for various claim states
- Use `page.screenshot()` to validate claims list and detail layouts
- Implement PDF download verification with `page.on('popup')` or `context.tracing`
- Validate table sorting with `page.locator()` and assertion chains
- Use `page.setDefaultTimeout()` for slow timeline rendering
- Mock relative time display with custom date fixtures
- Capture network requests to validate authorization headers
- Trace file capture on unauthorized access attempts
- Test pagination with `page.click()` and DOM assertion

---

### 4. Profile & Account Management

#### Functionality Description

Allows veterans to view and update personal information, contact details, communication preferences, security settings, and account configuration.

#### Priority Level

**HIGH**

#### Test Objectives

- Validate profile information accuracy and completeness
- Ensure secure updates to personal data
- Verify field validation and error handling
- Test security settings and password management
- Validate audit trails for account changes

#### Test Scenarios / Cases

##### Positive Cases

| Case ID | Description                      | Steps                                                                                     | Expected Result                                                        |
| ------- | -------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| PRF-01  | View complete profile            | 1. Navigate to profile<br>2. View all sections                                            | All profile sections displayed, current information shown              |
| PRF-02  | Update email address             | 1. Edit email field<br>2. Enter new email<br>3. Save<br>4. Verify confirmation email      | Email updated, confirmation sent to old email, verify link required    |
| PRF-03  | Update phone number              | 1. Edit phone field<br>2. Enter valid phone<br>3. Save                                    | Phone number updated, displayed with icon for type (mobile/home)       |
| PRF-04  | Update mailing address           | 1. Edit address fields<br>2. Enter complete address<br>3. Save                            | Address updated and validated, zip code verified, address standardized |
| PRF-05  | Update communication preferences | 1. Select notification type<br>2. Choose delivery method (email/phone/text)<br>3. Save    | Preferences saved, confirmation shown, affects future notifications    |
| PRF-06  | Change password                  | 1. Navigate to security settings<br>2. Enter current/new password<br>3. Save              | Password changed, confirmation email sent, old sessions invalidated    |
| PRF-07  | Enable two-factor authentication | 1. Go to security settings<br>2. Enable 2FA<br>3. Scan QR code<br>4. Verify with code     | 2FA enabled, backup codes provided, login requires verification        |
| PRF-08  | Add emergency contact            | 1. Navigate to emergency contacts<br>2. Add new contact<br>3. Enter name/phone<br>4. Save | Emergency contact added, confirmation shown, can be updated            |

##### Negative Cases

| Case ID | Description                                 | Steps                                                                  | Expected Result                                                         |
| ------- | ------------------------------------------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| PRF-09  | Update with invalid email format            | 1. Enter invalid email<br>2. Attempt save                              | Error: "Invalid email format", field highlighted, save blocked          |
| PRF-10  | Update with invalid phone format            | 1. Enter invalid phone<br>2. Attempt save                              | Error: "Invalid phone format", example format shown                     |
| PRF-11  | Update address with incomplete fields       | 1. Leave zip code blank<br>2. Attempt save                             | Error: "Zip code required", address not updated                         |
| PRF-12  | Change password with current password wrong | 1. Enter incorrect current password<br>2. Attempt change               | Error: "Current password incorrect", change blocked                     |
| PRF-13  | Change password with weak new password      | 1. New password = "123456"<br>2. Attempt change                        | Error: "Password does not meet requirements", requirements shown        |
| PRF-14  | Update phone within rate limit              | 1. Update phone<br>2. Immediately update again<br>3. Update third time | After 3 attempts in 5 mins, error: "Too many attempts, try again later" |
| PRF-15  | Disable 2FA without backup codes            | 1. Enable 2FA<br>2. Lose backup codes<br>3. Attempt to disable 2FA     | Require identity verification before disabling                          |

##### Edge Cases

| Case ID | Description                           | Steps                                                              | Expected Result                                                     |
| ------- | ------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------- |
| PRF-16  | Update with maximum length inputs     | 1. Enter 200-char address line<br>2. Enter 50-char name<br>3. Save | All data saved without truncation                                   |
| PRF-17  | Update with special characters        | 1. Name with: O'Brien, José, Müller<br>2. Save                     | Special characters preserved correctly                              |
| PRF-18  | International phone number            | 1. Enter +44 UK phone number<br>2. Save                            | Validation recognizes international format, saves with country code |
| PRF-19  | Rapid sequential field updates        | 1. Update 5 fields in <10 seconds<br>2. Save                       | All changes saved, no data loss or race conditions                  |
| PRF-20  | Update profile during session timeout | 1. Leave form open >15 mins<br>2. Attempt save                     | Session expired error, redirect to login, changes not lost          |

##### Data-Driven Scenarios

| Case ID | Field Type    | Valid Input                        | Invalid Input | Expected Result                      |
| ------- | ------------- | ---------------------------------- | ------------- | ------------------------------------ |
| PRF-21  | Email         | user@va.gov                        | invalid.email | Valid accepted, invalid rejected     |
| PRF-22  | Phone (US)    | (202) 555-0123                     | 123456789     | Format validated, standardized       |
| PRF-23  | Address (US)  | 123 Main St, Springfield, IL 62701 | 123 Main St   | Incomplete rejected, valid accepted  |
| PRF-24  | Password      | MyP@ss1234!9                       | password123   | Complex accepted, weak rejected      |
| PRF-25  | Date of Birth | 01/15/1970                         | 99/99/9999    | Valid DOB accepted, invalid rejected |

#### Test Data Requirements

- Multiple test veteran accounts with various profile states
- Valid/invalid email addresses and phone numbers
- Valid/invalid addresses for multiple states
- Password complexity validation rules
- Mock email service for confirmation messages
- 2FA QR codes and backup codes
- Emergency contact database
- Audit log for tracking changes
- International phone formats
- Special characters in various fields

#### Preconditions

- User authenticated with valid account
- Profile data loaded in test database
- Email service mocked for verifications
- Password requirements clearly defined
- 2FA system available (mock or test TOTP)
- Audit logging enabled
- User's security settings initialized

#### Expected Results

- All profile sections display current information
- Updates persist and are immediately reflected in UI
- Validation errors prevent invalid data from being saved
- Confirmation emails sent for sensitive changes
- Password changes invalidate old sessions
- 2FA configuration properly secured
- All changes logged with timestamp and user action
- Emergency contacts accessible in user's profile

#### Security Tests

| Test Case  | Description             | Validation Points                                 |
| ---------- | ----------------------- | ------------------------------------------------- |
| SEC-PRF-01 | Authentication required | Cannot access profile without login               |
| SEC-PRF-02 | Authorization checks    | User can only modify own profile                  |
| SEC-PRF-03 | Email verification      | Email change requires verification link           |
| SEC-PRF-04 | Password requirements   | Enforce complexity, history, no reuse             |
| SEC-PRF-05 | Password transmission   | Password sent over HTTPS only, hashed in transit  |
| SEC-PRF-06 | 2FA enforcement         | 2FA seeds stored securely, not logged             |
| SEC-PRF-07 | PII in logs             | Patient data not exposed in application logs      |
| SEC-PRF-08 | Session invalidation    | Old sessions invalidated on password change       |
| SEC-PRF-09 | Audit trail             | All changes logged with user action and timestamp |
| SEC-PRF-10 | CSRF protection         | Profile updates require valid CSRF token          |

#### Performance Considerations

| Metric             | Target       | Notes                        |
| ------------------ | ------------ | ---------------------------- |
| Profile page load  | <1.5 seconds | Initial profile display      |
| Field validation   | <500ms       | Real-time field validation   |
| Profile update     | <2 seconds   | Save profile changes         |
| Email verification | <3 seconds   | Send verification email      |
| Password change    | <2 seconds   | Validate and process change  |
| 2FA setup          | <2 seconds   | Generate and display QR code |

#### Automation Suitability

- **Fully Automatable**: All profile views and basic updates
- **Partially Automatable**: Email verification, 2FA (requires mock services)
- **Data-Driven**: Multiple field types and validation rules
- **Special Handling**:
  - Email verification token capture
  - 2FA code generation and validation
  - Session invalidation verification
  - Password strength validation

#### Playwright Considerations

- Use `page.fill()` for field inputs with validation
- Implement `page.click()` and `page.screenshot()` for save operations
- Mock email service with `route.continue()` for verification testing
- Validate confirmation messages with `page.locator().isVisible()`
- Capture network requests to verify password transmission over HTTPS
- Use form submission handlers for 2FA QR code testing
- Implement custom fixtures for pre-populated test accounts
- Trace file capture on validation errors
- Use `page.waitForNavigation()` for session timeout redirects
- Validate audit logs via separate test database queries

---

### 5. Secure Messaging with VA Providers

#### Functionality Description

Enables veterans to send, receive, and manage secure messages with VA healthcare providers and support personnel, including message threading, attachments, and read receipts.

#### Priority Level

**HIGH**

#### Test Objectives

- Validate secure message send/receive workflow
- Ensure message encryption and secure storage
- Verify attachment handling and virus scanning
- Test message threading and conversation management
- Validate notification delivery

#### Test Scenarios / Cases

##### Positive Cases

| Case ID | Description                     | Steps                                                                            | Expected Result                                                           |
| ------- | ------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| MSG-01  | Send message to provider        | 1. Navigate to messaging<br>2. Select provider<br>3. Type message<br>4. Send     | Message sent, stored securely, provider notified                          |
| MSG-02  | Receive message from provider   | 1. Provider sends message<br>2. Check inbox<br>3. Open message                   | Message displayed, marked as read, timestamp shown                        |
| MSG-03  | Reply to provider message       | 1. Open received message<br>2. Click Reply<br>3. Type response<br>4. Send        | Reply sent, threaded with original, provider notified                     |
| MSG-04  | Send message with attachment    | 1. Compose message<br>2. Attach document<br>3. Send                              | Message sent with attachment, scanned for malware, accessible to provider |
| MSG-05  | Receive message with attachment | 1. Provider sends message with file<br>2. Open message<br>3. Download attachment | Attachment accessible, download secure, scanned for safety                |
| MSG-06  | Message thread display          | 1. Open message with replies<br>2. View conversation                             | Full thread displayed chronologically, all messages visible               |
| MSG-07  | Mark message as read            | 1. Open unread message<br>2. View content                                        | Automatically marked read, unread indicator disappears                    |
| MSG-08  | Archive message                 | 1. Select message<br>2. Click Archive<br>3. View archived folder                 | Message moved to archive, removed from inbox                              |

##### Negative Cases

| Case ID | Description                           | Steps                                                     | Expected Result                                                   |
| ------- | ------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------------------- |
| MSG-09  | Send empty message                    | 1. Open compose<br>2. Leave body blank<br>3. Attempt send | Error: "Message cannot be empty", send button disabled            |
| MSG-10  | Send oversized message                | 1. Compose 100,000+ character message<br>2. Attempt send  | Error: "Message exceeds 50,000 characters", character limit shown |
| MSG-11  | Attach oversized file                 | 1. Attempt to attach 50MB file<br>2. Attempt send         | Error: "File exceeds 25MB limit", max size shown                  |
| MSG-12  | Attach malicious file type            | 1. Attempt to attach .exe or .bat<br>2. Attempt send      | File rejected: "File type not allowed", allowed types listed      |
| MSG-13  | Send message to non-existent provider | 1. Manually input invalid provider ID<br>2. Attempt send  | Error: "Provider not found", verified provider list shown         |
| MSG-14  | Attempt to send spam/bulk messages    | 1. Send 20 messages in <1 minute<br>2. Continue sending   | After limit, error: "Too many messages, try again later"          |
| MSG-15  | Send message with malicious content   | 1. Type HTML/JavaScript in message<br>2. Send and view    | Content sanitized, no code execution, displayed as text           |

##### Edge Cases

| Case ID | Description                              | Steps                                                                                      | Expected Result                                                                 |
| ------- | ---------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| MSG-16  | Send message with special characters     | 1. Message: !@#$%^&\*()\_+{}[]<>?<br>2. Send                                               | Special characters preserved, displayed correctly                               |
| MSG-17  | Send message with Unicode text           | 1. Include Unicode text in message<br>2. Send and receive                                  | Unicode text rendered correctly on both ends                                    |
| MSG-18  | Send message with links                  | 1. Include URL in message<br>2. Verify rendering                                           | URL displayed as clickable link, verified safe                                  |
| MSG-19  | Thread with 50+ messages                 | 1. Open conversation with many replies<br>2. Load thread                                   | All messages load, pagination or lazy-loading works, no performance degradation |
| MSG-20  | Message sent during network interruption | 1. Send message<br>2. Simulate network timeout<br>3. Resume connection                     | Message queued/retried, sent successfully without duplication                   |
| MSG-21  | Delete message from archive              | 1. Archive message<br>2. Permanently delete from archive<br>3. Verify removal              | Message deleted, not recoverable from inbox or archive                          |
| MSG-22  | Rapid send/receive in thread             | 1. Send message<br>2. Provider responds immediately<br>3. Reply quickly<br>4. Check thread | All messages in order, no race conditions, thread integrity maintained          |

##### Data-Driven Scenarios

| Case ID | Message Type             | Recipient Type      | Attachment         | Expected Result                 |
| ------- | ------------------------ | ------------------- | ------------------ | ------------------------------- |
| MSG-23  | Appointment question     | Clinic Scheduler    | None               | Message sent to correct clinic  |
| MSG-24  | Prescription refill      | Pharmacy Provider   | Prescription photo | Message sent, attachment stored |
| MSG-25  | Appointment cancellation | Primary Care Doctor | None               | Message sent, marked urgent     |
| MSG-26  | General inquiry          | Care coordinator    | PDF document       | Message sent with scanned doc   |
| MSG-27  | Feedback/complaint       | VA Administrator    | Screenshot         | Message sent to admin queue     |

#### Test Data Requirements

- Multiple test veteran accounts
- Multiple provider accounts with various roles
- Messages in various states (sent, received, archived, deleted)
- Valid/invalid file types for attachment testing
- Files of various sizes (small, medium, large, oversized)
- Malicious/suspicious file payloads for scanning
- Message templates for different scenarios
- Notification templates
- Mock virus scanning service
- Mock email notification service

#### Preconditions

- User authenticated with valid veteran account
- Providers configured and available in test environment
- Message encryption keys generated
- Email service mocked for notifications
- Virus scanning service mocked
- Message database initialized and clean
- Attachment storage configured
- Rate limiting configured

#### Expected Results

- Messages sent and delivered to intended provider
- Messages encrypted in transit and at rest
- Attachments scanned and stored securely
- Message threads display chronologically
- Notifications sent for new messages
- Attachments downloadable only by authorized parties
- Message history preserved in audit trail
- Rate limiting prevents abuse
- Content sanitization prevents XSS attacks

#### Security Tests

| Test Case  | Description             | Validation Points                                 |
| ---------- | ----------------------- | ------------------------------------------------- |
| SEC-MSG-01 | Authentication required | Unauthenticated user cannot send/receive messages |
| SEC-MSG-02 | Authorization checks    | User can only access own messages, not others'    |
| SEC-MSG-03 | Message encryption      | Messages encrypted with TLS in transit            |
| SEC-MSG-04 | At-rest encryption      | Messages encrypted in database                    |
| SEC-MSG-05 | Attachment scanning     | Malicious files detected and blocked              |
| SEC-MSG-06 | XSS prevention          | HTML/JavaScript in messages sanitized             |
| SEC-MSG-07 | Rate limiting           | Bulk message sending blocked                      |
| SEC-MSG-08 | Provider verification   | Messages only sent to verified providers          |
| SEC-MSG-09 | PII in logs             | Patient identifiers not exposed in logs           |
| SEC-MSG-10 | Session timeout         | Timeout doesn't affect sent messages              |
| SEC-MSG-11 | CSRF protection         | Message send requires valid CSRF token            |

#### Performance Considerations

| Metric                    | Target       | Notes                       |
| ------------------------- | ------------ | --------------------------- |
| Message load/display      | <1.5 seconds | Load message content        |
| Thread load (50 messages) | <2 seconds   | Load full conversation      |
| Send message              | <2 seconds   | Submit and confirm          |
| Attachment upload         | <3 seconds   | For typical 2-5MB files     |
| Attachment download       | <2 seconds   | Download from server        |
| Virus scan                | <2 seconds   | Scan uploaded file          |
| Notification send         | <1 second    | Email notification delivery |
| Archive operation         | <500ms       | Move message to archive     |

#### Automation Suitability

- **Fully Automatable**: Message send/receive, threading, archive operations
- **Mostly Automatable**: Attachment handling (with file mocking)
- **Special Handling**:
  - Virus scan simulation
  - Email notification verification
  - Message encryption validation
  - Provider notification tracking

#### Playwright Considerations

- Use `page.fill()` and `page.click()` for message composition
- Implement file upload with `page.setInputFiles()` for attachments
- Use `page.screenshot()` for message thread verification
- Mock virus scanning API with `route.abort()` for malicious files
- Intercept outgoing messages with `page.on('request')` for encryption validation
- Use `page.waitForNavigation()` for sent confirmation
- Implement message polling with `page.reload()` for receive testing
- Capture network requests to validate HTTPS transmission
- Trace file capture on security validation failures
- Use custom fixtures for message state management
- Validate email notifications via mock SMTP interception

---

## Performance Testing Strategy

### Overview

Performance testing ensures that VA.gov functionalities meet defined service level objectives and provide optimal user experience across varying load conditions and network speeds.

### Performance Testing Objectives

- Validate response times meet defined SLOs
- Identify performance bottlenecks before production
- Verify scalability under peak load
- Ensure mobile and low-bandwidth user experience
- Validate API response times and database query performance

### Performance Metrics & Targets

#### Page Load Metrics

| Metric                         | Target | Threshold | Notes                   |
| ------------------------------ | ------ | --------- | ----------------------- |
| First Contentful Paint (FCP)   | <1.5s  | <2.5s     | Initial content appears |
| Largest Contentful Paint (LCP) | <2s    | <3s       | Main content loaded     |
| Time to Interactive (TTI)      | <3s    | <4s       | Page fully interactive  |
| Cumulative Layout Shift (CLS)  | <0.1   | <0.25     | Visual stability        |
| First Input Delay (FID)        | <100ms | <300ms    | Input responsiveness    |

#### API Response Metrics

| Endpoint           | Target | Alert Threshold | Notes               |
| ------------------ | ------ | --------------- | ------------------- |
| GET claims         | <1.5s  | <2.5s           | Load claims list    |
| POST appointment   | <2s    | <3s             | Create appointment  |
| PUT profile update | <2s    | <3s             | Update user data    |
| GET messages       | <1.5s  | <2.5s           | Load message thread |
| POST file upload   | <3s    | <5s             | Upload attachment   |

#### Database Performance

| Operation                 | Target  | Notes                      |
| ------------------------- | ------- | -------------------------- |
| User authentication       | <300ms  | Login query                |
| Claims query (10 claims)  | <500ms  | Standard claim retrieval   |
| Claims query (100 claims) | <1500ms | Large dataset              |
| Profile update            | <400ms  | Write operation            |
| Appointment slot search   | <800ms  | Complex query with filters |

### Performance Test Scenarios

#### Scenario 1: Page Load Performance

| Test ID | Load Condition       | Validation                                  |
| ------- | -------------------- | ------------------------------------------- |
| PERF-01 | Fast connection (4G) | All metrics: FCP < 1s, LCP < 1.5s, TTI < 2s |
| PERF-02 | 3G connection        | FCP < 2s, LCP < 3s, TTI < 4s                |
| PERF-03 | 2G/Edge connection   | FCP < 3s, LCP < 5s, TTI < 6s                |
| PERF-04 | Slow mobile (1Mbps)  | Page usable within 5s                       |
| PERF-05 | High latency (500ms) | Page load <6s despite latency               |

#### Scenario 2: Form Submission Performance

| Test ID | Form                   | Load              | Expected | Notes                         |
| ------- | ---------------------- | ----------------- | -------- | ----------------------------- |
| PERF-06 | Benefits application   | 1 submission      | <2s      | Real-time submission tracking |
| PERF-07 | Appointment scheduling | 1 booking         | <2s      | Calendar interaction          |
| PERF-08 | Profile update         | 1 update          | <2s      | Field validation + save       |
| PERF-09 | File upload            | 5MB file          | <3s      | Including virus scan          |
| PERF-10 | Message send           | Text + attachment | <2s      | Message + file processing     |

#### Scenario 3: Data Processing Performance

| Test ID | Dataset                   | Operation                      | Target | Notes                      |
| ------- | ------------------------- | ------------------------------ | ------ | -------------------------- |
| PERF-11 | 10 claims                 | Load & display                 | <1.5s  | Standard case              |
| PERF-12 | 50 claims                 | Load & display                 | <2s    | Large claim history        |
| PERF-13 | 100 claims                | Load & display with pagination | <2s    | Pagination support         |
| PERF-14 | 500 messages              | Load thread                    | <2.5s  | Lazy-load after initial 50 |
| PERF-15 | 10K appointments (clinic) | Slot search                    | <1s    | Database query performance |

#### Scenario 4: Concurrent User Load Testing

| Test ID | Concurrent Users           | Test Duration | Expected Results                         |
| ------- | -------------------------- | ------------- | ---------------------------------------- |
| PERF-16 | 50 users                   | 5 minutes     | Page load <3s, no errors                 |
| PERF-17 | 100 users                  | 5 minutes     | Page load <4s, <1% error rate            |
| PERF-18 | 250 users                  | 10 minutes    | Page load <5s, <2% error rate, API <2.5s |
| PERF-19 | Peak load (500 users)      | 15 minutes    | Graceful degradation, <10% error rate    |
| PERF-20 | Spike test (100→500 users) | Ramp up 30s   | Handle spike without complete failure    |

#### Scenario 5: API Performance Under Load

| Test ID | Endpoint              | RPS (Requests/sec) | Target                  | Notes                |
| ------- | --------------------- | ------------------ | ----------------------- | -------------------- |
| PERF-21 | GET /claims           | 100                | <1.5s median, <3s p95   | Peak load            |
| PERF-22 | POST /appointments    | 50                 | <2s median, <4s p95     | Appointment booking  |
| PERF-23 | PUT /profile          | 50                 | <2s median, <3s p95     | Profile updates      |
| PERF-24 | GET /messages         | 100                | <1.5s median, <2.5s p95 | Message retrieval    |
| PERF-25 | POST /messages/upload | 20                 | <3s median, <5s p95     | File upload handling |

#### Scenario 6: Network Condition Resilience

| Test ID | Network Condition            | Expected Behavior                           |
| ------- | ---------------------------- | ------------------------------------------- |
| PERF-26 | Offline mode                 | Graceful error: "No connection"             |
| PERF-27 | High latency (500ms)         | UI responsive, loading indicator shown      |
| PERF-28 | Packet loss (5%)             | Retry mechanism activates, eventual success |
| PERF-29 | Connection timeout           | Error message, retry option available       |
| PERF-30 | Bandwidth throttle (256kbps) | Page functional within 8s                   |

### Performance Testing Tools & Implementation

#### Browser-Based Performance Testing

- **Lighthouse**: Validate Core Web Vitals (FCP, LCP, CLS, FID)
- **WebPageTest**: Detailed waterfall charts and filmstrip view
- **Chrome DevTools**: Real-time performance monitoring
- **Playwright Performance API**: In-test metric collection

#### Load Testing

- **Apache JMeter**: API load testing and concurrent user simulation
- **k6**: Script-based performance testing with Playwright integration
- **Artillery**: Rapid load testing with realistic scenarios
- **Locust**: Python-based distributed load testing

#### Monitoring & Reporting

- **New Relic**: Real-time performance monitoring
- **DataDog**: Infrastructure and application metrics
- **CloudWatch**: AWS-specific performance metrics
- **Custom dashboards**: Real-time test execution metrics

### Performance Test Implementation in Playwright

#### Measuring Page Metrics

```javascript
// Capture Core Web Vitals
const metrics = await page.evaluate(() => {
  return {
    fcp: performance.getEntries().find((e) => e.name === 'first-contentful-paint')?.startTime,
    lcp: performance.getEntriesByName('largest-contentful-paint')[
      performance.getEntriesByName('largest-contentful-paint').length - 1
    ]?.startTime,
    ttfb: performance.timeOrigin + performance.timing.responseStart - performance.timing.navigationStart,
  };
});
```

#### Measuring API Response Times

```javascript
// Track API response times
page.on('response', (response) => {
  const duration = response.url().includes('api/') ? performance.now() - startTime : null;
  console.log(`API: ${response.url()}, Time: ${duration}ms`);
});
```

#### Load Testing with k6 Integration

```javascript
// k6 can be called from Playwright for load test coordination
const loadTestResults = await executeLoadTest({
  duration: '5m',
  vus: 100,
  scenarios: {
    benefitsApplication: { weight: 30 },
    appointmentScheduling: { weight: 20 },
    claimsTracking: { weight: 20 },
    profileManagement: { weight: 15 },
    messaging: { weight: 15 },
  },
});
```

### Performance Test Data

#### Network Profiles (Throttling)

- 4G: 4Mbps down, 3Mbps up, 20ms latency
- 3G: 1.6Mbps down, 750kbps up, 100ms latency
- 2G: 400kbps down, 400kbps up, 400ms latency
- LTE: 12Mbps down, 12Mbps up, 10ms latency

#### Device Profiles

- Desktop: Latitude 1920x1080, typical bandwidth
- Tablet: iPad Pro 1024x1366, mobile bandwidth
- Mobile: iPhone 14 375x667, mobile bandwidth
- Low-end mobile: Moto G4 360x640, 3G conditions

### Performance Reporting

#### Key Metrics Report

- Page load times by scenario and network condition
- API response time distributions (median, p75, p95, p99)
- Error rates and failure patterns
- Resource utilization during load tests
- Throughput (requests per second)
- User experience metrics (FCP, LCP, CLS, FID)

#### Performance Baselines & Alerts

- Establish baselines from production or staging
- Alert on degradation >10% from baseline
- Track trend analysis over time
- Identify regression in feature-specific metrics

---

## Security Testing Strategy

### Overview

Security testing ensures that VA.gov protects veteran data, prevents unauthorized access, and complies with federal security standards and regulations.

### Security Testing Objectives

- Validate authentication and authorization mechanisms
- Identify and prevent injection attacks (XSS, CSRF, SQLi)
- Verify sensitive data protection and encryption
- Test access control enforcement
- Validate session management security
- Identify vulnerable dependencies and components

### Security Test Categories

#### Category 1: Authentication & Authorization

##### Test Scenarios

| Test ID | Scenario                 | Steps                                   | Expected Result                       | Security Impact                         |
| ------- | ------------------------ | --------------------------------------- | ------------------------------------- | --------------------------------------- |
| SEC-001 | Missing authentication   | Access endpoint without token           | 401 Unauthorized                      | High - prevents unauthenticated access  |
| SEC-002 | Invalid/expired token    | Use expired JWT                         | 401 Unauthorized                      | High - invalidates stale sessions       |
| SEC-003 | Manipulated token        | Modify token payload/signature          | 401 Unauthorized                      | Critical - prevents token forgery       |
| SEC-004 | Weak password accepted   | Use "password" as password              | Rejection with requirements           | High - enforces password strength       |
| SEC-005 | Account lockout          | 5 failed login attempts                 | Account locked, message shown         | High - prevents brute force             |
| SEC-006 | Cross-user authorization | Access other user's data via direct URL | 403 Forbidden                         | Critical - prevents unauthorized access |
| SEC-007 | Privilege escalation     | Veteran attempts admin endpoint         | 403 Forbidden                         | Critical - enforces role-based access   |
| SEC-008 | Session hijacking        | Use stolen session cookie               | Session invalidated, re-auth required | Critical - prevents session reuse       |
| SEC-009 | Default credentials      | Attempt to use default admin password   | Access denied                         | High - impacts only if defaults exist   |
| SEC-010 | OAuth/SAML validation    | Tamper with SAML response               | Rejection of invalid signature        | High - prevents identity spoofing       |

#### Category 2: Injection Attacks (XSS, CSRF, SQLi)

##### XSS Prevention

| Test ID | Attack Vector            | Payload                                       | Expected Result                    | Impact     |
| ------- | ------------------------ | --------------------------------------------- | ---------------------------------- | ---------- |
| SEC-011 | Stored XSS in profile    | `<script>alert('XSS')</script>` in name field | Script sanitized, not executed     | Critical   |
| SEC-012 | Reflected XSS in search  | `?search=<img src=x onerror=alert(1)>`        | Payload escaped in response        | Critical   |
| SEC-013 | DOM-based XSS in message | Inject in message body displayed in HTML      | Content escaped, displayed as text | Critical   |
| SEC-014 | Event handler injection  | `<div onmouseover=alert(1)>` in notes         | Event handlers stripped            | Critical   |
| SEC-015 | SVG-based XSS            | `<svg onload=alert(1)>`                       | SVG/script tags sanitized          | Critical   |
| SEC-016 | CSS injection            | `<style>body{background:red}</style>`         | Styles sanitized appropriately     | Medium     |
| SEC-017 | Comment-based XSS        | HTML comments with escaped scripts            | Properly handled/escaped           | Low-Medium |
| SEC-018 | Unicode encoding bypass  | `\u003cscript\u003e`                          | Decoding and sanitization applied  | High       |

##### CSRF Protection

| Test ID | Scenario                    | Steps                                 | Expected Result            |
| ------- | --------------------------- | ------------------------------------- | -------------------------- |
| SEC-019 | Missing CSRF token          | POST without X-CSRF-Token header      | 403 Forbidden              |
| SEC-020 | Invalid CSRF token          | POST with mismatched token            | 403 Forbidden              |
| SEC-021 | Token reuse across users    | Use User A's token for User B request | 403 Forbidden              |
| SEC-022 | Stale token                 | Use 1-hour-old CSRF token             | 403 Forbidden              |
| SEC-023 | SameSite cookie enforcement | Verify SameSite=Strict set            | Cookie not sent cross-site |
| SEC-024 | Token rotation              | Token changes after each request      | Previous token invalid     |

##### SQLi Prevention

| Test ID | Payload                             | Expected Result                 | Notes                         |
| ------- | ----------------------------------- | ------------------------------- | ----------------------------- |
| SEC-025 | `'; DROP TABLE users; --` in search | Query parameterized, data safe  | ORM/prepared statements       |
| SEC-026 | `1 OR 1=1` in claim ID              | Only user's own claims returned | Parameterized queries         |
| SEC-027 | Unicode bypass `\u0031`             | Handled as normal input         | Proper encoding/escaping      |
| SEC-028 | Time-based blind SQLi `SLEEP(5)`    | Query executes normally         | Parameterized prevents timing |

#### Category 3: Sensitive Data Protection

##### Data Classification & Handling

| Test ID | Data Type                    | Classification      | Test Scenario    | Expected Result                             |
| ------- | ---------------------------- | ------------------- | ---------------- | ------------------------------------------- |
| SEC-029 | SSN (Social Security Number) | Confidential PII    | Display in UI    | Masked format: XXX-XX-1234                  |
| SEC-030 | Email address                | Confidential PII    | Store & transmit | Encrypted at rest, TLS in transit           |
| SEC-031 | Phone number                 | Confidential PII    | Log for auditing | Partially masked or hashed logs             |
| SEC-032 | Medical records              | Highly Confidential | API response     | Encrypted field-level encryption            |
| SEC-033 | Claim amount                 | Confidential        | Database storage | Encrypted at rest                           |
| SEC-034 | Credential (password)        | Critical            | Display/logging  | Never logged, hashed storage                |
| SEC-035 | Authentication token         | Critical            | Transmission     | HTTPS only, Secure+HttpOnly cookie flags    |
| SEC-036 | 2FA backup codes             | Critical            | Generation       | Generated securely, shown once, then hashed |

##### Encryption Validation

| Test ID | Element                  | Expected                 | Validation                           |
| ------- | ------------------------ | ------------------------ | ------------------------------------ |
| SEC-037 | HTTPS enforcement        | All traffic over HTTPS   | Check HSTS header, no mixed content  |
| SEC-038 | TLS version              | TLS 1.2+                 | Verify ciphers, no SSLv3             |
| SEC-039 | Certificate validation   | Valid certificate        | Check cert chain, expiration, domain |
| SEC-040 | At-rest encryption (PII) | AES-256 encryption       | Verify database encryption enabled   |
| SEC-041 | Data masking in logs     | PII masked in logs       | Search logs for exposed SSN/CC       |
| SEC-042 | API request encryption   | Request bodies encrypted | Verify HTTPS for POST/PUT            |

#### Category 4: Session Management

##### Session Security

| Test ID | Scenario                            | Expected Behavior                   | Notes                              |
| ------- | ----------------------------------- | ----------------------------------- | ---------------------------------- |
| SEC-043 | Session timeout (15 min inactivity) | Auto-logout, re-auth required       | User notified before timeout       |
| SEC-044 | Concurrent session limit            | Only 3 active sessions per user     | 4th session terminates oldest      |
| SEC-045 | Session fixation attack             | Session ID changes at login         | New SID issued post-authentication |
| SEC-046 | Session cookie attributes           | Secure, HttpOnly, SameSite flags    | Verify in Set-Cookie header        |
| SEC-047 | Session invalidation on logout      | Session token becomes invalid       | Cannot reuse after logout          |
| SEC-048 | Cross-site session exploitation     | Session not usable cross-site       | SameSite=Strict enforced           |
| SEC-049 | Session replay                      | Old session cannot be replayed      | Token includes timestamp/nonce     |
| SEC-050 | Concurrent logout                   | All sessions end on explicit logout | Across all devices                 |

#### Category 5: API Security

##### API Endpoint Security

| Test ID | Test Scenario                   | Expected Result                               |
| ------- | ------------------------------- | --------------------------------------------- | ------------------------ |
| SEC-051 | Unauthenticated API call        | 401 Unauthorized                              |
| SEC-052 | API rate limiting exceeded      | 429 Too Many Requests                         |
| SEC-053 | Invalid API key/token           | 401 Unauthorized, no details in response      |
| SEC-054 | Accessing disabled API version  | 410 Gone or deprecation notice                |
| SEC-055 | Missing required API parameters | 400 Bad Request with field-level errors       |
| SEC-056 | API returning sensitive headers | Verify no `X-Powered-By`, `Server` disclosure |
| SEC-057 | API HTTP method restriction     | DELETE disabled, only GET/POST/PUT            | Default deny approach    |
| SEC-058 | API query string injection      | Parameters properly escaped                   | Verify in logs/responses |

##### API Data Validation

| Test ID | Validation Type        | Test Case                      | Expected Result                      |
| ------- | ---------------------- | ------------------------------ | ------------------------------------ |
| SEC-059 | Input length           | Field >max length (5000 chars) | Rejected with error message          |
| SEC-060 | Input type             | Phone field receives text      | Validation error, data not persisted |
| SEC-061 | Date format validation | Invalid date format            | Error: "Invalid date format"         |
| SEC-062 | Enum validation        | Invalid enum value             | Rejected, allowed values shown       |

#### Category 6: File Upload Security

##### File Upload Validation

| Test ID | File Type           | Test Scenario                | Expected Result                           | Notes                             |
| ------- | ------------------- | ---------------------------- | ----------------------------------------- | --------------------------------- |
| SEC-063 | Executable          | Try uploading .exe file      | Rejected: "File type not allowed"         | Critical - prevent code execution |
| SEC-064 | Script              | Upload .js or .html          | Rejected: "File type not allowed"         | Prevent script execution          |
| SEC-065 | Archive             | Upload .zip with nested .exe | Rejected: "File type not allowed"         | Check nested contents             |
| SEC-066 | Malformed PDF       | Upload corrupted PDF         | Scanned, flagged if malicious             | Virus scanning                    |
| SEC-067 | File size bomb      | Upload valid 100MB PDF       | Rejected: "File exceeds limit"            | Prevent DoS                       |
| SEC-068 | Double extension    | Upload "document.pdf.exe"    | Rejected based on actual type             | Don't trust extension             |
| SEC-069 | Null byte injection | Filename with \x00           | Sanitized, no directory traversal         | Path traversal prevention         |
| SEC-070 | MIME type mismatch  | PDF file with .jpg extension | Validation via magic bytes, not extension | Proper file type checking         |

#### Category 7: Configuration & Deployment Security

##### Security Headers

| Header                    | Expected Value                      | Test Method                       |
| ------------------------- | ----------------------------------- | --------------------------------- |
| Strict-Transport-Security | max-age=31536000; includeSubDomains | Check HSTS presence, validity     |
| Content-Security-Policy   | Restrictive policy defined          | Validate inline script prevention |
| X-Content-Type-Options    | nosniff                             | Prevent MIME type guessing        |
| X-Frame-Options           | DENY or SAMEORIGIN                  | Clickjacking prevention           |
| X-XSS-Protection          | 1; mode=block                       | Legacy XSS protection             |
| Referrer-Policy           | strict-origin-when-cross-origin     | Control referrer information      |
| Permissions-Policy        | Restrict camera, microphone, etc.   | Feature policy enforcement        |

##### SSL/TLS Configuration

| Test ID | Validation            | Expected                   | Tool                        |
| ------- | --------------------- | -------------------------- | --------------------------- |
| SEC-071 | SSL/TLS certificate   | Valid, non-expired         | SSL Labs A+ rating          |
| SEC-072 | Cipher suite strength | No weak ciphers (DES, RC4) | SSL Labs analysis           |
| SEC-073 | TLS version           | 1.2 minimum, 1.3 preferred | SSL Labs scan               |
| SEC-074 | Certificate pinning   | Critical endpoints pinned  | Monitor certificate updates |
| SEC-075 | CRL/OCSP checking     | Valid revocation status    | Active OCSP stapling        |

### Security Testing Tools

#### Static Application Security Testing (SAST)

- **SonarQube**: Code quality and security scanning
- **Checkmarx**: Vulnerability detection
- **WhiteSource/Mend**: Dependency vulnerability scanning

#### Dynamic Application Security Testing (DAST)

- **OWASP ZAP**: Automated web security scanning
- **Burp Suite**: Manual penetration testing
- **Playwright** with security assertions: Custom security validation

#### Dependency Scanning

- **npm audit**: Node.js dependency vulnerabilities
- **pip audit** (Python): Python package vulnerabilities
- **OWASP Dependency-Check**: Component vulnerability identification

#### Secrets Management

- **GitGuardian**: Secret detection in repositories
- **Vault**: Secure credential management
- **AWS Secrets Manager**: Cloud secrets storage

### Security Test Implementation in Playwright

#### Testing Authentication

```javascript
test('Unauthenticated user cannot access claims', async ({ page }) => {
  await page.goto('/claims');
  expect(page.url()).toContain('/login');
  expect(await page.locator('text=Log In').isVisible()).toBeTruthy();
});

test('Expired token triggers re-authentication', async ({ page }) => {
  await loginWithExpiredToken(page);
  await page.goto('/appointments');
  expect(page.url()).toContain('/login');
});
```

#### Testing XSS Prevention

```javascript
test('XSS payload in name field is sanitized', async ({ page }) => {
  await page.fill('input[name="veteranName"]', '<script>alert("xss")</script>');
  await page.click('button[type="submit"]');
  const savedName = await page.locator('text=Veteran Name').textContent();
  expect(savedName).not.toContain('<script>');
});
```

#### Testing CSRF Protection

```javascript
test('Request without CSRF token is rejected', async ({ request }) => {
  const response = await request.post('/api/appointments', {
    data: { clinicId: 'clinic123' },
    headers: { 'Content-Type': 'application/json' },
    // No X-CSRF-Token header
  });
  expect(response.status()).toBe(403);
});
```

#### Testing Sensitive Data Masking

```javascript
test('SSN is masked in UI', async ({ page }) => {
  await loginAsVeteran(page);
  await page.goto('/profile');
  const ssn = await page.locator('text=SSN').textContent();
  expect(ssn).toMatch(/XXX-XX-\d{4}/);
});

test('Password is never logged', async ({ page }) => {
  const logs = [];
  page.on('console', (msg) => logs.push(msg.text()));
  await page.fill('input[type="password"]', 'MySecurePassword123!');
  const passwordExposed = logs.some((log) => log.includes('MySecurePassword123'));
  expect(passwordExposed).toBeFalsy();
});
```

### Security Testing Timeline & Execution

#### Pre-Release Security Testing

- Run SAST on code commits (daily)
- Run DAST on staging environment (weekly)
- Run dependency scans (weekly)
- Manual penetration testing (bi-weekly)
- Security architecture review (quarterly)

#### Continuous Security Monitoring

- Monitor for emerging CVEs in dependencies
- Track security metrics and trends
- Alert on security events in logs
- Regular vulnerability reassessment

### Security Test Data

#### Test Accounts

- `veteran@example.com` - Standard veteran user
- `admin@example.com` - Admin user (for authorization tests)
- `expired-creds@example.com` - Expired/locked account
- Multiple accounts for concurrent session testing

#### Sensitive Test Data

- Real-looking but fake SSNs (999-80-0000 range)
- Real-looking but invalid credit cards
- Test medical records with realistic PII
- Non-production encryption keys

---

## Data-Driven Testing Strategy

### Overview

Data-driven testing enables comprehensive validation across multiple datasets, scenarios, and configurations without code duplication, maximizing test coverage and maintainability.

### Data-Driven Testing Objectives

- Validate functionality across diverse data sets
- Reduce test code duplication
- Enable easy addition of new test scenarios
- Ensure consistency in test execution
- Facilitate easier test maintenance and updates

### Data-Driven Testing Approaches

#### Approach 1: Parameterized Test Cases

##### Benefits Application Data-Driven Tests

| Test ID   | Benefit Type              | Eligibility Status | Annual Income | Expected Field                 |
| --------- | ------------------------- | ------------------ | ------------- | ------------------------------ |
| BEN-DT-01 | Disability Compensation   | Eligible           | $50,000       | Disability rating (%)          |
| BEN-DT-02 | GI Bill                   | Eligible           | $75,000       | School code                    |
| BEN-DT-03 | Surviving Spouse Benefits | Eligible           | $30,000       | Service member SSN             |
| BEN-DT-04 | Dependent Education       | Eligible           | $100,000      | Dependent age                  |
| BEN-DT-05 | Vocational Rehab          | Non-eligible       | $120,000      | Not eligible - ineligible form |
| BEN-DT-06 | Housing Assistance        | Eligible           | $0            | Housing status                 |

##### Appointment Scheduling Data-Driven Tests

| Test ID   | Clinic     | Provider Type | Distance   | Availability | Expected                  |
| --------- | ---------- | ------------- | ---------- | ------------ | ------------------------- |
| APT-DT-01 | Boston VA  | Primary Care  | Local      | High         | Appointment booked        |
| APT-DT-02 | Telehealth | Mental Health | Remote     | Medium       | Remote appointment        |
| APT-DT-03 | Houston VA | Cardiology    | 250 miles  | Low          | Limited slots shown       |
| APT-DT-04 | NYC VA     | Orthopedic    | 100 miles  | None         | "No availability" message |
| APT-DT-05 | Remote     | Dermatology   | 500+ miles | High         | Remote only option        |

##### Claims Status Data-Driven Tests

| Test ID   | Claim Type | Status       | Months Processing | Expected Actions               |
| --------- | ---------- | ------------ | ----------------- | ------------------------------ |
| CLM-DT-01 | Disability | Pending      | 2                 | View status, upload docs       |
| CLM-DT-02 | Dependency | Approved     | 6                 | View decision, download letter |
| CLM-DT-03 | Education  | Under Review | 1                 | View timeline, submit docs     |
| CLM-DT-04 | Housing    | Denied       | 3                 | View denial, appeal option     |
| CLM-DT-05 | Vocational | In Progress  | 4                 | View milestones, submit proof  |

##### Profile Data-Driven Tests

| Test ID   | Field Type | Valid Input                        | Invalid Input | Error Message          |
| --------- | ---------- | ---------------------------------- | ------------- | ---------------------- |
| PRF-DT-01 | Email      | user@va.gov                        | user@invalid  | "Invalid email format" |
| PRF-DT-02 | Phone (US) | (202) 555-0123                     | 123456789     | "Invalid phone format" |
| PRF-DT-03 | Address    | 123 Main St, Springfield, IL 62701 | 123 Main St   | "Incomplete address"   |
| PRF-DT-04 | Password   | MyP@ss1234!9                       | password123   | "Weak password"        |
| PRF-DT-05 | Date       | 01/15/1970                         | 13/32/1970    | "Invalid date"         |
| PRF-DT-06 | ZIP code   | 12345 / 12345-6789                 | 1234          | "Invalid ZIP code"     |

##### Secure Messaging Data-Driven Tests

| Test ID   | Message Type         | Recipient Type   | Attachment | Expected              |
| --------- | -------------------- | ---------------- | ---------- | --------------------- |
| MSG-DT-01 | Appointment question | Clinic           | None       | Routed to clinic      |
| MSG-DT-02 | Prescription refill  | Pharmacy         | None       | Routed to pharmacy    |
| MSG-DT-03 | Complaint            | Administrator    | None       | Escalated to admin    |
| MSG-DT-04 | Medical question     | Doctor           | PDF doc    | Message + file stored |
| MSG-DT-05 | General inquiry      | Care coordinator | Image      | Routed correctly      |

#### Approach 2: CSV-Based Test Data

##### Sample CSV: Benefits Application Test Data

```csv
benefit_type,eligibility_status,annual_income,expected_field,expected_validation
"Disability Compensation","Eligible","50000","Disability rating","Required if income > 30000"
"GI Bill","Eligible","75000","School Code","Must be valid institution"
"Surviving Spouse","Eligible","30000","Service Member SSN","Must match record"
"Dependent Education","Eligible","100000","Dependent Age","Must be 18-23"
"Vocational Rehab","Non-Eligible","120000","N/A","Show ineligibility reason"
```

##### Sample CSV: Appointment Slots

```csv
clinic_id,clinic_name,provider,specialty,date,time,capacity,status
"CLI-001","Boston VA","Dr. Smith","Primary Care","2026-02-25","09:00","5","Available"
"CLI-001","Boston VA","Dr. Smith","Primary Care","2026-02-25","10:00","1","Available"
"CLI-002","Telehealth","Dr. Jones","Mental Health","2026-02-26","14:00","10","Available"
"CLI-003","Houston VA","Dr. Brown","Cardiology","2026-03-01","11:00","0","Booked"
```

#### Approach 3: Fixture-Based Test Data

##### JavaScript Fixture Example

```javascript
// tests/fixtures/veteranTestData.js
export const veteranAccounts = [
  {
    id: 'vet-001',
    email: 'veteran1@example.com',
    status: 'active',
    eligibleBenefits: ['disability', 'gi-bill'],
    claims: 5,
    appointments: 2,
  },
  {
    id: 'vet-002',
    email: 'veteran2@example.com',
    status: 'archived',
    eligibleBenefits: ['housing'],
    claims: 0,
    appointments: 0,
  },
];

export const claimTypes = [
  { type: 'disability', processingDays: 60, requiresDocuments: true },
  { type: 'education', processingDays: 30, requiresDocuments: false },
  { type: 'housing', processingDays: 45, requiresDocuments: true },
];
```

#### Approach 4: Database Seeding for Complex Scenarios

##### Database Seed Script

```sql
-- Seed veteran with multiple claims and appointments
INSERT INTO veterans (id, email, status)
VALUES ('vet-ddt-001', 'ddt-veteran@example.com', 'active');

INSERT INTO claims (veteran_id, type, status, created_date)
VALUES
  ('vet-ddt-001', 'disability', 'pending', NOW() - INTERVAL '30 days'),
  ('vet-ddt-001', 'housing', 'approved', NOW() - INTERVAL '90 days'),
  ('vet-ddt-001', 'education', 'under-review', NOW() - INTERVAL '15 days');

INSERT INTO appointments (veteran_id, clinic_id, provider_id, status, scheduled_date)
VALUES
  ('vet-ddt-001', 'cli-001', 'doc-001', 'confirmed', NOW() + INTERVAL '5 days'),
  ('vet-ddt-001', 'cli-002', 'doc-002', 'completed', NOW() - INTERVAL '10 days');
```

### Data-Driven Test Implementation

#### Playwright Parameterized Tests

```javascript
import { test, expect } from '@playwright/test';
import { benefitTypes } from './testData/benefits';

// Loop through benefit types
for (const benefit of benefitTypes) {
  test(`Submit ${benefit.type} application`, async ({ page }) => {
    await page.goto('/benefits/apply');
    await page.selectOption('select#benefit-type', benefit.type);

    if (benefit.requiresEligibility) {
      await page.fill('input#eligibility', benefit.eligibilityCode);
    }

    await page.click('button[type="submit"]');

    const confirmation = await page.locator(`text=${benefit.confirmationMessage}`);
    expect(confirmation).toBeVisible();
  });
}
```

#### Test Generators for Dynamic Scenarios

```javascript
// Generate test cases dynamically
const clinics = await loadClinics();
const availableDates = generateDatesForNextMonth();

clinics.forEach((clinic) => {
  availableDates.forEach((date) => {
    test(`Schedule appointment at ${clinic.name} on ${date}`, async ({ page }) => {
      await scheduleAppointment(page, clinic.id, date);
      // Assertions
    });
  });
});
```

#### CSV Data Loading in Tests

```javascript
import * as csv from 'csv-parse/sync';
import * as fs from 'fs';

const testData = csv.parse(fs.readFileSync('test-data/claims.csv'), { columns: true });

testData.forEach((row) => {
  test(`View ${row.claim_type} claim with ${row.status} status`, async ({ page }) => {
    const claim = await retrieveTestClaim(row.claim_id);
    expect(claim.status).toBe(row.status);
  });
});
```

### Test Data Management

#### Test Data Organization

```
tests/
├── fixtures/
│   ├── veterans.js       # Veteran account data
│   ├── clinics.js        # Clinic and provider data
│   ├── claims.js         # Claim data
│   └── messages.js       # Message data
├── data/
│   ├── benefits.csv      # Benefit types and eligibility
│   ├── appointments.csv  # Appointment slots
│   ├── claims.csv        # Claims test dataset
│   ├── profiles.csv      # Profile update scenarios
│   └── messages.csv      # Message test data
└── seeds/
    ├── seedDatabase.sql  # Database initialization
    └── cleanupDatabase.sql # Test cleanup
```

#### Test Data Lifecycle

1. **Setup**: Load test data from fixtures/CSV into test environment
2. **Execution**: Run tests using parameterized data
3. **Validation**: Assert expected outcomes based on data
4. **Teardown**: Clean up test data after execution
5. **Archival**: Maintain test data history for regression analysis

### Data-Driven Coverage Matrix

#### Coverage by Functionality

| Functionality          | Positive Cases | Negative Cases | Edge Cases | Data Sets                            |
| ---------------------- | -------------- | -------------- | ---------- | ------------------------------------ |
| Benefits Application   | 5              | 5              | 3          | 6 benefit types                      |
| Appointment Scheduling | 5              | 5              | 3          | 5 clinics × 3 availability levels    |
| Claims Status          | 5              | 3              | 3          | 5 claim types × 5 statuses           |
| Profile Management     | 8              | 5              | 4          | 6 field types × validation scenarios |
| Secure Messaging       | 5              | 4              | 3          | 5 message types × 3 attachment types |

#### Data Combination Strategies

##### Pairwise Testing (Reduce Test Case Explosion)

For form with 5+ fields, use pairwise combination to reduce from 2^N to ~N^2 test cases:

- Benefits Application: 32 possible combinations → 10 pairwise test cases
- Profile Update: 48 possible combinations → 15 pairwise test cases

##### Equivalence Partitioning

Group similar data into equivalence classes to reduce redundant tests:

- Valid email addresses (one representative)
- Invalid email formats (one representative per pattern)
- Boundary values (empty, max length, just under max)

### Data-Driven Test Metrics

#### Coverage Measurement

- Number of data combinations tested
- Percentage of business logic paths covered
- Number of edge cases validated
- Data type coverage (valid, invalid, boundary)

#### Reporting

- Test results grouped by data parameter
- Failed test cases mapped to specific data values
- Data-driven test execution time and efficiency
- Recommendation for additional test data

---

## Cross-Functional Test Considerations

### Parallel Test Execution

- Tests within each functionality can run in parallel with proper test data isolation
- Different functionalities can be tested concurrently (5 separate suites)
- Use separate test databases or namespaced test data for parallel runs

### Test Data Management

- Implement database reset between test suite runs
- Use factory patterns for consistent test data creation
- Maintain separate test data sets for different environments (dev/staging/prod-like)
- Use unique identifiers (timestamps, UUIDs) for data isolation in parallel execution

### Authentication & Session Management

- Implement centralized authentication fixture
- Reuse authenticated sessions across related tests
- Properly clear cookies and local storage between user scenarios
- Test both new sessions and existing/stale sessions

### Mocking & API Strategy

- Mock all external APIs (eligibility, appointments, payments, etc.)
- Implement both happy-path and error-path mocks
- Use network interception for API validation without modifying code
- Validate that correct endpoints are called with correct payloads

### Reporting & Traceability

- Capture screenshots on every assertion failure
- Generate trace files for debugging failed tests
- Log all API requests/responses for test analysis
- Create detailed test reports with pass/fail rates and failure reasons
- Map test cases to user stories and business requirements

### Environment Configuration

- Support configuration for dev, staging, and production-like environments
- Manage environment-specific URLs, credentials, and test data
- Document environment setup and prerequisites
- Validate environment readiness before running tests

### Accessibility Testing

- Test keyboard navigation for each functionality
- Validate screen reader compatibility for critical flows
- Test high-contrast mode for visibility
- Ensure ARIA labels are correct and complete

### Internationalization Testing (Future Phase)

- Test with different language settings
- Validate date/time/currency formatting by locale
- Test RTL (Right-to-Left) languages if applicable
- Ensure special characters render correctly

---

## Playwright Configuration Guidelines

### Browser Options

```
Use chromium for primary testing
Include Firefox and WebKit for cross-browser validation
Test on multiple viewport sizes (mobile, tablet, desktop)
```

### Test Organization

```
Organize tests by functionality (as defined in this plan)
Create separate test files for each functionality
Group related scenarios using test suites and describe blocks
Use meaningful test names that describe the scenario
```

### Fixtures & Setup

```
Create authentication fixture for user login
Implement database reset fixture for test isolation
Create API mocking fixtures for consistent responses
Build time/timezone manipulation fixtures
```

### Error Handling

```
Capture full page screenshots on failure
Generate trace files for debugging
Log all API interactions
Provide detailed error messages
```

### Performance Monitoring

```
Track page load times for each navigation
Monitor API response times
Validate rendering performance for large datasets
Report performance metrics in test results
```

---

## Success Criteria

- All positive test cases pass consistently
- All negative cases properly reject invalid inputs
- All edge cases handled gracefully without crashes
- All security tests pass (auth, CSRF, XSS, injection prevention)
- Performance metrics meet defined targets
- All test cases automatable at 80%+ coverage
- Zero critical security vulnerabilities detected
- 100% of test scenarios documented and traceable
- Test execution time <30 minutes for full suite
- Test maintenance effort minimal with descriptive assertions

---

## Document Control

- **Version**: 1.0
- **Created Date**: February 18, 2026
- **Last Updated**: February 18, 2026
- **Author**: Senior QA/Test Architect
- **Purpose**: Blueprint for Playwright test automation of VA.gov critical functionalities
- **Status**: Ready for Implementation

---

End of Test Plan Document
