# frozen_string_literal: true

require_relative 'lib/records_set_csv'
require_relative 'lib/recordset_renderer'

# レコード情報が記述された CSV ファイルから行情報を読み込み
record_set_csv_rows = RecordsSetCSV.read_as_array_of_csv_rows

# roadwoker コマンドで利用できる DNS レコードセット定義を ERB で生成
erb_data, records =
  RecordsetRenderer.new(record_set_csv_rows)
                   .generate_data

# FIXME: RecordsetRenderer 内でERB テンプレート描画とそのデータを返却する形にしたい
@additional_records_set = records # Set variable for ERB template
puts erb_data.result
