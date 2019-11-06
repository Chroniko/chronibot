require 'discordrb'
require 'google_custom_search_api'
require 'nokogiri'
require 'yaml'
require 'yaml/store'
require 'redis'
require 'htmlentities'

require_relative '../lib/imgur'
require_relative '../lib/markov-polo'
require_relative '../lib/player_order'
require_relative '../lib/player_order_store'
require_relative '../lib/spoilers'

BOT_PREFIX = "rubi"
google_api = true
last_tracked_channel = 0

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')
redis = Redis.new(url: ENV.fetch('REDIS_URL'))

redis_chain = redis.get("chain")
chain = redis_chain ? MarkovPolo::Chain.new(JSON.parse(redis_chain)) : MarkovPolo::Chain.new
chain << "bunnies are the best" if chain.to_h.empty?
redis_reverse_chain = redis.get("reverse_chain")
reverse_chain = redis_reverse_chain ? MarkovPolo::Chain.new(JSON.parse(redis_reverse_chain)) : MarkovPolo::Chain.new
reverse_chain >> "bunnies are the best" if reverse_chain.to_h.empty?

answers = Hash.new
wrong_answers = Hash.new
last_wrong_answerer = Hash.new

lite_db = YAML::Store.new "lite_db.store"
lite_db.transaction do
  lite_db["anidb"] = { "last_query_at" => Time.now }
end

def quoted_prefix
  Regexp.quote(BOT_PREFIX)
end

bot.message(content: /#{quoted_prefix} help/i) do |event|
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
    embed.add_field(name: "Markov - #{BOT_PREFIX} markov (<key>) (#)", value: "Generate sentences via markov chain from messages seen in channels. Optional key which to start generating sentences from. Variants: remarkov - generates sentence from key backwards, mmarkov - generates sentence from key both ways. Can suffix a 1-9 number for multiple results.", inline: false)
    embed.add_field(name: "Racing - #{BOT_PREFIX} racing|spoilers [+N]", value: "Show motorports events for this week. Append +1 for next week, etc.", inline: false)
  end
end

bot.message(content: /#{quoted_prefix} name .+/i) do |event|
  if event.user.id.to_s == ENV.fetch('MY_ID')
    m = event.message.content
    key = m[BOT_PREFIX.length+6..m.length]

    bot.profile.name = key
  else
    event.respond "<:miyanofu:443849528102223873>"
  end
end

bot.message(content: /#{quoted_prefix} rate .+/i) do |event|
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

bot.message(content: /#{quoted_prefix} image .+/i) do |event|
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

bot.message(content: /#{quoted_prefix} animate .+/i) do |event|
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

bot.message(content: /#{quoted_prefix} reddit .+/i) do |event|
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

bot.message(content: /#{quoted_prefix} question .+/i) do |event|
  m = event.message.content
  key = m[BOT_PREFIX.length+10..m.length].downcase

  seed = Time.now.to_date.iso8601
  key << seed

  if Digest::MD5.hexdigest(key).to_i(16).odd?
    event.respond ["Yes, indeed.", "Yeah", "Sure", "Why not", "Totally."].sample
  else
    event.respond ["Definitely not.", "Nope", "No", "Don't think so."].sample
  end
end

bot.message(content: /#{quoted_prefix} (decide|choose) .+(\/.+)+/i) do |event|
  m = event.message.content
  event.respond m[BOT_PREFIX.length+8..m.length].split("/").sample
end

bot.message(content: /#{quoted_prefix} (yt|youtube) .+/i) do |event|
  GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY_3")
  GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX_3")
  m = event.message.content
  if m[BOT_PREFIX.length+2] == 't'
    key = m[BOT_PREFIX.length+4..m.length]
  else
    key = m[BOT_PREFIX.length+9..m.length]
  end
  results = GoogleCustomSearchApi.search(key)
  event.respond results["items"].first(3).sample["link"]
end

bot.message(content: /#{quoted_prefix} anime .+/i) do |event|
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

->(event) do
  week_offset = event.message.content[/\+(\d)$/, 1].to_i

  spoilers = Spoilers.new(week_offset: week_offset)

  event.channel.send_embed do |embed|
    embed.title = spoilers.title
    embed.color = "36513e"

    spoilers.current_events.each do |e|
      embed.add_field(name: e.category, value: e.name, inline: true)
    end
  end
end.tap do |spoilers|
  bot.message(content: /#{quoted_prefix} (spoilers|racing)(.*)/i, &spoilers)
  bot.message(content: /.*There are.+events? this week.*/) do |event|
    if event.message.user.name == "Rushsync"
      spoilers.(event)
    end
  end
end

bot.message(content: /#{quoted_prefix} hammer .+/i) do |event|
  event.respond [
    "https://s3.amazonaws.com/s3.userdata.www.universalsubtitles.org/video/thumbnail/77dc435db61bfc75bf773fd334bbc957ab1c707f.jpg",
    "https://nefariousreviews.files.wordpress.com/2018/04/city-hunter-hammer.jpg",
    "https://i.pinimg.com/236x/44/7a/e7/447ae7ab9cd9ab0d0a515b872206177c--city-hunter-angel-heart.jpg",
    "https://img.fireden.net/a/image/1506/21/1506215921521.jpg",
    "http://orig13.deviantart.net/0a64/f/2010/263/8/a/coup_de_massue___rendu_final_by_statealchemist86-d2z51bg.jpg",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ7H6T24YcowhqZHo8G-c1xdD5owsUutE8w3gDMT9-qAmjXELdI",
    "https://i.pinimg.com/236x/71/88/37/7188378593322d0f789e8db0985cbe37--city-hunter.jpg",
    "http://www.iamfatterthanyou.com/blog/wp-content/uploads/2012/06/ch3.jpg",
    "https://i.pinimg.com/originals/39/dd/14/39dd148a23088054a6e78276c19f0eed.jpg",
  ].sample
end

BOARDGAME_PLAYER_IDS = {
  chrono: 268723800030445569,
  darjo: 367573587055476737,
  fire: 400021825637187586,
  njok: 448954998219341824,
}

# User mentions look like this: "<@448954998219341824>"
def mention(player_id)
  "<@#{player_id}>"
end

bot.message(content: /board init.+/) do |event|
  player_ids = event.message.content.scan(/<@(\d+)>/).flatten
  if player_ids.any?
    player_order = PlayerOrder.new(player_ids)
    PlayerOrderStore.set(channel: event.channel, value: player_order)
  end
  event.respond ":boar: :thumbsup:"
end

bot.message(content: /board next/) do |event|
  if player_order = PlayerOrderStore.get(channel: event.channel)
    next_player_id = player_order.next_player
    new_order = player_order.advance
    PlayerOrderStore.set(channel: event.channel, value: new_order)

    event.respond(mention(next_player_id))
  else
    event.respond(":boar: :warning: Unable to determine next player")
  end
end

bot.message do |event|
  m = event.message.content

  # logging
  if event.channel.id == 439700683990630402
    bot.send_message("478918445132546068", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("478918445132546068", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 388334487894884364
    bot.send_message("487946041937625104", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("487946041937625104", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 388417506513256463
    bot.send_message("487946082999861248", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("487946082999861248", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 388410901000355841
    bot.send_message("487946133793013771", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("487946133793013771", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 470313907387498506
    bot.send_message("488247507982221323", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488247507982221323", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 388419594437787659
    bot.send_message("488249218188967947", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488249218188967947", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 388419621390385153
    bot.send_message("488250079317327873", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488250079317327873", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 388417570044117003
    bot.send_message("488274686480875522", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488274686480875522", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 389985087665602560
    bot.send_message("488277875234045952", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488277875234045952", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 405490106573783041
    bot.send_message("488279957420769282", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488279957420769282", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 405831095029071872
    bot.send_message("488280775096008704", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488280775096008704", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 433765499407564820
    bot.send_message("488284688339828736", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488284688339828736", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 470261896432451585
    bot.send_message("488290626572648469", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("488290626572648469", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 511228429887078410
    bot.send_message("513011290382270464", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("513011290382270464", event.message.attachments.last.url) if event.message.attachments.any?
  elsif event.channel.id == 388410837116649474
    bot.send_message("513011169246707714", "[#{event.message.timestamp.strftime("%H:%M")}] #{event.author.display_name}: #{m}")
    bot.send_message("513011169246707714", event.message.attachments.last.url) if event.message.attachments.any?
  end

  # markov
  unless m.downcase.start_with?("#{BOT_PREFIX} ", "!", "=", "&", "p!", ":", "$", "<", "\\", "http") || /^[0-9]+$/.match?(m) || m.length < 10 || event.server.id == ENV.fetch('REZIDENCA_ID').to_i
    chain << m
    redis.set("chain", chain.to_h.to_json)
    reverse_chain >> m
    redis.set("reverse_chain", reverse_chain.to_h.to_json)
  end
  if rand < 0.01
    event.respond chain.markov unless [ENV.fetch('CANELE_ID'), ENV.fetch('VANGUARD_ID'), ENV.fetch('REZIDENCA_ID')].include?(event.server.id.to_s)
  end

  # channel tracker
  ignore_servers = [448750750437474306,470061749350039552,351157784923996170,434769061575000087]
  next if event.server.nil?
  next if ignore_servers.include?(event.server.id)
  bot.send_message("484262673777950721", "#{event.server.name}/##{event.channel.name} - #{event.channel.id}") unless event.channel.id == last_tracked_channel
  last_tracked_channel = event.channel.id
end

bot.message(content: /#{quoted_prefix} (markov|remarkov|mmarkov).*/i) do |event|
  m = event.message.content
  i = 1
  i = m[-1].to_i if m[-1] =~ /[1-9]/
  key = m.split[2] unless m.split[2] =~ /^[0-9]+$/
  i.times do
    case m.split[1]
    when "markov"
      event.respond chain.markov(key)
    when "remarkov"
      event.respond reverse_chain.remarkov(key)
    when "mmarkov"
      tail = chain.markov(key)
      head = reverse_chain.remarkov(key)[/(.*)\s/,1]
      event.respond([head, tail].join " ")
    end
  end
end

bot.message(content: /#{quoted_prefix} silence.*/i) do |event|
  client = Imgur.new(ENV['CLIENT_ID'])
  event.respond("#{client.get_album("HJAUs1m").images.sample.link}?t=#{SecureRandom.hex(8)}")
end

bot.pm do |event|
  if event.message.user.id == ENV.fetch("MY_ID").to_i
    m = event.message.content
    if m.split[0] == "send"
      bot.send_message(m.split[1], m.split[2..-1].join(" "))
    elsif ["pm", "dm"].include?(m.split[0])
      bot.user(m.split[1]).pm(m.split[2..-1].join(" "))
    end
  else
    bot.user(ENV.fetch("MY_ID")).pm("PM from #{event.message.user.name}: #{event.message.content}")
    bot.user(ENV.fetch("MY_ID")).pm(event.message.attachments.last.url) if event.message.attachments.any?
  end
end

bot.message(content: /#{quoted_prefix} quiz.*/i) do |event|
  result = JSON.parse(HTTParty.get("https://opentdb.com/api.php?amount=1&type=multiple").body)["results"][0]
  answers[event.server.id.to_s] = HTMLEntities.new.decode(result["correct_answer"].downcase)
  wrong_answers[event.server.id.to_s] = result["incorrect_answers"]
    .map { |incorrect| HTMLEntities.new.decode(incorrect.downcase) }
  $quiz_answer_points = 2
  last_wrong_answerer[event.server.id.to_s] = nil
  event.respond(HTMLEntities.new.decode(result["question"]))

  Thread.new do
    sleep 10
    next unless answers[event.server.id.to_s]
    event.respond(HTMLEntities.new.decode(([result["correct_answer"]] + result["incorrect_answers"]).shuffle.join("\n")))
    $quiz_answer_points = 1
  end
end

# Quiz answers
bot.message do |event|
  m = event.message.content
  if m.downcase == answers[event.server.id.to_s]
    if event.message.user.id == last_wrong_answerer[event.server.id.to_s]
      event.respond("Cannot try to answer twice in a row.")
    else
      answers[event.server.id.to_s] = nil
      last_wrong_answerer[event.server.id.to_s] = nil

      redis.set("quiz_points", "{}") unless redis.get("quiz_points")
      quiz_points = JSON.parse(redis.get("quiz_points"))
      quiz_points[event.server.id.to_s] = {} unless quiz_points[event.server.id.to_s]
      quiz_points[event.server.id.to_s][event.message.user.id.to_s] =
        quiz_points[event.server.id.to_s][event.message.user.id.to_s].to_i + $quiz_answer_points
      redis.set("quiz_points", quiz_points.to_json)

      event.respond("Correct, #{event.message.user.name}!")
      event.respond(quiz_points[event.server.id.to_s].sort_by(&:last).reverse
        .map { |user_id, value| "*#{bot.user(user_id).name}*: #{value}" }.join("\n"))
    end

  elsif wrong_answers[event.server.id.to_s] &.include?(m.downcase)
    if event.message.user.id == last_wrong_answerer[event.server.id.to_s]
      event.respond("Cannot try to answer twice in a row.")
    else
      last_wrong_answerer[event.server.id.to_s] = event.message.user.id
    end
  end
end

bot.run
