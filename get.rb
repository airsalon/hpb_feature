require 'open-uri'
require 'json'
require 'csv'

class Client
  def initialize
    @key = '1d7127b4f4c65e77'
    @format = 'json'
    @count = 100
    @origin = 'http://webservice.recruit.co.jp'
    @search_path = 'beauty/salon/v1'
    @feature_detail_master_path = 'beauty/feature_detail/v1/'
    @default_parameters = {key: @key, format: @format, count: @count}
    @salon_to_row = -> (salon, code) do
      header = ['url', 'name', 'name_kana', 'address', 'access', 'service_area_code', 'middle_area_code', 'small_area_code', 'open', 'close', 'price', 'catch_copy', 'description' 'feature_name', 'feature_description', 'feature_image_url']
      feature = salon['feature'].find { |f| f['code'] == code }
      row = [salon['urls']['pc'], salon['name'], salon['name_kana'], salon['address'], salon['access'], salon['service_area']['name'], salon['middle_area']['name'], salon['small_area']['name'], salon['open'], salon['close'], salon['price'], salon['catch_copy'], salon['description'], feature['name'], feature['description'], feature['photo']['l']]
      CSV::Row.new(header, row)
    end

  end

  def get_feature_detail_codes
    feature_uri = URI.parse(build_url(@feature_detail_master_path))
    JSON.parse(feature_uri.read)['results']['feature_detail'].map { |v| v['code'] }
  end

  def search(code)
    salons = []
    start = 1
    while true
      search_uri = URI.parse(build_url(@search_path, {feature_detail: code, start: start}))
      current_salons = JSON.parse(search_uri.read)['results']['salon']
      break if current_salons.empty?
      salons += current_salons.map{|s| @salon_to_row.call(s, code)}
      start += @count
      sleep(1)
    end
    salons
  end

  private
  def build_url(path, parameter = {})
    param = parameter.merge(@default_parameters)
    @origin + '/' + path + '?' + param.map { |k, v| "#{k}=#{v}" }.join("&")
  end
end

client = Client.new
salons = []

codes = client.get_feature_detail_codes
codes.each do |code|
  STDERR.puts "start #{code}"
  File.write("result-#{code}.csv", CSV::Table.new(client.search(code)).to_csv)
  STDERR.puts "finish #{code}"
end


