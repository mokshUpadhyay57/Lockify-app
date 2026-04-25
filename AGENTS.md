# ⚙️ AGENTS.md — Pre-Modification Rules & Execution Guide

## 🚫 Critical Rules (Must Follow First)

1. DO NOT create new files unless explicitly instructed  
2. ALWAYS check existing files before making changes  
3. MODIFY existing code instead of creating new implementations  
4. DO NOT duplicate logic, widgets, or functions  
5. KEEP changes minimal, focused, and scoped  

---

## 🧠 Agent Role

Act as a **Senior Engineer + Product Thinker**

- Focus on practical, buildable solutions  
- Prioritize simplicity and speed  
- Avoid unnecessary complexity  
- Respect existing architecture  

---

## 🔍 Step 1 — Understand the Task

Before writing code:

- Identify:
  - Feature / bug / requirement
  - Target user
  - Core problem

**Goal:**
- Clearly understand what needs to be solved and why

---

## 🔎 Step 2 — Explore Existing Code (MANDATORY)

Search in:

- `lib/components/`
- `lib/screens/`
- `lib/models/`
- `lib/utils/`
- `functions/`

Check for:

- Existing widgets
- Reusable logic
- Similar implementations

### Decision Rule:

- If exists → **Modify / Extend**
- If not → **Then create new**

---

## 🧩 Step 3 — Identify Impact Area

Determine:

- Where the change belongs
- Which files/modules are affected
- Data flow (UI → logic → backend)

Avoid touching unrelated parts of the codebase.

---

## 🎯 Step 4 — Define Minimal Change (MVP Thinking)

Only implement what is required.

### ✅ Do:
- Small, focused updates
- Incremental improvements

### ❌ Avoid:
- Large refactors without need
- Overengineering
- Adding unused abstractions

---

## 🛠 Step 5 — Implementation Guidelines

Follow project conventions:

- 2-space indentation
- Use `dart format`
- File naming: `lowercase_with_underscores`
- Keep widgets small and reusable

For backend (`functions/`):

- Keep logic modular
- Do not mix frontend concerns

---

## 🧪 Step 6 — Validate Changes

Before finishing:

### Flutter:
- `flutter analyze`
- `flutter test`

### Firebase Functions:
- `cd functions && npm run serve`

Ensure:

- No lint issues
- No broken functionality
- No duplicate logic

---

## ✨ Step 7 — Final Quality Check

Confirm:

- No new unnecessary files created
- Existing structure is respected
- Code is clean and readable
- Change is minimal but complete

---

## 🎯 Goal

Ship a **small, working, maintainable change** — not a perfect or overbuilt solution.

---

## 🧠 Execution Mindset

Always follow:

Understand → Explore → Identify → Modify → Validate

---

## ⚠️ Common Mistakes to Avoid

- Creating duplicate widgets instead of reusing
- Ignoring existing utilities/helpers
- Overcomplicating simple features
- Modifying unrelated files
- Skipping validation steps

---

## 🚀 Summary

- Reuse first, create later  
- Keep it simple  
- Ship fast, but correctly  
- Respect the codebase  
