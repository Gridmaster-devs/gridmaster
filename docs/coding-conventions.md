# GridMaster Repo-Wide Conventions

---

## 1. Git & Workflow

### Commits
- **Commit as you go**: Commit each logical change incrementally; one logical change per commit.
- **Header**: Must continue *"This commit will..."* with an active-form verb (`Add`, `Fix`, `Refactor`, `Update`, `Remove`). Never use past tense (`added`), `WIP`, or vague labels (`fixed stuff`, `changes`).
- **Body**: Explain **what** and **why**, not **how**. Reference the issue (`Refs: #123` / `Closes #123`).

### Pull Requests & Issues
- Keep PRs small: one PR = one issue or goal.
- Use `docs/pull_request_template.md` (`What`, `Why`, `How tested`, `Additional Notes`/risk, `Screenshots/logs` for UI/visual changes, `Related Issues`).
- Every meaningful change should have a labeled GitHub issue (`bug`, `enhancement`, `documentation`, `code maintenance`) with problem statement and acceptance criteria.

---

## 2. Godot & Scene Architecture

- **Node scope**: Each node/script manages state and logic only for itself or its children.
- **Thin UI**: Do **not** attach one-off scripts to individual buttons/controls; connect built-in UI signals to a handler.
- **Avoid scene/subclass bloat**:
  - Use plain `class_name` node scripts instead of `.tscn` scenes when no scene tree is needed.
  - Use `Resource` subclasses for data/behavior variants instead of creating many node/scene subclasses.
- **Decouple with signals & groups**: Prefer signals (especially 1-to-many or down-tree) and groups (broadcasting to labeled nodes) over tight direct node references.
- **`DANGER:` comments**: Marks severe architectural violations; do not copy them, and flag any unavoidable shortcut with `DANGER:`.

---

## 3. GDScript Style

### Static Typing (Mandatory)
- Explicitly type all variables, parameters, and return types (including `-> void`).
- Use `:=` **only** for constructor calls (`var items := Array()`). Use `: Type` everywhere else.

### Naming

| Element | Convention | Example / Rule |
|---|---|---|
| Files | `snake_case` | `game_state.gd` |
| Classes / Nodes / Preloads | `PascalCase` | `class_name YAMLParser`, `const Weapon = preload(...)` |
| Functions / Variables | `snake_case` | Prefix `_` if private/virtual (`_update_state`) |
| Signals | `snake_case` (**past tense**) | `signal turn_ended(turn_number: int)` |
| Constants / Enum members | `CONSTANT_CASE` | `const MAX_SPEED: int = 100`, `UP = 0,` |
| Enum names | `PascalCase` | `enum Direction` |
| Debug/test-only methods | `DEBUG` prefix | Place at **end of file**; tag `TESTING` in `##` doc comment |

### Formatting & Docs
- Two blank lines between top-level functions.
- Multi-line enums, arrays, and dicts: one item per line with trailing commas.
- One statement per line; parenthesize multi-line boolean conditions.
- No unnecessary commented-out code in commits.
- Add `##` doc comments on classes, public methods, signals, enums, constants, and public/`@export` vars. Leave private `_`-prefixed helpers without `##` (use `#` if needed).

### Script Member Order (public before `_`-private in each group)
1. `@tool`, `@icon`, `@static_unload`
2. `class_name`
3. `extends`
4. `##` class doc comment
5. `signals`
6. `enums`
7. `constants`
8. `static` vars
9. `@export` vars (annotation immediately above)
10. regular vars
11. `@onready` vars
12. `_static_init()`
13. static methods
14. overridden virtual methods (`_init()`, `_enter_tree()`, `_ready()`, `_process()`, `_physics_process()`, others)
15. overridden custom methods
16. remaining methods (`DEBUG*` methods last)
17. inner classes

---

## 4. File Layout & Export Presets

- Place every script next to its `.tscn` scene.
- Keep component boundaries strict under `grid-master-app/`:
  - `editor/` (editor-only), `executioner/` (client-only), `common/` (shared), `server/` (headless server).
- When adding new files/folders under `grid-master-app/`, verify `export_presets.cfg` includes them.

---

## 5. Testing (GUT & Smoke)

- Place unit tests in `grid-master-app/executioner/tests/`, `editor/tests/`, or `server/tests/` (per `.gutconfig.json`).
- File names: `test_<name>.gd`, `extends GutTest`, test methods `test_<name>()`, inner test classes `Test<Name>`.
- **Pass criteria**: Zero engine errors, `push_error`, warnings, and >0 tests executed.
- **Commands**:
  - Import: `godot --headless --path grid-master-app --import`
  - All GUT tests: `godot --headless --path grid-master-app -s addons/gut/gut_cmdln.gd`
  - Single suite: `godot --headless --path grid-master-app -s addons/gut/gut_cmdln.gd -gselect=<file>.gd`
  - Multiplayer smoke: `./local-multiplayer.sh --smoke`
