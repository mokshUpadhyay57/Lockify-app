# Firebase Performance Skill

---

## 1. Firestore Cost Basics (CRITICAL)

You pay for:
- Reads (MOST expensive)
- Writes
- Deletes
- Function invocations

Rule:
1 screen load = minimal reads


---

## 2. Query Optimization

Bad:
db.collection("orders").get()

Good:
db.collection("orders")
  .where("userId", "==", uid)
  .limit(1)

Rule:
- Always filter
- Always limit


---

## 3. Read Reduction Skill

Techniques:
- Cache results (memory/state)
- Avoid re-fetch on every rebuild
- Use single source of truth

Example:
- Don't call checkAccess multiple times


---

## 4. Payment Flow Optimization

Ideal:

createOrder:
→ 1 write

webhook:
→ 1 read + 1 write

checkAccess:
→ 1 read

Total per purchase:
≈ 2–3 reads, 2 writes

If more → waste


---

## 5. Function Optimization

Avoid:
- multiple triggers for same event
- unnecessary API calls

Use:
- early return
- idempotency


---

## 6. Listener Optimization

Avoid:
- continuous listeners for static data

Use:
- `.get()` for one-time data
- listeners only for live updates


---

## 7. Indexing Skill

Ensure:
- queries are indexed
- no full collection scan

Firestore will warn → FIX IT


---

## 8. Cost Estimation Skill

Example:

If:
- 1 user → 5 reads/session
- 1000 users/day

Reads/day = 5000

Multiply by Firebase pricing

---

## 9. Red Flags

❌ Fetching full collections  
❌ Re-fetching same data  
❌ Multiple access checks per screen  
❌ Uncontrolled listeners  
❌ No caching  

---

## 10. Optimization Goal

- Reduce reads
- Reduce duplicate calls
- Keep backend lean