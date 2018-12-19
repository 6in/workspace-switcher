import docopt
import wspkg/main

let doc = """
ws.

Usage:
  ws init
  ws list
  ws shell <profile> [<args>]
  ws exec  <profile> <command> [<args>]
  ws edit  <profile>
  ws new   <profile> 
  ws show  [<envnames>...]
  ws test  <profile>
  ws (-h | --help)
  ws --version

Options:
  init          create .workspaces folder.
  list          show profiles in .workspaces forlder.
  shell         open terminal with profile.
  exec          execute application with profile.
  edit          edit a profile with editor.
  new           create a new prilfe on (HOME)/.workspaces.
  show          show current environments.
  test          symulate profile's environments.
  <profile>     profile name(without .yml)    
  <args>        execute application's arguments.
  <envnames...> show multiple variables
  -h --help     Show this screen.
  --version     Show version. 
"""

# 引数チェック
when isMainModule:
  let args = docopt(doc, version = "ws 0.1.1")
  quit(main(args))
