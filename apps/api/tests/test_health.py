from collections.abc import AsyncIterator

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.exc import OperationalError

from app.db.session import get_session
from app.main import app


class FakeSession:
    def __init__(self, fail: bool = False) -> None:
        self.fail = fail

    async def execute(self, *_args, **_kwargs) -> None:
        if self.fail:
            raise OperationalError("SELECT 1", {}, Exception("db down"))


def override_session(fail: bool):
    async def _get_session() -> AsyncIterator[FakeSession]:
        yield FakeSession(fail=fail)

    return _get_session


@pytest.fixture
async def client() -> AsyncIterator[AsyncClient]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


async def test_health_ok(client: AsyncClient) -> None:
    app.dependency_overrides[get_session] = override_session(fail=False)
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "db": "ok"}


async def test_health_db_down(client: AsyncClient) -> None:
    app.dependency_overrides[get_session] = override_session(fail=True)
    response = await client.get("/api/v1/health")
    assert response.status_code == 503
    assert response.json() == {"status": "degraded", "db": "down"}
