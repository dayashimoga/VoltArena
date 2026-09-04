# Contributing to VoltArena

Thank you for your interest in contributing to VoltArena! We maintain high standards of code quality, performance, and containerized reliability.

---

## 1. Development Principles

1. **Zero Host Installations**: Never add scripts or tools requiring local package managers (`npm`, `pip`, native toolchains). Everything must run inside Podman containers.
2. **Zero External Assets**: All visual and audio assets must be procedurally generated at runtime using `MaterialGenerator` and `AudioManager`.
3. **100% Passing Tests**: All pull requests must pass the automated test runner (`scripts/test.sh`) with 0 failures.
4. **>90% Code Coverage**: Any new gameplay feature must include unit or acceptance tests maintaining $> 90.0\%$ code coverage.
5. **Cloudflare Free Tier Compliant**: No single web export file may exceed 25.0 MB.

---

## 2. Coding Conventions (GDScript 2.0)

* **Static Typing**: All function signatures, parameters, and variable declarations must use static type hints:
  ```gdscript
  func calculate_damage(base_amount: float, distance: float) -> float:
      var falloff: float = clampf(1.0 - (distance / 50.0), 0.0, 1.0)
      return base_amount * falloff
  ```
* **Signal Naming**: Use past-tense verbs for signals representing completed events (`died`, `lap_completed`, `weapon_fired`).
* **Autoload Rules**: Do not declare `class_name` on scripts registered as Autoload singletons in `project.godot`.
* **Defensive Tree Checks**: Always verify `is_inside_tree()` or `get_tree() != null` before scheduling timers or querying viewports.

---

## 3. Pull Request Validation Checklist

Before submitting a pull request, run the full production validation pipeline:

### Using Bash:
```bash
bash scripts/validate-production.sh
```

### Using PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-production.ps1
```

Confirm that:
* [x] Gate 1: 100% assertions passed.
* [x] Gate 2: Code coverage is $>90.0\%$.
* [x] Gate 3: All 5 main scenes boot cleanly headlessly.
* [x] Gate 4: Performance benchmarks pass.
* [x] Gate 5: Web export satisfies Cloudflare 25MB limits.
* [x] Gate 6: `artifacts/production-certification.json` is generated.
