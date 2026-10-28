
# GitHub CLI & Restricted Token Auth (github)

Installs GitHub CLI (gh) if not present, forwards the host's DEVCONTAINER_GITHUB_TOKEN into GH_TOKEN and GITHUB_TOKEN inside the container, and configures Git to authenticate over HTTPS using that token.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/github:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | GitHub CLI (gh) version to install when gh is not already present (e.g. 'latest' or '2.67.0') | string | latest |
| gitProtocol | When 'https', rewrites git@github.com: and ssh://git@github.com/ remotes to https://github.com/ in system Git config so git push/pull uses the restricted token instead of forwarded host SSH keys | string | https |

## Host setup

Create a fine-grained Personal Access Token on GitHub scoped only to the repositories and permissions you want the container to have (for example, **Contents: Read and write** and **Pull requests: Read and write** on a single repository), and export it in your host `~/.zshrc`:

```sh
export DEVCONTAINER_GITHUB_TOKEN="github_pat_..."
```

Keeping it under `DEVCONTAINER_GITHUB_TOKEN` on the host leaves your host's `GH_TOKEN` / `GITHUB_TOKEN` and `gh auth` login untouched.

## What it configures in the container

- **Environment (`remoteEnv`)**: Forwards `${localEnv:DEVCONTAINER_GITHUB_TOKEN}` into `GH_TOKEN`, `GITHUB_TOKEN`, and `DEVCONTAINER_GITHUB_TOKEN` inside the container. Because it uses `remoteEnv` rather than `containerEnv`, the token is not baked into the image or container config (`docker inspect`).
- **GitHub CLI (`gh`)**: Installs the official `gh` release binary (verified against `gh_<version>_checksums.txt`) if `gh` is not already installed on the image. With `GH_TOKEN` set, `gh pr create`, `gh pr view`, `gh api`, etc. authenticate immediately without `gh auth login` or writing tokens to `~/.config/gh/hosts.yml`.
- **Git credential helper**: Configures `/etc/gitconfig` (`--system`, so a stowed `~/.gitconfig` from the `dotfiles` feature is never modified on the host) to authenticate `https://github.com` and `https://gist.github.com` via `gh auth git-credential`.
- **SSH-to-HTTPS remote rewrite (`gitProtocol: "https"`, default)**: Adds `url."https://github.com/".insteadOf` for `git@github.com:` and `ssh://git@github.com/` in `/etc/gitconfig`. Even if the repository on the host was cloned over SSH and VS Code forwards `SSH_AUTH_SOCK`, `git push` and `git fetch` inside the container go over HTTPS and are bound to the restricted `DEVCONTAINER_GITHUB_TOKEN` permissions instead of your unrestricted host SSH key. Set `"gitProtocol": "ssh"` to disable this rewrite.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
