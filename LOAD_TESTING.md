# Load Testing Guide for Lockify

Load testing helps you understand how your application behaves under a specific expected load. For a Flutter app with a Firebase backend like Lockify, load testing primarily focuses on the backend infrastructure (Firebase Authentication, Cloud Firestore, Cloud Functions).

## Recommended Tools

1. **k6 (Grafana k6)**
   - **Why:** k6 is a modern, developer-centric load testing tool built for testing the performance of APIs, microservices, and websites. It uses JavaScript for writing tests.
   - **How it works:** You can write scripts that mimic user interactions with your backend (e.g., calling Cloud Functions via HTTP or simulating Firestore reads/writes if exposed via REST or by using a custom server).
   - **Link:** [k6.io](https://k6.io/)

2. **Artillery**
   - **Why:** Artillery is a modern, powerful, and easy-to-use load testing toolkit. It's written in Node.js and allows you to write test scenarios in YAML or JSON.
   - **How it works:** It excels at testing HTTP, WebSockets, and Socket.io. You can use it to hammer your Firebase HTTP endpoints or Cloud Functions.
   - **Link:** [artillery.io](https://artillery.io/)

3. **Apache JMeter**
   - **Why:** A classic, robust tool designed to load test functional behavior and measure performance.
   - **How it works:** Provides a GUI to construct complex test plans. Can be used to test static and dynamic resources, web dynamic applications.
   - **Link:** [jmeter.apache.org](https://jmeter.apache.org/)

## Testing Strategy for Firebase Apps

Testing a Firebase backend requires a specific approach because direct SDK connections (like the Flutter SDK uses) are often stateful (WebSockets for Firestore real-time updates) and harder to simulate at massive scale purely through standard HTTP load testers without extra setup.

### 1. Test Cloud Functions (HTTP endpoints)
If your app uses HTTP-triggered Cloud Functions for heavy operations, you can easily load test these using any of the tools above.
- Secure your endpoints for testing (e.g., using test tokens if using Firebase Auth).
- Measure response times, error rates, and throughput.

### 2. Test Firestore via REST API
To load test Firestore directly, you can use the Firestore REST API instead of the native SDKs.
- Construct the correct REST payloads and authentication headers.
- Simulate typical read/write operations (e.g., creating messages, voting on polls).
- Monitor Firestore read/write/delete quotas and performance in the Google Cloud Console.

### 3. Considerations & Best Practices
- **Cost:** Load testing Firebase *will* consume your project's resources (reads, writes, bandwidth, function invocations). **Do not load test on your production environment without careful planning.** It's highly recommended to use a separate, dedicated Firebase project for load testing to avoid affecting real users and accumulating unexpected charges on your main billing account.
- **Firebase Limits:** Be aware of Firebase's hard limits (e.g., 10,000 writes per second per database in Firestore). Load testing beyond these limits will naturally result in errors (429 Too Many Requests).
- **Authentication:** For realistic tests, you might need to pre-generate a list of test users and their authentication tokens to include in your test scripts.

## Example: Simple k6 script for an HTTP Cloud Function

```javascript
import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  vus: 10, // Virtual Users
  duration: '30s', // Test duration
};

export default function () {
  // Replace with your actual Cloud Function URL
  const url = 'https://us-central1-your-project-id.cloudfunctions.net/yourFunction';

  const payload = JSON.stringify({
    data: { testData: 'hello' }
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer YOUR_TEST_TOKEN' // If needed
    },
  };

  const res = http.post(url, payload, params);

  check(res, {
    'is status 200': (r) => r.status === 200,
  });

  sleep(1);
}
```
