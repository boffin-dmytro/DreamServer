"""Tests for setup router endpoints."""

from unittest.mock import patch, AsyncMock, MagicMock
import json


def test_setup_status_first_run(test_client, setup_config_dir):
    """GET /api/setup/status on first run → first_run=True."""
    resp = test_client.get("/api/setup/status", headers=test_client.auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["first_run"] is True
    assert data["step"] == 0
    assert data["persona"] is None
    assert "personas_available" in data


def test_setup_status_after_completion(test_client, setup_config_dir):
    """GET /api/setup/status after setup complete → first_run=False."""
    # Create setup-complete.json
    (setup_config_dir / "setup-complete.json").write_text(
        json.dumps({"completed_at": "2024-01-01T00:00:00Z", "version": "1.0.0"})
    )

    resp = test_client.get("/api/setup/status", headers=test_client.auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["first_run"] is False


def test_setup_persona_valid(test_client, setup_config_dir):
    """POST /api/setup/persona with valid persona → 200, creates files."""
    resp = test_client.post(
        "/api/setup/persona",
        json={"persona": "general"},
        headers=test_client.auth_headers
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["persona"] == "general"

    # Verify persona.json was created
    persona_file = setup_config_dir / "persona.json"
    assert persona_file.exists()
    persona_data = json.loads(persona_file.read_text())
    assert persona_data["persona"] == "general"

    # Verify progress file was created
    progress_file = setup_config_dir / "setup-progress.json"
    assert progress_file.exists()
    progress_data = json.loads(progress_file.read_text())
    assert progress_data["step"] == 2


def test_setup_persona_invalid(test_client, setup_config_dir):
    """POST /api/setup/persona with invalid persona → 400."""
    resp = test_client.post(
        "/api/setup/persona",
        json={"persona": "nonexistent"},
        headers=test_client.auth_headers
    )
    assert resp.status_code == 400
    assert "Invalid persona" in resp.json()["detail"]


def test_setup_complete(test_client, setup_config_dir):
    """POST /api/setup/complete → creates completion marker, removes progress."""
    # Create progress file first
    progress_file = setup_config_dir / "setup-progress.json"
    progress_file.write_text(json.dumps({"step": 2}))

    resp = test_client.post("/api/setup/complete", headers=test_client.auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["redirect"] == "/"

    # Verify setup-complete.json was created
    complete_file = setup_config_dir / "setup-complete.json"
    assert complete_file.exists()

    # Verify progress file was removed
    assert not progress_file.exists()


def test_get_persona_info_valid(test_client):
    """GET /api/setup/persona/{id} with valid ID → 200, returns persona details."""
    resp = test_client.get("/api/setup/persona/general", headers=test_client.auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == "general"
    assert "name" in data
    assert "system_prompt" in data


def test_get_persona_info_invalid(test_client):
    """GET /api/setup/persona/{id} with invalid ID → 404."""
    resp = test_client.get("/api/setup/persona/nonexistent", headers=test_client.auth_headers)
    assert resp.status_code == 404


def test_list_personas(test_client):
    """GET /api/setup/personas → 200, returns all available personas."""
    resp = test_client.get("/api/setup/personas", headers=test_client.auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "personas" in data
    assert isinstance(data["personas"], list)
    assert len(data["personas"]) > 0
    # Check structure of first persona
    persona = data["personas"][0]
    assert "id" in persona
    assert "name" in persona
    assert "system_prompt" in persona


def test_chat_endpoint(test_client, mock_aiohttp_session):
    """POST /api/chat → 200, returns LLM response."""
    session = mock_aiohttp_session(
        status=200,
        json_data={
            "choices": [
                {"message": {"content": "Hello! How can I help you?"}}
            ]
        }
    )

    with patch("aiohttp.ClientSession", return_value=session):
        resp = test_client.post(
            "/api/chat",
            json={"message": "Hello"},
            headers=test_client.auth_headers
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "response" in data
        assert len(data["response"]) > 0


def test_chat_endpoint_llm_unreachable(test_client, mock_aiohttp_session):
    """POST /api/chat when LLM unreachable → 503."""
    import aiohttp
    session = mock_aiohttp_session(raise_on_get=aiohttp.ClientError("Connection refused"))

    with patch("aiohttp.ClientSession", return_value=session):
        resp = test_client.post(
            "/api/chat",
            json={"message": "Hello"},
            headers=test_client.auth_headers
        )
        assert resp.status_code == 503
        assert "Cannot reach LLM backend" in resp.json()["detail"]
