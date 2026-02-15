---
description: An enterprise-level App development skill following strict rules and best practices.
---

# App Development

This skill provides mandatory guidelines for developing enterprise-level applications, ensuring code quality, maintainability, and consistency.

## Enterprise App Rules

1.  **Strict Adherence to SRP (Single Responsibility Principle)**:
    -   Ensure every class, function, and module has one clear responsibility.
    -   Maintain a strict separation between business logic and UI components.
    -   Avoid massive "God classes" or highly coupled logic.

2.  **Clean Architecture**:
    -   Structure the app into valid layers: **Presentation**, **Domain**, and **Data**.
    -   Dependencies should point inwards (Data -> Domain <- Presentation).

3.  **Vertical Slice Architecture (VSA)**:
    -   **Feature-Oriented Organization**: Group code by feature under `lib/feature/`.
    -   **Self-Contained Slices**: Each feature slice contains its own layers (Presentation, Domain, Data).
    -   **Independence & Decoupling**: Slices should be independent and shouldn't leak implementation details to other slices.
    -   **Controlled Communication**: Cross-slice communication should happen through shared entities in `core` or well-defined APIs.
    -   **Core Module Role**: Restrict `core` to truly shared infrastructure and cross-cutting concerns.

4.  **Core Design Principles**:
    -   **UseCase doesn't trust UI**: Never rely on data directly passed from the UI layer without validation
    -   **UseCase fetches its own data**: UseCases should retrieve all data they need to make decisions independently
    -   **UI passes intent, not results**: The UI should communicate user intentions, not pre-computed results or business logic outcomes

5.  **Good Practices**:
    -   Follow standard Dart/Flutter coding conventions.
    -   Write self-documenting code with meaningful variable and function names.
    -   Keep widgets small and reusable.

6.  **Defined Constants**:
    -   **ALL** constant variables (Supabase table names, bucket names, Assets, API keys, etc.) **MUST** be defined in:
        `core/config/app_constants.dart`
    -   Do not hardcode strings or magic numbers in the business logic or UI code.

7.  **Theme Usage**:
    -   **ALWAYS** use `Theme.of(context)` to access the app's primary colors and fonts.
    -   Do not hardcode color values or font styles directly in widgets.
    -   Access theme properties through `Theme.of(context).colorScheme` and `Theme.of(context).textTheme`.

## Development Workflow & Quality Checks

### 1. Compilation & Analysis
Before finishing any task, you **MUST** run the following to check for compilation errors and static analysis issues:
```bash
dart analyze
```
Fix all reported errors and warnings.

### 2. Formatting & Fixes
Ensure code is properly formatted and auto-fixable issues are resolved by running:
```bash
dart fix --apply && dart format .
```

### 3. Framework Usage (MCP Tools)
-   Use **context7** MCP tools to query the latest usage and best practices for frameworks and libraries (e.g., Flutter, Supabase, Riverpod, etc.).
-   Ensure you are using the most up-to-date and deprecated-free APIs.

## Version Control Rules

-   **NO Automated Commits**: You are **STRICTLY FORBIDDEN** from using `git add`, `git commit`, or `git push`.
-   **Manual Review**: The user will review the code changes and perform the commit/push operations manually.
