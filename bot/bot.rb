require 'discordrb'
require 'google_custom_search_api'
require 'yaml'

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')

google_api = true

bot.message(content: /bot rate .+/i) do |event|
  m = event.message.content
  key = m[9..m.length].downcase

  if key == "me"
    key = "<@!#{event.message.user.id}>"
  end

  seed = Time.now.to_date.iso8601
  key << seed

  rating = Digest::MD5.hexdigest(key).to_i(16) % 11
  event.respond "#{rating}/10"
end

bot.message(content: /go+d *bo+t/i) do |event|
  event.message.react("oowwoaaa:435243426913714177")
end

bot.message(content: /ba+d *bo+t|\<\:GWchadMEGATHINK\:366999806343774218\>|\<\:Think\:357607104418283522\>|\<\:think\:443803808259244032\>/i) do |event|
  event.message.react("miyanofu:443849528102223873")
end

bot.message(content: /.*(´･ω･`).*/i) do |event|
  event.respond [
    "DENKO RUN",
    "SAVE YOURSELF, DENKO",
    "DENKO HIDE QUICKLY"
  ].sample if Random.rand > 0.2
end

bot.message(content: /image .*/i) do |event|
  if google_api
    GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY")
    GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX")
  else
    GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY_2")
    GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX_2")
  end
  google_api = !google_api
  m = event.message.content
  key = m[6..m.length].downcase

  results = GoogleCustomSearchApi.search(key, searchType: "image")
  event.respond results["items"].sample["link"]
end

bot.message(content: /chrquestion .*/i) do |event|
  m = event.message.content
  key = m[13..m.length].downcase

  seed = Time.now.to_date.iso8601
  key << seed

  answer = Digest::MD5.hexdigest(key).to_i(16) % 2
  if answer == 1
    event.respond ["Yes, indeed.", "Yeah", "Sure", "Why not", "Totally."].sample
  else
    event.respond ["Definitely not.", "Nope", "No", "Don't think so."].sample
  end
end

bot.message(content: /chrdecide .*\/.*(\/.*)*/i) do |event|
  m = event.message.content
  event.respond m[10..m.length].split("/").sample
end

bot.message(content: /chrbooru .*/i) do |event|
  m = event.message.content
  tag = m[9..m.length].downcase.gsub(/[ +]/, "_")
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

bot.message(content: /chrporn .*/i) do |event|
  m = event.message.content
  tag = m[8..m.length].downcase.gsub(/[ +]/, "_")
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