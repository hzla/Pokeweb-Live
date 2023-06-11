class CreateTraders < ActiveRecord::Migration[7.0]
  def change
    create_table :traders do |t|
      t.string :address, null: false, default: ''
      t.float :pnl, default: 0
      t.integer :trade_count, default: 0
      t.datetime :last_trade
      t.datetime :first_trade
      t.float :avg_size, default: 0
      t.float :max_size, default: 0

      t.timestamps
    end
  end
end

