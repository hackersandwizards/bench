# Transcription

`transcribe [-o outdir] file...` writes a `.txt` transcript and `.srt` subtitles for each recording. Both files go next to the input by default.

Download **Parakeet Ultra** in T3 Code's speech settings. The command reads T3 Code's model at `~/.t3/userdata/speech/models/parakeet-ultra-Q8_0.gguf`. It converts each input to 16 kHz mono with ffmpeg and runs [transcribe.cpp 0.5.0](https://pypi.org/project/transcribe-cpp/0.5.0/) through uv. Parakeet Ultra detects the spoken language and splits long recordings at pauses.

Subtitles use the model's word timestamps. Each cue ends at sentence-ending punctuation or splits at a word boundary when the sentence runs past about 10 seconds.

## Why Parakeet Ultra

The bench maintainer chose Parakeet Ultra on 2026-11-27. T3 Code's bundled catalog lists word error rates of 4.58% in German and 4.26% in English, with 1.3 seconds of processing per 30 seconds of audio. It lists Whisper Large v3 Turbo at 4.54% and 4.38%, with 9.7 seconds per 30 seconds of audio.

Bench's 2026-10-31 German test measured 7.11% for chunked Parakeet TDT v3 and 6.25% for Whisper. Parakeet Ultra has yet to be measured on the bench test sets.
