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

add_refs "$SOLUTION_NAME.Application" "$SOLUTION_NAME.Domain"
add_refs "$SOLUTION_NAME.Infrastructure" "$SOLUTION_NAME.Domain" "$SOLUTION_NAME.Application"
add_refs "$SOLUTION_NAME.API" "$SOLUTION_NAME.Domain" "$SOLUTION_NAME.Application" "$SOLUTION_NAME.Infrastructure"

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

add_packages "$SOLUTION_NAME.Domain" MLSolutions.Core MLSolutions.Domain
add_packages "$SOLUTION_NAME.Application" MLSolutions.Core MLSolutions.Services
add_packages "$SOLUTION_NAME.Infrastructure" MLSolutions.Core MLSolutions.EfCore MLSolutions.MongoDb MLSolutions.Shard
add_packages "$SOLUTION_NAME.API" MLSolutions.Core MLSolutions.Shard

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

create_folders "$SOLUTION_NAME.Domain" Entities ValueObjects Repositories Aggregates DomainEvents Specifications
create_folders "$SOLUTION_NAME.Application" DTOs Interfaces Services Commands Queries Validators
create_folders "$SOLUTION_NAME.Infrastructure" Persistence ExternalServices Repositories
create_folders "$SOLUTION_NAME.API" Controllers Filters Middleware

echo "✅ Done! Clean Architecture solution '$SOLUTION_NAME' is ready."
if [ "$WITH_TEST" = true ]; then
  echo "🧪 Unit test projects created with xUnit, Moq, and FluentAssertions."
else
  echo "ℹ️  Run with '--with-test' to generate unit test projects."
fi