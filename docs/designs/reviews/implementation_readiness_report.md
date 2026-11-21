# Goldfish Review Report — Stage 9 (Implementation Readiness Test)

**Target:** `c:/Users/Victor/Documents/DEV/Huntress/huntress/docs/designs/architectural-deepening-seam-consolidation.md` (`Lines 247..436`)

## Reviewer Status

| Reviewer | Status |
| --- | --- |
| `egm-implementation-readiness` | completed |
| `egm-codebase-details` | completed |
| `egm-style` | completed |

---

## Severity Summary

* 🔴 **Blocker:** 1
* 🟡 **Major:** 3
* 🟢 **Nit:** 1

---

## Prioritized Findings (Blockers -> Major -> Nits)

### 1. Synchronous State Transition Detection in `PlayerIdleState`, `PlayerMoveState`, and `PlayerAttackState` - Severity: 🔴 Blocker
* **Reviewer Lens:** `egm-codebase-details`, `egm-implementation-readiness`
* **Affected Scope:** `Lines 279-320` (Items #5, #6, #8, #9, #10: `state.gd`, `state_machine.gd`, `player_idle_state.gd`, `player_move_state.gd`, `player_attack_state.gd`)
* **Discrepancy Description**:
  1. In `src/entities/player/states/player_idle_state.gd` (`Lines 11-28`) and `src/entities/player/states/player_move_state.gd` (`Lines 11-32`), emitting `transition_requested.emit(self, &"DodgeState")` synchronously invokes `StateMachine.transition_to(&"DodgeState")`. When `PlayerDodgeState.can_enter()` returns `true`, `PlayerDodgeState.enter()` immediately sets `movement_component.apply_direct_velocity(_locked_direction, _initial_dodge_speed)` (`460.0 px/s`). If `PlayerIdleState.physics_update()` or `PlayerMoveState.physics_update()` does not immediately `return` after a successful transition, execution falls through to `movement_component.apply_friction(delta)` or `movement_component.accelerate_in_direction(direction, delta)`, overwriting the dodge velocity on frame 1 and breaking `TestPlayerStateMachine._test_directional_dodge_locks_direction_rf005`.
  2. Conversely, in `src/entities/player/states/player_attack_state.gd` (`Lines 75-77`, `127-128`, `168-174`), `_try_dodge_cancel() -> bool` must return `true` **only** if the transition to `DodgeState` actually succeeded. If `_try_dodge_cancel()` returns `true` when `can_enter()` rejected the transition (e.g., dodge is on cooldown), `PlayerAttackState.physics_update()` will `return` early at line 77 and freeze `_phase_timer`.
  3. Item #8 (`Line 304`) suggests checking `get_parent().current_state != self`, which directly violates **Constitution v1.1.0 Section 1.2.3 (Call Down, Signal Up)** forbidding child nodes from querying parent state via `get_parent()`.
* **Rationale & Recommendation**:
  Add `var is_active: bool = false` to the `State` base class (`src/state_machine/state.gd`), managed by `StateMachine` (`is_active = true` before `enter()`, `is_active = false` before `exit()`). Then:
  * In `PlayerIdleState.physics_update()` and `PlayerMoveState.physics_update()`, after `transition_requested.emit(self, &"DodgeState")`, check `if not is_active: return`.
  * In `PlayerAttackState._try_dodge_cancel() -> bool`, emit `transition_requested.emit(self, &"DodgeState")` and `return not is_active`.

---

### 2. Missing Target File Entries or Compatibility Contract for `InventoryComponent` Callers (`CombatStyleComponent` & `PreparationUIGreybox`) - Severity: 🟡 Major
* **Reviewer Lens:** `egm-implementation-readiness`, `egm-codebase-details`
* **Affected Scope:** `Lines 370-390` (Items #18, #19, #20) and `Lines 413-418` (Item #24) vs. `Line 29` & `Line 181`
* **Discrepancy Description**:
  `Goals` (`Line 29`) and `Phase 4 Technical Plan` (`Line 181`) state that 1:1 forwarding methods will be removed from `InventoryComponent` and that `CombatStyleComponent` and `PreparationUIGreybox` will be updated to read state from `inventory_component.preparation_data`. However:
  1. Neither `src/components/combat_style_component.gd` nor `src/ui/preparation_ui_greybox.gd` is listed in `Target Files to Create/Modify` (`Lines 249-425`).
  2. In the actual codebase, `CombatStyleComponent` (`Lines 57, 79, 90`) calls `inventory_component.has_oil_charges()` and `inventory_component.consume_charge_for_oil()`.
  3. `PreparationUIGreybox` (`Lines 89-97, 114-127, 151, 246, 267`) calls `inventory_component.manager.get_registered_reagents()`, `inventory_component.get_reagent_count()`, `inventory_component.manager.get_registered_recipes()`, `inventory_component.get_oil_charges()`, `inventory_component.max_oil_charges`, `inventory_component.try_craft_recipe()`, and `inventory_component.trigger_campfire_rest()`.
  4. `TestPreparationManager` (`Lines 76-103`) calls `inv.collect_reagent_from_world()`, `inv.try_craft_recipe()`, `inv.get_oil_charges()`, `inv.get_reagent_count()`, and `inv.consume_charge_for_oil()`.
* **Rationale & Recommendation**:
  Explicitly add `src/components/combat_style_component.gd` and `src/ui/preparation_ui_greybox.gd` to `Target Files to Create/Modify` (or specify in Item #20 `src/components/inventory_component.gd` that `InventoryComponent` eliminates the 7 duplicated `@export` configuration fields and `_sync_parameters()` in favor of `@export var preparation_data: PreparationData`, while retaining the scene-connector methods and `manager` getter delegating to `preparation_data` so `PreparationUIGreybox`, `CombatStyleComponent`, and `TestPreparationManager` remain 100% compatible).

---

### 3. Missing `facing_direction` Dependency in `PlayerInteractionComponent` for Composite Relevance Scoring - Severity: 🟡 Major
* **Reviewer Lens:** `egm-codebase-details`, `egm-implementation-readiness`
* **Affected Scope:** `Lines 321-327` (Item #11: `src/entities/player/player.gd`) and `Lines 363-369` (Item #17: `src/components/player_interaction_component.gd`)
* **Discrepancy Description**:
  Item #17 defines `compute_interactable_score(origin: Vector2, facing: Vector2, target: Interactable) -> float` and `select_best_interactable(origin: Vector2, facing: Vector2, candidates: Array[Interactable]) -> Interactable`. However, in the actual codebase (`src/components/player_interaction_component.gd`, `Lines 16-20`, and `src/entities/player/player.gd`, `Lines 67-70`), `PlayerInteractionComponent` only holds references to `state_machine: StateMachine` and `input_component: PlayerInputComponent`—it has no reference to `movement_component: MovementComponent` (where `facing_direction` is stored).
* **Rationale & Recommendation**:
  Update Item #11 (`src/entities/player/player.gd`) and Item #17 (`src/components/player_interaction_component.gd`) to declare `var movement_component: MovementComponent` on `PlayerInteractionComponent`, wire `interaction_component.movement_component = movement_component` in `Player._ready()`, and read `movement_component.facing_direction` (defaulting to `Vector2.DOWN` when `movement_component == null`) inside `_refresh_focused_targets()`.

---

### 4. Preserving `PlayerDodgeState.is_invulnerable()` When `health_component` Is Null in Headless StateMachine Tests - Severity: 🟡 Major
* **Reviewer Lens:** `egm-codebase-details`
* **Affected Scope:** `Lines 293-299` (Item #7: `src/entities/player/states/player_dodge_state.gd`)
* **Discrepancy Description**:
  In `tests/unit/test_player_state_machine.gd` (`Lines 27-65` and `147-169`), `_build_test_rig()` instantiates `PlayerDodgeState` without a `HealthComponent` (`dodge_state.health_component == null`) and asserts `dodge.is_invulnerable()` at `0.016s` and `0.18s`. In addition, `tests/sandboxes/sandbox_player_movement.gd` (`Line 17`) and `tests/sandboxes/sandbox_combat.gd` (`Line 44`) call `player.dodge_state.is_invulnerable()`, and `PlayerGreyboxVisual` (`Lines 62-66`) connects to `dodge_state.invulnerability_started` and `dodge_state.invulnerability_ended`.
* **Rationale & Recommendation**:
  Clarify in Item #7 (`src/entities/player/states/player_dodge_state.gd`) that `PlayerDodgeState` retains its local `_is_invulnerable` state, `is_invulnerable() -> bool` method, and `invulnerability_started` / `invulnerability_ended` signals alongside the new `if health_component != null: health_component.grant_invulnerability(_invulnerability_duration, &"dodge")` / `revoke_invulnerability(&"dodge")` calls.

---

### 5. Explicit Signal Emission Contract on `PreparationData` Methods - Severity: 🟢 Nit
* **Reviewer Lens:** `egm-style`, `egm-implementation-readiness`
* **Affected Scope:** `Lines 370-376` (Item #18: `src/data/preparation_data.gd`)
* **Discrepancy Description**:
  Item #18 lists the signals on `PreparationData` (`reagent_count_changed`, `oil_charges_changed`, `oil_crafted`, `crafting_failed`, `active_oil_depleted`, `campfire_rest_completed`) but does not state which methods on `PreparationData` emit them (`add_reagent`, `set_oil_charges`, `craft_oil`, `consume_oil_charge`, `register_campfire_rest`) vs. whether `InventoryComponent` forwards those signals or emits its own.
* **Rationale & Recommendation**:
  Specify in Item #18 and Item #20 whether `PreparationData` methods emit those signals directly (and `InventoryComponent` connects and re-emits them) so signal emission happens exactly once per operation in `TestPreparationManager`.
