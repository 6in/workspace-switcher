import os
import osproc
import strtabs

import yaml,yaml/presenter,yaml/serialization
import json,strutils,os,streams
import ospaths
import nre

proc dump(yamlDoc:YamlDocument ,file:string, style:PresentationStyle) =
  ## Yamlをダンプ
  var s = newFileStream(file, fmWrite)
  yamlDoc.dumpDom(s, options= defineOptions(style = style) )
  s.close()

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

proc getProfilePath(path:string) : string =
  var root = os.getCurrentDir()

  if (root / path).existsFile :
    result = root / path
    return

  when defined(window):
    root = getEnv("USERPROFILE",os.getCurrentDir()) / ".workspace"
  else:
    root = getEnv("HOME",os.getCurrentDir()) / ".workspace"

  result = root / path
  if result.existsFile == false:
    var
      e: ref OSError
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
    # echo "key=" & key
    # echo "val=" & val2
    result[key] = result.embedParam(val2)

proc getCurrentEnv*() : StringTableRef =
  result = newStringTable()
  for item in envPairs():
    result[item.key] = $item.value

proc remove* (env: StringTableRef, keys: openArray[string]) : StringTableRef =
  result = newStringTable()
  for item in env.pairs :
    if keys.contains(item.key) == false :
      result[item.key] = item.value