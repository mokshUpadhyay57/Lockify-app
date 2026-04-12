# Lockify Frontend 🔐

A lightweight React + Vite frontend for Lockify — share locked messages, accept payments, and monetize content.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?cacheSeconds=2592000)](https://github.com/mokshupadhyay57/LockifyFrontend) [![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## About

Lockify helps creators share premium content as locked messages and earn from access payments. This repo contains the frontend UI built with Vite and React, integrated with Firebase for auth and data.

## Key Features

- **Locked Messages:** Share content behind a payment gate
- **Payments:** UPI and QR payment options
- **User Management:** Firebase-backed authentication and user flows
- **Modular UI:** Components for payments, locked messages, and user management

## Tech Stack

- React
- Vite
- Firebase
- CSS (modular component styles)

## Quick Start

Prerequisites: Node.js (v18+), pnpm or npm

1. Clone and install:

```bash
git clone https://github.com/mokshupadhyay57/LockifyFrontend.git
cd lockify-frontend
pnpm install    # or `npm install`
```

2. Run the dev server:

```bash
pnpm dev        # or `npm run dev`
```

Environment variables:

```bash
cp .env.example .env
```

- `VITE_CREATE_ORDER_URL`: create order function endpoint
- `VITE_VERIFY_PAYMENT_URL`: verify payment function endpoint
- `VITE_CASHFREE_MODE`: `sandbox` or `production`

3. Build for production:

```bash
pnpm build      # or `npm run build`
```

## Author

Moksh Upadhyay — https://github.com/mokshupadhyay57

## License

This project is licensed under the MIT License. See LICENSE for details.
