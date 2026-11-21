# Goldfish Review Report (Stage 5 — Initial Zoom Out & Inventive Catalyst)

**Target:** `c:/Users/Victor/Documents/DEV/Huntress/huntress/docs/designs/architectural-deepening-seam-consolidation.md` (`Lines 1..436`)

## Reviewer Status

| Reviewer | Status |
| --- | --- |
| `egm-zoom-out` | completed |
| `egm-inventive-catalyst` | completed |

**Severity Breakdown:** 0 Blockers, 4 Major, 2 Nits

---

## Prioritized Findings (Blockers -> Major -> Nits)

### 1. Residual Pass-Through Methods vs. Goal of Eliminating `InventoryComponent` Wrappers - Severity: Major
* **Reviewer Lens:** `egm-zoom-out`
* **Affected Scope:** `Lines 29, 90-93, 178-181, 384-390`
* **Discrepancy Description:** In **Goals** (`Line 29`), the design commits to *"remove one-to-one forwarding methods from `InventoryComponent`"*, and the Architecture diagram (`Lines 90-93`) shows `CombatStyleComponent -- "queries / consumes charges" --> PreparationData (Resource)`. However, the **Detailed Implementation Plan** for `InventoryComponent` (`Lines 384-390`) does not specify which forwarding methods (`get_reagent_count`, `get_oil_charges`, `has_oil_charges`, `consume_charge_for_oil`, `get_hidden_alert_level`) are deleted versus retained, nor does the target file list include `src/components/combat_style_component.gd`, `src/ui/preparation_ui_greybox.gd`, or `tests/unit/test_preparation_manager.gd` callers that currently invoke those wrapper methods on `InventoryComponent`.
* **Rationale & Recommendation:** Clarify the exact boundary of `InventoryComponent` in Phase 4. Either:
  1. Explicitly list `src/components/combat_style_component.gd` and `src/ui/preparation_ui_greybox.gd` in the **Detailed Implementation Plan** to migrate their calls to `inventory_component.preparation_data`, and specify which thin convenience delegators remain on `InventoryComponent` for backward compatibility with existing tests (`TestPreparationManager`), **or**
  2. Scope `InventoryComponent` as the thin scene-tree signal/lifecycle connector that delegates to `preparation_data` while eliminating only the duplicated `@export` configuration fields and `_sync_parameters()` boilerplate, updating the Goal statement (`Line 29`) so architecture and implementation match 100%.

### 2. Action-Specific `can_cancel_into_dodge()` on Generic `State` Base Class - Severity: Major
* **Reviewer Lens:** `egm-inventive-catalyst`
* **Affected Scope:** `Lines 120-137, 279-299`
* **Discrepancy Description:** Phase 2 removes the sibling reference `@export var dodge_state: PlayerDodgeState` from `PlayerIdleState`, `PlayerMoveState`, and `PlayerAttackState` by introducing `can_enter(from_state: State) -> bool` on `State`. However, it also adds `func can_cancel_into_dodge() -> bool: return true` directly to the generic `State` base class (`src/state_machine/state.gd`, `Line 125` and `Line 283`). `StateMachine` and `State` are intended to be entity-agnostic (reused across the Player, minor monsters, and `SPEC-005` Boss AI). Embedding a player-dodge-specific query (`can_cancel_into_dodge()`) in the universal `State` base class re-introduces concrete action vocabulary into the abstract state machine layer and will not scale cleanly when `ParryState`, `StunState`, or `UseToolState` are added.
* **Rationale & Recommendation:** Generalize the cancellation query on `State` to `func can_be_interrupted_by(target_state_name: StringName) -> bool: return true` (or `func can_transition_to(target_state_name: StringName) -> bool: return true`). In `PlayerAttackState`, override this method to block `&"DodgeState"` during `Phase.ACTIVE` while allowing forced interruptions like `&"HurtState"`. `PlayerDodgeState.can_enter(from_state)` then checks `from_state == null or from_state.can_be_interrupted_by(&"DodgeState")`, keeping `src/state_machine/state.gd` 100% domain-agnostic.

### 3. Unparameterized Magic Constants in `PlayerInteractionComponent` Composite Score Formula - Severity: Major
* **Reviewer Lens:** `egm-zoom-out`
* **Affected Scope:** `Lines 164-170, 363-369`
* **Discrepancy Description:** Phase 3 specifies the composite relevance formula in `PlayerInteractionComponent` (`Lines 164-169`):
  $$\text{Score} = (P \times 10.0) + \text{foot\_bonus} + (\text{align} \times 20.0) - (d^2 \times 0.05)$$
  with hardcoded constants (`10.0` priority weight, `1200.0` foot bonus, `144.0` / `12 px` foot radius squared, `20.0` alignment weight, and `0.05` distance-squared penalty). Project Constitution v1.1.0 Section 1.2.4 (*Game Feel 100% Parametrizado*) strictly forbids hardcoded magic numbers in gameplay feel and spatial arbitration logic. Furthermore, because `compute_interactable_score` is proposed as a `static func` (`Line 367`), instance `@export` weights would not be accessible unless passed or defined via constants/config.
* **Rationale & Recommendation:** Expose the scoring weights/thresholds as named constants (`const PRIORITY_WEIGHT: float = 10.0`, `const FOOT_ZONE_RADIUS_SQ: float = 144.0`, `const FOOT_ZONE_BONUS: float = 1200.0`, `const FACING_ALIGNMENT_WEIGHT: float = 20.0`, `const DISTANCE_SQ_PENALTY: float = 0.05`) alongside `@export_group("Focus Scoring Weights")` properties on `PlayerInteractionComponent` (with default values matching the constants for static helper calls). This satisfies Constitution Section 1.2.4 while preserving static testability.

### 4. Polymorphic `Interactable` Seam Still Branches on Concrete Subclasses for Domain Signal Emission - Severity: Major
* **Reviewer Lens:** `egm-inventive-catalyst`
* **Affected Scope:** `Lines 144-171, 335-369`
* **Discrepancy Description:** Phase 3 states that `PlayerInteractionComponent` will *"deepen so new world interactables require zero changes to the player interaction script"* (`Line 368`), while also stating it will emit *"existing domain signals (`clue_inspection_completed`, `reagent_collected_from_world`, `campfire_interacted`) for backward compatibility"* (`Line 367`). Currently (`src/components/player_interaction_component.gd`, `Lines 69-81, 168-171`), those three signals carry concrete subclass payloads (`ClueData`, `ReagentData + amount`, `InteractableCampfire`). If `PlayerInteractionComponent` must inspect `if target is InteractableClue` / `elif target is InteractableReagent` / `elif target is InteractableCampfire` after `complete_interaction()` to emit those specific signals, it retains procedural type-branching across concrete world subclasses.
* **Rationale & Recommendation:** Introduce a generic domain-agnostic signal on `PlayerInteractionComponent`:
  `signal interaction_completed(interactable: Interactable, payload: Variant)`
  and let `Interactable.complete_interaction(interactor: Node2D) -> Variant` emit an `interacted(interactor: Node2D, result: Variant)` signal on the `Interactable` itself (while keeping a localized compatibility adapter or virtual notification hook `on_completed_by_player(interaction_component: PlayerInteractionComponent)` overridden by the three legacy subclasses to emit `clue_inspection_completed`, `reagent_collected_from_world`, and `campfire_interacted`). That way, `PlayerInteractionComponent` never performs `is InteractableClue / Reagent / Campfire` checks in its core lifecycle.

### 5. Missing `facing_direction` Source in `PlayerInteractionComponent` - Severity: Nit
* **Reviewer Lens:** `egm-zoom-out`
* **Affected Scope:** `Lines 164-170, 321-327, 363-369`
* **Discrepancy Description:** `PlayerInteractionComponent.compute_interactable_score(origin: Vector2, facing: Vector2, target: Interactable)` requires the player's `facing` vector during `_refresh_focused_targets()`. Currently, `PlayerInteractionComponent` holds references only to `state_machine: StateMachine` and `input_component: PlayerInputComponent` (`src/components/player_interaction_component.gd`, `Lines 16-17`), while `facing_direction` lives on `MovementComponent` (`movement_component.facing_direction`). The design does not mention injecting `movement_component: MovementComponent` into `PlayerInteractionComponent` inside `player.gd`.
* **Rationale & Recommendation:** Note in the **Detailed Implementation Plan** for `src/components/player_interaction_component.gd` (#17) and `src/entities/player/player.gd` (#11) that `interaction_component.movement_component = movement_component` is wired (falling back to `input_component.move_direction` or `Vector2.DOWN` when `movement_component == null` in isolated unit tests).

### 6. Folder Convention Note: `src/entities/world/` vs. Constitution `src/entities/interactables/` - Severity: Nit
* **Reviewer Lens:** `egm-zoom-out`
* **Affected Scope:** `Lines 144, 335-362`
* **Discrepancy Description:** Constitution Section 4.2 (`docs/CONSTITUICAO.md`, `Line 167`) illustrates `src/entities/interactables/` in the reference folder tree, whereas the repository currently places `interactable_clue.gd`, `interactable_reagent.gd`, and `interactable_campfire.gd` under `src/entities/world/`. Placing the new `interactable.gd` base class in `src/entities/world/interactable.gd` (`Line 335`) is consistent with the actual codebase, but the discrepancy with the Constitution diagram is undocumented.
* **Rationale & Recommendation:** Add a brief note in Phase 3 confirming that `src/entities/world/interactable.gd` co-locates with existing `SPEC-003` and `SPEC-004` world interactables to avoid breaking `.tscn` script UIDs/paths.
