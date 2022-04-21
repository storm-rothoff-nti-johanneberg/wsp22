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

    if BCrypt::Password.new(pwddigest) == password
        session[:id] = id
        session[:username] = username
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



post("/image/new") do 
    id = session[:id].to_i
    path = File.join("./public/img/",params[:imageFile]["filename"])
    pathForDb = File.join("img/",params[:imageFile]["filename"])
    db = dbCalled('db/main.db')
    mod = rand(1...10)  
    db.execute("INSERT INTO images (path, mod, name, user_id) VALUES (?, ?, ?, ?)", pathForDb, mod, params[:imageName], id)

    File.open(path, 'wb') do |f|
        f.write(params[:imageFile][:tempfile].read)
    end      
    redirect('/images')
end

post('/image/delete/:id') do 
    n = params[:id].to_i
    db = dbCalled("db/main.db")
    deletePath = db.execute("SELECT path FROM images WHERE id = ?", n)
    #Tar bort all
    File.delete("public/#{deletePath[0]["path"]}") if File.exist?("public/#{deletePath[0]["path"]}")  
    result = db.execute("DELETE FROM images WHERE id = ?", n)
    redirect('/images')
end

