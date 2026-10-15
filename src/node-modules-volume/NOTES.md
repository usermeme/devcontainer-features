## Notes

- The volume is named `${devcontainerId}-node_modules`, so two projects whose folders have the same name no longer share `node_modules`. Upgrading from 1.0.0 starts with an empty volume; the old `<folder>-node_modules` volumes can be removed with `docker volume rm`.
- The volume is mounted at `/workspaces/<folder name>/node_modules`; a custom `workspaceFolder` or `workspaceMount` does not get it.
- Fixing the ownership of a fresh volume needs root or passwordless sudo in the container; otherwise postCreate prints the command to run.
