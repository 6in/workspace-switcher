
import private/main_impl
import docopt

import os
import osproc
import strtabs
import strutils
import nre
import strformat

when defined(windows):
  proc c_setenv(envstr: cstring): cint {.
    importc: "putenv", header: "<stdlib.h>".}

when defined(macosx):
  proc c_setenv(envstr: cstring): cint {.
    importc: "putenv", header: "<stdlib.h>".}    

proc editProfile(path: string, env: StringTableRef ) : int = 
    # プロファイルを読み出し
    let newEnv = readProfile( path & ".yml", env)
    let editor = env["WORKSPACE_EDITOR"]

    let process : Process = startProcess(
        editor, 
        "", 
        @[getProfilePath(path & ".yml")], 
        newEnv, 
        {poStdErrToStdOut, poInteractive}
    )
    process.close

proc main*(args:Table[string,Value]) : int =
  result = 0

  # echo "args=>",args
  var env = getCurrentEnv()

  if args["init"] :
    result = createWorkspacesForlder()
    return

  if args["list"] :
    result = showProfiles()

  if args["shell"] or args["exec"]:
    let path = $args["<profile>"] 
    env["WORKSPACE_NAME"] = path
    env["DEFAULT_PATH"] = os.getEnv("Path","") & PathSep & os.getEnv("PATH","")

    # プロファイルを読み出し
    env = readProfile( path & ".yml",env)
    env = env.remove(@["DEFAULT_PATH"])
    var ws_path = ""
    if env.hasKey("Path"): 
      ws_path = env["Path"]
    elif env.hasKey("PATH"):
      ws_path = env["PATH"]

    env["WORKSPACE_PATH"] = ws_path

    var exec_path = ""
    var arguments : seq[string] = @[]

    if args["shell"] :
      if env.hasKey("WORKSPACE_SHELL"):
        exec_path = env["WORKSPACE_SHELL"]
      if env.hasKey("WORKSPACE_SHELL_ARGS") :
        arguments = ($env["WORKSPACE_SHELL_ARGS"]).split(re"\s+")

    if args["exec"] :
      exec_path = $args["<command>"]
      if args["<args>"].kind == vkStr :
        arguments = (" " & $args["<args>"]).split(re"\s+")
    
    when defined(windows):
      if exec_path.toLower.startsWith("start") :
        for item in env.pairs:
          # echo fmt"{item.key}={item.value}"
          discard c_setenv(item.key & "=" & item.value)
        result = os.execShellCmd(exec_path & " " & arguments.join(" "))
        return

    when defined(macosx):
      if exec_path.toLower.startsWith("open") :
        for item in env.pairs:
          # echo $item
          discard c_setenv(item.key & "=" & item.value)
        result = os.execShellCmd(exec_path & " " & arguments.join(" ") & " " & os.getCurrentDir())
        return

    echo exec_path & " " & $arguments.join(" ")

    let process : Process = startProcess(
        exec_path, 
        "", 
        arguments, 
        env, 
        {poStdErrToStdOut, poInteractive}
      )
    # result = process.waitForExit(-1)
    process.close

  if args["show"] :
    var envNames: seq[string] = @[] 
    let v: Value = args["<envnames>"]
    for item in v.items:
      # echo $item
      envNames.add $item

    let allShow = envNames.len == 0

    echo "include:"
    echo "  - base"
    echo "env:"
    for item in os.envPairs():
      let key = item.key
      let val = item.value

      if allShow == false and envNames.find(key) == -1 :
        continue

      if val.find($PathSep) >= 0:
        echo "  " & key & ":"
        for p in val.split($PathSep):
          if p != "":
            echo "    - " & p
      else:
        if key != "":
          echo "  " & key & ": " & val

  if args["edit"] :
    let profile = $args["<profile>"] 
    result = editProfile( profile, env )

  if args["new"]: 
    let path = $args["<profile>"] 
    let newPath = getProfilePath(path & ".yml", false)

    if newPath.existsFile == false :
      let f = open(newPath, FileMode.fmWrite)
      when defined(windows):
        let pathName = "Path"
        let crlf = "\r\n"
      else: 
        let pathName = "PATH"
        let crlf = "\n"

      f.write fmt"""include:{crlf}  - base{crlf}env:{crlf}  {pathName}:{crlf}"""

      for p in env[pathName].split($PathSep):
        if p != "" :
          f.write fmt"    - {p}{crlf}" 
      f.close

    if newPath.existsFile :
      echo fmt"{newPath} was created."
      # プロファイルの編集
      result = editProfile(path,env)
