# Goldfish Review Report (Stage 8 — Intermediate Zoom Out Review)

**Target:** `c:/Users/Victor/Documents/DEV/Huntress/huntress/docs/designs/architectural-deepening-seam-consolidation.md` (`Lines 1..436`)

## Reviewer Status

| Reviewer | Status |
| --- | --- |
| `egm-zoom-out` | completed |

**Severity Breakdown:** 0 Blockers, 3 Major, 3 Nits

---

## High-Level Synthesis of Stage 5, Stage 6, and Stage 7 Findings (Simplicity, Minimalism & YAGNI Audit)

Evaluating the aggregated findings from `zoom_out_report.md`, `comprehension_report.md`, and `critic_report.md` through the `zoom-out-standard` lens shows strong alignment across all stages, with two key recommendations where **minimalism and YAGNI must govern the chosen resolution option**:

1. **`InventoryComponent` Boundary (Stage 5 #1, Stage 6 #1, Stage 7 #1) — Choose Option B (Zero Caller Churn):**
   - Stages 5 and 7 offered two resolution paths: (Option A) expanding the file modification blast radius to rewrite `CombatStyleComponent`, `PreparationUIGreybox`, and `TestPreparationManager` callers, or (Option B) scoping Phase 4 to eliminate the duplicated `@export` parameter fields and `_sync_parameters()` boilerplate on `InventoryComponent` in favor of `@export var preparation_data: PreparationData` (aliased to `manager`), while keeping the existing thin delegator methods on `InventoryComponent`.
   - **Zoom-Out Verdict:** **Choose Option B.** Keeping `InventoryComponent` as the thin `Node` facade over `preparation_data` removes the duplicated `@export` synchronization debt while keeping `CombatStyleComponent`, `PreparationUIGreybox`, and `TestPreparationManager` untouched (zero cross-system churn, strict YAGNI compliance).
2. **`State` Cancellation Contract (Stage 5 #2) — Simple Generic Virtual Method:**
   - Replacing `can_cancel_into_dodge() -> bool` on `State` (`src/state_machine/state.gd`) with `can_be_interrupted_by(target_state_name: StringName) -> bool: return true` keeps the core FSM 100% entity- and action-agnostic with zero extra classes or indirection.
3. **Polymorphic `Interactable` Signal Dispatch (Stage 5 #4) — Avoid Double-Dispatch Bloat:**
   - Stage 5 #4 noted that emitting legacy signals (`clue_inspection_completed`, `reagent_collected_from_world`, `campfire_interacted`) from `PlayerInteractionComponent` could reintroduce `is InteractableClue` branching, and suggested adding both `signal interaction_completed(interactable, payload)`, an `interacted` signal on `Interactable`, and a virtual `on_completed_by_player(interaction_component)` callback hook.
   - **Zoom-Out Verdict:** **Trim the over-engineering.** A circular callback (`Interactable.on_completed_by_player(PlayerInteractionComponent)`) would couple the base `Interactable` class back to `PlayerInteractionComponent`. Instead, simply add `signal interaction_completed(interactable: Interactable, payload: Variant)` on `PlayerInteractionComponent` as the primary polymorphic seam, and isolate legacy signal emission in a single 6-line compatibility helper (`_emit_legacy_domain_signal(target, payload)`) until `SPEC-006` UI consolidation.
4. **Parameterized Scoring Constants & Facing Vector Source (Stage 5 #3 & #5, Stage 7 #2 & #3) — Approved without Bloat:**
   - Defining named `const` default weights + `@export_group("Focus Scoring Weights")` on `PlayerInteractionComponent` and wiring an optional `movement_component: MovementComponent` reference (with `Vector2.DOWN` fallback) resolves the Constitution Section 1.2.4 violation and missing data flow cleanly.

---

## Prioritized Findings (Blockers -> Major -> Nits)

### 1. Align `InventoryComponent` Phase 4 Scope with Minimal Caller Churn (Option B) - Severity: Major
* **Reviewer Lens:** `egm-zoom-out` (consolidating Stage 5 #1, Stage 6 #1, Stage 7 #1)
* **Affected Scope:** `Lines 29, 90-93, 178-181, 384-390`
* **Discrepancy Description:** `Line 29` (Goals) and `Line 181` (Phase 4) state that one-to-one forwarding methods will be deleted from `InventoryComponent` and that `CombatStyleComponent` and `PreparationUIGreybox` will be updated to read `inventory_component.preparation_data` directly, yet neither file is in the 25-file Detailed Implementation Plan (`Lines 249-425`), and `TestPreparationManager` calls those methods directly on `InventoryComponent`.
* **Rationale & Recommendation:** Apply **Option B** for architectural minimalism: update `Line 29`, `Lines 90-93`, `Lines 178-181`, and `Lines 384-390` to specify that Phase 4 eliminates the duplicated `@export` configuration properties and `_sync_parameters()` synchronization boilerplate on `InventoryComponent` by introducing `@export var preparation_data: PreparationData` (with `var manager: PreparationData` retained as an alias property), while retaining the lightweight domain delegation methods on `InventoryComponent` (`collect_reagent_from_world`, `try_craft_recipe`, `consume_charge_for_oil`, `trigger_campfire_rest`, `get_reagent_count`, `get_oil_charges`, `has_oil_charges`) so `CombatStyleComponent`, `PreparationUIGreybox`, and `TestPreparationManager` require zero breaking caller edits.

### 2. Replace Action-Specific `can_cancel_into_dodge()` on Generic `State` Base Class with `can_be_interrupted_by(target_state_name: StringName)` - Severity: Major
* **Reviewer Lens:** `egm-zoom-out` (consolidating Stage 5 #2)
* **Affected Scope:** `Lines 123-137, 279-299, 314-320`
* **Discrepancy Description:** Phase 2 adds `func can_cancel_into_dodge() -> bool: return true` directly to `src/state_machine/state.gd` (`Line 125`, `Line 283`). Putting player-dodge terminology into the universal `State` base class violates domain decoupling and would require adding more action-specific methods (`can_cancel_into_parry()`, etc.) in future specs.
* **Rationale & Recommendation:** Replace `func can_cancel_into_dodge() -> bool` on `State` with `func can_be_interrupted_by(_target_state_name: StringName) -> bool: return true`. In `PlayerAttackState`, override `can_be_interrupted_by(target_state_name: StringName) -> bool` to return `current_phase == Phase.WINDUP or current_phase == Phase.RECOVERY` when `target_state_name == &"DodgeState"` (and `true` otherwise). In `PlayerDodgeState.can_enter(from_state: State) -> bool`, check `from_state == null or from_state.can_be_interrupted_by(&"DodgeState")`.

### 3. Parameterize Interaction Scoring Constants and Specify `facing_direction` Resolution in `PlayerInteractionComponent` - Severity: Major
* **Reviewer Lens:** `egm-zoom-out` (consolidating Stage 5 #3 & #5, Stage 7 #2 & #3)
* **Affected Scope:** `Lines 162-171, 321-327, 363-369`
* **Discrepancy Description:** Phase 3 (`Lines 164-169`) embeds raw numeric literals (`10.0`, `1200.0`, `144.0`, `20.0`, `0.05`) in `compute_interactable_score()`, violating Project Constitution v1.1.0 Section 1.2.4 (*Game Feel 100% Parametrizado*), and requires a `facing: Vector2` argument without specifying how `PlayerInteractionComponent` accesses `movement_component.facing_direction` or what `select_best_clue(origin, candidates)` passes as the default facing vector.
* **Rationale & Recommendation:**
  1. Declare named default constants (`DEFAULT_PRIORITY_WEIGHT = 10.0`, `DEFAULT_FOOT_ZONE_RADIUS_SQ = 144.0`, `DEFAULT_FOOT_ZONE_BONUS = 1200.0`, `DEFAULT_ALIGNMENT_WEIGHT = 20.0`, `DEFAULT_DISTANCE_SQ_PENALTY = 0.05`) and matching `@export_group("Focus Scoring Weights")` properties on `PlayerInteractionComponent`.
  2. Wire `@export var movement_component: MovementComponent` on `PlayerInteractionComponent` in `player.gd` (falling back to `input_component.move_direction` or `Vector2.DOWN` when `movement_component == null` in unit tests, and passing `Vector2.DOWN` with `alignment_weight = 0.0` in the `select_best_clue` compatibility wrapper).
  3. Add `signal interaction_completed(interactable: Interactable, payload: Variant)` to `PlayerInteractionComponent` as the unified completion signal while isolating legacy domain signal emission (`clue_inspection_completed`, `reagent_collected_from_world`, `campfire_interacted`) to a localized compatibility helper rather than introducing circular double-dispatch hooks on `Interactable`.

### 4. Clear `_active_iframes` on `HealthComponent.reset_health()` - Severity: Nit
* **Reviewer Lens:** `egm-zoom-out` (consolidating Stage 7 #4)
* **Affected Scope:** `Lines 100-109, 251-256`
* **Discrepancy Description:** Phase 1 does not explicitly note that `HealthComponent.reset_health()` clears `_active_iframes` (via `revoke_invulnerability(&"")`).
* **Rationale & Recommendation:** Add a brief clause in Phase 1 (`Line 105` and `Line 255`) stating that `reset_health()` calls `revoke_invulnerability(&"")` so entity resets never retain stale i-frame leases.

### 5. Consistent Method Naming (`set_interaction_progress`) in CUJ 2 - Severity: Nit
* **Reviewer Lens:** `egm-zoom-out` (consolidating Stage 7 #5)
* **Affected Scope:** `Lines 55, 154, 339`
* **Discrepancy Description:** CUJ 2 (`Line 55`) refers to `Interactable.update_interaction()`, whereas Phase 3 (`Line 154`, `Line 339`) defines the virtual method as `Interactable.set_interaction_progress(_ratio: float) -> void`.
* **Rationale & Recommendation:** Update `Line 55` in CUJ 2 to reference `Interactable.set_interaction_progress()` for 100% terminology consistency.

### 6. Document `src/entities/world/` Co-location Note & Define `EGM` Provenance Acronym - Severity: Nit
* **Reviewer Lens:** `egm-zoom-out` (consolidating Stage 5 #6, Stage 6 #2, Stage 7 #6)
* **Affected Scope:** `Lines 144, 335, 434-436`
* **Discrepancy Description:** Phase 3 places `interactable.gd` in `src/entities/world/` (matching existing `interactable_*.gd` files rather than the illustrative `src/entities/interactables/` path in Constitution Section 4.2) without a brief note, and `Line 436` uses the acronym `EGM` without expansion.
* **Rationale & Recommendation:** Add a parenthetical note at `Line 144` confirming `src/entities/world/interactable.gd` co-locates with existing world entity scripts to preserve `.tscn` paths, and expand `EGM` to `Elephant-Goldfish Methodology (EGM)` at `Line 436`.
