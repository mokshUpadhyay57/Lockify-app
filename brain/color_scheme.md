# 🎨 Lockify App - Color Scheme & Design Tokens Specification

This document provides a comprehensive breakdown of the **Lockify** color palette extracted directly from the Flutter application codebase (`lib/utils/colors.dart`). 

It is formatted for easy integration into web projects (React, Next.js, HTML/CSS, Tailwind CSS, etc.) for the **Lockify Web Portal** and promotional websites.

---

## 🎯 Quick Reference — Core Brand Colors (Top 5)

A minimal, high-impact 5-color palette for rapid integration and brand consistency:

| # | Role | Color Name | Hex Code | RGB | Usage |
| :- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Primary Brand** | Lockify Purple | **`#9C27B0`** | `rgb(156, 39, 176)` | Logo, primary action buttons (*"Claim Content"*, *"Create Link"*), active navigation |
| **2** | **Brand Shade** | Deep Purple | **`#7B1FA2`** | `rgb(123, 31, 162)` | Button hover states, headings, high-contrast titles |
| **3** | **Brand Tint** | Soft Lavender | **`#F3E5F5`** | `rgb(243, 229, 245)` | Badge pills (*"Locked Link"*), subtle card highlights, hero section glow |
| **4** | **Action Accent** | Unlock Green | **`#43A047`** | `rgb(67, 160, 71)` | *"Pay & Unlock"* button, price tags, payment success |
| **5** | **Alert Accent** | Security Red | **`#F44336`** | `rgb(244, 67, 54)` | Padlock icons, *"Content Locked"* notices, expiry timer |

**Supporting Neutrals:**
- **Card / Surface White**: `#FFFFFF`
- **Page Background**: `#F5F5F5`
- **Main Text**: `#212121` (Dark Charcoal)
- **Subtle Border**: `#E0E0E0`

---

## 🎯 1. Primary Brand Colors (Purple Spectrum)

The signature Lockify purple represents security, premium monetization, and brand identity.

| Name | Hex Code | RGB | Flutter Constant | Usage / Intent |
| :--- | :--- | :--- | :--- | :--- |
| **Primary Purple (500)** | `#9C27B0` | `rgb(156, 39, 176)` | `AppColors.primaryPurple` | Main brand color, primary CTA buttons, active tabs |
| **Primary Purple Light (50)** | `#F3E5F5` | `rgb(243, 229, 245)` | `AppColors.purple50` | Light purple backgrounds, badge containers, active tint |
| **Purple 100** | `#E1BEE7` | `rgb(225, 190, 231)` | `AppColors.purple100` | Soft subtle borders, light hover states |
| **Purple 200** | `#CE93D8` | `rgb(206, 147, 216)` | `AppColors.purple200` | Secondary highlights, disabled purple buttons |
| **Purple 300** | `#BA68C8` | `rgb(186, 104, 200)` | `AppColors.purple300` | Secondary interactive accents |
| **Purple 400** | `#AB47BC` | `rgb(171, 71, 188)` | `AppColors.purple400` | Medium purple hover / active state |
| **Purple 600** | `#8E24AA` | `rgb(142, 36, 170)` | `AppColors.purple600` | Pressed button state, focused inputs |
| **Purple 700** | `#7B1FA2` | `rgb(123, 31, 162)` | `AppColors.purple700` | Header text, key action cards, dark accents |
| **Purple 800** | `#6A1B9A` | `rgb(106, 27, 154)` | `AppColors.purple800` | Deep contrast text, dark purple elements |
| **Purple 900** | `#4A148C` | `rgb(74, 20, 140)` | `AppColors.purple900` | Ultra-dark branding backgrounds |
| **Deep Purple (Seed)** | `#673AB7` | `rgb(103, 58, 183)` | `Colors.deepPurple` | Theme Seed Color |

---

## 💵 2. Monetization & Status Colors

Used for financial transactions, claim buttons, success feedback, and system status indicators.

| Category | Name | Hex Code | RGB | Flutter Constant | Web Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Monetization** | Money Green | `#43A047` | `rgb(67, 160, 71)` | `AppColors.moneyGreen` | Unlocking prices, earnings, paid status |
| **Success** | Online Green (500) | `#4CAF50` | `rgb(76, 175, 80)` | `AppColors.onlineGreen` | Success alerts, online badges |
| **Success Tint** | Green 50 | `#E8F5E9` | `rgb(232, 245, 233)` | `AppColors.green50` | Success notification background |
| **Error / Alert** | Error Red (500) | `#F44336` | `rgb(244, 67, 54)` | `AppColors.errorRed` | Error messages, locked alert icons |
| **Error Accent** | Red Accent | `#FF5252` | `rgb(255, 82, 82)` | `AppColors.errorRedAccent` | Destructive action highlights |
| **Error Tint** | Red 50 | `#FFEBEE` | `rgb(255, 235, 238)` | `AppColors.red50` | Danger banner background |
| **Warning** | Warning Orange | `#FF9800` | `rgb(255, 152, 0)` | `AppColors.warningOrange` | Channel badges, pending status |

---

## 🌫 3. Neutral & Surface Colors

| Name | Hex Code / RGBA | Flutter Constant | Web Usage |
| :--- | :--- | :--- | :--- |
| **Background Grey** | `#F5F5F5` | `AppColors.backgroundGrey` | Page body background |
| **White** | `#FFFFFF` | `AppColors.white` | Card backgrounds, modal popups, button text |
| **White 70%** | `rgba(255, 255, 255, 0.7)` | `AppColors.white70` | Text on dark purple buttons |
| **White 24%** | `rgba(255, 255, 255, 0.24)` | `AppColors.white24` | Dividers on dark backgrounds |
| **Black** | `#000000` | `AppColors.black` | Primary high-contrast elements |
| **Black 87%** | `rgba(0, 0, 0, 0.87)` | `AppColors.black87` | Primary body text color |
| **Black 54%** | `rgba(0, 0, 0, 0.54)` | `AppColors.black54` | Secondary text, placeholders |
| **Black 45%** | `rgba(0, 0, 0, 0.45)` | `AppColors.black45` | Subtitles, icon tints |
| **Black 38%** | `rgba(0, 0, 0, 0.38)` | `AppColors.black38` | Disabled text |
| **Black 12%** | `rgba(0, 0, 0, 0.12)` | `AppColors.black12` | Subtle borders, card elevation shadows |
| **Grey 50** | `#FAFAFA` | `AppColors.grey50` | Light container fill |
| **Grey 100** | `#F5F5F5` | `AppColors.grey100` | Input field background |
| **Grey 200** | `#EEEEEE` | `AppColors.grey200` | Divider lines, light borders |
| **Grey 300** | `#E0E0E0` | `AppColors.grey300` | Border outlines, signature boxes |
| **Grey 400** | `#BDBDBD` | `AppColors.grey400` | Inactive icon color |
| **Grey 500** | `#9E9E9E` | `AppColors.grey500` | Secondary text fallback |
| **Grey 600** | `#757575` | `AppColors.grey600` | Caption text |
| **Grey 700** | `#616161` | `AppColors.grey700` | Dark gray icons |
| **Grey 800** | `#424242` | `AppColors.grey800` | Dark mode card background |
| **Grey 900** | `#212121` | `AppColors.grey900` | Dark mode surface background |

---

## 🎨 4. Avatar & Entity Identity Colors

| Entity Type | Color Name | Hex Code | Purpose |
| :--- | :--- | :--- | :--- |
| **Direct Chats** | Primary Purple | `#9C27B0` | User DMs avatar background & message bubbles |
| **Groups** | Blue | `#2196F3` | Group avatar background & group indicators |
| **Channels** | Warning Orange | `#FF9800` | Broadcast channels avatar background |
| **Section Icons** | Teal | `#009688` | Settings / Information section headers |

---

## 🌐 5. Web Developer Integration Code Snippets

### A. CSS Custom Properties (`variables.css`)

```css
:root {
  /* Brand Purple Spectrum */
  --lockify-purple-primary: #9C27B0;
  --lockify-purple-light: #F3E5F5;
  --lockify-purple-50: #F3E5F5;
  --lockify-purple-100: #E1BEE7;
  --lockify-purple-200: #CE93D8;
  --lockify-purple-300: #BA68C8;
  --lockify-purple-400: #AB47BC;
  --lockify-purple-500: #9C27B0;
  --lockify-purple-600: #8E24AA;
  --lockify-purple-700: #7B1FA2;
  --lockify-purple-800: #6A1B9A;
  --lockify-purple-900: #4A148C;

  /* Functional & Status */
  --lockify-money-green: #43A047;
  --lockify-green-online: #4CAF50;
  --lockify-green-50: #E8F5E9;
  --lockify-red-error: #F44336;
  --lockify-red-50: #FFEBEE;
  --lockify-orange-warning: #FF9800;
  --lockify-group-blue: #2196F3;
  --lockify-teal: #009688;

  /* Neutrals & Surfaces */
  --lockify-bg-grey: #F5F5F5;
  --lockify-white: #FFFFFF;
  --lockify-grey-100: #F5F5F5;
  --lockify-grey-200: #EEEEEE;
  --lockify-grey-300: #E0E0E0;
  --lockify-grey-600: #757575;
  --lockify-grey-900: #212121;
  --lockify-text-primary: rgba(0, 0, 0, 0.87);
  --lockify-text-secondary: rgba(0, 0, 0, 0.54);
}
```

### B. Tailwind CSS Configuration (`tailwind.config.js`)

```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        lockify: {
          purple: {
            50: '#F3E5F5',
            100: '#E1BEE7',
            200: '#CE93D8',
            300: '#BA68C8',
            400: '#AB47BC',
            DEFAULT: '#9C27B0',
            500: '#9C27B0',
            600: '#8E24AA',
            700: '#7B1FA2',
            800: '#6A1B9A',
            900: '#4A148C',
          },
          money: '#43A047',
          success: '#4CAF50',
          error: '#F44336',
          warning: '#FF9800',
          group: '#2196F3',
          bg: '#F5F5F5',
        },
      },
    },
  },
}
```
