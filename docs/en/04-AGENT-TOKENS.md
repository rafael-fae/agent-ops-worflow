# GitHub Token Configuration for Hermes Agents

> Complete and detailed guide on configuring GitHub Personal Access Tokens
> (PATs) for multi-agent Hermes Agent teams.
> Each agent on the team needs its **own token** so that commits are
> correctly attributed, the audit trail is clear, and permissions remain
> granular.

---

## Summary

1. [Why Each Agent Needs Its Own Token](#1-why-each-agent-needs-its-own-token)
2. [Team Nova Structure (Example)](#2-team-nova-structure-example)
3. [Token Types and Permissions](#3-token-types-and-permissions)
4. [Step by Step — Creating a Fine-Grained PAT for an Agent](#4-step-by-step--creating-a-fine-grained-pat-for-an-agent)
5. [Configuring the Token in Hermes](#5-configuring-the-token-in-hermes)
6. [Recommended Approach for Multi-Agent Teams](#6-recommended-approach-for-multi-agent-teams)
7. [Security Best Practices](#7-security-best-practices)
8. [Troubleshooting](#8-troubleshooting)
9. [Complete Configuration Example](#9-complete-configuration-example)
10. [Quick Command Reference](#10-quick-command-reference)

---

## 1. Why Each Agent Needs Its Own Token

In a multi-agent Hermes team, several AI agents may be working
simultaneously on the same repository. Each agent needs its **own
GitHub token** for the following reasons:

- **Correct commit attribution** — the git commit author will be the
  agent that performed the task, not a generic "bot" user. This
  preserves the audit trail in the repository history.

- **Clear audit trail** — with individual tokens, you can identify
  exactly which agent did what, both by the name on commits and by
  GitHub's API logs.

- **Granular permissions** — a Frontend agent does not need access to
  the infrastructure repository. Each token can (and should) be
  limited to the repositories that specific agent requires.

- **Selective rotation and revocation** — if an agent is deactivated
  or compromised, you only revoke that one agent's token without
  affecting the others.

- **Branch protection compatibility** — commits from different agents
  appear as distinct authors, respecting branch protection rules that
  require peer review or specific authors.

---

## 2. Team Nova Structure (Example)

**Team Nova** is a fictional multi-agent team with 6 roles. Each role
has its own Hermes agent, its own GitHub token, and its own set of
accessible repositories.

| Role | Agent Name | What It Commits | Typical Repositories |
|------|-----------|-----------------|---------------------|
| **Orchestrator** | `nova-orch` | Daily plans (`PLANO.md`), audit reports, indexes | `agent-ops-workflow` |
| **Backend Engineer** | `nova-backend` | Backend code (APIs, models, migrations) | `api`, `core-lib`, `worker` |
| **Frontend Engineer** | `nova-frontend` | Frontend/UI code (components, styles, pages) | `webapp`, `design-system` |
| **DevOps Engineer** | `nova-devops` | Infrastructure as code, deployment configs | `infra`, `k8s-configs`, `terraform` |
| **Auditor** | `nova-auditor` | Audit reports, validations, documentation | `agent-ops-workflow`, `docs` |
| **GitOps** | `nova-gitops` | CI/CD, vault, technical documentation, merge | `ci-cd`, `vault-config`, `docs` |

Each agent operates independently, with its own Hermes environment,
its own profile, and its own token. The Orchestrator coordinates task
delegation, but each agent executes its own commits.

---

## 3. Token Types and Permissions

### 3.1 Fine-Grained PAT vs Classic PAT

GitHub offers two types of Personal Access Token:

| Feature | Fine-Grained PAT | Classic PAT |
|---------|:----------------:|:-----------:|
| **Prefix** | `github_pat_` | `ghp_` |
| **Repository-level permissions** | Yes (granular) | No (all or nothing) |
| **Reduced scope** | Yes | Broad scopes (`repo`, `workflow`) |
| **Mandatory expiration** | Yes | Optional |
| **Organization approval** | Required in orgs | No |
| **Creation** | `github.com/settings/tokens?type=beta` | `github.com/settings/tokens` |

**Recommendation:** **Always use fine-grained PATs** for agents. They
allow you to restrict access to exactly the repositories the agent
needs, with the minimum required permissions.

### 3.2 Required Permissions

For a Hermes agent to clone repositories, make commits, open pull
requests, and check CI status, the following permissions are needed
on the fine-grained PAT:

| Permission | Level | Reason |
|------------|-------|--------|
| **Contents** | Read and Write | Clone, commit, push |
| **Metadata** | Read-only (mandatory) | GitHub requires this for any token |
| **Pull requests** | Read and Write | Open and comment on PRs |
| **Actions** | Read | Check workflow status |
| **Commit statuses** | Read | Check status checks |

For agents that need to modify GitHub Actions workflows (files in
`.github/workflows/`), also add:

| Permission | Level | Reason |
|------------|-------|--------|
| **Workflows** | Read and Write | Create/update workflow files |

### 3.3 Organization vs Personal Account

- **Personal account:** The token is tied to your GitHub user. The
  accessible repositories are those your account has access to.
  Suitable for personal projects or small teams.

- **Organization:** The token must be **approved by the organization**
  before it can access org repositories. The organization can set
  restriction policies for fine-grained tokens (e.g., require approval
  for each repository).

> **Note for orgs:** When creating a fine-grained PAT for access to
> organization repositories, an organization owner must approve the
> token. The token will only work after approval.

---

## 4. Step by Step — Creating a Fine-Grained PAT for an Agent

Follow these steps to create a token for a Team Nova agent.

### 4.1 Access the tokens page

1. Log in to GitHub
2. Go to **Settings** (gear icon in the top right corner)
3. In the left sidebar, click **Developer settings**
4. Click **Personal access tokens**
5. Click **Fine-grained tokens**
6. Click **Generate new token**

> **Direct link:** https://github.com/settings/tokens?type=beta

### 4.2 Fill in token details

| Field | Value | Example |
|-------|-------|---------|
| **Token name** | Descriptive agent name | `hermes-agent-nova-backend` |
| **Expiration** | Custom (90 days recommended) | 90 days |
| **Description** | (optional) Purpose description | Token for the Nova Backend agent |

### 4.3 Configure repository access

Under **Repository access**, choose:

- **Only select repositories** — select only the repositories this
  agent needs to access

  For `nova-backend`, for example: `api`, `core-lib`, `worker`.

- **All repositories** — only if the agent truly needs access to
  all repositories (not recommended for security).

### 4.4 Configure permissions

Under **Permissions**, select **Repository permissions** and set:

```
Contents:         Read and write
Metadata:         Read-only        (already checked)
Pull requests:    Read and write   (if the agent opens PRs)
Actions:          Read             (to check CI status)
Commit statuses:  Read             (to check status checks)
Workflows:        Read and write   (only if modifying .github/workflows/)
```

### 4.5 Generate and copy the token

1. Click **Generate token**
2. **Copy the token immediately!** GitHub shows the token only once
3. Store it securely (password manager or protected `.env` file)
4. If you lose the token, it cannot be recovered — you will need to
   generate a new one

> ⚠️ **Important:** The generated token starts with `github_pat_` and
> is about 80 alphanumeric characters long. Never share this token or
> commit it to repositories.

---

## 5. Configuring the Token in Hermes

There are several ways to configure the token for use with git and
Hermes. Below are the 4 most common options, from most recommended
to least.

### 5.1 Option A: Environment Variable (`GITHUB_TOKEN`)

**Recommended for Hermes agents.** Define an environment variable in
the agent's profile or shell profile.

```bash
# In ~/.hermes/profiles/nova-backend/config.yaml
# or in ~/.zshrc (for global use)

export GITHUB_TOKEN_NOVA_BACKEND="github_pat_xxxxxxxxxxxxxxxxxxxx"
```

Then, in the agent's git script, use the token:

```bash
# Set the remote with the token
git remote set-url origin \
  "https://oauth2:${GITHUB_TOKEN_NOVA_BACKEND}@github.com/team-nova/api.git"
```

> **Note about the `oauth2:` prefix:** For fine-grained PATs, the
> `oauth2:` prefix is **mandatory** in the URL. For classic PATs
> (`ghp_*`), use the token directly as the password.

### 5.2 Option B: `~/.netrc` File

The `.netrc` file allows git to authenticate automatically without
exposing the token in URLs.

```bash
# ~/.netrc
machine github.com
  login oauth2
  password github_pat_xxxxxxxxxxxxxxxxxxxx
```

Protect the file with restricted permissions:

```bash
chmod 600 ~/.netrc
```

To use with fine-grained PATs, the login **must be** `oauth2`. For
classic PATs, use your GitHub username.

### 5.3 Option C: Git Credential Helper

Configure git to use a credential helper that stores the token.

```bash
# Configure credential helper (once)
git config --global credential.helper osxkeychain  # macOS
# or
git config --global credential.helper cache        # Linux (memory cache)

# On the first git operation, provide the token as password
# Username: oauth2 (for fine-grained) or your user (for classic)
# Password: github_pat_xxxxxxxxxxxxxxxxxxxx
```

### 5.4 Option D: SSH Deploy Key (alternative)

For environments where PATs are not viable, SSH keys can be used.

```bash
# Generate agent-specific SSH key
ssh-keygen -t ed25519 -C "nova-backend@teamnova.dev" -f ~/.ssh/nova-backend

# Add to ssh-agent
ssh-add ~/.ssh/nova-backend

# Configure host in ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'
Host github.com-nova-backend
  HostName github.com
  IdentityFile ~/.ssh/nova-backend
EOF

# Add the public key in GitHub:
# Settings → SSH and GPG keys → New SSH key
# Title: "nova-backend"
# Key: (contents of ~/.ssh/nova-backend.pub)

# Use SSH remote
git remote set-url origin "git@github.com-nova-backend:team-nova/api.git"
```

> ⚠️ **Limitation:** Deploy keys have access to **only one repository**
> each. For multiple repositories, you need to add the same key to
> each one.

---

## 6. Recommended Approach for Multi-Agent Teams

Team Nova uses the following approach, combining simplicity and
security:

### 6.1 Profile Structure

Each agent has its own Hermes profile directory:

```
~/.hermes/profiles/
├── nova-orch/
│   ├── config.yaml
│   └── .env
├── nova-backend/
│   ├── config.yaml
│   └── .env
├── nova-frontend/
│   ├── config.yaml
│   └── .env
├── nova-devops/
│   ├── config.yaml
│   └── .env
├── nova-auditor/
│   ├── config.yaml
│   └── .env
└── nova-gitops/
    ├── config.yaml
    └── .env
```

### 6.2 YAML Configuration

Each `config.yaml` contains the agent's git configuration:

```yaml
# ~/.hermes/profiles/nova-backend/config.yaml
git:
  user_name: "Nova Backend"
  user_email: "nova-backend@teamnova.dev"
  token_env_var: "GITHUB_TOKEN_NOVA_BACKEND"
```

### 6.3 Token Storage

The actual token lives in the profile's `.env` file:

```bash
# ~/.hermes/profiles/nova-backend/.env
GITHUB_TOKEN_NOVA_BACKEND="github_pat_xxxxxxxxxxxxxxxxxxxx"
```

This file is **never committed** (included in the global `.gitignore`).

### 6.4 Automation on Agent Start

Whenever an agent is started, it executes:

```bash
# Load token from active profile
source ~/.hermes/active-profile/.env

# Set git identity
export GIT_AUTHOR_NAME="${HERMES_AGENT_NAME}"
export GIT_AUTHOR_EMAIL="${HERMES_AGENT_EMAIL}"
export GIT_COMMITTER_NAME="${HERMES_AGENT_NAME}"
export GIT_COMMITTER_EMAIL="${HERMES_AGENT_EMAIL}"

# Configure remote with token
git config user.name "${GIT_AUTHOR_NAME}"
git config user.email "${GIT_AUTHOR_EMAIL}"
```

### 6.5 Agent Activation Script

A single script manages activating the correct profile:

```bash
#!/bin/bash
# ~/.hermes/scripts/activate-agent.sh
# Usage: activate-agent.sh nova-backend

PROFILE_NAME="$1"
PROFILE_DIR="$HOME/.hermes/profiles/${PROFILE_NAME}"

if [ ! -d "$PROFILE_DIR" ]; then
  echo "Error: Profile '${PROFILE_NAME}' not found."
  exit 1
fi

# Activate the profile
ln -sfn "$PROFILE_DIR" "$HOME/.hermes/active-profile"
source "$PROFILE_DIR/.env"

echo "Profile activated: ${PROFILE_NAME}"
echo "Git user: $(git config user.name 2>/dev/null || echo 'not configured')"
```

---

## 7. Security Best Practices

### 7.1 Never Commit Tokens

- Add `.env` and `*.env` to the **global** `.gitignore`:
  ```bash
  git config --global core.excludesFile ~/.gitignore
  echo ".env" >> ~/.gitignore
  echo "*.env" >> ~/.gitignore
  ```
- Use `gitleaks` or `trufflehog` to scan the repository for
  accidentally committed tokens
- If a token is committed, **revoke it immediately** on GitHub and
  generate a new one

### 7.2 Rotate Tokens Every 90 Days

- Set expiration to **90 days** when creating the token
- Set a calendar reminder or automate with a script:
  ```bash
  # Example rotation script
  # 1. Generate new token via GitHub API
  # 2. Update the profile's .env file
  # 3. Test the new token
  # 4. Revoke the old token
  ```

### 7.3 Use Fine-Grained Tokens (never Classic)

- Fine-grained tokens have **per-repository** permissions
- Classic tokens have broad scopes like `repo` (all repositories the
  user accesses)
- An organization can **block classic tokens** in its security
  policies

### 7.4 Least Privilege

Each agent should have access **only** to the repositories it needs:

| Agent | Repositories |
|-------|-------------|
| `nova-orch` | `agent-ops-workflow` |
| `nova-backend` | `api`, `core-lib` |
| `nova-frontend` | `webapp`, `design-system` |
| `nova-devops` | `infra`, `k8s-configs`, `terraform` |
| `nova-auditor` | `agent-ops-workflow`, `docs` |
| `nova-gitops` | `ci-cd`, `vault-config`, `docs` |

### 7.5 Revoke Tokens for Deactivated Agents

When an agent is deactivated:

1. Go to https://github.com/settings/tokens?type=beta
2. Find the agent's token
3. Click **Delete** (trash icon)
4. Confirm revocation
5. Remove the agent profile from `~/.hermes/profiles/`

### 7.6 Monitoring

- Enable **security alerts** on GitHub to detect leaks
- Monitor GitHub API access logs to identify suspicious token usage
- Set up Slack notifications for new tokens created in the
  organization

---

## 8. Troubleshooting

### 8.1 "Permission denied" — Wrong or expired token

```
remote: Permission to team-nova/api.git denied to oauth2.
fatal: unable to access 'https://github.com/team-nova/api.git/':
  The requested URL returned error: 403
```

**Possible causes:**
- Token expired (fine-grained tokens have expiration dates)
- Token has been revoked
- Token does not have access to the specific repository
- Token is from an organization and has not yet been approved

**Solutions:**
```bash
# Check if the token is loaded
echo ${GITHUB_TOKEN_NOVA_BACKEND:0:10}  # shows first 10 chars

# Verify access via API
curl -s -H "Authorization: Bearer ${GITHUB_TOKEN_NOVA_BACKEND}" \
  "https://api.github.com/repos/team-nova/api" | head -5

# If it returns 404, the token has no access to the repo
# If it returns 401, the token is expired or invalid
```

### 8.2 Push rejected — Branch Protection

```
! [remote rejected] main -> main (protected branch hook declined)
error: failed to push some refs to 'https://github.com/team-nova/api.git'
```

**Causes:**
- The branch has protection requiring pull requests
- The branch requires status checks before merging
- The agent does not have permission to push directly to the
  protected branch

**Solutions:**
```bash
# Option 1: Create a feature branch and open a PR
git checkout -b feat/nova-backend/implementation
git push origin feat/nova-backend/implementation
gh pr create --title "Implementation" --body "Auto PR from Nova Backend"

# Option 2: Add the agent as an exception in branch protection
# GitHub → Repo → Settings → Branches → Edit rule → "Allow bypass"
```

### 8.3 Token not found — Environment variable not loaded

```
fatal: could not read Username for 'https://github.com': terminal prompts disabled
```

**Causes:**
- The profile `.env` was not loaded (`source` not executed)
- The environment variable has a different name than expected
- The shell profile (`.zshrc`, `.bashrc`) does not include the source

**Solutions:**
```bash
# Check if the variable exists
env | grep GITHUB_TOKEN

# Load manually
source ~/.hermes/profiles/nova-backend/.env

# Check which variable config.yaml expects
grep token_env_var ~/.hermes/profiles/nova-backend/config.yaml
```

### 8.4 "Workflow scope" Error with Classic PAT

```
! [remote rejected] main -> main
  (refusing to allow an OAuth App to create or update workflow
   `.github/workflows/ci.yml` without `workflow` scope)
```

**Cause:** The Classic PAT does not have the `workflow` scope.

**Solution:** Add the scope via GitHub CLI:
```bash
gh auth refresh -h github.com -s workflow
```

Or migrate to a fine-grained PAT with the **Workflows: Read and write**
permission.

### 8.5 Error Summary Table

| Symptom | Likely Cause | Solution |
|---------|-------------|----------|
| `403: Permission denied` | Expired token or no access | Check expiration and token permissions |
| `404: Not Found` on API | Token does not have repo access | Add repo in "Only select repositories" |
| Push rejected on protected branch | Branch protection rules | Create feature branch + PR |
| `could not read Username` | Token not loaded | `source ~/.hermes/profiles/AGENT/.env` |
| `workflow scope` | Classic PAT without workflow scope | `gh auth refresh -s workflow` or migrate to fine-grained |
| Token appears as `***` in terminal | Hermes terminal masking | Extract via Python: `open(".env").read()` |

---

## 9. Complete Configuration Example

### 9.1 Agent "nova-dev" (DevOps Engineer)

**Step 1:** Create the token on GitHub

```
Name:         hermes-agent-nova-dev
Expiration:   90 days
Repositories: infra, k8s-configs, terraform
Permissions:
  Contents:       Read and write
  Metadata:       Read-only
  Pull requests:  Read and write
  Actions:        Read
  Commit statuses: Read
  Workflows:      Read and write
```

**Step 2:** Configure the Hermes profile

```bash
# Create profile directory
mkdir -p ~/.hermes/profiles/nova-dev
```

```yaml
# ~/.hermes/profiles/nova-dev/config.yaml
name: "nova-dev"
description: "DevOps Engineer for Team Nova"

git:
  user_name: "Nova Dev"
  user_email: "nova-dev@teamnova.dev"
  token_env_var: "GITHUB_TOKEN_NOVA_DEV"

repos:
  - infra
  - k8s-configs
  - terraform
```

```bash
# ~/.hermes/profiles/nova-dev/.env
GITHUB_TOKEN_NOVA_DEV="github_pat_xxxxxxxxxxxxxxxxxxxx"
```

**Step 3:** Configure the shell profile

```bash
# ~/.zshrc (or ~/.bashrc)
export GITHUB_TOKEN_NOVA_DEV="github_pat_xxxxxxxxxxxxxxxxxxxx"

# Convenience: alias to activate the profile
alias activate-nova-dev="source ~/.hermes/profiles/nova-dev/.env && \
  git config user.name 'Nova Dev' && \
  git config user.email 'nova-dev@teamnova.dev'"
```

**Step 4:** Test the configuration

```bash
activate-nova-dev

# Check git identity
git config user.name     # Should return "Nova Dev"
git config user.email    # Should return "nova-dev@teamnova.dev"

# Verify repository access
curl -s -H "Authorization: Bearer ${GITHUB_TOKEN_NOVA_DEV}" \
  "https://api.github.com/repos/team-nova/infra" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('full_name','NO ACCESS'))"

# Make a test commit (inside the repository)
cd ~/projects/infra
echo "# Configuration generated by Nova Dev" >> README.md
git add README.md
git commit -m "docs(infra): add Nova Dev configuration note"
git push origin main
```

### 9.2 Orchestrator Configuration (Commander Alex)

Team Nova's orchestrator, **Commander Alex**, has a token with access
only to the `agent-ops-workflow` repository:

```yaml
# ~/.hermes/profiles/nova-orch/config.yaml
name: "nova-orch"
description: "Team Nova Orchestrator — planning and auditing"

git:
  user_name: "Commander Alex"
  user_email: "commander.alex@teamnova.dev"
  token_env_var: "GITHUB_TOKEN_NOVA_ORCH"

repos:
  - agent-ops-workflow
```

---

## 10. Quick Command Reference

### Create and configure tokens

| Action | Command / Link |
|--------|---------------|
| Create fine-grained token | https://github.com/settings/tokens?type=beta |
| View existing tokens | https://github.com/settings/tokens |
| Verify API access | `curl -H "Authorization: Bearer \$TOKEN" https://api.github.com/repos/OWNER/REPO` |

### Configure git with token

```bash
# URL with token (fine-grained)
git remote set-url origin "https://oauth2:${TOKEN}@github.com/OWNER/REPO.git"

# URL with token (classic)
git remote set-url origin "https://${TOKEN}@github.com/OWNER/REPO.git"

# Set identity
git config user.name "Agent Name"
git config user.email "agent@domain.com"
```

### Token management

```bash
# Check token expiration (via API)
curl -s -H "Authorization: Bearer ${GH_TOKEN}" \
  "https://api.github.com/user/personal_access_tokens"

# Revoke token (via GitHub CLI)
gh auth logout

# Test if token has repository access
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${TOKEN}" \
  "https://api.github.com/repos/OWNER/REPO"
# 200 = OK, 404 = no access, 401 = invalid
```

### Security

```bash
# Check for tokens in the repository
git secrets --scan
# or
gitleaks detect --source .

# Global .gitignore
git config --global core.excludesFile ~/.gitignore_global
echo ".env" >> ~/.gitignore_global
```

---

> **Document maintained by Team Nova — agent-ops-workflow**
>
> Version: 1.0
> Last updated: June 2026
>
> Next document: [09-SECURITY.md](09-SECURITY.md)
