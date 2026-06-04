from fastapi import FastAPI

from fitflow_api.api.routes import router as api_router

app = FastAPI(
    title="FitFlow Recommendation API",
    version="0.1.0",
    description="Explainable training suggestions based on user-recorded workout history.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(api_router)
