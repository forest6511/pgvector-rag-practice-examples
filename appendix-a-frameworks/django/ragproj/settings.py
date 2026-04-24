"""Django settings(抜粋。本サンプルで関係する部分のみ)"""
import os

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "dev-only-do-not-use-in-production")
DEBUG      = True
ALLOWED_HOSTS = ["*"]

INSTALLED_APPS = [
    "django.contrib.contenttypes",
    "django.contrib.auth",
    "pgvector.django",
    "rag",
]

DATABASES = {
    "default": {
        "ENGINE":   "django.db.backends.postgresql",
        "NAME":     "ragdb",
        "USER":     os.environ.get("DATABASE_USER", "rag"),
        "PASSWORD": os.environ.get("DATABASE_PASSWORD", "ragpass"),
        "HOST":     os.environ.get("DATABASE_HOST", "localhost"),
        "PORT":     os.environ.get("DATABASE_PORT", "5432"),
    }
}

ROOT_URLCONF    = "ragproj.urls"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
