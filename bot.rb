require 'telegram/bot'
require 'sequel'
require 'sqlite3'

token = '6747277091:AAG-yWV6FaVOzjovYYeCQbJJKp9BBpD9CNw'

DB= Sequel.sqlite('database2.db')
DBadmin= Sequel.sqlite('databaseAdmin.db')


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



Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    puts "@#{message.from.username}: #{message.text}"
    command = message.text.split(' ').first

    case command
        when '/start'
            bot.api.send_message(chat_id: message.chat.id, text: "HI, if you want to login as an Admin: /adminReg , if you are a user: /user")
        when '/adminReg'
            # Prompt the admin to input their username
            bot.api.send_message(chat_id: message.chat.id, text: "Please enter your admin username:")

            # Listen for the admin's response
            bot.listen do |response_message|
            # Assuming the admin's response is the username
            admin_username = response_message.text.strip

            # Check if the admin username exists in the database
            if DBadmin[:adminTable].where(name: admin_username, role: 'admin').count > 0
                # Update the last_login_time for the admin
                DBadmin[:adminTable].where(name: admin_username).update(last_login_time: Sequel::CURRENT_TIMESTAMP)

                # Login time
                last_login = DBadmin[:adminTable].where(name: admin_username).get(:last_login_time)
                current_time = Time.now
                login_duration = current_time - last_login
                DBadmin[:adminTable].where(name: admin_username).update(hours_logged: Sequel[:hours_logged] + login_duration)

                # Inform the admin that they have been logged in
                bot.api.send_message(chat_id: message.chat.id, text: "You have been logged in as admin '#{admin_username}'.")
            else
                # Inform the admin that their username does not exist
                bot.api.send_message(chat_id: message.chat.id, text: "The admin username '#{admin_username}' does not exist.")
            end
        end


        when '/user'
            # Prompt the user to input their username
            bot.api.send_message(chat_id: message.chat.id, text: "Please enter your username:")

            # Listen for the user's response
            bot.listen do |response_message|
            # Assuming the user's response is the username
            username = response_message.text.strip

            # Insert the username into the database
            DB[:userTable].insert(name: username)
            #When User Login
            DB[:userTable].where(name: username).update(last_login_time: Sequel::CURRENT_TIMESTAMP)

            #Login time
            last_login = DB[:userTable].where(name: username).get(:last_login_time)
            current_time = Time.now
            login_duration = current_time - last_login
            DB[:userTable].where(name: username).update(hours_logged: Sequel[:hours_logged] + login_duration)

            # Inform the user that their username has been saved
            bot.api.send_message(chat_id: message.chat.id, text: "Your username '#{username}' has been saved.")
            bot.api.send_message(chat_id: message.chat.id, text: "if you want to logout : /logout")
            end
            else
                bot.api.send_message(chat_id: message.chat.id, text: "I have no idea what #{command.inspect} means.")
            end
        end
        end
