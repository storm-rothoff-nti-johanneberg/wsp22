require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def dbCalled(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

get('/') do
    slim(:start)
end


#-Users-
get('/showregister') do
    slim(:register)
end
get('/showlogin') do
    slim(:login)
end
get('/showaccount/:id') do
    db = dbCalled("db/main.db")
    id = params[:id].to_i
    userId = session[:id].to_i
    usersUnsorted = db.execute("SELECT id, username FROM users")
    users = usersUnsorted.sort_by { |k| k["id"] }
    images = db.execute("SELECT * FROM images WHERE user_id = ? OR creator_id = ?", id, id)
    frames = db.execute("SELECT * FROM frameModRelation")
    return slim(:account, locals:{images:images, frames:frames, users:users, id:id})
end

# get('/images/show/:id') do
#     db = dbCalled("db/main.db")
#     id = params[:id].to_i
#     userid = session[:id].to_i
#     usersUnsorted = db.execute("SELECT id, username FROM users")
#     users = usersUnsorted.sort_by { |k| k["id"] }
#     image = db.execute("SELECT * FROM images WHERE id = ?", id)
#     frames = db.execute("SELECT * FROM frameModRelation")
#     return slim(:"images/show", locals:{image:image, frames:frames, users:users})
# end


get('/logout') do
    session[:id] = nil
    session[:username] = nil
    redirect('/images')
end
post('/login') do
    username = params[:username]
    password = params[:password]
    db = dbCalled('db/main.db')
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwddigest = result["pwddigest"]
    id = result["id"]
    username = result["username"]
    tokens = result["tokens"]

    if BCrypt::Password.new(pwddigest) == password
        session[:id] = id
        session[:username] = username
        session[:tokens] = tokens
        redirect('/images')
    else
       "Username and Password do not match"
    end
end

post("/users/new") do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if password == password_confirm
        db = dbCalled('db/main.db')
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO users (username,pwddigest) VALUES (?,?)",username,password_digest)
        redirect('/')
    else
        "Passwords do not match"
    end
end

#-Images-

get('/images') do
    id = session[:id].to_i
    db = dbCalled("db/main.db")
    #userCurrent = db.execute("SELECT username FROM users WHERE id = ?", id)
    usersUnsorted = db.execute("SELECT id, username FROM users")
    users = usersUnsorted.sort_by { |k| k["id"] }
    #p "this is your stuff #{result}"

    images = db.execute("SELECT * FROM images")
    frames = db.execute("SELECT * FROM frameModRelation")
    return slim(:"images/index", locals:{images:images, frames:frames, users:users,  usersUnsorted:usersUnsorted})
end

get('/newimg') do
    return slim(:new)
end

get('/images/show/:id') do
    db = dbCalled("db/main.db")
    id = params[:id].to_i
    userid = session[:id].to_i
    usersUnsorted = db.execute("SELECT id, username FROM users")
    users = usersUnsorted.sort_by { |k| k["id"] }
    image = db.execute("SELECT * FROM images WHERE id = ?", id)
    frames = db.execute("SELECT * FROM frameModRelation")
    return slim(:"images/show", locals:{image:image, frames:frames, users:users})
end

post("/image/new") do 
    id = session[:id].to_i
    path = File.join("./public/img/",params[:imageFile]["filename"])
    pathForDb = File.join("img/",params[:imageFile]["filename"])
    db = dbCalled('db/main.db')
    mod = rand(1...10)  
    db.execute("INSERT INTO images (path, mod, name, user_id, creator_id) VALUES (?, ?, ?, ?, ?)", pathForDb, mod, params[:imageName], id, id)

    File.open(path, 'wb') do |f|
        f.write(params[:imageFile][:tempfile].read)
    end      
    redirect('/images')
end

post('/images/show/delete/:id') do 
    id = params[:id].to_i
    db = dbCalled("db/main.db")
    deletePath = db.execute("SELECT path FROM images WHERE id = ?", id)
    #Tar bort all
    File.delete("public/#{deletePath[0]["path"]}") if File.exist?("public/#{deletePath[0]["path"]}")  
    result = db.execute("DELETE FROM images WHERE id = ?", id)
    redirect('/images')
end
post('/images/show/update/:id') do 
    id = params[:id].to_i
    value = params[:value].to_i
    db = dbCalled("db/main.db")
    db.execute("UPDATE images SET price = ? WHERE id = ?", value, id)
    redirect("/images/show/#{id}")
end

post('/images/show/purchase/:id') do 
    db = dbCalled("db/main.db")
    id = params[:id].to_i
    user_id = session[:id].to_i
    # usersUnsorted = db.execute("SELECT id, username FROM users")
    # users = usersUnsorted.sort_by { |k| k["id"] }
   
   
    seller_id = db.execute("SELECT user_id FROM images WHERE id = ?", id)
    p seller_id
    price = db.execute("SELECT price FROM images WHERE id = ?", id)
    tokensBuyer = db.execute("SELECT tokens FROM users WHERE id = ?", user_id)
    tokensSeller = db.execute("SELECT tokens FROM users WHERE id = ?", seller_id[0]["user_id"])
    newBuyer = tokensBuyer[0]["tokens"].to_i - price[0]["price"].to_i
    newSeller = tokensSeller[0]["tokens"].to_i + price[0]["price"].to_i



    db.execute("UPDATE users SET tokens = ? WHERE id = ?", newBuyer, user_id)
    db.execute("UPDATE users SET tokens = ? WHERE id = ?", newSeller, seller_id[0]["user_id"])

    db.execute("UPDATE images SET user_id = ? WHERE id = ?", user_id, id)
    session[:tokens] = db.execute("SELECT tokens FROM users WHERE id = ?", user_id)[0]["tokens"]
    redirect("/images/show/#{id}")
end