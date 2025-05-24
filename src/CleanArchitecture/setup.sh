#!/usr/bin/env bash

# Clean Architecture .NET Solution Generator with optional TDD (--with-test)
# Supports src/test structure, .gitignore, NuGet install
# Compatible with MacOS/Linux (Bash <4)

if [ -z "$1" ]; then
  echo "❌ You must provide a solution name!"
  echo "👉 Example: ./setup.sh MyProject [--with-test]"
  exit 1
fi

SOLUTION_NAME=$1
WITH_TEST=false

if [ "$2" == "--with-test" ]; then
  WITH_TEST=true
fi

SRC_DIR="src"
TEST_DIR="test"

PROJECTS=(
  "$SOLUTION_NAME.Domain"
  "$SOLUTION_NAME.Application"
  "$SOLUTION_NAME.Infrastructure"
  "$SOLUTION_NAME.API"
  "$SOLUTION_NAME.Shared"
)

TEST_PROJECTS=(
  "$SOLUTION_NAME.Domain.UnitTests"
  "$SOLUTION_NAME.Application.UnitTests"
  "$SOLUTION_NAME.Infrastructure.UnitTests"
)

echo "📂 Creating root structure: $SOLUTION_NAME/{src,test}"
mkdir -p "$SOLUTION_NAME/$SRC_DIR"
mkdir -p "$SOLUTION_NAME/$TEST_DIR"
cd "$SOLUTION_NAME" || exit

# Create .gitignore
echo "📝 Creating .gitignore"
cat > .gitignore <<EOL
bin/
obj/
*.user
*.suo
*.log
*.vs/
.vscode/
.env
.env.*
TestResults/
coverage/
*.coverage
.gitkeep
appsettings*.json

EOL

# Create solution
echo "🛠️ Creating solution: $SOLUTION_NAME.sln"
dotnet new sln -n "$SOLUTION_NAME"

# Create src projects
for project in "${PROJECTS[@]}"; do
  PROJECT_PATH="$SRC_DIR/$project"
  if [[ "$project" == *".API" ]]; then
    echo "📦 Creating WebAPI project: $project"
    dotnet new webapi -n "$project" -o "$PROJECT_PATH"
  else
    echo "📦 Creating classlib project: $project"
    dotnet new classlib -n "$project" -o "$PROJECT_PATH"
  fi
  echo "➕ Adding $project to solution"
  dotnet sln add "$PROJECT_PATH/$project.csproj"
done

# Create test projects only if --with-test
if [ "$WITH_TEST" = true ]; then
  for testproject in "${TEST_PROJECTS[@]}"; do
    TEST_PATH="$TEST_DIR/$testproject"
    echo "🧪 Creating unit test project: $testproject"
    dotnet new xunit -n "$testproject" -o "$TEST_PATH"
    echo "➕ Adding $testproject to solution"
    dotnet sln add "$TEST_PATH/$testproject.csproj"
  done
fi

# Add references
echo "🔗 Adding project references..."

function add_refs() {
  from="$SRC_DIR/$1"
  shift
  cd "$from" || exit
  for ref in "$@"; do
    dotnet add reference "../../$SRC_DIR/$ref/$ref.csproj"
  done
  cd - > /dev/null
}

function add_test_refs() {
  from="$TEST_DIR/$1"
  ref="$SRC_DIR/$2"
  echo "🔗 $1 --> $2"
  cd "$from" || exit
  dotnet add reference "../../$ref/$2.csproj"
  cd - > /dev/null
}

add_refs "$SOLUTION_NAME.Application" "$SOLUTION_NAME.Domain" "$SOLUTION_NAME.Infrastructure" "$SOLUTION_NAME.Shared"
add_refs "$SOLUTION_NAME.Infrastructure" "$SOLUTION_NAME.Domain" "$SOLUTION_NAME.Shared"
add_refs "$SOLUTION_NAME.API" "$SOLUTION_NAME.Domain" "$SOLUTION_NAME.Application" "$SOLUTION_NAME.Infrastructure"
add_refs "$SOLUTION_NAME.Shared" 

if [ "$WITH_TEST" = true ]; then
  add_test_refs "$SOLUTION_NAME.Domain.UnitTests" "$SOLUTION_NAME.Domain"
  add_test_refs "$SOLUTION_NAME.Application.UnitTests" "$SOLUTION_NAME.Application"
  add_test_refs "$SOLUTION_NAME.Infrastructure.UnitTests" "$SOLUTION_NAME.Infrastructure"
fi

# Install NuGet packages
echo "📦 Installing NuGet packages..."

function add_packages() {
  proj="$SRC_DIR/$1"
  shift
  echo "📥 Installing packages for $proj"
  cd "$proj" || exit
  for pkg in "$@"; do
    dotnet add package "$pkg"
  done
  cd - > /dev/null
}

function add_test_packages() {
  proj="$TEST_DIR/$1"
  shift
  echo "📥 Installing test packages for $proj"
  cd "$proj" || exit
  for pkg in "$@"; do
    dotnet add package "$pkg"
  done
  cd - > /dev/null
}

add_packages "$SOLUTION_NAME.Domain" Moclawr.Core Moclawr.Domain Moclawr.Shared
add_packages "$SOLUTION_NAME.Application" Moclawr.Core Moclawr.Services Moclawr.Services.Caching Moclawr.Shared
add_packages "$SOLUTION_NAME.Infrastructure" Moclawr.Core Moclawr.EfCore Moclawr.MongoDb Moclawr.Shared Moclawr.DotNetCore.Cap Moclawr.Services.External Serilog Microsoft.EntityFrameworkCore.Design Microsoft.EntityFrameworkCore.Tools
add_packages "$SOLUTION_NAME.API" Moclawr.Core Moclawr.Shared Moclawr.MinimalAPI Moclawr.Host Serilog Microsoft.EntityFrameworkCore.Design Microsoft.EntityFrameworkCore.Tools
add_packages "$SOLUTION_NAME.Shared" Moclawr.Shared

if [ "$WITH_TEST" = true ]; then
  add_test_packages "$SOLUTION_NAME.Domain.UnitTests" xunit FluentAssertions Moq
  add_test_packages "$SOLUTION_NAME.Application.UnitTests" xunit FluentAssertions Moq
  add_test_packages "$SOLUTION_NAME.Infrastructure.UnitTests" xunit FluentAssertions Moq
fi

# Create folder structures and add .gitkeep
echo "📁 Creating folders for Clean Architecture"

function create_folders() {
  proj="$SRC_DIR/$1"
  shift
  echo "📁 Creating folders in $proj:"
  for folder in "$@"; do
    mkdir -p "$proj/$folder"
    touch "$proj/$folder/.gitkeep"
  done
}

# Function to remove .gitkeep from non-empty folders
function remove_gitkeep_from_nonempty_folders() {
  base_dir="$1"
  echo "🧹 Removing .gitkeep files from non-empty folders..."
  find "$base_dir" -type f -name ".gitkeep" | while read gitkeep_file; do
    dir_path=$(dirname "$gitkeep_file")
    # Count other files in the directory
    other_files=$(find "$dir_path" -type f -not -name ".gitkeep" | wc -l)
    if [ "$other_files" -gt 0 ]; then
      rm -f "$gitkeep_file"
      echo "  Removed .gitkeep from: $dir_path"
    fi
  done
}

create_folders "$SOLUTION_NAME.Domain" Entities ValueObjects Repositories Aggregates DomainEvents Specifications Constants
create_folders "$SOLUTION_NAME.Application" DTOs Interfaces Services Commands Queries Validators
create_folders "$SOLUTION_NAME.Infrastructure" "Persistence/EfCore" "Persistence/EfCore/Configurations" ExternalServices Repositories
create_folders "$SOLUTION_NAME.API" Endpoints Filters Middleware
create_folders "$SOLUTION_NAME.Shared" SharedKernel

# Extract template files
echo "📦 Loading template files from templates directory..."
TEMPLATE_DIR="$(dirname "$0")/templates"

# Create GlobalUsings.cs in the Shared project first
GLOBAL_USINGS_PATH="$SRC_DIR/$SOLUTION_NAME.Shared/GlobalUsings.cs"
TEMPLATE_PATH="$TEMPLATE_DIR/GlobalUsings.cs"
if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$GLOBAL_USINGS_PATH"
else
  cat > "$GLOBAL_USINGS_PATH" << EOL
// filepath: $GLOBAL_USINGS_PATH
global using Shared.Responses;
EOL
fi

# Create Service.Register.cs for Application
APP_SERVICE_REGISTER_PATH="$SRC_DIR/$SOLUTION_NAME.Application/Service.Register.cs"
TEMPLATE_PATH="$TEMPLATE_DIR/Application.Service.Register.cs"
if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$APP_SERVICE_REGISTER_PATH"
else
  cat > "$APP_SERVICE_REGISTER_PATH" << EOL
// filepath: $APP_SERVICE_REGISTER_PATH
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace $SOLUTION_NAME.Application
{
    public static partial class Register
    {
        public static IServiceCollection AddApplicationServices(
            this IServiceCollection services,
            IConfiguration configuration
        )
        {
            return services;
        }
    }
}
EOL
fi

# Create Service.Register.cs for Infrastructure
INFRA_SERVICE_REGISTER_PATH="$SRC_DIR/$SOLUTION_NAME.Infrastructure/Service.Register.cs"
TEMPLATE_PATH="$TEMPLATE_DIR/Infrastructure.Service.Register.cs"
if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$INFRA_SERVICE_REGISTER_PATH"
else
  cat > "$INFRA_SERVICE_REGISTER_PATH" << EOL
// filepath: $INFRA_SERVICE_REGISTER_PATH
using DotnetCap;
using EfCore.IRepositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using $SOLUTION_NAME.Domain.Constants;
using $SOLUTION_NAME.Infrastructure.Persistence.EfCore;
using $SOLUTION_NAME.Infrastructure.Repositories;

namespace $SOLUTION_NAME.Infrastructure
{
    public static partial class Register
    {
        public static IServiceCollection AddInfrastructureServices(
            this IServiceCollection services,
            IConfiguration configuration
        )
        {
            // Register DbContext
            # services.AddDbContext<ApplicationDbContext>(options =>
            #     options.UseSqlite(configuration.GetConnectionString("DefaultConnection")));

            services.AddDotnetCap(configuration).AddRabbitMq(configuration);

            services.AddKeyedScoped<ICommandRepository, CommandDefaultRepository>(
                ServiceKeys.CommandRepository
            );
            services.TryAddKeyedScoped(
                typeof(IQueryRepository<,>),
                ServiceKeys.QueryRepository,
                typeof(QueryDefaultRepository<,>)
            );

            return services;
        }
    }
}
EOL
fi

# Create Program.cs for API
PROGRAM_PATH="$SRC_DIR/$SOLUTION_NAME.API/Program.cs"
TEMPLATE_PATH="$TEMPLATE_DIR/Program.cs"
if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$PROGRAM_PATH"
else
  cat > "$PROGRAM_PATH" << EOL
// filepath: $PROGRAM_PATH
using Host;
using Host.Services;
using MinimalAPI;
using $SOLUTION_NAME.Application;
using $SOLUTION_NAME.Infrastructure;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

var appName = builder.Environment.ApplicationName;
var configuration = builder.Configuration;

// Configure Serilog
builder.AddSerilog(configuration, appName);

// Register other services
builder
    .Services.AddCorsServices(configuration)
    .AddMinimalApi(
        typeof(Program).Assembly,
        typeof($SOLUTION_NAME.Application.Register).Assembly,
        typeof($SOLUTION_NAME.Infrastructure.Register).Assembly
    )
    .AddGlobalExceptionHandling(appName)
    .AddHealthCheck(configuration)
    // Register Infrastructure and Application services
    .AddInfrastructureServices(configuration)
    .AddApplicationServices(configuration)
    // Register OpenAPI/Swagger
    .AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

// Configure CORS
app.UseCorsServices(configuration);

// Configure Global Exception Handling
app.UseGlobalExceptionHandling();

// Configure ARM Elastic
app.UseElasticApm(configuration);

app.UseRouting();

// Configure Health Check
app.UseHealthChecks(configuration);

// Map all endpoints from the assembly
app.MapMinimalEndpoints(typeof(Program).Assembly);

await app.RunAsync();
EOL

# Create GlobalUsings.cs in API
API_GLOBAL_USINGS="$SRC_DIR/$SOLUTION_NAME.API/GlobalUsings.cs"
cat > "$API_GLOBAL_USINGS" << EOL
// filepath: $API_GLOBAL_USINGS
global using Shared.Responses;
EOL

# Create ApplicationDbContext.cs
DB_CONTEXT_DIR="$SRC_DIR/$SOLUTION_NAME.Infrastructure/Persistence/EfCore"
DB_CONTEXT_PATH="$DB_CONTEXT_DIR/ApplicationDbContext.cs"
mkdir -p "$DB_CONTEXT_DIR"
TEMPLATE_PATH="$TEMPLATE_DIR/ApplicationDbContext.cs"

if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$DB_CONTEXT_PATH"
else
  cat > "$DB_CONTEXT_PATH" << EOL
// filepath: $DB_CONTEXT_PATH
using EfCore;
using Microsoft.EntityFrameworkCore;
using $SOLUTION_NAME.Infrastructure.Persistence.EfCore.Configurations;
using System.Reflection;

namespace $SOLUTION_NAME.Infrastructure.Persistence.EfCore
{
    public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : BaseDbContext(options)
    {
        protected override Assembly ExecutingAssembly => typeof(ApplicationDbContext).Assembly;

        protected override Func<Type, bool> RegisterConfigurationsPredicate =>
            t => t.Namespace == typeof(ConfigurationFilter).Namespace;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
        }
    }
}
EOL

# Create ConfigurationFilter.cs
CONFIG_DIR="$SRC_DIR/$SOLUTION_NAME.Infrastructure/Persistence/EfCore/Configurations"
CONFIG_PATH="$CONFIG_DIR/ConfigurationFilter.cs"
mkdir -p "$CONFIG_DIR"
TEMPLATE_PATH="$TEMPLATE_DIR/ConfigurationFilter.cs"

if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$CONFIG_PATH"
else
  cat > "$CONFIG_PATH" << EOL
// filepath: $CONFIG_PATH
namespace $SOLUTION_NAME.Infrastructure.Persistence.EfCore.Configurations
{
    internal class ConfigurationFilter
    {
    }
    }
}
EOL

# Create CommandDefaultRepository.cs
REPO_DIR="$SRC_DIR/$SOLUTION_NAME.Infrastructure/Repositories"
COMMAND_REPO_PATH="$REPO_DIR/CommandDefaultRepository.cs"
mkdir -p "$REPO_DIR"
TEMPLATE_PATH="$TEMPLATE_DIR/CommandDefaultRepository.cs"

if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$COMMAND_REPO_PATH"
else
  cat > "$COMMAND_REPO_PATH" << EOL
// filepath: $COMMAND_REPO_PATH
using EfCore.Repositories;
using Microsoft.Extensions.Logging;
using $SOLUTION_NAME.Infrastructure.Persistence.EfCore;

namespace $SOLUTION_NAME.Infrastructure.Repositories;

public class CommandDefaultRepository(ApplicationDbContext dbContext, ILogger<CommandDefaultRepository> logger)
    : CommandRepository(dbContext, logger)
{ }
EOL

# Create QueryDefaultRepository.cs
QUERY_REPO_PATH="$REPO_DIR/QueryDefaultRepository.cs"
TEMPLATE_PATH="$TEMPLATE_DIR/QueryDefaultRepository.cs"

if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$QUERY_REPO_PATH"
else
  cat > "$QUERY_REPO_PATH" << EOL
// filepath: $QUERY_REPO_PATH
using EfCore.Repositories;
using $SOLUTION_NAME.Infrastructure.Persistence.EfCore;
using Shared.Entities;

namespace $SOLUTION_NAME.Infrastructure.Repositories;
public class QueryDefaultRepository<TEntity, TKey>(ApplicationDbContext dbContext)
    : QueryRepository<TEntity, TKey>(dbContext)
    where TEntity : class, IEntity<TKey>
    where TKey : IEquatable<TKey>
{
}
}
EOL

# Create domain constants folder and ServiceKeys class
CONSTANTS_DIR="$SRC_DIR/$SOLUTION_NAME.Domain/Constants"
SERVICE_KEYS_PATH="$CONSTANTS_DIR/ServiceKeys.cs"
mkdir -p "$CONSTANTS_DIR"
TEMPLATE_PATH="$TEMPLATE_DIR/ServiceKeys.cs"

if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$SERVICE_KEYS_PATH"
else
  cat > "$SERVICE_KEYS_PATH" << EOL
// filepath: $SERVICE_KEYS_PATH
namespace $SOLUTION_NAME.Domain.Constants;

public static class ServiceKeys
{
    public const string CommandRepository = "CommandRepository";
    public const string QueryRepository = "QueryRepository";
}
EOL

# Create GlobalUsings.cs for Domain
DOMAIN_GLOBAL_USINGS="$SRC_DIR/$SOLUTION_NAME.Domain/GlobalUsings.cs"
cat > "$DOMAIN_GLOBAL_USINGS" << EOL
// filepath: $DOMAIN_GLOBAL_USINGS
global using Shared.Responses;
EOL

# Create GlobalUsings.cs for Infrastructure
INFRA_GLOBAL_USINGS="$SRC_DIR/$SOLUTION_NAME.Infrastructure/GlobalUsings.cs"
cat > "$INFRA_GLOBAL_USINGS" << EOL
// filepath: $INFRA_GLOBAL_USINGS
global using Shared.Responses;
EOL

# Create appsettings.Development.json
APP_SETTINGS_DEV_PATH="$SRC_DIR/$SOLUTION_NAME.API/appsettings.Development.json"
TEMPLATE_PATH="$TEMPLATE_DIR/appsettings.Development.json"

if [ -f "$TEMPLATE_PATH" ]; then
  cat "$TEMPLATE_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$APP_SETTINGS_DEV_PATH"
else
  cat > "$APP_SETTINGS_DEV_PATH" << EOL
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },

  "AllowedHosts": "*",

  "ConnectionStrings": {
    "DefaultConnection": "Data Source=todo.db;"
  },

  "CorsSettings": {
    "IsAllowLocalhost": true,
    "DefaultPolicy": "DefaultPolicyName",
    "Policies": [
      {
        "Name": "Policy1",
        "AllowAnyOrigin": false,
        "AllowedOrigins": [ "https://example.com", "https://anotherdomain.com" ],
        "AllowAnyMethod": false,
        "AllowedMethods": [ "GET", "POST" ],
        "AllowAnyHeader": false,
        "AllowedHeaders": [ "Content-Type", "Authorization" ]
      },
      {
        "Name": "Policy2",
        "AllowAnyOrigin": true,
        "AllowAnyMethod": true,
        "AllowAnyHeader": true
      }
    ],
    "EnablePreflightRequests": true
  },
  "Serilog": {
    "Using": [
      "Serilog.Sinks.Async",
      "Serilog.Sinks.File",
      "Serilog.Sinks.Console",
      "Serilog.Sinks.Elasticsearch"
    ],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning"
      }
    },
    "Enrich": [ "FromLogContext", "WithMachineName", "WithProcessId", "WithThreadId" ],
    "WriteTo": [
      {
        "Name": "Async",
        "Args": {
          "configure": [
            {
              "Name": "Console"
            },
            {
              "Name": "File",
              "Args": {
                "path": "Logs/.log",
                "rollingInterval": "Hour",
                "encoding": "System.Text.Encoding::UTF8"
              }
            },
            {
              "Name": "File",
              "Args": {
                "path": "Logs/.json",
                "rollingInterval": "Hour",
                "formatter": "Serilog.Formatting.Json.JsonFormatter, Serilog"
              }
            },
            {
              "Name": "Elasticsearch",              "Args": {
                "nodeUris": "http://localhost:9200",
                "connectionGlobalHeaders": "Authorization=Basic ZWxhc3RpYzpjaGFuZ2VtZQ==",
                "indexFormat": "log-dev-$SOLUTION_NAME-{0:yyyy.MM.dd}",
                "autoRegisterTemplate": true,
                "autoRegisterTemplateVersion": "ESv8"
              }
            }
          ]
        }
      }
    ]
  },

  "HealthCheckSettings": {
    "Url": "http://localhost:5000/health",
    "Interval": 30,
    "Timeout": 10,
    "FailureThreshold": 3,
    "SuccessThreshold": 1,
    "EnableDatabaseCheck": true
  },

  "ElasticApm": {
    "ServiceName": "my-service-name",
    "SecretToken": "",
    "ServerUrl": "http://localhost:8200",
    "Environment": "my-environment",
    "CaptureBody": "all",
    "LogLevel": "Trace"
  },
  "DotnetCap": {
    "ConnectionString": "mongodb://localhost:27017/$SOLUTION_NAME",
    "DbProvider": "MongoDB",
    "UseTransaction": true,

    "UseDashboard": true,
    "DashboardPath": "/cap-dashboard",
    "DashboardUser": "admin",
    "DashboardPassword": "admin",

    "FailedRetryCount": 5,
    "FailedRetryInterval": 60,
    "SucceedMessageExpiredAfter": 86400,

    "RabbitMQ": {
      "HostName": "localhost",
      "Port": 5672,
      "UserName": "username",
      "Password": "password",
      "VirtualHost": "/",
      "ExchangeName": "cap.default.router",
      "PublishConfirms": true,
      "QueueArguments": {
        "QueueMode": "default",
        "MessageTTL": 864000000,
        "QueueType": "classic"
      },
      "QueueOptions": {
        "Durable": true,
        "Exclusive": false,
        "AutoDelete": false
      },
      "BasicQosOptions": {
        "PrefetchCount": 10,
        "Global": false
      }
    }
  },
  "SmtpOptions": {
    "Host": "smtp.example.com",
    "Port": 587,
    "UserName": "user@example.com",
    "Password": "yourSmtpPassword",
    "EnableSsl": true,
    "UseDefaultCredentials": false,
    "FromEmail": "noreply@example.com",
    "FromName": "Example App"
  },
  "SmsOptions": {
    "ApiKey": "your-sms-api-key",
    "ApiSecret": "your-sms-api-secret",
    "SenderId": "ExampleSender",
    "BaseUrl": "https://api.smsprovider.com",
    "Timeout": 30,
    "UseDefaultCredentials": false
  }
}
EOL

# Remove all default Class1.cs files from the generated projects
find "$SRC_DIR" -name 'Class1.cs' -type f -delete
echo "🗑️ Removed all default Class1.cs files"

# Remove .gitkeep from non-empty folders
remove_gitkeep_from_nonempty_folders "$SOLUTION_NAME/$SRC_DIR"

# Copy and customize feature scripts to root directory
echo "📄 Creating feature generation scripts in project root..."

# Copy PowerShell feature script for Windows users
FEATURE_PS_PATH="$TEMPLATE_DIR/feature.ps1"
FEATURE_PS_TARGET="feature.ps1"

if [ -f "$FEATURE_PS_PATH" ]; then
  cat "$FEATURE_PS_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$FEATURE_PS_TARGET"
  echo "✅ PowerShell feature script added to project root: $FEATURE_PS_TARGET"
else
  echo "⚠️ PowerShell feature script template not found. Skipping."
fi

# Copy Bash feature script for macOS/Linux users
FEATURE_SH_PATH="$TEMPLATE_DIR/feature.sh"
FEATURE_SH_TARGET="feature.sh"

if [ -f "$FEATURE_SH_PATH" ]; then
  cat "$FEATURE_SH_PATH" | sed "s/Sample\./$SOLUTION_NAME./g; s/sample\./$SOLUTION_NAME./g; s/\bSample\b/$SOLUTION_NAME/g; s/\bsample\b/$SOLUTION_NAME/g" > "$FEATURE_SH_TARGET"
  chmod +x "$FEATURE_SH_TARGET"  # Make the script executable
  echo "✅ Bash feature script added to project root: $FEATURE_SH_TARGET"
else
  echo "⚠️ Bash feature script template not found. Skipping."
fi

# Set API layer as startup project
echo "🚀 Setting $SOLUTION_NAME.API as startup project..."
VS_DIR=".vs"
VS_CONFIG_DIR="$VS_DIR/$SOLUTION_NAME/config"
mkdir -p "$VS_CONFIG_DIR"

# Create startup.json file
STARTUP_JSON="$VS_CONFIG_DIR/startup.json"
cat > "$STARTUP_JSON" << EOL
{
  "profiles": [
    {
      "name": "$SOLUTION_NAME.API",
      "startupProject": "$SRC_DIR/$SOLUTION_NAME.API/$SOLUTION_NAME.API.csproj"
    }
  ]
}
EOL

echo "✅ Done! Clean Architecture solution '$SOLUTION_NAME' is ready."
if [ "$WITH_TEST" = true ]; then
  echo "🧪 Unit test projects created with xUnit, Moq, and FluentAssertions."
else
  echo "ℹ️  Run with '--with-test' to generate unit test projects."
fi