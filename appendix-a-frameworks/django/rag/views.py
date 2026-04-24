import json

from django.http import JsonResponse, HttpResponseNotAllowed
from django.views.decorators.csrf import csrf_exempt
from pgvector.django import CosineDistance

from .models import Doc
from .embedder import embed


@csrf_exempt
def create_doc(request):
    if request.method != "POST":
        return HttpResponseNotAllowed(["POST"])

    payload = json.loads(request.body)
    vec     = embed(f"{payload['title']}\n{payload['body']}")

    doc = Doc.objects.create(
        title=payload["title"],
        body=payload["body"],
        embedding=vec,
    )
    return JsonResponse({"ok": True, "id": doc.id})


def search(request):
    q    = request.GET.get("q", "")
    vec  = embed(q)
    docs = (
        Doc.objects
           .annotate(dist=CosineDistance("embedding", vec))
           .order_by("dist")[:10]
    )
    return JsonResponse(
        {"hits": [{"id": d.id, "title": d.title} for d in docs]}
    )
