# AGENTS.md - Python

# APPLIES-TO: python

This document provides guidance for AI assistants working with Python code in this repository.

## Project Context

This repository contains Python applications and tools for automation, data processing, API services, and infrastructure management. Code should follow Python best practices, be fully type-hinted, maintainable, and production-ready.

## Core Principles

### 1. Type Hints (Mandatory)

- **ALL code must use type hints** - Functions, methods, variables, and class attributes
- Use `mypy` in strict mode for type checking
- Prefer specific types over `Any` whenever possible
- Use `typing` and `collections.abc` for generic types
- Document complex types with `TypeAlias`

### 2. Modern Python

- Target Python 3.11+ (use 3.12 features when appropriate)
- Use modern syntax (match/case, union types with `|`, etc.)
- Leverage dataclasses and Pydantic models
- Use pathlib for file operations
- Prefer f-strings for formatting

### 3. Dependency Management

- **Primary: Use `uv` for dependency management** (fast, reliable, rust-based)
- Alternative support for `poetry`, `pip-tools`, or `venv`
- Lock dependencies for reproducibility
- Separate dev dependencies from production

### 4. Code Quality

- Use `ruff` for linting and formatting (replaces black, isort, flake8)
- Run `mypy --strict` for type checking
- Write tests with `pytest`
- Aim for >80% code coverage
- Use pre-commit hooks

## Project Structure

### Standard Layout

```
.
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── main.py
│       ├── api/
│       │   ├── __init__.py
│       │   └── routes.py
│       ├── core/
│       │   ├── __init__.py
│       │   ├── config.py
│       │   └── logging.py
│       ├── models/
│       │   ├── __init__.py
│       │   └── schemas.py
│       └── services/
│           ├── __init__.py
│           └── azure.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   │   └── test_services.py
│   └── integration/
│       └── test_api.py
├── scripts/
│   ├── deploy.py
│   └── setup.sh
├── docs/
│   └── architecture.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── pyproject.toml          # Project configuration (uv/poetry/setuptools)
├── uv.lock                 # Locked dependencies (uv)
├── .python-version         # Python version (for uv/pyenv)
├── requirements.txt        # Compiled dependencies (for pip)
├── requirements-dev.txt    # Dev dependencies (for pip)
├── mypy.ini               # Type checking configuration
├── ruff.toml              # Linting configuration
├── .pre-commit-config.yaml
├── Dockerfile
├── Makefile
└── README.md
```

## Environment Setup

### Using uv (Recommended)

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create project with uv
uv init myproject
cd myproject

# Set Python version
echo "3.12" > .python-version

# Add dependencies
uv add fastapi uvicorn pydantic
uv add --dev pytest mypy ruff

# Add Azure SDK
uv add azure-identity azure-storage-blob azure-mgmt-resource

# Install dependencies
uv sync

# Run Python with uv
uv run python -m myproject.main

# Run scripts
uv run pytest
uv run mypy src/
uv run ruff check src/
```

### Using Poetry (Alternative)

```bash
# Install poetry
curl -sSL https://install.python-poetry.org | python3 -

# Create project
poetry new myproject
cd myproject

# Add dependencies
poetry add fastapi uvicorn pydantic
poetry add --group dev pytest mypy ruff

# Install
poetry install

# Run commands
poetry run python -m myproject.main
poetry run pytest
```

### Using pip + venv (Alternative)

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows

# Install pip-tools
pip install pip-tools

# Create requirements.in
cat > requirements.in <<EOF
fastapi
uvicorn
pydantic
azure-identity
EOF

# Compile requirements
pip-compile requirements.in
pip-compile requirements-dev.in

# Install
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

## pyproject.toml Configuration

### For uv

```toml
[project]
name = "myproject"
version = "0.1.0"
description = "Azure infrastructure automation tool"
readme = "README.md"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
    "pydantic>=2.9.0",
    "pydantic-settings>=2.6.0",
    "azure-identity>=1.19.0",
    "azure-mgmt-resource>=23.2.0",
    "azure-storage-blob>=12.23.0",
    "httpx>=0.27.0",
    "structlog>=24.4.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-cov>=6.0.0",
    "pytest-asyncio>=0.24.0",
    "mypy>=1.13.0",
    "ruff>=0.7.0",
    "types-requests",
]

[project.scripts]
myproject = "myproject.main:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = [
    "pytest>=8.3.0",
    "pytest-cov>=6.0.0",
    "mypy>=1.13.0",
    "ruff>=0.7.0",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "A",   # flake8-builtins
    "C4",  # flake8-comprehensions
    "DTZ", # flake8-datetimez
    "T20", # flake8-print
    "SIM", # flake8-simplify
    "ARG", # flake8-unused-arguments
    "PTH", # flake8-use-pathlib
    "ERA", # eradicate
    "RUF", # ruff-specific rules
]
ignore = [
    "E501",  # line too long (handled by formatter)
]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = ["ARG", "S101"]  # Allow assertions and unused args in tests

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_any_generics = true
check_untyped_defs = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
plugins = ["pydantic.mypy"]

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-report=html",
]
asyncio_mode = "auto"

[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/__pycache__/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
    "@abstractmethod",
]
```

## Code Templates

### Main Application with Type Hints

```python
"""Main application entry point."""

from __future__ import annotations

import asyncio
import logging
import sys
from pathlib import Path
from typing import NoReturn

import structlog
from pydantic import ValidationError

from myproject.core.config import Settings, load_settings
from myproject.core.logging import setup_logging
from myproject.services.azure import AzureResourceManager

logger = structlog.get_logger()


async def main() -> int:
    """Run the main application.

    Returns:
        Exit code (0 for success, non-zero for error).
    """
    # Setup logging
    setup_logging()

    # Load configuration
    try:
        settings = load_settings()
    except ValidationError as e:
        logger.error("Invalid configuration", error=str(e))
        return 1

    # Initialize services
    try:
        async with AzureResourceManager(
            subscription_id=settings.azure_subscription_id,
            tenant_id=settings.azure_tenant_id,
        ) as manager:
            # Do work
            resources = await manager.list_resource_groups()
            logger.info("Listed resources", count=len(resources))

    except Exception as e:
        logger.exception("Application error", error=str(e))
        return 1

    return 0


def run() -> NoReturn:
    """Entry point for console script."""
    exit_code = asyncio.run(main())
    sys.exit(exit_code)


if __name__ == "__main__":
    run()
```

### Configuration with Pydantic

```python
"""Application configuration using Pydantic settings."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application settings
    app_name: str = "myproject"
    app_version: str = "0.1.0"
    environment: Literal["development", "staging", "production"] = "development"
    debug: bool = False
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"

    # Azure settings
    azure_subscription_id: str = Field(..., description="Azure subscription ID")
    azure_tenant_id: str = Field(..., description="Azure tenant ID")
    azure_client_id: str | None = Field(None, description="Azure client ID for service principal")
    azure_client_secret: str | None = Field(None, description="Azure client secret")

    # API settings
    api_host: str = "0.0.0.0"
    api_port: int = Field(8000, ge=1, le=65535)
    api_workers: int = Field(4, ge=1, le=32)
    api_timeout: int = Field(30, ge=1)

    # Database settings (example)
    database_url: str | None = None
    database_pool_size: int = Field(5, ge=1, le=100)

    @field_validator("log_level", mode="before")
    @classmethod
    def uppercase_log_level(cls, v: str) -> str:
        """Ensure log level is uppercase."""
        return v.upper() if isinstance(v, str) else v

    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment == "production"


@lru_cache
def load_settings() -> Settings:
    """Load and cache settings.

    Returns:
        Application settings instance.
    """
    return Settings()
```

### Azure Service with Type Hints

```python
"""Azure resource management service."""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator, Sequence
from contextlib import asynccontextmanager
from typing import Any, Protocol, TypeAlias

import structlog
from azure.core.credentials import TokenCredential
from azure.identity.aio import DefaultAzureCredential
from azure.mgmt.resource.aio import ResourceManagementClient
from azure.mgmt.resource.models import ResourceGroup

logger = structlog.get_logger()

# Type aliases for clarity
ResourceGroupList: TypeAlias = Sequence[ResourceGroup]
ResourceTags: TypeAlias = dict[str, str]


class AzureCredentialProvider(Protocol):
    """Protocol for Azure credential providers."""

    async def get_token(self, *scopes: str, **kwargs: Any) -> Any:
        """Get an access token."""
        ...

    async def close(self) -> None:
        """Close the credential provider."""
        ...


class AzureResourceManager:
    """Manages Azure resources with async context manager support.

    Example:
        >>> async with AzureResourceManager(subscription_id="...") as manager:
        ...     groups = await manager.list_resource_groups()
        ...     for group in groups:
        ...         print(group.name)
    """

    def __init__(
        self,
        subscription_id: str,
        tenant_id: str | None = None,
        credential: TokenCredential | None = None,
        *,
        timeout: int = 30,
    ) -> None:
        """Initialize Azure resource manager.

        Args:
            subscription_id: Azure subscription ID.
            tenant_id: Azure tenant ID (optional).
            credential: Custom credential (optional, uses DefaultAzureCredential if None).
            timeout: Request timeout in seconds.
        """
        self.subscription_id = subscription_id
        self.tenant_id = tenant_id
        self.timeout = timeout
        self._credential = credential
        self._client: ResourceManagementClient | None = None

    async def __aenter__(self) -> AzureResourceManager:
        """Enter async context manager."""
        await self._connect()
        return self

    async def __aexit__(self, *args: Any) -> None:
        """Exit async context manager."""
        await self.close()

    async def _connect(self) -> None:
        """Initialize Azure client connection."""
        if self._credential is None:
            self._credential = DefaultAzureCredential()

        self._client = ResourceManagementClient(
            credential=self._credential,
            subscription_id=self.subscription_id,
        )

        logger.info(
            "Connected to Azure",
            subscription_id=self.subscription_id,
            tenant_id=self.tenant_id,
        )

    async def close(self) -> None:
        """Close Azure client connections."""
        if self._client is not None:
            await self._client.close()

        if self._credential is not None:
            await self._credential.close()

        logger.info("Closed Azure connections")

    async def list_resource_groups(self, *, tags: ResourceTags | None = None) -> ResourceGroupList:
        """List all resource groups in the subscription.

        Args:
            tags: Filter by tags (optional).

        Returns:
            List of resource groups.

        Raises:
            ValueError: If client not initialized.
            RuntimeError: If API call fails.
        """
        if self._client is None:
            raise ValueError("Client not initialized. Use 'async with' context manager.")

        try:
            groups: list[ResourceGroup] = []
            async for group in self._client.resource_groups.list():
                # Filter by tags if provided
                if tags and not self._match_tags(group.tags or {}, tags):
                    continue
                groups.append(group)

            logger.info("Listed resource groups", count=len(groups))
            return groups

        except Exception as e:
            logger.exception("Failed to list resource groups", error=str(e))
            raise RuntimeError(f"Failed to list resource groups: {e}") from e

    async def get_resource_group(self, name: str) -> ResourceGroup:
        """Get a specific resource group by name.

        Args:
            name: Resource group name.

        Returns:
            Resource group details.

        Raises:
            ValueError: If client not initialized or resource group not found.
            RuntimeError: If API call fails.
        """
        if self._client is None:
            raise ValueError("Client not initialized. Use 'async with' context manager.")

        try:
            group = await self._client.resource_groups.get(name)
            logger.info("Retrieved resource group", name=name)
            return group

        except Exception as e:
            logger.exception("Failed to get resource group", name=name, error=str(e))
            raise RuntimeError(f"Failed to get resource group: {e}") from e

    async def create_resource_group(
        self,
        name: str,
        location: str,
        *,
        tags: ResourceTags | None = None,
    ) -> ResourceGroup:
        """Create a new resource group.

        Args:
            name: Resource group name.
            location: Azure region (e.g., 'eastus').
            tags: Resource tags (optional).

        Returns:
            Created resource group.

        Raises:
            ValueError: If client not initialized.
            RuntimeError: If API call fails.
        """
        if self._client is None:
            raise ValueError("Client not initialized. Use 'async with' context manager.")

        try:
            parameters = {
                "location": location,
                "tags": tags or {},
            }

            group = await self._client.resource_groups.create_or_update(
                name,
                parameters,
            )

            logger.info(
                "Created resource group",
                name=name,
                location=location,
                tags=tags,
            )
            return group

        except Exception as e:
            logger.exception("Failed to create resource group", name=name, error=str(e))
            raise RuntimeError(f"Failed to create resource group: {e}") from e

    @staticmethod
    def _match_tags(resource_tags: dict[str, str], filter_tags: dict[str, str]) -> bool:
        """Check if resource tags match filter tags.

        Args:
            resource_tags: Tags on the resource.
            filter_tags: Tags to filter by.

        Returns:
            True if all filter tags are present in resource tags.
        """
        return all(
            resource_tags.get(key) == value
            for key, value in filter_tags.items()
        )


# Factory function pattern
def create_resource_manager(
    subscription_id: str,
    tenant_id: str | None = None,
    **kwargs: Any,
) -> AzureResourceManager:
    """Factory function to create an Azure resource manager.

    Args:
        subscription_id: Azure subscription ID.
        tenant_id: Azure tenant ID (optional).
        **kwargs: Additional arguments passed to AzureResourceManager.

    Returns:
        Configured resource manager instance.
    """
    return AzureResourceManager(
        subscription_id=subscription_id,
        tenant_id=tenant_id,
        **kwargs,
    )
```

### Data Models with Pydantic

```python
"""Data models for Azure resources."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field, field_validator


class ResourceState(str, Enum):
    """Resource provisioning states."""

    CREATING = "Creating"
    RUNNING = "Running"
    UPDATING = "Updating"
    DELETING = "Deleting"
    FAILED = "Failed"
    SUCCEEDED = "Succeeded"


class AzureLocation(str, Enum):
    """Common Azure regions."""

    EAST_US = "eastus"
    WEST_US = "westus"
    CENTRAL_US = "centralus"
    NORTH_EUROPE = "northeurope"
    WEST_EUROPE = "westeurope"


class ResourceBase(BaseModel):
    """Base model for Azure resources."""

    id: str = Field(..., description="Resource ID")
    name: str = Field(..., description="Resource name")
    type: str = Field(..., description="Resource type")
    location: str = Field(..., description="Azure region")
    tags: dict[str, str] = Field(default_factory=dict, description="Resource tags")

    model_config = {
        "frozen": False,
        "extra": "allow",
        "str_strip_whitespace": True,
    }


class ResourceGroupModel(ResourceBase):
    """Model for Azure resource group."""

    provisioning_state: ResourceState = Field(..., description="Provisioning state")
    managed_by: str | None = Field(None, description="Managing resource")

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate resource group name format."""
        if not v or len(v) > 90:
            raise ValueError("Resource group name must be 1-90 characters")
        if not v.replace("-", "").replace("_", "").replace(".", "").isalnum():
            raise ValueError("Resource group name contains invalid characters")
        return v


class StorageAccountModel(ResourceBase):
    """Model for Azure storage account."""

    sku_name: str = Field(..., description="SKU name")
    kind: str = Field(..., description="Storage account kind")
    primary_endpoints: dict[str, str] = Field(default_factory=dict)
    creation_time: datetime | None = None

    @field_validator("name")
    @classmethod
    def validate_storage_name(cls, v: str) -> str:
        """Validate storage account name format."""
        if not v or len(v) > 24:
            raise ValueError("Storage account name must be 3-24 characters")
        if not v.islower() or not v.isalnum():
            raise ValueError("Storage account name must be lowercase alphanumeric")
        return v


class ResourceListResponse(BaseModel):
    """Response model for resource list operations."""

    resources: list[ResourceBase]
    total_count: int = Field(..., ge=0)
    page_token: str | None = None

    @classmethod
    def from_azure_response(cls, resources: list[Any]) -> ResourceListResponse:
        """Create response from Azure SDK response.

        Args:
            resources: List of resources from Azure SDK.

        Returns:
            Formatted response model.
        """
        return cls(
            resources=[
                ResourceBase(
                    id=r.id,
                    name=r.name,
                    type=r.type,
                    location=r.location,
                    tags=r.tags or {},
                )
                for r in resources
            ],
            total_count=len(resources),
        )
```

### FastAPI Application with Type Hints

```python
"""FastAPI application with typed routes."""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Annotated

import structlog
from fastapi import Depends, FastAPI, HTTPException, Query, status
from fastapi.responses import JSONResponse

from myproject.core.config import Settings, load_settings
from myproject.models.schemas import ResourceGroupModel, ResourceListResponse
from myproject.services.azure import AzureResourceManager, create_resource_manager

logger = structlog.get_logger()


# Dependency injection
async def get_settings() -> Settings:
    """Get application settings."""
    return load_settings()


async def get_azure_manager(
    settings: Annotated[Settings, Depends(get_settings)],
) -> AsyncIterator[AzureResourceManager]:
    """Get Azure resource manager with dependency injection.

    Yields:
        Configured Azure resource manager.
    """
    async with create_resource_manager(
        subscription_id=settings.azure_subscription_id,
        tenant_id=settings.azure_tenant_id,
    ) as manager:
        yield manager


# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan context manager.

    Args:
        app: FastAPI application instance.

    Yields:
        None during application lifetime.
    """
    logger.info("Starting application")
    # Startup logic here
    yield
    # Shutdown logic here
    logger.info("Shutting down application")


# Create FastAPI app
app = FastAPI(
    title="Azure Resource Manager API",
    description="API for managing Azure resources",
    version="0.1.0",
    lifespan=lifespan,
)


@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check() -> dict[str, str]:
    """Health check endpoint.

    Returns:
        Health status.
    """
    return {"status": "healthy"}


@app.get(
    "/api/v1/resource-groups",
    response_model=ResourceListResponse,
    status_code=status.HTTP_200_OK,
)
async def list_resource_groups(
    manager: Annotated[AzureResourceManager, Depends(get_azure_manager)],
    tag_key: Annotated[str | None, Query()] = None,
    tag_value: Annotated[str | None, Query()] = None,
) -> ResourceListResponse:
    """List all resource groups.

    Args:
        manager: Azure resource manager (injected).
        tag_key: Filter by tag key (optional).
        tag_value: Filter by tag value (optional).

    Returns:
        List of resource groups.

    Raises:
        HTTPException: If listing fails.
    """
    try:
        tags = {tag_key: tag_value} if tag_key and tag_value else None
        groups = await manager.list_resource_groups(tags=tags)

        return ResourceListResponse.from_azure_response(groups)

    except Exception as e:
        logger.exception("Failed to list resource groups", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list resource groups: {e}",
        ) from e


@app.get(
    "/api/v1/resource-groups/{name}",
    response_model=ResourceGroupModel,
    status_code=status.HTTP_200_OK,
)
async def get_resource_group(
    name: str,
    manager: Annotated[AzureResourceManager, Depends(get_azure_manager)],
) -> ResourceGroupModel:
    """Get a specific resource group.

    Args:
        name: Resource group name.
        manager: Azure resource manager (injected).

    Returns:
        Resource group details.

    Raises:
        HTTPException: If resource group not found or retrieval fails.
    """
    try:
        group = await manager.get_resource_group(name)

        return ResourceGroupModel(
            id=group.id,
            name=group.name,
            type=group.type,
            location=group.location,
            tags=group.tags or {},
            provisioning_state=group.properties.provisioning_state,
            managed_by=group.managed_by,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        ) from e
    except Exception as e:
        logger.exception("Failed to get resource group", name=name, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get resource group: {e}",
        ) from e


@app.post(
    "/api/v1/resource-groups",
    response_model=ResourceGroupModel,
    status_code=status.HTTP_201_CREATED,
)
async def create_resource_group(
    data: ResourceGroupModel,
    manager: Annotated[AzureResourceManager, Depends(get_azure_manager)],
) -> ResourceGroupModel:
    """Create a new resource group.

    Args:
        data: Resource group data.
        manager: Azure resource manager (injected).

    Returns:
        Created resource group.

    Raises:
        HTTPException: If creation fails.
    """
    try:
        group = await manager.create_resource_group(
            name=data.name,
            location=data.location,
            tags=data.tags,
        )

        return ResourceGroupModel(
            id=group.id,
            name=group.name,
            type=group.type,
            location=group.location,
            tags=group.tags or {},
            provisioning_state=group.properties.provisioning_state,
            managed_by=group.managed_by,
        )

    except Exception as e:
        logger.exception("Failed to create resource group", name=data.name, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create resource group: {e}",
        ) from e
```

## Testing Patterns

### Unit Tests with Type Hints

```python
"""Unit tests for Azure resource manager."""

from __future__ import annotations

from typing import Any
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from azure.mgmt.resource.models import ResourceGroup

from myproject.services.azure import AzureResourceManager


@pytest.fixture
def mock_credential() -> AsyncMock:
    """Mock Azure credential."""
    return AsyncMock()


@pytest.fixture
def mock_client() -> AsyncMock:
    """Mock Azure resource management client."""
    client = AsyncMock()
    client.resource_groups = AsyncMock()
    return client


@pytest.fixture
def resource_manager(mock_credential: AsyncMock) -> AzureResourceManager:
    """Create resource manager with mocked credential."""
    return AzureResourceManager(
        subscription_id="test-sub",
        tenant_id="test-tenant",
        credential=mock_credential,
    )


class TestAzureResourceManager:
    """Test suite for AzureResourceManager."""

    async def test_context_manager(
        self,
        resource_manager: AzureResourceManager,
        mock_client: AsyncMock,
    ) -> None:
        """Test async context manager initialization."""
        with patch(
            "myproject.services.azure.ResourceManagementClient",
            return_value=mock_client,
        ):
            async with resource_manager as manager:
                assert manager._client is not None
                assert manager._credential is not None

            # Verify cleanup
            mock_client.close.assert_called_once()

    async def test_list_resource_groups_success(
        self,
        resource_manager: AzureResourceManager,
        mock_client: AsyncMock,
    ) -> None:
        """Test successful resource group listing."""
        # Setup mock
        mock_groups = [
            ResourceGroup(
                id="/subscriptions/test/resourceGroups/rg1",
                name="rg1",
                location="eastus",
                tags={"env": "test"},
            ),
            ResourceGroup(
                id="/subscriptions/test/resourceGroups/rg2",
                name="rg2",
                location="westus",
                tags={"env": "prod"},
            ),
        ]

        async def mock_list() -> AsyncIterator[ResourceGroup]:
            for group in mock_groups:
                yield group

        mock_client.resource_groups.list.return_value = mock_list()

        with patch(
            "myproject.services.azure.ResourceManagementClient",
            return_value=mock_client,
        ):
            async with resource_manager as manager:
                groups = await manager.list_resource_groups()

                assert len(groups) == 2
                assert groups[0].name == "rg1"
                assert groups[1].name == "rg2"

    async def test_list_resource_groups_with_tags(
        self,
        resource_manager: AzureResourceManager,
        mock_client: AsyncMock,
    ) -> None:
        """Test resource group listing with tag filtering."""
        mock_groups = [
            ResourceGroup(
                id="/subscriptions/test/resourceGroups/rg1",
                name="rg1",
                location="eastus",
                tags={"env": "test"},
            ),
            ResourceGroup(
                id="/subscriptions/test/resourceGroups/rg2",
                name="rg2",
                location="westus",
                tags={"env": "prod"},
            ),
        ]

        async def mock_list() -> AsyncIterator[ResourceGroup]:
            for group in mock_groups:
                yield group

        mock_client.resource_groups.list.return_value = mock_list()

        with patch(
            "myproject.services.azure.ResourceManagementClient",
            return_value=mock_client,
        ):
            async with resource_manager as manager:
                groups = await manager.list_resource_groups(tags={"env": "test"})

                assert len(groups) == 1
                assert groups[0].name == "rg1"

    async def test_list_resource_groups_not_initialized(
        self,
        resource_manager: AzureResourceManager,
    ) -> None:
        """Test listing without initialization raises error."""
        with pytest.raises(ValueError, match="Client not initialized"):
            await resource_manager.list_resource_groups()

    async def test_get_resource_group_success(
        self,
        resource_manager: AzureResourceManager,
        mock_client: AsyncMock,
    ) -> None:
        """Test successful resource group retrieval."""
        mock_group = ResourceGroup(
            id="/subscriptions/test/resourceGroups/rg1",
            name="rg1",
            location="eastus",
            tags={"env": "test"},
        )

        mock_client.resource_groups.get.return_value = mock_group

        with patch(
            "myproject.services.azure.ResourceManagementClient",
            return_value=mock_client,
        ):
            async with resource_manager as manager:
                group = await manager.get_resource_group("rg1")

                assert group.name == "rg1"
                assert group.location == "eastus"
                mock_client.resource_groups.get.assert_called_once_with("rg1")

    async def test_create_resource_group_success(
        self,
        resource_manager: AzureResourceManager,
        mock_client: AsyncMock,
    ) -> None:
        """Test successful resource group creation."""
        mock_group = ResourceGroup(
            id="/subscriptions/test/resourceGroups/new-rg",
            name="new-rg",
            location="eastus",
            tags={"env": "test"},
        )

        mock_client.resource_groups.create_or_update.return_value = mock_group

        with patch(
            "myproject.services.azure.ResourceManagementClient",
            return_value=mock_client,
        ):
            async with resource_manager as manager:
                group = await manager.create_resource_group(
                    name="new-rg",
                    location="eastus",
                    tags={"env": "test"},
                )

                assert group.name == "new-rg"
                assert group.location == "eastus"

                mock_client.resource_groups.create_or_update.assert_called_once()
                call_args = mock_client.resource_groups.create_or_update.call_args
                assert call_args[0][0] == "new-rg"
                assert call_args[0][1]["location"] == "eastus"


# Pytest fixtures for common test data
@pytest.fixture
def sample_resource_group() -> dict[str, Any]:
    """Sample resource group data for testing."""
    return {
        "id": "/subscriptions/test/resourceGroups/rg1",
        "name": "rg1",
        "location": "eastus",
        "tags": {"env": "test", "owner": "devops"},
    }


@pytest.fixture
def sample_storage_account() -> dict[str, Any]:
    """Sample storage account data for testing."""
    return {
        "id": "/subscriptions/test/resourceGroups/rg1/providers/Microsoft.Storage/storageAccounts/sa1",
        "name": "sa1",
        "location": "eastus",
        "sku_name": "Standard_LRS",
        "kind": "StorageV2",
    }
```

### Integration Tests

```python
"""Integration tests for API endpoints."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from httpx import AsyncClient

from myproject.main import app


@pytest.fixture
def client() -> TestClient:
    """Create test client for FastAPI app."""
    return TestClient(app)


@pytest.fixture
async def async_client() -> AsyncClient:
    """Create async test client for FastAPI app."""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac


class TestHealthEndpoint:
    """Test suite for health check endpoint."""

    def test_health_check(self, client: TestClient) -> None:
        """Test health check returns 200."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "healthy"}


class TestResourceGroupEndpoints:
    """Test suite for resource group endpoints."""

    async def test_list_resource_groups(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Test listing resource groups."""
        response = await async_client.get("/api/v1/resource-groups")

        assert response.status_code == 200
        data = response.json()
        assert "resources" in data
        assert "total_count" in data
        assert isinstance(data["resources"], list)

    async def test_list_resource_groups_with_tags(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Test listing resource groups with tag filter."""
        response = await async_client.get(
            "/api/v1/resource-groups",
            params={"tag_key": "env", "tag_value": "test"},
        )

        assert response.status_code == 200

    async def test_get_resource_group(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Test getting specific resource group."""
        response = await async_client.get("/api/v1/resource-groups/test-rg")

        # May be 200 or 404 depending on Azure state
        assert response.status_code in (200, 404)

    async def test_create_resource_group(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Test creating resource group."""
        data = {
            "name": "test-rg-new",
            "location": "eastus",
            "tags": {"env": "test"},
        }

        response = await async_client.post(
            "/api/v1/resource-groups",
            json=data,
        )

        # May be 201 or error depending on Azure state
        assert response.status_code in (201, 500)
```

## Type Checking Best Practices

### Advanced Type Hints

```python
"""Advanced type hint patterns."""

from __future__ import annotations

from collections.abc import Awaitable, Callable, Iterator, Sequence
from typing import (
    Any,
    Generic,
    Literal,
    ParamSpec,
    Protocol,
    TypeAlias,
    TypeVar,
    cast,
    overload,
)

# Type variables
T = TypeVar("T")
T_co = TypeVar("T_co", covariant=True)
T_contra = TypeVar("T_contra", contravariant=True)
P = ParamSpec("P")

# Type aliases for clarity
JSON: TypeAlias = dict[str, Any]
Headers: TypeAlias = dict[str, str]
QueryParams: TypeAlias = dict[str, str | int | bool]


# Protocol for structural typing
class Closeable(Protocol):
    """Protocol for closeable resources."""

    async def close(self) -> None:
        """Close the resource."""
        ...


class SupportsRead(Protocol[T_co]):
    """Protocol for readable resources."""

    def read(self, size: int = -1) -> T_co:
        """Read data from resource."""
        ...


# Generic classes
class Repository(Generic[T]):
    """Generic repository pattern."""

    def __init__(self, item_type: type[T]) -> None:
        """Initialize repository.

        Args:
            item_type: Type of items stored in repository.
        """
        self._item_type = item_type
        self._items: dict[str, T] = {}

    def add(self, key: str, item: T) -> None:
        """Add item to repository."""
        self._items[key] = item

    def get(self, key: str) -> T | None:
        """Get item from repository."""
        return self._items.get(key)

    def list_all(self) -> Sequence[T]:
        """List all items."""
        return list(self._items.values())


# Overloaded functions
@overload
def process_data(data: str) -> str:
    ...


@overload
def process_data(data: int) -> int:
    ...


@overload
def process_data(data: list[str]) -> list[str]:
    ...


def process_data(data: str | int | list[str]) -> str | int | list[str]:
    """Process data with type-specific logic.

    Args:
        data: Input data of various types.

    Returns:
        Processed data of same type as input.
    """
    if isinstance(data, str):
        return data.upper()
    elif isinstance(data, int):
        return data * 2
    else:
        return [item.upper() for item in data]


# Callable types
SyncHandler: TypeAlias = Callable[[str], None]
AsyncHandler: TypeAlias = Callable[[str], Awaitable[None]]
DecoratorType: TypeAlias = Callable[[Callable[P, T]], Callable[P, T]]


def with_logging(func: Callable[P, T]) -> Callable[P, T]:
    """Decorator that adds logging to a function.

    Args:
        func: Function to decorate.

    Returns:
        Decorated function with same signature.
    """
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        print(f"Calling {func.__name__}")
        result = func(*args, **kwargs)
        print(f"Finished {func.__name__}")
        return result

    return wrapper


# Type narrowing with TypeGuard
from typing import TypeGuard


def is_string_list(val: list[Any]) -> TypeGuard[list[str]]:
    """Check if list contains only strings.

    Args:
        val: List to check.

    Returns:
        True if all elements are strings.
    """
    return all(isinstance(item, str) for item in val)


def process_strings(items: list[Any]) -> None:
    """Process list of items, requiring all to be strings.

    Args:
        items: List of items to process.
    """
    if is_string_list(items):
        # Type narrowed to list[str]
        for item in items:
            print(item.upper())  # No type error
```

### mypy Configuration

```ini
# mypy.ini
[mypy]
python_version = 3.11
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_any_generics = True
disallow_subclassing_any = True
disallow_untyped_calls = True
disallow_untyped_decorators = True
disallow_incomplete_defs = True
check_untyped_defs = True
no_implicit_optional = True
warn_redundant_casts = True
warn_unused_ignores = True
warn_no_return = True
warn_unreachable = True
strict_equality = True
strict = True

# Pydantic plugin
plugins = pydantic.mypy

[pydantic-mypy]
init_forbid_extra = True
init_typed = True
warn_required_dynamic_aliases = True

# Per-module overrides
[mypy-tests.*]
disallow_untyped_defs = False

[mypy-azure.*]
ignore_missing_imports = True

[mypy-uvicorn.*]
ignore_missing_imports = True
```

## Makefile

```makefile
.PHONY: help install dev test lint format type-check clean run docker-build

# Variables
PYTHON := python
UV := uv
PROJECT_NAME := myproject
SRC_DIR := src
TEST_DIR := tests

# Help
help:
	@echo "Available targets:"
	@echo "  install      - Install production dependencies"
	@echo "  dev          - Install development dependencies"
	@echo "  test         - Run tests with coverage"
	@echo "  lint         - Run linting checks"
	@echo "  format       - Format code with ruff"
	@echo "  type-check   - Run mypy type checking"
	@echo "  clean        - Remove generated files"
	@echo "  run          - Run the application"
	@echo "  docker-build - Build Docker image"

# Installation (using uv)
install:
	$(UV) sync --no-dev

dev:
	$(UV) sync

# Alternative: Using poetry
install-poetry:
	poetry install --no-dev

dev-poetry:
	poetry install

# Alternative: Using pip
install-pip:
	pip install -r requirements.txt

dev-pip:
	pip install -r requirements.txt -r requirements-dev.txt

# Testing
test:
	$(UV) run pytest $(TEST_DIR) -v --cov=$(SRC_DIR) --cov-report=term-missing --cov-report=html

test-unit:
	$(UV) run pytest $(TEST_DIR)/unit -v

test-integration:
	$(UV) run pytest $(TEST_DIR)/integration -v

# Linting and formatting
lint:
	$(UV) run ruff check $(SRC_DIR) $(TEST_DIR)

format:
	$(UV) run ruff format $(SRC_DIR) $(TEST_DIR)
	$(UV) run ruff check --fix $(SRC_DIR) $(TEST_DIR)

# Type checking
type-check:
	$(UV) run mypy $(SRC_DIR)

# All checks
check: lint type-check test

# Clean
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	rm -rf .ruff_cache
	rm -rf htmlcov
	rm -rf dist
	rm -rf build
	rm -f .coverage

# Run application
run:
	$(UV) run python -m $(PROJECT_NAME).main

# Docker
docker-build:
	docker build -t $(PROJECT_NAME):latest .

docker-run:
	docker run -p 8000:8000 $(PROJECT_NAME):latest

# CI target
ci: lint type-check test
```

## Dockerfile

```dockerfile
# Multi-stage build using uv
FROM python:3.12-slim as builder

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen --no-dev --no-install-project

# Copy source code
COPY src/ ./src/

# Install project
RUN uv sync --frozen --no-dev

# Runtime stage
FROM python:3.12-slim

WORKDIR /app

# Copy installed dependencies and source from builder
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Expose port
EXPOSE 8000

# Run application
CMD ["python", "-m", "myproject.main"]
```

## Pre-commit Configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-json
      - id: check-toml
      - id: check-merge-conflict
      - id: debug-statements

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.7.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.13.0
    hooks:
      - id: mypy
        additional_dependencies:
          - pydantic
          - types-requests
        args: [--strict]
```

## AI Assistant Guidelines

### When Reviewing Code

1. **Check Type Hints**
   - Verify ALL functions have complete type hints
   - Check for `Any` usage - should be minimized
   - Ensure return types are specified
   - Verify Pydantic models use proper field types

2. **Check Code Quality**
   - Run ruff and mypy in strict mode
   - Verify proper error handling
   - Check for proper async/await usage
   - Ensure resources are properly cleaned up

3. **Check Best Practices**
   - Verify use of Pydantic for data validation
   - Check for proper logging with structured logging
   - Ensure configuration uses environment variables
   - Verify proper use of async context managers

4. **Check Dependencies**
   - Verify uv.lock is up to date
   - Check for security vulnerabilities
   - Ensure dependencies are pinned appropriately

5. **Check Protobuf/gRPC**
   - Verify proto files follow naming conventions
   - Check that type stubs are generated (mypy-protobuf)
   - Ensure proper error handling in gRPC methods
   - Verify streaming RPCs handle cancellation

6. **Check MCP Servers**
   - Verify all tools have proper input schemas
   - Check that tool implementations match schemas
   - Ensure proper error handling and logging
   - Verify resources are properly typed

### When Writing Code

1. Always start with type hints
2. Use Pydantic for data validation
3. Use async/await for I/O operations
4. Implement proper error handling
5. Add docstrings with type information
6. Write tests alongside code
7. Use context managers for resources
8. Prefer composition over inheritance
9. Keep functions small and focused
10. Use type aliases for complex types

### When Writing Protobuf

1. Always generate type stubs with mypy-protobuf
2. Use well-known types (Timestamp, Duration, etc.)
3. Implement proper error handling in servicers
4. Use streaming for large data sets
5. Handle gRPC context cancellation properly
6. Test both client and server implementations

### When Writing MCP Servers

1. Define clear, typed argument schemas with Pydantic
2. Use descriptive tool and resource names
3. Implement proper error handling in all tools
4. Return structured data (JSON) from tools
5. Test tools with actual MCP clients
6. Document all available tools and resources
7. Use async context managers for resource management

### When Writing Tests

1. Use type hints in test functions
2. Use pytest fixtures for setup
3. Mock external dependencies
4. Test both success and error cases
5. Use parametrize for multiple test cases
6. Keep tests focused and independent
7. Use AsyncMock for async functions
8. Verify type correctness with reveal_type in tests

### When Debugging

1. Check mypy output first
2. Use reveal_type() to understand types
3. Add type: ignore comments only as last resort
4. Use debugger with type information
5. Check for unhandled async operations
6. Verify context manager usage

## Common Patterns

### Async Context Manager

```python
from __future__ import annotations

from typing import Any, Self


class AsyncResource:
    """Async resource with context manager."""

    async def __aenter__(self) -> Self:
        """Enter async context."""
        await self._connect()
        return self

    async def __aexit__(self, *args: Any) -> None:
        """Exit async context."""
        await self._disconnect()

    async def _connect(self) -> None:
        """Connect to resource."""
        ...

    async def _disconnect(self) -> None:
        """Disconnect from resource."""
        ...
```

### Dependency Injection

```python
from __future__ import annotations

from collections.abc import Callable
from typing import Annotated, TypeVar

from fastapi import Depends

T = TypeVar("T")


def get_service() -> Service:
    """Dependency provider for service."""
    return Service()


async def endpoint(
    service: Annotated[Service, Depends(get_service)],
) -> dict[str, str]:
    """Endpoint with injected dependency."""
    return await service.do_work()
```

### Factory Pattern with Type Hints

```python
from __future__ import annotations

from typing import Protocol, TypeVar

T = TypeVar("T", bound="Creatable")


class Creatable(Protocol):
    """Protocol for creatable types."""

    @classmethod
    def create(cls: type[T], **kwargs: Any) -> T:
        """Create instance."""
        ...


class Factory:
    """Generic factory."""

    def create_instance(self, cls: type[T], **kwargs: Any) -> T:
        """Create instance of given type."""
        return cls.create(**kwargs)
```

## Resources

- [Python Type Hints Documentation](https://docs.python.org/3/library/typing.html)
- [mypy Documentation](https://mypy.readthedocs.io/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [uv Documentation](https://docs.astral.sh/uv/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [pytest Documentation](https://docs.pytest.org/)
- [Azure SDK for Python](https://github.com/Azure/azure-sdk-for-python)

## Protocol Buffers

### Overview

Protocol Buffers (protobuf) in Python are used for:

- gRPC service definitions
- Data serialization for storage and transmission
- Cross-language data interchange
- High-performance data processing

### Installation

```bash
# Using uv
uv add grpcio grpcio-tools protobuf
uv add --dev mypy-protobuf  # Type stubs generator

# Using poetry
poetry add grpcio grpcio-tools protobuf
poetry add --group dev mypy-protobuf

# Using pip
pip install grpcio grpcio-tools protobuf mypy-protobuf
```

### Project Structure

```
.
├── protos/
│   └── v1/
│       ├── service.proto
│       └── models.proto
├── src/
│   └── myproject/
│       ├── generated/          # Generated Python code
│       │   ├── __init__.py
│       │   └── v1/
│       │       ├── __init__.py
│       │       ├── service_pb2.py
│       │       ├── service_pb2.pyi       # Type stubs
│       │       ├── service_pb2_grpc.py
│       │       ├── models_pb2.py
│       │       └── models_pb2.pyi
│       └── services/
│           └── grpc_service.py
├── scripts/
│   └── generate_protos.py
└── pyproject.toml
```

### Proto Definitions

```protobuf
// protos/v1/service.proto
syntax = "proto3";

package myproject.v1;

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";
import "protos/v1/models.proto";

// ResourceService manages Azure resources
service ResourceService {
  // ListResources returns all resources in a resource group
  rpc ListResources(ListResourcesRequest) returns (ListResourcesResponse);

  // GetResource returns a specific resource by ID
  rpc GetResource(GetResourceRequest) returns (Resource);

  // CreateResource creates a new resource
  rpc CreateResource(CreateResourceRequest) returns (Resource);

  // StreamResourceUpdates streams resource update events
  rpc StreamResourceUpdates(StreamResourceUpdatesRequest) returns (stream ResourceUpdate);
}

message ListResourcesRequest {
  string resource_group = 1;
  string subscription_id = 2;
  int32 page_size = 3;
  string page_token = 4;
  map<string, string> tags = 5;
}

message ListResourcesResponse {
  repeated Resource resources = 1;
  string next_page_token = 2;
  int32 total_count = 3;
}

message GetResourceRequest {
  string resource_id = 1;
  string subscription_id = 2;
}

message CreateResourceRequest {
  string name = 1;
  string resource_group = 2;
  string location = 3;
  map<string, string> tags = 4;
}

message StreamResourceUpdatesRequest {
  string resource_group = 1;
  repeated string resource_types = 2;
}

message ResourceUpdate {
  enum UpdateType {
    UNKNOWN = 0;
    CREATED = 1;
    UPDATED = 2;
    DELETED = 3;
  }

  UpdateType type = 1;
  Resource resource = 2;
  google.protobuf.Timestamp timestamp = 3;
}
```

```protobuf
// protos/v1/models.proto
syntax = "proto3";

package myproject.v1;

import "google/protobuf/timestamp.proto";

message Resource {
  string id = 1;
  string name = 2;
  string type = 3;
  string location = 4;
  string resource_group = 5;
  map<string, string> tags = 6;
  google.protobuf.Timestamp created_at = 7;
  google.protobuf.Timestamp updated_at = 8;
}
```

### Code Generation Script

```python
"""Generate Python code from protobuf definitions."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def generate_protos() -> int:
    """Generate Python protobuf code with type stubs.

    Returns:
        Exit code (0 for success).
    """
    proto_dir = Path("protos")
    output_dir = Path("src/myproject/generated")

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "__init__.py").touch()
    (output_dir / "v1" / "__init__.py").touch()

    # Find all proto files
    proto_files = list(proto_dir.rglob("*.proto"))

    if not proto_files:
        print("No proto files found", file=sys.stderr)
        return 1

    # Generate Python code with type stubs
    cmd = [
        sys.executable,
        "-m",
        "grpc_tools.protoc",
        f"--proto_path={proto_dir}",
        f"--python_out={output_dir}",
        f"--grpc_python_out={output_dir}",
        f"--mypy_out={output_dir}",  # Generate type stubs
    ]

    for proto_file in proto_files:
        cmd.append(str(proto_file))

    print(f"Generating protobuf code from {len(proto_files)} files...")
    result = subprocess.run(cmd, check=False)

    if result.returncode == 0:
        print(f"Generated code in {output_dir}")
        return 0

    print("Failed to generate protobuf code", file=sys.stderr)
    return result.returncode


if __name__ == "__main__":
    sys.exit(generate_protos())
```

### gRPC Server Implementation

```python
"""gRPC server implementation with full type hints."""

from __future__ import annotations

import asyncio
import logging
from collections.abc import AsyncIterator
from typing import TYPE_CHECKING

import grpc
import structlog
from google.protobuf.timestamp_pb2 import Timestamp

from myproject.generated.v1 import service_pb2, service_pb2_grpc
from myproject.generated.v1.models_pb2 import Resource
from myproject.services.azure import AzureResourceManager

if TYPE_CHECKING:
    from myproject.core.config import Settings

logger = structlog.get_logger()


class ResourceServicer(service_pb2_grpc.ResourceServiceServicer):
    """Implementation of ResourceService gRPC service."""

    def __init__(self, settings: Settings) -> None:
        """Initialize resource servicer.

        Args:
            settings: Application settings.
        """
        self.settings = settings
        self._manager: AzureResourceManager | None = None

    async def _get_manager(self) -> AzureResourceManager:
        """Get or create Azure resource manager.

        Returns:
            Azure resource manager instance.
        """
        if self._manager is None:
            self._manager = AzureResourceManager(
                subscription_id=self.settings.azure_subscription_id,
                tenant_id=self.settings.azure_tenant_id,
            )
            await self._manager.__aenter__()
        return self._manager

    async def ListResources(
        self,
        request: service_pb2.ListResourcesRequest,
        context: grpc.aio.ServicerContext,
    ) -> service_pb2.ListResourcesResponse:
        """List all resources in a resource group.

        Args:
            request: List resources request.
            context: gRPC context.

        Returns:
            List of resources response.
        """
        try:
            manager = await self._get_manager()

            # Build tag filter
            tags = dict(request.tags) if request.tags else None

            # List resource groups from Azure
            groups = await manager.list_resource_groups(tags=tags)

            # Convert to protobuf messages
            resources = [
                Resource(
                    id=group.id,
                    name=group.name,
                    type=group.type,
                    location=group.location,
                    resource_group=group.name,
                    tags=group.tags or {},
                )
                for group in groups
            ]

            return service_pb2.ListResourcesResponse(
                resources=resources,
                total_count=len(resources),
            )

        except Exception as e:
            logger.exception("Failed to list resources", error=str(e))
            await context.abort(
                grpc.StatusCode.INTERNAL,
                f"Failed to list resources: {e}",
            )

    async def GetResource(
        self,
        request: service_pb2.GetResourceRequest,
        context: grpc.aio.ServicerContext,
    ) -> Resource:
        """Get a specific resource by ID.

        Args:
            request: Get resource request.
            context: gRPC context.

        Returns:
            Resource details.
        """
        try:
            manager = await self._get_manager()

            # Extract resource group name from ID
            parts = request.resource_id.split("/")
            if len(parts) < 5:
                await context.abort(
                    grpc.StatusCode.INVALID_ARGUMENT,
                    "Invalid resource ID format",
                )

            resource_group = parts[4]
            group = await manager.get_resource_group(resource_group)

            return Resource(
                id=group.id,
                name=group.name,
                type=group.type,
                location=group.location,
                resource_group=group.name,
                tags=group.tags or {},
            )

        except ValueError as e:
            await context.abort(grpc.StatusCode.NOT_FOUND, str(e))
        except Exception as e:
            logger.exception("Failed to get resource", error=str(e))
            await context.abort(
                grpc.StatusCode.INTERNAL,
                f"Failed to get resource: {e}",
            )

    async def CreateResource(
        self,
        request: service_pb2.CreateResourceRequest,
        context: grpc.aio.ServicerContext,
    ) -> Resource:
        """Create a new resource.

        Args:
            request: Create resource request.
            context: gRPC context.

        Returns:
            Created resource.
        """
        try:
            manager = await self._get_manager()

            group = await manager.create_resource_group(
                name=request.name,
                location=request.location,
                tags=dict(request.tags),
            )

            return Resource(
                id=group.id,
                name=group.name,
                type=group.type,
                location=group.location,
                resource_group=group.name,
                tags=group.tags or {},
            )

        except Exception as e:
            logger.exception("Failed to create resource", error=str(e))
            await context.abort(
                grpc.StatusCode.INTERNAL,
                f"Failed to create resource: {e}",
            )

    async def StreamResourceUpdates(
        self,
        request: service_pb2.StreamResourceUpdatesRequest,
        context: grpc.aio.ServicerContext,
    ) -> AsyncIterator[service_pb2.ResourceUpdate]:
        """Stream resource update events.

        Args:
            request: Stream request.
            context: gRPC context.

        Yields:
            Resource update events.
        """
        try:
            # In a real implementation, this would connect to Azure Event Grid
            # or similar service for real-time updates

            # Example: yield updates every 5 seconds
            while not context.cancelled():
                manager = await self._get_manager()
                groups = await manager.list_resource_groups()

                for group in groups:
                    timestamp = Timestamp()
                    timestamp.GetCurrentTime()

                    yield service_pb2.ResourceUpdate(
                        type=service_pb2.ResourceUpdate.UpdateType.UPDATED,
                        resource=Resource(
                            id=group.id,
                            name=group.name,
                            type=group.type,
                            location=group.location,
                            resource_group=group.name,
                            tags=group.tags or {},
                        ),
                        timestamp=timestamp,
                    )

                await asyncio.sleep(5)

        except Exception as e:
            logger.exception("Stream error", error=str(e))
            await context.abort(
                grpc.StatusCode.INTERNAL,
                f"Stream error: {e}",
            )


async def serve(settings: Settings) -> None:
    """Start gRPC server.

    Args:
        settings: Application settings.
    """
    server = grpc.aio.server()
    service_pb2_grpc.add_ResourceServiceServicer_to_server(
        ResourceServicer(settings),
        server,
    )

    listen_addr = f"{settings.api_host}:{settings.api_port}"
    server.add_insecure_port(listen_addr)

    logger.info("Starting gRPC server", address=listen_addr)
    await server.start()
    await server.wait_for_termination()
```

### gRPC Client

```python
"""gRPC client implementation with full type hints."""

from __future__ import annotations

from collections.abc import AsyncIterator
from typing import TYPE_CHECKING

import grpc
import structlog

from myproject.generated.v1 import service_pb2, service_pb2_grpc
from myproject.generated.v1.models_pb2 import Resource

if TYPE_CHECKING:
    from myproject.generated.v1.service_pb2 import (
        CreateResourceRequest,
        GetResourceRequest,
        ListResourcesRequest,
        ListResourcesResponse,
        ResourceUpdate,
        StreamResourceUpdatesRequest,
    )

logger = structlog.get_logger()


class ResourceClient:
    """Client for ResourceService gRPC service."""

    def __init__(self, address: str) -> None:
        """Initialize client.

        Args:
            address: Server address (e.g., 'localhost:50051').
        """
        self.address = address
        self._channel: grpc.aio.Channel | None = None
        self._stub: service_pb2_grpc.ResourceServiceStub | None = None

    async def __aenter__(self) -> ResourceClient:
        """Enter async context manager."""
        self._channel = grpc.aio.insecure_channel(self.address)
        self._stub = service_pb2_grpc.ResourceServiceStub(self._channel)
        logger.info("Connected to gRPC server", address=self.address)
        return self

    async def __aexit__(self, *args: object) -> None:
        """Exit async context manager."""
        if self._channel is not None:
            await self._channel.close()
        logger.info("Closed gRPC connection")

    async def list_resources(
        self,
        resource_group: str,
        subscription_id: str,
        *,
        tags: dict[str, str] | None = None,
    ) -> ListResourcesResponse:
        """List all resources.

        Args:
            resource_group: Resource group name.
            subscription_id: Azure subscription ID.
            tags: Filter by tags (optional).

        Returns:
            List of resources.

        Raises:
            ValueError: If client not initialized.
        """
        if self._stub is None:
            raise ValueError("Client not initialized. Use 'async with' context.")

        request = service_pb2.ListResourcesRequest(
            resource_group=resource_group,
            subscription_id=subscription_id,
            tags=tags or {},
        )

        return await self._stub.ListResources(request)

    async def get_resource(
        self,
        resource_id: str,
        subscription_id: str,
    ) -> Resource:
        """Get a specific resource.

        Args:
            resource_id: Resource ID.
            subscription_id: Azure subscription ID.

        Returns:
            Resource details.

        Raises:
            ValueError: If client not initialized.
        """
        if self._stub is None:
            raise ValueError("Client not initialized. Use 'async with' context.")

        request = service_pb2.GetResourceRequest(
            resource_id=resource_id,
            subscription_id=subscription_id,
        )

        return await self._stub.GetResource(request)

    async def create_resource(
        self,
        name: str,
        resource_group: str,
        location: str,
        *,
        tags: dict[str, str] | None = None,
    ) -> Resource:
        """Create a new resource.

        Args:
            name: Resource name.
            resource_group: Resource group name.
            location: Azure region.
            tags: Resource tags (optional).

        Returns:
            Created resource.

        Raises:
            ValueError: If client not initialized.
        """
        if self._stub is None:
            raise ValueError("Client not initialized. Use 'async with' context.")

        request = service_pb2.CreateResourceRequest(
            name=name,
            resource_group=resource_group,
            location=location,
            tags=tags or {},
        )

        return await self._stub.CreateResource(request)

    async def stream_updates(
        self,
        resource_group: str,
        resource_types: list[str] | None = None,
    ) -> AsyncIterator[ResourceUpdate]:
        """Stream resource updates.

        Args:
            resource_group: Resource group to monitor.
            resource_types: Filter by resource types (optional).

        Yields:
            Resource update events.

        Raises:
            ValueError: If client not initialized.
        """
        if self._stub is None:
            raise ValueError("Client not initialized. Use 'async with' context.")

        request = service_pb2.StreamResourceUpdatesRequest(
            resource_group=resource_group,
            resource_types=resource_types or [],
        )

        async for update in self._stub.StreamResourceUpdates(request):
            yield update


# Example usage
async def main() -> None:
    """Example client usage."""
    async with ResourceClient("localhost:50051") as client:
        # List resources
        response = await client.list_resources(
            resource_group="my-rg",
            subscription_id="sub-123",
        )

        for resource in response.resources:
            print(f"Resource: {resource.name} ({resource.location})")

        # Stream updates
        async for update in client.stream_updates("my-rg"):
            print(f"Update: {update.type} - {update.resource.name}")
```

### Makefile Integration

Add to your Makefile:

```makefile
# Protobuf targets
.PHONY: proto proto-clean

proto:
	@echo "Generating protobuf code..."
	$(UV) run python scripts/generate_protos.py

proto-clean:
	rm -rf src/myproject/generated/
	mkdir -p src/myproject/generated/
	touch src/myproject/generated/__init__.py
```

## Model Context Protocol (MCP) Server

### Overview

MCP (Model Context Protocol) servers provide AI assistants with tools and resources. A Python MCP server exposes functions that can be called by AI clients.

### Installation

```bash
# Using uv
uv add mcp pydantic

# Using poetry
poetry add mcp pydantic

# Using pip
pip install mcp pydantic
```

### MCP Server Structure

```
.
├── src/
│   └── myproject/
│       ├── mcp/
│       │   ├── __init__.py
│       │   ├── server.py          # MCP server implementation
│       │   ├── tools.py           # Tool definitions
│       │   └── resources.py       # Resource definitions
│       └── services/
│           └── azure.py
├── pyproject.toml
└── README.md
```

### MCP Server Implementation

```python
"""MCP server for Azure resource management."""

from __future__ import annotations

import asyncio
from collections.abc import Sequence
from typing import Any

import structlog
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    Resource,
    TextContent,
    Tool,
    ToolCallMessage,
)
from pydantic import AnyUrl, BaseModel, Field

from myproject.core.config import Settings, load_settings
from myproject.services.azure import AzureResourceManager

logger = structlog.get_logger()


class ListResourceGroupsArgs(BaseModel):
    """Arguments for list_resource_groups tool."""

    subscription_id: str = Field(..., description="Azure subscription ID")
    tag_key: str | None = Field(None, description="Filter by tag key")
    tag_value: str | None = Field(None, description="Filter by tag value")


class GetResourceGroupArgs(BaseModel):
    """Arguments for get_resource_group tool."""

    subscription_id: str = Field(..., description="Azure subscription ID")
    name: str = Field(..., description="Resource group name")


class CreateResourceGroupArgs(BaseModel):
    """Arguments for create_resource_group tool."""

    subscription_id: str = Field(..., description="Azure subscription ID")
    name: str = Field(..., description="Resource group name")
    location: str = Field(..., description="Azure region (e.g., eastus)")
    tags: dict[str, str] = Field(default_factory=dict, description="Resource tags")


class AzureMCPServer:
    """MCP server for Azure resource management."""

    def __init__(self, settings: Settings) -> None:
        """Initialize MCP server.

        Args:
            settings: Application settings.
        """
        self.settings = settings
        self.server = Server("azure-mcp-server")
        self._manager: AzureResourceManager | None = None

        # Register handlers
        self._register_handlers()

    def _register_handlers(self) -> None:
        """Register MCP request handlers."""

        @self.server.list_tools()
        async def list_tools() -> list[Tool]:
            """List available tools.

            Returns:
                List of available tools.
            """
            return [
                Tool(
                    name="list_resource_groups",
                    description="List all resource groups in an Azure subscription",
                    inputSchema=ListResourceGroupsArgs.model_json_schema(),
                ),
                Tool(
                    name="get_resource_group",
                    description="Get details of a specific resource group",
                    inputSchema=GetResourceGroupArgs.model_json_schema(),
                ),
                Tool(
                    name="create_resource_group",
                    description="Create a new Azure resource group",
                    inputSchema=CreateResourceGroupArgs.model_json_schema(),
                ),
            ]

        @self.server.call_tool()
        async def call_tool(
            name: str,
            arguments: dict[str, Any],
        ) -> Sequence[TextContent]:
            """Execute a tool.

            Args:
                name: Tool name.
                arguments: Tool arguments.

            Returns:
                Tool execution result.

            Raises:
                ValueError: If tool not found.
            """
            if name == "list_resource_groups":
                return await self._list_resource_groups(
                    ListResourceGroupsArgs(**arguments)
                )
            elif name == "get_resource_group":
                return await self._get_resource_group(
                    GetResourceGroupArgs(**arguments)
                )
            elif name == "create_resource_group":
                return await self._create_resource_group(
                    CreateResourceGroupArgs(**arguments)
                )
            else:
                raise ValueError(f"Unknown tool: {name}")

        @self.server.list_resources()
        async def list_resources() -> list[Resource]:
            """List available resources.

            Returns:
                List of available resources.
            """
            return [
                Resource(
                    uri=AnyUrl("azure://subscriptions"),
                    name="Azure Subscriptions",
                    description="List of Azure subscriptions",
                    mimeType="application/json",
                ),
            ]

        @self.server.read_resource()
        async def read_resource(uri: AnyUrl) -> str:
            """Read a resource.

            Args:
                uri: Resource URI.

            Returns:
                Resource content.

            Raises:
                ValueError: If resource not found.
            """
            if str(uri) == "azure://subscriptions":
                return f"Subscription: {self.settings.azure_subscription_id}"
            raise ValueError(f"Unknown resource: {uri}")

    async def _get_manager(self) -> AzureResourceManager:
        """Get or create Azure resource manager.

        Returns:
            Azure resource manager instance.
        """
        if self._manager is None:
            self._manager = AzureResourceManager(
                subscription_id=self.settings.azure_subscription_id,
                tenant_id=self.settings.azure_tenant_id,
            )
            await self._manager.__aenter__()
        return self._manager

    async def _list_resource_groups(
        self,
        args: ListResourceGroupsArgs,
    ) -> Sequence[TextContent]:
        """List resource groups tool implementation.

        Args:
            args: Tool arguments.

        Returns:
            List of resource groups as text content.
        """
        try:
            manager = await self._get_manager()

            tags = None
            if args.tag_key and args.tag_value:
                tags = {args.tag_key: args.tag_value}

            groups = await manager.list_resource_groups(tags=tags)

            result = {
                "total_count": len(groups),
                "resource_groups": [
                    {
                        "name": group.name,
                        "location": group.location,
                        "tags": group.tags or {},
                    }
                    for group in groups
                ],
            }

            import json
            return [TextContent(type="text", text=json.dumps(result, indent=2))]

        except Exception as e:
            logger.exception("Failed to list resource groups", error=str(e))
            return [TextContent(type="text", text=f"Error: {e}")]

    async def _get_resource_group(
        self,
        args: GetResourceGroupArgs,
    ) -> Sequence[TextContent]:
        """Get resource group tool implementation.

        Args:
            args: Tool arguments.

        Returns:
            Resource group details as text content.
        """
        try:
            manager = await self._get_manager()
            group = await manager.get_resource_group(args.name)

            result = {
                "name": group.name,
                "location": group.location,
                "tags": group.tags or {},
                "id": group.id,
                "type": group.type,
            }

            import json
            return [TextContent(type="text", text=json.dumps(result, indent=2))]

        except Exception as e:
            logger.exception("Failed to get resource group", error=str(e))
            return [TextContent(type="text", text=f"Error: {e}")]

    async def _create_resource_group(
        self,
        args: CreateResourceGroupArgs,
    ) -> Sequence[TextContent]:
        """Create resource group tool implementation.

        Args:
            args: Tool arguments.

        Returns:
            Created resource group details as text content.
        """
        try:
            manager = await self._get_manager()
            group = await manager.create_resource_group(
                name=args.name,
                location=args.location,
                tags=args.tags,
            )

            result = {
                "name": group.name,
                "location": group.location,
                "tags": group.tags or {},
                "id": group.id,
                "type": group.type,
                "status": "created",
            }

            import json
            return [TextContent(type="text", text=json.dumps(result, indent=2))]

        except Exception as e:
            logger.exception("Failed to create resource group", error=str(e))
            return [TextContent(type="text", text=f"Error: {e}")]

    async def run(self) -> None:
        """Run the MCP server."""
        async with stdio_server() as (read_stream, write_stream):
            await self.server.run(
                read_stream,
                write_stream,
                self.server.create_initialization_options(),
            )


async def main() -> None:
    """Main entry point for MCP server."""
    settings = load_settings()
    server = AzureMCPServer(settings)
    await server.run()


if __name__ == "__main__":
    asyncio.run(main())
```

### MCP Server Configuration

```json
// .mcp/config.json
{
  "mcpServers": {
    "azure-resources": {
      "command": "uv",
      "args": ["run", "python", "-m", "myproject.mcp.server"],
      "env": {
        "AZURE_SUBSCRIPTION_ID": "your-subscription-id",
        "AZURE_TENANT_ID": "your-tenant-id"
      }
    }
  }
}
```

### Advanced MCP Patterns

```python
"""Advanced MCP patterns with type hints."""

from __future__ import annotations

from collections.abc import Sequence
from typing import Annotated, Any, Literal

from mcp.server import Server
from mcp.types import (
    ImageContent,
    Prompt,
    PromptArgument,
    PromptMessage,
    Resource,
    TextContent,
    Tool,
)
from pydantic import AnyUrl, BaseModel, Field


class AdvancedMCPServer:
    """Advanced MCP server with prompts and resources."""

    def __init__(self) -> None:
        """Initialize advanced MCP server."""
        self.server = Server("advanced-mcp-server")
        self._register_handlers()

    def _register_handlers(self) -> None:
        """Register all MCP handlers."""

        # Tools
        @self.server.list_tools()
        async def list_tools() -> list[Tool]:
            """List available tools."""
            return [
                Tool(
                    name="analyze_logs",
                    description="Analyze Azure resource logs",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "resource_id": {
                                "type": "string",
                                "description": "Azure resource ID",
                            },
                            "time_range": {
                                "type": "string",
                                "enum": ["1h", "24h", "7d"],
                                "description": "Time range for analysis",
                            },
                        },
                        "required": ["resource_id"],
                    },
                ),
            ]

        # Prompts
        @self.server.list_prompts()
        async def list_prompts() -> list[Prompt]:
            """List available prompts."""
            return [
                Prompt(
                    name="troubleshoot_resource",
                    description="Troubleshoot Azure resource issues",
                    arguments=[
                        PromptArgument(
                            name="resource_type",
                            description="Type of Azure resource",
                            required=True,
                        ),
                        PromptArgument(
                            name="error_message",
                            description="Error message to troubleshoot",
                            required=True,
                        ),
                    ],
                ),
            ]

        @self.server.get_prompt()
        async def get_prompt(
            name: str,
            arguments: dict[str, str] | None = None,
        ) -> Sequence[PromptMessage]:
            """Get a prompt template.

            Args:
                name: Prompt name.
                arguments: Prompt arguments.

            Returns:
                Prompt messages.
            """
            if name == "troubleshoot_resource":
                resource_type = arguments.get("resource_type", "unknown")
                error_message = arguments.get("error_message", "unknown error")

                return [
                    PromptMessage(
                        role="user",
                        content=TextContent(
                            type="text",
                            text=f"""You are an Azure expert troubleshooting a {resource_type}.

Error message: {error_message}

Please provide:
1. Likely causes of this error
2. Steps to diagnose the issue
3. Recommended solutions
4. Prevention strategies""",
                        ),
                    ),
                ]

            return []

        # Resources
        @self.server.list_resources()
        async def list_resources() -> list[Resource]:
            """List available resources."""
            return [
                Resource(
                    uri=AnyUrl("azure://docs/best-practices"),
                    name="Azure Best Practices",
                    description="Best practices for Azure resources",
                    mimeType="text/markdown",
                ),
                Resource(
                    uri=AnyUrl("azure://schemas/resource-group"),
                    name="Resource Group Schema",
                    description="JSON schema for resource groups",
                    mimeType="application/json",
                ),
            ]

        @self.server.read_resource()
        async def read_resource(uri: AnyUrl) -> str:
            """Read resource content.

            Args:
                uri: Resource URI.

            Returns:
                Resource content.
            """
            uri_str = str(uri)

            if uri_str == "azure://docs/best-practices":
                return """# Azure Best Practices

## Resource Groups
- Use consistent naming conventions
- Tag all resources appropriately
- Group related resources together

## Security
- Enable Azure AD authentication
- Use managed identities
- Apply least privilege access
"""

            elif uri_str == "azure://schemas/resource-group":
                import json
                schema = {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "location": {"type": "string"},
                        "tags": {"type": "object"},
                    },
                    "required": ["name", "location"],
                }
                return json.dumps(schema, indent=2)

            raise ValueError(f"Unknown resource: {uri}")
```

### MCP Client Example

```python
"""MCP client for testing MCP servers."""

from __future__ import annotations

import asyncio

from mcp.client import Client
from mcp.client.stdio import stdio_client


async def main() -> None:
    """Example MCP client usage."""
    async with stdio_client(
        command="uv",
        args=["run", "python", "-m", "myproject.mcp.server"],
    ) as (read, write):
        async with Client(read, write) as client:
            # Initialize
            await client.initialize()

            # List available tools
            tools = await client.list_tools()
            print(f"Available tools: {[t.name for t in tools]}")

            # Call a tool
            result = await client.call_tool(
                "list_resource_groups",
                arguments={
                    "subscription_id": "your-sub-id",
                },
            )
            print(f"Result: {result}")

            # List resources
            resources = await client.list_resources()
            print(f"Available resources: {[r.name for r in resources]}")


if __name__ == "__main__":
    asyncio.run(main())
```

### pyproject.toml Configuration for MCP

```toml
[project.scripts]
azure-mcp = "myproject.mcp.server:main"

[tool.uv]
dev-dependencies = [
    "mcp>=0.1.0",
]
```

### Testing MCP Server

```python
"""Tests for MCP server."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from mcp.types import TextContent

from myproject.core.config import Settings
from myproject.mcp.server import AzureMCPServer, ListResourceGroupsArgs


@pytest.fixture
def settings() -> Settings:
    """Create test settings."""
    return Settings(
        azure_subscription_id="test-sub",
        azure_tenant_id="test-tenant",
    )


@pytest.fixture
def mock_manager() -> AsyncMock:
    """Create mock Azure resource manager."""
    manager = AsyncMock()
    manager.__aenter__ = AsyncMock(return_value=manager)
    manager.__aexit__ = AsyncMock()
    return manager


class TestAzureMCPServer:
    """Test suite for Azure MCP server."""

    async def test_list_resource_groups(
        self,
        settings: Settings,
        mock_manager: AsyncMock,
    ) -> None:
        """Test list resource groups tool."""
        # Setup mock
        mock_groups = [
            MagicMock(
                name="rg1",
                location="eastus",
                tags={"env": "test"},
            ),
        ]
        mock_manager.list_resource_groups.return_value = mock_groups

        # Create server
        server = AzureMCPServer(settings)
        server._manager = mock_manager

        # Call tool
        args = ListResourceGroupsArgs(subscription_id="test-sub")
        result = await server._list_resource_groups(args)

        # Verify
        assert len(result) == 1
        assert isinstance(result[0], TextContent)
        assert "rg1" in result[0].text
        assert "eastus" in result[0].text


if __name__ == "__main__":
    pytest.main([__file__])
```

## Editor Setup

For LazyVim (preferred) or VSCode configuration, see [EDITORS.md](./EDITORS.md).

## Resources

- [Python Type Hints Documentation](https://docs.python.org/3/library/typing.html)
- [mypy Documentation](https://mypy.readthedocs.io/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [uv Documentation](https://docs.astral.sh/uv/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [pytest Documentation](https://docs.pytest.org/)
- [Azure SDK for Python](https://github.com/Azure/azure-sdk-for-python)
- [Protocol Buffers Python Documentation](https://protobuf.dev/reference/python/)
- [gRPC Python Documentation](https://grpc.io/docs/languages/python/)
- [Model Context Protocol (MCP) Documentation](https://modelcontextprotocol.io/)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)

## Version History

- 1.0.0 - Initial version with comprehensive Python development guidelines
