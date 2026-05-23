struct CatOption {
  unbuffered: Bool
  files: Array[String]
} 
// Parse command line arguments to extract -u flag and files
fn parse_args(args: Array[String]) -> CatOption {
  let mut unbuffered = false
  let files: Array[String] = []
  let mut i = 0 // Skip program name

  while i < args.length() {
    let arg = args[i]
    if arg == "-u" {
      unbuffered = true
    } else {
      files.push(arg)
    }
    i = i + 1
  }

  return {unbuffered, files}
}

// Read from file and write to stdout
fn cat_file!(path~: String) -> Unit {
  let file_content = @fs.read_file_to_string!(path = path)
  let file_lines = file_content.split("\n").to_array()
  for line in file_lines{
    println(line)
  }
}

fn main {
  let args = @sys.get_cli_args()

  let catOption = parse_args(args)
  
  // Set unbuffered mode if requested
  if catOption.unbuffered {
    println("Unbuffered not supported yet")
    return
  }

  // If no files specified, read from stdin
  if catOption.files.length() == 0 {
    println("Reading from stdin not supported yet")
    return
  }

  // Process each file
  for file in catOption.files {
    match @fs.is_file?(path=file){
      Ok(true) => {
        let _ = cat_file?(path=file)  
      }
      _ => {
        println("File not found: " + file)  
      } 
    }
  }
}