///|
struct RmdirConfig {
  ignore_fail_on_non_empty : Bool
  parents : Bool
  verbose : Bool
}

///|
fn strip_trailing_slashes(dir : String) -> String {
  let mut end = dir.length()
  while end > 0 && dir[end - 1] == '/' {
    end = end - 1
  }
  dir[:end].to_owned()
}

///|
fn parent_dir(dir : String) -> String? {
  let dir = strip_trailing_slashes(dir)
  let parts = dir.split("/").to_array()
  if parts.length() == 1 {
    None
  } else {
    Some(parts[:parts.length() - 1].join("/"))
  }
}

///|
fn rmdir(config : RmdirConfig, file : String) -> Unit {
  if !@fs.path_exists(file) {
    println("rmdir: failed to remove '" + file + "': No such file or directory")
    return
  }

  let is_dir = try @fs.is_dir(file) catch {
    _ => {
      println("rmdir: failed to remove '" + file + "': unknown error")
      return
    }
  } noraise {
    flag => flag
  }
  if !is_dir {
    println("rmdir: failed to remove '" + file + "': Not a directory")
    return
  }

  let files_in_dir = try @fs.read_dir(file) catch {
    _ => {
      println("rmdir: failed to read directory '" + file + "': unknown error")
      return
    }
  } noraise {
    list => list
  }

  if files_in_dir.length() > 0 && !config.ignore_fail_on_non_empty {
    println("rmdir: failed to remove '" + file + "': Directory not empty")
    return
  }

  try @fs.remove_dir(file) catch {
    _ => println("rmdir: failed to remove '" + file + "': unknown error")
  } noraise {
    _ => {
      if config.verbose {
        println("rmdir: removed directory '" + file + "'")
      }
      if config.parents {
        match parent_dir(file) {
          Some(parent) => rmdir(config, parent)
          None => ()
        }
      }
    }
  }
}

///|
fn rmdir_command() -> @argparse.Command {
  @argparse.Command(
    "rmdir",
    about="Remove the DIRECTORY(ies), if they are empty.",
    version="rmdir 0.1.0",
    flags=[
      @argparse.FlagArg(
        "ignore-fail-on-non-empty",
        short='I',
        about="ignore each failure that is solely because a directory is non-empty",
      ),
      @argparse.FlagArg(
        "parents",
        short='p',
        about="remove DIRECTORY and its ancestors",
      ),
      @argparse.FlagArg(
        "verbose",
        short='V',
        about="output a diagnostic for every directory processed",
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
        "directory",
        about="DIRECTORY",
        num_args=@argparse.ValueRange(lower=1),
      ),
    ],
    arg_required_else_help=true,
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
  let cmd = rmdir_command()
  let matches = try cmd.parse() catch {
    err => {
      println(err.to_string())
      return
    }
  } noraise {
    matches => matches
  }

  let config = {
    ignore_fail_on_non_empty: flag_is_set(matches, "ignore-fail-on-non-empty"),
    parents: flag_is_set(matches, "parents"),
    verbose: flag_is_set(matches, "verbose"),
  }
  for file in positional_values(matches, "directory") {
    rmdir(config, file)
  }
}
