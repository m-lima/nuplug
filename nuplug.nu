export-env {
  let dir = ([$nu.home-path .local share nuplug] | path join)
  mkdir $dir
  touch ([$dir load.nu] | path join)
  $env.FILE_PWD | save --force ([$dir REPO] | path join)
}

export def load [plugins: list] {
  if (plug_dir git | path exists) {
    return
  }

  mkdir (plug_dir git)

  $plugins
  | each {|t i|
      let span = (metadata $t).span;
      let description = ($t | describe);
      if $description == 'string' {
        handle_repo { repo: $t } $i $span
      } else if $description =~ 'record.*' {
        if 'path' in $t and 'record' in $t {
          make_err 'Cannot have "path" and "repo" fields simultaneously' $span
        } else if 'path' in $t {
          handle_path $t.path $span
        } else if 'repo' in $t {
          handle_repo $t $i $span
        } else {
          make_err 'Expected mandatory field "repo" or "path"' $span
        }
      } else {
        make_err 'Expected a record or string' $span
      }
    }
  | str join (char newline)
  | save --force (plug_dir load.nu)
}

export def reset [] {
  rm -rf (plug_dir)
  mkdir (plug_dir)
  touch (plug_dir load.nu)
}

export def update [
  --self(-s): bool # Update nuplug itself
] {
  if $self {
    let repo = (cat (plug_dir REPO))
    cd $repo
    git pull
  } else {
    if (plug_dir git | path exists) {
      return
    }

    ls (plug_dir git)
    | get name
    | each {|t|
        cd $t
        git pull
      }
  }
}

def make_err [msg: string, span: record] {
  error make {
    msg: 'Invalid plugin'
    label: {
      text: $msg
      start: $span.start
      end: $span.end
    }
  }
}

def plug_dir [...parts: string] {
  [$nu.home-path .local share nuplug] | append $parts | path join
}

def handle_path [path: string, span: record] {
  let path = ($path | path expand)

  if ($path | path type) == 'file' {
    'source ' + $path
  } else {
    make_err 'Path does not point to a file' $span
  }
}

def handle_repo [plugin: record, idx: number, span: record] {
  let columns = ($plugin | columns | filter {|t| $t != repo and $t != branch and $t != run and $t != loader})
  if ($columns | length) != 0 {
    make_err ('Unrecognized columns: ' + $columns | (str join ', ')) $span
  }

  let url = if ($plugin.repo | str contains ':') {
    $plugin.repo
  } else {
    'https://github.com/' + $plugin.repo
  }

  let name = ($url | parse -r '^.*:.*?(?<name>[^/]+)$' | first | get name) + ($idx | into string)
  let dir = (plug_dir git $name)

  let branch = if 'branch' in $plugin {
    do -c { git clone -b $plugin.branch $url $dir }
  } else {
    do -c { git clone $url $dir }
  }

  if 'run' in $plugin {
    do {
      cd $dir
      do $plugin.run
    }
  }

  let loader = if 'loader' in $plugin {
    let loader = ([$dir $plugin.loader] | path join)
    if ($loader | path type) == 'file' {
      $loader
    } else {
      make_err 'Loader does not point to a file' $span
    }
  } else {
    let loader = ([$dir ($name + '.nu')] | path join)
    if ($loader | path type) == 'file' {
      $loader
    } else {
      let loader = ([$dir 'load.nu'] | path join)
      if ($loader | path type) == 'file' {
        $loader
      } else {
        make_err 'Plugin has no loader script' $span
      }
    }
  }

  'source ' + $loader
}
