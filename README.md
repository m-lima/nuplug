# NuPlug
A plugin manager for Nushell

# Installation
Download and install:
```
$ git clone https://github.com/m-lima/nuplug
$ cd nuplug
$ nu install.nu
```

Add to your initialization scripts:
```
source ~/.nuplug/load.nu

nuplug load [
  some/plugin
  {
    repo: other/plugin
    run: {|t| nu init.nu}
  }
  { path: /path/to/local/plugin }
  {
    repo: "https://github.com/one_more/plugin"
    branch: patch2
    loader: main.nu
  }
]
```

# Plugin record
| Field  | Description                                                                                          | Type    | Conflicts |
|--------|------------------------------------------------------------------------------------------------------|---------|-----------|
| path   | Path to local plug-ing                                                                               | string  | repo      |
| repo   | Path to the plug-in repository. Will prepend 'https://github.com/' if path is just "user/repo"       | string  | path      |
| branch | Branch to checkout from the repository                                                               | string  |           |
| loader | Loader script for the plug-in relative to the checked out path. Defaults to "<name>.nu" or "load.nu" | string  |           |
| run    | Closure to run in the checkd out path after download                                                 | closure |           |

