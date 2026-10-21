# 🔬 Pesquisa Técnica e Decisões de Design: `SPEC-003` (Investigação e Grimório Dinâmico)

**Feature**: `specs/003-investigation-grimoire`  
**Data**: 2026-10-21

---

## 1. Detecção de Pistas e Seleção Determinística (`EC-001`)

- **Desafio**: Em zonas de investigação densas, duas ou mais pistas (`InteractableClue`) podem estar dentro do raio do `PlayerInteractionComponent` (`Area2D`) ao mesmo tempo.
- **Solução**:
  - `InteractableClue` herda de `Area2D` e opera em uma camada de colisão dedicada (`collision_layer = 8` / Layer 4: Interactables).
  - `PlayerInteractionComponent` mantém um array tipado `_overlapping_clues: Array[InteractableClue]` atualizado via `area_entered` / `area_exited`.
  - A função pura `select_best_clue(origin: Vector2, candidates: Array[InteractableClue]) -> InteractableClue` prioriza:
    1. Pistas com `is_inspected == false` antes de pistas já inspecionadas;
    2. Menor `global_position.distance_squared_to(origin)`.
  - Isso garante determinismo total e permite teste unitário direto sem depender de física assíncrona.

---

## 2. Canalização Curta Cancelável (`inspect_duration` — `Q2` / `RF-002` / `EC-003`)

- **Desafio**: Inspecionar uma pista deve ter peso tátil (`0.5s` por padrão com barra de progresso *Greybox*), mas nunca pode travar a Caçadora caso ela precise esquivar ou se afastar, nem continuar rodando se ela sofrer dano.
- **Solução**:
  - Quando o jogador aciona `interact` estando em `IdleState` ou `MoveState` (`EC-004`) e com um `focused_clue` válido:
    - Se `inspect_duration <= 0.0`, a coleta ocorre instantaneamente no mesmo frame.
    - Caso contrário, `PlayerInteractionComponent` inicia `_inspecting_clue` e incrementa `_inspect_elapsed += delta`.
  - **Condições de Cancelamento Imediato**:
    1. A Caçadora sai de `IdleState`/`MoveState` (ex.: entra em `DodgeState`, `AttackState` ou `HurtState` ao sofrer dano);
    2. A pista deixa de ser a candidata em alcance (`area_exited` ou afastamento);
    3. O jogador pressiona movimento para fora do raio.
  - Ao cancelar, `_inspect_elapsed` zera e `inspection_cancelled` é emitido, limpando a barra de progresso no `InteractableClue`.

---

## 3. Pistas Falsas (*Red Herrings*), Julgamento Manual e Fórmulas de Óleos (`Q5` / `RF-004` / `RF-005`)

- **Desafio**: Evitar o "modo automático sem pensar" de *The Witcher 3*, punindo o jogador desatento (que pode fabricar o Óleo errado na `SPEC-004`) e recompensando o jogador que lê e cruza as evidências.
- **Solução Arquitetural (`GrimoireTracker`)**:
  - Cada `ClueData` define:
    - `clue_id: StringName`
    - `monster_id: StringName`
    - `section_type: GrimoireTypes.SectionType` (`STYLE_MATCHUP`, `ELEMENT_OIL_RECIPE`, `BEHAVIOR_STAGGER`)
    - `is_false_lead: bool` (oculto da UI — a UI nunca mostra um rótulo "PISTA FALSA" automático!)
    - `reported_style: CombatTypes.StyleType` / `reported_element_oil: CombatTypes.ElementOil` / `reported_oil_recipe: String` / `reported_summary: String`.
  - **Regra de Resolução da Síntese por Seção (`resolve_section_state`)**:
    - Consideram-se apenas as pistas **coletadas** e **não descartadas manualmente pelo jogador** (`not is_clue_discarded(clue_id)`) daquela seção:
    - Se **nenhuma** pista ativa existir na seção $\rightarrow$ Estado `UNKNOWN` (`???`).
    - Se existir **qualquer pista falsa ativa (`is_false_lead == true`)** na seção $\rightarrow$ A pista falsa **contamina a síntese ativa**, exibindo a recomendação enganosa da pista falsa (e marcando internamente `is_accurate = false`, além de sinalizar na UI se houver múltiplas pistas ativas na mesma seção para instigar o jogador a investigar a contradição).
    - Se **apenas a pista verdadeira (`is_false_lead == false`)** estiver ativa na seção (porque o jogador descartou a pista falsa via `toggle_clue_discarded(clue_id)`) $\rightarrow$ A seção resolve a **Síntese Verdadeira** (`is_accurate = true`), revelando o Estilo exato, o Comportamento de Stagger ou a **Fórmula de Materiais do Óleo Fabricável**!
  - Quando todas as 3 seções do monstro estão resolvidas com precisão (`is_accurate == true`), `GrimoireTracker` emite `monster_research_completed(monster_id)`.
