# Contributing

Issues and pull requests are welcome. Please keep changes focused, preserve
local-only transcription, and test on an Apple Silicon Mac running macOS 14 or
newer.

Before opening a pull request, run:

```bash
swift run -c debug --package-path swift Parakey --self-test all
./scripts/build-app.sh ./dist/SuperDictate.app
```

