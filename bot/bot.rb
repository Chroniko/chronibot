require 'discordrb'

bot = Discordrb::Bot.new token: ENV['BOT_TOKEN']

#bot.message(content: ['<:GWchadMEGATHINK:366999806343774218>', '<:Think:357607104418283522>', '<:think:443803808259244032>'] ) do |event|
#  unless event.user.id == MY_ID
#    event.message.delete
#  end
#end

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
    "SAVE YOURSELF,
    DENKO",
    "DENKO HIDE QUICKLY"
  ].sample if Random.rand > 0.2
end

bot.run