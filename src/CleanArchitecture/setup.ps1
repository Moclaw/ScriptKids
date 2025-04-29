param(
    [Parameter(Mandatory = $true)]
    [string]$SolutionName,

    [switch]$WithTest
)

$SrcDir = "src"
$TestDir = "test"

$Projects = @(
    "$SolutionName.Domain",
    "$SolutionName.Application",
    "$SolutionName.Infrastructure",
    "$SolutionName.API"
)

$TestProjects = @(
    "$SolutionName.Domain.UnitTests",
    "$SolutionName.Application.UnitTests",
    "$SolutionName.Infrastructure.UnitTests"
)

Write-Host "📂 Creating root structure: $SolutionName/{src,test}" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $SolutionName/$SrcDir -Force | Out-Null
New-Item -ItemType Directory -Path $SolutionName/$TestDir -Force | Out-Null
Set-Location $SolutionName

# Create .gitignore
Write-Host "📝 Creating .gitignore" -ForegroundColor Cyan
@"
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
"@ | Set-Content ".gitignore"

# Create Solution
Write-Host "🛠️ Creating solution: $SolutionName.sln" -ForegroundColor Cyan
dotnet new sln -n $SolutionName

# Create src projects
foreach ($project in $Projects) {
    $ProjectPath = "$SrcDir/$project"
    if ($project -like "*.API") {
        Write-Host "📦 Creating WebAPI project: $project" -ForegroundColor Yellow
        dotnet new webapi -n $project -o $ProjectPath
    }
    else {
        Write-Host "📦 Creating classlib project: $project" -ForegroundColor Yellow
        dotnet new classlib -n $project -o $ProjectPath
    }
    Write-Host "➕ Adding $project to solution" -ForegroundColor Green
    dotnet sln add "$ProjectPath/$project.csproj"
}

# Create test projects (if --with-test)
if ($WithTest) {
    foreach ($testproject in $TestProjects) {
        $TestPath = "$TestDir/$testproject"
        Write-Host "🧪 Creating unit test project: $testproject" -ForegroundColor Yellow
        dotnet new xunit -n $testproject -o $TestPath
        Write-Host "➕ Adding $testproject to solution" -ForegroundColor Green
        dotnet sln add "$TestPath/$testproject.csproj"
    }
}

# Add references
Write-Host "🔗 Adding project references..." -ForegroundColor Cyan

function Add-Refs($From, $References) {
    Set-Location "$SrcDir/$From"
    foreach ($ref in $References) {
        dotnet add reference "../../$SrcDir/$ref/$ref.csproj"
    }
    Set-Location ../.. 
}

function Add-TestRefs($From, $Ref) {
    Set-Location "$TestDir/$From"
    dotnet add reference "../../$SrcDir/$Ref/$Ref.csproj"
    Set-Location ../.. 
}

Add-Refs "$SolutionName.Application" @("$SolutionName.Domain")
Add-Refs "$SolutionName.Infrastructure" @("$SolutionName.Domain", "$SolutionName.Application")
Add-Refs "$SolutionName.API" @("$SolutionName.Domain", "$SolutionName.Application", "$SolutionName.Infrastructure")

if ($WithTest) {
    Add-TestRefs "$SolutionName.Domain.UnitTests" "$SolutionName.Domain"
    Add-TestRefs "$SolutionName.Application.UnitTests" "$SolutionName.Application"
    Add-TestRefs "$SolutionName.Infrastructure.UnitTests" "$SolutionName.Infrastructure"
}

# Install NuGet packages
Write-Host "📦 Installing NuGet packages..." -ForegroundColor Cyan

function Add-Packages($ProjectPath, $Packages) {
    Set-Location "$SrcDir/$ProjectPath"
    foreach ($pkg in $Packages) {
        dotnet add package $pkg
    }
    Set-Location ../.. 
}

function Add-TestPackages($TestPath, $Packages) {
    Set-Location "$TestDir/$TestPath"
    foreach ($pkg in $Packages) {
        dotnet add package $pkg
    }
    Set-Location ../.. 
}

Add-Packages "$SolutionName.Domain" @("MLSolutions.Core", "MLSolutions.Domain")
Add-Packages "$SolutionName.Application" @("MLSolutions.Core", "MLSolutions.Services")
Add-Packages "$SolutionName.Infrastructure" @("MLSolutions.Core", "MLSolutions.EfCore", "MLSolutions.MongoDb", "MLSolutions.Shard")
Add-Packages "$SolutionName.API" @("MLSolutions.Core", "MLSolutions.Shard")

if ($WithTest) {
    Add-TestPackages "$SolutionName.Domain.UnitTests" @("xunit", "FluentAssertions", "Moq")
    Add-TestPackages "$SolutionName.Application.UnitTests" @("xunit", "FluentAssertions", "Moq")
    Add-TestPackages "$SolutionName.Infrastructure.UnitTests" @("xunit", "FluentAssertions", "Moq")
}

# Create folders
Write-Host "📁 Creating Clean Architecture folders..." -ForegroundColor Cyan

function Create-Folders($Project, $Folders) {
    foreach ($folder in $Folders) {
        $Path = "$SrcDir/$Project/$folder"
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        New-Item -ItemType File -Path "$Path/.gitkeep" -Force | Out-Null
    }
}

Create-Folders "$SolutionName.Domain" @("Entities", "ValueObjects", "Repositories", "Aggregates", "DomainEvents", "Specifications")
Create-Folders "$SolutionName.Application" @("DTOs", "Interfaces", "Services", "Commands", "Queries", "Validators")
Create-Folders "$SolutionName.Infrastructure" @("Persistence", "ExternalServices", "Repositories")
Create-Folders "$SolutionName.API" @("Controllers", "Filters", "Middleware")

Write-Host "`n✅ Done! Clean Architecture solution '$SolutionName' is ready." -ForegroundColor Green
if ($WithTest) {
    Write-Host "🧪 Unit test projects created with xUnit, Moq, and FluentAssertions." -ForegroundColor Green
} else {
    Write-Host "ℹ️  Run with '--with-test' to generate unit test projects." -ForegroundColor Yellow
}