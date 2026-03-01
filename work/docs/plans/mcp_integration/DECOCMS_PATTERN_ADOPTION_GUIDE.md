# DecoCMS Pattern Adoption Guide for SPOTS MCP Server

**Date:** November 21, 2025  
**Status:** Implementation Guide  
**Purpose:** Practical guide for adopting DecoCMS patterns in SPOTS MCP server implementation

> **Reference:** [`DECOCMS_EVALUATION.md`](./DECOCMS_EVALUATION.md) - Full evaluation and rationale

---

## 🎯 **OVERVIEW**

This guide provides **specific, actionable code examples** for adopting DecoCMS patterns in SPOTS' Supabase Edge Functions MCP server implementation.

**What We're Adopting:**
- ✅ Type-safe tool definitions (Zod)
- ✅ Context pattern (MCPContext)
- ✅ Observability (OpenTelemetry)
- ✅ Policy enforcement (access control middleware)

**What We're NOT Adopting:**
- ❌ Full DecoCMS framework
- ❌ React frontend
- ❌ Cloudflare deployment

---

## 📁 **FILE STRUCTURE**

```
supabase/functions/mcp-server/
├── index.ts                    # Main MCP server entry point
├── core/
│   ├── context.ts              # MCPContext definition
│   ├── access_control.ts       # Policy enforcement
│   └── types.ts                # Shared types
├── tools/
│   ├── admin_tools.ts          # Admin tools with Zod schemas
│   ├── business_tools.ts       # Business account tools
│   └── tool_registry.ts        # Tool registration system
├── observability/
│   ├── tracing.ts              # OpenTelemetry integration
│   └── logging.ts              # Structured logging
└── utils/
    ├── validation.ts           # Zod validation helpers
    └── errors.ts               # Error handling
```

---

## 1️⃣ **TYPE-SAFE TOOL DEFINITIONS (ZOD)**

### **Pattern: Zod Schema Validation**

**DecoCMS Approach:**
- Uses Zod for input/output validation
- Type-safe tool definitions
- Runtime validation

**SPOTS Implementation:**

#### **Step 1: Install Zod for Deno**

```typescript
// supabase/functions/mcp-server/utils/validation.ts
import { z } from "https://deno.land/x/zod/mod.ts"

// Re-export for convenience
export { z }
export type { ZodType, ZodObject, ZodSchema } from "https://deno.land/x/zod/mod.ts"
```

#### **Step 2: Define Tool Schema**

```typescript
// supabase/functions/mcp-server/tools/admin_tools.ts
import { z } from "../utils/validation.ts"
import type { MCPContext } from "../core/context.ts"

// Input schema for get_system_health tool
export const GetSystemHealthInputSchema = z.object({
  includeMetrics: z.boolean().optional().default(false),
  includeUsers: z.boolean().optional().default(false),
}).optional().default({})

// Output schema for get_system_health tool
export const GetSystemHealthOutputSchema = z.object({
  health: z.number().min(0).max(100),
  status: z.enum(["healthy", "degraded", "unhealthy"]),
  timestamp: z.string().datetime(),
  metrics: z.object({
    totalUsers: z.number().optional(),
    activeUsers: z.number().optional(),
    totalSpots: z.number().optional(),
    totalLists: z.number().optional(),
  }).optional(),
})

// Tool definition with type safety
export const getSystemHealthTool = {
  name: "get_system_health",
  description: "Get system health metrics and status",
  inputSchema: {
    type: "object",
    properties: {
      includeMetrics: {
        type: "boolean",
        description: "Include detailed metrics",
        default: false,
      },
      includeUsers: {
        type: "boolean",
        description: "Include user statistics",
        default: false,
      },
    },
  },
  handler: async (
    input: z.infer<typeof GetSystemHealthInputSchema>,
    ctx: MCPContext
  ): Promise<z.infer<typeof GetSystemHealthOutputSchema>> => {
    // Input is automatically validated and typed
    const validatedInput = GetSystemHealthInputSchema.parse(input)
    
    // Implementation...
    const health = await calculateSystemHealth(ctx)
    
    // Output is type-checked
    return GetSystemHealthOutputSchema.parse({
      health,
      status: health > 80 ? "healthy" : health > 50 ? "degraded" : "unhealthy",
      timestamp: new Date().toISOString(),
      metrics: validatedInput.includeMetrics ? await getMetrics(ctx) : undefined,
    })
  },
}
```

#### **Step 3: Search Users Tool Example**

```typescript
// supabase/functions/mcp-server/tools/admin_tools.ts

// Input schema
export const SearchUsersInputSchema = z.object({
  query: z.string().min(1).max(100),
  filters: z.object({
    role: z.enum(["user", "admin", "business", "expert"]).optional(),
    verified: z.boolean().optional(),
    active: z.boolean().optional(),
  }).optional(),
  limit: z.number().int().min(1).max(100).optional().default(20),
  offset: z.number().int().min(0).optional().default(0),
})

// Output schema
export const SearchUsersOutputSchema = z.object({
  users: z.array(z.object({
    id: z.string().uuid(),
    email: z.string().email().optional(),
    role: z.enum(["user", "admin", "business", "expert"]),
    verified: z.boolean(),
    createdAt: z.string().datetime(),
    lastActiveAt: z.string().datetime().optional(),
  })),
  total: z.number().int(),
  limit: z.number().int(),
  offset: z.number().int(),
})

export const searchUsersTool = {
  name: "search_users",
  description: "Search and filter users by query and criteria",
  inputSchema: {
    type: "object",
    properties: {
      query: {
        type: "string",
        description: "Search query (name, email, etc.)",
      },
      filters: {
        type: "object",
        properties: {
          role: {
            type: "string",
            enum: ["user", "admin", "business", "expert"],
          },
          verified: { type: "boolean" },
          active: { type: "boolean" },
        },
      },
      limit: { type: "number", default: 20 },
      offset: { type: "number", default: 0 },
    },
    required: ["query"],
  },
  handler: async (
    input: z.infer<typeof SearchUsersInputSchema>,
    ctx: MCPContext
  ): Promise<z.infer<typeof SearchUsersOutputSchema>> => {
    // Validate input
    const validated = SearchUsersInputSchema.parse(input)
    
    // Type-safe database query
    const { data, error, count } = await ctx.data.searchUsers({
      query: validated.query,
      filters: validated.filters,
      limit: validated.limit,
      offset: validated.offset,
    })
    
    if (error) throw error
    
    // Validate and return type-safe output
    return SearchUsersOutputSchema.parse({
      users: data || [],
      total: count || 0,
      limit: validated.limit,
      offset: validated.offset,
    })
  },
}
```

#### **Step 4: Validation Helper**

```typescript
// supabase/functions/mcp-server/utils/validation.ts
import { z } from "https://deno.land/x/zod/mod.ts"
import { ZodError } from "https://deno.land/x/zod/mod.ts"

/**
 * Validate input against Zod schema with helpful error messages
 */
export function validateInput<T extends z.ZodType>(
  schema: T,
  input: unknown
): z.infer<T> {
  try {
    return schema.parse(input)
  } catch (error) {
    if (error instanceof ZodError) {
      const messages = error.errors.map((e) => 
        `${e.path.join(".")}: ${e.message}`
      ).join(", ")
      throw new Error(`Validation error: ${messages}`)
    }
    throw error
  }
}

/**
 * Validate output against Zod schema (for development/debugging)
 */
export function validateOutput<T extends z.ZodType>(
  schema: T,
  output: unknown
): z.infer<T> {
  try {
    return schema.parse(output)
  } catch (error) {
    if (error instanceof ZodError) {
      console.error("Output validation failed:", error.errors)
      // In production, might want to log but not throw
      // For now, throw to catch bugs early
      throw new Error(`Output validation error: ${JSON.stringify(error.errors)}`)
    }
    throw error
  }
}
```

---

## 2️⃣ **CONTEXT PATTERN (MCPCONTEXT)**

### **Pattern: Execution Context with Dependencies**

**DecoCMS Approach:**
- MeshContext provides auth, access, storage, observability
- Clean separation of concerns
- Testable and mockable

**SPOTS Implementation:**

#### **Step 1: Define MCPContext Interface**

```typescript
// supabase/functions/mcp-server/core/context.ts
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2"

/**
 * Access control interface
 */
export interface AccessControl {
  /**
   * Check if user has permission
   */
  check(permission: string): Promise<boolean>
  
  /**
   * Require permission (throws if not granted)
   */
  require(permission: string): Promise<void>
  
  /**
   * Get user role
   */
  getRole(): Promise<string>
  
  /**
   * Check if user is admin
   */
  isAdmin(): Promise<boolean>
}

/**
 * Data access interface
 */
export interface DataAccess {
  /**
   * Search users
   */
  searchUsers(params: {
    query: string
    filters?: {
      role?: string
      verified?: boolean
      active?: boolean
    }
    limit: number
    offset: number
  }): Promise<{ data: any[] | null; error: any; count: number | null }>
  
  /**
   * Get user by ID
   */
  getUserById(userId: string): Promise<{ data: any | null; error: any }>
  
  /**
   * Get system metrics
   */
  getSystemMetrics(): Promise<{
    totalUsers: number
    activeUsers: number
    totalSpots: number
    totalLists: number
  }>
  
  /**
   * Get businesses
   */
  getBusinesses(params: {
    verified?: boolean
    limit: number
    offset: number
  }): Promise<{ data: any[] | null; error: any; count: number | null }>
}

/**
 * Audit logger interface
 */
export interface AuditLogger {
  /**
   * Log tool execution
   */
  logToolExecution(params: {
    toolName: string
    userId: string
    input: unknown
    output?: unknown
    error?: Error
    duration: number
  }): Promise<void>
  
  /**
   * Log access denial
   */
  logAccessDenial(params: {
    userId: string
    permission: string
    resource: string
  }): Promise<void>
}

/**
 * MCP Context - provides all dependencies for tool execution
 */
export interface MCPContext {
  /**
   * User ID from authentication
   */
  userId: string
  
  /**
   * User role
   */
  role: "admin" | "user" | "business" | "expert"
  
  /**
   * Access control
   */
  access: AccessControl
  
  /**
   * Data access layer
   */
  data: DataAccess
  
  /**
   * Audit logging
   */
  audit: AuditLogger
  
  /**
   * Supabase client (for direct access if needed)
   */
  supabase: SupabaseClient
}
```

#### **Step 2: Implement Access Control**

```typescript
// supabase/functions/mcp-server/core/access_control.ts
import type { MCPContext, AccessControl } from "./context.ts"
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2"

/**
 * Permission definitions
 */
export const PERMISSIONS = {
  // Admin permissions
  ADMIN_VIEW_SYSTEM_HEALTH: "admin:view:system_health",
  ADMIN_SEARCH_USERS: "admin:search:users",
  ADMIN_VIEW_USER_DETAILS: "admin:view:user_details",
  ADMIN_VIEW_BUSINESSES: "admin:view:businesses",
  ADMIN_VIEW_AI2AI_STATUS: "admin:view:ai2ai_status",
  
  // Business permissions
  BUSINESS_VIEW_EXPERTS: "business:view:experts",
  BUSINESS_VIEW_PARTNERSHIPS: "business:view:partnerships",
  BUSINESS_VIEW_REVENUE: "business:view:revenue",
  
  // Expert permissions
  EXPERT_VIEW_BUSINESSES: "expert:view:businesses",
  EXPERT_VIEW_PARTNERSHIPS: "expert:view:partnerships",
  EXPERT_VIEW_EARNINGS: "expert:view:earnings",
} as const

/**
 * Role-based permission mapping
 */
const ROLE_PERMISSIONS: Record<string, string[]> = {
  admin: [
    PERMISSIONS.ADMIN_VIEW_SYSTEM_HEALTH,
    PERMISSIONS.ADMIN_SEARCH_USERS,
    PERMISSIONS.ADMIN_VIEW_USER_DETAILS,
    PERMISSIONS.ADMIN_VIEW_BUSINESSES,
    PERMISSIONS.ADMIN_VIEW_AI2AI_STATUS,
  ],
  business: [
    PERMISSIONS.BUSINESS_VIEW_EXPERTS,
    PERMISSIONS.BUSINESS_VIEW_PARTNERSHIPS,
    PERMISSIONS.BUSINESS_VIEW_REVENUE,
  ],
  expert: [
    PERMISSIONS.EXPERT_VIEW_BUSINESSES,
    PERMISSIONS.EXPERT_VIEW_PARTNERSHIPS,
    PERMISSIONS.EXPERT_VIEW_EARNINGS,
  ],
  user: [], // Regular users have no MCP permissions
}

/**
 * Create access control instance
 */
export function createAccessControl(
  userId: string,
  role: string,
  supabase: SupabaseClient
): AccessControl {
  return {
    async check(permission: string): Promise<boolean> {
      // Get role permissions
      const rolePerms = ROLE_PERMISSIONS[role] || []
      
      // Check if role has permission
      if (rolePerms.includes(permission)) {
        return true
      }
      
      // Could add additional checks here (e.g., database lookups)
      return false
    },
    
    async require(permission: string): Promise<void> {
      const hasAccess = await this.check(permission)
      if (!hasAccess) {
        throw new Error(`Permission denied: ${permission}`)
      }
    },
    
    async getRole(): Promise<string> {
      return role
    },
    
    async isAdmin(): Promise<boolean> {
      return role === "admin"
    },
  }
}

/**
 * Require permission helper (throws if not granted)
 */
export async function requirePermission(
  ctx: MCPContext,
  permission: string
): Promise<void> {
  await ctx.access.require(permission)
}
```

#### **Step 3: Implement Data Access**

```typescript
// supabase/functions/mcp-server/core/data_access.ts
import type { DataAccess } from "./context.ts"
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2"

/**
 * Create data access instance
 */
export function createDataAccess(supabase: SupabaseClient): DataAccess {
  return {
    async searchUsers(params) {
      let query = supabase
        .from("users")
        .select("*", { count: "exact" })
      
      // Apply search query
      if (params.query) {
        query = query.or(`email.ilike.%${params.query}%,name.ilike.%${params.query}%`)
      }
      
      // Apply filters
      if (params.filters?.role) {
        query = query.eq("role", params.filters.role)
      }
      if (params.filters?.verified !== undefined) {
        query = query.eq("verified", params.filters.verified)
      }
      if (params.filters?.active !== undefined) {
        query = query.eq("active", params.filters.active)
      }
      
      // Apply pagination
      query = query
        .range(params.offset, params.offset + params.limit - 1)
        .order("created_at", { ascending: false })
      
      const { data, error, count } = await query
      
      return { data, error, count }
    },
    
    async getUserById(userId: string) {
      const { data, error } = await supabase
        .from("users")
        .select("*")
        .eq("id", userId)
        .single()
      
      return { data, error }
    },
    
    async getSystemMetrics() {
      // Get total users
      const { count: totalUsers } = await supabase
        .from("users")
        .select("*", { count: "exact", head: true })
      
      // Get active users (last 30 days)
      const thirtyDaysAgo = new Date()
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
      
      const { count: activeUsers } = await supabase
        .from("users")
        .select("*", { count: "exact", head: true })
        .gte("last_active_at", thirtyDaysAgo.toISOString())
      
      // Get total spots
      const { count: totalSpots } = await supabase
        .from("spots")
        .select("*", { count: "exact", head: true })
      
      // Get total lists
      const { count: totalLists } = await supabase
        .from("lists")
        .select("*", { count: "exact", head: true })
      
      return {
        totalUsers: totalUsers || 0,
        activeUsers: activeUsers || 0,
        totalSpots: totalSpots || 0,
        totalLists: totalLists || 0,
      }
    },
    
    async getBusinesses(params) {
      let query = supabase
        .from("businesses")
        .select("*", { count: "exact" })
      
      if (params.verified !== undefined) {
        query = query.eq("verified", params.verified)
      }
      
      query = query
        .range(params.offset, params.offset + params.limit - 1)
        .order("created_at", { ascending: false })
      
      const { data, error, count } = await query
      
      return { data, error, count }
    },
  }
}
```

#### **Step 4: Implement Audit Logger**

```typescript
// supabase/functions/mcp-server/core/audit_logger.ts
import type { AuditLogger } from "./context.ts"
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2"

/**
 * Create audit logger instance
 */
export function createAuditLogger(supabase: SupabaseClient): AuditLogger {
  return {
    async logToolExecution(params) {
      // Log to audit table
      await supabase.from("mcp_audit_log").insert({
        user_id: params.userId,
        tool_name: params.toolName,
        input: params.input,
        output: params.output,
        error: params.error ? {
          message: params.error.message,
          stack: params.error.stack,
        } : null,
        duration_ms: params.duration,
        timestamp: new Date().toISOString(),
      })
      
      // Also log to console for debugging
      console.log(`[AUDIT] ${params.toolName}`, {
        userId: params.userId,
        duration: params.duration,
        error: params.error?.message,
      })
    },
    
    async logAccessDenial(params) {
      await supabase.from("mcp_access_denials").insert({
        user_id: params.userId,
        permission: params.permission,
        resource: params.resource,
        timestamp: new Date().toISOString(),
      })
      
      console.warn(`[ACCESS DENIED] ${params.userId} - ${params.permission}`, {
        resource: params.resource,
      })
    },
  }
}
```

#### **Step 5: Create Context Factory**

```typescript
// supabase/functions/mcp-server/core/context.ts (continued)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { createAccessControl } from "./access_control.ts"
import { createDataAccess } from "./data_access.ts"
import { createAuditLogger } from "./audit_logger.ts"

/**
 * Create MCP context from request
 */
export async function createMCPContext(
  userId: string,
  role: string
): Promise<MCPContext> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  
  const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: { persistSession: false },
  })
  
  return {
    userId,
    role: role as "admin" | "user" | "business" | "expert",
    access: createAccessControl(userId, role, supabase),
    data: createDataAccess(supabase),
    audit: createAuditLogger(supabase),
    supabase,
  }
}
```

---

## 3️⃣ **OBSERVABILITY (OPENTELEMETRY)**

### **Pattern: Distributed Tracing**

**DecoCMS Approach:**
- OpenTelemetry tracing
- Cost per step analysis
- Error analytics

**SPOTS Implementation:**

#### **Step 1: Setup OpenTelemetry**

```typescript
// supabase/functions/mcp-server/observability/tracing.ts
import { trace, context, SpanStatusCode } from "https://deno.land/x/opentelemetry/api/mod.ts"
import { OTLPTraceExporter } from "https://deno.land/x/opentelemetry_exporter_otlp_http/mod.ts"
import { Resource } from "https://deno.land/x/opentelemetry_sdk/mod.ts"
import { BasicTracerProvider, SimpleSpanProcessor } from "https://deno.land/x/opentelemetry_sdk/mod.ts"

// Initialize tracer provider
const provider = new BasicTracerProvider({
  resource: new Resource({
    "service.name": "spots-mcp-server",
    "service.version": "1.0.0",
  }),
})

// Configure exporter (optional - can use console for development)
const exporter = Deno.env.get("OTEL_EXPORTER_OTLP_ENDPOINT")
  ? new OTLPTraceExporter({
      url: Deno.env.get("OTEL_EXPORTER_OTLP_ENDPOINT")!,
    })
  : undefined

if (exporter) {
  provider.addSpanProcessor(new SimpleSpanProcessor(exporter))
}

provider.register()

// Get tracer
export const tracer = trace.getTracer("spots-mcp")

/**
 * Trace tool execution
 */
export async function traceToolExecution<T>(
  toolName: string,
  handler: () => Promise<T>
): Promise<T> {
  return tracer.startActiveSpan(`mcp.tool.${toolName}`, async (span) => {
    const startTime = Date.now()
    
    try {
      span.setAttributes({
        "tool.name": toolName,
        "tool.type": "mcp",
      })
      
      const result = await handler()
      
      const duration = Date.now() - startTime
      span.setAttributes({
        "tool.duration_ms": duration,
        "tool.success": true,
      })
      span.setStatus({ code: SpanStatusCode.OK })
      
      return result
    } catch (error) {
      const duration = Date.now() - startTime
      span.setAttributes({
        "tool.duration_ms": duration,
        "tool.success": false,
        "error.message": error instanceof Error ? error.message : String(error),
      })
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error instanceof Error ? error.message : String(error),
      })
      span.recordException(error as Error)
      
      throw error
    } finally {
      span.end()
    }
  })
}

/**
 * Add span attributes
 */
export function addSpanAttribute(key: string, value: string | number | boolean) {
  const span = trace.getActiveSpan()
  if (span) {
    span.setAttribute(key, value)
  }
}

/**
 * Record exception in current span
 */
export function recordException(error: Error) {
  const span = trace.getActiveSpan()
  if (span) {
    span.recordException(error)
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error.message,
    })
  }
}
```

#### **Step 2: Integrate Tracing in Tools**

```typescript
// supabase/functions/mcp-server/tools/admin_tools.ts
import { traceToolExecution } from "../observability/tracing.ts"
import { addSpanAttribute } from "../observability/tracing.ts"

export const getSystemHealthTool = {
  name: "get_system_health",
  // ... schema definitions ...
  handler: async (
    input: z.infer<typeof GetSystemHealthInputSchema>,
    ctx: MCPContext
  ): Promise<z.infer<typeof GetSystemHealthOutputSchema>> => {
    // Wrap handler in tracing
    return traceToolExecution("get_system_health", async () => {
      // Add context attributes
      addSpanAttribute("user.id", ctx.userId)
      addSpanAttribute("user.role", ctx.role)
      addSpanAttribute("input.include_metrics", String(input?.includeMetrics || false))
      
      // Validate input
      const validatedInput = GetSystemHealthInputSchema.parse(input)
      
      // Check permissions
      await ctx.access.require(PERMISSIONS.ADMIN_VIEW_SYSTEM_HEALTH)
      
      // Calculate health
      const health = await calculateSystemHealth(ctx)
      addSpanAttribute("output.health", health)
      
      // Get metrics if requested
      const metrics = validatedInput.includeMetrics
        ? await ctx.data.getSystemMetrics()
        : undefined
      
      if (metrics) {
        addSpanAttribute("output.metrics.total_users", metrics.totalUsers)
        addSpanAttribute("output.metrics.active_users", metrics.activeUsers)
      }
      
      // Return validated output
      return GetSystemHealthOutputSchema.parse({
        health,
        status: health > 80 ? "healthy" : health > 50 ? "degraded" : "unhealthy",
        timestamp: new Date().toISOString(),
        metrics,
      })
    })
  },
}
```

#### **Step 3: Structured Logging**

```typescript
// supabase/functions/mcp-server/observability/logging.ts
import { addSpanAttribute } from "./tracing.ts"

export interface LogContext {
  userId?: string
  toolName?: string
  [key: string]: unknown
}

/**
 * Structured logger
 */
export class Logger {
  constructor(private context: LogContext = {}) {}
  
  /**
   * Create child logger with additional context
   */
  child(additionalContext: LogContext): Logger {
    return new Logger({ ...this.context, ...additionalContext })
  }
  
  /**
   * Log info message
   */
  info(message: string, data?: LogContext): void {
    const logData = { ...this.context, ...data, level: "info", message }
    console.log(JSON.stringify(logData))
    
    // Add to span if available
    addSpanAttribute("log.message", message)
    if (data) {
      Object.entries(data).forEach(([key, value]) => {
        addSpanAttribute(`log.${key}`, String(value))
      })
    }
  }
  
  /**
   * Log warning
   */
  warn(message: string, data?: LogContext): void {
    const logData = { ...this.context, ...data, level: "warn", message }
    console.warn(JSON.stringify(logData))
  }
  
  /**
   * Log error
   */
  error(message: string, error?: Error, data?: LogContext): void {
    const logData = {
      ...this.context,
      ...data,
      level: "error",
      message,
      error: error ? {
        message: error.message,
        stack: error.stack,
        name: error.name,
      } : undefined,
    }
    console.error(JSON.stringify(logData))
    
    // Record in span
    if (error) {
      recordException(error)
    }
  }
}

/**
 * Create logger with context
 */
export function createLogger(context: LogContext = {}): Logger {
  return new Logger(context)
}
```

---

## 4️⃣ **POLICY ENFORCEMENT (ACCESS CONTROL)**

### **Pattern: Middleware-Based Access Control**

**DecoCMS Approach:**
- `await ctx.access.check(permission)`
- Policy enforcement in tool handlers
- Clean security model

**SPOTS Implementation:**

#### **Step 1: Tool Execution Wrapper**

```typescript
// supabase/functions/mcp-server/core/tool_executor.ts
import type { MCPContext } from "./context.ts"
import { traceToolExecution } from "../observability/tracing.ts"
import { createLogger } from "../observability/logging.ts"
import { recordException } from "../observability/tracing.ts"

export interface ToolDefinition<TInput = unknown, TOutput = unknown> {
  name: string
  description: string
  inputSchema: Record<string, unknown>
  handler: (input: TInput, ctx: MCPContext) => Promise<TOutput>
  requiredPermission?: string
}

/**
 * Execute tool with full observability and access control
 */
export async function executeTool<TInput, TOutput>(
  tool: ToolDefinition<TInput, TOutput>,
  input: TInput,
  ctx: MCPContext
): Promise<TOutput> {
  const logger = createLogger({
    userId: ctx.userId,
    toolName: tool.name,
  })
  
  const startTime = Date.now()
  
  return traceToolExecution(tool.name, async () => {
    try {
      // Check permission if required
      if (tool.requiredPermission) {
        logger.info("Checking permission", { permission: tool.requiredPermission })
        await ctx.access.require(tool.requiredPermission)
      }
      
      // Execute tool
      logger.info("Executing tool", { input })
      const result = await tool.handler(input, ctx)
      
      // Log success
      const duration = Date.now() - startTime
      await ctx.audit.logToolExecution({
        toolName: tool.name,
        userId: ctx.userId,
        input,
        output: result,
        duration,
      })
      
      logger.info("Tool execution successful", { duration })
      
      return result
    } catch (error) {
      const duration = Date.now() - startTime
      
      // Check if it's a permission error
      if (error instanceof Error && error.message.includes("Permission denied")) {
        await ctx.audit.logAccessDenial({
          userId: ctx.userId,
          permission: tool.requiredPermission || "unknown",
          resource: tool.name,
        })
      }
      
      // Log error
      await ctx.audit.logToolExecution({
        toolName: tool.name,
        userId: ctx.userId,
        input,
        error: error as Error,
        duration,
      })
      
      logger.error("Tool execution failed", error as Error)
      recordException(error as Error)
      
      throw error
    }
  })
}
```

#### **Step 2: Update Tool Definitions**

```typescript
// supabase/functions/mcp-server/tools/admin_tools.ts
import { PERMISSIONS } from "../core/access_control.ts"
import type { ToolDefinition } from "../core/tool_executor.ts"

export const getSystemHealthTool: ToolDefinition<
  z.infer<typeof GetSystemHealthInputSchema>,
  z.infer<typeof GetSystemHealthOutputSchema>
> = {
  name: "get_system_health",
  description: "Get system health metrics and status",
  inputSchema: {
    // ... JSON schema ...
  },
  requiredPermission: PERMISSIONS.ADMIN_VIEW_SYSTEM_HEALTH,
  handler: async (input, ctx) => {
    // Permission is automatically checked by executeTool
    // Just implement the logic
    const validatedInput = GetSystemHealthInputSchema.parse(input)
    const health = await calculateSystemHealth(ctx)
    // ... rest of implementation
  },
}
```

#### **Step 3: Main Server Integration**

```typescript
// supabase/functions/mcp-server/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createMCPContext } from "./core/context.ts"
import { executeTool } from "./core/tool_executor.ts"
import { getSystemHealthTool, searchUsersTool } from "./tools/admin_tools.ts"
import { createLogger } from "./observability/logging.ts"

// Tool registry
const TOOLS: Record<string, ToolDefinition> = {
  [getSystemHealthTool.name]: getSystemHealthTool,
  [searchUsersTool.name]: searchUsersTool,
  // ... more tools
}

serve(async (req) => {
  const logger = createLogger()
  
  try {
    // CORS headers
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    }
    
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders })
    }
    
    // Authenticate user (from Supabase JWT)
    const authHeader = req.headers.get("authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }
    
    // Parse JWT and get user info (simplified - use Supabase auth)
    const userId = await getUserIdFromToken(authHeader)
    const role = await getUserRole(userId)
    
    // Create context
    const ctx = await createMCPContext(userId, role)
    
    // Parse MCP request (JSON-RPC)
    const body = await req.json()
    const { method, params } = body
    
    // Handle MCP protocol methods
    if (method === "tools/list") {
      return new Response(
        JSON.stringify({
          tools: Object.values(TOOLS).map((tool) => ({
            name: tool.name,
            description: tool.description,
            inputSchema: tool.inputSchema,
          })),
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }
    
    if (method === "tools/call") {
      const { name, arguments: toolInput } = params
      const tool = TOOLS[name]
      
      if (!tool) {
        return new Response(
          JSON.stringify({ error: `Tool not found: ${name}` }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        )
      }
      
      // Execute tool with full observability
      const result = await executeTool(tool, toolInput, ctx)
      
      return new Response(
        JSON.stringify({ content: [{ type: "text", text: JSON.stringify(result) }] }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }
    
    return new Response(
      JSON.stringify({ error: "Method not supported" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    logger.error("MCP server error", error as Error)
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
```

---

## 5️⃣ **COMPLETE EXAMPLE: FULL TOOL IMPLEMENTATION**

### **Example: View User Details Tool**

```typescript
// supabase/functions/mcp-server/tools/admin_tools.ts

// Schemas
export const ViewUserDetailsInputSchema = z.object({
  userId: z.string().uuid(),
  includeActivity: z.boolean().optional().default(false),
  includeLists: z.boolean().optional().default(false),
})

export const ViewUserDetailsOutputSchema = z.object({
  user: z.object({
    id: z.string().uuid(),
    email: z.string().email().optional(),
    name: z.string().optional(),
    role: z.enum(["user", "admin", "business", "expert"]),
    verified: z.boolean(),
    createdAt: z.string().datetime(),
    lastActiveAt: z.string().datetime().optional(),
  }),
  activity: z.object({
    totalSpots: z.number().int(),
    totalLists: z.number().int(),
    recentActivity: z.array(z.object({
      type: z.string(),
      timestamp: z.string().datetime(),
    })),
  }).optional(),
  lists: z.array(z.object({
    id: z.string().uuid(),
    name: z.string(),
    spotCount: z.number().int(),
  })).optional(),
})

// Tool definition
export const viewUserDetailsTool: ToolDefinition<
  z.infer<typeof ViewUserDetailsInputSchema>,
  z.infer<typeof ViewUserDetailsOutputSchema>
> = {
  name: "view_user_details",
  description: "View detailed information about a specific user",
  inputSchema: {
    type: "object",
    properties: {
      userId: {
        type: "string",
        format: "uuid",
        description: "User ID to view",
      },
      includeActivity: {
        type: "boolean",
        description: "Include user activity statistics",
        default: false,
      },
      includeLists: {
        type: "boolean",
        description: "Include user's lists",
        default: false,
      },
    },
    required: ["userId"],
  },
  requiredPermission: PERMISSIONS.ADMIN_VIEW_USER_DETAILS,
  handler: async (input, ctx) => {
    // Input is automatically validated
    const validated = ViewUserDetailsInputSchema.parse(input)
    
    // Permission is automatically checked by executeTool
    
    // Get user
    const { data: user, error } = await ctx.data.getUserById(validated.userId)
    if (error) throw error
    if (!user) throw new Error(`User not found: ${validated.userId}`)
    
    // Get activity if requested
    let activity: z.infer<typeof ViewUserDetailsOutputSchema>["activity"]
    if (validated.includeActivity) {
      const { data: spots } = await ctx.supabase
        .from("spots")
        .select("id, created_at")
        .eq("user_id", validated.userId)
      
      const { data: lists } = await ctx.supabase
        .from("lists")
        .select("id, created_at")
        .eq("user_id", validated.userId)
      
      const recentActivity = [
        ...(spots || []).map((s) => ({
          type: "spot_created",
          timestamp: s.created_at,
        })),
        ...(lists || []).map((l) => ({
          type: "list_created",
          timestamp: l.created_at,
        })),
      ]
        .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
        .slice(0, 10)
      
      activity = {
        totalSpots: spots?.length || 0,
        totalLists: lists?.length || 0,
        recentActivity,
      }
    }
    
    // Get lists if requested
    let lists: z.infer<typeof ViewUserDetailsOutputSchema>["lists"]
    if (validated.includeLists) {
      const { data: userLists } = await ctx.supabase
        .from("lists")
        .select("id, name")
        .eq("user_id", validated.userId)
      
      // Get spot counts for each list
      lists = await Promise.all(
        (userLists || []).map(async (list) => {
          const { count } = await ctx.supabase
            .from("list_spots")
            .select("*", { count: "exact", head: true })
            .eq("list_id", list.id)
          
          return {
            id: list.id,
            name: list.name,
            spotCount: count || 0,
          }
        })
      )
    }
    
    // Return validated output
    return ViewUserDetailsOutputSchema.parse({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        verified: user.verified || false,
        createdAt: user.created_at,
        lastActiveAt: user.last_active_at,
      },
      activity,
      lists,
    })
  },
}
```

---

## 6️⃣ **MIGRATION STRATEGY**

### **Step-by-Step Adoption**

#### **Phase 1: Foundation (Days 1-2)**
1. ✅ Set up file structure
2. ✅ Install Zod dependency
3. ✅ Create context interfaces
4. ✅ Implement basic access control

#### **Phase 2: Core Patterns (Days 3-5)**
1. ✅ Implement data access layer
2. ✅ Implement audit logger
3. ✅ Create context factory
4. ✅ Add tool executor wrapper

#### **Phase 3: Observability (Days 6-7)**
1. ✅ Set up OpenTelemetry (optional - can use console for MVP)
2. ✅ Add tracing to tools
3. ✅ Add structured logging

#### **Phase 4: Tool Migration (Days 8-10)**
1. ✅ Migrate existing tools to new pattern
2. ✅ Add Zod schemas
3. ✅ Add permission checks
4. ✅ Add tracing

#### **Phase 5: Testing & Refinement (Days 11-12)**
1. ✅ Test all tools
2. ✅ Verify type safety
3. ✅ Check observability
4. ✅ Refine error handling

---

## 7️⃣ **BENEFITS SUMMARY**

### **Type Safety (Zod)**
- ✅ Runtime validation
- ✅ Type inference
- ✅ Better error messages
- ✅ Prevents bugs early

### **Context Pattern**
- ✅ Clean separation of concerns
- ✅ Testable (mockable dependencies)
- ✅ Reusable across tools
- ✅ Consistent patterns

### **Observability**
- ✅ Distributed tracing
- ✅ Performance monitoring
- ✅ Error tracking
- ✅ Debugging support

### **Policy Enforcement**
- ✅ Centralized access control
- ✅ Audit logging
- ✅ Security by default
- ✅ Clear permission model

---

## 8️⃣ **NEXT STEPS**

1. **Review this guide** with the team
2. **Set up file structure** in `supabase/functions/mcp-server/`
3. **Install dependencies** (Zod, OpenTelemetry)
4. **Implement core patterns** (context, access control)
5. **Migrate first tool** as proof of concept
6. **Iterate and refine** based on experience

---

## 📚 **REFERENCES**

- **DecoCMS Evaluation:** [`DECOCMS_EVALUATION.md`](./DECOCMS_EVALUATION.md)
- **Zod Documentation:** https://zod.dev
- **OpenTelemetry:** https://opentelemetry.io
- **MCP Specification:** SEP-1865
- **Supabase Edge Functions:** https://supabase.com/docs/guides/functions

---

**Status:** Ready for implementation  
**Timeline Impact:** +2-5 days (for pattern adoption)  
**Risk:** Low (patterns, not full framework)  
**Value:** High (better quality, maintainability, observability)

