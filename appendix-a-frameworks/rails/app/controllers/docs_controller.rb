class DocsController < ApplicationController
  def create
    params.permit(:title, :body)

    doc = Doc.new(title: params[:title], body: params[:body])
    doc.embedding = Embedder.new.embed("#{params[:title]}\n#{params[:body]}")
    doc.save!

    render json: { ok: true, id: doc.id }
  end
end
