require "sinatra/reloader"
class DatabasePersistence
  def initialize(pg_connection)
    @connection = pg_connection
  end

  def query(sql, *params)
    @connection.exec_params(sql, [*params].flatten)
  end

  def lookup_user_id(username)
    sql = "SELECT id FROM users WHERE username = $1;"
    query(sql, username)[0]["id"]
  end

  def recipe_instructions_lines(recipe_id)
    sql = <<~SQL
    SELECT instructions FROM recipes
    WHERE recipes.id = $1;
    SQL
    raw_text = query(sql, recipe_id).values[0][0]

    return [] unless !!raw_text

    newlines = raw_text.split(/[\r\n][\r\n]/)

    newlines
  
  end

  def list_meal_plans(user_id)
    sql = <<~SQL
    SELECT id, name FROM meal_plans
    WHERE user_id = $1;
    SQL
    pg_result = query(sql, user_id).values

    final_result = ""
    pg_result.each do |arr|
      final_result << "<div class='meal_plan_row'>" +
      "<a href='/user/#{user_id}/meal-plans/#{arr[0]}'><p>#{arr[1]}</p></a>" + 
      "<form method='POST' action='/user/#{user_id}/meal-plans/#{arr[0]}/delete'>" +
      "<button type='submit' class='delete'></button>" +
    "</form>" + 
    "</div>"
    end
    final_result
  end

  def recipe_instructions(recipe_id)
    sql = <<~SQL
    SELECT instructions FROM recipes
    WHERE recipes.id = $1;
    SQL
    query(sql, recipe_id).values[0][0]
  end
  
  def update_instructions_for_recipe(recipe_id, text)
    sql = <<~SQL
    UPDATE recipes
    SET instructions = $1
    WHERE id = $2;
    SQL
    query(sql, text, recipe_id)
  end

  def reset_sequences  
    sql = <<~SQL
    ALTER SEQUENCE recipes_id_seq RESTART WITH 1;
    SQL
    @connection.exec(sql)

    sql = <<~SQL
    ALTER SEQUENCE recipes_ingredients_id_seq RESTART WITH 1;
    SQL
    @connection.exec(sql)

    sql = <<~SQL
    ALTER SEQUENCE users_id_seq RESTART WITH 1;
    SQL
    @connection.exec(sql)

    sql = <<~SQL
    ALTER SEQUENCE meal_plans_id_seq RESTART WITH 1;
    SQL
    @connection.exec(sql)

    sql = <<~SQL
    ALTER SEQUENCE meal_plans_recipes_id_seq RESTART WITH 1;
    SQL
    @connection.exec(sql)
  end

  def recipes
    recipes = []
    recipes_ids_array.each do |id|
      sql = <<~SQL
      SELECT * FROM recipes WHERE id = $1;
      SQL
      pg_result = query(sql, id).values[0]
      id = pg_result[0]
      category = pg_result[1]
      name = pg_result[2]
      image_url = pg_result[3]

      recipes << {:id => id, :name => name, :category => category, :image_url => image_url}
    end
    recipes

  end
  
  def update_recipe(recipe_id, name, category, recipe_image_url)
    sql = <<~SQL
    UPDATE recipes
    SET name = $2 WHERE id = $1;
    SQL
    query(sql, recipe_id, name)

    sql = <<~SQL
    UPDATE recipes
    SET category = $2 WHERE id = $1;
    SQL
    query(sql, recipe_id, category)

    sql = <<~SQL
    UPDATE recipes
    SET image_url = $2 WHERE id = $1;
    SQL
    query(sql, recipe_id, recipe_image_url)
    
  end

  def update_ingredient_quantity(recipe_id, ingredient_id, ingredient_quantity)
    puts "inner method"
    sql = <<~SQL
    UPDATE recipes_ingredients
    SET num_servings = $1
    WHERE recipe_id = $2 AND ingredient_id = $3;
    SQL
    query(sql, ingredient_quantity, recipe_id, ingredient_id)

  end



  def get_ingredient(id)
    sql = <<~SQL
      SELECT * FROM nutrition_data
      WHERE id = $1;
    SQL
    query(sql, id)
  end

  def add_ingredient( recipe_id, ingredient_id, num_servings)
    sql = <<~SQL
    INSERT INTO recipes_ingredients (recipe_id, ingredient_id, num_servings)
    VALUES  ($1, $2, $3);
    SQL
    query(sql, [recipe_id, ingredient_id, num_servings])
  end

  def display_ingredient_data(ingredient)
    ingredient = ingredient.values[0]
    "<h3>Selected Ingredient: #{ingredient[1]}</h3>" +
    "<h3>Calories per 100g: #{ingredient[2]}</h3>"
  end

  def count_ingredients_for_recipe(recipe_id)
    sql = <<~SQL
      SELECT count(id) FROM recipes_ingredients
      WHERE recipe_id = $1;
    SQL
    query(sql, recipe_id).values[0][0].to_i
  end

  def calculate_nutrition_totals(recipe, quantity = 1)
    
    quantity = quantity.to_f

    calories = (total_recipe_calories(recipe) * quantity).round(0) || 0
    total_fat = (total_recipe_fat(recipe) * quantity).round(1) || 0
    saturated_fat = (total_recipe_sat_fat(recipe) * quantity).round(1) || 0
    sodium = (total_recipe_sodium(recipe) * quantity).round(2) || 0
    carbs = (total_recipe_carbs(recipe) * quantity).round(1) || 0
    protein = (total_recipe_protein(recipe) * quantity).round(1) || 0

    {calories: calories, total_fat: total_fat, saturated_fat: saturated_fat, sodium: sodium, carbohydrate: carbs, protein: protein}
  end

  def total_recipe_protein(recipe_id)
    sql = <<~SQL
    SELECT num_servings, protein FROM recipes_ingredients
    INNER JOIN nutrition_data
    ON nutrition_data.id = recipes_ingredients.ingredient_id
    WHERE recipe_id = $1;
    SQL
    pg_result = query(sql, recipe_id).values
    pg_result.map do |array|
      array.map! { |str| str.to_f}
      array.inject(:*)
    end.sum.round(1)
  end

  def total_recipe_calories(recipe_id)
    sql = <<~SQL
    SELECT num_servings, calories FROM recipes_ingredients
    INNER JOIN nutrition_data
    ON nutrition_data.id = recipes_ingredients.ingredient_id
    WHERE recipe_id = $1;
    SQL
    pg_result = query(sql, recipe_id).values
    pg_result.map do |array|
      array.map! { |str| str.to_f}
      array.inject(:*)
    end.sum
  end

  def total_recipe_carbs(recipe_id)
    sql = <<~SQL
    SELECT num_servings, carbohydrate FROM recipes_ingredients
    INNER JOIN nutrition_data
    ON nutrition_data.id = recipes_ingredients.ingredient_id
    WHERE recipe_id = $1;
    SQL
    pg_result = query(sql, recipe_id).values
    pg_result.map do |array|
      array.map! { |str| str.to_f}
      array.inject(:*)
    end.sum.round(1)
  end

  def total_recipe_fat(recipe_id)
    sql = <<~SQL
    SELECT num_servings, total_fat FROM recipes_ingredients
    INNER JOIN nutrition_data
    ON nutrition_data.id = recipes_ingredients.ingredient_id
    WHERE recipe_id = $1;
    SQL
    pg_result = query(sql, recipe_id).values
    pg_result.map do |array|
      array.map! { |str| str.to_f}
      array.inject(:*)
    end.sum.round(1)
  end

  def total_recipe_sat_fat(recipe_id)
    sql = <<~SQL
    SELECT num_servings, saturated_fat FROM recipes_ingredients
    INNER JOIN nutrition_data
    ON nutrition_data.id = recipes_ingredients.ingredient_id
    WHERE recipe_id = $1;
    SQL
    pg_result = query(sql, recipe_id).values
    pg_result.map do |array|
      array.map! { |str| str.to_f}
      array.inject(:*)
    end.sum.round(1)
  end

  def total_recipe_sodium(recipe_id)
    sql = <<~SQL
    SELECT num_servings, sodium FROM recipes_ingredients
    INNER JOIN nutrition_data
    ON nutrition_data.id = recipes_ingredients.ingredient_id
    WHERE recipe_id = $1;
    SQL
    pg_result = query(sql, recipe_id).values
    pg_result.map do |array|
      array.map! { |str| str.to_f}
      array.inject(:*)
    end.sum.round(1)
  end

  def total_meal_plan_calories(meal_plan_id)
    recipes = recipes_for_mealplan(meal_plan_id)
    sum = 0
    recipes.each do |recipe|
      sum += (total_recipe_calories(recipe["recipe_id"]) * recipe["quantity"].to_f)
    end
    sum.round(0)
  end

  def total_meal_plan_fat(meal_plan_id)
    recipes = recipes_for_mealplan(meal_plan_id)
    sum = 0
    recipes.each do |recipe|
      sum += (total_recipe_fat(recipe["recipe_id"]) * recipe["quantity"].to_f)
    end
    sum.round(1)
  end
  def total_meal_plan_sat_fat(meal_plan_id)
    recipes = recipes_for_mealplan(meal_plan_id)
    sum = 0
    recipes.each do |recipe|
      sum += (total_recipe_sat_fat(recipe["recipe_id"]) * recipe["quantity"].to_f)
    end
    sum.round(1)
  end
  def total_meal_plan_sodium(meal_plan_id)
    recipes = recipes_for_mealplan(meal_plan_id)
    sum = 0
    recipes.each do |recipe|
      sum += (total_recipe_sodium(recipe["recipe_id"]) * recipe["quantity"].to_f)
    end
    sum.round(2)
  end
  def total_meal_plan_protein(meal_plan_id)
    recipes = recipes_for_mealplan(meal_plan_id)
    sum = 0
    recipes.each do |recipe|
      sum += (total_recipe_protein(recipe["recipe_id"]) * recipe["quantity"].to_f)
    end
    sum.round(1)
  end
  def total_meal_plan_carbs(meal_plan_id)
    recipes = recipes_for_mealplan(meal_plan_id)
    sum = 0
    recipes.each do |recipe|
      sum += (total_recipe_carbs(recipe["recipe_id"]) * recipe["quantity"].to_f)
    end
    sum.round(1)
  end

  def calculate_nutrition_totals_meal_plan(meal_plan)
    calories = total_recipe_calories(meal_plan) || 0
    total_fat = total_meal_plan_fat(meal_plan) || 0
    saturated_fat = total_meal_plan_sat_fat(meal_plan) || 0
    sodium = total_meal_plan_sodium(meal_plan) || 0
    carbs = total_meal_plan_carbs(meal_plan) || 0
    protein = total_meal_plan_protein(meal_plan) || 0

    {calories: calories, total_fat: total_fat, saturated_fat: saturated_fat, sodium: sodium, carbohydrate: carbs, protein: protein}
  end

  def count_recipes
    sql = <<~SQL
      SELECT count(id) FROM recipes;
    SQL
    @connection.exec(sql).values[0][0].to_i
  end

  def ingredient_ids_array(recipe_id)
    sql = <<~SQL
      SELECT id FROM recipes_ingredients
      WHERE recipe_id = $1;
    SQL
    # @connection.exec(sql).values.flatten
    query(sql, recipe_id).values.flatten
  end

  def ingredients(recipe_id)
    sql = <<~SQL
    SELECT * FROM recipes_ingredients
      INNER JOIN nutrition_data
      ON nutrition_data.id = recipes_ingredients.ingredient_id
    WHERE recipe_id = $1
    ORDER BY name;
    SQL
    query(sql, recipe_id)
  end

  def recipes_ids_array
    sql = <<~SQL
    SELECT id FROM recipes;
    SQL
    @connection.exec(sql).values.flatten
  end

  def print_ingredient_data_as_row(id)
    
      sql = <<~SQL
      SELECT name, calories, num_servings, recipe_id, ingredient_id FROM nutrition_data
      INNER JOIN recipes_ingredients
      ON recipes_ingredients.ingredient_id = nutrition_data.id
      WHERE recipes_ingredients.id = $1;
      SQL
      pg_result = query(sql, id)[0]
      "<tr>
      <td>
        #{pg_result["name"]}
      </td>
      <td>
      #{pg_result["num_servings"]}
      </td>
      <td>
      #{pg_result["calories"]}
      </td>
      </tr>"

  end

  def delete_all_recipes
    sql = <<~SQL
      DELETE FROM recipes;
    SQL
    @connection.exec(sql)
  end

  def get_recipe(id)
    sql = <<~SQL
      SELECT * FROM recipes
      WHERE id = $1;
    SQL
    
    recipe_data = query(sql, id).values[0]
    id = recipe_data[0]
    category = recipe_data[1]
    name = recipe_data[2]
    image_url = recipe_data[3]
    user_id = recipe_data[4]
    { :id => id, :category => category,
      :name => name, :image_url => image_url,
      :user_id => user_id
    }

  end

  def create_new_recipe(user, name, category, image_url)
    sql = <<~SQL
      INSERT INTO recipes (user_id, name, category, image_url)
      VALUES  ($1, $2, $3, $4);
    SQL
    query(sql, user, name, category, image_url)
  end

  def delete_recipe(id)
    sql = <<~SQL
      DELETE FROM recipes 
      WHERE id = $1;
    SQL
    query(sql, id)
  end

  def delete_recipe_ingredient(recipe_id, ingredient_id)
    sql = <<~SQL
    DELETE FROM recipes_ingredients
    WHERE recipe_id = $1 AND ingredient_id = $2;
    SQL
    query(sql, recipe_id, ingredient_id)
  end

  def delete_meal_plan(user_id, meal_plan_id)
    sql = <<~SQL
    DELETE FROM meal_plans
    WHERE id = $2 AND user_id = $1;
    SQL
    query(sql, user_id, meal_plan_id)
  end

  def get_meal_plan(user_id, meal_plan_id)
    sql = <<~SQL
    SELECT name, image_url FROM meal_plans
    WHERE user_id = $1 AND id = $2;
    SQL
    name = query(sql, user_id, meal_plan_id).values[0][0]
    image_url = query(sql, user_id, meal_plan_id).values[0][1]
    {:name => name, :image_url => image_url}
  end

  def recipes_for_mealplan(meal_plan_id)
    sql = <<~SQL
    SELECT * from meal_plans_recipes INNER JOIN recipes
    ON recipes.id = meal_plans_recipes.recipe_id
    WHERE meal_plans_recipes.meal_plan_id = $1;
    SQL
    pg_result = query(sql, meal_plan_id)

    recipes = []
    pg_result.each do |tuple|
      recipes << tuple
    end
    recipes
  end

  def unselected_recipes_for_mealplan(meal_plan_id)
    sql = <<~SQL
    SELECT recipes.id AS recipe_id, recipes.name, string_agg(meal_plan_id::char, ', ') AS meal_plan_ids
    FROM recipes LEFT OUTER JOIN meal_plans_recipes
    ON recipes.id = meal_plans_recipes.recipe_id
    GROUP BY recipes.id;
    SQL
  
    pg_result = query(sql)

    recipes = []
    pg_result.each do |tuple|
      recipes << tuple
    end
    recipes.each do |recipe|
      if recipe["meal_plan_ids"] == nil
        recipe["meal_plan_ids"] = []
      else
        recipe["meal_plan_ids"] = recipe["meal_plan_ids"].split(", ").map{|str| str.to_i}
      end
    end
    recipes.reject{|recipe| recipe["meal_plan_ids"].include?(meal_plan_id.to_i)}
  end

  def create_meal_plan(user_id, name, image_url="/Images/default.png")
    sql = <<~SQL
    INSERT INTO meal_plans (user_id, name, image_url)
    VALUES  ($1, $2, $3);
    SQL
    query(sql, user_id, name, image_url)
  end

  def update_meal_plan(meal_plan_id, name, image_url)
    sql = <<~SQL
    UPDATE meal_plans
    SET name = $2
    WHERE id = $1;
    SQL
    query(sql, meal_plan_id, name)
    sql = <<~SQL
    UPDATE meal_plans
    SET image_url = $2
    WHERE id = $1;
    SQL
    query(sql, meal_plan_id, image_url)
  end

  def delete_all_meal_plans
    sql = <<~SQL
    DELETE FROM meal_plans;
    SQL
    @connection.exec(sql)
  end

  def delete_all_user_meal_plans(user_id)
    sql = <<~SQL
    DELETE FROM meal_plans
    WHERE user_id = $1;
    SQL
    query(sql, user_id)
  end

  def update_meal_plan_recipe_quantity(meal_plan_id, recipe_id, quantity)
    sql = <<~SQL
    UPDATE meal_plans_recipes
    SET quantity = $3
    WHERE meal_plan_id = $1 AND recipe_id = $2;
    SQL
    query(sql, meal_plan_id, recipe_id, quantity)
  end

end