param(
  [Parameter(Mandatory = $true)]
  [string]$SolutionName,

  [switch]$WithTest
)

# Define directories
$srcDir = 'src'
$testDir = 'test'

# Projects
$projects = @(
  "$SolutionName.Domain",
  "$SolutionName.Application",
  "$SolutionName.Infrastructure",
  "$SolutionName.API",
  "$SolutionName.Shared"
)

# Test projects
$testProjects = @(
  "$SolutionName.Domain.UnitTests",
  "$SolutionName.Application.UnitTests",
  "$SolutionName.Infrastructure.UnitTests"
)

# Create root structure
Write-Host "Creating solution folders: $SolutionName/{src, test}" -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$SolutionName/$srcDir" -Force | Out-Null
New-Item -ItemType Directory -Path "$SolutionName/$testDir" -Force | Out-Null
Set-Location $SolutionName

# Generate .gitignore
Write-Host "Generating .gitignore" -ForegroundColor Cyan
@"
bin/
obj/
*.user
*.suo
*.log
.vs/
.vscode/
.env
.env.*
TestResults/
coverage/
*.coverage
.gitkeep
appsettings*.json
"@ | Set-Content '.gitignore'

# Initialize solution file
Write-Host "Initializing solution: $SolutionName.sln" -ForegroundColor Cyan
dotnet new sln -n $SolutionName

# Create each project
foreach ($proj in $projects) {
  $projPath = "$srcDir/$proj"
  if ($proj -like '*.API') {
    Write-Host "Creating WebAPI project: $proj" -ForegroundColor Yellow
    dotnet new webapi -n $proj -o $projPath
  }
  else {
    Write-Host "Creating class library: $proj" -ForegroundColor Yellow
    dotnet new classlib -n $proj -o $projPath
  }
  Write-Host "Adding $proj to solution" -ForegroundColor Green
  dotnet sln add "$projPath/$proj.csproj"
}

# Create test projects if requested
if ($WithTest) {
  foreach ($testProj in $testProjects) {
    $testPath = "$testDir/$testProj"
    Write-Host "Creating test project: $testProj" -ForegroundColor Yellow
    dotnet new xunit -n $testProj -o $testPath
    Write-Host "Adding $testProj to solution" -ForegroundColor Green
    dotnet sln add "$testPath/$testProj.csproj"
  }
}

# Define helper functions for references
function Add-Refs($fromProj, $refs) {
  Set-Location "$srcDir/$fromProj"
  foreach ($r in $refs) {
    dotnet add reference "../../$srcDir/$r/$r.csproj"
  }
  Set-Location ../..
}

function Add-TestRefs($fromTestProj, $refProj) {
  Set-Location "$testDir/$fromTestProj"
  dotnet add reference "../../$srcDir/$refProj/$refProj.csproj"
  Set-Location ../..
}

# Configure project references
Add-Refs "$SolutionName.Application"    @("$SolutionName.Domain", "$SolutionName.Infrastructure" , "$SolutionName.Shared")
Add-Refs "$SolutionName.Infrastructure" @("$SolutionName.Domain", "$SolutionName.Shared")
Add-Refs "$SolutionName.API"            @("$SolutionName.Domain", "$SolutionName.Application", "$SolutionName.Infrastructure")
Add-Refs "$SolutionName.Shared"         @()

if ($WithTest) {
  Add-TestRefs "$SolutionName.Domain.UnitTests"        "$SolutionName.Domain"
  Add-TestRefs "$SolutionName.Application.UnitTests"   "$SolutionName.Application"
  Add-TestRefs "$SolutionName.Infrastructure.UnitTests" "$SolutionName.Infrastructure"
}

# Define helper functions for NuGet packages
function Add-Packages($projPath, $packages) {
  Set-Location "$srcDir/$projPath"
  foreach ($pkg in $packages) {
    dotnet add package $pkg
  }
  Set-Location ../..
}

function Add-TestPackages($testPath, $packages) {
  Set-Location "$testDir/$testPath"
  foreach ($pkg in $packages) {
    dotnet add package $pkg
  }
  Set-Location ../..
}

# Install NuGet packages
Write-Host "Installing NuGet packages..." -ForegroundColor Cyan
Add-Packages "$SolutionName.Domain"        @("Moclawr.Core", "Moclawr.Domain", "Moclawr.Shared")
Add-Packages "$SolutionName.Application"   @("Moclawr.Core", "Moclawr.Services", "Moclawr.Services.Caching", "Moclawr.Shared")
Add-Packages "$SolutionName.Infrastructure" @("Moclawr.Core", "Moclawr.EfCore", "Moclawr.MongoDb", "Moclawr.Shared", "Moclawr.DotNetCore.Cap", "Moclawr.Services.External", "Serilog")
Add-Packages "$SolutionName.API"           @("Moclawr.Core", "Moclawr.Shared", "Moclawr.MinimalAPI", "Moclawr.Host", "Serilog")
Add-Packages "$SolutionName.Shared"        @("Moclawr.Shared")

if ($WithTest) {
  Add-TestPackages "$SolutionName.Domain.UnitTests"        @("xunit", "FluentAssertions", "Moq")
  Add-TestPackages "$SolutionName.Application.UnitTests"   @("xunit", "FluentAssertions", "Moq")
  Add-TestPackages "$SolutionName.Infrastructure.UnitTests" @("xunit", "FluentAssertions", "Moq")
}

# Create Clean Architecture folders
function New-Folders($proj, $folders) {
  foreach ($f in $folders) {
    $path = "$srcDir/$proj/$f"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    New-Item -ItemType File -Path "$path/.gitkeep" -Force | Out-Null
  }
}

# Function to remove .gitkeep files from non-empty folders
function Remove-GitKeepFromNonEmptyFolders($baseDir) {
  $folders = Get-ChildItem -Path $baseDir -Recurse -Directory
  foreach ($folder in $folders) {
    $gitkeepPath = Join-Path $folder.FullName ".gitkeep"
    if (Test-Path $gitkeepPath) {
      $otherFiles = Get-ChildItem -Path $folder.FullName -File | Where-Object { $_.Name -ne ".gitkeep" }
      if ($otherFiles.Count -gt 0) {
        Remove-Item $gitkeepPath -Force
        Write-Host "Removed .gitkeep from non-empty folder: $($folder.FullName)" -ForegroundColor Gray
      }
    }
  }
}

Write-Host "Creating Clean Architecture folders..." -ForegroundColor Cyan
New-Folders "$SolutionName.Domain"       @("Entities", "ValueObjects", "Repositories", "Aggregates", "DomainEvents", "Specifications", "Constants")
New-Folders "$SolutionName.Application"  @("DTOs", "Interfaces", "Services", "Commands", "Queries", "Validators")
New-Folders "$SolutionName.Infrastructure" @("Persistence/EfCore", "Persistence/EfCore/Configurations", "ExternalServices", "Repositories")
New-Folders "$SolutionName.API"          @("Endpoints", "Filters", "Middleware")
New-Folders "$SolutionName.Shared"       @("SharedKernel")

# Extract template files
Write-Host "Loading template files from templates directory..." -ForegroundColor Cyan
$templateDir = Join-Path $PSScriptRoot 'templates'

# Create template files with correct content
# Create GlobalUsings.cs in the Shared project first
$globalUsingsPath = "$srcDir/$SolutionName.Shared/GlobalUsings.cs"
$templatePath = Join-Path $templateDir "GlobalUsings.cs"
if (Test-Path $templatePath) {
  $content = Get-Content $templatePath -Raw
  $updated = $content -replace 'Sample\.', "$SolutionName." -replace 'sample\.', "$SolutionName." -replace '\bSample\b', "$SolutionName" -replace '\bsample\b', "$SolutionName"
  Set-Content -Path $globalUsingsPath -Value $updated -NoNewline
}
else {
  @"
// filepath: $globalUsingsPath
global using Shared.Responses;
"@ | Set-Content $globalUsingsPath
}

# Create Service.Register.cs for Application
$appServiceRegisterPath = "$srcDir/$SolutionName.Application/Service.Register.cs"
$templatePath = Join-Path $templateDir "Application.Service.Register.cs"
if (Test-Path $templatePath) {
  $content = Get-Content $templatePath -Raw
  $updated = $content -replace 'Sample\.', "$SolutionName." -replace 'sample\.', "$SolutionName." -replace '\bSample\b', "$SolutionName" -replace '\bsample\b', "$SolutionName"
  Set-Content -Path $appServiceRegisterPath -Value $updated -NoNewline
}
else {
  @"
// filepath: $appServiceRegisterPath
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace $SolutionName.Application
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

"@ | Set-Content $appServiceRegisterPath
}

# Create Service.Register.cs for Infrastructure
$infraServiceRegisterPath = "$srcDir/$SolutionName.Infrastructure/Service.Register.cs"
$templatePath = Join-Path $templateDir "Infrastructure.Service.Register.cs"
if (Test-Path $templatePath) {
  $content = Get-Content $templatePath -Raw
  $updated = $content -replace 'Sample\.', "$SolutionName." -replace 'sample\.', "$SolutionName." -replace '\bSample\b', "$SolutionName" -replace '\bsample\b', "$SolutionName"
  Set-Content -Path $infraServiceRegisterPath -Value $updated -NoNewline
}
else {
  @"
// filepath: $infraServiceRegisterPath
using DotnetCap;
using EfCore.IRepositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using $SolutionName.Domain.Constants;
using $SolutionName.Infrastructure.Persistence.EfCore;
using $SolutionName.Infrastructure.Repositories;

namespace $SolutionName.Infrastructure
{
     public static partial class Register
 {
     public static IServiceCollection AddInfrastructureServices(
         this IServiceCollection services,
         IConfiguration configuration
     )
     {
         // Register DbContext
         // services.AddDbContext<ApplicationDbContext>(options =>
         //     options.UseSqlite(configuration.GetConnectionString("DefaultConnection")));

         //services.AddDotnetCap(configuration).AddRabbitMq(configuration);

         services.AddKeyedScoped(
             typeof(ICommandRepository),
             ServiceKeys.CommandRepository,
             typeof(CommandDefaultRepository) 
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
"@ | Set-Content $infraServiceRegisterPath
}

# Create Program.cs for API
$programPath = "$srcDir/$SolutionName.API/Program.cs"
$templatePath = Join-Path $templateDir "Program.cs"
if (Test-Path $templatePath) {
  $content = Get-Content $templatePath -Raw
  $updated = $content -replace 'Sample\.', "$SolutionName." -replace 'sample\.', "$SolutionName." -replace '\bSample\b', "$SolutionName" -replace '\bsample\b', "$SolutionName"
  Set-Content -Path $programPath -Value $updated -NoNewline
}
else {
  @"
// filepath: $programPath
using Host;
using Host.Services;
using MinimalAPI;
using $SolutionName.Application;
using $SolutionName.Infrastructure;
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
        typeof($SolutionName.Application.Register).Assembly,
        typeof($SolutionName.Infrastructure.Register).Assembly
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

"@ | Set-Content $programPath
}

# Create GlobalUsings.cs in API
$apiGlobalUsings = "$srcDir/$SolutionName.API/GlobalUsings.cs"
@"
// filepath: $apiGlobalUsings
global using Shared.Responses;
"@ | Set-Content $apiGlobalUsings

# Create ApplicationDbContext.cs
$dbContextDir = "$srcDir/$SolutionName.Infrastructure/Persistence/EfCore"
$dbContextPath = "$dbContextDir/ApplicationDbContext.cs"
$templatePath = Join-Path $templateDir "ApplicationDbContext.cs"
if (-not (Test-Path $dbContextDir)) {
  New-Item -ItemType Directory -Path $dbContextDir -Force | Out-Null
}

if (Test-Path $templatePath) {
  $content = Get-Content $templatePath -Raw
  $updated = $content -replace 'Sample\.', "$SolutionName." -replace 'sample\.', "$SolutionName." -replace '\bSample\b', "$SolutionName" -replace '\bsample\b', "$SolutionName"
  Set-Content -Path $dbContextPath -Value $updated -NoNewline
}
else {
  @"
// filepath: $dbContextPath
using EfCore;
using Microsoft.EntityFrameworkCore;
using $SolutionName.Infrastructure.Persistence.EfCore.Configurations;
using System.Reflection;

namespace $SolutionName.Infrastructure.Persistence.EfCore
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
"@ | Set-Content $dbContextPath
}

# Create ConfigurationFilter.cs
$configDir = "$srcDir/$SolutionName.Infrastructure/Persistence/EfCore/Configurations"
$configPath = "$configDir/ConfigurationFilter.cs"
$templatePath = Join-Path $templateDir "ConfigurationFilter.cs"
if (-not (Test-Path $configDir)) {
  New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

if (Test-Path $templatePath) {
  $content = Get-Content $templatePath -Raw
  $updated = $content -replace 'Sample\.', "$SolutionName." -replace 'sample\.', "$SolutionName." -replace '\bSample\b', "$SolutionName" -replace '\bsample\b', "$SolutionName"
  Set-Content -Path $configPath -Value $updated -NoNewline
}
else {
  @"
// filepath: $configPath
namespace $SolutionName.Infrastructure.Persistence.EfCore.Configurations
{
    internal class ConfigurationFilter
    {
    }
}
"@ | Set-Content $configPath
}

# Create CommandDefaultRepository.cs
$repoDir = "$srcDir/$SolutionName.Infrastructure/Repositories"
$commandRepoPath = "$repoDir/CommandDefaultRepository.cs"
$templatePath = Join-Path $templateDir "CommandDefaultRepository.cs"
if (-not (Test-Path $repoDir)) {
  New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
}

if (Test-Path $templatePath) {
  $content = Get-Content $templatePath -Raw
  $updated = $content -replace 'Sample\.', "$SolutionName." -replace 'sample\.', "$SolutionName." -replace '\bSample\b', "$SolutionName" -replace '\bsample\b', "$SolutionName"
  Set-Content -Path $commandRepoPath -Value $updated -NoNewline
}
else {
  @"
// filepath: $commandRepoPath
using EfCore.Repositories;
using Microsoft.Extensions.Logging;
using $SolutionName.Infrastructure.Persistence.EfCore;

namespace $SolutionName.Infrastructure.Repositories;

public class CommandDefaultRepository(ApplicationDbContext dbContext, ILogger<CommandDefaultRepository> logger)
    : CommandRepository(dbContext, logger)
{ }
"@ | Set-Content $commandRepoPath
}

# Create QueryDefaultRepository.cs
$queryRepoPath = "$repoDir/QueryDefaultRepository.cs"
$templatePath = Join-Path $templateDir "QueryDefaultRepository.cs"
if (Test-Path $templatePath) {
  $content = Get-Content $templatePath -Raw
  $updated = $content -replace 'Sample\.', "$SolutionName." -replace 'sample\.', "$SolutionName." -replace '\bSample\b', "$SolutionName" -replace '\bsample\b', "$SolutionName"
  Set-Content -Path $queryRepoPath -Value $updated -NoNewline
}
else {
  @"
// filepath: $queryRepoPath
using EfCore.Repositories;
using $SolutionName.Infrastructure.Persistence.EfCore;
using Shared.Entities;

namespace $SolutionName.Infrastructure.Repositories;
public class QueryDefaultRepository<TEntity, TKey>(ApplicationDbContext dbContext)
    : QueryRepository<TEntity, TKey>(dbContext)
    where TEntity : class, IEntity<TKey>
    where TKey : IEquatable<TKey>
{
}
"@ | Set-Content $queryRepoPath
}

# Create domain constants folder and ServiceKeys class
$constantsDir = "$srcDir/$SolutionName.Domain/Constants"
$serviceKeysPath = "$constantsDir/ServiceKeys.cs"
if (-not (Test-Path $constantsDir)) {
  New-Item -ItemType Directory -Path $constantsDir -Force | Out-Null
}

@"
 // filepath: $serviceKeysPath
 namespace $SolutionName.Domain.Constants;

 public static class ServiceKeys
 {
     public const string CommandRepository = `"CommandRepository`";
     public const string QueryRepository = `"QueryRepository`";
 }
"@ | Set-Content $serviceKeysPath

$appSettingsDevPath = "$srcDir/$SolutionName.API/appsettings.Development.json"
@"
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
                "connectionGlobalHeaders": "Authorization=Basic ZWxhc3RpYzpjaGFuZ2VtZQ==", // Base64 encoded "username:password"
                "indexFormat": "log-dev-$SolutionName-{0:yyyy.MM.dd}",
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
    "SecretToken": "", // Optional, if you have a secret token for your APM server
    "ServerUrl": "http://localhost:8200",
    "Environment": "my-environment",
    "CaptureBody": "all",
    "LogLevel": "Trace"
  },  "DotnetCap": {
    "ConnectionString": "mongodb://localhost:27017/$SolutionName",
    "DbProvider": "MongoDB",
    "UseTransaction": true,

    "UseDashboard": true,
    "DashboardPath": "/cap-dashboard",
    "DashboardUser": "admin",
    "DashboardPassword": "admin",

    "FailedRetryCount": 5,
    "FailedRetryInterval": 60,
    "SucceedMessageExpiredAfter": 86400,

    //"Kafka": {
    //  "BootstrapServers": [ "localhost:9092" ],
    //  "GroupId": "cap-group",
    //  "ClientId": "cap-client",
    //  "Topic": "cap-topic",
    //  "SecurityProtocol": "SASL_SSL",
    //  "SaslMechanism": "PLAIN",
    //  "SaslUsername": "your-kafka-user",
    //  "SaslPassword": "your-kafka-pass",
    //  "ConnectionPoolSize": 10,
    //  "MainConfig": {
    //    "auto.offset.reset": "earliest",
    //    "enable.auto.commit": "true"
    //  },
    //  "TopicOptions": {
    //    "NumPartitions": 3,
    //    "ReplicationFactor": 1
    //  },
    //  "RetriableErrorCodes": [ 15, 25, 27 ]
    //},

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
"@ | Set-Content $appSettingsDevPath

# Create GlobalUsings.cs for Domain
$domainGlobalUsings = "$srcDir/$SolutionName.Domain/GlobalUsings.cs"
@"
// filepath: $domainGlobalUsings
global using Shared.Responses;
"@ | Set-Content $domainGlobalUsings

# Create GlobalUsings.cs for Infrastructure
$infraGlobalUsings = "$srcDir/$SolutionName.Infrastructure/GlobalUsings.cs"
@"
// filepath: $infraGlobalUsings
global using Shared.Responses;
"@ | Set-Content $infraGlobalUsings

# Remove all default Class1.cs files from the generated projects
Write-Host "Removing default Class1.cs files..." -ForegroundColor Cyan
Get-ChildItem -Path $srcDir -Recurse -Filter 'Class1.cs' | Remove-Item -Force

# Remove .gitkeep files from non-empty folders
Write-Host "Removing .gitkeep files from non-empty folders..." -ForegroundColor Cyan
Remove-GitKeepFromNonEmptyFolders "$SolutionName/$srcDir"

# Set API layer as startup project
Write-Host "Setting $SolutionName.API as startup project..." -ForegroundColor Cyan
$solutionFilePath = "$SolutionName.sln"
$projectPath = "$srcDir/$SolutionName.API/$SolutionName.API.csproj"

# Clean up temporary folder if $tempDir is defined
if ($null -ne $tempDir -and (Test-Path $tempDir)) {
  Remove-Item $tempDir -Recurse -Force
}

Write-Host "Done! Solution '$SolutionName' setup complete." -ForegroundColor Green
if ($WithTest) {
  Write-Host "Unit test projects created." -ForegroundColor Green
}
else {
  Write-Host "Run with -WithTest to include test projects." -ForegroundColor Yellow
}
