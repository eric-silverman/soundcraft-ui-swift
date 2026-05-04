# Contributing

## Development workflow

The package is developed as a standard SwiftPM library.

- Run tests with `swift test`
- Keep public API docs close to the code with doc comments
- Keep long-form package guides in `Sources/SoundcraftUI/SoundcraftUI.docc`
- Keep upstream parity notes in [`PARITY.md`](PARITY.md)

If you move the checkout or hit stale local build artifacts, clean `.build/` or run with a temporary scratch path:

```bash
swift test --scratch-path /tmp/soundcraft-ui-swift-build
```

## Documentation

User-facing package documentation is split across:

- [`README.md`](README.md) for the GitHub landing page
- `Sources/SoundcraftUI/SoundcraftUI.docc` for published DocC guides and API reference navigation
- [`PARITY.md`](PARITY.md) for upstream TypeScript parity tracking

Build the static DocC site locally with:

```bash
bash scripts/build-docc-site.sh
```

The GitHub Pages workflow publishes the same output from `.build/docc-site/site`.

## Testing

Tests live in `Tests/SoundcraftUITests`.

- Use `MockWebSocketTransport` for facade and connection tests
- Prefer focused state/setup assertions over end-to-end timing where possible
- Add tests when parity work introduces or changes public behavior

## Parity maintenance

This repo tracks the upstream `fmalcher/soundcraft-ui` library.

- Review [`PARITY.md`](PARITY.md) before changing parity-sensitive code
- If upstream changes, port the relevant behavior and update the baseline SHA
- Keep tests and docs in sync with any newly ported surface
