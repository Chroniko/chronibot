require 'discordrb'
require 'google_custom_search_api'
require 'nokogiri'
require 'yaml'
require 'yaml/store'

BOT_PREFIX = "rubi"
google_api = true

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')

lite_db = YAML::Store.new "lite_db.store"
lite_db.transaction do
  lite_db["anidb"] = { "last_query_at" => Time.now }
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} help/i) do |event|
  event.respond "Thank you for using #{bot.profile.name} services. <:botblush:456053146737967115>"
  event.channel.send_embed do |embed|
    embed.title = "Bot commands:"
    embed.add_field(name: "Help - #{BOT_PREFIX} help", value: "List bot commands", inline: false)
    embed.add_field(name: "Name - #{BOT_PREFIX} name <new name>", value: "Give me a new name (owners only).", inline: false)
    embed.add_field(name: "Rate - #{BOT_PREFIX} rate <ratee>", value: "Rate something 0-10.", inline: false)
    embed.add_field(name: "Image - #{BOT_PREFIX} image <input>", value: "Post a google images result. Requests limited to 200 per day.", inline: false)
    embed.add_field(name: "Animate - #{BOT_PREFIX} animate <input>", value: "Post an animated google images result. Shares **Image**'s request limit.", inline: false)
    embed.add_field(name: "Question - #{BOT_PREFIX} question <your question>", value: "Give a positive or negative answer.", inline: false)
    embed.add_field(name: "Decide/Choose - #{BOT_PREFIX} decide|choose <a>/<b>", value: "Choose from one of the given inputs. Any number of choices can be received.", inline: false)
    embed.add_field(name: "Art - #{BOT_PREFIX} art <image tags>", value: "Post image from Sankaku based on given tags. Separate multiple tags with commas, max 8 tags. Tags must match Sankaku's format.", inline: false)
    embed.add_field(name: "Ero - #{BOT_PREFIX} ero <image tags>", value: "NSFW! Otherwise same as **Art**.", inline: false)
    embed.add_field(name: "Youtube - #{BOT_PREFIX} yt|youtube <input>", value: "Post a Youtube video result. Requests limited to 100 per day.")
    embed.add_field(name: "Anime - #{BOT_PREFIX} anime <title>", value: "Return AniDB entry for matching title. AniDB requests limited to one per 5s.", inline: false)
  end
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} name .+/i) do |event|
  if event.user.id.to_s == ENV.fetch('MY_ID')
    m = event.message.content
    key = m[BOT_PREFIX.length+6..m.length]

    bot.profile.name = key
  else
    event.respond "<:miyanofu:443849528102223873>"
  end
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} rate .+/i) do |event|
  m = event.message.content
  key = m[BOT_PREFIX.length+6..m.length].downcase

  if key == "me"
    key = "<@!#{event.message.user.id}>"
  end

  seed = Time.now.to_date.iso8601
  key << seed

  rating = Digest::MD5.hexdigest(key).to_i(16) % 11
  event.respond "#{rating}/10"
end

bot.message(content: /.*go+d *bo+t.*/i) do |event|
  event.message.react("oowwoaaa:435243426913714177")
end

bot.message(content: /.*ba+d *bo+t.*|.*\<\:GWchadMEGATHINK\:366999806343774218\>.*|.*\<\:Think\:357607104418283522\>.*|.*\<\:think\:443803808259244032\>.*/i) do |event|
  event.message.react("miyanofu:443849528102223873")
end

bot.message(content: /.*(´･ω･`).*/i) do |event|
  event.respond [
    "DENKO RUN",
    "SAVE YOURSELF, DENKO",
    "DENKO HIDE QUICKLY"
  ].sample if Random.rand > 0.2
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} image .+/i) do |event|
  if google_api
    GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY")
    GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX")
  else
    GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY_2")
    GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX_2")
  end
  google_api = !google_api
  m = event.message.content
  key = m[BOT_PREFIX.length+7..m.length].downcase

  results = GoogleCustomSearchApi.search(key, searchType: "image")
  event.respond results["items"].sample["link"]
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} animate .+/i) do |event|
  if google_api
    GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY")
    GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX")
  else
    GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY_2")
    GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX_2")
  end
  google_api = !google_api
  m = event.message.content
  key = m[BOT_PREFIX.length+9..m.length].downcase

  results = GoogleCustomSearchApi.search(key, searchType: "image", fileType: "gif")
  event.respond results["items"].sample["link"]
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} question .+/i) do |event|
  m = event.message.content
  key = m[BOT_PREFIX.length+10..m.length].downcase

  seed = Time.now.to_date.iso8601
  key << seed

  answer = Digest::MD5.hexdigest(key).to_i(16) % 2
  if answer == 1
    event.respond ["Yes, indeed.", "Yeah", "Sure", "Why not", "Totally."].sample
  else
    event.respond ["Definitely not.", "Nope", "No", "Don't think so."].sample
  end
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} (decide|choose) .+(\/.+)+/i) do |event|
  m = event.message.content
  event.respond m[BOT_PREFIX.length+8..m.length].split("/").sample
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} art .+/i) do |event|
  get_sankaku_post(event, "+")
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} ero .+/i) do |event|
  next if event.server.id.to_s == ENV.fetch('CANELE_ID')
  get_sankaku_post(event, "+-")
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} (yt|youtube) .+/i) do |event|
  GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY_3")
  GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX_3")
  m = event.message.content
  if m[BOT_PREFIX.length+2] == 't'
    key = m[BOT_PREFIX.length+4..m.length]
  else
    key = m[BOT_PREFIX.length+9..m.length]
  end
  results = GoogleCustomSearchApi.search(key)
  event.respond results["items"].sample["link"]
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} anime .+/i) do |event|
  yml = YAML.load_file('lite_db.store')
  if yml["anidb"]["last_query_at"] > Time.now - 5
    event.respond "Please do not spam AniDB requests."
  else
    m = event.message.content
    key = m[BOT_PREFIX.length+7..m.length]
    anime_search = Nokogiri::XML(HTTParty.get("http://anisearch.outrance.pl/?task=search&query=\\#{key}").to_s)
    anime_search = Nokogiri::XML(HTTParty.get("http://anisearch.outrance.pl/?task=search&query=#{key}").to_s) if anime_search.xpath("//animetitles//anime/@aid").first.nil?
    anime_id = anime_search.xpath("//animetitles//anime/@aid").first
    if anime_id.nil?
      event.respond "No such anime found"
    else
      anidb_result = Nokogiri::XML(HTTParty.get("http://api.anidb.net:9001/httpapi?client=chronibot&clientver=1&protover=1&request=anime&aid=#{anime_id}").to_s)
      lite_db.transaction do
        lite_db["anidb"] = { "last_query_at" => Time.now }
      end
      anime = anidb_result.xpath("//anime")
      main_title = anime.xpath("//titles/title").first.content
      type = anime.xpath("//type").first.content
      ep_count = anime.xpath("//episodecount").first.content
      start_date = anime.xpath("//startdate").first.content
      end_date = anime.xpath("//enddate").first.content
      desc = anime.xpath("//description").first.content

      if google_api
        GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY")
        GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX")
      else
        GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY_2")
        GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX_2")
      end
      google_api = !google_api
      results = GoogleCustomSearchApi.search("#{main_title} anime", searchType: "image")

      event.channel.send_embed do |embed|
        embed.title = main_title
        embed.url = "http://anidb.net/a#{anime_id}"
        embed.add_field(name: "Type", value: "#{type}, #{ep_count} ep", inline: false)
        embed.add_field(name: "Year", value: "#{start_date} - #{end_date}", inline: false)
        embed.add_field(name: "Description", value: desc, inline: false)
        embed.image = { url: results["items"].first["link"] }
      end
    end
  end
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