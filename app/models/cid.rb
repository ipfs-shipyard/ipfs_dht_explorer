class Cid < ApplicationRecord
  has_many :wants, dependent: :delete_all
end
