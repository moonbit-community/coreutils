struct HeadOptions {
  mut file : String
  mut count : Int
  mut by_chars : Bool
}

fn min(a : Int, b : Int) -> Int {
  if a < b { a } else { b }
}

fn print_usage() -> Unit {
  println("Usage:")
  println("  head [-c number|-n number] [file...]")
  println("")
  println("Options:")
  println("  -c number show last N characters")
  println("  -n number show last N lines")
}

fn parse_number(arg : String) -> Result[Int, String] {
  try @string.parse_int(arg, base=10) catch {
    _ => Err("Invalid number format")
  } noraise {
    n =>
      if n <= 0 {
        Err("Number must be non-negative")
      } else {
        Ok(n)
      }
  }
}

fn parse_args(args : Array[String]) -> Result[HeadOptions, String] {
  if args.length() < 1 {
    return Err("No arguments provided")
  }

  let mut i = 0
  let options : HeadOptions = { file: "", count: 10, by_chars: false }
  let mut number_set = false

  while i < args.length() {
    match args[i] {
      "-c" => {
        if number_set {
          return Err("Cannot specify both -c and -n")
        }
        if i + 1 >= args.length() {
          return Err("Missing number after -c")
        }
        match parse_number(args[i + 1]) {
          Ok(n) => {
            options.count = n
            options.by_chars = true
            number_set = true
          }
          Err(e) => return Err(e)
        }
        i = i + 2
      }
      "-n" => {
        if number_set {
          return Err("Cannot specify both -c and -n")
        }
        if i + 1 >= args.length() {
          return Err("Missing number after -n")
        }
        match parse_number(args[i + 1]) {
          Ok(n) => {
            options.count = n
            number_set = true
          }
          Err(e) => return Err(e)
        }
        i = i + 2
      }
      _ => {
        if options.file != "" {
          return Err("Multiple files specified")
        }
        options.file = args[i]
        i = i + 1
      }
    }
  }

  Ok(options)
}

fn take_chars(content : String, count : Int) -> String {
  if count <= 0 {
    return ""
  }
  match content.offset_of_nth_char(count) {
    Some(end_index) => content[:end_index].to_owned()
    None => content
  }
}

fn head(file : String, by_chars : Bool, count : Int) -> Unit raise {
  let file_content = @fs.read_file_to_string(file)
  if by_chars {
    println(take_chars(file_content, count))
  } else {
    let file_lines = file_content.split("\n").to_array()
    let end_index = min(count, file_lines.length())
    for line in file_lines[:end_index] {
      println(line)
    }
  }
}

test "take_chars preserves non-BMP character boundaries" {
  let content = "a😀b"
  inspect(take_chars(content, 2), content="a😀")
  inspect(take_chars(content, 3), content="a😀b")
}

///|
fn user_args() -> Array[String] {
  let raw_args = @sys.get_cli_args()
  if raw_args.length() > 0 {
    raw_args[1:].to_owned()
  } else {
    []
  }
}

///|
fn main {
  let args = user_args()
  match parse_args(args) {
    Ok(options) => {
      let file_exists = try @fs.is_file(options.file) catch {
        _ => false
      } noraise {
        exists => exists
      }
      if file_exists {
        try head(options.file, options.by_chars, options.count) catch {
          _ => {
              println("Error: failed to read " + options.file)
              println("")
              print_usage()
            }
        } noraise {
          _ => ()
        }
      } else {
          println("Error: " + options.file + " does not exist")
          println("")
          print_usage()
      }
    }
    Err(e) => {
      println("Error: " + e)
      println("")
      print_usage()
    }
  }
}
