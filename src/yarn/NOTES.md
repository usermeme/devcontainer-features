## Notes

- Requires Node.js (Corepack or npm) in the image.
- `yarn-cache` is one named volume shared by every devcontainer on the machine. Yarn Berry's global cache (`YARN_GLOBAL_FOLDER`) is placed inside it as well.
- With `runInstall` and `immutable` (default), an out-of-date lockfile fails the install instead of being rewritten.
