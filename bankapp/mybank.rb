require 'yaml'
require 'io/console'

def load_data
	YAML.load_file("new_user_data.yml")
end

def save_data(user_record)
	File.open("new_user_data.yml","w") do |f|
		f.write(user_record.to_yaml)
	end
end
																		
def input(statement)																		#^[^_0-9]\w+\.mp3$ re for .mp3
	print statement
	var = gets.chomp
	if /^$/.match var 		#var.empty?
		puts 'Input cannot be empty.'
		input(statement)
	end
	block_given? ? yield(var) : var
end

def enter_valid_password(statement)
	print statement
	password = STDIN.getpass
	return password if (/\w{8,}/.match password)
  puts 'Conflict:Password invalid'
  enter_valid_password(statement) : password
end

def enter_valid_user_id(user_record, statement)
	user_id = input(statement) {|id| id.to_sym}
	if user_record.has_key?(user_id)
		puts 'Conflict:UserId is invalid'
		return enter_valid_user_id(user_record, statement)
	end
	user_id
end

def enter_valid_payee_id(user_id, user_record, statement)
	payee_id = input(statement) { |id| id.to_sym }
	if user_record[payee_id].nil? || user_id == payee_id
		puts 'Conflict:PayeeId is invalid'
		return enter_valid_payee_id(user_record, statement)
	end
	payee_id
end

def enter_valid_date(statement)
	date = input(statement)
	return Date.parse(date) if /\d{1,2}\/\d{1,2}\/\d{4}/.match date
  puts 'Conflict:Date should be in valid format'
  enter_valid_date(statement) 
  #date.empty? ? (return enter_valid_date(statement)) : Date.parse(date)
end

def enter_valid_amount(statement)
	amount = input(statement)
	return amount.to_f if /^\d+[.]?\d+$/.match amount
  puts 'Conflict:Amount should be valid number'
  enter_valid_amount(statement)
end

def enter_valid_email(statement)
  email = input(statement)
  return email if /^\w+@\w+[.]\w+/.match email
  puts 'Conflict:Email is invalid'
  return enter_valid_email(statement)
end

def add_user(user_record)
	system 'clear'
	name = input('Enter the Name: ')
	email = enter_valid_email('Enter the Email address: ')
	user_id = enter_valid_user_id(user_record, 'Enter the new UserId: ')
	password = enter_valid_password('Enter the new Password(pass length >= 8): ')
	user_info = {name: name, email: email, balance: 0, password: password, transaction_history: []} 
	user_record.store(user_id,user_info)
end

def login(user_record)
	system 'clear'
	user_id = input("\n\t\t::::::Login Window:::::\nEnter UserId: ") {|id| id.to_sym}
	unless user_record.has_key? (user_id)
		if input('UserId not found. Do you want to create new User(y/n)') == 'y'
			add_user(user_record)
			login(user_record)
			return
		else
			abort("Quiting the app!!")
		end			
	end
	if user_record[user_id][:password] == STDIN.getpass('Enter the Password: ')
		user_interface(user_id, user_record)
	else
		abort("Wrong password!! Quiting the app")
	end
end

def update_bal(user_record, user_id, amount)
	yield(user_record, user_id, amount) if block_given?
end

def add_transaction_history(user_record, user_id, amount, message)
	user_record[user_id][:transaction_history] << {msg: message, amount: amount, date_time: Time.now}
end

def deposit(user_id, user_record, amount)
	update_bal(user_record, user_id, amount) { |record, id, amount| record[id][:balance] += amount }
	check_balance(user_id, user_record)
	add_transaction_history(user_record, user_id, amount, 'deposited')
end

def withdraw(user_id, user_record, amount)
	return false if user_record[user_id][:balance] - amount < 0
	update_bal(user_record, user_id, amount) { |record, id, amount| record[id][:balance] -= amount }
	check_balance(user_id, user_record)
	add_transaction_history(user_record, user_id, amount, 'withdrawn') 
end

def money_transfer(user_id, user_record, to_id, amount)
	return false if user_record[user_id][:balance] - amount < 0
	update_bal(user_record, user_id, amount) { |record, id, amount| record[id][:balance] -= amount }
	add_transaction_history(user_record, user_id, amount, "transferred to #{to_id}" )
	update_bal(user_record, to_id, amount) { |record, id, amount| record[id][:balance] += amount }
	add_transaction_history(user_record, to_id, amount, "received from #{user_id}" )
end

def transaction_history(user_id, user_record, from_date, to_date)
	puts "Transaction history of user #{user_id}"
	user_record[user_id][:transaction_history].each do |transaction|
		transaction_date = Date.parse(transaction[:date_time].to_s) 	#DateTime.parse(..) is used when we are considering date as well as time
		if transaction_date.between?(from_date, to_date)
			puts "#{transaction[:date_time].strftime('%d-%m-%Y %H:%M:%S')} => #{user_id} #{transaction[:msg]} #{transaction[:amount]}"	
		end
	end
end

def check_balance(user_id, user_record)
	puts "The updated balance for user #{user_id} is #{user_record[user_id][:balance]}"
end

def user_interface(user_id, user_record)
	system 'clear'
	begin
		option = input("\t\tMenu\n1.Deposit\n2.Withdraw\n3.Money Transaction\n4.Transaction History\n5.Show Balance\n6.Logout\n") {|x| x.to_i}
		case option
		when 1
			amount = enter_valid_amount('Enter the Amount you want to deposit: ')
			deposit(user_id, user_record, amount)
		when 2
			amount = enter_valid_amount('Enter the Amount you want to withdraw: ')
			puts 'Invalid Transaction:Account balance insufficent.' unless withdraw(user_id, user_record, amount)
		when 3
      to_id = enter_valid_payee_id(user_id, user_record, 'Enter the UserId to transfer money to: ') #validate to_id
      amount = enter_valid_amount('Enter the Amount you want to transfer: ')
      puts 'Invalid Transaction:Account balance insufficent.' unless money_transfer(user_id, user_record, to_id, amount)
    when 4
    	from_date = enter_valid_date('Enter the Start date(dd/mm/yyyy): ')
    	to_date = enter_valid_date('Enter the End date(dd/mm/yyyy): ')
    	transaction_history(user_id, user_record, from_date, to_date)
    when 5
    	check_balance(user_id, user_record)
    end
  end while option < 6
end

def main
	user_record = load_data
	login(user_record)
	save_data(user_record)
end

main
