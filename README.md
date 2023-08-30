# About
![logo](./public/images/logo_beige.png)

Simple Nutrition Planner is a tool for tracking nutrition and macronutrient goals.

![home](./public/images/recipes.png)
Easily create recipes. Nutrition info is calculated automatically using an open-source dataset

Combine recipes to make mealplans!
![home](./public/images/mealplan.png)

# Installation
1. `git clone` the repo
2. `bundle install`
3. `bundle exec ruby simple_nutrition_planner.rb`
4. default login info: admin 123456 (for development)

# Setting up database
- This app uses a postgres database. Please first install postgres
- To set up the database run `bash idempotent_script.sh nutrition_data`
- The database will be populated with some placeholder recipes and meal plans (feel free to edit or delete)
