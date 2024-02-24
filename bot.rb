require 'telegram/bot'
require 'sequel'

token = '6747277091:AAG-yWV6FaVOzjovYYeCQbJJKp9BBpD9CNw'

DB = Sequel.sqlite('database2.db')
DBadmin = Sequel.sqlite('databaseAdmin.db')

DB.create_table? :userTable do
  primary_key :id
  String :name
  String :role, default: 'user'
  DateTime :last_login_time
  Float :hours_logged, default: 0.0
end

DBadmin.create_table? :adminTable do
  primary_key :id
  String :name
  String :role, default: 'admin'
  DateTime :last_login_time
  Float :hours_logged, default: 0.0
end

# Insert a new admin into the adminTable
DBadmin[:adminTable].insert(name: 'Yamlak', role: 'admin', last_login_time: Sequel::CURRENT_TIMESTAMP, hours_logged: 0.0)

def list_users(bot, chat_id)
  users = DB[:userTable].all

  if users.empty?
    bot.api.send_message(chat_id: chat_id, text: "No users found.")
  else
    message = "Remaining users:\n"
    users.each do |user|
      message += "#{user[:name]} - Last Login: #{user[:last_login_time]}\n"
    end
    bot.api.send_message(chat_id: chat_id, text: message)
  end
end

def start_menu(bot, chat_id)
  bot.api.send_message(chat_id: chat_id, text: "Hi, if you want to login as an Admin: /adminReg, if you are a user: /user")
end

def delete_user(bot, message, username_to_delete)
  if DB[:userTable].where(name: username_to_delete).count > 0
    DB[:userTable].where(name: username_to_delete).delete
    bot.api.send_message(chat_id: message.chat.id, text: "User '#{username_to_delete}' has been deleted.")
    list_users(bot, message.chat.id)
    start_menu(bot, message.chat.id) # Automatically send the start menu
  else
    bot.api.send_message(chat_id: message.chat.id, text: "User '#{username_to_delete}' not found.")
  end
end

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    puts "@#{message.from.username}: #{message.text}"
    command = message.text.split(' ').first

    case command
    when '/start'
      start_menu(bot, message.chat.id)
    when '/adminReg'
      bot.api.send_message(chat_id: message.chat.id, text: "Please enter your admin username:")

      bot.listen do |response_message|
        admin_username = response_message.text.strip

        if DBadmin[:adminTable].where(name: admin_username, role: 'admin').count > 0
          # Admin login logic...
          bot.api.send_message(chat_id: message.chat.id, text: "You have been logged in as admin '#{admin_username}'. If you want to list all users: /listUsers. If you want to delete a user: /deleteUser")

          bot.listen do |admin_command|
            case admin_command.text.strip
            when '/listUsers'
              # List all users
              users = DB[:userTable].all
              users.each do |user|
                bot.api.send_message(chat_id: message.chat.id, text: "#{user[:name]} - Last Login: #{user[:last_login_time]}")
              end
            when '/deleteUser'
              bot.api.send_message(chat_id: message.chat.id, text: "Please enter the username of the user you want to delete:")

              bot.listen do |delete_command|
                username_to_delete = delete_command.text.strip
                delete_user(bot, message, username_to_delete)
                break # Break the /deleteUser loop
              end
            # Additional admin cases...
            else
              bot.api.send_message(chat_id: message.chat.id, text: "Invalid admin command.")
            end
          end
        else
          bot.api.send_message(chat_id: message.chat.id, text: "The admin username '#{admin_username}' does not exist.")
        end

        break # Break the /adminReg loop
      end

    when '/user'
      bot.api.send_message(chat_id: message.chat.id, text: "Please enter your username:")

      bot.listen do |response_message|
        username = response_message.text.strip

        # Insert the username into the database
        DB[:userTable].insert(name: username)
        # When User Login
        DB[:userTable].where(name: username).update(last_login_time: Sequel::CURRENT_TIMESTAMP)

        # Login time...
        bot.api.send_message(chat_id: message.chat.id, text: "Your username '#{username}' has been saved.")
        bot.api.send_message(chat_id: message.chat.id, text: "If you want to access the start menu: /start")

        # Exit the /user loop to prevent further processing
        break
      end

    # Additional cases...

    else
      bot.api.send_message(chat_id: message.chat.id, text: "I have no idea what #{command.inspect} means.")
    end
  end
end
