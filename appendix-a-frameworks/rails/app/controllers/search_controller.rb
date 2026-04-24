class SearchController < ApplicationController
  def index
    qvec = Embedder.new.embed(params[:q])
    docs = Doc.nearest_neighbors(:embedding, qvec, distance: "cosine").limit(10)

    render json: {
      hits: docs.map { |d| { id: d.id, title: d.title } }
    }
  end
end
