require './lib/bist_data_fetcher'

fetcher = BistDataFetcher.new
puts 'Veri çekme başlıyor...'
stocks = fetcher.fetch_all_stocks
puts "Çekilen hisse sayısı: #{stocks.size}"
puts 'İlk birkaç hisse:'
stocks.first(3).each { |s| puts s.inspect } if stocks.any?