# Remote Dev Environment Setup for Claude Code

> **Date:** 2026-03-19
> **Confidence:** High (core patterns) / Medium (tool-specific details — evolving rapidly)
> **Scope:** Running Claude Code in a remote session against a GitHub repo where secrets aren't checked in

---

## Executive Summary

You want Claude Code running remotely — a cloud VM, GitHub Codespace, CI runner, or headless session — working against a repo cloned from GitHub. The app needs real secrets (database URLs, API keys, service tokens) to run, but those secrets only live on your local machine in `.env` files that are (correctly) never committed.

**The core problem:** How do you get secrets from "nowhere" into a remote environment that starts with just a fresh `git clone`?

**The answer:** Use a **remote secret store** that the remote session authenticates to at runtime. Your secrets live in Doppler, 1Password, Infisical, GitHub Secrets, or a cloud provider's secret manager — not in files, not in git, not on your laptop. The remote session pulls them when it needs them.

This guide covers every pattern from simplest to most robust, with specific setup instructions for each.

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
Do you use GitHub Codespaces?
├── YES → Pattern 1: GitHub Codespaces Secrets (easiest)
└── NO
    ├── Is this a CI/CD pipeline (GitHub Actions, etc.)?
    │   └── YES → Pattern 2: GitHub Actions Secrets
    └── NO (cloud VM, remote dev server, etc.)
        ├── Do you already use a secret manager (Doppler, 1Password, etc.)?
        │   └── YES → Pattern 3: Cloud Secret Manager
        └── NO
            ├── Are you on AWS/GCP/Azure?
            │   └── YES → Pattern 5: Cloud-Native Secrets (IAM roles)
            └── NO
                ├── Want minimal setup?
                │   └── Pattern 4: dotenv-vault (encrypted .env in git)
                └── Want the "right" long-term solution?
                    └── Pattern 3: Set up Doppler or Infisical (free tier)
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

## 5. Pattern 3: Cloud Secret Managers (Recommended for Teams)

**Best for:** Teams, multi-environment setups, or anyone who wants the "right" long-term solution.

A cloud secret manager stores your secrets centrally. The remote session authenticates (via token, OIDC, or machine identity) and pulls secrets at runtime. No files, no copying, no encrypting.

### Option A: Doppler (Simplest Setup)

```bash
# One-time: Install Doppler CLI on the remote machine
curl -sLf https://cli.doppler.com/install.sh | sh

# One-time: Authenticate (interactive — do this once)
doppler login

# One-time: Link to your project
doppler setup  # select project + environment (dev/staging/prod)

# Every time: Run your app with secrets injected
doppler run -- npm run dev
doppler run -- npx prisma migrate dev
doppler run -- claude  # Claude Code session with secrets available
```

**For non-interactive remote sessions (CI, headless):**

```bash
# Create a Service Token in Doppler dashboard (read-only, scoped to dev environment)
# Set it as an env var on the remote machine
export DOPPLER_TOKEN=dp.st.dev_abc123...

# Now doppler run works without interactive login
doppler run -- npm run dev
```

**What your team commits to the repo:**

```bash
# doppler.yaml (committed — tells Doppler CLI which project to use)
setup:
  project: my-app
  config: dev
```

Source: [Doppler CLI](https://docs.doppler.com/docs/cli)

### Option B: 1Password

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

### Option C: Infisical (Open-Source)

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
| **Doppler** | 30 min | Low | Yes | No | Teams, multi-env |
| **1Password** | 30 min | Low | Yes | No | 1Password users |
| **Infisical** | 30 min | Low | Yes | Self-host option | Open-source preference |
| **dotenv-vault** | 15 min | Low | Limited | Yes | Simple, quick |
| **Cloud-native (IAM)** | 1 hr | None | Yes | No | Cloud VMs |
| **Reverse tunnel** | 15 min | High (laptop on) | No | No | Local service access |
| **Mock everything** | 15 min | None | N/A | Yes | Tests only |

---

## 12. Recommended Setup: Step by Step

For most developers, here's what I'd recommend:

### Step 1: Pick Your Secret Store

- **Solo dev, simple project** → dotenv-vault or GitHub Codespaces Secrets
- **Team or multi-environment** → Doppler (free tier covers most needs)
- **Already on AWS/GCP/Azure** → Cloud-native secret manager
- **CI/CD only** → GitHub Actions Secrets

### Step 2: Create Your Secret Manifest

Whatever pattern you chose, commit a file that documents what secrets are needed:

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
- Run app: `doppler run -- npm run dev` (or `op run --env-file=.env.tpl -- npm run dev`)
- Run tests: `cp .env.test .env && npm test`
- Never read .env files directly
```

### Step 7: Done

The remote session clones the repo, installs the secret manager CLI, authenticates, and runs `doppler run -- npm run dev`. Secrets flow from the cloud, not from files.

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
