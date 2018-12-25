import docopt
import wspkg/main
# import version

include nimble_config
include ../ws.nimble

let doc = """
ws.

Usage:
  ws init
  ws list
  ws shell <profile> [<kvargs>...]
  ws exec  <profile> <command> [<args>]
  ws edit  <profile>
  ws new   <profile> 
  ws show  [<envnames>...]
  ws test  <profile>
  ws (-h | --help)
  ws (-v | --version)

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
