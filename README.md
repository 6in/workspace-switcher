# ws アプリケーション

## 概要

* 任意の環境変数をセットした状態で、任意のプロセスを起動するツールです
* 複数の言語バージョンを組み合わせた環境を構築するときなどに利用すると便利です
* XXXenv系との共存
  * XXXEnv系(pyenv/rbenv等)との相性はあまりよくありません。
  * XXXEnvでインストールされた任意のバージョンへの物理パスを把握しておく必要があります。

## コマンドラインオプション

```
ws.

Usage:
  ws init
  ws shell <profile>
  ws exec  <profile> <command> [<args>]
  ws show
  ws (-h | --help)
  ws --version

Options:
  init          create .workspaces folder
  shell         open terminal with profile
  exec          execute application with profile
  <profile>     profile name(without .yml)    
  <args>        execute application's arguments.
  -h --help     Show this screen.
  --version     Show version. 

```

## 設定ファイルの仕様

* Yaml形式で記述します。
* パス区切り(：や；)で記述する環境変数は、Yamlの配列表記が可能です。
* Yaml内で別の変数への参照(プレースホルダ)が利用できます。
* 別のYamlファイルを取り込むことができます。
  * 共通設定情報等を記述します。

### Yaml形式

* envセクション配下にハッシュ形式で変数名と値を記述します。
* PATH等のパス区切りを設定する変数については、Yamlの配列表現にて記述することもできます。

```
env:
  WORKSPACE_SHELL: start
  JAVA_VER: 1.7.0_181
  # プレースホルダは(変数名)の形式
  JAVA_HOME: C:\java\jdk-(JAVA_VER)
  # PATHの組み立て
  PATH:
    - (JAVA_HOME)\bin
    - (PATH)
```

### 別のYamlの読み込み

* includeセクションに配列形式で、読み込みたいプロファイル名を指定します。
  * 拡張子(.yml)は不要です

```
# base.yml
# 共通設定を記述したプロファイル
env:
  WORKSPACE_SHELL: start
```

```
# base.ymlを読み込む
include:
  - base
env:
  JAVA_VER: 1.7.0_181
  # プレースホルダは(変数名)の形式
  JAVA_HOME: C:\java\jdk-(JAVA_VER)
  # PATHの組み立て
  PATH:
    - (JAVA_HOME)\bin
    - (PATH)
```

## shellコマンドの設定について

* shellコマンドは、ターミナルを起動しますが、各OSのデフォルト設定は特に定義していないので、プロファイル(Yamlファイル)に、起動するシェルの情報を環境変数として定義する必要があります。

### Windowsの場合

* shellコマンドでコマンドプロンプトを開く場合には、cmd.exeを指定するのではなく、startを指定します。

| 変数名 | 値 |
| ----- | ----- |
| WORKSPACE_SHELL | start |

* cmd.exeではなく、ConEmuなどのプロセスを起動する場合は、そのEXEへのパスを記述してください

### Macの場合

* shellコマンドで、ターミナルを開く場合には、Terminal.appを指定するのではなく、openを指定し、引数に```-a Terminal```を指定します。

| 変数名 | 値 | 備考 |
| ----- | ----- | -- |
| WORKSPACE_SHELL | start |  |
| WORKSPACE_SHELL_ARGS | -a Terminal | 既存のウィンドウがあればその中で起動 |
| WORKSPACE_SHELL_ARGS | -na Terminal | 常に新しいウィンドウで起動 |

* iTermを起動したい場合は、TerminalをiTermに変更するだけです

### Linuxの場合

* shellコマンドで、ターミナルを開く場合には、gnome-terminalへのパスを、設定してください。

| 変数名 | 値 | 備考 |
| ----- | ----- | -- |
| WORKSPACE_SHELL | /usr/bin/gnome-terminal | 各ディストリビューションに依存します |


## 設定ファイルの置き場所

* プロファイルとして記述するYamlファイルを配置する場所は２箇所あります。
* ファイルの探索順序は、カレントディレクトリを先に探索します。カレントディレクトリにない場合は、各OSごとに決められたフォルダを検索しにいきます。

### Windowsの場合

* カレントディレクトリ
* %USERPROFILE%\.workspacesに入っているYamlファイル

### linux/MacOS系の場合

* カレントディレクトリ
* ${HOME}/.workspacesに入っているYamlファイル


### 設定ファイルサンプル

```jdk17.yml
env:
  WORKSPACE_SHELL: start
  JAVA_VER: 1.7.0_181
  JAVA_HOME: C:\java\jdk-(JAVA_VER)
  PATH:
    - (JAVA_HOME)\bin
    - (DEFAULT_PATH)
```

```jdk18.yml
env:
  WORKSPACE_SHELL: start
  JAVA_VER: 1.8.0_141
  JAVA_HOME: C:\java\jdk-(JAVA_VER)
  PATH:
    - (JAVA_HOME)\bin
    - (DEFAULT_PATH)
```

```
$ cat Hello.java

public Class Hello {
  public static void main(String[] args) {
    System.out.println("hello")
  }
}
```

```
ws shell jdk17.yml

(jdk17)$ java -version
java version "1.7.0_141"

(jdk17)$ javac Hello.java
```

## Linux/Mac系で動作させる場合

* Mac/Linuxでターミナルを起動するとデフォルトに設定されているシェル(bash/zsh)が起動され、.bashrc/.zshrc等のプロファイルを読み込みます。
* workspaceツールは、起動するプロセスに環境変数を付与する形式なので、シェルが自動で読み込むプロファイル無いにてPATHを再設定すると、Yamlで設定した環境変数(特にPATH)が正しく設定されない状態になってしまいます。
* この状態を回避するために以下のコードを、プロファイルの一番最後に追記してください。

```
if [ "$WORKSPACE_NAME" != "" ]; then
  PROMPT="(${WORKSPACE_NAME})${PROMPT}"
  export PATH=$WORKSPACE_PATH
fi
```

* workspaceを経由して起動したターミナルの環境のWORKSPACE_NAMEという変数に、指定したワークスペース名が格納されます。
* この変数が空でないときに、環境変数PATHをWORKSPACE_PATHという環境変数の値に置き換える処理を記述します。
* WORKSPACE_PATHは、workspaceが起動した環境変数PATHと同じ値を保持しています。
