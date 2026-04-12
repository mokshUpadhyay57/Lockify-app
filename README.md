`# Lockify

Lockify is a high-performance, multi-platform messaging and creator platform built with **Flutter** and **Firebase**. It provides a professional communication suite (1-1, Groups, Channels) combined with a powerful monetization engine for digital content and creator engagement.

## 🚀 Key Features

### 📨 Advanced Messaging Engine
*   **Conversation Types:** Production-grade 1-1 Private Chats, community Groups with admin controls, and high-scale broadcast Channels.
*   **Real-Time Presence:** Global status tracking (Online/Offline) with visual indicators across all lists and chat headers.
*   **Atomic Consistency:** Powered by Firestore `WriteBatch` to ensure message previews and history are always in perfect sync.

### 🖼️ Rich Media & Interactive Tools
*   **High-Speed Media:** Instant sending of Images and Videos with WebP compression and Base64 thumbnails for zero-latency UI feedback.
*   **Interactive Polls:** Create, vote, and track live percentage results within any conversation.
*   **Document Support:** Send and preview various file types with a dedicated document UI.

### 🔒 Content Monetization
*   **Locked Messages:** Premium content hidden behind paywalls, allowing creators to monetize exclusive photos, videos, or texts.
*   **Paid Subscriptions:** Monetize broadcast channels with recurring subscription tiers.
*   **Creator Dashboard:** Real-time earnings analytics, subscriber tracking, and monthly revenue data.

### 👤 Identity & Privacy
*   **Local Contact Priority:** Intelligent resolution that prioritizes names from the user's local address book for a personalized experience.
*   **Privacy-First:** Secure multi-provider authentication (Google, Email, Phone) with standardized identity resolution.

---

## 🏗️ Architecture & Tech Stack

*   **Frontend:** Flutter SDK (Clean Architecture / Service-based pattern)
*   **Backend:** Firebase (Auth, Firestore, Cloud Functions, Storage)
*   **UI Components:** Atomic design using unified components (`ChatInput`, `MessageBubble`, `ChatListItem`)
*   **State Management:** Native reactive Streams and StreamControllers (Zero RxDart overhead)

### Folder Structure
```text
lib/
├── components/       # Unified Atomic UI widgets
├── models/           # Data models (Messages, Polls, Users)
├── screens/          # Organized by feature (Auth, Chat, Dashboard, Settings)
├── services/         # Specialized business logic (Auth, Group, Channel, Media)
├── utils/            # Shared mixins, colors, and constants
└── main.dart         # Entry point & App Check initialization
```

---

## 🛠️ Getting Started

### Prerequisites
*   Flutter SDK (3.x recommended)
*   Firebase CLI & Account
*   Android Studio / Xcode (for platform-specific builds)

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/mokshupadhyay57/lockify.git
    cd lockify
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Initialize Firebase:**
    Ensure your `google-services.json` and `GoogleService-Info.plist` are in place, or run `flutterfire configure`.
4.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 📈 Roadmap & Scaling
Lockify is designed for infinite scale. Future milestones include:
*   **Subcollection Membership:** Transitioning to subcollections for handling 100k+ group members.
*   **Atomic Transactions:** Implementing `runTransaction` for critical wallet and payout operations.
*   **Push Notifications:** Cloud-triggered engagement alerts for new messages and sales.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
