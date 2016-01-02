COPY stockflare.odin_stock (id, active, category, classification, created_at, currency_code, defunct, exchange_id, is_primary, latest_market_value_usd, latest_price, latest_price_change, latest_pricing_date, latest_rating, repo_no, ric, sector_code, solr_query, ticker, updated_at) TO '/mnt/csv/odin_stock.csv' WITH HEADER='true';

COPY stockflare.odin_company (id, country_code, created_at, currency_code, description, financial_information, financial_summary, home_page, investor_relations, long_name, short_name, solr_query, stock_id, updated_at) TO '/mnt/csv/odin_company.csv' WITH HEADER='true';

COPY stockflare.odin_company_data (id, pricing_date, enterprise_value, enterprise_value_to_operating_profit, enterprise_value_to_sales, forecast_net_profit, forecast_sales, gross_margin, latest_sales, long_term_growth, market_value, market_value_usd, net_cash, net_profit, operating_profit, return_on_equity, sales_next_quarter, solr_query) TO '/mnt/csv/odin_company_data.csv' WITH HEADER='true';

COPY stockflare.odin_stock_data (id, pricing_date, book_value, cash_flow_per_share, cheaper, dividends, dps, eps, eps_next_quarter, fifty_two_week_high, fifty_two_week_low, forecast_dividend_yield, forecast_dps, forecast_eps, forecast_pe, free_cash_flow_yield, growing, high_growth, long_term_gain, momentum, one_month_forecast_eps_change, one_month_price_change, pe_ratio, peer_average_forecast_pe, peer_average_long_term_growth, per_year_gain, price, price_change, price_to_book_value, profitable, rating, recommendation, recommendation_text, seven_year_gain, shares_outstanding, solr_query, target_price, ten_day_average_volume, three_month_forecast_eps_change, three_month_price_change, upside) TO '/mnt/csv/odin_stock_data.csv' WITH HEADER='true';






id, country_code, created_at, currency_code, description, financial_information, financial_summary, home_page, investor_relations, long_name, short_name, solr_query, stock_id, updated_at



id, pricing_date, enterprise_value, enterprise_value_to_operating_profit, enterprise_value_to_sales, forecast_net_profit, forecast_sales, gross_margin, latest_sales, long_term_growth, market_value, market_value_usd, net_cash, net_profit, operating_profit, return_on_equity, sales_next_quarter, solr_query



id, active, category, classification, created_at, currency_code, defunct, exchange_id, is_primary, latest_market_value_usd, latest_price, latest_price_change, latest_pricing_date, latest_rating, repo_no, ric, sector_code, solr_query, ticker, updated_at


id, pricing_date, book_value, cash_flow_per_share, cheaper, dividends, dps, eps, eps_next_quarter, fifty_two_week_high, fifty_two_week_low, forecast_dividend_yield, forecast_dps, forecast_eps, forecast_pe, free_cash_flow_yield, growing, high_growth, long_term_gain, momentum, one_month_forecast_eps_change, one_month_price_change, pe_ratio, peer_average_forecast_pe, peer_average_long_term_growth, per_year_gain, price, price_change, price_to_book_value, profitable, rating, recommendation, recommendation_text, seven_year_gain, shares_outstanding, solr_query, target_price, ten_day_average_volume, three_month_forecast_eps_change, three_month_price_change, upside


./cassandra-unloader -f stdout -host localhost -numThreads 1 -schema "stockflare.odin_company_data (id, pricing_date, enterprise_value, enterprise_value_to_operating_profit, enterprise_value_to_sales, forecast_net_profit, forecast_sales, gross_margin, latest_sales, long_term_growth, market_value, market_value_usd, net_cash, net_profit, operating_profit, return_on_equity, sales_next_quarter, solr_query)" > /mnt/csv/odin_company_data.csv

./cassandra-unloader -f stdout -host localhost -numThreads 1 -schema "stockflare.odin_stock_data (id, pricing_date, book_value, cash_flow_per_share, cheaper, dividends, dps, eps, eps_next_quarter, fifty_two_week_high, fifty_two_week_low, forecast_dividend_yield, forecast_dps, forecast_eps, forecast_pe, free_cash_flow_yield, growing, high_growth, long_term_gain, momentum, one_month_forecast_eps_change, one_month_price_change, pe_ratio, peer_average_forecast_pe, peer_average_long_term_growth, per_year_gain, price, price_change, price_to_book_value, profitable, rating, recommendation, recommendation_text, seven_year_gain, shares_outstanding, solr_query, target_price, ten_day_average_volume, three_month_forecast_eps_change, three_month_price_change, upside)" > /mnt/csv/odin_stock_data.csv
