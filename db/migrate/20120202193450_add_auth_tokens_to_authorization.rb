class AddAuthTokensToAuthorization < ActiveRecord::Migration
  def change
    change_table :authorizations do |t|
      t.string :token
      t.string :token_secret
    end
  end
end
