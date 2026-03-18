"""Tests for privacy router endpoints."""

from unittest.mock import patch, AsyncMock, MagicMock
import aiohttp


def test_privacy_shield_toggle_requires_auth(test_client):
    """POST /api/privacy-shield/toggle without auth → 401."""
    resp = test_client.post("/api/privacy-shield/toggle", json={"enabled": True})
    assert resp.status_code == 401


def test_privacy_shield_stats_requires_auth(test_client):
    """GET /api/privacy-shield/stats without auth → 401."""
    resp = test_client.get("/api/privacy-shield/stats")
    assert resp.status_code == 401


def test_privacy_shield_status_requires_auth(test_client):
    """GET /api/privacy-shield/status without auth → 401."""
    resp = test_client.get("/api/privacy-shield/status")
    assert resp.status_code == 401


def test_privacy_shield_status_container_not_running(test_client):
    """GET /api/privacy-shield/status when container not running → enabled=False."""
    async def _fake_subprocess(*args, **kwargs):
        proc = MagicMock()
        proc.communicate = AsyncMock(return_value=(b"", b""))
        proc.returncode = 0
        return proc

    with patch("asyncio.create_subprocess_exec", side_effect=_fake_subprocess):
        resp = test_client.get("/api/privacy-shield/status", headers=test_client.auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["enabled"] is False
        assert data["container_running"] is False


def test_privacy_shield_status_container_running_healthy(test_client, mock_aiohttp_session):
    """GET /api/privacy-shield/status when container running and healthy → enabled=True."""
    async def _fake_subprocess(*args, **kwargs):
        proc = MagicMock()
        proc.communicate = AsyncMock(return_value=(b"dream-privacy-shield", b""))
        proc.returncode = 0
        return proc

    session = mock_aiohttp_session(status=200)

    with patch("asyncio.create_subprocess_exec", side_effect=_fake_subprocess):
        with patch("aiohttp.ClientSession", return_value=session):
            resp = test_client.get("/api/privacy-shield/status", headers=test_client.auth_headers)
            assert resp.status_code == 200
            data = resp.json()
            assert data["enabled"] is True
            assert data["container_running"] is True


def test_privacy_shield_toggle_enable(test_client):
    """POST /api/privacy-shield/toggle with enable=True → starts container."""
    async def _fake_subprocess(*args, **kwargs):
        proc = MagicMock()
        proc.communicate = AsyncMock(return_value=(b"Started privacy-shield", b""))
        proc.returncode = 0
        return proc

    with patch("asyncio.create_subprocess_exec", side_effect=_fake_subprocess):
        resp = test_client.post(
            "/api/privacy-shield/toggle",
            json={"enable": True},
            headers=test_client.auth_headers
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "started" in data["message"].lower()


def test_privacy_shield_toggle_disable(test_client):
    """POST /api/privacy-shield/toggle with enable=False → stops container."""
    async def _fake_subprocess(*args, **kwargs):
        proc = MagicMock()
        proc.communicate = AsyncMock(return_value=(b"Stopped privacy-shield", b""))
        proc.returncode = 0
        return proc

    with patch("asyncio.create_subprocess_exec", side_effect=_fake_subprocess):
        resp = test_client.post(
            "/api/privacy-shield/toggle",
            json={"enable": False},
            headers=test_client.auth_headers
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "stopped" in data["message"].lower()


def test_privacy_shield_stats_authenticated(test_client, mock_aiohttp_session):
    """GET /api/privacy-shield/stats with auth → 200, returns stats."""
    session = mock_aiohttp_session(status=200, json_data={"requests": 42, "pii_detected": 5})

    with patch("aiohttp.ClientSession", return_value=session):
        resp = test_client.get("/api/privacy-shield/stats", headers=test_client.auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert isinstance(data, dict)
        assert data["requests"] == 42


def test_privacy_shield_stats_service_unreachable(test_client, mock_aiohttp_session):
    """GET /api/privacy-shield/stats when service unreachable → returns error."""
    session = mock_aiohttp_session(raise_on_get=aiohttp.ClientError("Connection refused"))

    with patch("aiohttp.ClientSession", return_value=session):
        resp = test_client.get("/api/privacy-shield/stats", headers=test_client.auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert "error" in data
        assert data["enabled"] is False
