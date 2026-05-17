///|
fn char_from_int(val : Int) -> Char? = "%char_from_int"

///|
pub fn read_char() -> Char? {
  char_from_int(__read_char())
}

///|
pub fn read_line_from_stdin() -> String? {
  let buf = @buffer.new()
  while true {
    match read_char() {
      None =>
        match buf.to_string() {
          "" => return None
          s => return Some(s)
        }
      Some('\n') => {
        buf.write_char('\n')
        break
      }
      Some(c) => buf.write_char(c)
    }
  }
  Some(buf.to_string())
}

///|
struct Stats {
  lines : Int?
  words : Int?
  characters : Int?
  bytes : Int?
  max_line_length : Int?
}

///|
fn Stats::to_strings(self : Stats) -> Array[String] {
  [self.lines, self.words, self.characters, self.bytes, self.max_line_length]
  .iter()
  .map(fn(x) {
    match x {
      Some(n) => n.to_string()
      None => ""
    }
  })
  .to_array()
}

///|
fn Stats::to_string(self : Stats) -> String {
  self.to_strings().filter(x => x.length() > 0).join(" ")
}

///|
fn print_stats(
  list : @queue.Queue[(Stats, String)],
  total_stats : Stats,
) -> Unit {
  if list.is_empty() {
    println("wc: print stats error: list is empty")
    return
  }

  let fix_length = [
    match total_stats.lines {
      None => 0
      Some(x) => x.to_string().length()
    },
    match total_stats.words {
      None => 0
      Some(x) => x.to_string().length()
    },
    match total_stats.characters {
      None => 0
      Some(x) => x.to_string().length()
    },
    match total_stats.bytes {
      None => 0
      Some(x) => x.to_string().length()
    },
    match total_stats.max_line_length {
      None => 0
      Some(x) => x.to_string().length()
    },
  ]

  list.each(fn(item : (Stats, String)) {
    let (stats, file) = item
    let strings = stats.to_strings()
    let output : @queue.Queue[String] = @queue.Queue([])
    let mut i = 0
    while i < fix_length.length() {
      if fix_length[i] > 0 && strings[i].length() > 0 {
        let whitespace = fix_length[i] + 1 - strings[i].length()
        let mut j = 0
        while j < whitespace {
          output.push(" ")
          j = j + 1
        }
        output.push(strings[i])
      }
      i = i + 1
    }
    output.push(" ")
    output.push(file)
    println(output.iter().to_array().join(""))
  })
}

///|
fn Stats::add(self : Stats, other : Stats) -> Stats {
  fn option_add(x : Int?, y : Int?) -> Int? {
    match (x, y) {
      (None, _) => y
      (_, None) => x
      (Some(a), Some(b)) => Some(a + b)
    }
  }

  fn option_max(x : Int?, y : Int?) -> Int? {
    match (x, y) {
      (None, _) => y
      (_, None) => x
      (Some(a), Some(b)) => Some(if a > b { a } else { b })
    }
  }

  {
    lines: option_add(self.lines, other.lines),
    words: option_add(self.words, other.words),
    characters: option_add(self.characters, other.characters),
    bytes: option_add(self.bytes, other.bytes),
    max_line_length: option_max(self.max_line_length, other.max_line_length),
  }
}

///|
fn word_count(
  content : String,
  file_bytes : Bytes?,
  line~ : Bool,
  word~ : Bool,
  char~ : Bool,
  byte~ : Bool,
  max_line_length~ : Bool,
) -> Stats {
  let lines = if line { Some(content.split("\n").count()) } else { None }
  let words = if word {
    Some(
      content
      .replace_all(old="\n", new=" ")
      .split(" ")
      .filter(s => s.length() > 0)
      .count(),
    )
  } else {
    None
  }
  let characters = if char { Some(content.length()) } else { None }
  let bytes = if byte {
    match file_bytes {
      Some(bytes) => Some(bytes.length())
      None => Some(@utf8.encode(content).length())
    }
  } else {
    None
  }
  let max_line_length = if max_line_length {
    Some(
      content
      .split("\n")
      .map(line => line.length())
      .fold(fn(a : Int, b : Int) { if a > b { a } else { b } }, init=0),
    )
  } else {
    None
  }
  { lines, words, characters, bytes, max_line_length }
}

///|
fn count_file(
  file : String,
  line : Bool,
  word : Bool,
  char_count : Bool,
  byte : Bool,
  max_line_length : Bool,
) -> Stats? {
  if !@fs.path_exists(file) {
    println("wc: \{file}: No such file or directory")
    return None
  }

  let content = try @fs.read_file_to_string(file) catch {
    _ => {
      println("wc: \{file}: meet a error when read file")
      return None
    }
  } noraise {
    s => s
  }

  let bytes = if byte {
    try @fs.read_file_to_bytes(file) catch {
      _ => {
        println("wc: \{file}: meet a error when read file")
        return None
      }
    } noraise {
      s => Some(s)
    }
  } else {
    None
  }

  Some(
    word_count(
      content,
      bytes,
      line~,
      word~,
      char=char_count,
      byte~,
      max_line_length~,
    ),
  )
}

///|
fn wc_command() -> @argparse.Command {
  @argparse.Command(
    "wc",
    about="Print newline, word, and byte counts for each FILE, and a total line if more than one FILE is specified.",
    version="wc 0.1.0",
    flags=[
      @argparse.FlagArg("lines", short='l', about="print the newline counts"),
      @argparse.FlagArg("words", short='w', about="print the word counts"),
      @argparse.FlagArg("chars", short='m', about="print the character counts"),
      @argparse.FlagArg("bytes", short='c', about="print the byte counts"),
      @argparse.FlagArg(
        "max-line-length",
        short='L',
        about="print the maximum display width",
      ),
      @argparse.FlagArg(
        "version",
        short='v',
        long="version",
        about="output version information and exit",
        action=@argparse.Version,
      ),
    ],
    positionals=[
      @argparse.PositionArg(
        "file",
        about="FILE",
        num_args=@argparse.ValueRange(lower=0),
      ),
    ],
    disable_version_flag=true,
  )
}

///|
fn flag_is_set(matches : @argparse.Matches, name : String) -> Bool {
  matches.flags.get(name).unwrap_or(false)
}

///|
fn positional_values(
  matches : @argparse.Matches,
  name : String,
) -> Array[String] {
  match matches.values.get(name) {
    Some(values) => values
    None => []
  }
}

///|
fn main {
  let cmd = wc_command()
  let matches = try cmd.parse() catch {
    err => {
      println(err.to_string())
      return
    }
  } noraise {
    matches => matches
  }

  let files = positional_values(matches, "file")
  let char_count = flag_is_set(matches, "chars")
  let max_line_length = flag_is_set(matches, "max-line-length")
  let mut line = flag_is_set(matches, "lines")
  let mut word = flag_is_set(matches, "words")
  let mut byte = flag_is_set(matches, "bytes")

  if !(line || word || byte || char_count || max_line_length) {
    line = true
    word = true
    byte = true
  }

  if files.is_empty() {
    let lines : @queue.Queue[String] = @queue.Queue([])
    while true {
      match read_line_from_stdin() {
        None => break
        Some(line) => lines.push(line)
      }
    }
    let content = lines.iter().to_array().join("")
    let stats = word_count(
      content,
      if byte {
        Some(@utf8.encode(content))
      } else {
        None
      },
      line~,
      word~,
      char=char_count,
      byte~,
      max_line_length~,
    )
    println("  \{stats.to_string()}")
  } else {
    let mut total_stats = {
      lines: if line {
        Some(0)
      } else {
        None
      },
      words: if word {
        Some(0)
      } else {
        None
      },
      bytes: if byte {
        Some(0)
      } else {
        None
      },
      characters: if char_count {
        Some(0)
      } else {
        None
      },
      max_line_length: if max_line_length {
        Some(0)
      } else {
        None
      },
    }
    let list : @queue.Queue[(Stats, String)] = @queue.Queue([])
    for file in files {
      match count_file(file, line, word, char_count, byte, max_line_length) {
        Some(stats) => {
          total_stats = total_stats.add(stats)
          list.push((stats, file))
        }
        None => ()
      }
    }

    if list.length() == 1 {
      match list.pop() {
        Some((stat, file)) => println(" \{stat.to_string()} \{file}")
        None => ()
      }
    } else {
      list.push((total_stats, "total"))
      print_stats(list, total_stats)
    }
  }
}
