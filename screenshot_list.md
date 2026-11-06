# SmartQueue — Screenshots & Figures Guide for Project Documentation

This guide provides the exact list of screenshots and diagram figures needed for the project report (**`SmartQueue_Project_Documentation_Final.docx`**), their precise chapter positions, dimensions, and instructions on how to capture them from your application.

---

## 📸 Section A: Application UI Screenshots (Chapter 10 Results & Preliminary List of Figures)

Capture these screens directly by running the app (`flutter run -d windows` or on your mobile device) using the test credentials.

---

### Screenshot 1: Login & Self-Registration Screen
- **Figure Label**: `Fig. 10.1 SmartQueue Authentication Screen (Login & Student Registration)`
- **Chapter / Location**: 
  - **Preliminary Pages**: Under *LIST OF FIGURES* (Page iii)
  - **Chapter 10**: Right under the Chapter 10 introduction paragraph (before Table 8 / Section 10.1)
- **Placeholder in Docx**: `[SCREENSHOT 1 HERE: Login & Self-Registration Screen]`
- **How to Capture**:
  1. Launch the app (`flutter run -d windows` or launch the APK on phone).
  2. The initial screen loaded is the Login Screen.
  3. Enter Roll Number `22A61A0501` and password `password123` (or toggle to the Register tab).
  4. Capture full window or mobile screenshot.
- **Recommended Dimensions**: 5.5 to 6.0 inches width (aspect ratio maintained, centered).

---

### Screenshot 2: Student Home — Live Campus Queues
- **Figure Label**: `Fig. 10.2 Student Portal — Service Center Directory & Active Queues`
- **Chapter / Location**: 
  - **Preliminary Pages**: Under *LIST OF FIGURES*
  - **Chapter 10**: Under Table 8 / Section 10.1
- **Placeholder in Docx**: `[SCREENSHOT 2 HERE: Student Portal — Service Center Directory & Active Queues]`
- **How to Capture**:
  1. Sign in as Student (`22A61A0501` / `password123`).
  2. You will be on the *Live Campus Queues* tab showing service cards (Examination Section, Accounts, Library, Department Office).
  3. Ensure the search bar and *Join Queue* buttons are clearly visible.
  4. Capture the screenshot.
- **Recommended Dimensions**: 6.0 inches width (centered).

---

### Screenshot 3: Live Queue Ticket & Tracking Screen
- **Figure Label**: `Fig. 10.3 Student Live Queue Ticket & Turn Position Monitor`
- **Chapter / Location**: 
  - **Chapter 10**: Immediately following Fig. 10.2
- **Placeholder in Docx**: `[SCREENSHOT 3 HERE: Student Live Queue Ticket & Turn Position Monitor]`
- **How to Capture**:
  1. On the Student Home screen, tap **Join Queue** on any active service (e.g., Hall Ticket Collection).
  2. The Live Queue Ticket screen opens showing the numbered token circle (`#Token`), status chip (`WAITING` or `CALLED`), your current position, and Estimated Wait Time (EWT).
  3. Capture this screen.
- **Recommended Dimensions**: 5.0 to 5.5 inches width (centered).

---

### Screenshot 4: Staff Counter Workspace (Counter Operations Desk)
- **Figure Label**: `Fig. 10.4 Staff Counter Workspace (Live Queue Line, Call Next & Now Serving)`
- **Chapter / Location**: 
  - **Chapter 10**: Following Fig. 10.3
- **Placeholder in Docx**: `[SCREENSHOT 4 HERE: Staff Counter Workspace (Live Queue Line, Call Next & Now Serving)]`
- **How to Capture**:
  1. Sign out and sign in as Staff (`STAFF001` / `password123`).
  2. Select **Counter 1** (or any counter).
  3. The workspace displays the top bar (`[ ⇄ Switch Desk ]`, `[ • Available ▼ ]`, `[ ⟳ ]`), the *Now Serving* card, action buttons (`Call Next`, `Complete`, `No-Show`), and the *Live Waiting Line*.
  4. Capture the desktop workspace or mobile view.
- **Recommended Dimensions**: 6.0 inches width (centered).

---

### Screenshot 5: Admin Live Campus Monitor & Operations Analytics
- **Figure Label**: `Fig. 10.5 Administrator Suite — Live Campus Monitor & Throughput Analytics`
- **Chapter / Location**: 
  - **Chapter 10**: Following Fig. 10.4
- **Placeholder in Docx**: `[SCREENSHOT 5 HERE: Administrator Suite — Live Campus Monitor & Throughput Analytics]`
- **How to Capture**:
  1. Sign out and sign in as Administrator (`ADMIN001` / `password123`).
  2. Navigate to **Live Campus Monitor** (showing active counters, waiting students, completions) or **Analytics & Reports** (showing the `fl_chart` daily throughput bar chart and peak hours heatmap).
  3. Capture the screen.
- **Recommended Dimensions**: 6.0 inches width (centered).

---

## 📐 Section B: Architecture & UML Diagrams (Chapter 3 & Chapter 5)

If your department guide requests UML diagrams in Chapter 3 and Chapter 5, here are the positions and recommended contents:

| Figure No | Caption | Chapter Location | Description / Content |
|:---|:---|:---|:---|
| **Fig. 3.1** | `Workflow of the Proposed System` | **Chapter 3**, Section 3.4 (under proposed system overview) | Flowchart: Student App (Join Queue) → Supabase Realtime (Token Generation & RLS) → Staff Console (Call & Serve) → Session Completed & Live Analytics update. |
| **Fig. 5.1** | `SmartQueue System Architecture` | **Chapter 5**, Section 5.1 (under architecture description) | Clean Architecture 4-tier diagram: Presentation (Flutter UI) ↕ State Management (Riverpod) ↕ Repositories/Domain (StateMachine, EwtCalculator) ↕ Backend (Supabase PostgreSQL + RLS + Realtime). |
| **Fig. 5.2** | `SmartQueue Class Diagram` | **Chapter 5**, Section 5.2.1 | UML Class diagram showing entities: `AppUser`, `QueueEntry`, `Queue`, `Counter`, `Service`, `ServiceCenter`, `QueueStateMachine`, and `EwtCalculator`. |
| **Fig. 5.3** | `SmartQueue Use Case Diagram` | **Chapter 5**, Section 5.2.2 | Use cases for **Student** (Register, Join Queue, Track EWT, Cancel), **Staff** (Select Counter, Call Next, Serve, Complete, Switch Desk), and **Admin** (Manage Centers, Counters, View Analytics). |
| **Fig. 5.4** | `Sequence Diagram — Student Queue Join Flow` | **Chapter 5**, Section 5.2.3 | Sequence: Student → GoRouter/UI → `QueueRepository.joinQueue()` → Supabase `get_or_create_today_queue` RPC → Realtime WebSocket emission → Token Screen update. |
| **Fig. 5.5** | `Entity-Relationship (ER) Diagram` | **Chapter 5**, Section 5.2.4 | Database schema diagram showing 9 tables: `users`, `service_centers`, `services`, `counters`, `queues`, `queue_entries`, `queue_events`, `service_sessions`, `ewt_stats` with primary and foreign key links. |

---

## 🛠️ Step-by-Step Instructions: How to Insert Images into the Word Document

1. Open **`SmartQueue_Project_Documentation_Final.docx`** in Microsoft Word, LibreOffice Writer, or Google Docs.
2. Press **Ctrl + F** (Find) and search for the placeholder tag (e.g. `[SCREENSHOT 1 HERE:`).
3. Delete the placeholder text box or text tag.
4. Click **Insert** → **Pictures** → **This Device...** and choose your screenshot image file.
5. Right-click the inserted image → **Wrap Text** → select **In Line with Text** (keeps pagination and formatting clean).
6. Click **Center Align** (**Ctrl + E**) on the image paragraph.
7. Verify that the caption below the image matches the figure numbering.
8. Save the document (**Ctrl + S**).
