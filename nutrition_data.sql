-- name,calories,total_fat,saturated_fat,cholesterol,sodium,carbohydrate,fiber,sugars
CREATE TABLE nutrition_data (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text UNIQUE NOT NULL,
  calories integer NOT NULL,
  total_fat varchar(15),
  saturated_fat varchar(15),
  cholesterol varchar(15),
  sodium varchar(15),
  carbohydrate varchar(15),
  fiber varchar(15),
  sugars varchar(15),
  protein varchar(15)
);

CREATE TABLE users (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  password text,
  username varchar(100) UNIQUE
);

CREATE TABLE meal_plans (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  image_url text DEFAULT '/Images/default.png',
  user_id integer REFERENCES users(id) ON DELETE CASCADE,
  name varchar(100) NOT NULL

);

INSERT INTO users (username, password)
VALUES  ('admin', '$2a$12$iW8ncprGg0cGbUUKFdCY/uHQxi1TjMW0gVU.jzJ/4kwTxeGKlayZ6');


CREATE TABLE recipes (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category varchar(50),
  name varchar(50) NOT NULL,
  image_url text DEFAULT '/Images/default.png',
  instructions varchar(10000),
  user_id integer REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE meal_plans_recipes (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  meal_plan_id integer REFERENCES meal_plans(id) ON DELETE CASCADE,
  recipe_id integer REFERENCES recipes(id) ON DELETE CASCADE,
  quantity decimal(4,2) default 1
);

INSERT INTO meal_plans (user_id, name)
VALUES  (1, 'High Calorie Gym Day'),
        (1, 'Cheat Day'),
        (1, 'Calorie Restriction');

INSERT INTO recipes (name, image_url, user_id, instructions)
VALUES  ('banana cream pie', 'https://brokenovenbaking.com/wp-content/uploads/2020/12/banana-cream-pie-7.jpg', 1,
         'This is how you make banana cream pie'),
        ('barbeque sauce', 'https://www.lecremedelacrumb.com/wp-content/uploads/2021/06/bbq-sauce-5sm-3-680x1020.jpg', 1,
         'Make the sauce like auntie used to make!');
INSERT INTO meal_plans_recipes (meal_plan_id, recipe_id)
VALUES  (1, 1),
        (1, 2),
        (2, 1),
        (2, 2);

CREATE TABLE recipes_ingredients (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ingredient_id integer REFERENCES nutrition_data(id) ON DELETE CASCADE,
  num_servings decimal CHECK(num_servings BETWEEN 0 AND 100),
  recipe_id integer REFERENCES recipes(id) ON DELETE CASCADE,
  UNIQUE(ingredient_id, recipe_id)
);

COPY nutrition_data(name, calories, total_fat, saturated_fat, cholesterol, sodium, carbohydrate, fiber, sugars, protein)
FROM '/Users/michaelshyer/launchschool/simple_nutrition_planner/nutrition_more_data.csv'
DELIMITER ','
CSV HEADER;


INSERT INTO recipes_ingredients (recipe_id, ingredient_id, num_servings)
VALUES  (1, 1, 1.5),
        (1, 72, 5),
        (2, 520, 0.5),
        (2, 54, 10);


