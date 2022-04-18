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
    result = db.execute("SELECT * FROM images")
    p result
    return slim(:"images/index", locals:{images:result})
end

get('/newimg') do
    return slim(:new)
end



post('/image/new') do 

    path = File.join("./public/img/",params[:imageFile]["filename"])
    path_for_db = File.join("img/",params[:imageFile]["filename"])
    #p params[:imageFile][:tempfile]
    db = db_called('db/main.db')
    mod = rand(1...10)
    db.execute("INSERT INTO images (path, mod) VALUES (?, ?)", path_for_db, mod)

    File.open(path, 'wb') do |f|
        f.write(params[:imageFile][:tempfile].read)
    end
    
    redirect('/')

    #File.open("./public/#{"filename"}", 'wb') do |f|
    # p "ö"
    # p File.read(params[:imageFile][:tempfile])
    # p "ö"
    # File.write(path, File.read(params[:imageFile][:tempfile]))
    #     # p "ö"
        # p File.read(params[:imageFile][:tempfile].read)

    # File.open(path, 'wb') do |f|
    #     File.write(File.read)
    # end 
    # File.write(path,File.read())
    
    # @filename = params[:imageFile]
    # p @filename["filename"]
    # p @filename["tempfile"]
    # db.execute("INSERT INTO images (img_id, mod) VALUES (?,?)", @filename["tempfile"], mod)
    # File.open("./public/#{@filename}", 'wb') do |f|
    #     f.write(file.read)
    # end
end

post('/image/delete/:id') do 
    n = params[:id].to_i
    db = db_called("db/main.db")
    result = db.execute("DELETE FROM images WHERE id = ?", n)
    redirect('/images')
    File.delete(path) if File.exist?(path)
end

# db = db_called("db/main.db")
#     result = db.execute("INSERT INTO images (img_id, mod) VALUES (?, ?), img_id, mod")
# end
