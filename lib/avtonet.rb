class Avtonet
  AVTONET_PROXY_BASE_URI = URI("http://ananas.filej.net:53888/")

  def self.proxy_uri(uri, proxy_uri = AVTONET_PROXY_BASE_URI)
    uri.scheme = proxy_uri.scheme
    uri.host   = proxy_uri.host
    uri.port   = proxy_uri.port
    uri
  end

  attr_reader :doc

  def initialize(input)
    @doc = Nokogiri::HTML(input)
  end

  def title
    title_text
  end

  def price
    to_field("Cena", price_text)
  end

  def odometer
    to_field("Odometer", odometer_text)
  end

  def year
    to_field("Letnik", year_text)
  end

  def photo_url
    doc.at_css("#BigPhoto").attr("src")
  end

  private

  def title_text
    doc.at_css("div.OglasDataTitle > h1").text.strip
  end

  def price_text
    doc.at_css(".OglasDataCenaTOP").text.strip
  end

  def odometer_text
    doc.at_css(".DataZero2 div:last").text.strip
  end

  def year_text
    doc.at_css("div.OglasData:nth-child(5) > div:nth-child(2)").text.strip
  end

  def to_field(name, value, inline: true)
    if value.empty?
      value = "-"
    end

    { name: name, value: value, inline: inline }
  end
end
