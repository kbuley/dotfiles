# YAML Standards and Best Practices

# APPLIES-TO: yaml

Standards for writing YAML configuration files.

## Table of Contents

- [Core Principles](#core-principles)
- [Formatting](#formatting)
- [Structure](#structure)
- [Common Patterns](#common-patterns)
- [Security](#security)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

## Core Principles

1. **Readability First**: YAML should be easy for humans to read
2. **Consistent Indentation**: Always use 2 spaces
3. **Explicit Types**: Be clear about data types
4. **Comments**: Document non-obvious configuration
5. **Version Control Friendly**: Structure for easy diffs

## Formatting

### Indentation

**Always use 2 spaces** (never tabs):

```yaml
# ✅ Good
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"

# ❌ Bad - inconsistent indentation
services:
    web:
      image: nginx:latest
        ports:
        - "80:80"
```

### Line Length

Keep lines under 120 characters:

```yaml
# ✅ Good
description: >
  This is a long description that wraps
  across multiple lines for readability

# ❌ Bad - too long
description: "This is a really long description that goes on and on and makes it hard to read in editors with reasonable line widths"
```

### Quotes

Use quotes consistently:

```yaml
# ✅ Good - quotes when needed
name: "my-service"
version: "1.0.0"
description: "Service with special chars: $VAR"
simple: value

# ❌ Bad - inconsistent
name: my-service
version: '1.0.0'
description: Service with special chars: $VAR  # Will expand variable!
```

**When to quote:**

- Strings with special characters: `$`, `{`, `}`, `[`, `]`, `:`, `#`
- Version numbers: `"1.0"` (not `1.0` which becomes float)
- Values that look like booleans: `"yes"`, `"no"`, `"true"`, `"false"`
- Empty strings: `""`

### Booleans

Use lowercase `true`/`false`:

```yaml
# ✅ Good
enabled: true
debug: false

# ❌ Bad
enabled: True
debug: FALSE
enabled: yes  # Ambiguous
```

### Null Values

Use explicit `null` or `~`:

```yaml
# ✅ Good
optional: null
another: ~

# ❌ Bad
optional:  # Ambiguous - is it null or missing?
```

### Lists

Use consistent list style:

```yaml
# ✅ Good - block style for readability
dependencies:
  - package-a
  - package-b
  - package-c

# ✅ Good - inline for short lists
ports: [80, 443, 8080]

# ❌ Bad - mixed styles
dependencies:
  - package-a
  - package-b
ports:
  - 80
  - 443
```

### Maps/Dictionaries

```yaml
# ✅ Good - explicit structure
config:
  database:
    host: localhost
    port: 5432
  cache:
    enabled: true

# ❌ Bad - flow style for large objects
config: {database: {host: localhost, port: 5432}, cache: {enabled: true}}
```

## Structure

### File Organization

```yaml
# 1. Metadata/version
apiVersion: v1
kind: Service

# 2. Required fields
metadata:
  name: my-service
  namespace: production

# 3. Main configuration
spec:
  replicas: 3
  selector:
    app: my-service

  # 4. Optional configuration
  template:
    metadata:
      labels:
        app: my-service
```

### Anchors and Aliases

Use for repeated configuration:

```yaml
# ✅ Good - DRY with anchors
defaults: &defaults
  timeout: 30
  retries: 3

development:
  <<: *defaults
  debug: true

production:
  <<: *defaults
  debug: false
  timeout: 60  # Override

# ❌ Bad - repetition
development:
  timeout: 30
  retries: 3
  debug: true

production:
  timeout: 60
  retries: 3
  debug: false
```

### Multi-line Strings

Choose the right style:

```yaml
# Literal block (|) - preserves newlines
script: |
  #!/bin/bash
  echo "Line 1"
  echo "Line 2"

# Folded block (>) - joins lines
description: >
  This is a long description
  that will be folded into
  a single line.

# Quoted - explicit
command: "echo 'Hello World'"
```

## Common Patterns

### Environment Variables

```yaml
# ✅ Good - explicit and documented
environment:
  # Database connection
  DATABASE_URL: "postgresql://localhost:5432/mydb"
  DATABASE_POOL_SIZE: 10

  # Feature flags
  ENABLE_CACHING: true
  DEBUG_MODE: false

# ❌ Bad - unclear purpose
env:
  DB: postgres
  PS: 10
  C: true
```

### Configuration Files

**Docker Compose**:

```yaml
version: "3.8"

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    environment:
      - NGINX_HOST=example.com
    volumes:
      - ./html:/usr/share/nginx/html:ro
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: "${DB_PASSWORD}" # From .env
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

**GitHub Actions**:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: "1.21"

      - name: Run tests
        run: go test -v ./...
```

**Azure Pipelines**:

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    exclude:
      - docs/*
      - README.md

pr:
  branches:
    include:
      - main
  paths:
    exclude:
      - docs/*

variables:
  buildConfiguration: "Release"
  vmImage: "ubuntu-latest"

stages:
  - stage: Build
    displayName: "Build and Test"
    jobs:
      - job: Build
        displayName: "Build Job"
        pool:
          vmImage: $(vmImage)

        steps:
          - task: UseDotNet@2
            displayName: "Install .NET SDK"
            inputs:
              version: "8.x"

          - task: DotNetCoreCLI@2
            displayName: "Restore dependencies"
            inputs:
              command: "restore"
              projects: "**/*.csproj"

          - task: DotNetCoreCLI@2
            displayName: "Build"
            inputs:
              command: "build"
              arguments: "--configuration $(buildConfiguration)"

          - task: DotNetCoreCLI@2
            displayName: "Run tests"
            inputs:
              command: "test"
              arguments: '--configuration $(buildConfiguration) --collect:"XPlat Code Coverage"'

          - task: PublishCodeCoverageResults@1
            displayName: "Publish coverage"
            inputs:
              codeCoverageTool: "Cobertura"
              summaryFileLocation: "$(Agent.TempDirectory)/**/*coverage.cobertura.xml"

  - stage: Deploy
    displayName: "Deploy to Azure"
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))

    jobs:
      - deployment: DeployWeb
        displayName: "Deploy Web App"
        environment: "production"
        pool:
          vmImage: $(vmImage)

        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureWebApp@1
                  displayName: "Deploy to App Service"
                  inputs:
                    azureSubscription: "Azure-Subscription"
                    appType: "webAppLinux"
                    appName: "my-web-app"
                    package: "$(Pipeline.Workspace)/**/*.zip"
```

**Azure Pipelines - Multi-stage with Templates**:

```yaml
# azure-pipelines.yml (main)
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - template: templates/build-stage.yml
    parameters:
      buildConfiguration: 'Release'

  - template: templates/deploy-stage.yml
    parameters:
      environment: 'production'
      dependsOn: 'Build'

# templates/build-stage.yml
parameters:
  - name: buildConfiguration
    type: string
    default: 'Release'

stages:
  - stage: Build
    displayName: 'Build'
    jobs:
      - job: BuildJob
        steps:
          - task: DotNetCoreCLI@2
            inputs:
              command: 'build'
              arguments: '--configuration ${{ parameters.buildConfiguration }}'

# templates/deploy-stage.yml
parameters:
  - name: environment
    type: string
  - name: dependsOn
    type: string

stages:
  - stage: Deploy
    displayName: 'Deploy to ${{ parameters.environment }}'
    dependsOn: ${{ parameters.dependsOn }}
    jobs:
      - deployment: DeployJob
        environment: ${{ parameters.environment }}
        strategy:
          runOnce:
            deploy:
              steps:
                - bash: echo "Deploying to ${{ parameters.environment }}"
```

**Azure Pipelines - Docker Build and Push**:

```yaml
trigger:
  - main

variables:
  dockerRegistryServiceConnection: "ACR-Connection"
  imageRepository: "myapp"
  containerRegistry: "myregistry.azurecr.io"
  dockerfilePath: "$(Build.SourcesDirectory)/Dockerfile"
  tag: "$(Build.BuildId)"
  vmImage: "ubuntu-latest"

stages:
  - stage: Build
    displayName: "Build and Push Docker Image"
    jobs:
      - job: Docker
        displayName: "Docker Build"
        pool:
          vmImage: $(vmImage)

        steps:
          - task: Docker@2
            displayName: "Build image"
            inputs:
              command: "build"
              repository: $(imageRepository)
              dockerfile: $(dockerfilePath)
              containerRegistry: $(dockerRegistryServiceConnection)
              tags: |
                $(tag)
                latest

          - task: Docker@2
            displayName: "Push image"
            inputs:
              command: "push"
              repository: $(imageRepository)
              containerRegistry: $(dockerRegistryServiceConnection)
              tags: |
                $(tag)
                latest

          - task: Docker@2
            displayName: "Scan image"
            inputs:
              command: "scan"
              arguments: "$(containerRegistry)/$(imageRepository):$(tag)"
```

**Azure Pipelines - Matrix Strategy**:

```yaml
trigger:
  - main

strategy:
  matrix:
    Python39_Linux:
      python.version: "3.9"
      vmImage: "ubuntu-latest"
    Python310_Linux:
      python.version: "3.10"
      vmImage: "ubuntu-latest"
    Python311_Linux:
      python.version: "3.11"
      vmImage: "ubuntu-latest"
    Python39_Windows:
      python.version: "3.9"
      vmImage: "windows-latest"
    Python39_macOS:
      python.version: "3.9"
      vmImage: "macOS-latest"

pool:
  vmImage: $(vmImage)

steps:
  - task: UsePythonVersion@0
    displayName: "Use Python $(python.version)"
    inputs:
      versionSpec: "$(python.version)"

  - script: |
      python -m pip install --upgrade pip
      pip install -r requirements.txt
    displayName: "Install dependencies"

  - script: |
      pip install pytest pytest-cov
      pytest tests/ --cov=src --cov-report=xml --cov-report=html
    displayName: "Run tests"

  - task: PublishTestResults@2
    condition: succeededOrFailed()
    inputs:
      testResultsFiles: "**/test-*.xml"
      testRunTitle: "Python $(python.version) on $(vmImage)"

  - task: PublishCodeCoverageResults@1
    inputs:
      codeCoverageTool: "Cobertura"
      summaryFileLocation: "$(System.DefaultWorkingDirectory)/**/coverage.xml"
```

**Azure Pipelines - PowerShell with Azure Resources**:

```yaml
trigger:
  - main

pool:
  vmImage: "windows-latest"

variables:
  azureSubscription: "Azure-Subscription"
  resourceGroup: "my-rg"
  location: "eastus"

steps:
  - task: AzurePowerShell@5
    displayName: "Validate Azure Resources"
    inputs:
      azureSubscription: $(azureSubscription)
      scriptType: "inlineScript"
      inline: |
        # Follows AGENTS_POWERSHELL.md patterns

        # Multi-subscription by default
        $query = @"
        Resources
        | where resourceGroup =~ '$(resourceGroup)'
        | project name, type, location
        "@

        $resources = Search-AzGraph -Query $query -First 1000

        Write-Host "Found $($resources.Count) resources"

        # Validate naming conventions
        foreach ($resource in $resources) {
            if ($resource.name -notmatch '^[a-z0-9-]+$') {
                Write-Warning "Resource $($resource.name) doesn't follow naming convention"
            }
        }
      azurePowerShellVersion: "latestVersion"

  - task: AzurePowerShell@5
    displayName: "Deploy Resources"
    inputs:
      azureSubscription: $(azureSubscription)
      scriptType: "filePath"
      scriptPath: "$(System.DefaultWorkingDirectory)/scripts/deploy.ps1"
      scriptArguments: "-ResourceGroup $(resourceGroup) -Location $(location)"
      azurePowerShellVersion: "latestVersion"
```

````

**Kubernetes**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
    version: "1.0"

spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app

  template:
    metadata:
      labels:
        app: my-app

    spec:
      containers:
        - name: app
          image: my-app:1.0
          ports:
            - containerPort: 8080

          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: url

          resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
            limits:
              memory: "128Mi"
              cpu: "500m"
````

## Security

### Sensitive Data

**Never commit secrets**:

```yaml
# ❌ Bad - secrets in config
database:
  password: "super-secret-password"
  api_key: "sk-1234567890"

# ✅ Good - reference secrets
database:
  password: "${DB_PASSWORD}"  # From environment
  api_key_file: "/run/secrets/api_key"  # From secret mount
```

### Validation

Use schema validation:

```yaml
# Define schema at top
# yaml-language-server: $schema=https://json.schemastore.org/docker-compose.json

version: "3.8"
services:
  web:
    image: nginx:latest
```

## AI Assistant Guidelines

### When Generating YAML

1. **Start with version/type**: API version, schema version
2. **Use 2-space indentation**: Consistently
3. **Add comments**: Explain non-obvious config
4. **Quote appropriately**: Versions, special chars
5. **Use anchors for repetition**: DRY principle
6. **Structure logically**: Group related config
7. **Include validation**: Schema references when possible

### Example AI Prompt

```
Create a docker-compose.yml following .ai/context/AGENTS_YAML.md:

Requirements:
- Web service (nginx)
- Database (postgres)
- Redis cache
- Proper volume mounts
- Environment variables from .env
- Health checks
- Restart policies
```

**Azure Pipelines Example Prompt**:

```
Create an Azure Pipeline following .ai/context/AGENTS_YAML.md:

Requirements:
- .NET 8 application
- Multi-stage (Build, Test, Deploy)
- Deploy to Azure App Service
- Run on ubuntu-latest
- Use templates for reusability
- Deploy only on main branch
- Include code coverage
- Use Azure Resource Graph in PowerShell tasks (per AGENTS_POWERSHELL.md)
```

### When Reviewing YAML

Check for:

- [ ] Consistent 2-space indentation
- [ ] Quoted version numbers and special chars
- [ ] No hardcoded secrets
- [ ] Comments for non-obvious config
- [ ] Logical grouping
- [ ] Proper anchors for repeated config
- [ ] Schema validation if applicable

### Common Tools

- **yamllint**: Linting tool

  ```bash
  yamllint config.yml
  ```

- **yq**: YAML processor

  ```bash
  yq eval '.services.web.image' docker-compose.yml
  ```

- **Schema validation**: Many editors support this

  ```yaml
  # yaml-language-server: $schema=<URL>
  ```

- **Azure Pipelines Validation**:

  ```bash
  # Validate pipeline syntax
  az pipelines build validate --yaml-path azure-pipelines.yml

  # Run pipeline locally (preview)
  az pipelines run --name "My Pipeline" --branch main
  ```

- **GitHub Actions Validation**:
  ```bash
  # Using act (local runner)
  act -l  # List workflows
  act push  # Run push event locally
  ```

## Examples by Use Case

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    tags:
      - "v*"

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Build image
        run: docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }} .

      - name: Push image
        run: docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }}
```

### Azure Pipelines Best Practices

**Use Templates for Reusability**:

```yaml
# Main pipeline
trigger:
  - main

stages:
  - template: templates/ci.yml
  - template: templates/cd.yml
```

**Variable Groups for Secrets**:

```yaml
variables:
  - group: "production-secrets" # From Azure DevOps Library
  - name: "buildConfiguration"
    value: "Release"
```

**Conditions and Dependencies**:

```yaml
stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - script: echo "Building"

  - stage: Deploy
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: DeployJob
        steps:
          - script: echo "Deploying"
```

**Service Connections**:

```yaml
steps:
  - task: AzureCLI@2
    inputs:
      azureSubscription: "Azure-Subscription" # Service connection name
      scriptType: "bash"
      scriptLocation: "inlineScript"
      inlineScript: |
        az group list --output table
```

**Artifacts and Caching**:

```yaml
steps:
  # Cache dependencies
  - task: Cache@2
    inputs:
      key: 'npm | "$(Agent.OS)" | package-lock.json'
      path: "$(Pipeline.Workspace)/.npm"
      restoreKeys: |
        npm | "$(Agent.OS)"

  # Publish artifacts
  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: "$(Build.ArtifactStagingDirectory)"
      artifactName: "drop"

  # Download artifacts in later stage
  - task: DownloadBuildArtifacts@1
    inputs:
      artifactName: "drop"
```

### Application Config

```yaml
# config.yml
app:
  name: "my-application"
  version: "1.0.0"

  server:
    host: "0.0.0.0"
    port: 8080
    timeout: 30

  database:
    host: "${DB_HOST:-localhost}"
    port: 5432
    name: "myapp"
    pool_size: 10

  logging:
    level: "info"
    format: "json"
    output: "stdout"

  features:
    caching: true
    rate_limiting: true
    debug: false
```

## Version History

- 2024-01-24: Initial version
