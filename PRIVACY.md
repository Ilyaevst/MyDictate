# Privacy

MyDictate is designed for local dictation.

## Data that stays on the Mac

- Microphone audio is processed locally and is not sent to a transcription API.
- Every successful transcript is saved as a plain-text file under
  `~/Library/Application Support/MyDictate/Saved Dictations/Transcripts` before
  MyDictate attempts to paste it. These files remain until the user deletes
  them.
- Timing statistics, corrections, preferences, and the short in-app history are
  stored locally under `~/Library/Application Support/MyDictate`.
- Diagnostic logs are stored in `~/Library/Logs/MyDictate.log` and avoid
  transcript text.
- While dictation is active, recoverable audio is continuously journaled under
  `~/Library/Application Support/MyDictate/Saved Dictations/Pending Audio`.
  After successful recognition and transcript archival, that pending audio is
  removed.
- If recognition fails or returns no text, the pending audio is retained for a
  retry and a standard WAV copy is saved under
  `~/Library/Application Support/MyDictate/Saved Dictations/Failed Audio`.
- The speech model is cached by FluidAudio under
  `~/Library/Application Support/FluidAudio/Models`.

## Network access

MyDictate uses the network only to download a selected speech model and to
check the public GitHub Releases feed for MyDictate updates. When the user
presses Update, it downloads the corresponding application archive and its
SHA-256 manifest from the same public repository. Recognition itself is local.
It has no account system, advertising, analytics, or telemetry.

## macOS permissions

- **Microphone** records speech while dictation is active.
- **Accessibility** inserts the resulting text into the focused field.
- **Input Monitoring** observes the configured global hotkey.
