# workspace-switcher アプリケーション

## 概要

* 任意の環境変数をセットした状態で、任意のプロセスを起動するツールです。以下、wsと呼びます。
* 複数の言語バージョンを組み合わせた環境を構築するときなどに利用すると便利です。
* XXXenv系との共存
  * XXXEnvでインストールされた任意のバージョンへの物理パスを把握しておく必要があります。

## 履歴

* 0.3.2
  * show/new コマンドで自動作成されるテンプレートにおいて、
    * パスセパレータを持つ環境変数の重複を排除
    * パス名でソート表示するように修正
    * パスの末尾のディレクトリ区切りを除去
  * execコマンドで渡された外部EXE名はフルパス必須だったが、環境変数PATHからも検索できるように修正

## ソースからビルド

* nim >= 0.19

```
# 0.19.0用のYaml
git clone -b "for-0.19.0" https://github.com/6in/NimYAML.git
cd NimYAML
nimble install

# wsのインストール
cd
git clone https://github.com/6in/workspace-switcher.git
cd workspace-switcher
nimble install
```

## コマンドラインオプション

```
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
```

| コマンド名 | 説明 |
| -------- | ---- |
| init   | 初期化コマンドです。ホームディレクトリ配下に.workspacesフォルダを生成します |
| list  | .workspaces配下のプロファイル一覧を表示します  |
| new  |  プロファイルを新規作成します |
| edit  | プロファイルをエディタを開きます  |
| show | 現在の環境変数をYaml形式で出力します |
| shell | プロファイル名を指定して、ターミナルをオープンします |
| exec | プロファイル名を指定して、アプリケーションを実行します |
| test | プロファイルを適用した結果を、バッチ/シェル用のコードを生成します |

プロファイル名は、Yamlファイルの拡張子(.yml)を取り除いたファイル名を指定します。

### init コマンド

wsのインストール後に、一度だけ呼び出してください。
HOMEディレクトリ配下に、.workspacesフォルダおよびbase.ymlファイルを作成します。

### new コマンド

| 引数 | 説明 |
| -------- | ---- |
| profile | プロファイル名 |

新しいプロファイルを作成し、エディタを起動します。
ファイルは、$HOME/.workspacesフォルダに格納されます。

### list コマンド

$HOME/.workspacesに作成されたプロファイル一覧を表示します。

### edit コマンド

| 引数 | 説明 |
| -------- | ---- |
| profile | プロファイル名 |

$HOME/.workspacesに作成されたプロファイルをエディタで編集します。
プロファイル名は、ファイル名から.ymlを取り除いたものです。

### show コマンド

| 引数 | 説明 |
| -------- | ---- |
| envnames | (オプション)環境変数名 複数指定可能 |

現在の環境変数情報をYaml形式でコンソールに出力します。
特定の環境変数のみを出力させたいときは、パラメータとして変数名を渡します。

```
# すべての環境変数を表示
ws show

# PATH,LD_LIBRARY_PATHだけを表示
ws show PATH LD_LIBRARY_PATH
```

### shell コマンド

| 引数 | 説明 |
| -------- | ---- |
| --no-inherit | (オプション)現行の環境変数を引き継がない |
| profile | プロファイル名 |
| kvargs | (オプション)追加の環境変数 KEY=VAL形式を複数指定可能 |

指定されたプロファイルで準備された環境の元でターミナルを起動します。
起動するターミナル情報は、WORKSPACE_SHELLおよびWORKSPACE_SHELL_ARGSの２つの環境変数に設定します。
この２つの変数は、initコマンドで生成されるbase.ymlに記述されています。

--no-inheritオプションを指定すると、wsを起動している環境変数を引き継がずに、プロファイルのみの設定値で環境変数を構築します。そのため、HOME/USERPROFILEや、システムディレクトリへのパス等もすべて自分で定義する必要があります。

前述のshowコマンドを利用すれば、現在の環境変数すべてをYamlとして表示することもできます。

プロファイル名の後に引数として環境変数(キー＝値形式)を渡すことができます。

Pythonのバージョンを指定して、ターミナルをオープンする

```python
include:
  - base
env:
  PATH:
    # VERは起動時に外から渡される
    - (HOME)/.anyenv/envs/pyenv/versions/(VER)/bin
    - (HOME)/bin
    - /usr/local/bin
    - /usr/bin
    - /bin
    - /usr/sbin
    - /sbin
  WORKSPACE_NAME: python-(VER)
```

上記のプロファイルを、VERに2.7.14を指定する

```
# VERにPythonのバージョンを渡して実行する
ws shell python-ver VER=2.7.14

# ターミナル起動後
(python-2.7.14)>> python --version
Python 2.7.14
```

### exec コマンド

| 引数 | 説明 |
| -------- | ---- |
| --no-inherit | (オプション)現行の環境変数を引き継がない |
| profile | プロファイル名 |
| commands | 実行パスとパラメータ |

プロファイルで定義した環境の元でアプリケーションを実行します。
commands 引数は、実行モジュールへのフルパスおよび実行モジュールへのパラメータを指定してください。
実行パラメータ名が-(ハイフン)で始まる場合には、以下のように設定してください。

```
# NG
ws exec profile a b c d -f

# NG
ws exec profile a b c d "-f"

# OK (between double quotaion and space suffix") 
ws exec profile a b c d " -f"
```

### test コマンド

| 引数 | 説明 |
| -------- | ---- |
| --no-inherit | (オプション)現行の環境変数を引き継がない |
| profile | プロファイル名 |

shell/execコマンドのようにアプリケーションを実行せず、プロファイルで定義した環境変数をセットするコード(シェルやバッチ)を表示します。

```
» ws --no-inherit test jdk8
export PATH="/Library/Java/JavaVirtualMachines/jdk1.8.0_141.jdk/Contents/Home/bin:/Users/USER/.nimble/bin:/Users/USER/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export WORKSPACE_PATH="/Library/Java/JavaVirtualMachines/jdk1.8.0_141.jdk/Contents/Home/bin:/Users/USER/.nimble/bin:/Users/USER/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export WORKSPACE_PWD="/Users/USER/workspaces/workspace-nim/workspace-switcher"
export WORKSPACE_SHELL="/Applications/Alacritty.app/Contents/MacOS/alacritty"
```

Windows系ならSETコマンド、Mac/Linux系ならexportコマンドが出力されます。

## プロファイル(設定ファイル)の仕様について

* Yaml形式で記述します。
* パス区切り(：や；)で記述する環境変数は、Yamlの配列表記が可能です。
* Yaml内で別の変数への参照(プレースホルダ)が利用できます。
* 別のYamlファイルを取り込むことができます。
  * 共通設定情報等を記述します。

### Yaml形式 

* envセクション配下にハッシュ(キー：値)形式で環境変数名と値を記述します。
* PATH等のパス区切りを設定する変数については、Yamlの配列表現にて記述することもできます。

```
env:
  WORKSPACE_SHELL: start
  JAVA_VER: 1.7.0_181
  # プレースホルダは(変数名)の形式
  JAVA_HOME: C:\java\jdk-(JAVA_VER)
  # PATHの組み立て
  PATH:
    - (JAVA_HOME)\bin
    - (PATH)
```

* PATHの表記は以下でも同等の記述となります。

```
env:
  WORKSPACE_SHELL: start
  JAVA_VER: 1.7.0_181
  # プレースホルダは(変数名)の形式
  JAVA_HOME: C:\java\jdk-(JAVA_VER)
  # PATHの組み立て
  PATH: (JAVA_HOME)\bin;(PATH)
```

### 別のYamlの読み込み

* includeセクションに配列形式で、読み込みたいプロファイル名を指定します。
  * 拡張子(.yml)は不要です

```
# base.yml
# 共通設定を記述したプロファイル
env:
  WORKSPACE_SHELL: start
```

```
# base.ymlを読み込む
include:
  - base
env:
  JAVA_VER: 1.7.0_181
  # プレースホルダは(変数名)の形式
  JAVA_HOME: C:\java\jdk-(JAVA_VER)
  # PATHの組み立て
  PATH:
    - (JAVA_HOME)\bin
    - (PATH)
```

* includeセクションには複数のファイル指定することができます。
* includeセクションに記述した順に環境の変数の適用をするので、順序には気をつける必要があります。(後勝ちとなります)

## shellコマンドの設定について

* initコマンドを実行すると、$HOME/.workspacesディレクトリを作成し、base.ymlというプロフィルを生成します。
  * Windowsの場合は、%USERPROFILE%/.workspaces
* 各OSに紐付いたターミナル起動コマンドのデフォルトが設定されています。
* includeセクションにおいてbaseを指定することにより、shellの起動設定をスキップすることができます。
* shellコマンドで起動したターミナルを変更したい場合は、以下をご参照ください。
* プロファイル(Yamlファイル)に、起動するシェルの情報を環境変数として定義する必要があります。

### Windowsの場合

* shellコマンドでコマンドプロンプトを開く場合には、cmd.exeを指定するのではなく、startを指定します。

| 変数名 | 値 |
| ----- | ----- |
| WORKSPACE_SHELL | start |

* cmd.exeではなく、ConEmuなどのプロセスを起動する場合は、そのEXEへのパスを記述してください

### Macの場合

shellコマンドで、ターミナルを開く場合には、Terminal.appを指定するのではなく、openを指定し、引数に```-a Terminal```を指定します。

| 変数名 | 値 | 備考 |
| ----- | ----- | -- |
| WORKSPACE_SHELL | open |  |
| WORKSPACE_SHELL_ARGS | -a Terminal | 既存のウィンドウがあればその中で新しいタブで起動 |
| WORKSPACE_SHELL_ARGS | -na Terminal | 常に新しいウィンドウで起動 |

iTermを起動したい場合は、TerminalをiTermに変更するだけです

#### Macでの動作不具合

Macでの動作確認をしていたところ、Terminal/iTermともに、あとから起動したターミナルの設定を、起動済みのターミナルに影響を与える症状があることがわかりました。
openコマンドでターミナルをあとから起動すると、既存のターミナルがそれまでのセッションを終了し、あとから起動したターミナルのセッションをと同様なセッションを復元するという現象のようです。
この現象の回避策が今の所見つからないので、Terminal/iTerm以外の端末アプリを試したところ、[Alacritty(https://github.com/jwilm/alacritty)](https://github.com/jwilm/alacritty)での動作が、Windiws/Linuxでの動作に最も近いものでした。

現在の私のMacOSでの設定は以下のようになっています。

```yaml:base.yml
env:
  WORKSPACE_SHELL: /Applications/Alacritty.app/Contents/MacOS/alacritty
```

### Linuxの場合

* shellコマンドで、ターミナルを開く場合には、gnome-terminal(ターミナルアプリ)へのフルパスを、設定してください。

| 変数名 | 値 | 備考 |
| ----- | ----- | -- |
| WORKSPACE_SHELL | /usr/bin/gnome-terminal | 各ディストリビューションに依存します |

## 設定ファイルの置き場所

* プロファイルとして記述するYamlファイルを配置する場所は２箇所あります。
* ファイルの探索順序は、カレントディレクトリを先に探索します。カレントディレクトリにない場合は、各OSごとに決められたフォルダを検索しにいきます。

### Windowsの場合

* カレントディレクトリ
* %USERPROFILE%\\.workspacesに入っているYamlファイル

### linux/MacOS系の場合

* カレントディレクトリ
* ${HOME}/.workspacesに入っているYamlファイル

## Linux/Mac系で動作させる場合

* Mac/Linuxでターミナルを起動するとデフォルトに設定されているシェル(bash/zsh)が起動され、.bashrc/.zshrc等のプロファイルを読み込みます。
* wsは、起動するプロセスに環境変数を付与する形式なので、シェルが自動で読み込むプロファイル無いにてPATHを再設定すると、Yamlで設定した環境変数(特にPATH)が正しく設定されない状態になってしまいます。
* この状態を回避するために以下のコードを、プロファイルの一番最後に追加してください。

```
if [ "$WORKSPACE_NAME" != "" ]; then
  PROMPT="${PROMPT}\n(${WORKSPACE_NAME})"
  export PATH=$WORKSPACE_PATH
  cd $WORKSPACE_PWD
fi
```

もしくは、testコマンドでShellを生成し、sourceで取り込むこともできます。

```
if [ "$WORKSPACE_NAME" != "" ]; then
  PROMPT="${PROMPT}\n(${WORKSPACE_NAME})"
  cd $WORKSPACE_PWD
  ws test $WORKSPACE_NAME > /tmp/$WORKSPACE_NAME
  source /tmp/$WORKSPACE_NAME
fi
```

* workspaceを経由して起動したターミナルの環境のWORKSPACE_NAMEという変数に、指定したワークスペース名が格納されます。
* この変数が空でないときに、環境変数PATHをWORKSPACE_PATHという環境変数の値に置き換える処理を記述します。
* WORKSPACE_PATHは、wsが起動した環境変数PATHと同じ値を保持しています。
* WORKSPACE_PWDは、wsを起動したときのディレクトリを保持しています。

## Macでexec コマンドでアプリケーションを起動する

MacでGUIアプリケーションを開くときにはopenコマンドを利用しますがopenにわたすパラメータが長くなるため、以下のようなシェルを用意しexecコマンドの引数に渡してください。

VSCodeを起動するシェル

```shell:~/bin/vscode
#!/bin/sh
VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $*
```

VSCodeをシェル経由で起動

```
ws exec jdk8 ~/bin/vscode .
```

以下のように記述してもVSCodeを起動することもできます。

```
ws exec jdk8 open " -n -b com.microsoft.VSCode --args $PWD"
```

## チュートリアル１

以下のサンプルは、MacOSX/anyenv/pyenvによるpython 2.7.14,3.6.4が入っている環境にて、2.7.14の環境設定をするサンプルです

```
# 初期化コマンドを作成(.bashrc/.zshrc等の最後に、ws環境変数設定を追加してください)
ws init

# リストを確認
ws list

# 新しい環境を作成する
ws new python27

# エディタが起動され、yamlが生成されていることを確認
```

python27を以下の内容に変更して保存する

```
include:
  - base
env:
  PATH:
    - (HOME)/.anyenv/envs/pyenv/versions/2.7.14/bin
    - /Users/USER/apps/nim/Nim/bin
    - (HOME)/.nimble/bin
    - (HOME)/bin
    - /usr/local/bin
    - /usr/bin
    - /bin
    - /usr/sbin
    - /sbin
```

shellコマンドで新しいターミナルを起動する

```
ws shell python27
```

新しいターミナルで、PATHを確認する

```
# 見にくいので改行を追加しています
(python27)>> echo $PATH 
/Users/USER/.anyenv/envs/pyenv/versions/2.7.14/bin:
/Users/USER/apps/nim/Nim/bin:/Users/USER/nimble/bin:
/Users/USER/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
```

新しいターミナルで、SHOWコマンドでPATHを確認する。

```
(python27)>> ws show PATH
include:
  - base
env:
  PATH:
    - /Users/USER/.anyenv/envs/pyenv/versions/2.7.14/bin
    - /Users/USER/apps/nim/Nim/bin
    - /Users/USER/.nimble/bin
    - /Users/USER/bin
    - /usr/local/bin
    - /usr/bin
    - /bin
    - /usr/sbin
    - /sbin
```

新しいターミナルで、pythonのバージョンを表示

```
(python27)>> python --version
Python 2.7.14

(python27)>> which python
/Users/USER/.anyenv/envs/pyenv/versions/2.7.14/bin/python
```

listコマンドで、プロファイルを確認する

```
$ ws list
base
python27
```

## サンプル ( MacOSX/Java固定バージョン)

```
# jdk8.yml
include:
  - base
env:
  JAVA_HOME: /Library/Java/JavaVirtualMachines/jdk1.8.0_141.jdk/Contents/Home
  PATH:
    - (JAVA_HOME)/bin
    - (HOME)/bin
    - /usr/local/bin
    - /usr/bin
    - /bin
    - /usr/sbin
    - /sbin
```

## サンプル ( MacOSX/GraalVM)

```
include:
  - base
env:
  GRAALVM_HOME: (HOME)/apps/graalvm/graalvm-ce-1.0.0-rc10/Contents/Home
  PATH:
    - (GRAALVM_HOME)/bin
    - (HOME)/bin
    - /usr/local/bin
    - /usr/bin
    - /bin
    - /usr/sbin
    - /sbin
```

