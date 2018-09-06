require 'discordrb'
require 'google_custom_search_api'
require 'nokogiri'
require 'yaml'
require 'yaml/store'
require 'markov-polo'

BOT_PREFIX = "rubi"
google_api = true
last_tracked_channel = 0

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')
chain = MarkovPolo::Chain.new
chain << "bunnies are the best"

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
    embed.add_field(name: "Reddit - #{BOT_PREFIX} reddit <subreddit> (#)", value: "Return a reddit post from the requested subreddit. Can suffix a 1-9 number for multiple results.", inline: false)
    embed.add_field(name: "Question - #{BOT_PREFIX} question <your question>", value: "Give a positive or negative answer.", inline: false)
    embed.add_field(name: "Decide/Choose - #{BOT_PREFIX} decide|choose <a>/<b>", value: "Choose from one of the given inputs. Any number of choices can be received.", inline: false)
    embed.add_field(name: "Art - #{BOT_PREFIX} art <image tags>", value: "Post image from Sankaku based on given tags. Separate multiple tags with commas, max 8 tags. Tags must match Sankaku's format.", inline: false)
    embed.add_field(name: "Ero - #{BOT_PREFIX} ero <image tags>", value: "NSFW! Otherwise same as **Art**.", inline: false)
    embed.add_field(name: "Youtube - #{BOT_PREFIX} yt|youtube <input>", value: "Post a Youtube video result. Requests limited to 100 per day.")
    embed.add_field(name: "Anime - #{BOT_PREFIX} anime <title>", value: "Return AniDB entry for matching title. AniDB requests limited to one per 5s.", inline: false)
    embed.add_field(name: "Markov - #{BOT_PREFIX} markov (#)", value: "Generate sentences via markov chain from messages seen in channels. Can suffix a 1-9 number for multiple results.", inline: false)
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
  key = m[BOT_PREFIX.length+6..m.length].downcase.sub('!', '')
  if key == "me"
    key = "<@#{event.message.user.id}>"
  else
    event.channel.users.each do |u|
      u_nick = u.nick || u.name
      key = "<@#{u.id}>" if u.name.downcase.include?(key) || u_nick.downcase.include?(key)
    end
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

bot.message(content: /.*@everyone.*/i) do |event|
  event.message.react("a:pingdoge:446087751092404244")
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

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} reddit .+/i) do |event|
  m = event.message.content
  if m =~ /.+ [1-9]/
    count = m[m.length-1].to_i
    subreddit = m[BOT_PREFIX.length+8..m.length-3]
  else
    count = 1
    subreddit = m[BOT_PREFIX.length+8..m.length]
  end
  posts = HTTParty.get(
    "https://www.reddit.com/r/#{subreddit}/new.json?sort=new&limit=100",
    format: :json,
    headers: { "User-agent" => "Chronibot" }
  )["data"]["children"].map { |p| p["data"] }
  posts.sample(count).each do |post|
    event.respond "#{post['title']} - #{post['url']}"
  end
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

bot.message do |event|
  m = event.message.content
  if event.channel.id == 439700683990630402
    bot.send_message("478918445132546068", "#{event.author.display_name}: #{m}")
    bot.send_message("478918445132546068", event.message.attachments.last.url) if event.message.attachments.any?
  end
  chain << m unless m.downcase.start_with?("#{BOT_PREFIX} ", "!", "=", "&", "p!", ":", "<", "\\", "http") || /^[0-9]+$/.match?(m) || m.length < 10 || event.server.id == ENV.fetch("REZIDENCA_ID").to_i
  if rand < 0.005
    markov_response = chain.generate
    event.respond markov_response
    bot.send_message("478918445132546068", "Rubine: #{markov_response}") if event.channel.id == 439700683990630402
  end

  # channel tracker
  ignore_servers = [448750750437474306,470061749350039552,351157784923996170,434769061575000087]
  next if event.server.nil?
  next if ignore_servers.include?(event.server.id)
  bot.send_message("484262673777950721", "#{event.server.name}/##{event.channel.name} - #{event.channel.id}") unless event.channel.id == last_tracked_channel
  last_tracked_channel = event.channel.id
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} markov.*/i) do |event|
  m = event.message.content
  i = 1
  i = m[m.length-1].to_i if m[m.length-1] =~ /[1-9]/
  i.times do
    event.respond chain.generate
  end
end

bot.pm do |event|
  unless event.message.user.id == ENV.fetch("MY_ID").to_i
    bot.user(ENV.fetch("MY_ID")).pm("PM from #{event.message.user.name}: #{event.message.content}")
    bot.user(ENV.fetch("MY_ID")).pm(event.message.attachments.last.url) if event.message.attachments.any?
  end
end

bot.run