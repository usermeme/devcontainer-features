## Notes

- `pnpm-store` is one named volume shared by every devcontainer on the machine: a package installed in one project can be reused by all others. postCreate only fixes the ownership of the store's top level, never recursively.
- The store is on a different filesystem than your project, so pnpm copies instead of hard-linking.
- Corepack state lives in `COREPACK_HOME=/usr/local/share/corepack`, owned by the remote user, so a pinned `version` applies to that user.
