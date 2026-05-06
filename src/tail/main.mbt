///|
struct TailOptions {
  mut file : String
  mut follow : Bool
  mut reverse : Bool
  mut count : Int
  mut by_chars : Bool
}

///|
fn max(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn print_usage() -> Unit {
  println("Usage:")
  println("  tail [-f] [-c number|-n number] [file]")
  println("  tail -r [-n number] [file]")
  println("")
  println("Options:")
  println("  -f        follow mode, output appended data as the file grows")
  println("  -c number show last N characters")
  println("  -n number show last N lines")
  println("  -r        reverse output")
}

///|
fn parse_number(arg : String) -> Result[Int, String] {
  try @string.parse_int(arg, base=10) catch {
    _ => Err("Invalid number format")
  } noraise {
    n => if n <= 0 { Err("Number must be non-negative") } else { Ok(n) }
  }
}

///|
fn parse_args(args : Array[String]) -> Result[TailOptions, String] {
  if args.length() < 1 {
    return Err("No arguments provided")
  }

  let mut i = 0
  let options : TailOptions = {
    file: "",
    follow: false,
    reverse: false,
    count: 10,
    by_chars: false,
  }
  let mut number_set = false

  if args[0] == "-r" {
    options.reverse = true
    i = i + 1
    while i < args.length() {
      match args[i] {
        "-n" => {
          if number_set {
            return Err("Cannot specify number multiple times")
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
  } else {
    while i < args.length() {
      match args[i] {
        "-f" => {
          options.follow = true
          i = i + 1
          return Err("Follow operation not supported yet")
        }
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
  }

  Ok(options)
}

///|
fn reverse_string(content : String) -> String {
  content.to_array().rev().map(ch => ch.to_string()).join("")
}

///|
fn take_last_chars(content : String, count : Int) -> String {
  if count <= 0 {
    return ""
  }
  match content.offset_of_nth_char(-count) {
    Some(start_index) => content[start_index:].to_owned()
    None => content
  }
}

///|
fn tail(
  file : String,
  reverse : Bool,
  by_chars : Bool,
  count : Int,
  follow : Bool,
) -> Unit raise {
  let file_content = @fs.read_file_to_string(file)
  if by_chars {
    let content_slice = take_last_chars(file_content, count)
    if reverse {
      println(reverse_string(content_slice))
    } else {
      println(content_slice)
    }
  } else {
    let file_lines = file_content.split("\n").to_array()
    let start_index = max(0, file_lines.length() - count)
    let content_slice = file_lines[start_index:]
    if reverse {
      for line in content_slice.rev() {
        println(line)
      }
    } else {
      for line in content_slice {
        println(line)
      }
    }
  }
  ignore(follow)
}

///|
test "take_last_chars preserves non-BMP character boundaries" {
  let content = "a😀b"
  inspect(take_last_chars(content, 2), content="😀b")
  inspect(take_last_chars(content, 3), content="a😀b")
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
        try
          tail(
            options.file,
            options.reverse,
            options.by_chars,
            options.count,
            options.follow,
          )
        catch {
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
