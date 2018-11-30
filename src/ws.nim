import docopt
import wspkg/main

let doc = """
ws.

Usage:
  ws init
  ws list
  ws shell <profile>
  ws exec  <profile> <command> [<args>]
  ws show [<envname>]
  ws (-h | --help)
  ws --version

Options:
  init          create .workspaces folder.
  list          show profiles in .workspaces forlder.
  shell         open terminal with profile.
  exec          execute application with profile.
  <profile>     profile name(without .yml)    
  <args>        execute application's arguments.
  -h --help     Show this screen.
  --version     Show version. 
"""

# 引数チェック
when isMainModule:
  let args = docopt(doc, version = "ws 0.1.1")
  quit(main(args))
