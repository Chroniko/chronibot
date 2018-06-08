require 'discordrb'
require 'google_custom_search_api'

GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY")
GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX")

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')

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
  m = event.message.content
  key = m[9..m.length].downcase

  results = GoogleCustomSearchApi.search(key, searchType: "image")
  event.respond results["items"].sample["link"]
end

bot.run