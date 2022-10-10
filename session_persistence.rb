require "sinatra/reloader"
class SessionPersistence
  def initialize(session)
    @session = session
    @session[:ingredients] ||= []
    @session[:recipes] ||= []
  end

  # def recipes
  #   @session[:recipes]
  # end

  # def next_recipe_id
  #   max = (@session[:recipes].map {|recipe| recipe[:id]}).max || 0
  #   max + 1
  # end

  # def next_ingredient_id(recipe)
  #   max = (recipe[:ingredients].map {|ingredient| ingredient[:id]}).max || 0
  #   max + 1
  # end

  # def create_new_recipe(name, category, image_url)
  #   @session[:recipes] << {
  #           :name => name, 
  #           :id => next_recipe_id, 
  #           :ingredients => [],
  #           :category => category,
  #           :image_url => image_url

  #           }
  # end

  # def delete_all_recipes
  #   @session[:recipes] = []
  # end

  # def delete_recipe(id)
  #   @session[:recipes].reject! {|recipe| recipe[:id] == id.to_i}
  # end

  # def get_recipe(id)
  #   @session[:recipes].select {|recipe| recipe[:id] == id.to_i}[0]
  # end

  # def set_name(recipe, name)
  #   recipe[:name] = name
  # end

  # def add_ingredient(recipe, ing_name, calories_per_serving = 0, servings = 1)
  #   recipe[:ingredients] << 
  #     {:name => ing_name, 
  #     :id => next_ingredient_id(recipe), 
  #     :calories_per_serving => calories_per_serving,
  #     :servings => servings}
  # end

  # def delete_ingredient(recipe, ingredient_id)
  #   recipe[:ingredients].reject! { |ingredient| ingredient[:id] == ingredient_id.to_i }
  # end

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