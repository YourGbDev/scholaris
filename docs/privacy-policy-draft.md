# Scholaris Privacy Policy (Draft)

> **Notice:** This document is an initial draft prepared for alignment with the **Philippine Data Privacy Act of 2012 (Republic Act No. 10173)**, its Implementing Rules and Regulations (IRR), and relevant National Privacy Commission (NPC) circulars. It reflects the architecture and data structures currently implemented in the Scholaris platform codebase. Items marked with **`[CONFIRM]`** require operational, legal, or administrative decisions before publication. Items marked with **`[PLACEHOLDER]`** require authorized institutional details.

**Effective Date:** [CONFIRM: Platform launch date or council ordinance effectivity date]  
**Last Updated:** October 1, 2026  
**Personal Information Controller (PIC):** [PLACEHOLDER: Legal Name of Operating Entity or Local Government Unit, e.g., City Government of Manila / Scholaris Technologies Inc.]  
**NPC Registration No.:** [PLACEHOLDER: National Privacy Commission Registration Number, e.g., PIC-REG-XXXX-XXXX]  

---

## 1. Introduction & Welcome

Welcome to **Scholaris**! Scholaris is a digital scholarship matching and grant management platform designed to help Filipino students find, apply for, and receive academic scholarships from local government units (LGUs), state colleges and universities (SUCs), government agencies (such as DOST and CHED), and accredited private organizations or philanthropists.

Because Scholaris helps connect you with educational grants, you share important personal and academic information with us. We treat your personal information with deep respect and dignity. This Privacy Policy explains in simple, straightforward English:
- What information we collect from you;
- Why we need it;
- Who can see it (and who cannot);
- How our technology protects it; and
- How you can exercise your statutory rights under **Republic Act No. 10173 (The Data Privacy Act of 2012)**.

---

## 2. What We Collect (Data Inventory)

Scholaris only collects information necessary to match you with grants, review your eligibility, verify scholarship providers, release financial aid, and keep your account secure. Depending on how you use Scholaris, we process the following categories of data:

### A. Student Profile & Demographics
When you create a student account and complete your Scholaris profile, we store:
- **Identity Information:** Full name, email address, profile photo/avatar.
- **Demographic Information:** Gender, nationality (defaults to Filipino), and **birth date**.
  > *Note on Birth Date:* We use your birth date to calculate your age. If you are under 18 years old, special consent requirements apply (see Section 8).
- **Geographic Location:** Region, province, and city/municipality (used to match you with city- or province-specific grants, such as LGU scholarships).
- **Academic Information:** Current educational institution (school/university), enrolled degree course or technical track, current year level (1st–5th year), and General Point Average (GPA).
- **Sensitive Demographics:**
  - **Disability Status (`has_disability`):** An indicator whether you are a Person with Disability (PWD). This is processed solely to match you with dedicated PWD priority allocations or inclusive education grants (such as the Inclusive Education Grant under RA 7277 / RA 10754).
  - **Indigenous Affiliation (`is_indigenous`):** An indicator whether you belong to an Indigenous Cultural Community / Indigenous Peoples (ICC/IP). This is processed solely to match you with affirmative-action grants prioritized for indigenous youth.
  - **Financial Information (`monthly_family_income`):** Self-reported total monthly household income, used to assess eligibility for need-based subsidies (e.g., low-income threshold brackets aligned with DSWD or LGU criteria).

### B. Scholarship Applications & Supporting Documents
When you submit an application to a scholarship listing on Scholaris:
- **Application Record:** The specific scholarship ID, your applicant user ID, application status (`draft`, `submitted`, `under_review`, `approved`, `rejected`, `withdrawn`, `awarded`), timestamp of submission, and reviewer notes.
- **Uploaded Verification Documents:** Electronic files (PDFs, JPEGs, or PNGs) uploaded directly to our private storage bucket (`application_documents`), including:
  - Official or certified copies of Academic Transcripts of Records (TOR) or Certificate of Grades;
  - Barangay or DSWD Certificate of Indigency / Certificate of Low Income;
  - Certificate of Enrollment or School Registration Form;
  - Formal Letters of Recommendation;
  - Government-issued or student identification cards (`id_document`);
  - Other supporting forms required by the specific scholarship benefactor.

### C. Bookmarks & Preferences
- Scholarships you bookmark or favorite for later reference (saved privately in your `bookmarks` record).

### D. Provider Verification Data (For Scholarship Grantors & Sponsors)
If you register on Scholaris as an **Individual Philanthropist** or an **Institutional Grantor/Organization**:
- **Individual Grantor Details:** Full name, email, phone number, government ID type, government ID card number, scanned front copy of valid government ID, biometric selfie holding the ID card, source of scholarship funds, monthly giving budget, Taxpayer Identification Number (TIN), and explicit privacy consent.
- **Organization Grantor Details:** Official registered entity name, organization type (NGO, foundation, corporation, SUC, LGU department), government registration number (SEC, CDA, or DTI), authorized representative's name, position, official email, and contact phone number.
- **Corporate/Legal Verification Files:** Scanned copies of SEC/CDA registration certificates, BIR Certificate of Registration (Form 2303), and Board Resolution or Secretary's Certificate authorizing the scholarship fund.

### E. Grant Disbursements & Payment Records
When a scholarship grant is released to an approved student recipient:
- Unique disbursement record, linked application ID, scholarship ID, and student recipient ID;
- Payout amount (PHP) and payment schedule/frequency (annual, per semester, or one-time);
- Payment channel or method (e.g., GCash, Maya, Landbank, or direct bank transfer) and official electronic transaction reference number;
- Date and timestamp of fund release, and ID of the approving officer or administrator who processed the payout.

### F. Security, Authentication & Audit Logs
To protect our platform against credential theft, brute-force attacks, and fraud:
- **Login Attempts (`login_attempts`):** Email address used to sign in, timestamp of attempt, whether the attempt succeeded or failed, IP address, and browser/device user-agent string.
- **System Audit Ledger (`audit_logs`):** An immutable, time-stamped ledger that records administrative and significant platform actions (such as provider verification approvals, role modifications, account deactivations, user deletions, and disbursement state changes). Log entries record the actor's ID, email, role, target record type, action name, timestamp, and metadata payload.

---

## 3. Why We Collect It (Purpose of Processing)

Under Section 11 of the Data Privacy Act of 2012, personal information must be collected for specified and legitimate purposes. We process your data exclusively for the following purposes:

1. **Automated Eligibility Matching:** Comparing your academic standing (GPA, year level, course), geographic residency (city/province), and demographic profile against the published criteria of available Philippine scholarships so that you discover grants you actually qualify for.
2. **Application Processing & Evaluation:** Presenting your completed application dossier to the authorized evaluators of the scholarship grantor so they can assess, interview, and decide on your award.
3. **Identity Verification & Anti-Fraud:** Verifying the legitimacy of scholarship benefactors before they are permitted to post grants or receive student applications, ensuring students are protected from predatory solicitations.
4. **Grant Disbursement Tracking:** Ensuring that scholarship allowances, tuition subsidies, and stipends reach the rightful recipient, maintaining an auditable financial trail for public LGU and private endowment funds.
5. **Account & Platform Security:** Enforcing automated brute-force protection (progressive account lockout backoff after repeated failed login attempts) and maintaining an immutable audit log of administrative actions.
6. **Regulatory Compliance:** Satisfying statutory audit standards for public funds under Commission on Audit (COA) rules (when LGU funds are disbursed) and reporting requirements under Republic Act No. 10173.

We **never** sell, rent, monetize, or trade your personal data to advertisers, commercial brokers, or third-party marketing companies.

---

## 4. Who Can See Your Data (Access & Row-Level Security)

Scholaris enforces strict **Row-Level Security (RLS)** at the database layer (PostgreSQL / Supabase). This means access rules are coded directly into the database engine and cannot be bypassed simply by manipulating the app interface.

Here is who has access to your data in plain language:

| Data Category | What the Student Sees | What Scholarship Providers See | What Platform Administrators See |
| :--- | :--- | :--- | :--- |
| **Student Profile** | Full access to read and update own profile anytime. | **Restricted Read:** Only providers whose scholarship you have applied to can view your applicant profile. *(See Section 11 regarding ongoing security reviews for sensitive fields).* Providers can never search or view arbitrary student profiles. | Full access to view, update status, and manage profiles across the platform for administrative, verification, and audit purposes. |
| **Bookmarks** | Private to you. Only you can read, add, or delete bookmarks. | **No access.** Providers cannot see your bookmarked scholarships. | **No access via application interface.** |
| **Scholarship Listings** | Can view all active scholarships and eligibility criteria. | Can view, create, edit, and delete only the scholarship listings that they personally created. | Full access to review, audit, and manage all scholarship listings. |
| **Applications** | Can view, create, and edit own applications; can withdraw applications at any stage. | Can view and update review status (`under_review`, `approved`, `rejected`) only for applications submitted to their own scholarships. Cannot set an application to `awarded`. | Can view all applications across the platform; holds exclusive authority to confer final `awarded` status upon verification. |
| **Application Documents** (Transcripts, Certificates, IDs) | Can view, upload, and delete documents attached to own applications while in `draft` or `submitted` status. | Can read submitted documents **only** for applications to their own scholarships, and **only after** the application has been formally submitted (documents in `draft` applications are blocked from providers). | Can read and audit all submitted application documents platform-wide. |
| **Provider Verification & Legal Docs** | **No access.** Students cannot view provider verification records or government IDs. | Can view and update own verification submission while pending or after rejection. Cannot approve own account. | Can view all provider identity documents, run vetting checks, and record approval/rejection decisions with notes. |
| **Disbursements** | Can read own disbursement ledger records, payment methods, amounts, and reference numbers. | **No direct database access.** *(Ledger managed via administrative oversight; provider console interfaces report aggregated grant status).* | Full access to generate, update, release, and audit all disbursement records. |
| **Login Attempts & Audit Logs** | **No access.** (Stored securely on the server; client maintains local session lockout countdown only). | **No access.** | Full access to inspect failed login logs, IP histories, and system-wide audit event trails. |

---

## 5. Third-Party Services & Data Sharing

Scholaris operates using vetted infrastructure providers. The following external systems process data in connection with the platform:

1. **Supabase (Backend, Database & Storage):**
   - **Service:** Scholaris uses Supabase (PostgreSQL database, Supabase Auth, and Supabase Storage) to host and secure application databases, user authentication credentials, and uploaded PDF/image document vaults.
   - **Hosting Location:** [CONFIRM: Cloud region hosting the Supabase project, e.g., AWS ap-southeast-1 Singapore].
   - **Protection:** All communication between the Scholaris client and Supabase is encrypted in transit using standard Transport Layer Security (TLS 1.3 / HTTPS with 256-bit encryption). Access keys in the client application are limited to public anonymous keys with database access strictly governed by PostgreSQL Row-Level Security policies.
2. **Google Fonts (Typography & Rendering):**
   - **Service:** The web application and landing pages load web fonts (Outfit, Poppins, Plus Jakarta Sans, and Material Symbols) from Google Fonts (`fonts.googleapis.com` and `fonts.gstatic.com`).
   - **Data Exchanged:** When downloading font files, your browser or device makes a direct HTTP request to Google's content delivery servers, transmitting your standard device IP address and HTTP user-agent header. Google does not receive your student profile, academic grades, or scholarship data.
3. **Local Device Storage (`shared_preferences` / Browser LocalStorage):**
   - **Service:** Scholaris stores local session authentication tokens (`sb-*-auth-token`) and login failure backoff counters on your local device storage. This allows you to stay signed in between app launches and enforces rate-limiting countdowns locally even if disconnected.
4. **Third-Party Integrations Mentioned in UI:**
   - [CONFIRM: The account settings interface mentions potential future data exchanges with State Universities and Colleges (e.g., UP CRS), CHED UniFAST, and DOST. Direct automated API connections to these systems are **not currently active** in the codebase. Any future automated institutional synchronization will be subject to explicit student consent and data sharing agreements under NPC Circular 16-02].

We do **not** use third-party behavioral advertising trackers, Facebook Pixel, Google Analytics tracking scripts, or commercial data brokers anywhere in the Scholaris Flutter client or landing pages.

---

## 6. How Long We Keep Your Data (Data Retention)

Under Section 11(e) of the Data Privacy Act, personal data shall only be retained as long as necessary for the fulfillment of the declared purposes.

- **Current Code Status:** The Scholaris database and application codebase do not currently execute an automated timer or scheduled purge script for expired user accounts, historical login attempts, or audit logs. In the administrative console settings, **"Audit Log Retention (days)"** is flagged as a feature planned for platform version 2.
- **Application & Document Records:** Transcripts, recommendation letters, and application forms submitted by students are currently preserved to allow students to track historical grants and to comply with public scholarship auditing guidelines.
- **Retention Schedule Policy:**
  - *Active Accounts:* Retained for the duration of the student's active enrollment and use of the platform.
  - *Disbursement & Financial Records:* [CONFIRM: Retention schedule for grant payment vouchers and ledger entries, typically required to be kept for at least 5 to 10 years pursuant to Philippine Commission on Audit (COA) circulars and tax regulations].
  - *Audit Logs & Login History:* [CONFIRM: Defined retention window for system logs, recommended at 12 to 24 months before automated aggregation or archiving].
  - *Inactive or Deactivated Accounts:* If an account is deactivated or marked for deletion upon request, the personal profile is removed or anonymized, subject to regulatory requirements to preserve audited grant records.

---

## 7. Security Measures

Scholaris employs organizational, physical, and technical safeguards designed to protect personal and sensitive personal information against accidental or unlawful destruction, alteration, disclosure, or unauthorized access:

1. **Row-Level Security (RLS) Enforced at the Engine Level:** Access rights are strictly controlled inside the database. A scholarship provider or third party cannot read your application documents or private bookmarks by altering client-side code.
2. **Encrypted Transmission:** All client-server traffic is conducted over HTTPS using TLS encryption with 256-bit keys, guarding against interception on public or campus Wi-Fi networks.
3. **Private Document Storage Buckets:** Both `application_documents` and `provider_documents` are designated as private buckets. Raw storage URLs cannot be indexed by search engines or accessed by unauthenticated internet visitors; files can only be accessed through authenticated, authorized session tokens.
4. **Brute-Force & Lockout Defense:** Scholaris includes a progressive login lockout service (`LoginLockoutService`). If an incorrect password is typed repeatedly for an account:
   - 3 consecutive failed attempts: locked for 5 minutes;
   - 4 consecutive failed attempts: locked for 15 minutes;
   - 5 or more consecutive failed attempts: locked for 60 minutes.
   Lockout statuses are recorded in `login_attempts` to defend student accounts from unauthorized credential guessing.
5. **Anti-Privilege Escalation Triggers:** PostgreSQL database triggers (`guard_profiles_role_change`) prevent users from elevating their own account roles (e.g., changing from `student` to `provider` or `admin`). Roles can only be granted through administrative verification or internal system workflows.
6. **Immutable Audit Trail:** High-impact administrative actions (including approving provider credentials, releasing disbursements, and modifying user account statuses) are automatically recorded in an immutable ledger (`audit_logs`) recording the timestamp, actor identity, and change details.

> *Clarification Regarding Interface Terminology:* While the mobile settings screen references "End-to-End Encrypted," data within the current architecture is secured using industry-standard **transport-level encryption (TLS 1.3 / HTTPS)** in transit and access-controlled cloud database storage at rest. Client-side cryptographic end-to-end zero-knowledge encryption is not currently implemented.

---

## 8. Your Rights Under Republic Act No. 10173

As a student or user in the Philippines, the Data Privacy Act of 2012 provides you with comprehensive statutory rights as a **Data Subject**. Scholaris is fully committed to upholding these rights:

1. **Right to Be Informed:** You have the right to know whether personal data pertaining to you is being collected, processed, and stored, and to be informed of the purposes, scope, and recipients of such processing. This Privacy Policy fulfills this right.
2. **Right to Object:** You have the right to object to the processing of your personal data, especially where processing is based on consent or legitimate interest. If you object, Scholaris will halt processing, except where required by law (e.g., tracking an active, contracted public fund disbursement).
3. **Right to Access:** You have the right to request reasonable access to your personal data, including the contents of your profile, submitted applications, and attached documents.
4. **Right to Correct (Rectification):** You have the right to dispute inaccurate or incorrect data and have it promptly updated.
   - *How to do this in the app:* You can edit your personal details, academic metrics (GPA, course, year level), and demographic location at any time directly through the **Profile** screen (`ProfileTabScreen` / `ProfileSetupScreen`).
5. **Right to Erasure or Blocking:** You have the right to suspend, withdraw, or order the removal or destruction of your personal data from our systems if the data is incomplete, outdated, false, unlawfully obtained, or no longer necessary for the stated purpose.
   - *How to do this in the app:* In the Account Settings screen under "Delete or Deactivate Account," students can initiate an account deletion or deactivation request by contacting `[PLACEHOLDER: support@scholaris.ph]`. A platform administrator processes the permanent removal of the profile (`adminDeleteProfile`), subject to regulatory retention of historical disbursement vouchers.
6. **Right to Data Portability:** Where your data is processed electronically, you have the right to obtain a copy of your personal data in an electronic or structured format for your further use.
   - *Current Implementation:* The Account Settings screen features an "Export My Data Dossier" action. [CONFIRM: An automated background export generator is planned for v2; manual data dossier requests are fulfilled upon request through the Data Protection Officer within [CONFIRM: e.g., 15 business days]].
7. **Right to Damages:** You have the right to be indemnified for any damages sustained due to inaccurate, false, unlawfully obtained, or unauthorized use of your personal data.
8. **Right to File a Complaint with the National Privacy Commission (NPC):** If you believe your rights under the Data Privacy Act have been violated or that Scholaris has failed to address your privacy concerns, you have the absolute right to lodge a formal complaint with the Philippine National Privacy Commission:
   - **National Privacy Commission**  
     5th Floor, Delegation Building, PICC Complex, Roxas Boulevard, Pasay City, Metro Manila 1307  
     Website: `https://www.privacy.gov.ph`  
     Email: `info@privacy.gov.ph` / `complaints@privacy.gov.ph`

---

## 9. Minors and Consent

Scholaris serves college, senior high school, and vocational students across the Philippines. Many incoming freshman and senior high school scholars are **under 18 years of age (minors)**.

- **Age Verification:** The platform collects your date of birth (`birth_date`) during initial profile registration.
- **Parental / Guardian Consent Policy:** Under Philippine civil law and NPC guidelines, minors do not possess the legal capacity to enter into binding independent consent contracts for data processing involving sensitive personal data.
- **Current Technical Implementation:** [CONFIRM: The current app registration flow requires all users to check a general consent box, but does not yet present a dedicated guardian verification step or parental consent upload modal for users whose calculated age is below 18].
- **Interim Procedure for Minor Scholars:** If you are below 18 years of age, you must review this Privacy Policy with your parent, legal guardian, or designated school guidance counselor. By submitting scholarship applications that require income, indigency, and academic transcripts, you affirm that your parent or legal guardian has reviewed and authorized the submission. [CONFIRM: Platform roadmap for implementing a verifiable parental consent mechanism (such as guardian digital sign-off or co-signature) prior to official LGU deployment].

---

## 10. Data Breach Management & Notification

In the unlikely event of a security incident or data breach involving your personal or sensitive personal information:

1. **72-Hour Statutory Notification:** In accordance with Section 20(f) of RA 10173 and **NPC Circular No. 16-03 (Personal Data Breach Management)**, Scholaris will notify both the **National Privacy Commission** and the **affected data subjects within seventy-two (72) hours** upon knowledge of, or reasonable belief that, a personal data breach has occurred involving sensitive personal information or information that may be used to commit identity fraud.
2. **Contents of Notice:** Breach notices will be sent via registered email or SMS and will detail:
   - The nature of the breach and data types involved;
   - The likely consequences and potential risks to you;
   - Measures taken or proposed to be taken by Scholaris to address the breach and mitigate its effects;
   - Recommended actions you can take to protect yourself (such as updating credentials); and
   - Direct contact details of our Data Protection Officer.
3. **Internal Incident Response Team:** [CONFIRM: Institutional protocol defining the LGU / platform incident response team composition and forensic workflow].

---

## 11. Security Transparency & Privacy Risk Disclosures

As part of our commitment to transparent governance and the principle of **Privacy by Design**, we openly document key privacy considerations currently under active engineering review:

1. **Granular Field-Level Privacy for Applicant Profiles:**  
   Provider access to applicant profiles is being limited through a database view that excludes birth date, gender, nationality, phone, email, disability and indigenous status. This takes effect when migrations 0020 and 0021 are applied.
   *Effective Date:* [CONFIRM: date migrations 0020/0021 are applied]
2. **Draft Application Scoping:**  
   Access to uploaded PDF documents is blocked from providers while an application is in `draft` status, and profile read permissions via the `provider_applicant_profiles` view will also be restricted to applications that are not in `draft` status once migrations 0020 and 0021 are applied.
3. **Self-Service Data Export & Erasure Automation:**  
   While the user interface displays informative toast notifications for "Export My Data Dossier" and "Delete or Deactivate Account," fulfillment currently relies on administrative assistance. Engineering is actively building self-service API endpoints for instant JSON dossier download and automated account wiping.

---

## 12. Contact Us (Data Protection Officer)

If you have questions, inquiries, or grievances regarding this Privacy Policy, or if you wish to exercise any of your statutory rights under the Data Privacy Act of 2012, please contact our designated **Data Protection Officer (DPO)**:

- **Attention:** Data Protection Officer (DPO)  
- **Operating Entity:** [PLACEHOLDER: Legal Organization or LGU Department Name]  
- **Office Address:** [PLACEHOLDER: Official Physical Office Address, e.g., City Hall Complex / Registered Tech Office]  
- **Email Address:** [PLACEHOLDER: dpo@scholaris.ph or privacy@scholaris.ph]  
- **Contact Telephone:** [PLACEHOLDER: Official Telephone / Hotline Number]  
- **General Support Desk:** [PLACEHOLDER: support@scholaris.ph]  

---

## 13. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect changes in our platform features, relevant regulations, or guidance issued by the National Privacy Commission.

- When changes are made, we will update the **Last Updated** date at the top of this document.
- For material changes that significantly affect how your personal data is handled, we will provide prominent notice via in-app banners or email notifications before the changes take effect.
- We encourage students and scholarship providers to periodically review this page to stay informed about how we protect your personal information.
