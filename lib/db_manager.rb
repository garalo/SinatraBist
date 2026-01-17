require 'mongo'

class DBManager
  def initialize(db_name = 'bist_stocks')
    @client = Mongo::Client.new(['127.0.0.1:27017'], database: db_name)
    @stocks_collection = @client[:stocks]
  end

  # Veritabanı bağlantısını al
  def client
    @client
  end

  # Hisse koleksiyonunu al
  def stocks_collection
    @stocks_collection
  end

  # Tüm hisseleri getir
  def get_all_stocks
    @stocks_collection.find.to_a
  end

  # Belirli bir hisseyi getir
  def get_stock(symbol)
    @stocks_collection.find(symbol: symbol).first
  end

  # Hisse verilerini güncelle veya ekle
  def upsert_stock(stock_data)
    @stocks_collection.find_one_and_update(
      { symbol: stock_data[:symbol] },
      { '$set' => stock_data },
      { upsert: true }
    )
  end

  # Birden fazla hisse verisini güncelle veya ekle
  def upsert_stocks(stocks)
    stocks.each do |stock|
      symbol = stock[:symbol] || stock['symbol']
      # 'history' alanını da kaydet
      @stocks_collection.update_one(
        { 'symbol' => symbol },
        { '$set' => stock },
        upsert: true
      )
    end
  end

  # Yükselen hisseleri getir
  def get_rising_stocks
    @stocks_collection.find({ change_percentage: { '$gt' => 0 } })
                      .sort({ change_percentage: -1 })
                      .to_a
  end

  # Düşen hisseleri getir
  def get_falling_stocks
    @stocks_collection.find({ change_percentage: { '$lt' => 0 } })
                      .sort({ change_percentage: 1 })
                      .to_a
  end

  # Veritabanı bağlantısını kapat
  def close
    @client.close
  end
end
