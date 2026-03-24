# Curity UI Kit

[![production](https://img.shields.io/badge/quality-production-green)](https://curity.io/resources/code-examples/status/) [![source](https://img.shields.io/badge/availability-source-blue)](https://curity.io/resources/code-examples/status/)

**Customize the look and feel of your applications**

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="src/common/assets/images/ui-kit-start-dark.svg">
  <img alt="Curity UI Kit" src="src/common/assets/images/ui-kit-start.svg" width="800">
</picture>


This monorepo contains:

- Identity Server Templates
- Self Service Portal
- CSS Library
- UI Icons React Library
- React Component Library

## Prerequisites
- Node.js (version as specified in the `.nvmrc` file)

## Setup

This project uses a specific Node.js version as specified in the `.nvmrc` file. We recommend using [nvm (Node Version Manager)](https://github.com/nvm-sh/nvm) to ensure compatibility.

#### Using nvm

If you have nvm installed, you can automatically use the correct Node.js version by running:

```shell
nvm use
```

This will read the version from `.nvmrc` and switch to it. If the specified version isn't installed, you'll be prompted to install it with:

```shell
nvm install
```

#### Installing nvm

If you don't have nvm installed:

- **macOS/Linux**: Follow the [official installation guide](https://github.com/nvm-sh/nvm#installing-and-updating)
- **Windows**: Use [nvm-windows](https://github.com/coreybutler/nvm-windows)

## Install

To install all dependencies across a monorepo using npm workspaces, you just run:

```shell
npm install
```

## Start Preview Servers

To start preview servers concurrently for all projects, run:

```shell
npm run start
```

Then you can access the projects at:

- Curity Identity Server Templates: [http://localhost:3000](http://localhost:3000)
- Self Service Portal: [http://localhost:5173/previewer](http://localhost:5173/previewer)

To start projects individually, run:

- `npm run start:identity-server` - to start the Curity Identity Server Templates
- `npm run start:ssp` to start the Self Service Portal

## Build

To build everything, run:

```shell
npm run build
```

To build projects individually, run:

- `npm run build:identity-server` to build the Identity Server Templates
- `npm run build:ssp` to build the Self Service Portal
- `npm run build:css` to build Curity CSS library
- `npm run build:icons` to build Curity UI Icons React library


## Deploy

To deploy build artifacts (assets, templates, and messages) to a production environment, you can use the `deploy.sh` script.

### Prerequisites

1. Set the `IDSVR_HOME` environment variable to your Identity Server installation directory:
   ```shell
   export IDSVR_HOME=/path/to/idsvr/dist
   ```

2. Build the projects before deploying:
   ```shell
   npm run build
   ```

### Deployment Options

**Deploy to overrides (default):**
```shell
./deploy.sh
```
This deploys:
- Identity Server assets, templates, and messages
- Self Service Portal to `templates/overrides` and `messages/overrides`

**Deploy to a specific template area:**
```shell
./deploy.sh my-template-area
```
This deploys:
- Identity Server assets, templates, and messages
- Self Service Portal only to the specified template area (not to overrides)

### What Gets Deployed

**Identity Server:**
- Assets (CSS, Fonts, Images, JS) → `${IDSVR_HOME}/usr/share/webroot`
- Templates → `${IDSVR_HOME}/usr/share/templates`
- Messages → `${IDSVR_HOME}/usr/share/messages`

**Self Service Portal:**
- Templates → `${IDSVR_HOME}/usr/share/templates/overrides/apps/self-service-portal` or `template-areas/{area}/apps/self-service-portal`
- Messages → `${IDSVR_HOME}/usr/share/messages/overrides/{language}/apps/self-service-portal` or `template-areas/{area}/{language}/apps/self-service-portal`

### Remote Deploy Over SSH

If your Identity Server runs on a remote host, build artifacts locally and sync them via SSH using `deploy-remote.sh`.

#### Prerequisites

1. Build Identity Server artifacts locally:
    ```shell
    npm run build:identity-server
    ```
2. Ensure SSH access to the remote host.
3. Ensure `rsync` is available locally.

#### Basic Usage

```shell
npm run deploy:remote -- --host <remote-host> --user <remote-user>
```

This syncs:
- `src/identity-server/build/webroot` → `/opt/idsvr/usr/share/webroot`
- `src/identity-server/build/templates` → `/opt/idsvr/usr/share/templates`
- `src/identity-server/build/messages` → `/opt/idsvr/usr/share/messages`

#### Useful Options

- Custom SSH port:
   ```shell
   npm run deploy:remote -- --host <remote-host> --user <remote-user> --port 2222
   ```
- SSH key file:
   ```shell
   npm run deploy:remote -- --host <remote-host> --user <remote-user> --identity-file ~/.ssh/id_rsa
   ```
- Simulate deploy (no changes):
   ```shell
   npm run deploy:remote -- --host <remote-host> --user <remote-user> --dry-run
   ```
- Remove remote files not present locally in synced folders:
   ```shell
   npm run deploy:remote -- --host <remote-host> --user <remote-user> --delete
   ```
- Run a remote restart command after deploy:
   ```shell
   npm run deploy:remote -- --host <remote-host> --user <remote-user> --restart-cmd "sudo systemctl restart idsvr"
   ```

### Core Restore + Partner Portal Runbook

For the full operational procedure to restore Curity defaults in environment core paths and then deploy the Partner Portal multi-brand theme, see:

- [README-CORE-RESTORE-AND-PARTNER-PORTAL-DEPLOY.md](README-CORE-RESTORE-AND-PARTNER-PORTAL-DEPLOY.md)

## License
Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
