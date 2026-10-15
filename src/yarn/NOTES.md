## Notes

- Requires Node.js (Corepack or npm) in the image.
- `yarn-cache` is one named volume shared by every devcontainer on the machine. Yarn Berry's global cache (`YARN_GLOBAL_FOLDER`) is placed inside it as well.
- With `runInstall` and `immutable` (default), an out-of-date lockfile fails the install instead of being rewritten.
- Corepack shims are installed to `/usr/local/share/corepack-shims`, which is placed before the rest of `PATH`, so the configured version wins over a yarn that ships with the base image (the official Node feature preinstalls pnpm, Node images ship yarn 1.x).
