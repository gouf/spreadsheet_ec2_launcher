# frozen_string_literal: true

require 'ostruct'

# ERB テンプレート描画で使うために データ群の定義を纏める
Recordset =
  Struct.new(
    :rrset,                # String
    :ttl,                  # Integer or String
    :resource_records,     # Array<String>
    :unique_nick_name_tag, # String
    keyword_init: true
  )
