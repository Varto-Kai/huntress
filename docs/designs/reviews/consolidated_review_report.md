# Consolidated Goldfish Review Report

**Target Document:** [docs/designs/architectural-deepening-seam-consolidation.md](./docs/designs/architectural-deepening-seam-consolidation.md)  
**Author:** Varto-Kai  
**Date:** 2026-11-20  
**Semantic Split:** `FeatureRange = 1..246` | `DetailedRange = 247..436`  
**Execution Mode:** Consolidated Report with All Review Rubrics (Stages 5, 6, 7, 8, and 9)

---

## 1. Stage Execution Summary

| Stage | Rubric / Subflow | Reviewers | Artifact Report | Findings |
| :--- | :--- | :--- | :--- | :--- |
| **Stage 5** | Initial Zoom Out & Inventive Catalyst | `egm-zoom-out`, `egm-inventive-catalyst` | [zoom_out_report.md](./zoom_out_report.md) | 0 Blocker, 4 Major, 2 Nit |
| **Stage 6** | Comprehension Test (Naive Reader) | `egm-comprehension` | [comprehension_report.md](./comprehension_report.md) | 0 Blocker, 0 Major, 2 Nit |
| **Stage 7** | Feature Spec Critic Review | `egm-design`, `egm-structural`, `egm-style` | [critic_report.md](./critic_report.md) | 0 Blocker, 3 Major, 3 Nit |
| **Stage 8** | Intermediate Zoom Out Review | `egm-zoom-out` | [intermediate_zoom_out_report.md](./intermediate_zoom_out_report.md) | 0 Blocker, 3 Major, 3 Nit |
| **Stage 9** | Implementation Readiness Test | `egm-implementation-readiness`, `egm-codebase-details`, `egm-style` | [implementation_readiness_report.md](./implementation_readiness_report.md) | 1 Blocker, 3 Major, 1 Nit |

**Deduplicated Total:** **1 🔴 Blocker, 5 🟡 Major, 4 🟢 Nit**

---

## 2. Consolidated Actionable Tasks (Prioritized)

### 🔴 Blockers (Must Resolve Before Implementation)

#### [ACT-01] Track Synchronous State Transition Completion via `State.is_active` Instead of `get_parent()`
* **Source Findings:** Stage 9 #1
* **Affected Document Lines:** `Lines 122-141, 279-320` (Phase 2: `state.gd`, `state_machine.gd`, `player_idle_state.gd`, `player_move_state.gd`, `player_attack_state.gd`)
* **Problem:**
  1. Emitting `transition_requested.emit(self, &"DodgeState")` inside `PlayerIdleState.physics_update()`, `PlayerMoveState.physics_update()`, or `PlayerAttackState._try_dodge_cancel()` triggers `StateMachine.transition_to(&"DodgeState")` synchronously. If `PlayerDodgeState.can_enter()` returns `true`, `PlayerDodgeState.enter()` immediately sets the initial dodge velocity (`460.0 px/s`). If `PlayerIdleState` or `PlayerMoveState` does not return immediately when the transition succeeds, it falls through to `apply_friction(delta)` or `accelerate_in_direction(direction, delta)` on the same physics tick, overwriting the dodge velocity on frame 1 and breaking `TestPlayerStateMachine._test_directional_dodge_locks_direction_rf005`.
  2. Conversely, if `PlayerDodgeState.can_enter()` returns `false` (dodge is on cooldown), `PlayerAttackState._try_dodge_cancel()` must return `false` so `_phase_timer` continues counting down instead of freezing the attack state.
  3. Line 304 suggests checking `get_parent().current_state != self`, which directly violates **Project Constitution v1.1.0 Section 1.2.3 (Call Down, Signal Up)** forbidding child nodes from calling `get_parent()`.
* **Actionable Fix:**
  - Add `var is_active: bool = false` to `State` (`src/state_machine/state.gd`).
  - Update `StateMachine` (`src/state_machine/state_machine.gd`) to set `current_state.is_active = false` immediately before `current_state.exit()` and `next_state.is_active = true` immediately before `next_state.enter()`.
  - In `PlayerIdleState.physics_update()` and `PlayerMoveState.physics_update()`, after `transition_requested.emit(self, &"DodgeState")`, check `if not is_active: return`.
  - In `PlayerAttackState._try_dodge_cancel() -> bool`, emit `transition_requested.emit(self, &"DodgeState")` and `return not is_active`.

---

### 🟡 Major Tasks

#### [ACT-02] Generalize `State.can_cancel_into_dodge()` to Domain-Agnostic `can_be_interrupted_by(target_state_name: StringName)`
* **Source Findings:** Stage 5 #2, Stage 8 #2
* **Affected Document Lines:** `Lines 123-137, 279-299, 314-320` (Phase 2: `state.gd`, `player_dodge_state.gd`, `player_attack_state.gd`)
* **Problem:** Adding a player-dodge-specific virtual method (`can_cancel_into_dodge()`) to the generic `State` base class pollutes the universal finite state machine layer (which will be reused by monsters and `SPEC-005` bosses) with player action vocabulary.
* **Actionable Fix:**
  - In `src/state_machine/state.gd`, replace `func can_cancel_into_dodge() -> bool` with `func can_be_interrupted_by(_target_state_name: StringName) -> bool: return true`.
  - In `src/entities/player/states/player_attack_state.gd`, override `can_be_interrupted_by(target_state_name: StringName) -> bool` to return `current_phase == Phase.WINDUP or current_phase == Phase.RECOVERY` when `String(target_state_name).to_lower() == "dodgestate"`, and `true` otherwise.
  - In `src/entities/player/states/player_dodge_state.gd`, update `can_enter(from_state: State) -> bool` to check `can_dodge() and (from_state == null or from_state.can_be_interrupted_by(&"DodgeState"))`.

#### [ACT-03] Preserve Local `_is_invulnerable` and Signals in `PlayerDodgeState` for Headless StateMachine Tests
* **Source Findings:** Stage 9 #4
* **Affected Document Lines:** `Lines 112-115, 293-299` (Phase 1 & 2: `src/entities/player/states/player_dodge_state.gd`)
* **Problem:** `TestPlayerStateMachine` instantiates `PlayerDodgeState` in a movement-only test rig without a `HealthComponent` (`health_component == null`) and asserts `dodge.is_invulnerable()`. In addition, `PlayerGreyboxVisual`, `sandbox_player_movement.gd`, and `sandbox_combat.gd` inspect `dodge_state.is_invulnerable()` and connect to `dodge_state.invulnerability_started` / `invulnerability_ended`.
* **Actionable Fix:**
  - Specify in Phase 1 and Item #7 (`src/entities/player/states/player_dodge_state.gd`) that `PlayerDodgeState` retains its local `_is_invulnerable` boolean, `is_invulnerable() -> bool` getter, and `invulnerability_started` / `invulnerability_ended` signals alongside delegating `if health_component != null: health_component.grant_invulnerability(_invulnerability_duration, &"dodge")` and `revoke_invulnerability(&"dodge")`.

#### [ACT-04] Parameterize Interaction Scoring Weights (`@export`) and Wire `movement_component` for `facing_direction`
* **Source Findings:** Stage 5 #3, Stage 5 #5, Stage 7 #2, Stage 7 #3, Stage 8 #3, Stage 9 #3
* **Affected Document Lines:** `Lines 162-171, 321-327, 363-369` (Phase 3: `src/components/player_interaction_component.gd`, `src/entities/player/player.gd`)
* **Problem:**
  1. Phase 3 embeds magic numeric literals (`10.0`, `1200.0`, `144.0`, `20.0`, `0.05`) in `compute_interactable_score()`, violating **Constitution v1.1.0 Section 1.2.4 (*Game Feel 100% Parametrizado*)**.
  2. `PlayerInteractionComponent` requires the player's `facing_direction` to compute alignment, which lives on `MovementComponent`, but `PlayerInteractionComponent` currently has no reference to `movement_component`.
* **Actionable Fix:**
  - Define named default constants (`DEFAULT_PRIORITY_WEIGHT = 10.0`, `DEFAULT_FOOT_ZONE_RADIUS = 12.0`, `DEFAULT_FOOT_BONUS = 1200.0`, `DEFAULT_ALIGNMENT_WEIGHT = 20.0`, `DEFAULT_DISTANCE_SQ_PENALTY = 0.05`) and corresponding `@export_group("Focus Scoring Weights")` properties on `PlayerInteractionComponent`.
  - Add `var movement_component: MovementComponent` to `PlayerInteractionComponent` and wire `interaction_component.movement_component = movement_component` in `Player._ready()` (falling back to `input_component.move_direction` or `Vector2.DOWN` when `movement_component == null` in unit tests).
  - Specify that the static compatibility wrapper `select_best_clue(origin, candidates)` evaluates candidates with `alignment_weight = 0.0` (priority + distance only) so `TestInteractionAndClues.test_select_best_clue_prioritizes_uninspected_and_closest_ec001()` remains deterministic.

#### [ACT-05] Add Polymorphic `interaction_completed` Signal and Localize Legacy Signal Adapter in `PlayerInteractionComponent`
* **Source Findings:** Stage 5 #4, Stage 8 #3
* **Affected Document Lines:** `Lines 162-171, 363-369` (Phase 3: `src/components/player_interaction_component.gd`)
* **Problem:** To prevent `PlayerInteractionComponent` from branching on concrete subclasses inside its core interaction lifecycle while still emitting legacy signals (`clue_inspection_completed`, `reagent_collected_from_world`, `campfire_interacted`), the polymorphic completion contract must be explicit without introducing circular callbacks on `Interactable`.
* **Actionable Fix:**
  - Add `signal focused_interactable_changed(target: Interactable)` and `signal interaction_completed(target: Interactable, result: Variant)` to `PlayerInteractionComponent` as the primary polymorphic signals.
  - Isolate legacy signal emission (`clue_inspection_completed`, `reagent_collected_from_world`, `campfire_interacted`) to a single private compatibility helper `_emit_legacy_domain_signals(target: Interactable, result: Variant)` invoked after `interaction_completed`.

#### [ACT-06] Align Phase 4 `InventoryComponent` Boundary with Minimal Caller Churn (Stage 8 Option B)
* **Source Findings:** Stage 5 #1, Stage 6 #1, Stage 7 #1, Stage 8 #1, Stage 9 #2
* **Affected Document Lines:** `Lines 29, 90-93, 178-181, 384-390` (Phase 4: `src/components/inventory_component.gd`)
* **Problem:** The Goals and Phase 4 prose state that forwarding methods will be deleted from `InventoryComponent` and that `CombatStyleComponent` and `PreparationUIGreybox` will be rewritten to access `inventory_component.preparation_data`, yet neither caller is in the 25-file modification list and `TestPreparationManager` calls those methods directly on `InventoryComponent`.
* **Actionable Fix:**
  - Apply **Stage 8 Option B (Zero Caller Churn)**: update `Line 29`, `Lines 90-93`, `Lines 178-181`, and `Lines 384-390` to clarify that Phase 4 eliminates the 7 duplicated `@export` configuration fields and `_sync_parameters()` boilerplate on `InventoryComponent` by replacing them with `@export var preparation_data: PreparationData` (aliased to `manager`), while retaining the lightweight scene-connector delegator methods on `InventoryComponent` (`collect_reagent_from_world`, `try_craft_recipe`, `consume_charge_for_oil`, `trigger_campfire_rest`, `get_reagent_count`, `get_oil_charges`, `has_oil_charges`) so `CombatStyleComponent`, `PreparationUIGreybox`, and `TestPreparationManager` require zero breaking edits.

---

### 🟢 Nits

#### [ACT-07] Clear `_active_iframes` inside `HealthComponent.reset_health()`
* **Source Findings:** Stage 7 #4, Stage 8 #4
* **Affected Document Lines:** `Lines 105, 255`
* **Actionable Fix:** State explicitly in Phase 1 and Item #1 (`src/components/health_component.gd`) that `reset_health()` calls `revoke_invulnerability(&"")` (or `_active_iframes.clear()`) so entity resets clear all active invulnerability leases.

#### [ACT-08] Unify Method Name `Interactable.set_interaction_progress()` in CUJ 2
* **Source Findings:** Stage 7 #5, Stage 8 #5
* **Affected Document Lines:** `Line 55`
* **Actionable Fix:** Replace `Interactable.update_interaction()` on `Line 55` (CUJ 2) with `Interactable.set_interaction_progress(ratio)` to match the virtual contract defined in Phase 3 (`Line 154` and `Line 339`).

#### [ACT-09] Clarify Single-Source Signal Emission Between `PreparationData` and `InventoryComponent`
* **Source Findings:** Stage 9 #5
* **Affected Document Lines:** `Lines 176, 374, 388`
* **Actionable Fix:** Specify in Items #18 and #20 that `PreparationData` emits the domain signals (`reagent_count_changed`, `oil_charges_changed`, `oil_crafted`, `crafting_failed`, `active_oil_depleted`, `campfire_rest_completed`) inside its mutation methods (`add_reagent`, `set_oil_charges`, `craft_oil`, `consume_oil_charge`, `register_campfire_rest`), and `InventoryComponent` forwards them via signal connection without double-emitting inside its delegator methods.

#### [ACT-10] Note `src/entities/world/` Co-location Rationale and Expand `EGM` Provenance Acronym
* **Source Findings:** Stage 5 #6, Stage 6 #2, Stage 7 #6, Stage 8 #6
* **Affected Document Lines:** `Lines 144, 335, 434-436`
* **Actionable Fix:** Add a brief note in Phase 3 (`Line 144`) stating that `src/entities/world/interactable.gd` co-locates with existing `SPEC-003`/`SPEC-004` world scripts to preserve `.tscn` UIDs/paths, and expand `EGM` to `Elephant-Goldfish Methodology (EGM)` at `Line 436`.

---

## 3. Cross-Stage Traceability Matrix

| Raw Stage Finding | Reviewer Lens | Severity | Consolidated Action Item | Status |
| :--- | :--- | :---: | :--- | :---: |
| **Stage 9 #1** (`get_parent()` violation & synchronous transition check) | `egm-codebase-details`, `egm-implementation-readiness` | 🔴 Blocker | **[ACT-01]** `State.is_active` transition check | Mapped |
| **Stage 5 #2** (`can_cancel_into_dodge()` on generic `State`) | `egm-inventive-catalyst` | 🟡 Major | **[ACT-02]** `State.can_be_interrupted_by()` | Mapped |
| **Stage 8 #2** (Generic `can_be_interrupted_by()` endorsement) | `egm-zoom-out` | 🟡 Major | **[ACT-02]** `State.can_be_interrupted_by()` | Mapped |
| **Stage 9 #4** (`PlayerDodgeState.is_invulnerable()` when `health_component == null`) | `egm-codebase-details` | 🟡 Major | **[ACT-03]** Retain local `_is_invulnerable` & signals | Mapped |
| **Stage 5 #3** (Magic constants in `compute_interactable_score`) | `egm-zoom-out` | 🟡 Major | **[ACT-04]** Parameterize scoring weights & wire `movement_component` | Mapped |
| **Stage 5 #5** (Missing `facing_direction` source in `PlayerInteractionComponent`) | `egm-zoom-out` | 🟢 Nit | **[ACT-04]** Parameterize scoring weights & wire `movement_component` | Mapped |
| **Stage 7 #2** (Missing `facing` source & `select_best_clue` contract) | `egm-design` | 🟡 Major | **[ACT-04]** Parameterize scoring weights & wire `movement_component` | Mapped |
| **Stage 7 #3** (Missing `@export` scoring weights — Constitution 1.2.4) | `egm-structural` | 🟡 Major | **[ACT-04]** Parameterize scoring weights & wire `movement_component` | Mapped |
| **Stage 8 #3** (Parameterize scoring constants & `facing_direction`) | `egm-zoom-out` | 🟡 Major | **[ACT-04]** Parameterize scoring weights & wire `movement_component` | Mapped |
| **Stage 9 #3** (Missing `movement_component` dependency in `PlayerInteractionComponent`) | `egm-codebase-details`, `egm-implementation-readiness` | 🟡 Major | **[ACT-04]** Parameterize scoring weights & wire `movement_component` | Mapped |
| **Stage 5 #4** (Polymorphic `Interactable` domain signal branching) | `egm-inventive-catalyst` | 🟡 Major | **[ACT-05]** Add `interaction_completed` & isolate legacy helper | Mapped |
| **Stage 5 #1** (`InventoryComponent` pass-through vs. caller list) | `egm-zoom-out` | 🟡 Major | **[ACT-06]** Align Phase 4 `InventoryComponent` scope (Option B) | Mapped |
| **Stage 6 #1** (`CombatStyleComponent` & `PreparationUIGreybox` omission) | `egm-comprehension` | 🟢 Nit | **[ACT-06]** Align Phase 4 `InventoryComponent` scope (Option B) | Mapped |
| **Stage 7 #1** (Ambiguous `InventoryComponent` pass-through removal) | `egm-design` | 🟡 Major | **[ACT-06]** Align Phase 4 `InventoryComponent` scope (Option B) | Mapped |
| **Stage 8 #1** (Minimal caller churn Option B verdict) | `egm-zoom-out` | 🟡 Major | **[ACT-06]** Align Phase 4 `InventoryComponent` scope (Option B) | Mapped |
| **Stage 9 #2** (Missing target entries or compatibility contract for callers) | `egm-implementation-readiness`, `egm-codebase-details` | 🟡 Major | **[ACT-06]** Align Phase 4 `InventoryComponent` scope (Option B) | Mapped |
| **Stage 7 #4** (`HealthComponent.reset_health()` clearing `_active_iframes`) | `egm-design` | 🟢 Nit | **[ACT-07]** Clear `_active_iframes` in `reset_health()` | Mapped |
| **Stage 8 #4** (`reset_health()` clause) | `egm-zoom-out` | 🟢 Nit | **[ACT-07]** Clear `_active_iframes` in `reset_health()` | Mapped |
| **Stage 7 #5** (`update_interaction()` vs `set_interaction_progress()`) | `egm-style` | 🟢 Nit | **[ACT-08]** Unify method name in CUJ 2 | Mapped |
| **Stage 8 #5** (Consistent method naming in CUJ 2) | `egm-zoom-out` | 🟢 Nit | **[ACT-08]** Unify method name in CUJ 2 | Mapped |
| **Stage 9 #5** (`PreparationData` single-source signal emission contract) | `egm-style`, `egm-implementation-readiness` | 🟢 Nit | **[ACT-09]** Clarify single-source signal forwarding | Mapped |
| **Stage 5 #6** (`src/entities/world/` vs `src/entities/interactables/`) | `egm-zoom-out` | 🟢 Nit | **[ACT-10]** Note `src/entities/world/` co-location & expand `EGM` | Mapped |
| **Stage 6 #2** (Undefined `EGM` acronym at line 436) | `egm-comprehension` | 🟢 Nit | **[ACT-10]** Note `src/entities/world/` co-location & expand `EGM` | Mapped |
| **Stage 7 #6** (`src/entities/world/` co-location note) | `egm-structural` | 🟢 Nit | **[ACT-10]** Note `src/entities/world/` co-location & expand `EGM` | Mapped |
| **Stage 8 #6** (Co-location note & `EGM` expansion) | `egm-zoom-out` | 🟢 Nit | **[ACT-10]** Note `src/entities/world/` co-location & expand `EGM` | Mapped |
