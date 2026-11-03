# Student companion and profile roadmap

User-approved November 3, 2026.

## In this change

- Quiet student surfaces from the preceding polish remain.
- Fix reproduced bookmark layout flicker and pending/error/concurrent-save state.
- Repair existing Profile Edit routing rather than shipping a visible dead action. Existing validated personal, academic and financial forms now support save/cancel and return to Profile; initial setup stays a separate flow. Formal increment-four requirement is unconfirmed without the official rubric.
- Three short skippable chat introduction screens shown on EVERY Chat opening (latest November 3 user instruction), replay from help, new transparent chest-up welcome/explain/tools poses for both companions. Skip/Start dismiss only for that visit; ignore old completion preferences.
- Explicit identity exception: boys see Ari in chat after Ariel's Home/tour; girls see Ariel in chat after Ari's Home/tour. Do not change the Home companion.
- QR, upload and Find scholarships remain visible shortcuts with concise explanations and existing functional destinations. No duplicate full tutorial on every tool tap. AI replies are not connected and Send remains unavailable.

## Follow-up implementation

- [ ] Verify profile edit/save/cancel against the real backend and physical iOS build, including validation failures, refresh, interrupted saves and changed matching results. Local widget/repository tests do not replace this.
- [ ] Connect companion to a real AI service with per-user access control, useful error/retry and honest sources for scholarship answers.
- [ ] Return QR lookup results to conversation with actual provider, deadline, requirements and deterministic eligibility checks. No guaranteed acceptance claims.
- [ ] Add document extraction with a review of proposed profile/application changes; apply only after confirmation, never silently overwrite data.
- [ ] Draft application assistance from verified stored data, clearly separated from submitting an application.
- [ ] Review the legacy internal demo percentage cutoff for quick apply and hidden high-fit filter state separately from the current visual cleanup.

Four-worktree test and release contract: `2026-11-03-pre-checking-test-contract.md`. No real AI/backend integration, commit, push or IPA is implied by this roadmap.

## Capstone: scholar experiences and student network

Added November 3, 2026 from the user's community discussion. Roadmap only; not part of the current IPA or increment-four scope unless separately approved against the rubric.

Purpose: help applicants learn from current and former scholars, and give accepted students a meaningful way to return as mentors. Success means useful questions answered and practical experiences shared, rather than time spent scrolling.

### First phase: scholarship discussions and experiences

- [ ] Add a discussion/experiences section inside each scholarship for application questions, requirements, interviews and recipient experiences.
- [ ] Link from the scholarship card with an experience count (for example, “12 scholar experiences”) instead of a scholarship popularity score.
- [ ] Let students mark reviews/answers as helpful with an upvote. Do not add scholarship-card upvote/downvote rankings: popularity or rejection frustration is not evidence of program quality or eligibility.
- [ ] Show a verified-recipient label only when Scholaris can confirm the relationship; distinguish other student contributions and official provider replies/updates.
- [ ] Provide reporting, moderation controls, spam prevention and clear privacy guidance before opening contributions. Keep suspected scam/misleading-listing reports separate from helpful votes.
- [ ] Support accepted scholars returning to share advice; evaluate participation and unanswered questions before expanding community navigation; the later proposed location is a Community tab within Discover, not a new bottom-navigation destination.

### Later exploration: peer-to-peer support

- [ ] Explore an opt-in student network and private peer-to-peer chat after public discussions demonstrate value. This is a candidate direction, not an approved implementation scope.
- [ ] Before private messaging, define contact permissions, blocking/reporting, anti-spam and impersonation handling, moderation responsibilities and protection of personal/application information.
- [ ] Keep provider decisions and eligibility separate from peer advice; do not imply that community membership or votes affect scholarship selection.

### Proposed Discover structure and connections

Recorded November 3, 2026. Direction for careful capstone planning, not authorization to build or include in the current IPA. Product framing: reusable scholarship applications plus a student network focused on financial aid and grants.

- [ ] Explore two tabs inside Discover: Scholarships and Community, with Scholarships selected by default. Validate navigation and accessibility before finalizing.
- [ ] Let students post scholarship journeys (for example, how they obtained two scholarships), practical advice and questions; support comments, replies and helpful engagement. Separate personal claims from verified recipient labels and official provider information.
- [ ] Explore mutual connections through explicit requests and acceptance, with student control over discoverability and who may contact them. Private chat remains a later candidate requiring the controls above.
- [ ] Plan in stages: scholarship discussions/experiences first, mutual connections next, provider discovery after that. Define participation and trust signals before expanding each stage.

### Proposed provider student discovery

- [ ] Explore Suggested students for both individual and organization providers, limited to students who explicitly opt into discovery.
- [ ] Match suggestions to the provider's specific scholarship criteria, not a universal student leaderboard or generic “matching power” score. Explain the matched course/year/location requirements and identify unknown or missing information; do not imply guaranteed selection.
- [ ] Present a limited discovery profile first. Keep grades, income, application documents and contact details private unless the student explicitly chooses to share them with the relevant recipient.
- [ ] Before implementation, plan consent/revocation, provider verification and access permissions, matching accuracy, visibility controls, moderation/reporting, contact requests and evaluation of whether suggestions help students and providers.

### Expanded capstone direction: student profiles, community and opportunity discovery

Recorded November 3, 2026 after further discussion. The user wants this vision retained for capstone planning and a potential public launch even if the academic panel requires a smaller scope. Recording the direction does not establish rubric approval, product implementation or startup viability.

Product purpose: help students discover financial aid, demonstrate their potential and learn from scholarship communities, while helping providers reach relevant applicants. “LinkedIn for students and scholarships” is a useful analogy for profiles, discovery and connections, not an instruction to reproduce LinkedIn's entire feature set.

- [ ] Expand the main student profile with an optional meaningful bio, aspirations, course, projects, research, creative portfolios, community contributions and external links such as GitHub. Let students explain their own contributions and circumstances. Support all disciplines and students without polished portfolios; do not infer ability, effort or the reason for low grades from activity alone.
- [ ] Separate the public/discovery profile from private application details. Students control discoverability, individual post audiences and which optional information providers may see. Provider access to community content does not grant access to private chats, documents, grades, income or contact details.
- [ ] Let students share academic questions, scholarship journeys, personal struggles, unfinished progress and how they overcame difficulties, alongside achievements. Sharing hardship must remain optional; avoid rewarding vulnerability, popularity or constant posting in scholarship discovery or selection.
- [ ] Allow clearly identified individual and organization providers to browse permitted community posts, participate in discussions and view opted-in student profiles. Distinguish official program information from personal advice.
- [ ] Support mutual connection requests and private messaging only after acceptance. Define message/contact controls, blocking, reporting, spam and impersonation handling, moderation responsibilities and any age-related safeguards before release.
- [ ] Let a provider discover a student's work or story and send a structured invitation to apply to an existing scholarship. Include the program, requirements and provider identity, with accept/decline controls. An invitation or connection is not an award or guarantee of acceptance; preserve the formal application and decision process.
- [ ] Explain program-specific required criteria separately from provider preferences and optional evidence of potential. A student's portfolio may inform human review where the published program allows it; it must not silently override hard requirements. Avoid a universal student-worth score, automatic GitHub scoring or popularity-based applicant rankings. Current match explanations must continue to use actual criteria rather than simulated percentages.
- [ ] Keep scholarship experiences and helpful votes connected to the relevant program. Do not introduce downvotes on personal stories or public popularity scores on profiles; retain the earlier decision against scholarship-card popularity rankings.

Intended participation loop: discover a scholarship → ask questions and meet students → apply → share experience → help the next applicant. A second loop is student-controlled profile/work sharing → provider discovery → invitation to apply → formal review. Evaluate useful answers and real opportunities rather than time spent scrolling.

### Proposed academic scope versus later launch

Planning recommendation, not a confirmed academic commitment:

1. Capstone core candidate: richer student profiles, scholarship discussions/experiences with helpful votes, and opt-in provider discovery with invitations to apply.
2. Next candidate: mutual connections; private messaging is a stretch goal until implementation effort, permissions and moderation are planned.
3. Broader launch exploration: a general academic community feed, expanded networking and discovery. Keep scholarship discovery/applications simple and preserve the white, Geist-based visual identity. Community may use different content layouts without replacing the current design system.

Use student/provider research and pilot evidence to refine priority and evaluate comprehension, application friction, relevant invitations and useful participation. Do not claim that panel approval, sustained adoption or a viable business model is established. Provider participation, trust, operating costs and who pays remain open questions.

### Public-benefit and funding exploration

- [ ] Explore possible school, community, government or other public-interest partnerships for a bounded pilot. No funding program, eligibility, commitment or endorsement has been verified.
- [ ] Frame any funding proposal around access to educational support, underserved students, clearer applications and easier program administration. Demonstrate outcomes, accessibility, responsible data handling and sustainable operations; feature count and project difficulty are not evidence of impact.

Next step: a dedicated planning discussion covering user journeys, academic boundaries, data permissions, moderation, matching explanations and phased delivery. No community/network feature implementation is included in this roadmap update.
