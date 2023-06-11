class Trades < ActiveRecord::Migration[7.0]
  def change
    create_table :trades do |t|
      t.string :tx_hash, null: false, default: ''
      t.string :address
      t.float :fees
      t.integer :trader_id
      t.float :current_pnl
      t.boolean :closed
      t.boolean :liquidated
      t.string :collateral_token
      t.string :index_token
      t.boolean :is_long
      t.integer :timestamp


      t.timestamps
    end
  end
end
