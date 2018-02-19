# JIRA Deployment

## Requirements

- [git-crypt](https://github.com/AGWA/git-crypt)
- [NixOps](https://nixos.org/nixops/)

## Deployment

1. Setup git-crypt

```bash
$ git-crypt unlock /path/to/key
```

2. Create NixOps deployment

```bash
$ nixops create ./jira.nix ./jira-secret.nix ./jira-hsrserver.nix -d jira-hsr
```

(or use `jira-vbox.nix` instead of `jira-hsrserver.nix` to deploy to virtual machine)

3. Deploy

```bash
$ nixops deploy -d jira-hsr
```
