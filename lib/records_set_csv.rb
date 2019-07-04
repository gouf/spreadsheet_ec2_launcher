# frozen_string_literal: true

require 'csv'

class RecordsSetCSV
  class << self
    CSV_FILE_PATH =
      File.expand_path(File.join(__dir__, '..', 'additional_records.csv')).freeze

    def read_as_array_of_csv_rows
      ret = []

      CSV.foreach(CSV_FILE_PATH, headers: :first_row) do |row|
        next if row.header_row?

        ret << row
      end

      ret
    end
  end
end
