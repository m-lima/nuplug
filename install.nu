let base = ([$nu.home-path .nuplug] | path join)
let git = ([$base git] | path join)
let loader = ([$base load.nu] | path join)
mkdir $base
open ([$env.FILE_PWD nuplug.template.nu] | path join)
| str replace --all '__NUPLUG_BASE__' $"'($env.FILE_PWD)'"
| str replace --all '__NUPLUG_GIT__' $"'($git)'"
| str replace --all '__NUPLUG_LOADER__' $"'($loader)'"
| save --force $loader
