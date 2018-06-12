require 'discordrb'
require 'google_custom_search_api'
require 'yaml'

BOT_PREFIX = "rubi"
google_api = true

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')

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
    embed.add_field(name: "Art - #{BOT_PREFIX} art <image tag>", value: "Post image from danbooru based on given (single) tag. Tag must match danbooru's format.", inline: false)
    embed.add_field(name: "Ero - #{BOT_PREFIX} ero <image tag>", value: "NSFW! Otherwise same as **Art**.", inline: false)
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
  m = event.message.content
  tag = m[BOT_PREFIX.length+5..m.length].gsub(/[ +]/, "_")
  if ["loli", "lolicon", "toddlercon", "shota"].include?(tag)
    tag = ["chroniko", "francesca_lucchini"].sample
  end
  response = HTTParty.get("https://danbooru.donmai.us/posts.json?tags=#{tag} rating:safe")
  body = YAML.load(response.body)
  if body == []
    event.respond "No image found"
  elsif body.kind_of?(Hash) && body["success"] == false
    event.respond "No image found"
  else
    event.respond body.sample["file_url"]
  end
end

bot.message(content: /#{Regexp.quote(BOT_PREFIX)} ero .+/i) do |event|
  next if event.server.id.to_s == ENV.fetch('CANELE_ID')
  m = event.message.content
  tag = m[BOT_PREFIX.length+5..m.length].gsub(/[ +]/, "_")
  if ["loli", "lolicon", "toddlercon", "shota"].include?(tag)
    tag = ["chroniko", "francesca_lucchini"].sample
  end
  response = HTTParty.get("https://danbooru.donmai.us/posts.json?tags=#{tag} -rating:safe")
  body = YAML.load(response.body)
  if body == []
    event.respond "No image found"
  elsif body.kind_of?(Hash) && body["success"] == false
    event.respond "No image found"
  else
    event.respond body.sample["file_url"]
  end
end

bot.run