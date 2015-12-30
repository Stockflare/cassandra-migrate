# require File.expand_path('../app/', __FILE__)
require_relative './app/stockflare'
require_relative './app/helpers'
require_relative './app/instrument_api'
require_relative './app/historical_api'
require 'dotenv/tasks'
include Helpers

namespace :migrate do
  task :setup do

  end

  task :copy_odin_stock do
    do_copy_file('odin_stock.csv')
  end

  task :copy_odin_stock_data do
    do_copy_file('odin_stock_data.csv')
  end

  task :add_header_to_odin_stock_data do
    add_header_to_file('odin_stock_data.csv', 'app/odin_stock_data.csv.header')
  end

  task :add_header_to_odin_company_data do
    add_header_to_file('odin_company_data.csv', 'app/odin_company_data.csv.header')
  end

  task :copy_odin_company do
    do_copy_file('odin_company.csv')
  end

  task :escape_odin_company_quotes do
    do_escape_quotes('odin_company.csv')
  end

  task :copy_odin_company_data do
    do_copy_file('odin_company_data.csv')
  end

  task :import_odin_stock do
    do_import_file('odin_stock.csv', ENV['ODIN_STOCK_TABLE'])
  end

  task :import_odin_stock_data do
    do_import_file('odin_stock_data.csv.with_header', ENV['ODIN_STOCK_DATA_TABLE'], ENV['START_DATE'].to_i)
  end

  task :import_odin_company do
    do_import_file('odin_company.csv', ENV['ODIN_COMPANY_TABLE'])
  end

  task :import_odin_company_data do
    do_import_file('odin_company_data.csv.with_header', ENV['ODIN_COMPANY_DATA_TABLE'], ENV['START_DATE'].to_i)
  end

  task :populate_instrument_api do
    InstrumentApi.populate
  end

  task :populate_historical_api do
    HistoricalApi.populate(ENV['START_DATE'].to_i)
  end

  task :create_company_data_script do
    create_company_data_script
  end



  task :instrument_api do
    puts 'Run Instrument Migration'
    Rake::Task["migrate:copy_odin_stock"].invoke
    Rake::Task["migrate:import_odin_stock"].invoke
    Rake::Task["migrate:copy_odin_company"].invoke
    Rake::Task["migrate:import_odin_company"].invoke
    Rake::Task["migrate:populate_instrument_api"].invoke

  end

  task :import_time_series_stock_data do
    puts 'Run import_time_series_stock_data'
    Rake::Task["migrate:copy_odin_stock_data"].invoke
    Rake::Task["migrate:add_header_to_odin_stock_data"].invoke
    Rake::Task["migrate:import_odin_stock_data"].invoke
  end

  task :import_time_series_company_data do
    puts 'Run import_time_series_company_data'
    Rake::Task["migrate:copy_odin_company_data"].invoke
    Rake::Task["migrate:add_header_to_odin_company_data"].invoke
    Rake::Task["migrate:import_odin_company_data"].invoke
  end

end
