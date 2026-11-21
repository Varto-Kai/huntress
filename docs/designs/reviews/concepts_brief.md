# Architectural Deepening & Seam Consolidation (Huntress Godot 4.x)

* **Author:** Varto-Kai
* **Date:** 2026-11-20

## Overview

A structured, 4-phase refactoring initiative designed to eliminate cross-component coupling and shallow pass-through layers accumulated across features SPEC-001 through SPEC-004 in the Huntress codebase. The target is to establish deep, testable modules and clean polymorphic seams across the world interaction pipeline, entity invulnerability queries, finite state machine transition gates, and hunter preparation/alchemy data models, aligning the codebase strictly with the Project Constitution v1.1.0 and ensuring seamless extension into boss arenas and village contracts (SPEC-005+).

## Analysis

Across the multi-lens Goldfish review (`egm-design`, `egm-codebase-details`, `egm-zoom-out`, `egm-comprehension`, `egm-implementation-readiness`, `egm-structural`, `egm-inventive-catalyst`), the proposed architecture survived deep technical stress-testing with key refinements:

1. **Seam 1 (Polymorphic World Interaction - `Interactable`):**
   - **Current Flaw:** `PlayerInteractionComponent` manages three separate concrete arrays (`_overlapping_clues`, `_overlapping_reagents`, `_overlapping_campfires`) and procedurally branches in `try_start_interaction()`. Adding chests, doors, or traps requires modifying the player core.
   - **Solution:** Introduce an abstract base class `Interactable` (`Area2D`) defining a uniform interaction lifecycle (`can_interact`, `start_interaction`, `update_interaction`, `complete_interaction`, `cancel_interaction`, `set_focused`).
   - **Inventive Resolution (C1: Priority vs. Proximity):** If an urgent consumable lies at the player's feet during combat while a high-priority clue is 40px away, pure priority fails. We adopt a composite relevance score combining numeric priority (`@export var interaction_priority: int`), distance squared, and player facing direction alignment (`facing_direction.dot()`). Any damage, movement, or dodge cancels channeled interaction and resets progress to zero.

2. **Seam 2 (Combat Hurtbox & Centralized Invulnerability):**
   - **Current Flaw:** `HurtboxComponent` directly holds an `@export var dodge_state: PlayerDodgeState` and polls it. Monsters, bosses, and environmental entities cannot share `HurtboxComponent` without phantom player state references.
   - **Solution:** Strip `dodge_state` from `HurtboxComponent`. Centralize temporal invulnerability inside `HealthComponent` via tagged leases: `grant_invulnerability(duration: float, tag: StringName = &"")` and `is_invulnerable(tag: StringName = &"") -> bool`.
   - **Inventive Opportunity (C2: Tagged i-frames):** Attacks (`AttackData`) can carry a `pierces_tags` array. A colossal boss grab can pierce `&"dodge"` while respecting `&"parry"`. Semantic greybox visuals listen to `invulnerability_granted(duration, tag)` to render appropriate visual feedback (e.g., cyan for dodge, flashing white for damage post-hit).

3. **Seam 3 (StateMachine Decoupling & Transition Preconditions):**
   - **Current Flaw:** `PlayerIdleState`, `PlayerMoveState`, and `PlayerAttackState` inject `@export var dodge_state: PlayerDodgeState` and poll `dodge_state.can_dodge()`, violating sibling state isolation.
   - **Solution:** Remove sibling references. Introduce a virtual precondition method `can_enter(from_state: State) -> bool` on `State`. `StateMachine.transition_to()` checks `target_state.can_enter(current_state)` before executing the transition.
   - **Inventive Resolution (C3: Buffer Retention):** The input component retains buffered actions for a 0.15s tolerance window. If `can_enter()` rejects the transition immediately (e.g., during active attack frames), the buffer remains alive until the window opens or expires.

4. **Seam 4 (Preparation & Inventory as Custom Resource - `PreparationData`):**
   - **Current Flaw:** `PreparationManager` is a pure `RefCounted` class wrapped by `InventoryComponent` using redundant 1:1 pass-through methods and parameter synchronization.
   - **Solution:** Convert `PreparationManager` into `PreparationData` (`class_name PreparationData extends Resource`). `InventoryComponent` holds `@export var preparation_data: PreparationData` and exposes it directly. Pure unit tests run against `PreparationData.new()` in headless memory, while Godot saves use schema-validated JSON via `to_dict()` and `from_dict()`.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  - Create `Interactable` base class and migrate `InteractableClue`, `InteractableReagent`, and `InteractableCampfire` to satisfy the interface.
  - Decouple `HurtboxComponent` by eliminating `dodge_state` and implementing tagged invulnerability timers in `HealthComponent`.
  - Refactor `StateMachine` and `PlayerDodgeState` to evaluate admission via `can_enter(from_state)`, removing sibling references from Idle, Move, and Attack states.
  - Transform `PreparationManager` into `PreparationData` (`Resource`), deleting pass-through methods in `InventoryComponent`.
  - Maintain 100% pass rate across existing unit tests (`tests/unit/`) and greybox sandbox scenes (`tests/sandboxes/`).

* **Out-of-Scope Non-Goals:**
  - Modifying damage formulas, combat styles, or oil recipes.
  - Creating new visual assets or replacing greybox polygon shaders.
  - Introducing new input devices, UI redesigns, or multiplayer networking.
  - Building new gameplay mechanics outside the existing SPEC-001 through SPEC-004 vertical slice requirements.

## Alternatives Weighed

- **Single Massive Monolithic Refactor:** Rejected by author. Touches too many core nodes simultaneously, introducing high risk of untraceable regressions across physics, combat, and UI sandboxes.
- **External InvulnerabilityComponent:** Rejected by author in favor of centralizing in `HealthComponent`. Avoids adding another node to every entity scene while ensuring life and damage-reception invariants live together.
- **Passing State References to Siblings:** Rejected by author. Violates the Component and State patterns established in Constitution v1.1.0 and increases cognitive load when adding new states.
- **Pure RefCounted without Resource:** Rejected by author. Kept `InventoryComponent` acting as a shallow wrapper without providing inspector benefits or native `.tres` serialization.

## Key Decisions & Staging for Next Steps

1. **Execution Sequence (Dependency Order):**
   - **Phase 1:** Seam 2 (Combat Hurtbox & Tagged Invulnerability in `HealthComponent`).
   - **Phase 2:** Seam 3 (StateMachine Decoupling & `can_enter()` Preconditions).
   - **Phase 3:** Seam 1 (Polymorphic `Interactable` base class and composite relevance score).
   - **Phase 4:** Seam 4 (`PreparationData` Resource conversion and pass-through elimination).
2. **Implementation Invariants (From Goldfish Review):**
   - **Composite Relevance Focus (`Interactable`):** Focus arbitration must score candidates by combining numeric priority (`@export var interaction_priority: int`), distance squared, and `facing_direction.dot()` alignment so items at the player's feet remain reachable without sacrificing clue priority at equivalent distances.
   - **Zero-Frame Dodge Cancel Parity (`StateMachine`):** `PlayerDodgeState.can_enter(from_state)` must inspect attack sub-phases (`WINDUP` and `RECOVERY` allowed, `ACTIVE` blocked) while preserving the 0.15s input buffer tolerance window.
   - **Resource Instance Isolation (`PreparationData`):** `InventoryComponent` must invoke `preparation_data.duplicate()` on initialization so runtime mutations in one scene or sandbox do not pollute shared `.tres` catalog instances in memory.
3. **Quality Gates & Verification:**
   - Each phase must pass the existing headless unit test runner (`tests/unit/run_tests.gd`) and verify corresponding sandbox scenes (`sandbox_player_movement`, `sandbox_combat`, `sandbox_investigation`).

