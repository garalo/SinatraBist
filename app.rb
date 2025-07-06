require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'mongo'
require 'json'
require 'httparty'
require 'nokogiri'
require 'chartkick'
require 'dotenv/load'
require_relative 'lib/bist_data_fetcher'
require_relative 'lib/stock_analyzer'
require_relative 'lib/db_manager'

# Uygulama yapılandırması
configure do
  set :db_manager, DBManager.new('bist_stocks')
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/views'
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
  set :protection, :except => [:json_csrf]
end

# Helper metodlar
helpers do
  # Sayıları binlik ayırıcı ile formatlar (Rails'in number_with_delimiter metodu benzeri)
  def number_with_delimiter(number, delimiter = ",", separator = ".")
    return number.to_s unless number.is_a?(Numeric) || (number.is_a?(String) && number =~ /\A[+-]?\d+(\.\d+)?\z/)
    
    number = number.to_s.gsub(/\A\D+/, '').gsub(/\D+\z/, '')
    
    # Ondalık kısmı ayır
    integer_part, decimal_part = number.split('.')
    
    # Binlik ayırıcı ekle
    integer_part = integer_part.gsub(/(?<=\d)(?=(\d\d\d)+(?!\d))/, delimiter)
    
    # Ondalık kısım varsa birleştir
    decimal_part ? "#{integer_part}#{separator}#{decimal_part}" : integer_part
  end
end

# Ana sayfa
get '/' do
  @stocks = settings.db_manager.get_all_stocks
  erb :index
end

# BIST verilerini güncelle
get '/update_stocks' do
  fetcher = BistDataFetcher.new
  stocks_data = fetcher.fetch_all_stocks
  
  if stocks_data.empty?
    session[:error] = "Hisse verileri güncellenemedi. Lütfen daha sonra tekrar deneyin."
  else
    # Verileri MongoDB'ye kaydet
    settings.db_manager.upsert_stocks(stocks_data)
    session[:success] = "#{stocks_data.size} hisse verisi başarıyla güncellendi."
  end
  
  redirect '/'
end

# Belirli bir hissenin detayları
get '/stock/:symbol' do
  @symbol = params[:symbol]
  @stock = settings.db_manager.get_stock(@symbol)
  
  if @stock.nil?
    session[:error] = "Hisse senedi bulunamadı: #{@symbol}"
    redirect '/'
  end
  
  @analyzer = StockAnalyzer.new(@stock)
  @trend = @analyzer.analyze_trend
  erb :stock_detail
end

# Yükselen hisseler
get '/rising_stocks' do
  @rising_stocks = settings.db_manager.get_rising_stocks
  erb :rising_stocks
end

# Düşen hisseler
get '/falling_stocks' do
  @falling_stocks = settings.db_manager.get_falling_stocks
  erb :falling_stocks
end

# API endpoint - Tüm hisseler
get '/api/stocks' do
  content_type :json
  settings.db_manager.get_all_stocks.to_json
end

# API endpoint - Belirli bir hisse
get '/api/stock/:symbol' do
  content_type :json
  stock = settings.db_manager.get_stock(params[:symbol])
  halt 404, { error: 'Hisse bulunamadı' }.to_json if stock.nil?
  stock.to_json
end