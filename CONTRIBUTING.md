# Contributing

Thanks for your interest in improving herdr-file-finder!

## Reporting bugs / requesting features

Open an issue using the templates under **New issue**. Please include your
macOS version, herdr version (`herdr --version`), and the versions of `fd`,
`fzf`, `jq`, and `bat` when relevant.

## Development setup

```bash
brew install fd fzf jq bat
herdr plugin link /path/to/herdr-file-finder   # link, not copy — edits apply live
```

The plugin is pure Bash — there is no build step. Edit the scripts under
`src/` and the change takes effect on the next invocation.

## Pull requests

1. Fork and create a topic branch off `main`.
2. Keep changes focused; one logical change per PR.
3. Test on macOS with a real herdr install before opening the PR — describe
   what you verified in the PR body.
4. Match the existing shell style: `set -euo pipefail`, quote expansions, and
   keep the scripts POSIX-friendly where practical.

## Shell guidelines

- Run [`shellcheck`](https://www.shellcheck.net/) on any script you touch.
- Prefer clear, small functions over clever one-liners.
- Preserve the placeholder contract (`{uri}` / `{path}` / `{dir}`) documented
  in the README.

## License

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE).
