module Model

    def dbCalled(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        p db
        return db
    end

    def show_account_get(id,userId)
        db = dbCalled('db/main.db')
        usersUnsorted = db.execute("SELECT id, username FROM users")
        users = usersUnsorted.sort_by { |k| k["id"] }
        images = db.execute("SELECT * FROM images WHERE user_id = ? OR creator_id = ?", id, id)
        frames = db.execute("SELECT * FROM frameModRelation")
    end

    def login_get(username,password) 
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

end