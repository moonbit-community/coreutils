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
  let col = if args.length() > 0 { args.join(" ") } else { "y" }
  for ;; {
    println(col)
  }
}
