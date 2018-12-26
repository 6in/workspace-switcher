import docopt
import wspkg/main
# import version

include nimble_config
include ../ws.nimble

let doc = """
workspace switcher.

Usage:
  ws init
  ws list
  ws new   <profile> 
  ws edit  <profile>
  ws show  [<envnames>...]
  ws shell [--no-inherit] <profile> [<kvargs>...]
  ws exec  [--no-inherit] <profile> <commands>...
  ws test  [--no-inherit] <profile> [<kvargs>...]
  ws (-h | --help)
  ws (-v | --version)

Options:
  init          create .workspaces folder.
  list          show profiles in .workspaces forlder.
  new           create a new prilfe on (HOME)/.workspaces.
  edit          edit a profile with editor.
  show          show current environments.
  shell         open terminal with profile.
  test          export environments profile.
  exec          execute application with profile.
  --no-inherit  not inherit from current environments only yaml environments.
  <profile>     profile name(without .yml)
  <commands>... exec parameters.    
  <kvargs>...   key,value Parameters.
  <args>        execute application's arguments.
  <envnames...> show multiple variables
  -h --help     Show this screen.
  -v --version  Show version. 
"""

# 引数チェック
when isMainModule:  
  let args = docopt(doc, version = "ws " & version)
  quit(main(args))
