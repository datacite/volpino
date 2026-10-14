# frozen_string_literal: true

class AddClaimsCompositeIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :claims, %i[orcid doi]
  end
end
