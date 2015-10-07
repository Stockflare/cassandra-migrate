require_relative './stockflare'
require 'aws-sdk'
require 'pry-byebug'
require 'shotgun'

class InstrumentApi
  def self.populate

    # Loop round and get the stocks
    start_key = nil

    begin
      result = get_stocks(start_key)
      start_key = result.last_evaluated_key
      result.items.each do |item|
        company = get_company(item['id'])
        instrument = {}
        if company
          # see if the instrument exists
          begin
            instrument = Stockflare::Instruments.get(ric: item['ric']).call
          rescue Shotgun::Services::Errors::HttpError => error
            puts error.inspect
            instrument = {}
          end

          # Build the instrument
          instrument = instrument.merge({
            ric: item['ric'],
            repo_no: item['repo_no'],
            ticker: item['ticker'],
            currency_code: item['currency_code'],
            classification: item['classification'],
            category: item['category'],
            exchange_code: item['exchange_id'],
            is_primary: item['is_primary'],
            active: item['active'],
            sector_code: item['sector_code'],
            isin: 'null'
          })

          instrument = instrument.merge({
            long_name: company['long_name'],
            short_name: company['short_name'],
            country_code: company['country_code'],
            description: company['description'],
            home_page: company['home_page'],
            financial_information: company['financial_information']
          })
          binding.pry
          begin
            Stockflare::Instruments.create(instrument).call
          rescue Shotgun::Services::Errors::HttpError => error
            binding.pry
            puts error.inspect
          end

        end


      end
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
