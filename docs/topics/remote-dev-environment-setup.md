# Remote Dev Environment Setup for Claude Code

> **Date:** 2026-03-19
> **Confidence:** High (core patterns) / Medium (tool-specific details — evolving rapidly)
> **Scope:** Running Claude Code in a remote session against a GitHub repo where secrets aren't checked in

---

## Executive Summary

You want Claude Code running remotely — a cloud VM, GitHub Codespace, CI runner, or headless session — working against a repo cloned from GitHub. The app needs real secrets (database URLs, API keys, service tokens) to run, but those secrets only live on your local machine in `.env` files that are (correctly) never committed.

**The core problem:** How do you get secrets from "nowhere" into a remote environment that starts with just a fresh `git clone`?

**The answer:** Use **Doppler** (or another remote secret store) that the remote session authenticates to at runtime. Your secrets live in Doppler's cloud — not in files, not in git, not on your laptop. The remote session authenticates and pulls them when it needs them.

**Recommended approach:** Doppler (free tier covers most solo/small team needs). This guide leads with Doppler as the primary path and covers alternatives for specific situations.

---

## 1. The Problem: Fresh Clone, No Secrets

```
Your laptop                          Remote session
┌──────────────┐                     ┌──────────────────────┐
│ .env          │                     │ git clone repo       │
│ .env.local    │  ← never committed  │ .env ???             │
│ secrets/      │                     │ npm run dev → FAILS  │
│               │                     │ "Missing DATABASE_URL"│
└──────────────┘                     └──────────────────────┘
```

The remote session has your code but not your secrets. You need a bridge — and that bridge should **never** be "copy the .env file over" or "commit it encrypted." There are better options.

---

## 2. Decision Tree: Which Pattern to Use

```
Start here:
│
├── Default recommendation → Pattern 3A: Doppler (works everywhere, free tier)
│
├── Already in GitHub Codespaces? → Pattern 1: Codespaces Secrets (built-in, no CLI)
├── CI/CD only (headless)? → Pattern 2: GitHub Actions Secrets
├── On AWS/GCP/Azure infra? → Pattern 5: Cloud-Native Secrets (IAM, no tokens)
├── Need to access local DB from remote? → Pattern 6: Reverse Tunnel (Tailscale)
├── Testing only, no real APIs? → Pattern 7: Mock Everything
└── Want encrypted .env in git (no cloud dependency)? → Pattern 4: dotenv-vault
```

---

## 3. Pattern 1: GitHub Codespaces Secrets (Easiest)

**Best for:** Solo devs or small teams already using Codespaces.

GitHub Codespaces has built-in encrypted secret storage. You add secrets through the GitHub UI, and they're automatically available as environment variables in every Codespace.

### Setup

1. Go to **GitHub → Settings → Codespaces → Secrets** (for account-level) or **Repo → Settings → Secrets and variables → Codespaces** (repo-level)
2. Click "New secret"
3. Add each secret from your local `.env`:

```
Name: DATABASE_URL
Value: postgresql://user:pass@host:5432/mydb

Name: STRIPE_SECRET_KEY
Value: sk_live_abc123...

Name: OPENAI_API_KEY
Value: sk-abc123...
```

4. Select which repos can access each secret

### How Claude Code Uses Them

When you open a Codespace and run Claude Code, the secrets are already in the shell environment:

```bash
# In the Codespace terminal
claude  # Claude Code can now run your app — secrets are env vars

# Your app reads DATABASE_URL, STRIPE_SECRET_KEY, etc. from process.env
npm run dev  # Just works
```

### What to Commit to the Repo

```bash
# .env.example (committed — tells devs what secrets are needed)
DATABASE_URL=
STRIPE_SECRET_KEY=
OPENAI_API_KEY=
NEXTAUTH_SECRET=
```

```jsonc
// .devcontainer/devcontainer.json (optional — recommended secrets)
{
  "secrets": {
    "DATABASE_URL": {
      "description": "PostgreSQL connection string"
    },
    "STRIPE_SECRET_KEY": {
      "description": "Stripe API secret key (use test key for dev)"
    }
  }
}
```

**Limits:** 100 secrets per account, 48 KB per secret.

Source: [GitHub Codespaces Secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces)

---

## 4. Pattern 2: GitHub Actions Secrets (CI/CD)

**Best for:** Headless Claude Code runs in CI/CD pipelines.

Claude Code supports headless mode (`-p` / `--print` flag) for CI. GitHub Actions secrets inject as env vars.

### Setup

1. **Repo → Settings → Secrets and variables → Actions**
2. Add your secrets (same as above)
3. Add `ANTHROPIC_API_KEY` for Claude Code authentication

### Workflow Example

```yaml
# .github/workflows/claude-review.yml
name: Claude Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Run Claude Code
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          STRIPE_SECRET_KEY: ${{ secrets.STRIPE_SECRET_KEY }}
        run: |
          claude -p "Review the changes in this PR for security issues and bugs"
```

### For Running the Full App in CI

```yaml
      - name: Start services
        run: docker compose up -d db redis

      - name: Run app with secrets
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          STRIPE_SECRET_KEY: ${{ secrets.STRIPE_SECRET_KEY }}
        run: |
          npm install
          npx prisma migrate deploy
          npm run dev &
          sleep 5
          claude -p "Run the test suite and report failures"
```

### Environment-Level Secrets (Staging vs Production)

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: staging  # Uses staging-specific secrets
    steps:
      - env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}  # staging DB, not prod
```

Source: [GitHub Actions Secrets](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions)

---

## 5. Pattern 3: Doppler (Recommended — Primary Path)

**Best for:** Everything. Solo devs, teams, CI/CD, cloud VMs, Codespaces. Free tier covers most needs.

Doppler stores your secrets in the cloud. The remote session authenticates and pulls them at runtime. No files to copy, no encryption to manage, no `.env` to sync. You add secrets in Doppler's dashboard, and `doppler run --` injects them into any process.

### Initial Setup (One-Time, ~15 Minutes)

**Step 1: Create a Doppler account and project**
1. Go to [doppler.com](https://www.doppler.com/) → Sign up (free)
2. Create a project (e.g., `my-app`)
3. Doppler auto-creates 3 environments: `dev`, `staging`, `prod`

**Step 2: Add your secrets to Doppler**
1. Open your project → `dev` environment
2. Click "Add Secret" for each value from your local `.env`:
   - `DATABASE_URL` = `postgresql://user:pass@host:5432/mydb`
   - `STRIPE_SECRET_KEY` = `sk_test_abc123...`
   - `OPENAI_API_KEY` = `sk-abc123...`
   - `REDIS_URL` = `redis://localhost:6379`
   - (everything from your `.env` file)

**Step 3: Install Doppler CLI on the remote machine**
```bash
# Linux / Codespaces / CI
curl -sLf https://cli.doppler.com/install.sh | sh

# macOS
brew install dopplerhq/cli/doppler
```

**Step 4: Authenticate**
```bash
# Interactive (for dev sessions — do once per machine)
doppler login

# Link to your project
doppler setup  # select project: my-app, config: dev
```

### Daily Usage

```bash
# Run your app — Doppler injects all secrets as env vars
doppler run -- npm run dev

# Run migrations
doppler run -- npx prisma migrate dev

# Run Claude Code with secrets available to the app
doppler run -- claude

# Run tests
doppler run -- npm test
```

That's it. `doppler run --` is the only command you need to remember. It wraps any command and injects your secrets into its environment.

### For Headless/CI Sessions (No Interactive Login)

```bash
# In Doppler dashboard: project → Access → Service Tokens → Generate
# Scope: read-only, dev environment only
# Set it as env var on the remote machine (or in GitHub Actions secrets):
export DOPPLER_TOKEN=dp.st.dev_abc123...

# Now doppler run works without interactive login
doppler run -- npm run dev
doppler run -- claude -p "Run the test suite"
```

### What to Commit to the Repo

```yaml
# doppler.yaml (committed — tells Doppler CLI which project/config to use)
setup:
  project: my-app
  config: dev
```

```bash
# .env.example (committed — documents what secrets exist, no values)
DATABASE_URL=
STRIPE_SECRET_KEY=
OPENAI_API_KEY=
REDIS_URL=
NEXTAUTH_SECRET=
```

### Multi-Environment (Dev / Staging / Prod)

Doppler handles this natively — each environment has its own secret set:

```bash
# Dev (default from doppler.yaml)
doppler run -- npm run dev

# Staging (override config)
doppler run --config stg -- npm run dev

# Production (you probably shouldn't do this from Claude Code)
doppler run --config prd -- npm run start
```

### Doppler + GitHub Actions

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Doppler CLI
        run: curl -sLf https://cli.doppler.com/install.sh | sh
      - name: Run tests with secrets
        env:
          DOPPLER_TOKEN: ${{ secrets.DOPPLER_TOKEN }}
        run: doppler run -- npm test
```

Store only `DOPPLER_TOKEN` as a GitHub Actions secret — Doppler serves everything else.

### Doppler + Docker Compose

```bash
# Option A: Wrap docker compose (secrets in app container's env)
doppler run -- docker compose up

# Option B: Generate .env for Docker (auto-deleted after use)
doppler secrets download --no-file --format docker > .env
docker compose up
rm .env
```

### Why Doppler Over Alternatives

| Feature | Doppler | .env files | dotenv-vault | GitHub Secrets |
|---------|---------|-----------|-------------|---------------|
| Works everywhere (CI, VMs, Codespaces, local) | ✅ | ❌ (local only) | ⚠️ (needs DOTENV_KEY) | ⚠️ (GitHub only) |
| Multi-environment | ✅ (built-in) | Manual | Manual | Via environments |
| Team sharing | ✅ (RBAC) | ❌ | ❌ | Org secrets |
| Audit log | ✅ | ❌ | ❌ | ❌ |
| Secret rotation | ✅ (instant) | Manual | Re-encrypt | Manual |
| Free tier | ✅ (5 users, unlimited secrets) | N/A | Paid | Free |

Source: [Doppler CLI](https://docs.doppler.com/docs/cli), [Doppler Setup Guide](https://securityboulevard.com/2025/09/how-to-set-up-doppler-for-secrets-management-step-by-step-guide/)

### Alternative A: 1Password (If You Already Use It)

```bash
# Install 1Password CLI
brew install 1password-cli  # or apt, etc.

# Create .env.tpl (committed — vault references, not values)
# This is your "secret manifest"
DATABASE_URL=op://Development/postgres/connection-string
STRIPE_SECRET_KEY=op://Development/stripe/secret-key
OPENAI_API_KEY=op://Development/openai/api-key
REDIS_URL=op://Development/redis/url

# Run with secrets injected
op run --env-file=.env.tpl -- npm run dev
op run --env-file=.env.tpl -- claude
```

**For headless/CI:**

```bash
# Create a Service Account in 1Password → Developer → Service Accounts
# Set the token as env var
export OP_SERVICE_ACCOUNT_TOKEN=ops_abc123...

# op run now works non-interactively
op run --env-file=.env.tpl -- npm run dev
```

Source: [1Password Service Accounts](https://developer.1password.com/docs/service-accounts/get-started/)

### Alternative B: Infisical (Open-Source, Self-Hostable)

```bash
# Install
curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
sudo apt install infisical

# Authenticate (interactive once, or use machine identity for CI)
infisical login

# Run with secrets
infisical run -- npm run dev
infisical run -- claude
```

**For CI (Universal Auth — no interactive login needed):**

```bash
# Set machine identity credentials
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=...
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=...

infisical run --projectId=abc123 --env=dev -- npm run dev
```

Source: [Infisical for Cursor Cloud Agents](https://infisical.com/blog/secure-secrets-management-for-cursor-cloud-agents) (applies equally to Claude Code)

---

## 6. Pattern 4: dotenv-vault (Encrypted .env in Git)

**Best for:** Quick setup, small projects, or when you don't want to set up a cloud secret manager.

The idea: encrypt your `.env` file, commit the encrypted version (`.env.vault`) to the repo, and set a single decryption key (`DOTENV_KEY`) on the remote machine.

### Setup

```bash
# Install dotenvx
npm install -g @dotenvx/dotenvx

# Encrypt your .env file
dotenvx encrypt

# This creates:
# .env.vault   ← committed to git (encrypted, safe)
# .env.keys    ← NEVER committed (contains decryption keys)
```

### On the Remote Machine

```bash
# Set the decryption key (from .env.keys, under DOTENV_KEY_DEVELOPMENT)
export DOTENV_KEY="dotenv://:key_abc123@dotenvx.com/vault/.env.vault?environment=development"

# Run your app — dotenvx auto-decrypts .env.vault
dotenvx run -- npm run dev
dotenvx run -- claude
```

### What Gets Committed

```
✅ .env.vault      (encrypted secrets — safe in git)
✅ .env.example     (secret names, no values)
❌ .env             (real secrets — in .gitignore)
❌ .env.keys        (decryption keys — in .gitignore)
```

**Trade-off:** Simpler than a cloud manager, but you still need to distribute the `DOTENV_KEY` somehow (GitHub Secrets, Codespaces Secrets, or manually).

Source: [dotenvx](https://dotenvx.com/)

---

## 7. Pattern 5: Cloud-Native Secrets (AWS/GCP/Azure)

**Best for:** Remote sessions running on cloud infrastructure where you can use IAM roles instead of credentials.

The most secure pattern — no credentials at all. The remote machine proves its identity through the cloud provider, and gets access to secrets.

### AWS Secrets Manager + IAM Role

```bash
# On an EC2 instance with the right IAM role attached:
# No credentials needed — the instance role provides access

# Fetch secrets at app startup (in your entrypoint script)
aws secretsmanager get-secret-value \
  --secret-id myapp/dev \
  --query SecretString \
  --output text | jq -r 'to_entries[] | "\(.key)=\(.value)"' > /tmp/.env

# Source and clean up
set -a; source /tmp/.env; set +a
rm /tmp/.env

# Now run your app
npm run dev
claude
```

### GCP Secret Manager + Workload Identity

```bash
# On a GCE VM or GKE pod with Workload Identity:
gcloud secrets versions access latest --secret="myapp-dev" | \
  jq -r 'to_entries[] | "\(.key)=\(.value)"' > /tmp/.env

set -a; source /tmp/.env; set +a
rm /tmp/.env

npm run dev
```

### Azure Key Vault + Managed Identity

```bash
# On an Azure VM with Managed Identity:
az keyvault secret show --vault-name myapp-vault --name dev-secrets \
  --query value -o tsv | jq -r 'to_entries[] | "\(.key)=\(.value)"' > /tmp/.env

set -a; source /tmp/.env; set +a
rm /tmp/.env

npm run dev
```

**Key advantage:** No tokens, no credentials to rotate. The cloud provider handles identity.

**Key limitation:** Only works on that cloud provider's infrastructure.

Sources: [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/), [GCP Secret Manager](https://cloud.google.com/secret-manager/docs), [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)

---

## 8. Pattern 6: Reverse Tunnel to Local Services

**Best for:** When you want the remote Claude Code session to use your local database/services directly.

Instead of moving secrets to the cloud, bring the remote session back to your local machine:

```
Remote session ──── reverse tunnel ────→ Your laptop
  Claude Code                              localhost:5432 (Postgres)
  git clone repo                           localhost:3000 (API)
  npm run dev (connects                    localhost:6379 (Redis)
   to "localhost:5432"
   which tunnels to your
   laptop)
```

### With Tailscale (Recommended)

```bash
# On both machines: install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# Your laptop gets a Tailscale IP, e.g., 100.64.1.1
# Remote machine gets, e.g., 100.64.1.2

# On remote, your app config uses the Tailscale IP:
DATABASE_URL=postgresql://dev:devpass@100.64.1.1:5432/myapp
REDIS_URL=redis://100.64.1.1:6379

# No port forwarding, no firewall rules, encrypted by default
```

### With SSH Reverse Tunnel

```bash
# From your laptop (creates tunnel from remote:5432 → local:5432)
ssh -R 5432:localhost:5432 -R 6379:localhost:6379 user@remote-machine

# On the remote machine, localhost:5432 now reaches your local Postgres
DATABASE_URL=postgresql://dev:devpass@localhost:5432/myapp
```

### With ngrok

```bash
# On your laptop
ngrok tcp 5432  # exposes local Postgres

# ngrok gives you: tcp://0.tcp.ngrok.io:12345
# Use that as DATABASE_URL on the remote machine
DATABASE_URL=postgresql://dev:devpass@0.tcp.ngrok.io:12345/myapp
```

**Trade-offs:** Your laptop must stay on. Latency is higher. But you never move secrets — the remote session connects through to your local services where secrets are already configured.

Source: [Tailscale for remote dev](https://tsoporan.com/blog/remote-ai-development-claude-code-tailscale/)

---

## 9. Pattern 7: Mock Everything (Dev/Test Only)

**Best for:** When Claude Code only needs to run tests, not the full production-connected app.

```bash
# .env.test (committed — all fake values, safe in git)
DATABASE_URL=postgresql://test:test@localhost:5432/myapp_test
STRIPE_SECRET_KEY=sk_test_fake_for_testing
OPENAI_API_KEY=sk-fake-for-testing
REDIS_URL=redis://localhost:6379/1
```

```yaml
# docker-compose.test.yml (committed — spins up real services with test data)
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: myapp_test
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

```bash
# On the remote machine
docker compose -f docker-compose.test.yml up -d
cp .env.test .env
npm run migrate
npm run seed
npm test  # runs against test DB with fake API keys
claude    # can run tests, debug, refactor — no real secrets needed
```

**When this works:** Unit tests, integration tests against local DB, refactoring, code review, documentation.

**When this fails:** End-to-end tests that hit real APIs (Stripe webhooks, OAuth flows, email delivery), performance testing against production-like data.

---

## 10. Configuring Claude Code for Remote Sessions

### CLAUDE.md Instructions

Add this to your repo's `CLAUDE.md` so Claude Code knows how to run the app:

```markdown
## Running the App

### Local development
Use `doppler run -- npm run dev` (secrets injected from Doppler).

### Without real secrets (testing only)
Use `docker compose -f docker-compose.test.yml up -d` then `npm test`.

### Required environment variables
See `.env.example` for the full list. Never hardcode secrets.

### IMPORTANT
- Never read or echo .env files
- Never run `env`, `printenv`, or `echo $SECRET_NAME`
- Use the dev scripts in `scripts/` which handle secret injection
```

### Claude Code Security Config

```jsonc
// .claude/settings.json (committed to repo)
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./**/*.pem)",
      "Read(./**/*.key)"
    ]
  }
}
```

### Startup Scripts

```bash
#!/bin/bash
# scripts/dev-up.sh — starts services (no secrets needed)
docker compose up -d
echo "Services ready: postgres:5432, redis:6379"
```

```bash
#!/bin/bash
# scripts/dev-run.sh — starts app with secrets from Doppler
doppler run -- npm run dev
```

```bash
#!/bin/bash
# scripts/dev-test.sh — runs tests with fake secrets
docker compose -f docker-compose.test.yml up -d
cp .env.test .env
npm test
```

---

## 11. Comparison Matrix

| Pattern | Setup Effort | Ongoing Effort | Multi-Env | Works Offline | Best For |
|---------|-------------|---------------|-----------|--------------|----------|
| **Codespaces Secrets** | 5 min | None | No | No | Codespaces users |
| **GitHub Actions** | 10 min | None | Yes (environments) | No | CI/CD |
| **Doppler** ⭐ | 15 min | Low | Yes | No | **Default recommendation** |
| **1Password** | 30 min | Low | Yes | No | 1Password users |
| **Infisical** | 30 min | Low | Yes | Self-host option | Open-source preference |
| **dotenv-vault** | 15 min | Low | Limited | Yes | Simple, quick |
| **Cloud-native (IAM)** | 1 hr | None | Yes | No | Cloud VMs |
| **Reverse tunnel** | 15 min | High (laptop on) | No | No | Local service access |
| **Mock everything** | 15 min | None | N/A | Yes | Tests only |

---

## 12. Recommended Setup: Step by Step (Doppler)

The default path. ~15 minutes from zero to working remote sessions.

### Step 1: Set Up Doppler

1. Sign up at [doppler.com](https://www.doppler.com/) (free)
2. Create project → add all secrets from your local `.env`
3. Install CLI: `curl -sLf https://cli.doppler.com/install.sh | sh`
4. `doppler login` → `doppler setup` (select your project + dev config)

### Step 2: Create Your Secret Manifest

Commit a file that documents what secrets are needed:

```bash
# .env.example (always commit this)
# Copy to .env and fill in values for local dev
DATABASE_URL=postgresql://user:pass@localhost:5432/myapp
STRIPE_SECRET_KEY=sk_test_...
OPENAI_API_KEY=sk-...
NEXTAUTH_SECRET=generate-with-openssl-rand-base64-32
REDIS_URL=redis://localhost:6379
```

### Step 3: Create Test Secrets

```bash
# .env.test (commit this — all fake/test values)
DATABASE_URL=postgresql://test:test@localhost:5432/myapp_test
STRIPE_SECRET_KEY=sk_test_fake
OPENAI_API_KEY=sk-fake
NEXTAUTH_SECRET=test-secret-not-real
REDIS_URL=redis://localhost:6379/1
```

### Step 4: Wire Up Docker Compose for Services

```yaml
# docker-compose.yml (committed)
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: myapp_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpassword
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
volumes:
  pgdata:
```

### Step 5: Add Claude Code Config

```jsonc
// .claude/settings.json
{
  "permissions": {
    "deny": ["Read(./.env)", "Read(./.env.*)"]
  }
}
```

### Step 6: Document in CLAUDE.md

```markdown
## Dev Environment
- Start services: `docker compose up -d`
- Run app: `doppler run -- npm run dev`
- Run tests: `cp .env.test .env && npm test`
- Never read .env files directly
```

### Step 7: Run It

On the remote machine (fresh clone from GitHub):

```bash
git clone git@github.com:you/my-app.git && cd my-app
curl -sLf https://cli.doppler.com/install.sh | sh    # install Doppler
doppler login && doppler setup                         # authenticate (one-time)
docker compose up -d                                   # start DB, Redis
doppler run -- npm install                             # install deps
doppler run -- npx prisma migrate dev                  # run migrations
doppler run -- npm run dev                             # start app with secrets
doppler run -- claude                                  # Claude Code with full access
```

Secrets flow from Doppler's cloud, not from files. Nothing sensitive ever touches the repo.

---

## 13. Security Checklist

### Repo Hygiene

- [ ] `.env` and `.env.*` in `.gitignore` (except `.env.example` and `.env.test`)
- [ ] `.env.example` committed with secret names, no values
- [ ] `.env.test` committed with obviously fake values
- [ ] `.claude/settings.json` blocks reading `.env` files
- [ ] No secrets in `CLAUDE.md`, `README.md`, or any committed file
- [ ] `CLAUDE.md` documents how to run with secrets (via manager, not files)

### Remote Session

- [ ] Secret manager CLI installed and authenticated
- [ ] Service token or machine identity configured (for headless/CI)
- [ ] Secrets scoped to the right environment (dev, not prod)
- [ ] Claude Code never runs `env`, `printenv`, or `echo $SECRET`
- [ ] App starts via wrapper script (`doppler run --`, `op run --`, etc.)

### Ongoing

- [ ] Rotate service tokens periodically
- [ ] Audit secret access logs in your manager
- [ ] Review Claude Code session history for accidental secret exposure
- [ ] Never connect Claude Code to production databases

---

## Anti-Patterns

| Don't Do This | Why | Do This Instead |
|---|---|---|
| **scp .env to remote machine** | File sits on disk, readable by Claude | Use a secret manager |
| **Commit .env.vault without understanding it** | Still needs DOTENV_KEY distributed somehow | Use a proper secret manager for teams |
| **Paste secrets into Claude Code chat** | Becomes conversation context, sent to Anthropic API | Use runtime injection via wrapper |
| **Set secrets as env vars in CLAUDE.md** | Committed to git, visible to everyone | Document the wrapper command instead |
| **Use production secrets in dev** | Accidental production writes | Separate dev/staging/prod environments |
| **Store DOTENV_KEY in the same repo** | Defeats the purpose of encryption | Store in GitHub Secrets or secret manager |
| **Run `env` to debug missing secrets** | All env vars become conversation context | Use `echo $?` after app start to check exit code |

---

## Sources

- [GitHub Codespaces Secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces)
- [GitHub Codespaces Recommended Secrets](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/configuring-dev-containers/specifying-recommended-secrets-for-a-repository)
- [GitHub Actions Secrets](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions)
- [Doppler CLI Docs](https://docs.doppler.com/docs/cli)
- [Doppler Secrets Management Setup](https://securityboulevard.com/2025/09/how-to-set-up-doppler-for-secrets-management-step-by-step-guide/)
- [1Password Service Accounts](https://developer.1password.com/docs/service-accounts/get-started/)
- [1Password Secrets Automation](https://developer.1password.com/docs/secrets-automation/)
- [Infisical — Secrets Management for AI Agents](https://infisical.com/blog/secure-secrets-management-for-cursor-cloud-agents)
- [Infisical Secrets Best Practices 2026](https://infisical.com/blog/secrets-management-best-practices)
- [dotenvx — Encrypted .env](https://dotenvx.com/)
- [SOPS — Encrypted Secrets in Git](https://github.com/getsops/sops)
- [SOPS with Age Encryption Guide](https://oneuptime.com/blog/post/2026-02-09-sops-age-encryption-kubernetes-secrets-git/view)
- [AWS Secrets Manager IAM Policies](https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_iam-policies.html)
- [GCP Secret Manager Authentication](https://cloud.google.com/secret-manager/docs/authentication)
- [Azure Key Vault Managed Identity](https://learnomate.org/managed-identity-and-azure-key-vault/)
- [Tailscale for Remote AI Development](https://tsoporan.com/blog/remote-ai-development-claude-code-tailscale/)
- [SSH Reverse Tunneling Guide](https://qbee.io/misc/reverse-ssh-tunneling-the-ultimate-guide/)
- [Claude Code Headless Mode for CI/CD](https://institute.sfeir.com/en/claude-code/claude-code-headless-mode-and-ci-cd/)
- [Secure Environment Variables for LLMs](https://williamcallahan.com/blog/secure-environment-variables-1password-doppler-llms-mcps-ai-tools)
- [HashiCorp Vault Agent Auto-Auth](https://oneuptime.com/blog/post/2026-02-02-vault-agent/view)

---

## Related Topics

- [Claude Code Power User Guide](claude-code-power-user.md) — Session discipline, hooks, and configuration patterns
- [CI/CD AI Integration Safety](cicd-ai-integration-safety.md) — Safely adding AI steps to pipelines
- [Error Recovery & Fallback Patterns](error-recovery-patterns.md) — What to do when remote services fail
- [Hooks & Enforcement Patterns](hooks-enforcement-patterns.md) — PreToolUse hooks for blocking dangerous actions
- [Team AI Onboarding](team-ai-onboarding.md) — Shared configuration and security policies for teams
