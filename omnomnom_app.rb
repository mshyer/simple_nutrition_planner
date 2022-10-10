require "sinatra"
# require "erb"
require "sinatra/content_for"
require "tilt/erubis"
require "pg"
require "bcrypt"
require_relative 'session_persistence'
require_relative 'database_persistence'


# Sinatra Setup
require "sinatra/reloader"


configure(:development) do

register Sinatra::Reloader
also_reload "/Users/michaelshyer/launchschool/omnomnom_project/database_persistence.rb" 
also_reload "database_persistence"
also_reload "/session_persistence"
after_reload do
  puts 'reloaded'
end
  enable :sessions
  secret = "c762eabfeb73461ed6daf1ab63d117c7f3c02ddf4f10a2d5c6c1560e517db061"
  set :session_secret, secret
  # set :erb, :escape_html => true

end
configure do
  set :erb, :escape_html => true
end

helpers do
  def verify_credentials(lgin_before, lgin_after)
    sql = <<~SQL
    SELECT username, password FROM users
    WHERE username = $1
    SQL

    pg_result = @database.query(sql, lgin_before)
    redirect "/" unless pg_result
    pg_result = pg_result[0]

    bcrypt_pass = BCrypt::Password.new(pg_result["password"])

    if bcrypt_pass == lgin_after && lgin_before == pg_result["username"]
      true
    else
      false
    end


  end

  def list_ingredient_data(row)
      "<tr>" + 
        "<td>#{row[1]}</td>" +
        "<td>#{row[2]}</td>" +
        "<td ><a href='/recipe/#{@recipe[:id]}/ingredient/#{row[0]}/add'>Add</a></td>" +
      "</tr>"
  end
end


before do
  @storage = SessionPersistence.new(session)
  @user = @storage.username
  if ENV["RACK_ENV"] == "test"
    @database = DatabasePersistence.new(PG.connect(dbname: "test_nutrition_data"))
  else
    @database = DatabasePersistence.new(PG.connect(dbname: "nutrition_data"))
  end
  if @user
    @user_id = @database.lookup_user_id(@storage.username).to_i
  end

end


# Routes

# home route

get "/" do 
  redirect "/login" unless @storage.logged_in?
  erb :home, layout: :layout
end

# get a specific recipe

get "/recipe/:id" do
  @recipe = @database.get_recipe(params[:id])
  erb :recipe, layout: :layout
end

#edit info for a recipe

get "/recipe/:id/edit" do
  @recipe = @database.get_recipe(params[:id])
  erb :edit_recipe, layout: :layout
end

# Route to create a new recipe

get "/recipes/new" do
  erb :new_recipe, layout: :layout
end


# Route to ingredient database lookup

get "/ingredients" do
  @recipe = {:id => 0}
  sql = <<~SQL
  SELECT * FROM nutrition_data WHERE name ~* $1;
  SQL

  @search = @storage.search_term

  if @search != ""
    @pg_result = @database.query(sql, @search).values
  end

  erb :ingredient_search, layout: :layout
end

# Route to add ingredients to a recipe

get "/recipe/:id/add-ingredients" do
  # @recipe = @storage.get_recipe(params[:id])
  @recipe = @database.get_recipe(params[:id])
  sql = <<~SQL
  SELECT * FROM nutrition_data WHERE name ~* $1;
  SQL

  @search = @storage.search_term

  if @search != ""
    @pg_result = @database.query(sql, @search).values
  end

  erb :add_ingredients, layout: :layout
end

get "/recipe/:recipe_id/ingredient/:ingredient_id/add" do
  @recipe = @database.get_recipe(params[:recipe_id])
  @ingredient = @database.get_ingredient(params[:ingredient_id].to_i)
  erb :add_ingredient, layout: :layout
end

# Add the selected ingredient plus number of servings to the recipes list

post "/recipe/:recipe_id/ingredient/:ingredient_id/add" do
  @recipe = @database.get_recipe(params[:recipe_id])
  @ingredient = @database.get_ingredient(params[:ingredient_id].to_i)
  @ingredient = @ingredient.values[0]
  # @storage.add_ingredient(@recipe, @ingredient[1], @ingredient[2], params[:num_servings])
  begin
    @database.add_ingredient(params[:recipe_id], params[:ingredient_id], params[:num_servings])
  rescue
    session[:error] = "Cannot reuse ingredient in same recipe."
    redirect "/recipe/#{params[:recipe_id]}/add-ingredients"
  end
  redirect "/recipe/#{params[:recipe_id]}"
end


post "/recipe/:id/ingredient-search" do
  id = params[:id]
  @search = params[:search_ingredients]
  @storage.temp_store_search_term(@search)
  redirect "/recipe/#{id}/add-ingredients"
end


# Create a new recipe

post "/recipes" do
  name = params[:recipe_name]
  category = params[:recipe_category] == "" ? "Recipe" : params[:recipe_category]
  image_url = params[:recipe_image_url] == "" ? "/Images/default.png" : params[:recipe_image_url]
  # @storage.create_new_recipe(name, category, image_url)
  
  @database.create_new_recipe(@user_id, name, category, image_url)
  
  redirect "/"
end

# delete all recipes from recipes list

post "/recipes/delete" do
  @database.delete_all_recipes
  redirect "/"
end

# delete one recipe from recipes list

post "/recipe/:id/delete" do
  

  @database.delete_recipe(params[:id])
  redirect "/"
end

# edit recipe name

post "/edit_name/:id" do
  @recipe = @storage.get_recipe(params[:id])
  redirect "/recipe/#{params[:id]}"
end

# add recipe ingredient

post "/add_ingredient/:id" do
  # @recipe = @storage.get_recipe(params[:id])
  # @storage.add_ingredient(@recipe, params[:add_ingredient])
  redirect "/recipe/#{params[:id]}"

  
end

# Delete a recipe ingredient

post "/recipe/:recipe_id/ingredient/:ingredient_id/delete" do
  # @recipe = @storage.get_recipe(params[:recipe_id])
  # @storage.delete_ingredient(@recipe, params[:ingredient_id])
  @database.delete_recipe_ingredient(params[:recipe_id], params[:ingredient_id])
  redirect "/recipe/#{params[:recipe_id]}"
end

# Update info for a recipe

post "/recipe/:id/update" do
  id = params[:id]
  name = params[:recipe_name]
  category = params[:recipe_category]
  recipe_image_url = params[:recipe_image_url]
  # @storage.update_recipe(id, name, category, recipe_image_url)
  @database.update_recipe(id, name, category, recipe_image_url)
  redirect "/recipe/#{id}"
end

# Post search results 

post "/search_ingredients" do
  @search = params[:search_ingredients]
  @storage.temp_store_search_term(@search)
  redirect "/ingredients"
end

# Login Routes

get "/login" do
  erb :signin,  layout: :login
end

# Sign up for an account
get "/signup" do
  erb :signup, layout: :login
end

# Create a new account
post "/signup" do
  @lgin_after = BCrypt::Password.new(params[:lgin_after])
  @lgin_before = params[:lgin_before]
end

# Sign in to existing account
post "/login" do
  if verify_credentials(params[:lgin_before], params[:lgin_after])
    @storage.login(params[:lgin_before])
    redirect "/"
  else
    redirect "/login"
  end
end

post "/logout" do
  @storage.logout
  redirect "/"
end

# update the cooking instructions for a recipe

post "/recipe/:id/instructions/update" do
  text = params[:instructions_text]
  @database.update_instructions_for_recipe(params[:id], text)
  redirect "/recipe/#{params[:id]}"
end

# Load page to create a new meal plan

get "/user/:user_id/meal-plans/new" do
  erb :create_meal_plan, layout: :layout
end

# load meal plan info
get "/user/:user_id/meal-plans/:meal_plan_id" do
  @user_id = params[:user_id]
  @meal_plan_id = params[:meal_plan_id]
  @recipes = @database.recipes_for_mealplan(@meal_plan_id)
  @meal_plan = @database.get_meal_plan(@user_id, @meal_plan_id)
  erb :meal_plan, layout: :layout
end

# Selection screen for adding recipes to a meal plan
get "/user/:user_id/meal-plans/:meal_plan_id/add_recipes" do
  @user_id = params[:user_id]
  @meal_plan_id = params[:meal_plan_id]
  @recipes = @database.recipes_for_mealplan(@meal_plan_id)
  @meal_plan = @database.get_meal_plan(@user_id, @meal_plan_id)
  erb :add_recipes_to_mealplan, layout: :layout
end

# delete a meal plan from user

post "/user/:user_id/meal-plans/:meal_plan_id/delete" do
  @database.delete_meal_plan(params[:user_id], params[:meal_plan_id])
  redirect "/"
end

# remove a recipe from meal plan

post '/user/:user_id/meal-plans/:meal_plan_id/remove_recipe/:recipe_id' do
  @user_id = params[:user_id]
  @meal_plan_id = params[:meal_plan_id]
  @recipe_id = params[:recipe_id]
  sql = <<~SQL
  DELETE FROM meal_plans_recipes
  WHERE meal_plan_id = $1 AND recipe_id = $2;
  SQL
  @database.query(sql, @meal_plan_id, @recipe_id)

  redirect "/user/#{@user_id}/meal-plans/#{@meal_plan_id}/add_recipes"
end

# add a recipe to meal plan

post '/user/:user_id/meal-plans/:meal_plan_id/add_recipe/:recipe_id' do
  @user_id = params[:user_id]
  @meal_plan_id = params[:meal_plan_id]
  @recipe_id = params[:recipe_id]
  sql = <<~SQL
  INSERT INTO meal_plans_recipes (meal_plan_id, recipe_id)
  VALUES ($1, $2);
  SQL
  @database.query(sql, @meal_plan_id, @recipe_id)

  redirect "/user/#{@user_id}/meal-plans/#{@meal_plan_id}/add_recipes"
end

# create a new meal plan

post '/user/:user_id/meal-plans/new' do
  @user_id = params[:user_id]
  @mp_name = params[:name]
  @image_url = params[:image_url] == "" ? "/Images/default.png" : params[:recipe_image_url]
  # @image_url = params[:image_url]
  # if @image_url == ""
  #   @image_url = '/Images/default.png'
  # end
  @database.create_meal_plan(@user_id, @mp_name, @image_url)
  redirect "/"
end

# update quantities of ingredient for a recipe

post '/recipe/:recipe_id/ingredient/:ingredient_id/update-ingredient-quantity' do
  @quantity = params.find {|hash| hash[0].match(/num_servings\//)}[1]
  @database.update_ingredient_quantity(params[:recipe_id], params[:ingredient_id], @quantity)
  redirect "/recipe/#{params[:recipe_id]}"
end

# update servings of a recipe for a meal plan

post '/meal-plans/:meal_plan_id/recipes/:recipe_id/update_quantity' do
  @quantity = params.find {|hash| hash[0].match(/num_servings\//)}[1]
  puts "see here"
  p @quantity
  @database.update_meal_plan_recipe_quantity(params[:meal_plan_id], params[:recipe_id], @quantity)
  redirect "/user/#{@user_id}/meal-plans/#{params[:meal_plan_id]}"
end

get '/meal-plans/:meal_plan_id/edit' do
  @meal_plan_id = params[:meal_plan_id]
  @meal_plan = @database.get_meal_plan(@user_id, @meal_plan_id)
  erb :edit_mealplan, layout: :layout
end

post '/meal-plan/:meal_plan_id/update' do
  @meal_plan_id = params[:meal_plan_id]
  name = params[:meal_plan_name]
  image_url = params[:image_url]
  @database.update_meal_plan(@meal_plan_id, name, image_url)
  redirect "/user/#{@user_id}/meal-plans/#{@meal_plan_id}"
  
end