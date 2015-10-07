# require File.expand_path('../app/', __FILE__)
require_relative './app/stockflare'
require_relative './app/helpers'
require_relative './app/instrument_api'
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

  task :copy_odin_company do
    do_copy_file('odin_company.csv')
  end

  task :copy_odin_company_data do
    do_copy_file('odin_company_data.csv')
  end

  task :import_odin_stock do
    do_import_file('odin_stock.csv', ENV['ODIN_STOCK_TABLE'])
  end

  task :import_odin_stock_data do
    do_import_file('odin_stock_data.csv', ENV['ODIN_STOCK_DATA_TABLE'])
  end

  task :import_odin_company do
    do_import_file('odin_company.csv', ENV['ODIN_COMPANY_TABLE'])
  end

  task :import_odin_company_data do
    do_import_file('odin_company_data.csv', ENV['ODIN_COMPANY_DATA_TABLE'])
  end

  task :populate_instrument_api do
    InstrumentApi.populate
  end



  task :instrument_api do
    puts 'Run Instrument Migration'
    Rake::Task["migrate:copy_odin_stock"].invoke
    Rake::Task["migrate:import_odin_stock"].invoke
    Rake::Task["migrate:copy_odin_company"].invoke
    Rake::Task["migrate:import_odin_company"].invoke
    Rake::Task["migrate:populate_instrument_api"].invoke

  end

end
