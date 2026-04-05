# Supabase MCP Server Access

## ✅ Available MCP Functions

You have access to Supabase MCP servers with the following capabilities:

### Project Management
- `mcp_Supabase_list_projects` - List all Supabase projects
- `mcp_Supabase_get_project` - Get project details
- `mcp_Supabase_get_project_url` - Get API URL for a project
- `mcp_Supabase_get_publishable_keys` - Get publishable API keys

### Database Operations
- `mcp_Supabase_list_tables` - List all tables in schemas
- `mcp_Supabase_list_extensions` - List database extensions
- `mcp_Supabase_list_migrations` - List all migrations
- `mcp_Supabase_apply_migration` - Apply a migration (DDL operations)
- `mcp_Supabase_execute_sql` - Execute raw SQL (DML operations)

### Edge Functions
- `mcp_Supabase_list_edge_functions` - List all Edge Functions
- `mcp_Supabase_get_edge_function` - Get Edge Function contents
- `mcp_Supabase_deploy_edge_function` - Deploy an Edge Function

### Monitoring & Debugging
- `mcp_Supabase_get_logs` - Get logs by service type
- `mcp_Supabase_get_advisors` - Get security/performance advisors

### Development Branches
- `mcp_Supabase_list_branches` - List development branches
- `mcp_Supabase_create_branch` - Create a development branch
- `mcp_Supabase_merge_branch` - Merge branch to production
- `mcp_Supabase_reset_branch` - Reset branch migrations
- `mcp_Supabase_rebase_branch` - Rebase branch on production

## 📋 Current Projects

### Active Project: `nfzlwgbvezwwrutqpedy` (SPOTS_)
- **Status**: ACTIVE_HEALTHY
- **Region**: us-west-2 (West US - Oregon)
- **Database**: PostgreSQL 17.6.1.052
- **Created**: 2025-11-18
- **URL**: `https://nfzlwgbvezwwrutqpedy.supabase.co`

### Inactive Project: `dsttvxuislebwriaprmt` (SPOTS)
- **Status**: INACTIVE
- **Region**: us-east-1 (East US - North Virginia)
- **Database**: PostgreSQL 17.4.1.069
- **Created**: 2025-08-07

## 🔧 Configuration

The app is configured to use the active project (`nfzlwgbvezwwrutqpedy`) via:
- **VS Code Launch Config**: `.vscode/launch.json`
- **Runtime Config**: `lib/supabase_config.dart` (reads from `--dart-define` flags)

## 🚀 Usage Examples

### Check Project Status
```dart
// Via MCP (in AI assistant)
mcp_Supabase_get_project(id: 'nfzlwgbvezwwrutqpedy')
```

### List Tables
```dart
mcp_Supabase_list_tables(project_id: 'nfzlwgbvezwwrutqpedy')
```

### Get Logs
```dart
mcp_Supabase_get_logs(project_id: 'nfzlwgbvezwwrutqpedy', service: 'api')
```

### Check Advisors (Security/Performance)
```dart
mcp_Supabase_get_advisors(project_id: 'nfzlwgbvezwwrutqpedy', type: 'security')
```

## 📝 Notes

- MCP servers provide programmatic access to Supabase without needing the CLI
- Useful for automated testing, monitoring, and deployment workflows
- All operations respect Supabase project permissions and rate limits
