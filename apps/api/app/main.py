from fastapi import FastAPI

from app.api.v1.router import api_router
from app.core.config import settings

app = FastAPI(
    title=settings.app_name,
    openapi_url="/api/openapi.json",
    docs_url="/api/docs",
    redoc_url=None,
)
app.include_router(api_router, prefix="/api/v1")
