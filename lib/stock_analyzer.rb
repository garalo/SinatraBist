class StockAnalyzer
  def initialize(stock_data)
    @stock_data = stock_data
    @fetcher = BistDataFetcher.new
  end
  
  # Hissenin trendini analiz et
  def analyze_trend
    return 'neutral' unless @stock_data
    
    change_percentage = @stock_data[:change_percentage].to_f
    
    if change_percentage > 3
      'strong_up'
    elsif change_percentage > 0
      'up'
    elsif change_percentage < -3
      'strong_down'
    elsif change_percentage < 0
      'down'
    else
      'neutral'
    end
  end
  
  # Hisse için grafik verilerini hazırla
  def prepare_chart_data
    return [] unless @stock_data
    
    # Gerçek uygulamada burada geçmiş verileri çekebilirsiniz
    # Şimdilik demo veriler kullanıyoruz
    history = @fetcher.fetch_stock_history(@stock_data[:symbol])
    
    # Chartkick için veri formatı
    history.map { |day| [day[:date].to_s, day[:price]] }
  end
  
  # Destek ve direnç seviyelerini hesapla (basit bir örnek)
  def calculate_support_resistance
    return {} unless @stock_data
    
    history = @fetcher.fetch_stock_history(@stock_data[:symbol])
    prices = history.map { |day| day[:price] }
    
    # Basit bir yaklaşım: Min ve max değerleri destek ve direnç olarak kullan
    min_price = prices.min
    max_price = prices.max
    
    # Ortalama fiyat
    avg_price = prices.sum / prices.size.to_f
    
    # Destek seviyeleri (ortalama ile minimum arasında)
    support1 = ((avg_price + min_price) / 2).round(2)
    
    # Direnç seviyeleri (ortalama ile maksimum arasında)
    resistance1 = ((avg_price + max_price) / 2).round(2)
    
    {
      support_levels: [min_price.round(2), support1],
      resistance_levels: [resistance1, max_price.round(2)]
    }
  end
  
  # Hareketli ortalama hesapla
  def calculate_moving_average(period=10)
    return [] unless @stock_data
    
    history = @fetcher.fetch_stock_history(@stock_data[:symbol], period + 10)
    prices = history.map { |day| day[:price] }
    
    moving_averages = []
    
    (period..prices.length-1).each do |i|
      date = history[i][:date]
      ma_value = prices[(i-period+1)..i].sum / period.to_f
      moving_averages << [date.to_s, ma_value.round(2)]
    end
    
    moving_averages
  end
  
  # Yükselen ve düşen kanalları belirle
  def identify_channels
    return {} unless @stock_data
    
    history = @fetcher.fetch_stock_history(@stock_data[:symbol], 30)
    prices = history.map { |day| day[:price] }
    dates = history.map { |day| day[:date].to_s }
    
    # Trend çizgisi için basit lineer regresyon
    n = prices.size
    x_values = (0...n).to_a
    sum_x = x_values.sum
    sum_y = prices.sum
    sum_xy = x_values.zip(prices).map { |x, y| x * y }.sum
    sum_xx = x_values.map { |x| x * x }.sum
    
    # Eğim ve kesişim hesapla
    slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x).to_f
    intercept = (sum_y - slope * sum_x) / n.to_f
    
    # Trend çizgisi
    trend_line = x_values.map { |x| [dates[x], (intercept + slope * x).round(2)] }
    
    # Kanal genişliği için standart sapma kullan
    deviations = []
    x_values.each do |x|
      predicted = intercept + slope * x
      actual = prices[x]
      deviations << (actual - predicted).abs
    end
    
    channel_width = deviations.sum / deviations.size.to_f
    
    # Üst ve alt kanal çizgileri
    upper_channel = x_values.map { |x| [dates[x], (intercept + slope * x + channel_width).round(2)] }
    lower_channel = x_values.map { |x| [dates[x], (intercept + slope * x - channel_width).round(2)] }
    
    {
      trend: slope > 0 ? 'rising' : 'falling',
      trend_line: trend_line,
      upper_channel: upper_channel,
      lower_channel: lower_channel
    }
  end
end