# frozen_string_literal: true

class AddDefaultProvider < ActiveRecord::Migration[4.2]
  def change
    change_column_default :users, :provider, "orcid"
  end
end
