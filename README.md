# Venworks AgentKit

A ready-made Codex workflow for planning, coding, infrastructure operations, art, 3D modeling, research, reviews, and documentation.

AgentKit gives Codex a set of specialist roles, shared instructions, and reusable task prompts. You describe the work, and the coordinator chooses the help it needs. The workflow adapts to your project's tools and conventions, whether you are building an application, managing infrastructure, creating assets, or writing documentation. The prompts can also read requirements from a Plane work item, so you do not have to copy everything into your task.

**Your existing Codex settings stay yours.** Installing or updating AgentKit does not replace your existing configuration, connections, or model preferences.

> [!NOTE]
> **Planned: more model choices through OpenRouter.** The goal is to let selected specialists use OpenRouter models while your main Codex assistant continues using OpenAI. This is waiting on a Codex bug that can ignore a specialist's provider choice and send its request to the wrong provider. Follow [Codex issue #40858](https://github.com/openai/codex/issues/40858) for progress. OpenRouter support is currently disabled; it will need to be checked and configured after the fix is available.

## What you get

- **Twelve specialists** for coding, infrastructure operations, architecture, graphic design and art, 3D modeling, research, code review, deeper review, security review, technical documentation, user guides, and marketing copy.
- **Thirteen shared instruction sets**, called skills, that explain how the coordinator and specialists should work.
- **Eight ready-to-use prompts** for new features, bug fixes, reviews, release preparation, documentation, marketing, and resuming unfinished work.
- **Infrastructure-as-code support** through `tech-ops`, using your project's existing tools to maintain configuration, prepare changes, investigate drift, and verify authorized operations.
- **Testing instructions with every implemented change**, covering setup, commands or manual steps, expected results, and what was actually checked. The implementing specialist supplies them, and the coordinator checks that the handoff covers the delivered work.
- **Delivery through a ready-for-review PR**, with a scoped commit and branch push included in the normal definition of done for repository changes. Explicit local-only instructions and read-only assignments retain their limits.
- **Art and 3D work within feature delivery**, using the skills and tools available in your setup to create assets, keep editable source files, and check exports in the project where possible.
- **Diagrams for architecture, technical documentation, and PRs**, with Mermaid Markdown for structure and flows and optional [PR Lens](https://github.com/coldteadotai/pr-lens) visuals when available. See the [diagram and PR guidance](skills/agent-router/references/diagrams-and-prs.md).
- **Optional tooling and credential policies** for shared defaults, repository-specific tools, named service accounts, and scoped operational permissions.
- **One installer for setup and updates**, with previews, backups, and checks before replacing files you have changed.

## Before you start

You will need Windows, **PowerShell 7 or newer**, and a signed-in Codex installation that supports custom agents and skills. The older app named *Windows PowerShell* is not PowerShell 7.

Your Codex account must have access to the models listed under [Model settings](#model-settings). Some settings also depend on your Codex version. The installer copies the files; it does not check model access or set up a Plane connection.

## Install

1. Download this repository using **Code → Download ZIP** on GitHub, then extract it. If you already use Git, cloning the repository works too. Keep the complete folder together.

2. Open that folder in PowerShell 7. You should be in the folder containing `README.md` and the `tools` folder. Run this command to preview the installation:

```powershell
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -WhatIf
```

The preview checks for problems and shows where AgentKit will be installed. It does not change any files.

3. If the preview reports no problems, run the installation:

```powershell
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1
```

Look for `Installed package` in the result. If the same version and files are already installed, you will see `Installation is already current` instead. Start a new Codex task to use the installed instructions.

AgentKit normally installs into your user account's `.codex` folder. If you have set `CODEX_HOME`, it uses that location instead. It installs local copies, so you do not need to keep the downloaded folder in the same place afterward.

### Optional: start with the example settings

If you are setting up a Codex home that does not already have a `config.toml`, you can create one from [the example settings](Config-Settings.toml.example):

```powershell
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -InitializeConfig -WhatIf
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -InitializeConfig
```

Read the example first. It includes the suggested models, support for multiple assistants, memory and context options, and a limit of 12 assistants running at once. It contains no account credentials or service connections. If you already have a configuration file, these commands leave it unchanged.

## Give AgentKit a task

Open a new Codex task in the project you want to work on. For a simple assignment, start your message with `$agent-router` and describe what you need:

```text
$agent-router

Help me improve the installation instructions in this project so a first-time user can follow them.
```

For a more structured assignment, open the [prompt guide](prompts/README.md), choose a template, replace its bracketed fields, and paste the complete text block into Codex.

The templates accept a Plane work-item ID or link. Codex needs access to Plane to read it. If you are not using Plane, replace the work-item input and the instruction to retrieve it with your own description of the task.

For art or 3D modeling, choose the [full feature delivery prompt](prompts/01-full-feature-delivery.md) and fill in its `Art/3D requirements` field. Describe what you need and include references, file formats, dimensions, or scale when you know them. The workflow asks Codex to agree on those details, keep editable originals, and check that exported assets work in the intended project when the necessary tools are available. The included `graphic-design` and `3d-modeling` specialists each have a matching skill and use the creative tools available in your setup. Codex should tell you when a required tool or check is unavailable.

For infrastructure work, ask the coordinator to use `tech-ops`. For example: "Update this project's infrastructure configuration and prepare a plan for review; do not apply it." The specialist uses the project's existing tools, such as Terraform, OpenTofu, Bicep, CloudFormation, Pulumi, Ansible, or Kubernetes tooling. It checks the target environment and reports separately what was edited, validated, and actually applied. Installing AgentKit does not install those tools or configure cloud credentials.

The prompts are text you copy and paste, not automatically added menu items or slash commands. A copy is also installed in your Codex `prompts` folder.

The workflow asks for reviews that fit the assignment. **Adversarial review—a deeper attempt to find hidden failures—is reserved for major new features, newly introduced frameworks or libraries, or an explicit request.** Routine fixes and documentation changes do not automatically need it. Security review is off by default. You can explicitly request it for any project; ordinary workflow prompts do not start it automatically. AgentKit uses its own local reviewer; it does not automatically launch the separate Codex Security scan product or require Daybreak access. The instructions also ask assistants to preserve useful progress and report unfinished or unverified work honestly.

## Definition of done

When you ask AgentKit to implement a repository change, the normal workflow continues through the applicable reviews, checks, and testing instructions, then commits the scoped changes, pushes the task branch, and creates or updates a **ready-for-review PR**. You do not need to ask separately for each Git step. The coordinator owns delivery after integrating specialist work; directly invoked specialists own it when there is no coordinator. See [Git delivery and definition of done](skills/agent-router/references/git-delivery.md).

Instructions such as "local changes only," "do not commit," or "do not push" override this default. Review-only, research, planning, and release-readiness tasks keep their report scope, and non-Git artifact work does not require a new repository. Delivery does not include merging, deployment, release publication, or marking external work items Done. If a required delivery step is blocked, AgentKit reports what completed and what remains; successful local edits alone do not count as completed Git delivery.

## Testing handoff

Every implemented change includes [testing instructions](skills/agent-router/references/testing-handoff.md) in the final response or a linked guide. The implementer owns the steps, and the coordinator checks coverage after the final fixes. Larger guides can use technical documentation or user documentation specialists; this phase does not require an additional agent.

Expect prerequisites, runnable commands or manual actions, expected results, relevant regression checks, and cleanup when a check changes state. Results show which checks passed, failed, or were not run, with any runtime or platform limits. Small documentation or asset changes receive proportionate proofreading, rendering, or integration steps. Writing instructions does not replace checks the assistant can and should run within the authorized task.

## Choose tools and service accounts

AgentKit can follow shared defaults and repository-specific policies. Use a tooling policy to choose tools for each specialist and a credential policy when a tool must use a named account. These files guide the agents; they do not configure a connector, create permissions, or log in automatically.

| Location | Applies to |
| --- | --- |
| `tooling-policy.md` and `credential-policy.md` in your Codex home | Shared defaults across projects. Your Codex home is normally your user `.codex` folder, or the location set by `CODEX_HOME`. |
| `.codex/tooling-policy.md` and `.codex/credential-policy.md` at a repository root | Overrides for that repository. Nested policy folders are not loaded. |

Start with the [example setup guide](example/README.md). Copy only the examples you need into the locations above, replace the placeholders, and configure the tools, account references, targets, and operations you intend to use. Repository entries replace matching shared entries in full; entries with other IDs remain available. Agents use these selections within your current task or existing authorization and verify the actual account and target before authenticated work. No adoption record, policy-hash baseline, or execution-review artifact is required, including for an existing login or identity check. Optional policies do not create a new approval workflow, and a policy entry cannot authorize actions beyond your instructions.

For example, define a shared GitHub identity for your automation account, reference its password-manager card, and require GitHub tools to verify that account before acting. A repository can separately tell tech-ops which infrastructure tool and development workspace to use, and whether plans are already authorized. Credential files contain references and verification instructions, never passwords or tokens. Keep private account or vault details in your local shared policy when they should not be published.

Sanitized templates live in the top-level `example/` folder and are excluded from installation into Codex. They are consulted only for explicit setup or example-editing work. It leaves active policy files alone and does not configure accounts, password managers, or tooling. An unavailable required tool, unverified account or Git transport, an unexpected credential destination, or unclear permission stops the affected operation while other useful work can continue. A policy naming a service account does not switch an existing connector to that account; account setup and verification remain explicit steps.

## Update AgentKit

Download and extract the latest complete package, then open its folder in PowerShell 7 and run the same commands:

```powershell
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -WhatIf
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1
```

If you installed from a Git clone and have no local changes in that clone, you can run `git pull --ff-only` first instead of downloading another ZIP.

There is no separate upgrade mode. The installer checks what changed, updates AgentKit's files, and leaves unrelated files and your existing configuration alone. Running it again when everything is current does not create extra backups. Start a new Codex task after updating.

Close editors working on AgentKit's installed files and let one installation finish before starting another.

### If you have edited an installed file

The installer stops before replacing a conflicting file. Review the files it names and keep a separate copy of any changes you want to retain.

If you intentionally want to replace those files with the package's versions, preview and then use `-Force`:

```powershell
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -Force -WhatIf
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -Force
```

The previous files are backed up. Your existing `config.toml` is still preserved.

When a newer package stops including a file, the installer backs up and removes the old copy if you have not edited it. If you have edited it, the update stops for your attention. With `-Force`, that edited file stays where it is and AgentKit stops managing it. An update that cannot keep it in place will still stop; move that file somewhere safe before retrying.

## Moving from the earlier OneDrive setup

Use this section only if you previously connected Codex's AgentKit folders to OneDrive with the old scripts.

Those connections are called *junctions*: they make a local folder point to a shared folder somewhere else. The new installer asks you to choose migration explicitly before replacing a supported connection with a local copy:

```powershell
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -MigrateJunctions -WhatIf
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -MigrateJunctions
```

Migration keeps the connected folder's contents locally and leaves the original shared files untouched. It supports connections for the whole `agents` and `prompts` folders and for individual skills included in this package. Other connection layouts are rejected. If your files also conflict with the package, follow the guidance under [edited files](#if-you-have-edited-an-installed-file).

After migration, use this installer to update each computer. Stop using the old OneDrive publish/connect scripts for that Codex home, since reconnecting would restore the old folder links.

## If something goes wrong

| What you see | What to do |
| --- | --- |
| `pwsh` is not recognized | Make sure PowerShell 7 is installed, then reopen your terminal. |
| The installer script cannot be found | Open PowerShell in the extracted package folder containing `README.md` and the `tools` folder, then try again. |
| A message about conflicting or edited files | Review the named files using the steps above before choosing whether to replace them. |
| A message about a junction or redirected folder | If you used the earlier OneDrive setup, check the migration section. Otherwise, review the location named in the message; `-Force` does not bypass these location checks. |
| A model is unavailable in Codex | Check that your account and Codex version support the configured model. Installing the files does not grant model access. |
| A write or recovery error | Keep the full error message and the backup folder shown in the result. Resolve the reported problem before trying again. |

When an installation makes changes, it saves recovery information and any replaced files under `.venworks-agentkit/backups` in your Codex folder. Keep each backup folder and its contents together.

The installer tries to undo its changes if a write fails. It cannot do that after a power loss or a forcibly closed process. If recovery is needed, preserve any newer edits and restore only the affected files identified in that backup's record. Do not delete your whole Codex folder. If you are unsure, ask for help using the error message and backup location before making more changes.

## Model settings

The included specialists use these settings. The *reasoning* column is the model's configured effort level.

| Specialist | Model | Reasoning |
| --- | --- | --- |
| Coding | GPT-5.6 Sol | high |
| Tech ops / infrastructure as code | GPT-5.6 Sol | high |
| Software architecture | GPT-6 Astra | medium |
| Graphic design and art | GPT-6 Astra | low |
| 3D modeling | GPT-6 Astra | high |
| Code review | GPT-6 Astra | medium |
| Adversarial review | GPT-6 Astra | high |
| Security review (opt-in) | GPT-6 Astra | medium |
| Research | GPT-5.6 Luna | high |
| Technical documentation | GPT-5.6 Luna | high |
| User documentation | GPT-6 Astra | low |
| Marketing documentation | GPT-6 Astra | low |

Your main assistant keeps the model and reasoning in your existing Codex settings. The optional example uses GPT-6 Astra with `low` reasoning and GPT-5.6 Sol with `high` as the default for additional assistants. Updating AgentKit preserves an existing `config.toml`, so changing the example does not change your current main assistant. The workflow uses the default service tier and does not enable Fast mode. It limits reasoning to `xhigh`, except for Luna, which may use `max`.

These are starting defaults, with more effort reserved for tasks that need it. Routine coordination, visual direction, and public-facing writing start at Astra `low`; architecture and normal/security reviews start at `medium`; 3D modeling and adversarial review keep `high` for difficult asset work and deeper failure analysis. Sol remains the implementation model, and Luna remains the focused research and technical-writing model. Increase effort when ambiguity, difficult interactions, or observed results justify it, within the runtime's supported settings and the package's limits. Explicit user model and reasoning choices take precedence.

OpenAI calls `low` **Light** in the app and recommends using the lowest effort that produces the needed result. The official pages consulted do not establish an exact Astra Light = Sol High equivalence. Treat these selections as defaults to evaluate against familiar work, not as a benchmarked quality or savings guarantee. See [OpenAI's reasoning guidance](https://learn.chatgpt.com/docs/models#pick-a-reasoning-effort) and [Astra's supported effort levels](https://developers.openai.com/api/docs/models/gpt-6-astra). Compare completion quality, missed defects, unnecessary findings, time, and usage on representative tasks before increasing defaults across all roles.

### Image generation for graphic design

The graphic-design specialist's Astra setting controls planning, tool use, and review. The model that renders an image is a separate tool setting. OpenAI's September 8, 2026 release adds [**GPT Image 2.5 Flare**](https://developers.openai.com/api/docs/models/gpt-image-2.5-flare) for fast everyday generation and [**GPT Image 2.5 Sunburst**](https://developers.openai.com/api/docs/models/gpt-image-2.5-sunburst) for precise editing. These are the preferred choices when an authorized image tool exposes model selection and its endpoint, tool/SDK options, and configured account support the requested model. AgentKit checks current official guidance and available capability evidence; a public model listing alone does not prove account or tool access. See the [release notes](https://developers.openai.com/api/docs/changelog) and [image-generation guide](https://developers.openai.com/api/docs/guides/image-generation).

The graphic-design subagent can use the built-in image-generation tool when that tool is available to it. The interface checked for this update exposes no model selector or backend identity, so AgentKit cannot force or confirm Image 2.5 through that interface. It keeps the available built-in path and reports this limitation when a particular image model is requested. Unsupported or unverified selections are reported without silently substituting a model or claiming a backend ran. Explicit API model selection needs an authorized, configured API workflow; installing AgentKit does not set up that access or update installed wrappers. Existing SVG and other editable vector assets still use the appropriate native tools.

### Future OpenRouter support

The planned OpenRouter option would give selected specialists access to models from other providers. The [OpenRouter example](OpenRouter-Future.toml.example) and comments in four agent files are preparation for that option, not a working setup to enable today.

The blocking [Codex provider issue (#40858)](https://github.com/openai/codex/issues/40858) reports that a specialist can pick up its assigned model while ignoring the provider assigned to it. The request then uses the parent's provider and can fail. The issue is open at the time of this update.

Once the bug is resolved, the example settings and chosen models will need to be tested with the fixed Codex version before support is enabled. The installer does not turn on OpenRouter or set up credentials, and a failed request should not be expected to switch automatically to another model.

## Advanced options and contributor notes

<details>
<summary>Use a different Codex folder</summary>

Add `-CodexRoot` to select a different installation location:

```powershell
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -CodexRoot 'D:\CodexHome' -WhatIf
pwsh -NoProfile -File .\tools\Install-CodexAgents.ps1 -CodexRoot 'D:\CodexHome'
```

Configure Codex separately to use that same location. This option changes where the files are installed, not how Codex is launched.

</details>

<details>
<summary>How updates are tracked</summary>

`VERSION` identifies the package version. The installer records its installed files and their hashes in `.venworks-agentkit/manifest.json` so it can detect updates and local edits. Keep that record in place. Backup storage must also remain a normal local directory, not a junction to another location.

</details>

<details>
<summary>Keep personal data out of this public repository</summary>

Only contribute reusable workflow files, documentation, installer/tests, and sanitized examples. Never copy your live Codex folder, configuration, credentials, sessions, or memories into this repository. Review your changes and scan for secrets before committing; `.gitignore` is only an extra precaution.

Git commits can also include your email address. Check your Git identity before committing. Changing it affects future commits, not existing history. The installer does not commit or push anything.

</details>

<details>
<summary>Run the installer and Git delivery tests</summary>

From the repository folder, run:

```powershell
pwsh -NoProfile -File .\tests\Test-Installer.ps1
pwsh -NoProfile -File .\tests\Test-GitDeliveryIsolation.ps1
```

The tests use temporary example folders under `.work`, including test junctions, local Git repositories, and logs. The Git isolation check runs the delivery harness with a clean environment and an inherited template containing a harmless rejecting hook; both must pass without that ambient hook executing. The tests do not install into your live Codex folder, change your templates, or use real credentials. Generated test output is excluded from Git; maintained scripts and regression fixtures belong in the delivered change. See the [testing guide](tests/README.md) for prerequisites, expected results, Git failure cases, cleanup, and separate fresh-agent and image-selection acceptance checks.

</details>

## License

See [LICENSE](LICENSE).
