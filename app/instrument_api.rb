require_relative './stockflare'
require 'aws-sdk'
require 'pry-byebug'
require 'shotgun'

class InstrumentApi
  def self.populate

    # Loop round and get the stocks
    start_key = nil
    index = 0
    block = 0
    begin
      result = get_stocks(start_key)
      start_key = result.last_evaluated_key
      result.items.each do |item|
        company = get_company(item['id'])
        instrument = {}
        if company
          # see if the instrument exists
          begin
            instruments = Stockflare::Instruments.get(ric: item['ric'].downcase).call.body
            if instruments.count > 0
              instrument = instruments[0].to_h
            end
          rescue Shotgun::Services::Errors::HttpError => error
            puts error.inspect
            instrument = {}
          end

          # Build the instrument
          instrument = instrument.merge({
            "sic" => item['id'].to_s.downcase,
            "ric" => item['ric'].downcase,
            "repo_no" => item['repo_no'].to_s.downcase,
            "ticker" => item['ticker'].to_s.downcase,
            "currency_code" => item['currency_code'].to_s.downcase,
            "classification" => item['classification'].to_s.downcase,
            "category" => item['category'].to_s.downcase,
            "exchange_code" => item['exchange_id'].to_i,
            "is_primary" => item['is_primary'],
            "active" => item['active'],
            "sector_code" => item['sector_code'].to_i
          })

          instrument = instrument.merge({
            'long_name' => company['long_name'],
            'short_name' => company['short_name'],
            'country_code' => company['country_code'].downcase,
            'description' => company['description'],
            'home_page' => company['home_page'],
            'financial_summary' => company['financial_summary'],
            'financial_information' => company['financial_information']
          })
          instrument = instrument.deep_compact
          instrument['isin'] = 'null'
          if instrument.has_key?('ticker')
            begin
              Stockflare::Instruments.create(instrument).call
              puts "Block: #{block}, Item No: #{index}, RIC: #{item['ric'].downcase}"
              index = index + 1
            rescue Shotgun::Services::Errors::HttpError => error
              puts error.inspect
              puts error.body
            end
          end

        end


      end
      block = block + 1
    end while start_key

  end


  def self.get_stocks(start_key)
    request = {
      table_name: ENV['ODIN_STOCK_TABLE'],
      select: 'ALL_ATTRIBUTES'
    }

    request[:exclusive_start_key] = start_key if start_key

    return do_dynamo_scan(request)
  end

  def self.get_company(stock_id)
    request = {
      table_name: ENV['ODIN_COMPANY_TABLE'],
      select: 'ALL_ATTRIBUTES',
      index_name: 'stock_id-index',
      key_condition_expression: 'stock_id = :stock_id',
      expression_attribute_values: {
        ":stock_id" => stock_id
      }
    }

    return do_dynamo_query(request)

  end

  def self.do_dynamo_scan(request)
    dynamodb = Aws::DynamoDB::Client.new(
      region: ENV['AWS_REGION']
    )

    result = dynamodb.scan(request)

    return result
  end

  def self.do_dynamo_query(request)
    dynamodb = Aws::DynamoDB::Client.new(
      region: ENV['AWS_REGION']
    )

    result = dynamodb.query(request)
    if result.count > 0
      return result.items[0]
    else
      return nil
    end
  end
end

class Hash
  # Recursively filters out nil (or blank - e.g. "" if exclude_blank: true is passed as an option) records from a Hash
  def deep_compact(options = {})
    inject({}) do |new_hash, (k,v)|
      result = (v.kind_of?(String) && (v.empty? || v == 'null')) || v.nil?
      if !result
        new_value = v
        new_hash[k] = new_value
      end
      new_hash
    end
  end
end
