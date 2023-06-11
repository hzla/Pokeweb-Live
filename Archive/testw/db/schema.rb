# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_04_13_015451) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.string "tx_hash", default: "", null: false
    t.string "method"
    t.string "params"
    t.integer "trader_id"
    t.integer "trade_id"
    t.float "current_pnl"
    t.integer "trade_count"
    t.integer "win_count"
    t.float "collateral_delta"
    t.float "size_delta"
    t.float "price"
    t.integer "timestamp"
    t.float "fee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "traders", force: :cascade do |t|
    t.string "address", default: "", null: false
    t.float "pnl", default: 0.0
    t.integer "trade_count", default: 0
    t.datetime "last_trade"
    t.datetime "first_trade"
    t.float "avg_size", default: 0.0
    t.float "max_size", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trades", force: :cascade do |t|
    t.string "tx_hash", default: "", null: false
    t.string "address"
    t.float "fees"
    t.integer "trader_id"
    t.float "current_pnl"
    t.boolean "closed"
    t.boolean "liquidated"
    t.string "collateral_token"
    t.string "index_token"
    t.boolean "is_long"
    t.integer "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
