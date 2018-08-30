require 'discordrb'
require 'google_custom_search_api'
require 'dotenv/load'
require 'nokogiri'
require 'yaml/store'
#require 'redis'
require 'markov-polo'

GOOGLE_API_KEY = ENV.fetch("GOOGLE_API_KEY")
GOOGLE_SEARCH_CX = ENV.fetch("GOOGLE_SEARCH_CX")
BOT_PREFIX = "rubi"

bot = Discordrb::Bot.new token: ENV.fetch('BOT_TOKEN')
#redis = Redis.new
chain = MarkovPolo::Chain.new
chain << "<:rooNya:470241461573779457>"

lite_db = YAML::Store.new "lite_db.store"
lite_db.transaction do
  lite_db["anidb"] = { "last_query_at" => Time.now }
  lite_db["last_poke"] = { "at" => Time.now }
end

bot.message(content: /rubi test.*/i) do |event|
  m = event.message.content
  bot.send_message(ENV.fetch("MY_ID").to_i, m)
end

bot.message(content: /rubi (nicky )?nudes/i) do |event|
  next unless [ENV.fetch("MY_ID").to_i, ENV.fetch("NICKY_ID").to_i].include?(event.message.author.id)
  event.message.user.pm("Psssst, hey. My database feels a bit empty, so I could really use any pics you might send this way. Noone's gonna know. <:botwut:482531370254467072>")
end

bot.message(content: /aaaa.*/) do |event|
  next unless ENV.fetch("MY_ID").to_i == event.message.author.id
  event.server.users.each do |u|
    next if u.id == 442538300884910080 # skip self otherwise crash
    p u.name
    u.pm.history(100).each {|m| p m.content }
  end
  #next unless event.channel.id == 439700683990630402
  #p event.message.attachments
  #m = event.message.content
  #p m
  #p user_ids = event.channel.users.map {|u| [u.id, u.name, u.nick]}
  #event.channel.users.each {|u| p u if u.id == ENV.fetch('MY_ID').to_i}
  #p m
  #bot.send_message("478918445132546068", "#{event.author.display_name}: #{m} ##{event.channel.name}: #{event.channel.id}")
end

bot.message do |event|
end

bot.ready do |event|
  c = bot.channel("439700683990630402")
  c.history(100).reverse_each do |m|
    p m.content if m.user.id == 442538300884910080
#    bot.send_message("478918445132546068", m.attachments.last.url) if m.attachments.any?
  end
  #p bot.users#.each do |u|
  #  next if u.id == 442538300884910080
  #  p u.name
  #  u.pm.history(100).each {|m| p m.content }
  #end
end

#bot.playing do |event|
#  if event.user.id == 122196782473150464 && event.game == "Heroes of the Storm"
#    event.user.pm("Hey wanna smurf boost team league with Aya?")
#  end
#end

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