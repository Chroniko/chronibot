require 'discordrb'

MY_ID = 268723800030445569

bot = Discordrb::Bot.new token: 'NDQyNTM4MzAwODg0OTEwMDgw.DdAR0A.DJey9GVpMtQiTQcXwh1DzShvqXk'

bot.message(content: ['<:GWchadMEGATHINK:366999806343774218>', '<:Think:357607104418283522>', '<:think:443803808259244032>'] ) do |event|
  unless event.user.id == MY_ID
    event.message.delete
  end
end

bot.message(start_with: /bot rate /i) do |event|
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

bot.message(content: /good bot/i) do |event|
  event.message.react("oowwoaaa:435243426913714177")
end

bot.message(content: /bad( )?bot|\<\:GWchadMEGATHINK\:366999806343774218\>|\<\:Think\:357607104418283522\>|\<\:think\:443803808259244032\>/i) do |event|
  event.message.react("miyanofu:443849528102223873")
end

bot.run