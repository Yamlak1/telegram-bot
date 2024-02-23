require 'telegram/bot'

token = '6747277091:AAG-yWV6FaVOzjovYYeCQbJJKp9BBpD9CNw'

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    puts "@#{message.from.username}: #{message.text}"
    command = message.text.split(' ').first

    case command
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "All I can do is hello. Try the /greet command.")
    when '/greet'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}.")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "I have no idea what #{command.inspect} means.")
    end
  end
end
