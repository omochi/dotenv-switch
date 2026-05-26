# dotenv-switch 仕様

## 目的

`dotenv-switch` は、`envs.yml` に定義した名前付き設定を、既存の `.env` ファイルへ部分適用するコマンドラインツールである。

複数の `.env.*` ファイルを丸ごと切り替えるのではなく、`envs.yml` を設定の正本として扱う。これにより、環境や状況ごとの値を 1 つのツリーで統合的に確認できるようにする。

## 基本方針

- Swift で実装する。
- 単一バイナリとして配布できる CLI にする。
- カレントディレクトリ、または指定したディレクトリを対象プロジェクトとして扱う。
- 入力ファイルの初期値は `envs.yml` とする。
- 書き換え対象の初期値は `.env` とする。
- `.env` 全体を生成し直すのではなく、指定されたキーの定義箇所だけを書き換える。
- `.env` 内のコメント、空行、キーの順序、対象外の値はできるだけ保持する。
- CI やスクリプトから使えるように、成功時と失敗時の exit code を安定させる。

## 用語

- source: 設定の正本となる YAML ファイル。初期値は `envs.yml`。
- target: 実際にアプリケーションが読む dotenv ファイル。初期値は `.env`。
- path: `envs.yml` 内のノードを指すドット区切りのパス。例: `network.home`。
- node: `envs.yml` 内の任意のマッピング。
- vars: 文字列テンプレートから参照できる変数を置くための予約キー。
- out: target に反映する key-value を置くための予約キー。

## `envs.yml`

`envs.yml` には任意のツリー構造を定義できる。

```yaml
vars:
  host: "192.168.1.2"

network:
  home:
    out:
      API_URL: "http://${{ host }}"
  office:
    vars:
      host: "192.168.10.23"
    out:
      API_URL: "http://${{ host }}"
```

この例では、次の 2 つの path が利用できる。

```text
network.home
network.office
```

## `out` 規約

`out` は予約キーであり、そのノードを target に反映するときの dotenv key-value を表す。

```yaml
network:
  home:
    out:
      API_URL: "http://192.168.1.2"
```

`dotenv-switch network.home` を実行すると、target 内の `API_URL` の定義箇所が `http://192.168.1.2` に書き換えられる。

仕様:

- `out` は YAML mapping でなければならない。
- `out` のキーは dotenv のキー名として扱う。
- `out` の値は文字列だけを認める。
- `out` 自体は path の一部として扱わない。
- 文字列以外の値が含まれている場合は失敗し、target は変更しない。

## `vars` 規約

`vars` は予約キーであり、`vars` と `out` の文字列から参照できる変数を定義する。

```yaml
vars:
  host: "192.168.1.2"

network:
  office:
    vars:
      host: "192.168.10.23"
    out:
      API_URL: "http://${{ host }}"
```

仕様:

- `vars` は YAML mapping でなければならない。
- `vars` のキーは変数名として扱う。
- `vars` の値は文字列だけを認める。
- 文字列以外の値が含まれている場合は失敗し、target は変更しない。
- top-level の `vars` は全 path から参照できる。
- path が指す定義ノード内の `vars` は、そのノードの `out` から参照できる。
- 定義ノード内の `vars` は top-level の `vars` を上書きできる。
- `vars` 自体は path の一部として扱わない。

## 式展開

`vars` の右辺と `out` の右辺では、`${{ }}` で式を開ける。

```yaml
vars:
  scheme: "http"
  host: "192.168.1.2"
  baseURL: "${{ scheme }}://${{ host }}"

network:
  home:
    out:
      API_URL: "${{ baseURL }}"
```

初期仕様で書ける式は変数名だけである。

仕様:

- `${{ host }}` は変数 `host` の値に置き換える。
- 式の前後の空白は無視する。`${{host}}` と `${{ host }}` は同じ意味とする。
- 式が参照する変数が存在しない場合は失敗し、target は変更しない。
- 変数展開は `vars` を解決してから `out` を解決する。
- 変数の値にも式を書ける。
- エスケープ構文は提供しない。
- 文字列に `$` を含めたい場合は、そのまま `$` を書く。
- `${{` から始まる文字列をリテラルとして書くための専用構文は提供しない。
- 循環参照がある場合は失敗し、target は変更しない。

## コマンド

### `dotenv-switch <path>`

指定した path の `out` を target に反映する。

```console
$ dotenv-switch network.home
Updated .env with network.home.
```

仕様:

- `envs.yml` から `network.home` ノードを探す。
- ノードに `out` がない場合は失敗する。
- `vars` と `out` の式を解決する。
- `out` に含まれる各キーについて、target 内の既存定義を探す。
- 既存定義が見つかったキーは、その行の値だけを書き換える。
- 既存定義が見つからないキーは、target 内へ新しい定義行を追加する。
- 対象外の行、コメント、空行は保持する。
- すべての更新が成功するまで、target の内容を中途半端に変更しない。

### `dotenv-switch list`

利用可能な path を一覧表示する。

```console
$ dotenv-switch list
network.home
network.office
```

仕様:

- `envs.yml` 内を再帰的に探索する。
- `out` を持つノードを path として表示する。
- `vars` と `out` 自体は表示しない。
- `out` を持たない中間ノードは表示しない。
- 表示順は YAML 上の出現順とする。
- 辞書順ソートはしない。

### `dotenv-switch show <path>`

指定した path の `out` を表示する。

```console
$ dotenv-switch show network.home
API_URL=http://192.168.1.2
```

仕様:

- `.env` は変更しない。
- `vars` と `out` の式を解決した結果を dotenv 形式で表示する。
- 初期版に含める。

### `dotenv-switch diff <path>`

指定した path を適用した場合の target 差分を表示する。

```console
$ dotenv-switch diff network.home
```

仕様:

- `.env` は変更しない。
- 実際の更新処理と同じロジックで変更後の内容を作り、現在の target と比較する。
- 初期版に含める。
- 表示形式は unified diff 形式に寄せる。
- diff 表示は Swift 内で自作する。
- ヘッダーには変更前として target path、変更後として target path と path 名を表示する。

例:

```diff
--- .env
+++ .env (network.home)
@@ -1,2 +1,2 @@
 # API endpoint
-API_URL=http://localhost:3000
+API_URL=http://192.168.1.2
```

## `.env` の書き換え

target は dotenv ファイルとして扱う。

例:

```dotenv
# API endpoint
API_URL=http://localhost:3000
TOKEN=abc
```

`dotenv-switch network.home` 後:

```dotenv
# API endpoint
API_URL=http://192.168.1.2
TOKEN=abc
```

仕様:

- `KEY=value` 形式の行を更新対象にする。
- target に同じキーの定義行が複数ある場合は、最後の定義行を更新する。
- target に対象キーの定義行が存在しない場合は、新しい定義行を追加する。
- 追加時は、まず `# KEY=...` 形式のコメントアウト行を探す。
- `# KEY=...` 形式のコメントアウト行が見つかった場合、その最後の行の直下に `KEY=value` を挿入する。
- コメントアウト行は変更しない。
- `# KEY=...` 形式のコメントアウト行も存在しない場合は、target の末尾に `KEY=value` を追加する。
- `export KEY=value` 形式はサポートしない。
- `KEY = value` のような空白を含む形式はサポートしない。
- 既存値の quote style は踏襲しない。
- コメント行の中にある `KEY=value` は更新対象にしない。

## `.env` 値の書き出し

`out` の文字列は、式展開後に次の規則で `.env` へ書き出す。

仕様:

- 通常の値は quote せずに `KEY=value` として書き出す。
- 値に `#` が含まれる場合は、値全体を double quote する。
- 値に改行が含まれる場合は、値全体を double quote し、改行を `\n` として書き出す。
- double quote される値に `\` が含まれる場合は、`\\` として書き出す。
- 既存値が double quote / single quote で囲まれていても、新しい値の quote style は上記規則だけで決める。

例:

```dotenv
PLAIN=abc
WITH_HASH="abc#def"
WITH_NEWLINE="line1\nline2"
WITH_BACKSLASH="C:\\Users\\omochi"
```

## 共通オプション

```text
--source <path>   source YAML を指定する。初期値は envs.yml。
--target <path>   target dotenv を指定する。初期値は .env。
--project <path>  対象ディレクトリを指定する。初期値はカレントディレクトリ。
--dry-run         target を変更せず、変更予定を表示する。
--quiet           成功時の通常メッセージを抑制する。
--version         バージョンを表示する。
--help            ヘルプを表示する。
```

## 安全性

target の更新は破壊的な操作になり得るため、次の安全策を持つ。

- source が存在しない場合は target を変更しない。
- 指定 path が存在しない場合は target を変更しない。
- 指定 path に `out` がない場合は target を変更しない。
- `vars` または `out` が不正な形式の場合は target を変更しない。
- 式展開に失敗した場合は target を変更しない。
- target が存在しない場合は失敗する。
- target の読み込み、変換、書き込みのいずれかに失敗した場合、できるだけ元の状態を保つ。
- 書き込み前に変更後の内容をメモリ上で完成させる。
- 更新前バックアップは作らない。

## Exit Code

- `0`: 成功。
- `1`: ユーザー入力やファイル状態による通常の失敗。
- `2`: コマンドライン引数の不正。
- `70`: 想定外の内部エラー。

## MVP

最初の実装範囲は次を候補とする。

- `dotenv-switch <path>`
- `dotenv-switch list`
- `dotenv-switch show <path>`
- `dotenv-switch diff <path>`
- `--source <path>`
- `--target <path>`
- `--project <path>`
- `--dry-run`
- `--quiet`
- `envs.yml` の任意ツリー探索。
- `vars` mapping の読み取り。
- `out` mapping の読み取り。
- `${{ variableName }}` 式の展開。
- target 内に存在する `KEY=value` 行の値更新。
- target 内に存在しないキーの追加。
- `# KEY=...` コメントアウト行を使った挿入位置の決定。
- unified diff 形式の差分表示。

## Open Questions

なし。
