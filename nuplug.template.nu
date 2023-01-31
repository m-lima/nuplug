module nuplug {
  export def load [plugins: list] {
    if (__NUPLUG_GIT__ | path exists) {
      return
    }

    mkdir (__NUPLUG_GIT__)
    nu ([__NUPLUG_BASE__ install.nu] | path join)

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
    | save --raw --append __NUPLUG_LOADER__

    print 'Plugins have been loaded. Restart nushell to take effect'
  }

  export def reset [] {
    rm -rf __NUPLUG_GIT__
    mkdir __NUPLUG_GIT__
  }

  export def update [
    --self(-s): bool # Update nuplug itself
  ] {
    if $self {
      cd __NUPLUG_BASE__
      git pull
    } else if (__NUPLUG_GIT__ | path exists) {
      ls __NUPLUG_GIT__
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
    let dir = ([__NUPLUG_GIT__ $name] | path join)

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
}

use nuplug
