# 🔒 Lockify — Core Brand & Accent Colors (Top 5)

A minimal, high-impact 5-color palette curated directly from the Lockify app for use in the website and web unlock portal.

---

## 🎨 The 5 Core Colors

| # | Role | Color Name | Hex Code | RGB | Web Portal Usage |
| :- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Primary Brand** | Lockify Purple | **`#9C27B0`** | `rgb(156, 39, 176)` | Logo, primary action buttons (*"Claim Content"*, *"Create Link"*), active navigation |
| **2** | **Brand Shade** | Deep Purple | **`#7B1FA2`** | `rgb(123, 31, 162)` | Button hover states, headings, high-contrast titles |
| **3** | **Brand Tint** | Soft Lavender | **`#F3E5F5`** | `rgb(243, 229, 245)` | Badge pills (*"Locked Link"*), subtle card highlights, hero section glow |
| **4** | **Action Accent** | Unlock Green | **`#43A047`** | `rgb(67, 160, 71)` | *"Pay & Unlock"* button, price tags, payment success |
| **5** | **Alert Accent** | Security Red | **`#F44336`** | `rgb(244, 67, 54)` | Padlock icons, *"Content Locked"* notices, expiry timer |

---

## 🌓 Supporting Neutrals (Surfaces & Text)

- **Card / Surface White**: `#FFFFFF`
- **Page Background**: `#F8F9FA` or `#F5F5F5`
- **Main Heading / Body Text**: `#212121` (Dark Charcoal)
- **Subtle Border**: `#E0E0E0`

---

## 💻 Quick Web Integration

### CSS Variables (`variables.css`)
```css
:root {
  --color-brand: #9C27B0;
  --color-brand-hover: #7B1FA2;
  --color-brand-light: #F3E5F5;
  --color-unlock: #43A047;
  --color-locked: #F44336;

  /* Surfaces & Text */
  --color-surface: #FFFFFF;
  --color-bg: #F5F5F5;
  --color-text: #212121;
  --color-border: #E0E0E0;
}
```

### Tailwind CSS Config (`tailwind.config.js`)
```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        lockify: {
          brand: '#9C27B0',
          dark: '#7B1FA2',
          light: '#F3E5F5',
          unlock: '#43A047',
          locked: '#F44336',
        },
      },
    },
  },
}
```
