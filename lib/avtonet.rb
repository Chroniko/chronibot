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

  def engine
    to_field("Motor", engine_text)
  end

  def fuel
    to_field("Gorivo", fuel_text)
  end

  def gearbox
    to_field("Menjalnik", gearbox_text)
  end

  def photo_url
    doc.at_css("#BigPhoto").attr("src")
  end

  private

  def title_text
    doc.at_css(".container h3").text.strip
  end

  def price_text
    doc.at_css(".card-body p").text.strip
  end

  def odometer_text
    extract_content_from_row(".container table tr", /km:$/)
  end

  def year_text
    [
      extract_content_from_row(".container table tr", /proizvodnje:$/),
      extract_content_from_row(".container table tr", /registracija:$/i),
      extract_content_from_row(".container table tr", /starost:$/i),
    ].find("") { |result| !result.empty? }
  end

  def engine_text
    extract_content_from_row(".container table tr", /motor:$/i)
      .gsub(/\s+/, " ")
  end

  def fuel_text
    extract_content_from_row(".container table tr", /gorivo:$/i)
      .sub(/\s*motor\s*/, " ")
  end

  def gearbox_text
    extract_content_from_row(".container table tr", /menjalnik:$/i)
      .sub(/\s*menjalnik\s*/, " ")
  end

  private

  def to_field(name, value, inline: true)
    if value.empty?
      value = "-"
    end

    { name: name, value: value, inline: inline }
  end

  def extract_content_from_row(css, regex)
    doc.css(css).each do |tr|
      th = tr.at_css("th")
      if th&.text =~ regex
        return tr.at_css("td")&.text&.strip.to_s
      end
    end
    ""
  end
end
