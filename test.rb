require 'discordrb'
require 'google_custom_search_api'
require 'dotenv/load'

GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY")
GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX")

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')








#bot.message(content: ['<:GWchadMEGATHINK:366999806343774218>', '<:Think:357607104418283522>', '<:think:443803808259244032>'] ) do |event|
#  unless event.user.id == MY_ID
#    event.message.delete
#  end
#end

#bot.typing do |event|
#  if event.user.id == 122196782473150464
#    event.user.pm('What are you typing?')
#  end
#end

#bot.message(content: 'who are you bot??') do |event|
#bot.message(content: /nani\? masaka!/i) do |event|
#  m = event.respond "Indeed..."
#  #m.user.nick="Chronibot"
#  event.server.member('442538300884910080').nick="Chronibot"
#  event.respond("It was me all along!")
#end

#bot.message(content: /good bot/i) do |event|
 # event.message.react("oowwoaaa:435243426913714177")
  #event.respond("<:oowwoaaa:435243426913714177>")
#end
#
#bot.message(content: /changemybotname/i) do |event|
#  bot.profile.name = "Chronibot"
#  event.respond("It was me all along!")
#end
#
#bot.message(content: /asd (?<key>.*)$/i) do |event, match|
#  puts match["key"]
#end
#
#bot.message(start_with: /a /i) do |event|
#  #event.user.nick = "tester"
#  m = event.message.content
#  key = m[2..m.length].downcase
#
#  if key == "me"
#    key = "<@!#{event.message.user.id}>"
#  end
#
#  seed = Time.now.to_date.iso8601
#  key << seed
#
#  puts Digest::MD5.hexdigest(key).to_i(16) % 11
#end
#
#bot.message() do |event|
#  if event.user.id == 298116576274808832
#    event.message.delete 
#  end
#end

#bot.message(content: /bot give tommy a space between his name and guild symbol because it really bothered pang and i said i could make the bot do it instead of just talking to him/) do |e|
  #122196782473150464
  #217091781316050946 hawke
#  e.message.channel.users.each do |u|
#    if u.id == 318805677025918976
#      u.nick = "◈ Tommy"
#    end
#  end
#end

bot.run