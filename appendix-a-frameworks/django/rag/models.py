from django.db import models
from pgvector.django import VectorField, HnswIndex


class Doc(models.Model):
    title      = models.CharField(max_length=200)
    body       = models.TextField()
    embedding  = VectorField(dimensions=1536)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            HnswIndex(
                name="docs_embedding_hnsw",
                fields=["embedding"],
                m=16,
                ef_construction=64,
                opclasses=["vector_cosine_ops"],
            ),
        ]
