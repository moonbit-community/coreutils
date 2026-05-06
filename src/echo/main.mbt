///|
fn parse_special_char(s : String) -> String {
  let chars = s.to_array()
  let mut result = ""
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '\\' {
      if i + 1 >= chars.length() {
        result = result + "\\"
        break
      }
      match chars[i + 1] {
        'a' => {
          result = result + "\u0007"
          i = i + 2
        }
        'b' => {
          result = result + "\u0008"
          i = i + 2
        }
        'c' => break
        'f' => {
          result = result + "\u000C"
          i = i + 2
        }
        'n' => {
          result = result + "\u000A"
          i = i + 2
        }
        'r' => {
          result = result + "\u000D"
          i = i + 2
        }
        't' => {
          result = result + "\u0009"
          i = i + 2
        }
        'v' => {
          result = result + "\u000B"
          i = i + 2
        }
        '\\' => {
          result = result + "\\"
          i = i + 2
        }
        '0' => {
          let mut octal_num = ""
          let mut j = i + 2
          while j < chars.length() &&
                j < i + 5 &&
                chars[j] >= '0' &&
                chars[j] <= '7' {
            octal_num = octal_num + chars[j].to_string()
            j = j + 1
          }
          if octal_num.length() > 0 {
            try @string.parse_int(octal_num, base=8) catch {
              _ => result = result + "\\0" + octal_num
            } noraise {
              dec_val =>
                match dec_val.to_char() {
                  Some(ch) => result = result + ch.to_string()
                  None => result = result + "\\0" + octal_num
                }
            }
            i = j
          } else {
            result = result + "\\0"
            i = i + 2
          }
        }
        _ => {
          result = result + "\\" + chars[i + 1].to_string()
          i = i + 2
        }
      }
    } else {
      result = result + chars[i].to_string()
      i = i + 1
    }
  }
  result
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
  let parsed : Array[String] = []
  for arg in args {
    parsed.push(parse_special_char(arg))
  }
  println(parsed.join(" "))
}
