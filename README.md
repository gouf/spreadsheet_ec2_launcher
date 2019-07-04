# 概要

Google Spreadsheet に定義したサブドメイン名をもとに次のことを実行する

* Spreadsheet を CSV ファイルとしてダウンロードする
* EC2 インスタンスを立ち上げる
* EC2 インスタンスにグローバルIP アドレスを割り当てる
  + そのグローバル IP アドレスを Route 53 にレコードとして登録する

実行時の処理の流れは次の通り

1. Spreadsheet -> CSV -> EC2 インスタンス + グローバル IP アドレス割り当て
2. Spreadsheet -> CSV -> Roadworker -> レコード定義

# 使い方

1. `download_remote_subdomain_sheet_as_csv.rb` で CSV ファイルを作成
2. `main.rb` で Roadworker で扱える DNS レコード定義セットが標準出力に表示される
  + リダイレクトして `roadworker/` にファイル生成
3. `bootup_ec2_instances_from_csv_data_list_definition.rb` で CSV ファイルに書かれた情報をもとに EC2 インスタンスを立ち上げ
4. `roadwork` コマンドで Route53 にレコード定義を生成
  + ドメイン名 (A レコード定義) と グローバル IP アドレスの関連付けが有効になれば各 EC2　インスタンスにアクセスできる

# `lib/*.rb` ファイルについて

## `download_remote_subdomain_sheet_as_csv.rb`

Google Spreadsheet 上に記述した「サブドメイン名 (subdomain name)」「ユニーク ニックネーム (unique nickname)」を取得、CSV ファイルとして保存する

初めて利用する場合:

* `credentials.json` を用意する必要がある : <https://developers.google.com/sheets/api/quickstart/ruby>
* スクリプト実行時に Web ブラウザ経由で認証を通す必要がある
* 作成済みの Spreadsheet のID を知っている必要がある


## `records_set_csv.rb`

`additional_records.csv` を読み取って 他のコード中で使用できるようにする


## `recordset_renderer.rb`

ERB テンプレート描画 → Roadworker 定義生成のためのデータ処理を行う

`HOSTED_ZONE` 定数値にドメイン名をハードコードしているので 必要があれば書き換える

## `recordset.rb`

ERB テンプレート描画で使うために データ群の定義を纏める


## `bootup_ec2_instances_from_csv_data_list_definition.rb`

CSV ファイル (`additional_records.csv`) の情報に沿って必要な数だけ EC2 インスタンスを立ち上げる

その際:

* CSV ファイル中の「unique nickname」をタグの Name 値に設定
* Elastic IP Address を取得・関連付け

をそれぞれのインスタンスに対して実行する
