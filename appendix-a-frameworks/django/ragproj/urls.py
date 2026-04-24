from django.urls import path

from rag import views

urlpatterns = [
    path("docs",   views.create_doc, name="create_doc"),
    path("search", views.search,     name="search"),
]
