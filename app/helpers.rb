require 'aws-sdk'
require 'csv'
require 'pry-byebug'
require 'fileutils'

module Helpers
  def do_copy_file(file_name)
    csv_file = file_name
    s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    f = FileUtils.mkdir_p("/data/cassandra-migrate")
    File.open("/data/cassandra-migrate/#{csv_file}", 'wb') do |file|
      s3.get_object({ bucket: ENV['CSV_DATA_BUCKET'], key: "#{ENV['CSV_DATA_FOLDER']}/#{csv_file}" }, target: file)
    end
  end

  def do_import_file(file_name, table_name)
    dynamodb = Aws::DynamoDB::Client.new(
      region: ENV['AWS_REGION']
    )
    table = table_name
    csv_file = file_name
    index = 0
    CSV.foreach("/data/cassandra-migrate/#{csv_file}", headers: true, converters: :all, encoding: "UTF-8") do |row|
      item = {}
      puts "Index: #{index}"
      puts row
      row.each do |tuple|

        value = tuple[1]

        if tuple[0] != 'id' && tuple[0] != 'stock_id' && tuple[0] != 'exchange_id' && tuple[0] != 'sector_code'
          value = 'null' if value == nil

          # is this a boolean
          value = true if value == 'True' || value == 'true'
          value = false if value == 'False' || value == 'false'

          # is a Date
          if value.kind_of?(String) && tuple[0].end_with?('_at')
            begin
               value = Date.parse(value).to_time.to_i
            rescue ArgumentError
               # handle invalid date
            rescue RangeError
            end
          end
        end
        item[tuple[0]] = value

        index = index + 1
      end

      puts "Item"
      puts item.inspect
      # Write the table to Dynamo
      response = dynamodb.put_item(
        table_name: table,
        item: item
      )
      puts response
    end
  end

end
