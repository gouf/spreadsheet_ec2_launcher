# frozen_string_literal: true

require 'aws-sdk'
require 'base64'
require 'yaml'
require 'active_support'
require 'active_support/core_ext/hash/keys'

require File.join(__dir__, 'records_set_csv')

#
# 一度に5 処理ずつ EC2 インスタンスを立ち上げる
#
# * CSV ファイルのレコード数と同じ量の EC2 インスタンスを立ち上げる
# * CSV ファイルの情報をもとにタグ情報の設定
# * Elastic IP Address の取得と割り当て
#

csv_rows = RecordsSetCSV.read_as_array_of_csv_rows

# User code that's executed when the instance starts
user_script = 'yum -y update && yum -y install httpd && chkconfig httpd on && service httpd start'
encoded_script = Base64.encode64(user_script)

# YAML ファイルから EC2 インスタンス起動用の設定を読み込み
boot_config =
  File.join(__dir__, '..', 'aws_ec2_boot_config.yml')
  .then { |file_path| File.read(file_path) }
  .then { |content| YAML.safe_load(content) }
  .then { |hash| hash.merge(user_data: encoded_script) }
  .then(&:symbolize_keys)

locks = Queue.new
5.times { locks.push :lock }

Array.new(csv_rows.size) do |i|
  Thread.new do
    lock = locks.pop

    ec2 = Aws::EC2::Resource.new(region: 'ap-northeast-1')

    # EC2 インスタンス作成
    # FIXME: YAML ファイルにテンプレートとして設定の書き出し && 読み込み
    instance = ec2.create_instances(**boot_config)

    pp instance[0].id

    # Wait for the instance to be created, running, and passed status checks
    ec2.client.wait_until(:instance_status_ok, instance_ids: [instance[0].id])

    #
    # Elastic IP Address 取得と割り当て
    # (外部からアクセス可能にする)
    #

    ec2_client = Aws::EC2::Client.new

    ec2_client.associate_address(
      allocation_id: ec2_client.allocate_address(domain: 'vpc').allocation_id,
      instance_id: instance[0].id
    )

    # タグ付け
    instance.create_tags(
      tags: [
        { key: 'Name', value: csv_rows[i]['unique nickname'] },
        { key: 'Group', value: 'Students' }
      ]
    )

    locks.push lock
  end
end.each(&:join)
