# AGENTS.md - TypeScript/Vue/Nuxt

# APPLIES-TO: vue, javascript, typescript

This document provides guidance for AI assistants working with TypeScript, Vue 3, and Nuxt 3 code in this repository.

## Project Context

This repository contains TypeScript applications using Vue 3 and Nuxt 3 for building modern web applications, dashboards, and user interfaces. Code should follow TypeScript best practices, be fully typed, maintainable, and production-ready.

## Core Principles

### 1. TypeScript First (Mandatory)

- **ALL code must use TypeScript** - No `.js` files in src/
- Use strict mode (`"strict": true` in tsconfig.json)
- Prefer explicit types over inference when it improves clarity
- Use type guards and discriminated unions
- Avoid `any` - use `unknown` when type is truly unknown

### 2. Vue 3 Composition API

- **Always use Composition API** with `<script setup>` syntax
- Use composables for reusable logic
- Prefer `ref` and `reactive` appropriately
- Use `computed` for derived state
- Implement proper cleanup in composables

### 3. Modern Development

- Use Vite for fast development and builds
- Leverage TypeScript 5.x features
- Use ESM (ES Modules) throughout
- Implement proper code splitting
- Use modern CSS (CSS variables, container queries)

### 4. Code Quality

- Use ESLint with TypeScript rules
- Use Prettier for consistent formatting
- Write tests with Vitest
- Use TypeScript for test files
- Aim for >80% code coverage

## Project Structure

### Vue 3 Application Structure

```
.
├── src/
│   ├── assets/
│   │   ├── styles/
│   │   │   ├── main.css
│   │   │   └── variables.css
│   │   └── images/
│   ├── components/
│   │   ├── base/              # Reusable base components
│   │   │   ├── BaseButton.vue
│   │   │   └── BaseInput.vue
│   │   ├── features/          # Feature-specific components
│   │   │   └── UserProfile.vue
│   │   └── layout/            # Layout components
│   │       ├── AppHeader.vue
│   │       └── AppSidebar.vue
│   ├── composables/           # Reusable composition functions
│   │   ├── useAuth.ts
│   │   ├── useApi.ts
│   │   └── useAzure.ts
│   ├── stores/                # Pinia stores
│   │   ├── auth.ts
│   │   └── resources.ts
│   ├── types/                 # TypeScript type definitions
│   │   ├── api.ts
│   │   ├── models.ts
│   │   └── index.ts
│   ├── utils/                 # Utility functions
│   │   ├── formatters.ts
│   │   └── validators.ts
│   ├── views/                 # Page components
│   │   ├── Home.vue
│   │   └── Dashboard.vue
│   ├── router/
│   │   └── index.ts
│   ├── App.vue
│   └── main.ts
├── tests/
│   ├── unit/
│   │   └── components/
│   └── e2e/
│       └── specs/
├── public/
├── index.html
├── vite.config.ts
├── tsconfig.json
├── tsconfig.node.json
├── package.json
└── README.md
```

### Nuxt 3 Application Structure

```
.
├── assets/
│   ├── styles/
│   │   └── main.css
│   └── images/
├── components/
│   ├── base/
│   │   ├── BaseButton.vue
│   │   └── BaseInput.vue
│   ├── features/
│   │   └── UserProfile.vue
│   └── layout/
│       └── AppHeader.vue
├── composables/               # Auto-imported composables
│   ├── useAuth.ts
│   └── useAzure.ts
├── layouts/
│   ├── default.vue
│   └── admin.vue
├── middleware/
│   └── auth.ts
├── pages/                     # File-based routing
│   ├── index.vue
│   ├── dashboard.vue
│   └── resources/
│       ├── index.vue
│       └── [id].vue
├── plugins/
│   └── api.ts
├── public/
├── server/                    # Server-side code
│   ├── api/
│   │   └── resources.ts
│   ├── middleware/
│   └── utils/
├── stores/                    # Pinia stores
│   └── auth.ts
├── types/
│   ├── api.ts
│   └── models.ts
├── utils/                     # Auto-imported utilities
│   └── formatters.ts
├── app.vue
├── nuxt.config.ts
├── tsconfig.json
└── package.json
```

## Installation and Setup

### Vue 3 Project Setup

```bash
# Create Vue 3 project with TypeScript
npm create vue@latest

# Select options:
# ✅ TypeScript
# ✅ Vue Router
# ✅ Pinia
# ✅ Vitest
# ✅ ESLint
# ✅ Prettier

cd project-name
npm install

# Add additional dependencies
npm install -D @types/node
npm install axios pinia vue-router

# For Azure SDK
npm install @azure/identity @azure/storage-blob @azure/arm-resources
```

### Nuxt 3 Project Setup

```bash
# Create Nuxt 3 project
npx nuxi@latest init project-name
cd project-name
npm install

# Add TypeScript support (already included in Nuxt 3)
# Add additional modules
npm install -D @nuxt/ui @pinia/nuxt @vueuse/nuxt

# For Azure SDK
npm install @azure/identity @azure/storage-blob @azure/arm-resources
```

## TypeScript Configuration

### tsconfig.json (Vue 3)

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,

    /* Vue specific */
    "types": ["vite/client"],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.tsx", "src/**/*.vue"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

### tsconfig.json (Nuxt 3)

```json
{
  "extends": "./.nuxt/tsconfig.json",
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## Code Templates

### Vue Component with TypeScript

```vue
<script setup lang="ts">
import { ref, computed, onMounted, type Ref } from "vue";
import type { ResourceGroup } from "@/types/models";

// Props with TypeScript
interface Props {
  resourceGroupId: string;
  mode?: "view" | "edit";
}

const props = withDefaults(defineProps<Props>(), {
  mode: "view",
});

// Emits with TypeScript
interface Emits {
  (e: "update", value: ResourceGroup): void;
  (e: "delete", id: string): void;
}

const emit = defineEmits<Emits>();

// State
const loading = ref(false);
const error = ref<Error | null>(null);
const resourceGroup: Ref<ResourceGroup | null> = ref(null);

// Computed
const isEditable = computed(() => props.mode === "edit" && !loading.value);

const displayName = computed(() => {
  if (!resourceGroup.value) return "Loading...";
  return `${resourceGroup.value.name} (${resourceGroup.value.location})`;
});

// Methods
async function loadResourceGroup(): Promise<void> {
  loading.value = true;
  error.value = null;

  try {
    // Fetch resource group
    const response = await fetch(`/api/resources/${props.resourceGroupId}`);
    if (!response.ok) {
      throw new Error(`Failed to load resource group: ${response.statusText}`);
    }

    resourceGroup.value = await response.json();
  } catch (e) {
    error.value = e instanceof Error ? e : new Error("Unknown error");
    console.error("Failed to load resource group:", e);
  } finally {
    loading.value = false;
  }
}

async function updateResourceGroup(): Promise<void> {
  if (!resourceGroup.value) return;

  loading.value = true;
  error.value = null;

  try {
    const response = await fetch(`/api/resources/${props.resourceGroupId}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(resourceGroup.value),
    });

    if (!response.ok) {
      throw new Error(
        `Failed to update resource group: ${response.statusText}`,
      );
    }

    const updated: ResourceGroup = await response.json();
    emit("update", updated);
  } catch (e) {
    error.value = e instanceof Error ? e : new Error("Unknown error");
    console.error("Failed to update resource group:", e);
  } finally {
    loading.value = false;
  }
}

function handleDelete(): void {
  emit("delete", props.resourceGroupId);
}

// Lifecycle
onMounted(() => {
  loadResourceGroup();
});
</script>

<template>
  <div class="resource-group">
    <div v-if="loading" class="loading">Loading resource group...</div>

    <div v-else-if="error" class="error">
      <p>Error: {{ error.message }}</p>
      <button @click="loadResourceGroup">Retry</button>
    </div>

    <div v-else-if="resourceGroup" class="content">
      <h2>{{ displayName }}</h2>

      <div class="details">
        <div class="field">
          <label>Name:</label>
          <input
            v-model="resourceGroup.name"
            :disabled="!isEditable"
            type="text"
          />
        </div>

        <div class="field">
          <label>Location:</label>
          <input
            v-model="resourceGroup.location"
            :disabled="!isEditable"
            type="text"
          />
        </div>

        <div class="field">
          <label>Tags:</label>
          <div class="tags">
            <span
              v-for="(value, key) in resourceGroup.tags"
              :key="key"
              class="tag"
            >
              {{ key }}: {{ value }}
            </span>
          </div>
        </div>
      </div>

      <div v-if="isEditable" class="actions">
        <button @click="updateResourceGroup">Save</button>
        <button @click="handleDelete" class="danger">Delete</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.resource-group {
  padding: 1rem;
}

.loading,
.error {
  padding: 2rem;
  text-align: center;
}

.error {
  color: var(--color-error);
}

.content {
  max-width: 800px;
}

.details {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin: 1rem 0;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.field label {
  font-weight: 600;
}

.field input {
  padding: 0.5rem;
  border: 1px solid var(--color-border);
  border-radius: 4px;
}

.field input:disabled {
  background-color: var(--color-background-mute);
  cursor: not-allowed;
}

.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.tag {
  padding: 0.25rem 0.5rem;
  background-color: var(--color-background-soft);
  border-radius: 4px;
  font-size: 0.875rem;
}

.actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}

button {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  background-color: var(--color-primary);
  color: white;
  cursor: pointer;
  font-weight: 600;
}

button:hover {
  opacity: 0.9;
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

button.danger {
  background-color: var(--color-error);
}
</style>
```

### Composable with TypeScript

````typescript
// composables/useAzureResources.ts
import { ref, computed, type Ref, type ComputedRef } from "vue";

export interface ResourceGroup {
  id: string;
  name: string;
  location: string;
  tags: Record<string, string>;
  createdAt: string;
  updatedAt: string;
}

export interface UseAzureResourcesOptions {
  subscriptionId: string;
  autoLoad?: boolean;
}

export interface UseAzureResourcesReturn {
  resourceGroups: Ref<ResourceGroup[]>;
  loading: Ref<boolean>;
  error: Ref<Error | null>;
  total: ComputedRef<number>;
  loadResourceGroups: (filters?: ResourceFilters) => Promise<void>;
  getResourceGroup: (id: string) => Promise<ResourceGroup | undefined>;
  createResourceGroup: (
    data: CreateResourceGroupData,
  ) => Promise<ResourceGroup>;
  deleteResourceGroup: (id: string) => Promise<void>;
}

export interface ResourceFilters {
  tags?: Record<string, string>;
  location?: string;
}

export interface CreateResourceGroupData {
  name: string;
  location: string;
  tags?: Record<string, string>;
}

/**
 * Composable for managing Azure resource groups.
 *
 * @example
 * ```ts
 * const { resourceGroups, loading, loadResourceGroups } = useAzureResources({
 *   subscriptionId: 'sub-123',
 *   autoLoad: true,
 * })
 * ```
 */
export function useAzureResources(
  options: UseAzureResourcesOptions,
): UseAzureResourcesReturn {
  const { subscriptionId, autoLoad = false } = options;

  // State
  const resourceGroups = ref<ResourceGroup[]>([]);
  const loading = ref(false);
  const error = ref<Error | null>(null);

  // Computed
  const total = computed(() => resourceGroups.value.length);

  // Methods
  async function loadResourceGroups(filters?: ResourceFilters): Promise<void> {
    loading.value = true;
    error.value = null;

    try {
      const params = new URLSearchParams({
        subscription_id: subscriptionId,
      });

      if (filters?.tags) {
        params.append("tags", JSON.stringify(filters.tags));
      }
      if (filters?.location) {
        params.append("location", filters.location);
      }

      const response = await fetch(`/api/resources?${params}`);

      if (!response.ok) {
        throw new Error(
          `Failed to load resource groups: ${response.statusText}`,
        );
      }

      const data = await response.json();
      resourceGroups.value = data.resource_groups;
    } catch (e) {
      error.value = e instanceof Error ? e : new Error("Unknown error");
      console.error("Failed to load resource groups:", e);
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function getResourceGroup(
    id: string,
  ): Promise<ResourceGroup | undefined> {
    loading.value = true;
    error.value = null;

    try {
      const response = await fetch(`/api/resources/${id}`);

      if (!response.ok) {
        if (response.status === 404) {
          return undefined;
        }
        throw new Error(`Failed to get resource group: ${response.statusText}`);
      }

      return await response.json();
    } catch (e) {
      error.value = e instanceof Error ? e : new Error("Unknown error");
      console.error("Failed to get resource group:", e);
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function createResourceGroup(
    data: CreateResourceGroupData,
  ): Promise<ResourceGroup> {
    loading.value = true;
    error.value = null;

    try {
      const response = await fetch("/api/resources", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          subscription_id: subscriptionId,
          ...data,
        }),
      });

      if (!response.ok) {
        throw new Error(
          `Failed to create resource group: ${response.statusText}`,
        );
      }

      const resourceGroup: ResourceGroup = await response.json();
      resourceGroups.value.push(resourceGroup);
      return resourceGroup;
    } catch (e) {
      error.value = e instanceof Error ? e : new Error("Unknown error");
      console.error("Failed to create resource group:", e);
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function deleteResourceGroup(id: string): Promise<void> {
    loading.value = true;
    error.value = null;

    try {
      const response = await fetch(`/api/resources/${id}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        throw new Error(
          `Failed to delete resource group: ${response.statusText}`,
        );
      }

      resourceGroups.value = resourceGroups.value.filter((rg) => rg.id !== id);
    } catch (e) {
      error.value = e instanceof Error ? e : new Error("Unknown error");
      console.error("Failed to delete resource group:", e);
      throw e;
    } finally {
      loading.value = false;
    }
  }

  // Auto-load if requested
  if (autoLoad) {
    loadResourceGroups();
  }

  return {
    resourceGroups,
    loading,
    error,
    total,
    loadResourceGroups,
    getResourceGroup,
    createResourceGroup,
    deleteResourceGroup,
  };
}
````

### Pinia Store with TypeScript

```typescript
// stores/auth.ts
import { defineStore } from "pinia";
import { ref, computed, type Ref, type ComputedRef } from "vue";

export interface User {
  id: string;
  email: string;
  name: string;
  roles: string[];
}

export interface AuthState {
  user: User | null;
  token: string | null;
  refreshToken: string | null;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface AuthStore {
  // State
  user: Ref<User | null>;
  token: Ref<string | null>;
  refreshToken: Ref<string | null>;

  // Getters
  isAuthenticated: ComputedRef<boolean>;
  hasRole: (role: string) => boolean;

  // Actions
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => Promise<void>;
  refreshAccessToken: () => Promise<void>;
  loadUser: () => Promise<void>;
}

/**
 * Authentication store using Pinia.
 * Handles user authentication, token management, and role-based access.
 */
export const useAuthStore = defineStore("auth", (): AuthStore => {
  // State
  const user = ref<User | null>(null);
  const token = ref<string | null>(null);
  const refreshToken = ref<string | null>(null);

  // Getters
  const isAuthenticated = computed(() => {
    return token.value !== null && user.value !== null;
  });

  function hasRole(role: string): boolean {
    return user.value?.roles.includes(role) ?? false;
  }

  // Actions
  async function login(credentials: LoginCredentials): Promise<void> {
    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(credentials),
      });

      if (!response.ok) {
        throw new Error("Login failed");
      }

      const data = await response.json();

      token.value = data.access_token;
      refreshToken.value = data.refresh_token;
      user.value = data.user;

      // Store tokens
      localStorage.setItem("token", data.access_token);
      localStorage.setItem("refreshToken", data.refresh_token);
    } catch (error) {
      console.error("Login error:", error);
      throw error;
    }
  }

  async function logout(): Promise<void> {
    try {
      if (token.value) {
        await fetch("/api/auth/logout", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token.value}`,
          },
        });
      }
    } catch (error) {
      console.error("Logout error:", error);
    } finally {
      // Clear state regardless of API call result
      user.value = null;
      token.value = null;
      refreshToken.value = null;

      localStorage.removeItem("token");
      localStorage.removeItem("refreshToken");
    }
  }

  async function refreshAccessToken(): Promise<void> {
    if (!refreshToken.value) {
      throw new Error("No refresh token available");
    }

    try {
      const response = await fetch("/api/auth/refresh", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh_token: refreshToken.value }),
      });

      if (!response.ok) {
        throw new Error("Token refresh failed");
      }

      const data = await response.json();

      token.value = data.access_token;
      localStorage.setItem("token", data.access_token);
    } catch (error) {
      console.error("Token refresh error:", error);
      // Clear auth state on refresh failure
      await logout();
      throw error;
    }
  }

  async function loadUser(): Promise<void> {
    const storedToken = localStorage.getItem("token");

    if (!storedToken) {
      return;
    }

    token.value = storedToken;
    refreshToken.value = localStorage.getItem("refreshToken");

    try {
      const response = await fetch("/api/auth/me", {
        headers: {
          Authorization: `Bearer ${storedToken}`,
        },
      });

      if (!response.ok) {
        throw new Error("Failed to load user");
      }

      user.value = await response.json();
    } catch (error) {
      console.error("Load user error:", error);
      await logout();
    }
  }

  return {
    // State
    user,
    token,
    refreshToken,

    // Getters
    isAuthenticated,
    hasRole,

    // Actions
    login,
    logout,
    refreshAccessToken,
    loadUser,
  };
});
```

### Type Definitions

```typescript
// types/models.ts

/**
 * Azure resource group representation.
 */
export interface ResourceGroup {
  id: string;
  name: string;
  location: string;
  tags: Record<string, string>;
  createdAt: string;
  updatedAt: string;
  managedBy?: string;
  provisioningState: ProvisioningState;
}

/**
 * Azure resource provisioning states.
 */
export type ProvisioningState =
  | "Creating"
  | "Running"
  | "Updating"
  | "Deleting"
  | "Failed"
  | "Succeeded";

/**
 * Azure storage account representation.
 */
export interface StorageAccount {
  id: string;
  name: string;
  location: string;
  resourceGroup: string;
  sku: StorageSku;
  kind: StorageKind;
  tags: Record<string, string>;
  primaryEndpoints: StorageEndpoints;
  creationTime: string;
}

/**
 * Storage SKU names.
 */
export type StorageSku =
  | "Standard_LRS"
  | "Standard_GRS"
  | "Standard_RAGRS"
  | "Standard_ZRS"
  | "Premium_LRS";

/**
 * Storage account kinds.
 */
export type StorageKind =
  | "Storage"
  | "StorageV2"
  | "BlobStorage"
  | "FileStorage"
  | "BlockBlobStorage";

/**
 * Storage account endpoints.
 */
export interface StorageEndpoints {
  blob?: string;
  file?: string;
  queue?: string;
  table?: string;
  dfs?: string;
  web?: string;
}

/**
 * API response wrapper.
 */
export interface ApiResponse<T> {
  data: T;
  message?: string;
  error?: string;
}

/**
 * Paginated API response.
 */
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
  nextPageToken?: string;
}

/**
 * API error response.
 */
export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}
```

```typescript
// types/api.ts

/**
 * HTTP methods.
 */
export type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

/**
 * API request configuration.
 */
export interface ApiRequestConfig {
  method: HttpMethod;
  url: string;
  headers?: Record<string, string>;
  params?: Record<string, string | number | boolean>;
  data?: unknown;
  timeout?: number;
}

/**
 * API client interface.
 */
export interface ApiClient {
  get<T>(url: string, config?: Partial<ApiRequestConfig>): Promise<T>;
  post<T>(
    url: string,
    data?: unknown,
    config?: Partial<ApiRequestConfig>,
  ): Promise<T>;
  put<T>(
    url: string,
    data?: unknown,
    config?: Partial<ApiRequestConfig>,
  ): Promise<T>;
  patch<T>(
    url: string,
    data?: unknown,
    config?: Partial<ApiRequestConfig>,
  ): Promise<T>;
  delete<T>(url: string, config?: Partial<ApiRequestConfig>): Promise<T>;
}

/**
 * Type guard to check if error is an ApiError.
 */
export function isApiError(error: unknown): error is ApiError {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    "message" in error
  );
}
```

### Nuxt 3 Page with TypeScript

```vue
<!-- pages/resources/[id].vue -->
<script setup lang="ts">
import type { ResourceGroup } from "@/types/models";

// Nuxt composables are auto-imported
const route = useRoute();
const router = useRouter();

// Type the route params
const resourceId = computed(() => route.params.id as string);

// Page metadata
definePageMeta({
  middleware: "auth",
  layout: "default",
});

// Head management with types
useHead({
  title: () => `Resource Group - ${resourceGroup.value?.name ?? "Loading"}`,
  meta: [
    {
      name: "description",
      content: () =>
        `Details for resource group ${resourceGroup.value?.name ?? ""}`,
    },
  ],
});

// Fetch data
const {
  data: resourceGroup,
  pending,
  error,
  refresh,
} = await useFetch<ResourceGroup>(`/api/resources/${resourceId.value}`, {
  key: `resource-${resourceId.value}`,
  // Transform response
  transform: (data: unknown) => data as ResourceGroup,
  // Handle errors
  onResponseError: ({ response }) => {
    console.error("Failed to load resource:", response.status);
  },
});

// Computed
const isLoaded = computed(() => !pending.value && resourceGroup.value !== null);

// Methods
async function handleUpdate(updated: ResourceGroup): Promise<void> {
  try {
    await $fetch(`/api/resources/${resourceId.value}`, {
      method: "PUT",
      body: updated,
    });

    await refresh();

    // Show success notification
    useToast().add({
      title: "Success",
      description: "Resource group updated successfully",
    });
  } catch (e) {
    console.error("Failed to update resource:", e);

    useToast().add({
      title: "Error",
      description: "Failed to update resource group",
      color: "red",
    });
  }
}

async function handleDelete(id: string): Promise<void> {
  try {
    await $fetch(`/api/resources/${id}`, {
      method: "DELETE",
    });

    // Navigate back to list
    await router.push("/resources");

    useToast().add({
      title: "Success",
      description: "Resource group deleted successfully",
    });
  } catch (e) {
    console.error("Failed to delete resource:", e);

    useToast().add({
      title: "Error",
      description: "Failed to delete resource group",
      color: "red",
    });
  }
}
</script>

<template>
  <div class="resource-page">
    <div v-if="pending" class="loading">
      <UIcon name="i-heroicons-arrow-path" class="animate-spin" />
      <p>Loading resource group...</p>
    </div>

    <div v-else-if="error" class="error">
      <UAlert
        icon="i-heroicons-exclamation-triangle"
        color="red"
        variant="subtle"
        title="Error loading resource group"
        :description="error.message"
      />
      <UButton @click="refresh"> Retry </UButton>
    </div>

    <div v-else-if="isLoaded">
      <ResourceGroupDetail
        :resource-group="resourceGroup!"
        :mode="'edit'"
        @update="handleUpdate"
        @delete="handleDelete"
      />
    </div>
  </div>
</template>

<style scoped>
.resource-page {
  padding: 2rem;
}

.loading,
.error {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 4rem 2rem;
}
</style>
```

### Nuxt 3 API Route with TypeScript

```typescript
// server/api/resources/[id].ts
import type { H3Event } from "h3";
import type { ResourceGroup } from "@/types/models";

/**
 * GET /api/resources/:id
 * Get a specific resource group by ID.
 */
export default defineEventHandler(
  async (event: H3Event): Promise<ResourceGroup> => {
    const id = getRouterParam(event, "id");

    if (!id) {
      throw createError({
        statusCode: 400,
        statusMessage: "Resource ID is required",
      });
    }

    try {
      // Get resource from Azure
      const resource = await getResourceGroup(id);

      if (!resource) {
        throw createError({
          statusCode: 404,
          statusMessage: "Resource group not found",
        });
      }

      return resource;
    } catch (error) {
      console.error("Failed to get resource group:", error);

      if (error instanceof H3Error) {
        throw error;
      }

      throw createError({
        statusCode: 500,
        statusMessage: "Failed to retrieve resource group",
      });
    }
  },
);

/**
 * PUT /api/resources/:id
 * Update a resource group.
 */
export async function put(event: H3Event): Promise<ResourceGroup> {
  const id = getRouterParam(event, "id");

  if (!id) {
    throw createError({
      statusCode: 400,
      statusMessage: "Resource ID is required",
    });
  }

  try {
    const body = await readBody<Partial<ResourceGroup>>(event);

    // Validate body
    if (!body.name || !body.location) {
      throw createError({
        statusCode: 400,
        statusMessage: "Name and location are required",
      });
    }

    // Update resource in Azure
    const updated = await updateResourceGroup(id, body);

    return updated;
  } catch (error) {
    console.error("Failed to update resource group:", error);

    if (error instanceof H3Error) {
      throw error;
    }

    throw createError({
      statusCode: 500,
      statusMessage: "Failed to update resource group",
    });
  }
}

/**
 * DELETE /api/resources/:id
 * Delete a resource group.
 */
export async function del(event: H3Event): Promise<{ success: boolean }> {
  const id = getRouterParam(event, "id");

  if (!id) {
    throw createError({
      statusCode: 400,
      statusMessage: "Resource ID is required",
    });
  }

  try {
    await deleteResourceGroup(id);

    return { success: true };
  } catch (error) {
    console.error("Failed to delete resource group:", error);

    if (error instanceof H3Error) {
      throw error;
    }

    throw createError({
      statusCode: 500,
      statusMessage: "Failed to delete resource group",
    });
  }
}

// Helper functions (would be in separate modules)
async function getResourceGroup(id: string): Promise<ResourceGroup | null> {
  // Implementation here
  return null;
}

async function updateResourceGroup(
  id: string,
  data: Partial<ResourceGroup>,
): Promise<ResourceGroup> {
  // Implementation here
  return {} as ResourceGroup;
}

async function deleteResourceGroup(id: string): Promise<void> {
  // Implementation here
}
```

## Testing Patterns

### Component Testing with Vitest

```typescript
// tests/unit/components/ResourceGroupDetail.spec.ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, VueWrapper } from "@vue/test-utils";
import ResourceGroupDetail from "@/components/ResourceGroupDetail.vue";
import type { ResourceGroup } from "@/types/models";

describe("ResourceGroupDetail", () => {
  let wrapper: VueWrapper;

  const mockResourceGroup: ResourceGroup = {
    id: "/subscriptions/test/resourceGroups/rg1",
    name: "rg1",
    location: "eastus",
    tags: { env: "test" },
    createdAt: "2024-01-01T00:00:00Z",
    updatedAt: "2024-01-01T00:00:00Z",
    provisioningState: "Succeeded",
  };

  beforeEach(() => {
    wrapper = mount(ResourceGroupDetail, {
      props: {
        resourceGroupId: "rg1",
        mode: "view",
      },
    });
  });

  it("renders resource group name", () => {
    expect(wrapper.text()).toContain(mockResourceGroup.name);
  });

  it("emits update event when save button clicked", async () => {
    await wrapper.setProps({ mode: "edit" });

    const button = wrapper.find('button[type="submit"]');
    await button.trigger("click");

    expect(wrapper.emitted("update")).toBeTruthy();
  });

  it("emits delete event when delete button clicked", async () => {
    await wrapper.setProps({ mode: "edit" });

    const button = wrapper.find("button.danger");
    await button.trigger("click");

    expect(wrapper.emitted("delete")).toBeTruthy();
    expect(wrapper.emitted("delete")?.[0]).toEqual(["rg1"]);
  });

  it("disables inputs in view mode", () => {
    const inputs = wrapper.findAll("input");
    inputs.forEach((input) => {
      expect(input.attributes("disabled")).toBeDefined();
    });
  });

  it("enables inputs in edit mode", async () => {
    await wrapper.setProps({ mode: "edit" });

    const inputs = wrapper.findAll("input");
    inputs.forEach((input) => {
      expect(input.attributes("disabled")).toBeUndefined();
    });
  });
});
```

### Composable Testing

```typescript
// tests/unit/composables/useAzureResources.spec.ts
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { useAzureResources } from "@/composables/useAzureResources";
import type { ResourceGroup } from "@/types/models";

// Mock fetch
global.fetch = vi.fn();

describe("useAzureResources", () => {
  const mockResourceGroups: ResourceGroup[] = [
    {
      id: "1",
      name: "rg1",
      location: "eastus",
      tags: {},
      createdAt: "2024-01-01T00:00:00Z",
      updatedAt: "2024-01-01T00:00:00Z",
      provisioningState: "Succeeded",
    },
  ];

  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("loads resource groups successfully", async () => {
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ resource_groups: mockResourceGroups }),
    } as Response);

    const { resourceGroups, loading, loadResourceGroups } = useAzureResources({
      subscriptionId: "test-sub",
    });

    expect(resourceGroups.value).toEqual([]);
    expect(loading.value).toBe(false);

    await loadResourceGroups();

    expect(loading.value).toBe(false);
    expect(resourceGroups.value).toEqual(mockResourceGroups);
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining("/api/resources"),
    );
  });

  it("handles load error", async () => {
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: false,
      statusText: "Internal Server Error",
    } as Response);

    const { error, loadResourceGroups } = useAzureResources({
      subscriptionId: "test-sub",
    });

    await expect(loadResourceGroups()).rejects.toThrow();
    expect(error.value).not.toBeNull();
  });

  it("computes total correctly", async () => {
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ resource_groups: mockResourceGroups }),
    } as Response);

    const { total, loadResourceGroups } = useAzureResources({
      subscriptionId: "test-sub",
    });

    expect(total.value).toBe(0);

    await loadResourceGroups();

    expect(total.value).toBe(1);
  });

  it("creates resource group successfully", async () => {
    const newResourceGroup: ResourceGroup = {
      id: "2",
      name: "rg2",
      location: "westus",
      tags: { env: "prod" },
      createdAt: "2024-01-02T00:00:00Z",
      updatedAt: "2024-01-02T00:00:00Z",
      provisioningState: "Succeeded",
    };

    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: async () => newResourceGroup,
    } as Response);

    const { resourceGroups, createResourceGroup } = useAzureResources({
      subscriptionId: "test-sub",
    });

    const result = await createResourceGroup({
      name: "rg2",
      location: "westus",
      tags: { env: "prod" },
    });

    expect(result).toEqual(newResourceGroup);
    expect(resourceGroups.value).toContainEqual(newResourceGroup);
  });
});
```

### Store Testing

```typescript
// tests/unit/stores/auth.spec.ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { useAuthStore } from "@/stores/auth";

// Mock fetch
global.fetch = vi.fn();

describe("Auth Store", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
    localStorage.clear();
  });

  it("initializes with null user", () => {
    const store = useAuthStore();

    expect(store.user).toBeNull();
    expect(store.token).toBeNull();
    expect(store.isAuthenticated).toBe(false);
  });

  it("logs in successfully", async () => {
    const mockUser = {
      id: "1",
      email: "test@example.com",
      name: "Test User",
      roles: ["user"],
    };

    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        access_token: "token123",
        refresh_token: "refresh123",
        user: mockUser,
      }),
    } as Response);

    const store = useAuthStore();

    await store.login({
      email: "test@example.com",
      password: "password",
    });

    expect(store.user).toEqual(mockUser);
    expect(store.token).toBe("token123");
    expect(store.isAuthenticated).toBe(true);
    expect(localStorage.getItem("token")).toBe("token123");
  });

  it("logs out successfully", async () => {
    const store = useAuthStore();

    // Set up authenticated state
    store.user = {
      id: "1",
      email: "test@example.com",
      name: "Test User",
      roles: ["user"],
    };
    store.token = "token123";

    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
    } as Response);

    await store.logout();

    expect(store.user).toBeNull();
    expect(store.token).toBeNull();
    expect(store.isAuthenticated).toBe(false);
    expect(localStorage.getItem("token")).toBeNull();
  });

  it("checks user roles", () => {
    const store = useAuthStore();

    store.user = {
      id: "1",
      email: "test@example.com",
      name: "Test User",
      roles: ["user", "admin"],
    };

    expect(store.hasRole("user")).toBe(true);
    expect(store.hasRole("admin")).toBe(true);
    expect(store.hasRole("superadmin")).toBe(false);
  });
});
```

## Vue Router with TypeScript

```typescript
// router/index.ts
import {
  createRouter,
  createWebHistory,
  type RouteRecordRaw,
  type NavigationGuardNext,
  type RouteLocationNormalized,
} from "vue-router";
import { useAuthStore } from "@/stores/auth";

// Type-safe route names
export enum RouteNames {
  Home = "home",
  Dashboard = "dashboard",
  Resources = "resources",
  ResourceDetail = "resource-detail",
  Login = "login",
  NotFound = "not-found",
}

// Extend route meta types
declare module "vue-router" {
  interface RouteMeta {
    requiresAuth?: boolean;
    roles?: string[];
    layout?: "default" | "admin" | "auth";
    title?: string;
  }
}

const routes: RouteRecordRaw[] = [
  {
    path: "/",
    name: RouteNames.Home,
    component: () => import("@/views/Home.vue"),
    meta: {
      title: "Home",
    },
  },
  {
    path: "/dashboard",
    name: RouteNames.Dashboard,
    component: () => import("@/views/Dashboard.vue"),
    meta: {
      requiresAuth: true,
      title: "Dashboard",
    },
  },
  {
    path: "/resources",
    name: RouteNames.Resources,
    component: () => import("@/views/Resources.vue"),
    meta: {
      requiresAuth: true,
      title: "Resources",
    },
  },
  {
    path: "/resources/:id",
    name: RouteNames.ResourceDetail,
    component: () => import("@/views/ResourceDetail.vue"),
    meta: {
      requiresAuth: true,
      title: "Resource Details",
    },
    props: true,
  },
  {
    path: "/login",
    name: RouteNames.Login,
    component: () => import("@/views/Login.vue"),
    meta: {
      layout: "auth",
      title: "Login",
    },
  },
  {
    path: "/:pathMatch(.*)*",
    name: RouteNames.NotFound,
    component: () => import("@/views/NotFound.vue"),
    meta: {
      title: "Not Found",
    },
  },
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});

// Navigation guard with TypeScript
router.beforeEach(
  async (
    to: RouteLocationNormalized,
    from: RouteLocationNormalized,
    next: NavigationGuardNext,
  ): Promise<void> => {
    const authStore = useAuthStore();

    // Set page title
    document.title = to.meta.title ? `${to.meta.title} - My App` : "My App";

    // Check authentication
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
      next({ name: RouteNames.Login, query: { redirect: to.fullPath } });
      return;
    }

    // Check roles
    if (
      to.meta.roles &&
      !to.meta.roles.some((role) => authStore.hasRole(role))
    ) {
      next({ name: RouteNames.Home });
      return;
    }

    next();
  },
);

export default router;
```

## Nuxt 3 Specific Patterns

### Middleware with TypeScript

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const authStore = useAuthStore();

  // Check if user is authenticated
  if (!authStore.isAuthenticated) {
    // Redirect to login with return URL
    return navigateTo({
      path: "/login",
      query: { redirect: to.fullPath },
    });
  }

  // Check role-based access if specified
  const requiredRoles = to.meta.roles as string[] | undefined;
  if (requiredRoles) {
    const hasAccess = requiredRoles.some((role) => authStore.hasRole(role));

    if (!hasAccess) {
      return abortNavigation("Insufficient permissions");
    }
  }
});
```

### Plugin with TypeScript

```typescript
// plugins/api.ts
import type { $Fetch } from "nitropack";

interface ApiInstance {
  $api: $Fetch;
}

export default defineNuxtPlugin((nuxtApp): ApiInstance => {
  const config = useRuntimeConfig();
  const authStore = useAuthStore();

  // Create custom fetch instance
  const $api = $fetch.create({
    baseURL: config.public.apiBase as string,

    onRequest({ options }) {
      // Add auth token to all requests
      const token = authStore.token;
      if (token) {
        options.headers = {
          ...options.headers,
          Authorization: `Bearer ${token}`,
        };
      }
    },

    onResponseError({ response }) {
      // Handle 401 errors
      if (response.status === 401) {
        authStore.logout();
        navigateTo("/login");
      }
    },
  });

  return {
    provide: {
      api: $api,
    },
  };
});

// Augment Nuxt types
declare module "#app" {
  interface NuxtApp {
    $api: $Fetch;
  }
}
```

### Nuxt Config with TypeScript

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  devtools: { enabled: true },

  modules: ["@nuxt/ui", "@pinia/nuxt", "@vueuse/nuxt"],

  typescript: {
    strict: true,
    typeCheck: true,
  },

  runtimeConfig: {
    // Private keys (server-only)
    azureClientSecret: process.env.AZURE_CLIENT_SECRET,

    // Public keys (client-accessible)
    public: {
      apiBase: process.env.API_BASE_URL || "http://localhost:3000/api",
      azureSubscriptionId: process.env.AZURE_SUBSCRIPTION_ID,
      azureTenantId: process.env.AZURE_TENANT_ID,
    },
  },

  app: {
    head: {
      title: "My App",
      meta: [
        { charset: "utf-8" },
        { name: "viewport", content: "width=device-width, initial-scale=1" },
      ],
      link: [{ rel: "icon", type: "image/x-icon", href: "/favicon.ico" }],
    },
  },

  css: ["~/assets/styles/main.css"],

  vite: {
    server: {
      hmr: {
        protocol: "ws",
        host: "localhost",
      },
    },
  },
});
```

## Advanced TypeScript Patterns

### Utility Types

```typescript
// types/utils.ts

/**
 * Make all properties optional recursively.
 */
export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

/**
 * Make all properties required recursively.
 */
export type DeepRequired<T> = {
  [P in keyof T]-?: T[P] extends object ? DeepRequired<T[P]> : T[P];
};

/**
 * Make all properties readonly recursively.
 */
export type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};

/**
 * Extract promise type.
 */
export type Awaited<T> = T extends Promise<infer U> ? U : T;

/**
 * Extract function return type.
 */
export type ReturnTypeOf<T> = T extends (...args: any[]) => infer R ? R : never;

/**
 * Extract function parameters.
 */
export type ParametersOf<T> = T extends (...args: infer P) => any ? P : never;

/**
 * Omit properties from union types.
 */
export type DistributiveOmit<T, K extends keyof any> = T extends any
  ? Omit<T, K>
  : never;

/**
 * Pick properties from union types.
 */
export type DistributivePick<T, K extends keyof any> = T extends any
  ? Pick<T, Extract<keyof T, K>>
  : never;

/**
 * Make specific properties optional.
 */
export type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

/**
 * Make specific properties required.
 */
export type RequiredBy<T, K extends keyof T> = Omit<T, K> &
  Required<Pick<T, K>>;
```

### Type Guards

```typescript
// types/guards.ts

/**
 * Type guard to check if value is defined.
 */
export function isDefined<T>(value: T | undefined | null): value is T {
  return value !== undefined && value !== null;
}

/**
 * Type guard to check if value is a string.
 */
export function isString(value: unknown): value is string {
  return typeof value === "string";
}

/**
 * Type guard to check if value is a number.
 */
export function isNumber(value: unknown): value is number {
  return typeof value === "number" && !isNaN(value);
}

/**
 * Type guard to check if value is an array.
 */
export function isArray<T>(value: unknown): value is T[] {
  return Array.isArray(value);
}

/**
 * Type guard to check if value is an object.
 */
export function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * Type guard to check if error is an Error instance.
 */
export function isError(error: unknown): error is Error {
  return error instanceof Error;
}

/**
 * Type guard to check if value has a specific property.
 */
export function hasProperty<K extends string>(
  obj: unknown,
  key: K,
): obj is Record<K, unknown> {
  return isObject(obj) && key in obj;
}

/**
 * Type guard for discriminated unions.
 */
export function isResourceGroup(resource: unknown): resource is ResourceGroup {
  return (
    isObject(resource) &&
    hasProperty(resource, "id") &&
    hasProperty(resource, "name") &&
    hasProperty(resource, "location")
  );
}
```

### Generic Components

```vue
<!-- components/base/BaseList.vue -->
<script setup lang="ts" generic="T extends { id: string | number }">
import { computed, type ComputedRef } from "vue";

interface Props {
  items: T[];
  loading?: boolean;
  emptyMessage?: string;
}

interface Emits {
  (e: "select", item: T): void;
  (e: "delete", id: string | number): void;
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  emptyMessage: "No items found",
});

const emit = defineEmits<Emits>();

// Computed
const hasItems: ComputedRef<boolean> = computed(() => props.items.length > 0);

// Methods
function handleSelect(item: T): void {
  emit("select", item);
}

function handleDelete(item: T): void {
  emit("delete", item.id);
}
</script>

<template>
  <div class="base-list">
    <div v-if="loading" class="loading">Loading...</div>

    <div v-else-if="!hasItems" class="empty">
      {{ emptyMessage }}
    </div>

    <ul v-else class="list">
      <li v-for="item in items" :key="item.id" class="list-item">
        <slot
          name="item"
          :item="item"
          :select="() => handleSelect(item)"
          :delete="() => handleDelete(item)"
        />
      </li>
    </ul>
  </div>
</template>

<style scoped>
.base-list {
  width: 100%;
}

.loading,
.empty {
  padding: 2rem;
  text-align: center;
  color: var(--color-text-muted);
}

.list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.list-item {
  border-bottom: 1px solid var(--color-border);
}

.list-item:last-child {
  border-bottom: none;
}
</style>
```

## Build Configuration

### vite.config.ts

```typescript
import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import vueDevTools from "vite-plugin-vue-devtools";

export default defineConfig({
  plugins: [vue(), vueDevTools()],

  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },

  server: {
    port: 3000,
    strictPort: false,
    host: true,
    proxy: {
      "/api": {
        target: "http://localhost:8000",
        changeOrigin: true,
        secure: false,
      },
    },
  },

  build: {
    target: "esnext",
    minify: "terser",
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          "vue-vendor": ["vue", "vue-router", "pinia"],
          "azure-sdk": [
            "@azure/identity",
            "@azure/storage-blob",
            "@azure/arm-resources",
          ],
        },
      },
    },
  },

  optimizeDeps: {
    include: ["vue", "vue-router", "pinia"],
  },
});
```

### ESLint Configuration

```typescript
// eslint.config.js
import js from "@eslint/js";
import typescript from "@typescript-eslint/eslint-plugin";
import typescriptParser from "@typescript-eslint/parser";
import vue from "eslint-plugin-vue";
import vueParser from "vue-eslint-parser";

export default [
  js.configs.recommended,
  {
    files: ["**/*.ts", "**/*.tsx", "**/*.vue"],
    languageOptions: {
      parser: vueParser,
      parserOptions: {
        parser: typescriptParser,
        ecmaVersion: "latest",
        sourceType: "module",
      },
    },
    plugins: {
      "@typescript-eslint": typescript,
      vue,
    },
    rules: {
      ...typescript.configs.strict.rules,
      ...vue.configs["vue3-recommended"].rules,

      // TypeScript specific
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/explicit-function-return-type": "warn",
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],

      // Vue specific
      "vue/multi-word-component-names": "off",
      "vue/require-default-prop": "off",
      "vue/component-api-style": ["error", ["script-setup"]],
      "vue/block-lang": [
        "error",
        {
          script: { lang: "ts" },
        },
      ],
    },
  },
];
```

## package.json Scripts

```json
{
  "name": "vue-nuxt-app",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage",
    "lint": "eslint . --ext .vue,.js,.jsx,.cjs,.mjs,.ts,.tsx,.cts,.mts --fix --ignore-path .gitignore",
    "format": "prettier --write src/",
    "type-check": "vue-tsc --noEmit"
  },
  "dependencies": {
    "@azure/arm-resources": "^5.0.0",
    "@azure/identity": "^4.0.0",
    "@azure/storage-blob": "^12.0.0",
    "pinia": "^2.1.0",
    "vue": "^3.4.0",
    "vue-router": "^4.2.0"
  },
  "devDependencies": {
    "@tsconfig/node20": "^20.1.0",
    "@types/node": "^20.11.0",
    "@typescript-eslint/eslint-plugin": "^7.0.0",
    "@typescript-eslint/parser": "^7.0.0",
    "@vitejs/plugin-vue": "^5.0.0",
    "@vue/test-utils": "^2.4.0",
    "@vue/tsconfig": "^0.5.0",
    "eslint": "^8.56.0",
    "eslint-plugin-vue": "^9.20.0",
    "jsdom": "^24.0.0",
    "prettier": "^3.2.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "vite-plugin-vue-devtools": "^7.0.0",
    "vitest": "^1.2.0",
    "vue-tsc": "^1.8.0"
  }
}
```

## AI Assistant Guidelines

### When Reviewing Code

1. **Check TypeScript Usage**
   - Verify all files use `.ts` or `.vue` with `lang="ts"`
   - Check for `any` types - should be minimal
   - Ensure proper generic types usage
   - Verify interface definitions are complete
   - Check for proper type guards

2. **Check Vue Patterns**
   - Verify `<script setup>` syntax is used
   - Check for proper `defineProps` and `defineEmits` typing
   - Ensure composables return proper types
   - Verify proper use of `ref` vs `reactive`
   - Check for proper cleanup in `onUnmounted`

3. **Check Nuxt Patterns** (if applicable)
   - Verify auto-imports are working
   - Check for proper `useFetch` typing
   - Ensure server routes have proper types
   - Verify middleware has correct signatures

4. **Check Code Quality**
   - Run ESLint and fix issues
   - Verify Prettier formatting
   - Check for unused imports
   - Ensure proper error handling

### When Writing Code

1. Always use TypeScript with strict mode
2. Use `<script setup>` for all Vue components
3. Define proper interfaces for props and emits
4. Use composables for reusable logic
5. Implement proper error handling
6. Write tests alongside components
7. Use type guards for runtime checks
8. Leverage Vue 3 reactivity system properly
9. Follow single-responsibility principle
10. Use Pinia for global state management

### When Debugging

1. Check TypeScript errors first (`vue-tsc`)
2. Use Vue DevTools for component inspection
3. Check network tab for API issues
4. Use `console.log` with types for debugging
5. Verify reactivity is working correctly
6. Check for prop drilling issues
7. Verify proper lifecycle hook usage

## Resources

- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
- [Vue 3 Documentation](https://vuejs.org/)
- [Nuxt 3 Documentation](https://nuxt.com/)
- [Pinia Documentation](https://pinia.vuejs.org/)
- [Vite Documentation](https://vitejs.dev/)
- [Vitest Documentation](https://vitest.dev/)
- [Vue Router Documentation](https://router.vuejs.org/)
- [VueUse](https://vueuse.org/) - Collection of Vue composition utilities
- [Nuxt UI](https://ui.nuxt.com/) - UI component library for Nuxt

## Editor Setup

For LazyVim (preferred) or VSCode configuration, see [EDITORS.md](./EDITORS.md).

## Version History

- 1.0.0 - Initial version with comprehensive TypeScript/Vue/Nuxt guidelines
