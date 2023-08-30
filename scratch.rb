recipes = []
def create_new_recipe(recipes_array, id, name, *ingredients)
  recipes_array << {id: id, name: name, ingredients: ingredients}
end

recipes.each do |recipe|
  puts "haha"
end
id = 3
create_new_recipe(recipes, 3, "Chicken Parm", "chicken", "parmesan", "parsely")
create_new_recipe(recipes, 4, "Sammich", "turkey", "lettuce", "mayonnaise")
p recipes

recipes.reject!{|recipe| recipe[:id] != id}
p recipes