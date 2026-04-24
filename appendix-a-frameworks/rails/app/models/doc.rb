class Doc < ApplicationRecord
  has_neighbors :embedding
end
