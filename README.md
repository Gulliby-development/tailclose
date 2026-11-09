<p align="center"><img src="docs/logo.svg" width="96" alt="" /></p>

# tailclose

[![CI](https://github.com/Gulliby-development/tailclose/actions/workflows/ci.yml/badge.svg)](https://github.com/Gulliby-development/tailclose/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

tailclose finishes a beginning of a JSON document cut off at any byte. It can
show the repaired document or just its suffix, report the location and parser
state at the cut, and check whether the input is complete, partial, or invalid.
It is intended for people building agents, tool-call runners, and evaluation
harnesses. It makes no model calls and needs no network.

The application uses only the Lua 5.4 standard library and runs on Windows,
macOS, and Linux. From the repository directory, invoke it with
`lua bin/tailclose COMMAND`. The examples below assume this POSIX-shell
function is defined:

```sh
tailclose() { lua bin/tailclose "$@"; }
```

## Commands

```text
usage: tailclose close [--fill VALUE]
       tailclose suffix [--fill VALUE]
       tailclose path
       tailclose where
       tailclose check
```

All five commands read their input from standard input. `close` prints the
shown input followed by its repair; `suffix` prints only the repair. Both
accept an optional `--fill VALUE`, which must be exactly one of `null`, `0`,
`""`, `false`, `[]`, or `{}`. The default is `null`. A fill value is used
where a missing value is needed; the zero used to finish an incomplete number
is unaffected by fill.

`path` reports the current location, `where` reports the parser's end state,
and `check` reports whether the input is complete or how many suffix bytes
would complete it. `check` uses `null` as its fill.

The first command-line word `help`, `-h`, or `--help` prints the synopsis;
`--version` prints `tailclose 0.1.0`. Either short-circuits any later words.
With no command, usage is printed to standard error. An unknown first word
reports `tailclose: unknown command WORD`. After a command, arguments are
checked left to right: a positional word, empty word, or `-` reports
`tailclose: unexpected argument WORD`; an unsupported option, or `--fill` on
`path`, `where`, or `check`, reports `tailclose: unknown option WORD`.
For eligible commands `--fill` consumes the next word even if it begins with
a hyphen. A repeated option reports `tailclose: given twice: --fill`; an option
without a following word reports `tailclose: missing value for --fill`; an
unaccepted value reports `tailclose: bad value for --fill`. The first
applicable error wins.

The program reads standard input only for a valid invocation of one of the
five commands. Help, version, missing or unknown commands, and invalid
arguments do not read it.

## Input grammar and limits

Input is a byte string containing the beginning of one JSON document, following
RFC 8259 syntax. Whitespace is space, tab, LF, or CR. Values are objects,
arrays, strings, numbers, `true`, `false`, and `null`; object keys are
strings, members and array values are comma-separated, and trailing commas are
not allowed. After the root value only whitespace may appear.

A number follows
`-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?`. Strings reject bytes
below 0x20 except through valid escapes. A backslash must be followed by one of
`"`, `\\`, `/`, `b`, `f`, `n`, `r`, `t`, or `u` and four hexadecimal
digits. Bytes 0x80 and above stand for themselves: tailclose does not validate
UTF-8 or Unicode surrogate pairs.

Input is limited to 100 bytes, and at most eight arrays or objects may be open
at once. Length is checked before syntax, so oversized input is reported before
any syntax error it might also contain. Exactly 100 bytes is permitted. After
that check, scanning proceeds from left to right. An invalid-JSON offset marks
the first byte that no continuation can make part of valid JSON; this also
identifies the offending continuation in malformed numbers, literals, and
string escapes. If an opening brace or bracket would create a ninth open
container, the depth error points to that opening byte. An empty input or
whitespace-only input is a valid beginning.

## End state

`where` returns one of these words:

- `start`: no value has begun (including empty or whitespace-only input).
- `done`: the root value is complete and only whitespace follows.
- `open`: just after an opening brace or bracket, with only whitespace since.
- `key`: inside an object key before its closing quote.
- `colon`: a key is complete but its colon has not appeared.
- `value`: a value is expected after a colon or an array comma.
- `string`: inside a string value.
- `number`: inside or immediately after a number token. At end of input, even
  a syntactically complete number is considered a possible prefix of a longer
  number.
- `literal`: inside `true`, `false`, or `null` before its final letter.
- `after`: a value inside an array or object is complete; a comma or closing
  delimiter is expected.
- `member`: just after an object comma, where a key is expected.

A literal is complete as soon as its final letter arrives. A number becomes
unambiguously complete when a following byte is not part of the number.

## Repair and display

The repair depends on the end state, then appends one closer for each open
container, innermost first (`}` for an object, `]` for an array):

- `start` and `value` use the fill value.
- `member` adds an empty key, a colon, and the fill value.
- `colon` adds a colon and the fill value.
- `key` finishes any unfinished escape, closes the key, adds a colon, and
  adds the fill value.
- `string` finishes any unfinished escape and closes the quote.
- `number` adds `0` if the token ends with `-`, `.`, `e`, `E`, or an
  exponent sign; a whole number needs no repair.
- `literal` adds the remaining letters of the literal.
- `open`, `after`, and `done` need no repair before the closers.

An input ending in a backslash is completed with a backslash escape. An input
ending in `\\u` plus zero to three hexadecimal digits gets enough zero digits
to complete the four-digit escape. Other unfinished escapes need no extra
escape bytes. Fill bytes do not count toward the nesting limit.

Displayed text is ASCII: backslashes are doubled; LF, CR, and tab are shown as
`\n`, `\r`, and `\t`; other bytes below 0x20 or above 0x7e are shown as
`\x` followed by two lowercase hexadecimal digits. Other bytes are shown
directly. Thus the input shown by `close` also displays JSON escape
backslashes doubled. `close` and `suffix` end their output with LF; an empty
suffix therefore prints a blank line.

`path` begins with `$` and adds a part for each open container, outermost
first. An array contributes `[I]`, where I is its number of commas read. An
object contributes no part until the current key's closing quote has been read.
A completed raw key matching an ASCII identifier (letters, digits, or
underscores, not beginning with a digit) is shown as `.KEY`; other keys are
shown as `["KEY"]`, with KEY kept as written in the JSON rather than decoded.
A comma clears the current object key. Outside all containers, the path is
`$`.

`check` prints either `complete` or `partial N`, where N is the byte length
of the suffix using the default `null` fill, followed by `depth D bytes B`.
D is the number of open containers and B is the input byte count.

## Errors and exit status

Successful commands exit 0 and write their result to standard output without
writing to standard error. Command-line errors exit 2 and print one
`tailclose: MESSAGE` line to standard error. Invalid input for `close`,
`suffix`, `path`, or `where` exits 1 and prints the same error form to
standard error. Syntax errors use
`invalid JSON at byte OFFSET: unexpected byte 0xHH`, where OFFSET is
zero-based and HH is lowercase hexadecimal. An over-limit nesting error is
`invalid JSON at byte OFFSET: nesting too deep (max 8)`; oversized input is
`input is too long (max 100 bytes)`.

For invalid JSON, `check` instead exits 1 and prints
`invalid at byte OFFSET: REASON` to standard output, without a stderr message.
An oversized input to `check` remains an input error on standard error and
exits 1. Thus exit statuses are 0 for success, 2 for command-line errors, and
1 for input errors or `check` finding invalid JSON.

## Library and development

The library interface is stream-free: `cli.run(args, input)` returns a reply
table with `status`, `out`, and `err`; `cli.reads_stdin(args)` is true only
for a valid command invocation. A registry handler receives
`handler(options, input)`; `options.fill` is present only when supplied.
Handlers return reply tables, or throw a table containing `status` and
`message`; the CLI converts that to an empty stdout reply and a
`tailclose: MESSAGE` stderr line. Only `bin/tailclose` reads and writes
streams.

Run the checks from the repository directory:

```text
stylua --check .
luacheck .
busted
```

These are development tools; the application itself requires only Lua 5.4 and
its standard library. On Windows the C library may translate CR LF input to LF
and LF output to CR LF. The program does not undo this translation; calls to
`cli.run` operate on exact strings and its tests are cross-platform.

## Examples

```text
$ printf '{"user":{"name":"Ann","tags":["a",' | tailclose close
{"user":{"name":"Ann","tags":["a",null]}}
$ printf '["tail\\' | tailclose suffix; printf '{"a":' | tailclose close --fill '""'
\\"]\n
{"a":""}
$ printf '{"items":[1,2,{"name":"x' | tailclose path; printf '{"items":[1,2,{"name":"x' | tailclose where
$.items[2].name
string
$ printf '[1,]' | tailclose check; printf '[1,2,{"a":tr' | tailclose check
invalid at byte 3: unexpected byte 0x5d
partial 4
depth 2 bytes 12
```

See the [MIT License](LICENSE).

---

Built with [BAKED](https://github.com/Gulliby-development/baked), an open-source coding agent (bench round R92).
