BVCEC SmartQueue — Agent Instructions
Project Identity

Project: BVCEC SmartQueue
Institution: Bonam Venkata Chalamayya Engineering College (Autonomous), Odalarevu, Andhra Pradesh, India
Project Type: B.Tech laboratory project
Primary Technology: Flutter / Dart
Primary Platform: Mobile
Secondary Platform: Desktop/tablet if required

1. Mandatory Context

Before making changes, read:

docs/PROJECT_CONTEXT.md

docs/OPEN_QUESTIONS.md

If additional context files are later added under docs/, read the relevant files before modifying the affected feature.

2. Critical Rule: Do Not Invent Requirements

This project is intended to model a real campus service system.

Never invent:

BVCEC service procedures

number of counters

staff responsibilities

service durations

queue rules

priority rules

authentication mechanisms

existing college software

student workflows

If information is unknown, explicitly mark it as:

UNKNOWN

If implementation requires an assumption, document it as:

PROTOTYPE ASSUMPTION

Never present an assumption as an actual BVCEC policy.

3. Project Objective

Build a real-time campus queue-management system that can:

allow users to join virtual queues,

generate tokens,

show queue position,

estimate waiting time,

notify users as their turn approaches,

allow authorized staff to operate counters,

record service sessions,

provide queue/service analytics.

The project should demonstrate genuine software engineering rather than merely CRUD functionality.

4. Product Roles
Student/User

Can:

authenticate,

browse service centers,

browse services,

view queue status,

join a queue,

receive a token,

view queue position,

view estimated waiting time,

cancel a queue entry,

receive notifications,

view queue history.

Staff

Can:

authenticate,

access assigned counter,

view waiting customers,

call next,

start service,

complete service,

skip,

mark no-show,

pause/resume counter.

Administrator

Can:

manage service centers,

manage services,

manage counters,

manage staff assignments,

configure queue settings,

monitor queues,

inspect analytics.

5. Flutter Architecture

Use separation of concerns.

Preferred structure:

View
  ↓
ViewModel / Controller
  ↓
Repository
  ↓
Service / Data Source
  ↓
Backend


Views must not contain business logic.

Do not:

perform database operations directly in widgets,

put queue algorithms inside widgets,

duplicate business logic,

place authentication logic inside UI widgets,

use uncontrolled global mutable state.

Prefer:

immutable models,

repositories,

dependency injection,

feature-based organization,

testable business logic,

explicit loading/error/empty states.

6. Navigation

Use go_router unless there is a documented reason to choose another navigation solution.

Routes must respect authentication and role authorization.

Do not rely solely on hidden UI elements for authorization.

7. Queue Domain

The queue is the core business domain.

Queue operations include:

join,

cancel,

call next,

start service,

complete,

skip,

no-show,

transfer,

pause counter,

resume counter.

All operations must use explicit business rules.

8. Queue State Machine

Valid states:

WAITING
CALLED
SERVING
COMPLETED
CANCELLED
NO_SHOW
TRANSFERRED


Example:

WAITING
   ↓
CALLED
   ↓
SERVING
   ↓
COMPLETED


Alternative paths:

WAITING → CANCELLED
CALLED → NO_SHOW
SERVING → TRANSFERRED


Invalid transitions must be rejected.

9. Data Integrity

Queue state must have one authoritative source.

Never allow multiple clients to independently modify authoritative queue ordering.

Queue operations must account for:

duplicate requests,

network retries,

rapid repeated taps,

stale client state,

concurrent staff operations.

Where appropriate, backend transactions or atomic operations must protect queue mutations.

10. Security

Never:

commit secrets,

hard-code production credentials,

expose API keys unnecessarily,

trust client-provided roles,

expose admin operations to students.

Authorization must be enforced by the backend.

11. Privacy

Collect only information required for the project.

Avoid unnecessary:

personal information,

precise location,

academic records,

sensitive information.

Use synthetic data during development whenever possible.

12. Waiting-Time Prediction

The initial estimator may use historical service durations.

Possible factors:

customers ahead,

service type,

active counters,

counter availability,

estimated service duration,

priority,

customers currently being served.

An adaptive estimate may later use:

newAverage =
    α × latestDuration
    +
    (1 - α) × previousAverage


Do not claim an algorithm is superior without testing it.

13. Priority Queues

Priority handling is optional.

Never implement arbitrary priority categories without confirming the real business requirement.

If priority is implemented, prevent starvation of normal users.

Potential future technique:

effectivePriority =
    basePriority + waitingTimeFactor


This is a design candidate, not an institutional rule.

14. Notifications

Potential notification events:

queue joined,

approaching turn,

token called,

counter assigned,

service completed,

cancellation.

Do not assume a particular notification channel until requirements are confirmed.

15. Testing

Business-critical logic requires automated tests.

At minimum test:

token generation,

queue ordering,

state transitions,

cancellation,

no-show,

waiting-time estimation,

counter assignment,

priority logic,

duplicate operations,

concurrent queue mutations.

Important user journeys should have widget/integration tests.

16. Development Method

Implement vertically.

Example:

Feature
 ↓
Model
 ↓
Repository
 ↓
Business logic
 ↓
ViewModel
 ↓
UI
 ↓
Tests


Do not create large numbers of placeholder screens before implementing actual functionality.

17. Academic Quality

The student must be able to explain:

architecture,

database design,

queue algorithm,

waiting-time prediction,

authentication,

authorization,

testing,

limitations.

Avoid unnecessary complexity.

Do not add technologies merely because they sound impressive.

Do not add:

blockchain,

cryptocurrency,

unnecessary AI,

face recognition,

AR,

IoT,

generic chatbots

unless a genuine requirement emerges.

18. Definition of Done

A feature is complete only when:

requirements are documented,

implementation exists,

loading/error/empty states are handled,

authorization is considered,

data integrity is considered,

relevant tests exist,

UI is usable,

architecture is respected,

no known critical issue is ignored.

19. Source of Truth

Priority order:

Confirmed assignment requirements

Confirmed project requirements

docs/PROJECT_CONTEXT.md

Confirmed BVCEC information

Engineering best practices

Agent suggestions

If sources conflict, report the conflict instead of silently choosing one.