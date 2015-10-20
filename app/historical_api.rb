require_relative './stockflare'
require 'aws-sdk'
require 'pry-byebug'
require 'shotgun'

class HistoricalApi
  def self.populate(start_key = nil)

    # Loop round and get the stocks
    index = 0
    block = 0
    begin
      result = get_stock_data(start_key)
      start_key = result.last_evaluated_key
      puts "Current Start Key: id: #{result.last_evaluated_key['id']}, pricing_date: #{result.last_evaluated_key['pricing_date'].to_i}" if start_key
      result.items.each do |item|
        company = get_company(item['id'])

        if company
          company_data = get_company_data(company['id'], item['pricing_date'])
          history_item = {}
          if company_data

            # Build the history_item
            history_item = history_item.merge({
              "sic" => item['id'].to_s.downcase,
              "updated_at" => item['pricing_date'].to_i,
              "high_growth" => item['high_growth'],
              "cheaper" => item['cheaper'],
              "upside" => item['upside'],
              "profitable" => item['profitable'],
              "dividends" => item['dividends'],
              "growing" => item['growing'],
              "rating" => item['rating'],
              "price" => item['price'],
              "fifty_two_week_high" => item['fifty_two_week_high'],
              "fifty_two_week_low" => item['fifty_two_week_low'],
              "ten_day_average_volume" => item['ten_day_average_volume'],
              "pe_ratio" => item['pe_ratio'],
              "eps" => item['eps'],
              "book_value" => item['book_value'],
              "cash_flow_per_share" => item['cash_flow_per_share'],
              "dps" => item['dps'],
              "recommendation" => item['recommendation'],
              "target_price" => item['target_price'],
              "eps_next_quarter" => item['eps_next_quarter'],
              "forecast_pe" => item['forecast_pe'],
              "forecast_eps" => item['forecast_eps'],
              "forecast_dps" => item['forecast_dps'],
              "forecast_dividend_yield" => item['forecast_dividend_yield'],
              "price_to_book_value" => item['price_to_book_value'],
              "shares_outstanding" => item['shares_outstanding'],
              "long_term_gain" => item['long_term_gain'],
              "peer_average_long_term_growth" => item['peer_average_long_term_growth'],
              "peer_average_forecast_pe" => item['peer_average_forecast_pe'],
              "recommendation_text" => item['recommendation_text'],
              "momentum" => item['momentum'],
              "price_change" => item['price_change'],
              "one_month_forecast_eps_change" => item['one_month_forecast_eps_change'],
              "three_month_forecast_eps_change" => item['three_month_forecast_eps_change'],
              "one_month_price_change" => item['one_month_price_change'],
              "three_month_price_change" => item['three_month_price_change'],
              "free_cash_flow_yield" => item['free_cash_flow_yield'],
              "seven_year_gain" => item['seven_year_gain'],
              "per_year_gain" => item['per_year_gain'],

              "net_cash" => company_data['net_cash'],
              "enterprise_value" => company_data['enterprise_value'],
              "market_value" => company_data['market_value'],
              "long_term_growth" => company_data['long_term_growth'],
              "forecast_sales" => company_data['forecast_sales'],
              "sales_next_quarter" => company_data['sales_next_quarter'],
              "forecast_net_profit" => company_data['forecast_net_profit'],
              "return_on_equity" => company_data['return_on_equity'],
              "latest_sales" => company_data['latest_sales'],
              "operating_profit" => company_data['operating_profit'],
              "net_profit" => company_data['net_profit'],
              "gross_margin" => company_data['gross_margin'],
              "enterprise_value_to_sales" => company_data['enterprise_value_to_sales'],
              "market_value_usd" => company_data['market_value_usd'],
              "enterprise_value_to_operating_profit" => company_data['enterprise_value_to_operating_profit']
            })

            # Hack Hack Hack Hack Hack
            # history_item["net_cash"] = 123.45
            history_item = history_item.deep_compact
            begin
              Stockflare::Historical.create(history_item).call
              puts "Block: #{block}, Item No: #{index}, SIC: #{item['id'].downcase}, Stock Pricing Date: #{item['pricing_date'].to_i}, Company Pricing Date: #{company_data['pricing_date'].to_i} #{item['pricing_date'].to_i == company_data['pricing_date'].to_i ? "" : "MISMATCH"}"
              index = index + 1
            rescue Shotgun::Services::Errors::HttpError => error
              # binding.pry
              puts error.inspect
              puts error.body
            end

          else
            puts "Cannot Find... Company Data with Stock ID: #{item['id']}, Company ID: #{company['id']}, Pricing Date: #{item['pricing_date'].to_i}"
          end
        else
          puts "Cannot Find... Company with Stock ID: #{item['id']}"
        end
      end
      block = block + 1
    end while start_key

  end


  def self.get_stock_data(start_key)
    request = {
      table_name: ENV['ODIN_STOCK_DATA_TABLE'],
      select: 'ALL_ATTRIBUTES',
      limit: 10000000
    }

    request[:exclusive_start_key] = start_key if start_key

    result = do_dynamo_scan(request)

    puts "Scan result"
    result.to_h.keys.each do |key|
      puts "#{key} => #{result.send(key)}" if key.to_s != 'items'
    end
    return result
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

  def self.get_company_data(id, pricing_date)
    request = {
      table_name: ENV['ODIN_COMPANY_DATA_TABLE'],
      select: 'ALL_ATTRIBUTES',
      key_condition_expression: 'id = :id AND pricing_date <= :pricing_date',
      expression_attribute_values: {
        ":id" => id,
        ":pricing_date" => pricing_date
      },
      scan_index_forward: false
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
