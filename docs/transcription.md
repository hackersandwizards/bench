# Transcription

`transcribe talk.mp4` writes `talk.txt` and `talk.srt` (segment timestamps) next to the input, or into `-o <dir>`. It runs `whisper-cli` from the Homebrew `whisper.cpp` package with Whisper large-v3-turbo and `-mc 0`. `-l de` sets another language; English and German are measured below. flac, mp3, ogg and wav go in as they are, anything else passes through ffmpeg first.

The wizard does not install the model. `transcribe` expects it at `~/.cache/whisper/ggml-large-v3-turbo.bin` (1.6 GB) and prints the download command when the file is missing.

Use `transcribe`, never bare `whisper-cli`. At its defaults `whisper-cli` feeds each 30-second window the text of the window before. On one of our conference recordings that wrote a sentence spoken once six times in a row, and it carried the first window's lower-case, unpunctuated style through all 27 minutes. `-mc 0` switches that conditioning off and removed both defects. `bench-test` fails when the script stops passing the flag. `parakeet-cli` ships in the same Homebrew package and is not used.

## Why Whisper

Measured on 2026-10-11 on an M3 Max with 64 GB and whisper.cpp 1.9.5. WER is the word error rate in percent, lower is better, after Whisper's English text normalizer. Set A is four Earnings-22 calls: non-native speakers on telephone audio, 150 minutes, 20,569 reference words. Set B is the TED-LIUM 3 long-form test set: four speakers, 78 minutes, 12,975 reference words. The interval is a 95 % bootstrap over windows of 100 reference words.

| Model, runner | WER A | WER B | Pooled [95 %] | Defects in 4.8 h of audio | Timestamps | 33 min of audio | Peak memory |
|---|---|---|---|---|---|---|---|
| Whisper large-v3-turbo, `whisper-cli` defaults | 14.19 | 2.77 | 9.77 [8.86, 10.70] | 1 loop of 5 invented repeats, 1 file without punctuation | segments, median 4 to 6 s | 53 s | 2.5 GB |
| Whisper large-v3-turbo, `whisper-cli -mc 0` | 13.99 | 3.01 | 9.74 [8.85, 10.64] | none | segments, median 2 to 4 s | 44 s | 2.5 GB |
| Parakeet TDT 0.6B v3, `parakeet-cli` | 17.46 | 3.21 | 11.95 [10.71, 13.23] | 13 dropped passages, 470 words | none written to a file | 17 s | 2.3 GB |
| Granite Speech 4.1 2B, mlx-audio | 11.95 | 3.24 | 8.58 [7.60, 9.73] | 5 repetition loops, up to 191 repeats | none, 25 s chunks | 121 s | 10.9 GB |
| Cohere Transcribe 03-2026, transformers | 14.30 | 3.11 | 9.97 [9.05, 10.90] | 1 invented passage, 27 words | none, 33 s chunks | 33 s | 10.0 GB |
| Canary-Qwen 2.5B, NeMo | 13.34 | 2.55 | 9.17 [8.29, 10.05] | none | none, 25 s chunks | 206 s | 15.2 GB |

Granite and Canary-Qwen lead the pooled score by 1.2 and 0.6 points, and the bootstrap separates both from Whisper. Granite's lead comes from set A alone: on set B it trails Whisper at defaults. Neither model writes timestamps, and both need a Python environment and a chunking script. Whisper is the only model with segment timestamps, and it runs from one Homebrew package.

Limits of the measurement: set A is four calls from four companies, and set B is mostly native speakers. The interval covers variation inside those recordings, not between speakers. On two of our own talks a list of 30 and 28 names and technical terms did not separate the candidates, each recalled 19 to 25. Time is the median wall time for one 33-minute recording, model load included, over three runs per row and two for Canary-Qwen.

Rechecked on 2026-10-31 with the same sets and scoring, `-mc 0` reproduced to the digit. Parakeet's dropped passages come from encoding the whole file in one pass, in `parakeet-cli` and in transcribe.cpp alike. transcribe.cpp is the runner inside Hex, which gives identical transcripts but writes no timestamps. Cut into 20 to 30 s chunks at the quietest 100 ms, Parakeet TDT v3 Q8_0 in transcribe.cpp scored 13.27 / 2.61 / 9.14 [8.22, 10.09] with 2 dropped passages of 63 words: 0.60 [0.11, 1.07] points ahead of Whisper and about four times faster. Parakeet Unified English tied Whisper when chunked and returned an empty transcript for a 46-minute call fed whole. On German, VoxPopuli parliament speech and Multilingual LibriSpeech at 60 minutes each, scored after Whisper's basic normalizer, `whisper-cli -l de -mc 0` reached 6.25 [5.57, 6.97] and chunked TDT v3 7.11 [6.23, 8.04] with one dropped passage. Whisper stays for every language: the English gain does not pay for a source build, a chunker and an `.srt` writer.
