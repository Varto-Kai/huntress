# Goldfish Annotated Review Report

**Status:** resolved
**Target:** `docs/designs/architectural-deepening-seam-consolidation.md` (`Lines 1-436`)

## Prioritized Findings & AI Suggestions

### [ACT-01: Synchronous State Transition Detection via `State.is_active` Instead of `get_parent()`] [`egm-codebase-details`, `egm-implementation-readiness`] - Severity: Blocker
*   **Affected Scope:** [Lines 122-141, 279-320](docs/designs/architectural-deepening-seam-consolidation.md#L122-L320) (`Phase 2: StateMachine Transition Preconditions` & `Target Files #5, #6, #8, #9, #10`)
*   **Discrepancy Description:** Emitting `transition_requested.emit(self, &"DodgeState")` synchronously invokes `StateMachine.transition_to(&"DodgeState")`, which calls `PlayerDodgeState.enter()` and applies initial dodge velocity (`460.0 px/s`). If `PlayerIdleState.physics_update()` or `PlayerMoveState.physics_update()` does not return immediately when the transition succeeds, it falls through to `apply_friction(delta)` or `accelerate_in_direction(direction, delta)` on the same physics tick, overwriting the dodge velocity on frame 1. Conversely, in `PlayerAttackState._try_dodge_cancel()`, returning `true` unconditionally when `can_enter()` rejects the transition freezes `_phase_timer`. Finally, checking `get_parent().current_state != self` on Line 304 violates Project Constitution v1.1.0 Section 1.2.3 (*Call Down, Signal Up*).
*   **Rationale:** Adding `var is_active: bool = false` on `State` (toggled by `StateMachine` around `enter()` and `exit()`) allows states to inspect `if not is_active: return` without calling `get_parent()`.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** The critique identifies both a Constitution Section 1.2.3 violation (`get_parent()`) and a frame-1 physics overwrite bug during synchronous signal dispatch in Godot. Adding `is_active: bool` on `State` resolves both cleanly.
*   ***Proposed Edit:***
    *   Location: `Phase 2` (`Lines 122-140`) and `Target Files #5, #6, #8, #9, #10` (`Lines 279-320`)
    *   Change: Add `var is_active: bool = false` to `State` (`src/state_machine/state.gd`), updated by `StateMachine` (`current_state.is_active = false` before `exit()`, `next_state.is_active = true` before `enter()`). Replace `get_parent().current_state != self` in `PlayerIdleState`, `PlayerMoveState`, and `PlayerAttackState._try_dodge_cancel()` with `if not is_active: return` (and `return not is_active`).

### [ACT-02: Generalize `State.can_cancel_into_dodge()` to Domain-Agnostic `can_be_interrupted_by(target_state_name: StringName)`] [`egm-inventive-catalyst`, `egm-zoom-out`] - Severity: Major
*   **Affected Scope:** [Lines 123-137, 279-299, 314-320](docs/designs/architectural-deepening-seam-consolidation.md#L123-L320) (`Phase 2` & `Target Files #5, #7, #10`)
*   **Discrepancy Description:** Adding `func can_cancel_into_dodge() -> bool: return true` directly to `src/state_machine/state.gd` introduces player-dodge-specific terminology into the universal `State` base class intended for reuse across monsters and bosses.
*   **Rationale:** Generalizing the method to `func can_be_interrupted_by(_target_state_name: StringName) -> bool: return true` keeps `State` entity- and action-agnostic.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Valid architectural boundary critique. A parameterized `can_be_interrupted_by(target_state_name: StringName)` scales to future states (`ParryState`, `StunState`, boss states) without adding action-specific methods to `State`.
*   ***Proposed Edit:***
    *   Location: `Lines 125, 129, 135, 283, 297, 318`
    *   Change: Replace `can_cancel_into_dodge() -> bool` with `can_be_interrupted_by(target_state_name: StringName) -> bool` on `State`, overridden in `PlayerAttackState` (returning `current_phase == Phase.WINDUP or current_phase == Phase.RECOVERY` when `String(target_state_name).to_lower() == "dodgestate"`, and `true` otherwise) and queried by `PlayerDodgeState.can_enter(from_state)` via `from_state.can_be_interrupted_by(&"DodgeState")`.

### [ACT-03: Preserve Local `_is_invulnerable` and Signals in `PlayerDodgeState` for Headless StateMachine Tests] [`egm-codebase-details`] - Severity: Major
*   **Affected Scope:** [Lines 112-115, 293-299](docs/designs/architectural-deepening-seam-consolidation.md#L112-L299) (`Phase 1 #3` & `Target File #7: src/entities/player/states/player_dodge_state.gd`)
*   **Discrepancy Description:** `TestPlayerStateMachine._build_test_rig()` instantiates `PlayerDodgeState` without a `HealthComponent` (`health_component == null`) and asserts `dodge.is_invulnerable()`. In addition, `PlayerGreyboxVisual`, `sandbox_player_movement.gd`, and `sandbox_combat.gd` call `dodge_state.is_invulnerable()` and connect to `dodge_state.invulnerability_started` / `invulnerability_ended`.
*   **Rationale:** `PlayerDodgeState` must retain its local `_is_invulnerable` state, `is_invulnerable() -> bool` getter, and `invulnerability_started` / `invulnerability_ended` signals alongside delegating leases to `health_component` when `health_component != null`.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Verified against `tests/unit/test_player_state_machine.gd` (`Lines 147-169`). Retaining local `_is_invulnerable` and signals on `PlayerDodgeState` preserves 100% compatibility with isolated movement tests and greybox visuals.
*   ***Proposed Edit:***
    *   Location: `Lines 113-115` and `Lines 297-298`
    *   Change: Explicitly state that `PlayerDodgeState` keeps its local `_is_invulnerable` flag, `is_invulnerable() -> bool` method, and `invulnerability_started` / `invulnerability_ended` signals while also calling `health_component.grant_invulnerability(_invulnerability_duration, &"dodge")` and `revoke_invulnerability(&"dodge")` when `health_component != null`.

### [ACT-04: Parameterize Interaction Scoring Weights (`@export`) and Wire `movement_component` for `facing_direction`] [`egm-zoom-out`, `egm-structural`, `egm-design`, `egm-codebase-details`] - Severity: Major
*   **Affected Scope:** [Lines 162-171, 321-327, 363-369](docs/designs/architectural-deepening-seam-consolidation.md#L162-L369) (`Phase 3 #3` & `Target Files #11, #17`)
*   **Discrepancy Description:** Phase 3 embeds magic numeric literals (`10.0`, `1200.0`, `144.0`, `20.0`, `0.05`) in `compute_interactable_score()`, violating Constitution Section 1.2.4 (*Game Feel 100% Parametrizado*), and requires `facing: Vector2` without wiring `movement_component` into `PlayerInteractionComponent` or defining the `facing` fallback for `select_best_clue()`.
*   **Rationale:** Declare named default constants and matching `@export_group("Focus Scoring Weights")` properties on `PlayerInteractionComponent`, wire `interaction_component.movement_component = movement_component` in `Player._ready()` (with fallback to `input_component.move_direction` or `Vector2.DOWN`), and pass `alignment_weight = 0.0` in `select_best_clue()`.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Directly enforces Constitution Section 1.2.4 and specifies the missing data dependency (`movement_component.facing_direction`) and `select_best_clue` backward compatibility contract.
*   ***Proposed Edit:***
    *   Location: `Lines 164-170`, `Lines 325-326`, and `Lines 367-368`
    *   Change: Add named constants (`DEFAULT_PRIORITY_WEIGHT = 10.0`, `DEFAULT_FOOT_ZONE_RADIUS = 12.0`, `DEFAULT_FOOT_BONUS = 1200.0`, `DEFAULT_ALIGNMENT_WEIGHT = 20.0`, `DEFAULT_DISTANCE_SQ_PENALTY = 0.05`) and `@export_group("Focus Scoring Weights")` variables on `PlayerInteractionComponent`; wire `interaction_component.movement_component = movement_component` in `Player._ready()`; and specify `alignment_weight = 0.0` in `select_best_clue(origin, candidates)`.

### [ACT-05: Add Polymorphic `interaction_completed` Signal and Localize Legacy Signal Adapter in `PlayerInteractionComponent`] [`egm-inventive-catalyst`, `egm-zoom-out`] - Severity: Major
*   **Affected Scope:** [Lines 162-171, 363-369](docs/designs/architectural-deepening-seam-consolidation.md#L162-L369) (`Phase 3 #3` & `Target File #17`)
*   **Discrepancy Description:** Phase 3 states that `PlayerInteractionComponent` will emit legacy concrete signals (`clue_inspection_completed`, `reagent_collected_from_world`, `campfire_interacted`) without explaining how it avoids procedural subclass branching in its core interaction loop.
*   **Rationale:** Add `signal focused_interactable_changed(target: Interactable)` and `signal interaction_completed(target: Interactable, result: Variant)` as the primary polymorphic signals on `PlayerInteractionComponent`, and isolate legacy domain signal emission inside a single private compatibility helper `_emit_legacy_domain_signals(target: Interactable, result: Variant)`.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Provides a clean polymorphic signal surface for all new `SPEC-005`+ interactables while keeping legacy signal compatibility isolated in one private helper.
*   ***Proposed Edit:***
    *   Location: `Lines 163, 367`
    *   Change: Add `signal focused_interactable_changed(target: Interactable)` and `signal interaction_completed(target: Interactable, result: Variant)` to `PlayerInteractionComponent`, routing legacy signals (`clue_inspection_completed`, `reagent_collected_from_world`, `campfire_interacted`) through an isolated `_emit_legacy_domain_signals(target, result)` helper.

### [ACT-06: Align Phase 4 `InventoryComponent` Boundary with Minimal Caller Churn (Stage 8 Option B)] [`egm-zoom-out`, `egm-design`, `egm-comprehension`, `egm-implementation-readiness`] - Severity: Major
*   **Affected Scope:** [Lines 29, 90-93, 178-181, 384-390](docs/designs/architectural-deepening-seam-consolidation.md#L29-L390) (`Goals`, `Phase 4`, & `Target File #20`)
*   **Discrepancy Description:** `Line 29` and `Line 181` state that one-to-one forwarding methods will be deleted from `InventoryComponent` and that `CombatStyleComponent` and `PreparationUIGreybox` will be updated to read `inventory_component.preparation_data`, yet neither caller is in the 25-file modification list and `TestPreparationManager` calls those methods directly on `InventoryComponent`.
*   **Rationale:** Adopt Stage 8 Option B (Zero Caller Churn): eliminate the 7 duplicated `@export` parameter fields and `_sync_parameters()` boilerplate on `InventoryComponent` in favor of `@export var preparation_data: PreparationData` (aliased to `manager`), while keeping the lightweight scene-connector delegator methods on `InventoryComponent`.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Eliminates the duplicated Inspector configuration and parameter-sync debt while preserving 100% caller compatibility across `CombatStyleComponent`, `PreparationUIGreybox`, and `TestPreparationManager` without unnecessary cross-system churn.
*   ***Proposed Edit:***
    *   Location: `Line 29`, `Lines 90-93`, `Lines 178-181`, and `Lines 384-390`
    *   Change: Clarify that Phase 4 removes the 7 duplicated `@export` configuration fields and `_sync_parameters()` boilerplate from `InventoryComponent` in favor of `@export var preparation_data: PreparationData` (aliased to `manager`), while retaining the thin scene-connector delegator methods on `InventoryComponent` (`collect_reagent_from_world`, `try_craft_recipe`, `consume_charge_for_oil`, `trigger_campfire_rest`, `get_reagent_count`, `get_oil_charges`, `has_oil_charges`).

### [ACT-07: Clear `_active_iframes` inside `HealthComponent.reset_health()`] [`egm-design`, `egm-zoom-out`] - Severity: Nit
*   **Affected Scope:** [Lines 100-109, 251-256](docs/designs/architectural-deepening-seam-consolidation.md#L100-L256) (`Phase 1 #1` & `Target File #1`)
*   **Discrepancy Description:** Phase 1 does not explicitly note that `HealthComponent.reset_health()` clears `_active_iframes`.
*   **Rationale:** Clearing `_active_iframes` via `revoke_invulnerability(&"")` in `reset_health()` ensures entity resets never leave stale invulnerability leases active.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Prevents edge-case stale leases after campfire rests or sandbox resets.
*   ***Proposed Edit:***
    *   Location: `Lines 105, 255`
    *   Change: Specify that `HealthComponent.reset_health()` calls `revoke_invulnerability(&"")` to clear all active invulnerability leases.

### [ACT-08: Unify Method Name `Interactable.set_interaction_progress()` in CUJ 2] [`egm-style`, `egm-zoom-out`] - Severity: Nit
*   **Affected Scope:** [Line 55](docs/designs/architectural-deepening-seam-consolidation.md#L55) (`CUJ 2`)
*   **Discrepancy Description:** CUJ 2 (`Line 55`) refers to `Interactable.update_interaction()`, whereas Phase 3 (`Line 154`, `Line 339`) names the virtual method `Interactable.set_interaction_progress(ratio: float) -> void`.
*   **Rationale:** Align terminology across CUJ 2 and Phase 3.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Eliminates naming inconsistency between the user journey and the class contract.
*   ***Proposed Edit:***
    *   Location: `Line 55`
    *   Change: Replace `Interactable.update_interaction()` with `Interactable.set_interaction_progress()`.

### [ACT-09: Clarify Single-Source Signal Emission Between `PreparationData` and `InventoryComponent`] [`egm-style`, `egm-implementation-readiness`] - Severity: Nit
*   **Affected Scope:** [Lines 176, 374, 388](docs/designs/architectural-deepening-seam-consolidation.md#L176-L388) (`Phase 4` & `Target Files #18, #20`)
*   **Discrepancy Description:** Items #18 and #20 list domain signals on both `PreparationData` and `InventoryComponent` without stating which object originates the emission vs. forwards it.
*   **Rationale:** Specify that `PreparationData` emits the domain signals inside its mutation methods (`add_reagent`, `set_oil_charges`, `craft_oil`, `consume_oil_charge`, `register_campfire_rest`) and `InventoryComponent` connects to and re-emits them once per operation.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Prevents duplicate signal firing when `InventoryComponent` delegates mutations to `preparation_data`.
*   ***Proposed Edit:***
    *   Location: `Lines 176-181, 374-390`
    *   Change: State that `PreparationData` mutation methods emit the domain signals directly and `InventoryComponent` bridges those signals via connection without double-emitting inside its delegator methods.

### [ACT-10: Note `src/entities/world/` Co-location Rationale and Expand `EGM` Provenance Acronym] [`egm-zoom-out`, `egm-comprehension`, `egm-structural`] - Severity: Nit
*   **Affected Scope:** [Lines 144, 335, 434-436](docs/designs/architectural-deepening-seam-consolidation.md#L144-L436) (`Phase 3 #1` & `Provenance Footer`)
*   **Discrepancy Description:** Phase 3 places `interactable.gd` in `src/entities/world/` (co-located with existing `interactable_*.gd` files rather than the illustrative `src/entities/interactables/` path in Constitution Section 4.2) without a note, and Line 436 uses the acronym `EGM` without definition.
*   **Rationale:** Add a brief co-location note in Phase 3 and expand `EGM` to `Elephant-Goldfish Methodology (EGM)`.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Clears up both minor comprehension items for future readers.
*   ***Proposed Edit:***
    *   Location: `Lines 144, 434-436`
    *   Change: Add parenthetical note confirming `src/entities/world/interactable.gd` co-locates with existing `SPEC-003`/`SPEC-004` world scripts to preserve `.tscn` UIDs/paths, and expand `EGM` to `Elephant-Goldfish Methodology (EGM)`.
