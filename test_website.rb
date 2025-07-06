require 'httparty'
require 'nokogiri'
require 'json'

begin
  puts 'Midas web sitesine bağlanılıyor...'
  response = HTTParty.get('https://www.getmidas.com/canli-borsa/', {
    headers: {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    },
    timeout: 10
  })
  puts "HTTP Yanıt Kodu: #{response.code}"

  if response.code == 200
    puts 'HTML içeriği ayrıştırılıyor...'
    doc = Nokogiri::HTML(response.body)

    # Öncelikle tabloyu bulmayı dene
    stock_rows = doc.css('table.dataTable tbody tr')
    puts "Bulunan hisse satırı sayısı: #{stock_rows.size}"

    if stock_rows.any?
      puts "İlk 5 hisse senedinin bilgileri:"
      stock_rows.first(5).each_with_index do |row, index|
        cells = row.css('td')
        if cells.size >= 8
          symbol = cells[0].text.strip
          last_price = cells[1].text.strip
          buy_price = cells[2].text.strip
          sell_price = cells[3].text.strip
          change_percent = cells[4].text.strip
          low = cells[5].text.strip
          high = cells[6].text.strip
          avg_price = cells[7].text.strip
          volume_tl = cells.size >= 9 ? cells[8].text.strip : 'N/A'
          volume_lot = cells.size >= 10 ? cells[9].text.strip : 'N/A'
          puts "  Hisse #{index + 1}: Sembol: #{symbol}, Son Fiyat: #{last_price}, Alış: #{buy_price}, Satış: #{sell_price}, Değişim: #{change_percent}, En Düşük: #{low}, En Yüksek: #{high}, Hacim TL: #{volume_tl}"
        else
          puts "  Hisse #{index + 1}: Eksik veri - sütun sayısı: #{cells.size}"
        end
      end
    else
      puts "Hisse tablosu bulunamadı. Alternatif veri kaynakları deneniyor..."

      # 1. Alternatif: Sayfa içinde gömülü JSON veya script tag'lerinde veri arama
      scripts = doc.css('script').map(&:text)
      found_data = false

      scripts.each do |script|
        # JSON array veya object içeren bir script var mı?
        if script.include?('window.__INITIAL_STATE__')
          json_str = script[/window\.__INITIAL_STATE__\s*=\s*(\{.*?\});/, 1]
          if json_str
            begin
              data = JSON.parse(json_str)
              # Burada veri yapısına göre hisse listesini bulup yazdırabilirsin
              puts "Gömülü JSON verisi bulundu, işlenebilir."
              found_data = true
              # ...veri işleme kodu eklenebilir...
            rescue JSON::ParserError => e
              puts "Gömülü JSON ayrıştırılamadı: #{e.message}"
            end
          end
        end
      end

      unless found_data
        # 2. Alternatif: Sayfadaki tüm tabloları göster ve verileri çek
        tables = doc.css('table')
        puts "Sayfadaki tablo sayısı: #{tables.size}"
        tables.each_with_index do |table, i|
          puts "\nTablo #{i + 1}:"
          puts "  Sınıf: #{table['class']}"
          puts "  Satır sayısı: #{table.css('tr').size}"
          headers = table.css('thead th').map(&:text).map(&:strip)
          puts "  Başlıklar: #{headers.join(', ')}"

          # Eğer tablo başlıkları hisse tablosuna uyuyorsa, ilk 5 satırı yazdır
          if headers.include?("Hisse") && headers.include?("Son")
            puts "Tablodan ilk 5 hisse verisi:"
            # thead ve tbody olup olmamasına bakmaksızın, başlıktan sonraki ilk 5 satırı al
            data_rows = table.css('tr')[1, 5] # ilk satır başlık, sonrakiler veri
            data_rows&.each_with_index do |row, idx|
              cells = row.css('td').map { |td| td.text.strip }
              next if cells.empty?
              # Hücre sayısı başlıkla eşleşiyorsa yazdır
              puts "  Hisse #{idx + 1}: #{headers.zip(cells).map { |h, v| "#{h}: #{v}" }.join(', ')}"
            end
          end
        end
      end
    end
  else
    puts "Hata: HTTP #{response.code}"
  end
rescue HTTParty::Error => e
  puts "HTTP Hatası: #{e.message}"
rescue Net::ReadTimeout, Net::OpenTimeout => e
  puts "Zaman aşımı hatası: #{e.message}"
rescue SocketError => e
  puts "Bağlantı hatası: #{e.message}"
rescue StandardError => e
  puts "Beklenmeyen hata: #{e.message}"
  puts "Hata detayı: #{e.backtrace.first}"
end
