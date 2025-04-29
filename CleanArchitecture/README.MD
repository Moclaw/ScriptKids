
📦 Clean Architecture .NET Solution Generator

This is a Bash script that automatically sets up a Clean Architecture project structure for .NET applications, following Domain-Driven Design (DDD) and optional Test-Driven Development (TDD) standards.

> **Note:** The code base leverages [MLSolutions](https://github.com/Moclaw/MLSolutions.git).

Currently I just created for only .NET 9, I will update for other version

⸻

🚀 Features
- Creates a full `src/` and `test/` directory structure
- Supports optional unit test project generation via `--with-test`
- Generates a `.gitignore` file suitable for .NET
- Installs NuGet packages for each project layer automatically
- Creates a Clean Architecture folder structure with `.gitkeep` placeholders
- Compatible with macOS/Linux and Bash versions <4 (no associative arrays)

⸻

📂 Solution Structure
```
YourSolution/
├── .gitignore
├── YourSolution.sln
├── src/
│   ├── YourSolution.Domain/
│   ├── YourSolution.Application/
│   ├── YourSolution.Infrastructure/
│   └── YourSolution.API/
└── test/ (only if --with-test)
    ├── YourSolution.Domain.UnitTests/
    ├── YourSolution.Application.UnitTests/
    └── YourSolution.Infrastructure.UnitTests/

```

⸻

🛠️ How to Use

1. **Give execution permission:**
   ```sh
   chmod +x setup.sh
   ```

2. **Run the script:**
   - To create only the main solution:
     ```sh
     ./setup.sh YourSolutionName
     ```
   - To create the main solution with TDD unit test projects:
     ```sh
     ./setup.sh YourSolutionName --with-test
     ```


🧩 Installed NuGet Packages

**Application & Domain Layers:**
- MLSolutions.Core
- MLSolutions.Domain
- MLSolutions.Services

**Infrastructure Layer:**
- MLSolutions.EfCore
- MLSolutions.MongoDb
- MLSolutions.Shard

**API Layer:**
- MLSolutions.Shard

**Unit Test Projects** (optional with `--with-test`):
- xunit
- FluentAssertions
- Moq

⸻

📁 Clean Architecture Folders (per layer)

| Layer          | Folders Created                                                                |
| -------------- | ------------------------------------------------------------------------------ |
| Domain         | Entities, ValueObjects, Aggregates, Repositories, DomainEvents, Specifications |
| Application    | DTOs, Interfaces, Services, Commands, Queries, Validators                      |
| Infrastructure | Persistence, ExternalServices, Repositories                                    |
| API            | Controllers, Filters, Middleware                                               |



⸻

📋 Example

```./setup.sh ECommerce --with-test ```

Creates a complete Clean Architecture solution named ECommerce with unit testing projects ready for TDD.

