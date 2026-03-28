"""Shared test fixtures for the agentic research app.

Fixtures provide mock providers and test infrastructure so unit tests
run fast without hitting external APIs. Mark tests that call real APIs
or LLMs with @pytest.mark.slow — these are excluded from the PostToolUse
hook and only run in full test suite passes.
"""

import pytest


# TODO Phase 1: Add mock SearchProvider fixture
# @pytest.fixture
# def mock_search_provider():
#     """Returns a SearchProvider that returns canned results without hitting Tavily."""
#     ...


# TODO Phase 1: Add mock Claude API fixture
# @pytest.fixture
# def mock_claude_client():
#     """Returns a patched Anthropic client that returns canned tool-use responses."""
#     ...


# TODO Phase 2: Add test ChromaDB fixture
# @pytest.fixture
# def test_vector_store(tmp_path):
#     """Returns a ChromaDB VectorStore using a temporary directory (cleaned up after test)."""
#     ...


# TODO Phase 2: Add mock EmbeddingProvider fixture
# @pytest.fixture
# def mock_embedding_provider():
#     """Returns an EmbeddingProvider that returns random vectors (fast, no model download)."""
#     ...
