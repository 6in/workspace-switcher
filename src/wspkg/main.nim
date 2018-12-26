
import private/main_impl
import docopt

import os
import osproc
import strtabs
import strutils
import nre
import strformat
import sequtils
import algorithm

# when defined(windows):
#   proc c_setenv(envstr: cstring): cint {.
#     importc: "putenv", header: "<stdlib.h>".}

# when defined(macosx):
#   proc c_setenv(envstr: cstring): cint {.
#     importc: "putenv", header: "<stdlib.h>".}    

proc editProfile(path: string, env: StringTableRef ) : int = 
    # プロファイルを読み出し
    let newEnv = readProfile( path & ".yml", env)
    let editor = env["WORKSPACE_EDITOR"]
    let profilePath = getProfilePath(path & ".yml")

    when defined(macosx) :
      discard execShellCmd(fmt"{editor} {profilePath}")

    else:
      let process : Process = startProcess(
          editor, 
          "", 
          @[profilePath], 
          newEnv, 
          {poStdErrToStdOut, poInteractive}
      )
      process.close

proc addKeyVal(env: var StringTableRef, keyvalues: seq[string]): StringTableRef =
  result = env
  let regKV = re"""(\S+)\s*=\s*(\S+)"""
  for kv in keyvalues:
    # echo $kv
    let optM = kv.match(regKV)
    if optM.isSome:
      let m = optM.get
      let k = m.captures[0]
      let v = m.captures[1]
      env[k] = v 

proc main*(args:Table[string,Value]) : int =
  result = 0
  # echo "args=>",args

  var env : StringTableRef = newStringTable()
  if args["--no-inherit"] == false: 
    echo "no-inherit"
    env = setCurrentEnv(env)

  if args["init"] :
    result = createWorkspacesForlder()
    return

  if args["list"] :
    result = showProfiles()

  if args["shell"] or args["exec"] or args["test"]:
    let path = $args["<profile>"] 
    env["WORKSPACE_NAME"] = path
    env["DEFAULT_PATH"] = os.getEnv(pathName,"")
    env["WORKSPACE_PWD"] = getCurrentDir()

    var kvArgs : seq[string] = @[]
    let valKV: Value = args["<kvargs>"]
    case valKV.kind
    of vkList:
      if valKV.len > 0 :
        kvArgs = @valKV
    of vkStr:
      kvArgs.add $valKV
    else:
      discard
    discard env.addKeyVal kvArgs

    # プロファイルを読み出し
    env = readProfile( path & ".yml",env)
    env = env.remove(@["DEFAULT_PATH"])

    env["WORKSPACE_PATH"] = env[pathName]

    var exec_path = ""
    var arguments : seq[string] = @[]

    if args["shell"] :
      if env.hasKey("WORKSPACE_SHELL"):
        exec_path = env["WORKSPACE_SHELL"]
      if env.hasKey("WORKSPACE_SHELL_ARGS") :
        arguments = ($env["WORKSPACE_SHELL_ARGS"]).split(re"\s+")

    if args["exec"] :
      # コマンドライン解析
      let commandsValue: Value = args["<commands>"]
      case commandsValue.kind
      of vkStr:
        exec_path = strip($commandsValue)
      of vkList:
        exec_path = commandsValue[0].strip
        arguments = @commandsValue[1..^1].map( proc (s:string): string = s.strip )
      else:
        discard

    if args["test"] == false: 
      when defined(windows):
        if exec_path.toLower.startsWith("start") :
          for item in env.pairs:
            # echo fmt"{item.key}={item.value}"
            # discard c_setenv(item.key & "=" & item.value)
            putEnv(item.key,item.value)
          result = os.execShellCmd(exec_path & " " & arguments.join(" "))
          return

      when defined(macosx):
        if exec_path.toLower.startsWith("open") :
          for item in env.pairs:
            # echo $item
            # discard c_setenv(item.key & "=" & item.value)
            putEnv($item.key, $item.value)
            #result = os.execShellCmd(exec_path & " " & arguments.join(" ") & " " & os.getCurrentDir())
          result = os.execShellCmd(exec_path & " " & arguments.join(" ") )
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

      f.write fmt"""include:{crlf}  - base{crlf}env:{crlf}  {pathName}:{crlf}"""

      for p in env[pathName].split($PathSep):
        if p != "" :
          f.write fmt"    - {p}{crlf}" 
      f.close

    if newPath.existsFile :
      echo fmt"{newPath} was created."
      # プロファイルの編集
      result = editProfile(path,env)

  if args["test"] :
    # let path = $args["<profile>"] 
    # env["WORKSPACE_NAME"] = path
    
    # # プロファイルを読み出し
    # env = readProfile( path & ".yml",env)

    # 環境変数のキー一覧を取得し、ソートする
    var keys : seq[string] = @[]
    for item in env.pairs:
      if item.key == "" : 
        continue
      keys.add item.key
    keys.sort( proc (x,y:string) : int = cmp(x,y) )

    # OS毎に環境変数設定を出力
    for key in keys:
      let val = env[key]
      when defined(windows) :
        echo fmt"SET {key}=""{val}"""
      else:
        echo fmt"export {key}=""{val}"""
