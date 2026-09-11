# Edutech Backend API

`edtech_api` is a robust, multi-tenant Educational Technology backend built with Ruby on Rails 8.

## Technology Stack & Architecture
- **Framework**: Ruby on Rails 8.1.3.1 (API mode)
- **Ruby Version**: 3.4.1
- **Database**: PostgreSQL with UUID primary keys (`gen_random_uuid()`)
- **Multi-Tenancy**: `acts_as_tenant` with strict tenant isolation and `Current.tenant` request scoping
- **Authentication**: JWT access tokens with rotation-capable `RefreshToken` digests
- **Authorization**: Fail-closed Pundit policies (`verify_authorized` enforced)
- **Serialization**: Blueprinter serializers
- **Financial Ledger**: Immutability-enforced append-only `Wallet` & `WalletTransaction` architecture

## Getting Started

### Prerequisites
- Ruby 3.4.1
- PostgreSQL 14+
- Bundler

### Setup Instructions
1. Install dependencies:
   ```bash
   bundle install
   ```

2. Setup Database & Run Seeds:
   ```bash
   bin/rails db:prepare
   bin/rails db:seed
   ```

3. Start Development Server:
   ```bash
   bin/rails server
   ```

## Running Verification & Tests

### Test Suite
Run the Minitest suite:
```bash
bin/rails test
```

### Static Analysis & Security Audits
Run RuboCop linting:
```bash
bundle exec rubocop
```

Run Brakeman security analyzer:
```bash
bundle exec brakeman
```

Run Zeitwerk eager loading verification:
```bash
bin/rails zeitwerk:check
```

## API Modules & Architecture Slices
- **Phase-1**: Multi-tenant database foundation, authentication, users, roles, permissions, system seeds.
- **Phase-2 Slice-1**: Tenant & Franchise Management domain.
- **Phase-2 Slice-2**: Wallet & Immutable Financial Ledger.
- **Phase-2 Slice-3**: Student Management domain.
