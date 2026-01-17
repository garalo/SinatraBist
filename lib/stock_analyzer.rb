class StockAnalyzer
  def initialize(stock_data)
    @stock_data = stock_data
    @history = stock_data['history'] || []
  end

  # Hissenin trendini analiz et
  def analyze_trend
    return 'neutral' if @history.empty?

    prices = @history.map { |h| h['close'] || h[:close] }.compact
    last_price = prices.last
    avg_price = prices.sum / prices.size

    return 'strong_up' if last_price > avg_price * 1.1
    return 'up' if last_price > avg_price
    return 'strong_down' if last_price < avg_price * 0.9
    return 'down' if last_price < avg_price
    'neutral'
  end

  # Hisse için grafik verilerini hazırla
  def prepare_chart_data
    @history.map { |h| [h['date'] || h[:date], h['close'] || h[:close]] }
  end

  # Destek ve direnç seviyelerini hesapla (basit bir örnek)
  def calculate_support_resistance
    return { support_levels: [], resistance_levels: [] } if @history.empty?

    prices = @history.map { |h| h['close'] || h[:close] }.compact
    {
      support_levels: [prices.min],
      resistance_levels: [prices.max]
    }
  end

  # Hareketli ortalama hesapla
  def calculate_moving_average(period)
    return [] if @history.empty?

    prices = @history.map { |h| h['close'] || h[:close] }
    result = []

    prices.each_cons(period) do |window|
      avg = window.sum / period.to_f
      result << [@history[result.size]['date'], avg]
    end

    result
  end
end

