class CreateActions < ActiveRecord::Migration[7.0]
  def change
     create_table :actions do |t|
      t.string :tx_hash, null: false, default: ''
      t.string :method
      t.string :params
      t.integer :trader_id
      t.integer :trade_id
      t.float :current_pnl
      t.integer :trade_count
      t.integer :win_count
      t.float :collateral_delta
      t.float :size_delta
      t.float :price
      t.integer :timestamp
      t.float :fee

      t.timestamps
    end
  end
end
