import os
import osproc
import strtabs

import yaml,yaml/presenter,yaml/serialization
import json,strutils,os,streams
import ospaths
import nre

when defined(windows):
  const pathName* = "Path"
  const crlf* = "\r\n"
  const USER_HOME = "USERPROFILE"
else: 
  const pathName* = "PATH"
  const crlf* = "\n"
  const USER_HOME = "HOME"

proc dump(yamlDoc:YamlDocument ,file:string, style:PresentationStyle) =
  ## Yamlをダンプ
  var s = newFileStream(file, fmWrite)
  yamlDoc.dumpDom(s, options= defineOptions(style = style) )
  s.close()

proc addAppPath* (env: StringTableRef ) : StringTableRef =
  result = env
  env[pathName] = env[pathName] & PathSep & getAppDir()

proc yaml2json(path: string) : JsonNode =
  ## Yaml to Json
  let fileStream = newFileStream(path,FileMode.fmRead)
  let yamlDoc = loadDom( fileStream )
  defer:
    fileStream.close
  # yamlをjsonに変換(TODO)
  let tempFile = os.getTempDir() / "test.json"
  yamlDoc.dump(tempFile, psJson)
  # jsonを読み込み
  result = parseFile(tempFile)
  # テンポラリファイルを削除
  tempFile.removeFile

proc mergeProfile(lhs: StringTableRef, rhs: StringTableRef): StringTableRef =
  result = lhs
  for item in rhs.pairs:
    result[item.key] = item.value

proc embedParam(env: StringTableRef, val: string ) : string = 
  ## 文字列を埋め込み
  result = val.replace( re"(\((\w+)\))", proc (m: RegexMatch) : string =
    let key = m.captures[1]
    if env.hasKey(key): 
      return env[key]
    else:
      return m.captures[0]
  )

proc remove* (env: StringTableRef, keys: openArray[string]) : StringTableRef =
  result = newStringTable()
  for item in env.pairs :
    if keys.contains(item.key) == false :
      result[item.key] = item.value  

proc getWorkspaceFolder() : string = 
  # result = getEnv(USER_HOME,"") / ".workspaces"
  result = getHomeDir() / ".workspaces"

proc getProfilePath* (path:string, checkExists: bool = true) : string =
  var root = getCurrentDir()

  # カレントディレクトリを優先
  if (root / path).existsFile :
    result = root / path
    return

  # .workspacesから取得
  root = getWorkspaceFolder()
  result = root / path

  # ファイル存在チェックが必須なら、存在チェック
  if checkExists and result.existsFile == false:
    var e: ref OSError
    new(e)
    e.msg = "file not found =>" & result
    raise e

proc readProfile*(path: string,env: StringTableRef) : StringTableRef =
  ## プロファイル読み出し
  result = env
  let yaml_file = getProfilePath(path)
  let jsonObj : JsonNode = yaml2json(yaml_file)

  if jsonObj["env"].kind != JObject :
    return

  # 別ファイル読み出し
  if jsonObj.hasKey("include") and jsonObj["include"].kind == JArray:
    for p in jsonObj["include"].items :
      let profile = readProfile( p.getStr & ".yml", result)
      # プロファイルをマージする
      result = mergeProfile(result,profile)
    
  # 環境構築を行う
  for item in jsonObj["env"].pairs:
    let key = item.key
    let val = item.val
    var val2 = ""
    if val.kind == JArray:
      var data: seq[string] = @[]
      for v in val.items:
        data.add($v.getStr)
      val2 = data.join($PathSep)
    if val.kind == JString:
      val2 = val.getStr
    result[key] = result.embedParam(val2)

proc setCurrentEnv*(env: var StringTableRef) : StringTableRef =
  result = env
  for item in envPairs():
    result[item.key] = $item.value

proc writeText(fileName:string, text: string) : bool =
  result = true

  var f : File = open(fileName ,FileMode.fmWrite)
  defer :
    close(f)
  f.writeLine text

proc getDefaultEditor* () : string =
  when defined(widows):
    result = r"start"
  when defined(macosx):
    result = "open -e "
  when defined(linux):
    result = "/usr/bin/gedit"

proc createWorkspacesForlder* () : int =
  result = 0
  var root = ""
  var yaml = ""
  var note = """# insert this text into your shell's profile at end.
# from here
if [ "$WORKSPACE_NAME" != "" ]; then
  PROMPT="${PROMPT}
(${WORKSPACE_NAME})» "
  export PATH=${WORKSPACE_PATH}
  ws test ${WORKSPACE_NAME} > /tmp/${WORKSPACE_NAME}
  source /tmp/${WORKSPACE_NAME}
fi
"""
  root = getEnv(USER_HOME,"undefined")

  # base.ymlのテンプレート
  when defined(windows):    
    yaml = "env:\r\n  WORKSPACE_SHELL: start\r\n  WORKSPACE_EDITOR: start\r\n  PROMPT: $P$_$C(WORKSPACE_NAME)$F$$$S\r\n  HOME: (USERPROFILE)"
    note = ""
  when defined(macosx):
    yaml = "env:\p  WORKSPACE_SHELL: open\p  WORKSPACE_SHELL_ARGS: -na Terminal\p  WORKSPACE_EDITOR: open -e "
  when defined(linux):
    yaml = "env:\p  WORKSPACE_SHELL: /usr/bin/gnome-terminal\p  WORKSPACE_EDITOR: xdg-open"

  if root == "undefined" :
    result = 1
    echo "env '" & USER_HOME & "' was not defined."
    echo "process was aborted."
    return

  root = root / ".workspaces"
  if root.existsDir() == false :
    root.createDir()
    echo root & " was created."

  # output base.yml
  if (root / "base.yml").existsFile == false:
    if writeText(root / "base.yml", yaml) :
      echo root / "base.yml was created."
    else:
      result = 1
      echo root / "base.yml was not created."
  
  echo note

proc showProfiles*() : int =
  var userHome = "HOME"

  when defined(windows):
    userHome = "USERPROFILE"

  let workspaces = getEnv(userHome,"undefined") / ".workspaces"
  if workspaces.existsDir == false:
    echo "folder not found. ->" & workspaces 
    result = 1
    return

  for t,f in walkDir(workspaces):
    if t != pcFile :
      continue
      
    let d = f.splitFile
    if d.ext == ".yml":
      echo d.name
