# dotenv-switch

`dotenv-switch` is a Swift CLI that applies named settings from `envs.yml` to an existing `.env` file.

`dotenv-switch` は、`envs.yml` に定義した名前付き設定を、既存の `.env` ファイルへ反映する Swift 製 CLI です。

Instead of switching whole `.env.*` files, it uses `envs.yml` as the settings source and applies only the selected path's `out` values to `.env`.

複数の `.env.*` ファイルを丸ごと切り替えるのではなく、`envs.yml` を設定のソースとして管理し、選んだ path の `out` だけを `.env` に部分適用します。

## Example / 例

`envs.yml`:

```yaml
var:
  scheme: "http"
  host: "192.168.1.2"

network:
  home:
    out:
      API_URL: "${{ scheme }}://${{ host }}"
  office:
    var:
      host: "192.168.10.23"
    out:
      API_URL: "${{ scheme }}://${{ host }}"
```

`.env`:

```dotenv
# API endpoint
API_URL=http://localhost:3000
TOKEN=abc
```

Apply `network.home`.

`network.home` を反映します。

```console
$ dotenv-switch network.home
Updated .env with network.home.
```

Result:

結果:

```dotenv
# API endpoint
API_URL=http://192.168.1.2
TOKEN=abc
```

## Usage / 使い方

```console
dotenv-switch <paths> ... [--dry-run] [--source <source>] [--target <target>] [--project <project>] [--quiet]
dotenv-switch <subcommand>
```

### Apply / 反映

Apply one or more paths to `.env`.

1 つ以上の path を `.env` に反映します。

```console
$ dotenv-switch network.home
$ dotenv-switch network.home api.local
```

Multiple paths are applied in the order given.

複数 path は、指定した順番で重ねて反映されます。

### List / 一覧

List paths that have an `out` mapping.

`out` を持つ path を一覧表示します。

```console
$ dotenv-switch list
network.home
network.office
```

### Show / 表示

Print resolved `out` values without changing `.env`.

`.env` を変更せず、式展開後の `out` を dotenv 形式で表示します。

```console
$ dotenv-switch show network.home
API_URL=http://192.168.1.2
```

### Diff / 差分

Print the diff that would be applied to `.env`.

`.env` に反映される予定の差分を表示します。

```console
$ dotenv-switch diff network.home
--- .env
+++ .env (network.home)
@@ -1,2 +1,2 @@
 # API endpoint
-API_URL=http://localhost:3000
+API_URL=http://192.168.1.2
```

`--dry-run` on the apply command also prints this diff instead of writing the target file.

反映コマンドに `--dry-run` を付けた場合も、target ファイルを書き換えずに差分を表示します。

```console
$ dotenv-switch network.home --dry-run
```

## envs.yml

`envs.yml` can contain any tree shape. A node becomes selectable when it has an `out` mapping.

`envs.yml` には任意のツリー構造を書けます。`out` を持つノードが、選択可能な path になります。

Reserved keys:

予約キー:

- `var`: string variables available to templates.
- `out`: dotenv key-value output for the selected node.

- `var`: テンプレートから参照できる文字列変数。
- `out`: 選択したノードから `.env` へ出力する key-value。

Only string values are allowed in `var` and `out`.

`var` と `out` の値は文字列だけを認めます。

Top-level `var` values are available to every path. A selected node can define its own `var`, and local variables override top-level variables with the same name.

トップレベルの `var` はすべての path から参照できます。選択したノード側にも `var` を定義でき、同名の変数はノード側の値で上書きされます。

```yaml
var:
  host: "192.168.1.2"

network:
  office:
    var:
      host: "192.168.10.23"
    out:
      API_URL: "http://${{ host }}"
```

## Templates / テンプレート

`var` and `out` values can use `${{ variableName }}` expressions.

`var` と `out` の値では、`${{ variableName }}` 形式の式を使えます。

```yaml
var:
  scheme: "http"
  host: "192.168.1.2"
  baseURL: "${{ scheme }}://${{ host }}"

network:
  home:
    out:
      API_URL: "${{ baseURL }}"
```

Only variable-name expressions are supported. There is no escape syntax.

式として書けるのは変数名だけです。エスケープ構文はありません。

## DotEnv Updates / .env の更新

`dotenv-switch` updates existing `KEY=value` lines while preserving unrelated comments, blank lines, and values.

`dotenv-switch` は既存の `KEY=value` 行を更新します。関係ないコメント、空行、値はできるだけ保持します。

If a key does not exist, it looks for a commented-out definition:

キーが存在しない場合は、まずコメントアウトされた定義を探します。

```dotenv
# API_URL=http://example
```

When found, the new definition is inserted below the last matching commented-out line.

見つかった場合は、最後に見つかったコメントアウト行の直下へ新しい定義を挿入します。

```dotenv
# API_URL=http://example
API_URL=http://192.168.1.2
```

If no matching commented-out line exists, the new definition is appended to the end of the file.

対応するコメントアウト行がなければ、ファイル末尾へ追加します。

Unsupported dotenv forms:

サポートしない dotenv 形式:

- `export KEY=value`
- `KEY = value`

## Value Formatting / 値の書き出し

Most values are written as-is.

通常の値はそのまま書き出します。

```dotenv
PLAIN=abc
```

Values containing `#` or a newline are double-quoted. Newlines are written as `\n`. Backslashes inside double-quoted values are doubled.

`#` または改行を含む値は double quote します。改行は `\n` として書き出します。double quote される値の中の backslash は二重にします。

```dotenv
WITH_HASH="abc#def"
WITH_NEWLINE="line1\nline2"
WITH_BACKSLASH="C:\\Users\\omochi"
```

## Options / オプション

```text
--source <source>    Source YAML path. Default: envs.yml
--target <target>    Target dotenv path. Default: .env
--project <project>  Project directory. Default: .
--dry-run            Print diff instead of writing .env
--quiet              Suppress success messages
--version            Show version
--help               Show help
```

## Build / ビルド

```console
$ swift build
```

Release build:

リリースビルド:

```console
$ swift build -c release
```

## Installation / インストール

Build the release binary, then copy it to a directory included in your `PATH`.

リリースビルドした後、`PATH` が通っているディレクトリへバイナリをコピーします。

```console
$ swift build -c release
$ cp .build/release/dotenv-switch <your-bin>/
```

Run from source:

ソースから実行:

```console
$ swift run dotenv-switch list
```

## Test / テスト

```console
$ swift test
```

## License / ライセンス

MIT. See [LICENSE](LICENSE).

MIT です。詳しくは [LICENSE](LICENSE) を見てください。
