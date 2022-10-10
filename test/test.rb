ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"
# require 'minitest-reporters
require_relative "../omnomnom_app"

# ROOT = data_path


class AppTest < Minitest::Test
  include Rack::Test::Methods
	def setup
    
    # connect to database
    @database = DatabasePersistence.new(PG.connect(dbname: "test_nutrition_data"))
    @database.delete_all_recipes
    @database.delete_all_meal_plans
    @database.reset_sequences

    # add initial test recipes
    @database.create_new_recipe("1", "Banana Cream Pie", "Desserts", "https://brokenovenbaking.com/wp-content/uploads/2020/12/banana-cream-pie-7.jpg")
    @database.create_new_recipe("1", "Barbeque Sauce", "Sides", "https://www.lecremedelacrumb.com/wp-content/uploads/2021/06/bbq-sauce-5sm-3-680x1020.jpg")
    
    # add initial test ingredients

    @database.add_ingredient(1, 1, 1.5) # Cornstarch,381
    @database.add_ingredient(2, 520, 0.5) #"Wild rice, raw",357
    @database.add_ingredient(1, 72, 5) #"Frankfurter, meatless",233
    @database.add_ingredient(2, 54, 10) #"Durian, raw or frozen",147
    @database.create_meal_plan(1, "Low Carb")

	end

  def app
    Sinatra::Application
  end
  def admin_session
    { "rack.session" => { logged_in: true, username: "admin", user_id: 1 } }
  end

  def session
    last_request.env["rack.session"]
  end
	def test_first_test
		assert true
	end

  def test_logged_out_redirect
    get "/"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "Sign In"
  end

  def test_load_recipes
    get "/", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Banana Cream Pie"
    assert_includes last_response.body, "Barbeque Sauce"
  end


  def test_delete_all_recipes
    @database.delete_all_recipes
    get "/", {}, admin_session
    assert_equal 200, last_response.status
    refute_includes last_response.body, "Banana Cream Pie"
    refute_includes last_response.body, "Barbeque Sauce"
  end

  def test_delete_single_recipe
    @database.delete_recipe(1)
    get "/", {}, admin_session
    assert_equal 200, last_response.status
    refute_includes last_response.body, "Banana Cream Pie"
    assert_includes last_response.body, "Barbeque Sauce"
  end

  def test_load_ingredients
    get "/recipe/1", {}, admin_session
    refute_includes last_response.body, "Wild rice"
    assert_includes last_response.body, "Frankfurter, meatless"
    get "/recipe/2", {}, admin_session
    refute_includes last_response.body, "Frankfurter, meatless"
    assert_includes last_response.body, "Wild rice"
  end

  def test_add_ingredient_to_recipe
    get "/recipe/1", {}, admin_session
    refute_includes last_response.body, "Wild rice"
    @database.add_ingredient(1, 520, 0.5) #"Wild rice, raw",357
    get "/recipe/1", {}, admin_session
    assert_includes last_response.body, "Wild rice"
  end

  def test_delete_ingredient_from_recipe
    get "/recipe/2", {}, admin_session
    assert_includes last_response.body, "Wild rice"
    @database.delete_recipe_ingredient(2, 520)
    get "/recipe/2", {}, admin_session
    refute_includes last_response.body, "Wild rice"
  end

  def test_add_recipe_to_database
    assert @database.count_recipes == 2
    @database.create_new_recipe("1", "Burger", "Mains", "test")
    assert @database.count_recipes == 3
  end
  
  def test_remove_recipe_from_database
    assert @database.count_recipes == 2
    @database.delete_recipe(1)
    assert @database.count_recipes == 1
  end

  def test_add_ingredient_to_database
    assert @database.count_ingredients_for_recipe(1) == 2
    @database.add_ingredient(1, 520, 0.5)
    assert @database.count_ingredients_for_recipe(1) == 3

  end

  def test_delete_ingredient_from_database
    assert @database.count_ingredients_for_recipe(2) == 2
    @database.delete_recipe_ingredient(2, 520)
    assert @database.count_ingredients_for_recipe(2) == 1
  end

  def test_search_ingredients
    get "/recipe/1/add-ingredients"
    assert_equal 200, last_response.status
    post "/recipe/1/ingredient-search", search_ingredients: 'apple'
    assert_equal 302, last_response.status
    assert session[:search] == 'apple'
    assert_equal 'http://example.org/recipe/1/add-ingredients', last_response['Location']
    get "/recipe/1/add-ingredients", {}, {"rack.session" => { search: "apple"} }
    
    assert_equal 200, last_response.status
    assert_includes last_response.body, "pineapple"
  end
  
  def test_add_ingredients_from_search_page
    get "/recipe/1", {}, admin_session
    refute_includes last_response.body, "Wild rice"
    assert @database.count_ingredients_for_recipe(1) == 2
    post "/recipe/1/ingredient/520/add"
    get "/recipe/1", {}, admin_session
    assert_includes last_response.body, "Wild rice"
    assert @database.count_ingredients_for_recipe(1) == 3
  end

  def test_create_delete_meal_plan
    post "/user/1/meal-plans/new", name: "ketogenic"

    assert_equal 302, last_response.status
    sql = <<~SQL
    SELECT * FROM meal_plans;
    SQL
    pg_result = @database.query(sql)
    assert pg_result[1]["name"] == "ketogenic"
    assert_equal 2, pg_result.ntuples

    get "/", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "ketogenic"

    post "/user/1/meal-plans/1/delete"
    pg_result = @database.query(sql)
    assert_equal 1, pg_result.ntuples

  end

  def test_add_remove_recipe_from_meal_plan
    sql = <<~SQL
    SELECT * FROM meal_plans_recipes
    SQL
    pg_result = @database.query(sql)
    assert_equal 0, pg_result.ntuples

    post "/user/1/meal-plans/1/add_recipe/1"
    pg_result = @database.query(sql)
    assert_equal 1, pg_result.ntuples

    get "/user/1/meal-plans/1"
    assert_includes last_response.body, "<td>Banana Cream Pie</td>"

    post "/user/1/meal-plans/1/remove_recipe/1"
    pg_result = @database.query(sql)
    assert_equal 0, pg_result.ntuples
    get "/user/1/meal-plans/1"
    refute_includes last_response.body, "<td>Banana Cream Pie</td>"
  end

	def teardown
    @storage = nil
    @database.delete_all_recipes
    @database.delete_all_meal_plans
    @database.reset_sequences

	end
end