# frozen_string_literal: true

require 'erb'
require_relative 'recordset'
require 'aws-sdk'

# ERB テンプレート描画 → Roadworker 定義生成のためのデータ処理を行う
# FIXME: クラス内で ERB に値を埋め込んだ結果を返すメソッドを記述
class RecordsetRenderer
  HOSTED_ZONE = 'example.com.'.freeze # NOTE: Update to your domain name
  TEMPLATE_FILE_PATH = File.join(__dir__, '..', 'editable_routes.erb').freeze

  def initialize(record_set_csv_rows)
    # ERB テンプレートを使って生成するファイルの差し込みデータ作成のために使う
    @record_set_csv_rows = record_set_csv_rows

    # タグ名から Public IP Address を照会するために使う
    @ec2_client = ::Aws::EC2::Client.new(region: 'ap-northeast-1')
  end

  def generate_data
    insertion_target_records =
      @record_set_csv_rows.map do |record|
        Recordset.new(
          rrset: "#{record['subdomain name']}.#{HOSTED_ZONE}",
          resource_records: fetch_global_ip_address_by_tag_name(record['unique nickname']),
          ttl: 60,
          unique_nick_name_tag: record['unique nickname']
        )
      end

    erb_file = File.read(TEMPLATE_FILE_PATH)

    [ERB.new(erb_file), insertion_target_records]
  end

  def fetch_global_ip_address_by_tag_name(tag_name)
    query_result =
      @ec2_client.describe_instances(
        filters: [
          name: 'tag:Name',
          values: [tag_name]
        ]
      )

    public_ip_address =
      query_result.reservations[0]
                  .instances[0]
                  .public_ip_address

    [public_ip_address]
  rescue NoMethodError
    puts "与えられたタグ名 (#{tag_name}) からは Public IP Address が見つけられませんでした"
    puts $ERROR_POSITION # スタックトレース出力
    exit
  end
end
