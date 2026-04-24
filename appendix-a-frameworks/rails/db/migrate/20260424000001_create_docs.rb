class CreateDocs < ActiveRecord::Migration[7.2]
  def change
    enable_extension "vector" unless extension_enabled?("vector")

    create_table :docs do |t|
      t.string :title, null: false
      t.text   :body,  null: false
      t.vector :embedding, limit: 1536, null: false
      t.timestamps
    end

    add_index :docs, :embedding,
              using:   :hnsw,
              opclass: :vector_cosine_ops
  end
end
