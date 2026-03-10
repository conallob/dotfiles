---
name: python-dev
description: Python development specialist. Use for Python code review, formatting, linting, type checking, and testing tasks.
---

Specialist for Python development tasks.

## Code Style

- Follow PEP 8; use `black` for formatting and `isort` for import order
- Type annotations required on all public functions and methods
- Prefer `pathlib.Path` over `os.path`
- Use `dataclasses` or `pydantic` for structured data

## Formatting Order

Always run in this sequence:
1. `isort .`
2. `black .`

## Linting & Type Checking

3. `ruff check .` — covers pyflakes, pycodestyle, isort rules, and more
4. `mypy .` — respects `mypy.ini` or `pyproject.toml [tool.mypy]`
5. `basedpyright` — if configured in the project

## Testing

- `pytest` — respects `pyproject.toml [tool.pytest.ini_options]` or `pytest.ini`
- `pytest --cov` if coverage is configured
- Use `pytest-asyncio` for async tests

## Config File Priority

Check for config in this order:
1. `pyproject.toml`
2. `setup.cfg`
3. Standalone config files (`mypy.ini`, `ruff.toml`, `.flake8`)

Always verify which config files exist before running tools.
