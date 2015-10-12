require 'aws-sdk'
require 'csv'
require 'pry-byebug'
require 'fileutils'
require 'active_support/core_ext/date/calculations'
require 'time'

module Helpers
  def do_copy_file(file_name)
    csv_file = file_name
    s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    f = FileUtils.mkdir_p("/data/cassandra-migrate")
    File.open("/data/cassandra-migrate/#{csv_file}", 'wb') do |file|
      s3.get_object({ bucket: ENV['CSV_DATA_BUCKET'], key: "#{ENV['CSV_DATA_FOLDER']}/#{csv_file}" }, target: file)
    end
  end

  def add_header_to_file(file_name, header_file)
    File.delete("/data/cassandra-migrate/#{file_name}.with_header") if File.exist?("/data/cassandra-migrate/#{file_name}.with_header");

    command = "cat #{header_file} /data/cassandra-migrate/#{file_name} > /data/cassandra-migrate/#{file_name}.with_header"
    result = system(command)
    result
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
          value = true if value == 'True' || value == 'true' || value == 'TRUE'
          value = false if value == 'False' || value == 'false' || value == 'FALSE'

          # is a Date
          if value.kind_of?(String) && (tuple[0].end_with?('_at') || tuple[0] == 'pricing_date')
            begin
               value = Date.parse(value).to_time.to_i
            rescue ArgumentError
              if tuple[0] == 'pricing_date'
                str = tuple[1]
                value = DateTime.strptime(str, '%m/%d/%y %I:%M %p').to_time.to_i
              end
               # handle invalid date
            rescue RangeError
            end
          end
        end
        item[tuple[0]] = value

      end

      puts "Item: #{index}"
      puts item.inspect
      # Write the table to Dynamo
      response = dynamodb.put_item(
        table_name: table,
        item: item
      )
      index = index + 1
      puts response
    end
  end

  def create_company_data_script
    dir = FileUtils.mkdir_p("/data/extract_scripts")
    # open and write to a file with ruby
    open("/data/extract_scripts/odin_company_data.cql", 'w') { |f|
      # Add the file output command
      f.puts "CAPTURE 'odin_company_data.txt';"
      hour_step = (1.to_f/24)
      end_date = DateTime.current
      start_date = end_date.advance(months: -6)
      start_date.step(end_date,hour_step).each do |date|
        f.puts "SELECT * FROM stockflare.odin_company_data WHERE pricing_date >= '#{date.strftime('%Y-%m-%d %H')}:00:00+0000' AND pricing_date <= '#{date.strftime('%Y-%m-%d %H')}:59:59+0000' ALLOW FILTERING;"
      end
    }

  end

end
