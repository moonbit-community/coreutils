# TODO

## Pre-existing bugs carried forward

- Fix `rmdir -I` / `--ignore-fail-on-non-empty`.
  The command should ignore failures that are solely caused by non-empty
  directories. The current control flow skips the diagnostic when `-I` is set,
  but still calls the removal function. On wasm-gc this was observed deleting a
  non-empty directory and its contents.

- Fix `wc` line counting.
  `wc` currently uses `content.split("\n").count()`, which counts fields rather
  than newline characters. For example, `a\nb\nc\n` is reported as 4 lines
  instead of 3, and empty stdin is reported as 1 line instead of 0.

- Fix `wc` word counting.
  `wc` currently replaces newlines with spaces and splits only on the ordinary
  space character. It should treat all whitespace as delimiters; for example,
  `a\tb\n` should count as 2 words, not 1.

- Fix `head -c` and `tail -c` output.
  Character-count mode currently uses `println`, which appends an extra newline.
  The command should emit exactly the requested character slice.

## Test coverage gaps

- Add assertions to the `wc` and `rmdir` shell tests.
  The current tests mostly check that commands run, so they do not catch
  incorrect counts, argument parsing regressions, or destructive `rmdir -I`
  behavior.
