require "sinatra/reloader"
class SessionPersistence
  def initialize(session)
    @session = session
    @session[:ingredients] ||= []
    @session[:recipes] ||= []
  end

  def temp_store_search_term(search)
    @session[:search] = search
  end

  def search_term
    @session[:search]
  end
  def error?
    @session[:error] != "" || nil
  end
  def error
    temp_error = @session[:error]
    @session[:error] = nil
    temp_error
  end

  def username
    @session[:username]
  end

  def reset_search
    @session[:search] = nil
  end

  def search_results?
    @session[:search] != "" && @session[:search] != nil
  end

  def login(username)
    @session[:logged_in] = true
    @session[:username] = username
  end

  def logged_in?
    !!@session[:logged_in]
  end

  def logout
    @session[:logged_in] = false
  end

  # def update_quantities_array
  #   puts "returns array method"
  #   puts @session
  #   @session.find_all {|tuple| tuple[0]}
  # end

  # def update_recipe(id, name, category, recipe_image_url)
  #   recipe = get_recipe(id)
  #   recipe[:name] = name
  #   recipe[:category] = category
  #   recipe[:image_url] = recipe_image_url
  # end

end