# Goldfish Review Report (Stage 7 — Critic Review)

**Target:** `c:/Users/Victor/Documents/DEV/Huntress/huntress/docs/designs/architectural-deepening-seam-consolidation.md` (`Lines 1-246`)

## Reviewer Status

| Reviewer | Status |
| --- | --- |
| `egm-design` | completed |
| `egm-structural` | completed |
| `egm-style` | completed |

## Severity Breakdown
- 🔴 **Blocker:** 0
- 🟡 **Major:** 3
- 🟢 **Nit:** 3

---

## Prioritized Findings (Blockers -> Major -> Nits)

### 1. Ambiguous `InventoryComponent` Pass-Through Removal vs. Caller Compatibility - Severity: Major
* **Reviewer Lens:** `egm-design`
* **Affected Scope:** `Lines 29, 178-181, 384-390`
* **Discrepancy Description**: In Goals (`Line 29`), the specification states it will *"remove one-to-one forwarding methods from `InventoryComponent`"*, and Phase 4 (`Line 181`) states it will *"update `CombatStyleComponent` and `PreparationUIGreybox` to read state from `inventory_component.preparation_data`"*. However, the Detailed Implementation Plan (`Lines 249-425`) omits both `src/components/combat_style_component.gd` and `src/ui/preparation_ui_greybox.gd` from the target file modification list, and existing tests in `tests/unit/test_preparation_manager.gd` (`Lines 80-102`) directly invoke `inv.try_craft_recipe()`, `inv.get_oil_charges()`, `inv.get_reagent_count()`, and `inv.consume_charge_for_oil()` on `InventoryComponent`. If those methods are deleted from `InventoryComponent` without either updating callers/tests or defining which domain orchestration methods remain on `InventoryComponent`, `TestPreparationManager`, `CombatStyleComponent`, and `PreparationUIGreybox` will fail at runtime.
* **Rationale & Recommendation**: Explicitly specify the exact boundary on `InventoryComponent`: either (a) list `src/components/combat_style_component.gd` and `src/ui/preparation_ui_greybox.gd` in the target files and specify how `TestPreparationManager` is updated, OR (b) clarify that `InventoryComponent` eliminates the duplicated `@export` parameter fields and `_sync_parameters()` boilerplate in favor of `@export var preparation_data: PreparationData` (aliased to `manager`), while retaining the 6 domain mutation/query entrypoints (`collect_reagent_from_world`, `try_craft_recipe`, `consume_charge_for_oil`, `trigger_campfire_rest`, `get_reagent_count`, `get_oil_charges`, `has_oil_charges`) as thin delegates to `preparation_data` so all existing callers (`CombatStyleComponent`, `PreparationUIGreybox`, `TestPreparationManager`) remain 100% compatible without cross-system churn.

### 2. Missing Facing Vector Source and Legacy Method Contract in `PlayerInteractionComponent` - Severity: Major
* **Reviewer Lens:** `egm-design`
* **Affected Scope:** `Lines 162-171, 363-369`
* **Discrepancy Description**: Phase 3 introduces `compute_interactable_score(origin: Vector2, facing: Vector2, target: Interactable) -> float`, which requires a `facing: Vector2` parameter. Currently, `PlayerInteractionComponent` (`src/components/player_interaction_component.gd`) only holds references to `state_machine: StateMachine` and `input_component: PlayerInputComponent`, neither of which stores `facing_direction` (`facing_direction` lives on `MovementComponent`, or falls back to `input_component.move_direction` / `Vector2.DOWN`). Furthermore, the spec mentions retaining `select_best_clue(origin: Vector2, candidates: Array[InteractableClue])` as a compatibility wrapper (`Line 367`), but does not specify what default `facing` vector `select_best_clue` passes or how `PlayerInteractionComponent` obtains `facing` during `_refresh_focused_targets()`.
* **Rationale & Recommendation**: Specify how `PlayerInteractionComponent` resolves the facing vector (e.g., optional `movement_component: MovementComponent` reference wired in `Player._ready()` with a fallback to `Vector2.DOWN` when `movement_component == null` in isolated unit tests), and explicitly state that `select_best_clue(origin, candidates)` delegates to `select_best_interactable` (or scores uninspected clues ahead of inspected clues by distance) so `TestInteractionAndClues.test_select_best_clue_prioritizes_uninspected_and_closest_ec001()` continues to pass deterministically.

### 3. Missing `@export` Parameterization for Interaction Scoring Weights (Constitution Section 1.2.4) - Severity: Major
* **Reviewer Lens:** `egm-structural`
* **Affected Scope:** `Lines 164-169`
* **Discrepancy Description**: Constitution Section 1.2.4 (*Game Feel 100% Parametrizado*) strictly forbids hardcoded magic numbers in gameplay/feel calculations. In Phase 3 (`Lines 168-169`), the composite relevance score hardcodes magic constants (`1200.0` foot bonus, `144.0` px² / `12.0` px foot-zone radius, `10.0` priority weight, `20.0` facing alignment weight, `0.05` distance-squared penalty) without declaring named constants or `@export` parameters.
* **Rationale & Recommendation**: Define named constants or `@export` tuning properties on `PlayerInteractionComponent` (and/or `const` default weights used by the static scoring helper, such as `DEFAULT_PRIORITY_WEIGHT = 10.0`, `DEFAULT_FOOT_ZONE_RADIUS = 12.0`, `DEFAULT_FOOT_BONUS = 1200.0`, `DEFAULT_ALIGNMENT_WEIGHT = 20.0`, `DEFAULT_DISTANCE_WEIGHT = 0.05`) so the scoring formula in `Lines 164-169` complies with Constitution Section 1.2.4.

### 4. `HealthComponent.reset_health()` Behavior with `_active_iframes` Not Specified - Severity: Nit
* **Reviewer Lens:** `egm-design`
* **Affected Scope:** `Lines 100-109, 251-256`
* **Discrepancy Description**: Phase 1 replaces `_invulnerability_timer: float` with `_active_iframes: Dictionary` in `HealthComponent`, but does not explicitly state that `reset_health()` must clear `_active_iframes` (or call `revoke_invulnerability(&"")`).
* **Rationale & Recommendation**: Note in Phase 1 (`Line 105` / `Line 255`) that `reset_health()` clears `_active_iframes` so entity resets never leave stale invulnerability leases active.

### 5. `Interactable.update_interaction()` Mentioned in CUJ 2 vs. `set_interaction_progress()` in Technical Plan - Severity: Nit
* **Reviewer Lens:** `egm-style`
* **Affected Scope:** `Lines 55, 149-157, 339`
* **Discrepancy Description**: CUJ 2 (`Line 55`) refers to channeling progress through `Interactable.update_interaction()`, whereas the Phase 3 technical specification (`Line 154` and `Line 339`) names the virtual method `set_interaction_progress(_ratio: float) -> void`.
* **Rationale & Recommendation**: Align the method name in CUJ 2 (`Line 55`) to `Interactable.set_interaction_progress(ratio)` so terminology is 100% consistent across sections.

### 6. Folder Convention Note: `src/entities/world/` vs. Constitution `src/entities/interactables/` - Severity: Nit
* **Reviewer Lens:** `egm-structural`
* **Affected Scope:** `Lines 144, 335-361`
* **Discrepancy Description**: Constitution Section 4.2 lists `src/entities/interactables/` in the reference directory tree, whereas the existing repository places `interactable_clue.gd`, `interactable_reagent.gd`, and `interactable_campfire.gd` in `src/entities/world/`. Placing `src/entities/world/interactable.gd` alongside its existing subclasses is the right choice to avoid breaking `.tscn` script paths, but the reason for keeping `src/entities/world/` could be briefly noted.
* **Rationale & Recommendation**: Add a brief parenthetical note in Phase 3 (`Line 144`) stating that `interactable.gd` is placed in `src/entities/world/` to co-locate with existing world entity scripts and preserve `.tscn` scene UIDs/paths.
