require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def db_called(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

get('/') do
    return slim(:start)
end

get('/images') do
    db = db_called("db/main.db")
    images = db.execute("SELECT * FROM images")
    frames = db.execute("SELECT * FROM frameModRelation")
    return slim(:"images/index", locals:{images:images, frames:frames})
end

get('/newimg') do
    return slim(:new)
end



post('/image/new') do 

    path = File.join("./public/img/",params[:imageFile]["filename"])
    path_for_db = File.join("img/",params[:imageFile]["filename"])
    db = db_called('db/main.db')
    mod = rand(1...10)  
    #p "test: #{params[:imageName]}"
    db.execute("INSERT INTO images (path, mod, name) VALUES (?, ?, ?)", path_for_db, mod, params[:imageName])

    File.open(path, 'wb') do |f|
        f.write(params[:imageFile][:tempfile].read)
    end      
    redirect('/images')
end

post('/image/delete/:id') do 
    n = params[:id].to_i
    db = db_called("db/main.db")
    deletePath = db.execute("SELECT path FROM images WHERE id = ?", n)

    File.delete("public/#{deletePath[0]["path"]}") if File.exist?("public/#{deletePath[0]["path"]}")
    
    result = db.execute("DELETE FROM images WHERE id = ?", n)
    redirect('/images')
end

# db = db_called("db/main.db")
#     result = db.execute("INSERT INTO images (img_id, mod) VALUES (?, ?), img_id, mod")
# end
