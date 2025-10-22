# Rails

## Set database connection
```yaml
development:
  <<: *default
  database: eshop_development
  username: rails_user
  password: PASSWORD
  host: localhost

test:
  <<: *default
  database: eshop_test
  username: rails_user
  password: PASSWORD
  host: localhost
```

## Create database
```bash
rails db:create
```

## Start server
```bash
rails server
```


## Create Model
```bash
rails generate model Category name:string description:text
```
**Description:**
* `rails generate model` command
* `Category` model name
* `name:string` column *name*, type *string*
* `description:text` column *description*, type *text*

**another types:**
* `price:decimal` column *price*, type *decimal*
* `product:references` reference to *product*
* `value:integer` column *value*, type *integer*

This command generate:
* `app/models/category.rb` model file
* `db/migrate/<timestamp>_create_categories.rb` migration file for create table *categories*

## Migration
```bash
rails db:migrate
```

## Check in Rails console
```bash
rails console
```

### Create category
```ruby
Category.create(name: "Electronics", description: "All kinds of electronics")
```

## Check routes
```bash
rails routes
```




```bash
```

```bash
```