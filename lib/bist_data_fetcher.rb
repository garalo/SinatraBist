require 'httparty'
require 'nokogiri'
require 'json'

class BistDataFetcher
  BIST_URL = 'https://www.getmidas.com/canli-borsa/'

  def initialize
    @cache = {}
    @last_fetch_time = nil
  end

  # Tüm BIST hisselerini getir
  def fetch_all_stocks
    puts "BistDataFetcher#fetch_all_stocks çağrıldı"

    # Önbellek kontrolü - son 15 dakika içinde veri çekildiyse önbellekten döndür
    if @last_fetch_time && Time.now - @last_fetch_time < 900 && !@cache.empty?
      puts "Önbellekten veri döndürülüyor (#{@cache.size} hisse)"
      return @cache.values
    end

    stocks = {}

    begin
      puts "BIST web sitesine bağlanılıyor: #{BIST_URL}"
      # User-Agent ile birlikte BIST sayfasını çek (10 saniye timeout ile)
      response = HTTParty.get(BIST_URL, {
        headers: {
          'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
        timeout: 10
      })
      puts "HTTP yanıt kodu: #{response.code}"

      if response.code == 200
        puts "HTML içeriği ayrıştırılıyor..."
        doc = Nokogiri::HTML(response.body)

        # Doğru tabloyu bulmak için başlıkları kontrol et
        table = doc.css('table').find do |tbl|
          headers = tbl.css('thead th').map(&:text).map(&:strip)
          headers.include?("Hisse") && headers.include?("Son")
        end

        if table
          headers = table.css('thead th').map(&:text).map(&:strip)
          puts "Tablo başlıkları: #{headers.join(', ')}"
          data_rows = table.css('tr')[1..] # ilk satır başlık, sonrakiler veri

          data_rows&.each do |row|
            cells = row.css('td').map { |td| td.text.strip }
            next if cells.empty? || cells.size < headers.size

            # Hücreleri başlıklarla eşleştir
            stock_hash = Hash[headers.zip(cells)]

            begin
              symbol = stock_hash["Hisse"].to_s.strip.upcase
              next if symbol.empty?
              last_price = parse_price(stock_hash["Son"])
              buy_price = parse_price(stock_hash["Alış"])
              sell_price = parse_price(stock_hash["Satış"])
              change_percentage = parse_percent(stock_hash["Fark"])
              low = parse_price(stock_hash["En Düşük"])
              high = parse_price(stock_hash["En Yüksek"])
              avg_price = parse_price(stock_hash["AOF"])
              volume_tl = stock_hash["Hacim TL"] ? parse_price(stock_hash["Hacim TL"]) : 0
              volume_lot = stock_hash["Hacim Lot"] ? parse_price(stock_hash["Hacim Lot"]) : 0

              change = (last_price * change_percentage / 100.0).round(2)

              stock_data = {
                symbol: symbol,
                last_price: last_price,
                buy_price: buy_price,
                sell_price: sell_price,
                change: change,
                change_percentage: change_percentage,
                low: low,
                high: high,
                avg_price: avg_price,
                volume_tl: volume_tl,
                volume_lot: volume_lot,
                timestamp: Time.now
              }

              # Aynı sembol varsa güncelle
              stocks[symbol] = stock_data
              @cache[symbol] = stock_data
            rescue => e
              puts "Hisse verisi ayrıştırılırken hata: #{e.message}"
            end
          end
          puts "Çekilen hisse sayısı: #{stocks.size}"
          @last_fetch_time = Time.now
        else
          puts "Uygun tablo bulunamadı."
        end
      end
    rescue => e
      puts "BIST verisi çekilirken hata oluştu: #{e.message}"
      puts "Hata detayı: #{e.backtrace.join("\n")}"
    end

    # Eğer veri çekilemediyse, alternatif kaynak kullan
    if stocks.empty?
      puts "Veri çekilemedi, alternatif kaynak kullanılacak"
      stocks = fetch_from_alternative_source.map { |s| [s[:symbol], s] }.to_h
    end

    stocks.values
  end

  # Yardımcı metotlar
  private

  def parse_price(str)
    return 0 if str.nil? || str.empty?
    str.gsub('.', '').gsub(',', '.').gsub(/[^\d\.]/, '').to_f
  end

  def parse_percent(str)
    return 0 if str.nil? || str.empty?
    str.gsub('%', '').gsub(',', '.').to_f
  end

  public

  # Belirli bir hissenin verilerini getir
  def fetch_stock(symbol)
    all_stocks = fetch_all_stocks
    all_stocks.find { |stock| stock[:symbol] == symbol }
  end

  # Alternatif kaynak olarak demo veri kullan
  def fetch_from_alternative_source
    puts "Alternatif veri kaynağı kullanılıyor..."

    # Demo veri oluştur
    demo_stocks = [
      { symbol: 'AKBNK', last_price: 25.64, change: 0.42, change_percentage: 1.67, volume_tl: 12500000, volume_lot: 500000, timestamp: Time.now },
      { symbol: 'GARAN', last_price: 30.12, change: -0.28, change_percentage: -0.92, volume_tl: 15600000, volume_lot: 600000, timestamp: Time.now },
      { symbol: 'THYAO', last_price: 42.86, change: 1.24, change_percentage: 2.98, volume_tl: 8900000, volume_lot: 300000, timestamp: Time.now },
      { symbol: 'EREGL', last_price: 18.75, change: 0.15, change_percentage: 0.81, volume_tl: 5400000, volume_lot: 200000, timestamp: Time.now },
      { symbol: 'KRDMD', last_price: 9.42, change: -0.18, change_percentage: -1.88, volume_tl: 7200000, volume_lot: 250000, timestamp: Time.now }
    ]

    demo_stocks.each { |stock| @cache[stock[:symbol]] = stock }

    @last_fetch_time = Time.now
    demo_stocks
  end

  # Hisse geçmişini getir (demo amaçlı rastgele veri)
  def fetch_stock_history(symbol, days=30)
    history = []
    base_price = rand(10..100)

    days.times do |i|
      date = Date.today - (days - i)
      # Rastgele fiyat değişimi
      price_change = rand(-2.0..2.0)
      price = base_price + price_change
      base_price = price # Bir sonraki gün için baz fiyatı güncelle

      history << {
        date: date,
        price: price.round(2),
        volume: rand(10000..1000000)
      }
    end

    history
  end
end
