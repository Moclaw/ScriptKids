# 📦 Clean Architecture .NET Solution Generator

This is a **Bash/PowerShell script** that automatically sets up a Clean Architecture project structure for .NET applications, following Domain-Driven Design (DDD) and optional Test-Driven Development (TDD) standards.

> **Note:** The code base leverages [MLSolutions](https://github.com/Moclaw/MLSolutions).

_Currently, this script is tailored for **.NET 9**. Future support for additional .NET versions is planned._

---

## 🚀 Features
- Creates a full `src/` and `test/` directory structure
- Supports optional unit test project generation via `--with-test`
- Generates a `.gitignore` file suitable for .NET
- Installs NuGet packages for each project layer automatically
- Creates a Clean Architecture folder structure with `.gitkeep` placeholders
- Compatible with:
  - ✅ Bash for macOS/Linux
  - ✅ PowerShell for Windows

---

## 📂 Solution Structure

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

---

## 🛠️ How to Use

### 🐧 On macOS/Linux (using `setup.sh`)

1. Give execution permission:
   ```sh
   chmod +x setup.sh
   ```
2. Run the script:
   - To create only the main solution:
     ```sh
     ./setup.sh YourSolutionName
     ```
   - To create the solution with TDD unit test projects:
     ```sh
     ./setup.sh YourSolutionName --with-test
     ```

---

### 🪟 On Windows (using `setup.ps1` with PowerShell)

- To create only the main solution:
  ```powershell
  .\setup.ps1 -SolutionName YourSolutionName
  ```
- To create the solution with unit test projects:
  ```powershell
  .\setup.ps1 -SolutionName YourSolutionName -WithTest
  ```

---

## 🧩 Installed NuGet Packages

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

**Unit Test Projects** (if enabled with `--with-test`):
- xunit
- FluentAssertions
- Moq

---

## 📁 Clean Architecture Folders (per layer)

| Layer         | Folders Created                                                        |
|-------------- |-----------------------------------------------------------------------|
| Domain        | Entities, ValueObjects, Aggregates, Repositories, DomainEvents, Specifications |
| Application   | DTOs, Interfaces, Services, Commands, Queries, Validators             |
| Infrastructure| Persistence, ExternalServices, Repositories                           |
| API           | Controllers, Filters, Middleware                                      |

---

## 📋 Example

```sh
./setup.sh ECommerce --with-test
```

or on Windows:

```powershell
.\setup.ps1 -SolutionName ECommerce -WithTest
```

Creates a complete Clean Architecture solution named `ECommerce` with unit testing projects ready for TDD.

