require 'discordrb'

BOT_PREFIX = "rubi"

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} art .+/i) do |event|
  get_sankaku_post(event, "+")
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} ero .+/i) do |event|
  next if event.server.id.to_s == ENV.fetch('CANELE_ID')
  get_sankaku_post(event, "+-")
end

def strip_tags(tags)
  truncate_embed_field(tags.to_s.gsub(/["+]|[\[+]|[\]+]/, ""), 500)
end

def truncate_embed_field(string, max)
  string.length > max ? "#{string[0...max]}..." : string
end

def get_sankaku_post(event, rating)
  m = event.message.content
  tags = m[BOT_PREFIX.length+5..m.length].gsub(/, ?/, "+").gsub(/ /, "_")
  response = HTTParty.get("https://capi-beta.sankakucomplex.com/post/index.json?tags=#{tags}#{rating}rating:safe&login=#{ENV.fetch("SANKAKU_USER")}&password_hash=#{ENV.fetch("SANKAKU_PASS")}")

  if response.none?
    event.respond "No image found"
    return
  elsif response.kind_of?(Hash) && response["success"] == false
    event.respond("Search failed with following error: " << response["reason"])
    return
  end

  post = response.sample

  image_url = "https:" << post["file_url"]
  preview_url = "https:" << post["preview_url"]
  artist_tags=[]
  content_tags=[]
  copyright_tags=[]
  character_tags=[]
  studio_tags=[]
  other_tags=[]

  post["tags"].each do |tag|
    case tag["type"]
    when 0
      content_tags << tag["name"]
    when 4
      character_tags << tag["name"]
    when 3
      copyright_tags << tag["name"]
    when 1
      artist_tags << tag["name"]
    when 2
      studio_tags << tag["name"]
    else
      other_tags << tag["name"]
    end
  end

  event.channel.send_embed do |embed|
    embed.title = "Original full-size image here"
    embed.url = image_url
    embed.add_field(name: "Copyright tags", value: strip_tags(copyright_tags), inline: false) if copyright_tags.any?
    embed.add_field(name: "Character tags", value: strip_tags(character_tags), inline: false) if character_tags.any?
    embed.add_field(name: "Artist tags", value: strip_tags(artist_tags), inline: false) if artist_tags.any?
    embed.add_field(name: "Studio tags", value: strip_tags(studio_tags), inline: false) if studio_tags.any?
    embed.add_field(name: "Content tags", value: strip_tags(content_tags), inline: false) if content_tags.any?
    embed.add_field(name: "Other tags", value: strip_tags(other_tags), inline: false) if other_tags.any?
    embed.image = { url: preview_url }
  end
end

bot.run