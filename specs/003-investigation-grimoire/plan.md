# 🏗️ Plano Técnico de Implementação: Sistema de Investigação (Coleta de Pistas) e Grimório Dinâmico (Greybox)

**Diretório da Feature**: `specs/003-investigation-grimoire` | **Data**: 2026-10-21 | **Spec**: `specs/003-investigation-grimoire/spec.md`  
**Status no Ciclo SDD**: `[x] 4. Plano Técnico Elaborado (/speckit-plan)`  
**Constituição de Referência**: `.specify/memory/constitution.md` (v1.1.0)

---

## 1. Resumo Executivo

Este plano técnico projeta a arquitetura da **`SPEC-003` (Sistema de Investigação e Grimório Dinâmico em Greybox)** na Godot 4.x com GDScript estrito. A solução implementa a **Fase 1 (Investigação)** e a base intelectual da **Fase 2 (Preparação/Grimório)** do Core Loop:
1. Detecção física desacoplada via `PlayerInteractionComponent` (`Area2D`) e `InteractableClue` (`Area2D`) com seleção determinística da pista não coletada mais próxima (`EC-001`) e canalização curta cancelável (`inspect_duration = 0.5s`, `Q2`).
2. Motor dedutivo puro em `GrimoireTracker` (`RefCounted`) e `GrimoireComponent` (`Node`) com suporte a **Vínculo 1:1 por Seção (`Q1`)**, **Pistas Falsas (*Red Herrings*, `is_false_lead = true`)**, **Julgamento Manual do Jogador (`toggle_clue_discarded`, `Q5`)** e revelação da **Fórmula de Materiais de Óleos Fabricáveis** (preparando o terreno para o crafting da `SPEC-004`).
3. Interface *Greybox* em Tempo Real Tático (`GrimoireUIGreybox`, `Q3`) + sincronização de telemetria descoberta no HUD dos alvos (`CombatDummy`, `Q4`) sem bônus artificial de status.

---

## 2. Contexto Técnico e Arquitetura (Godot 4.x)

- **Engine & Linguagem**: Godot 4.x (v4.7.2) — GDScript Estrito (Tipagem Estática Obrigatória)
- **Camadas Envolvidas**:
  - **Camada Core & Dedução (`RefCounted`)**: `GrimoireTypes` (enums de seção e forma visual) e `GrimoireTracker` (lógica pura de registro idempotente, descarte manual de pistas falsas e resolução de síntese)
  - **Camada de Dados (`Resource`)**: `ClueData`, `MonsterGrimoireEntryData` e catálogo `.tres` de pistas autênticas e falsas em `res://src/data/`
  - **Camada de Componentes (`Node` / `Area2D`)**: `PlayerInteractionComponent` e `GrimoireComponent` acoplados à Caçadora; `InteractableClue` posicionável no mapa
  - **Camada de Interface & Validação (`CanvasLayer` / `Control` / `Node2D`)**: `GrimoireUIGreybox` (diário interativo + Toast de pista) e cena `SandboxInvestigation` (`res://tests/sandboxes/sandbox_investigation.tscn`)
- **Armazenamento / Dados**: `Custom Resources (.tres)` somente leitura em `res://src/data/`
- **Estratégia de Testes**: Suíte automatizada headless (`test_grimoire_tracker.gd` e `test_interaction_and_clues.gd` integrados ao `run_tests.gd`) + Cena `sandbox_investigation.tscn`
- **Meta de Performance**: 60 FPS estáveis, zero acoplamento direto (`get_node`) entre pistas do mapa e UI do Grimório (*Signals First*)

### 2.1. Árvore de Cenas e Composição de Nós (`Nodes`)

#### Entidade `Player` Expandida (`res://src/entities/player/player.tscn`)
```text
Player (CharacterBody2D)
├── ... (Nós existentes da SPEC-001 e SPEC-002)
├── PlayerInteractionComponent (Area2D — Layer 0, Mask 8 [Interactables])
│   └── CollisionShape2D (CircleShape2D — raio configurável via @export)
└── GrimoireComponent (Node — encapsula GrimoireTracker e emite sinais de descoberta)
```

#### Entidade `InteractableClue` (`res://src/entities/world/interactable_clue.tscn`)
```text
InteractableClue (Area2D — Layer 8 [Interactables], Mask 0)
├── CollisionShape2D (CircleShape2D)
├── ClueVisual (Polygon2D — muda cor por estado: Não Inspecionada / Focada / Inspecionada)
├── InspectProgressBarBg (ColorRect)
│   └── InspectProgressBarFill (ColorRect — preenche durante inspect_duration)
└── PromptLabel (Label — "[E] Inspecionar" / "[E] Reler")
```

### 2.2. Responsabilidade Única por Script / Componente

| Script / Cena | Tipo Base | Caminho (`res://`) | Responsabilidade Única (SRP) | Requisitos Atendidos |
| :--- | :--- | :--- | :--- | :--- |
| `GrimoireTypes` | `RefCounted` | `res://src/core/grimoire_types.gd` | Declarar enums tipados (`SectionType`, `ClueVisualShape`) e constantes de estado de seção. | `RF-004`, `RF-005` |
| `ClueData` | `Resource` | `res://src/data/clue_data.gd` | Definir os dados imutáveis de uma pista física (autêntica ou falsa `is_false_lead`), seção alvo e conclusões de Estilo, Óleo, Receita de Materiais e Comportamento. | `RF-002`, `RF-004`, `EC-005` |
| `MonsterGrimoireEntryData` | `Resource` | `res://src/data/monster_grimoire_entry_data.gd` | Agrupar metadados da criatura, `DefenseProfileData` e catálogo de `ClueData` daquela caçada. | `RF-004`, `RF-005`, `EC-005` |
| `GrimoireTracker` | `RefCounted` | `res://src/systems/grimoire_tracker.gd` | Processar de forma pura e determinística a coleta idempotente de pistas (`EC-002`), o descarte/restauração manual (`toggle_clue_discarded`, `EC-006`) e a resolução de cada seção (contaminada por pista falsa vs. solucionada com precisão). | `RF-004`, `RF-005`, `SC-001` |
| `GrimoireComponent` | `Node` | `res://src/components/grimoire_component.gd` | Expor `GrimoireTracker` como componente de cena na Caçadora, emitindo sinais Godot (`clue_discovered`, `clue_discard_toggled`, `entry_updated`, `monster_research_completed`). | `RF-003`, `RF-005` |
| `InteractableClue` | `Area2D` | `res://src/entities/world/interactable_clue.gd` | Representar um vestígio físico no mapa com feedback visual *Greybox* de foco, progresso de canalização e estado coletado. | `RF-002`, `RF-008` |
| `PlayerInteractionComponent` | `Area2D` | `res://src/components/player_interaction_component.gd` | Detectar `InteractableClue` em alcance, selecionar a pista não inspecionada mais próxima (`EC-001`), gerenciar a canalização `inspect_duration` e abortar se a Caçadora esquivar, afastar-se ou sofrer dano (`EC-003`, `EC-004`). | `RF-001`, `RF-002`, `EC-001`, `EC-003`, `EC-004`, `SC-002` |
| `GrimoireUIGreybox` | `Control` | `res://src/ui/grimoire_ui_greybox.gd` | Renderizar o painel do Grimório em Tempo Real Tático (`Q3`), cartões de pistas com botão `[Descartar / Restaurar]`, painel de Síntese (Estilo + Receita do Óleo Fabricável) e banner Toast de nova pista (`RF-007`). | `RF-006`, `RF-007`, `RF-008` |

---

## 3. Modelo de Dados, Sinais e Parâmetros `@export`

### 3.1. Custom Resources (`.gd` / `.tres`)
Detalhados em [`data-model.md`](./data-model.md):
- `ClueData` (`res://src/data/clue_data.gd`) + 8 arquivos `.tres` (6 pistas autênticas e 2 pistas falsas para *Couraçado das Ruínas* e *Fera Ágil da Clareira*).
- `MonsterGrimoireEntryData` (`res://src/data/monster_grimoire_entry_data.gd`) + 2 arquivos `.tres` (`entry_armored_carapace.tres` e `entry_agile_beast.tres`).

### 3.2. Contrato de Sinais (*Call Down, Signal Up*)
- **`PlayerInteractionComponent`**:
  - `signal focused_clue_changed(clue: InteractableClue)`
  - `signal inspection_started(clue: InteractableClue, duration: float)`
  - `signal inspection_progress_changed(clue: InteractableClue, ratio: float)`
  - `signal inspection_cancelled(clue: InteractableClue)`
  - `signal clue_inspection_completed(clue_data: ClueData)`
- **`GrimoireComponent`**:
  - `signal clue_discovered(clue_data: ClueData, is_new: bool)`
  - `signal clue_discard_toggled(clue_id: StringName, is_discarded: bool)`
  - `signal entry_updated(monster_id: StringName, resolved_state: Dictionary)`
  - `signal monster_research_completed(monster_id: StringName)`
- **`PlayerInputComponent` (Expansão)**:
  - `signal interact_pressed()` / `is_interact_held: bool`
  - `signal grimoire_toggle_requested()`
  - `var gameplay_inputs_blocked: bool` (suprime ataques e locomoção quando o Grimório está aberto em Tempo Real Tático — `Q3` / `EC-003`)

### 3.3. Parâmetros de Game Feel (`@export`)
| Variável `@export` | Script | Valor Padrão | Faixa (`@export_range`) | Efeito no Game Feel |
| :--- | :--- | :--- | :--- | :--- |
| `interaction_radius` | `PlayerInteractionComponent` | `44.0` | `16.0, 120.0, 2.0` | Raio em pixels para detectar pistas no chão |
| `inspect_duration` | `InteractableClue` | `0.5` | `0.0, 3.0, 0.05` | Tempo de canalização para inspecionar (`0.0` = instantâneo) |
| `pause_tree_on_open` | `GrimoireUIGreybox` | `false` | `bool` | Define se abrir o Grimório roda em Tempo Real Tático (`false`) ou pausa a árvore (`true`) |
| `notification_display_duration` | `GrimoireUIGreybox` | `3.0` | `0.5, 10.0, 0.25` | Duração em segundos do Toast de pista coletada na HUD |
| `locked_placeholder_text` | `MonsterGrimoireEntryData` | `"???"` | `String` | Texto exibido para seções ocultas no Grimório e no HUD do alvo |
| `uninspected_color` / `focused_color` / `inspected_color` | `InteractableClue` | `#F39C12` / `#00FFFF` / `#7F8C8D` | `Color` | Cores semânticas *Greybox* do vestígio no mapa |

---

## 4. Decisões Técnicas com Justificativa (Trade-offs)

| ID | Decisão | Opção Escolhida | Alternativa Descartada | Justificativa Técnica |
| :--- | :--- | :--- | :--- | :--- |
| **`DT-01`** | Separação entre `GrimoireTracker` (`RefCounted`) e `GrimoireComponent` (`Node`) | Lógica dedutiva pura em `RefCounted` envolvida por um `Node` emissor de sinais | Colocar toda a lógica dentro do script de UI `Control` | Cumpre as Cláusulas 1.1 e 2.2 da Constituição: permite testar 100% da resolução de pistas falsas, idempotência e síntese em milissegundos sem instanciar interface gráfica. |
| **`DT-02`** | Julgamento Manual de Pistas Falsas (`toggle_clue_discarded`) | Pistas falsas (`is_false_lead = true`) contaminam a síntese da seção até serem descartadas manualmente pelo jogador na UI | Filtragem automática pela engine ao coletar | Preserva a agência de detetive (*Pilar #1 do GDD* e decisão `Q5` do Portão 1): o jogador desatento pode fabricar o Óleo errado na `SPEC-004`, enquanto o atento cruza as evidências e descarta o vestígio contraditório. |
| **`DT-03`** | Tempo Real Tático ao abrir o Grimório (`pause_tree_on_open = false`) | Suprimir inputs de ataque/locomoção em `PlayerInputComponent.gameplay_inputs_blocked` e fechar o Grimório no sinal `HealthComponent.damaged` | `get_tree().paused = true` fixo em código | Atende à decisão `Q3` do Portão 1 mantendo a tensão de campo hostil e permitindo testes integrados na Sandbox (como ser atingido pelo `HazardPulseEmitter` enquanto lê o Grimório). |
| **`DT-04`** | Sincronização de Telemetria no `CombatDummy` sem Bônus Artificial | `CombatDummy` exibe `???` para sua Fraqueza até receber a resolução do `GrimoireComponent` daquele `monster_id` | Adicionar multiplicador extra de dano no `DamageResolver` | Respeita a decisão `Q4` do Portão 1 e a pureza matemática do `DefenseProfileData` (`SPEC-002`). |

---

## 5. Constitution Check (Conferência Automática contra a Constituição)

*PORTÃO AUTOMÁTICO: 100% aprovado antes da geração de Tarefas (`/speckit-tasks`).*

| Regra Constitucional (`.specify/memory/constitution.md`) | Status | Evidência Concreta neste Plano |
| :--- | :---: | :--- |
| **1. Modularidade Total (Sem script monolítico; < 200 linhas)** | ✅ | Responsabilidades divididas em 8 scripts coesos (`GrimoireTypes`, `ClueData`, `MonsterGrimoireEntryData`, `GrimoireTracker`, `GrimoireComponent`, `InteractableClue`, `PlayerInteractionComponent`, `GrimoireUIGreybox`). |
| **2. Component Pattern (Nodes independentes e reutilizáveis)** | ✅ | `PlayerInteractionComponent`, `GrimoireComponent` e `InteractableClue` são nós independentes e desacoplados. |
| **3. StateMachine Isolada (Estados como Nodes separados)** | ✅ | `PlayerInteractionComponent` consulta `StateMachine.current_state` para permitir inspeção apenas em `IdleState`/`MoveState` (`EC-004`) e abortar em `DodgeState`/`AttackState`/`HurtState`. |
| **4. Comunicação Desacoplada (*Call Down, Signal Up* / `signals`)** | ✅ | `InteractableClue` $\rightarrow$ `PlayerInteractionComponent` $\rightarrow$ `GrimoireComponent` $\rightarrow$ `GrimoireUIGreybox` & `CombatDummy` comunicam-se exclusivamente por `signals`. |
| **5. Game Feel 100% Parametrizado (`@export` sem números mágicos)** | ✅ | `interaction_radius`, `inspect_duration`, `pause_tree_on_open`, `notification_display_duration` e cores *Greybox* expostos via `@export`. |
| **6. Tipagem Estática Estrita em GDScript** | ✅ | Todos os scripts, sinais, dicionários e arrays (`Array[ClueData]`, `Array[InteractableClue]`) usam tipagem explícita `:`. |
| **7. Placeholder First (Validação em Greybox antes de arte final)** | ✅ | Vestígios no chão usam `Polygon2D` geométrico e o Grimório usa painéis/botões nativos `Control` em *Greybox*. |
| **8. Política de Testes (Unitários/Componentes + Cena Sandbox)** | ✅ | `test_grimoire_tracker.gd` ($\ge 90\%$ na lógica dedutiva) + `test_interaction_and_clues.gd` + `sandbox_investigation.tscn`. |
| **9. Segurança e Integridade de Dados (`Resource` / Save seguro)** | ✅ | Validação defensiva contra `ClueData` ou `monster_id` nulos/inválidos (`EC-005`). |
| **10. Nomenclatura e Estrutura Oficial de Pastas (`src/`, `tests/`)** | ✅ | Segue rigorosamente `res://src/{core,data,systems,components,entities,ui}/` e `res://tests/{unit,sandboxes}/`. |

---

## 6. Estrutura de Arquivos a Criar/Modificar

```text
specs/003-investigation-grimoire/
├── spec.md                      # Especificação clarificada (Portão 1 Aprovado)
├── plan.md                      # Este arquivo (/speckit-plan)
├── research.md                  # Decisões de pesquisa técnica e design
├── data-model.md                # Modelo de dados e catálogo de pistas (autênticas e falsas)
├── quickstart.md                # Guia rápido de execução e validação
├── tasks.md                     # Tarefas + GitHub Issues + Análise Cruzada (Portão 2)
└── checklists/
    └── requirements.md          # Checklist de qualidade da Spec

src/
├── core/
│   └── grimoire_types.gd
├── data/
│   ├── clue_data.gd
│   ├── monster_grimoire_entry_data.gd
│   ├── clue_carapace_deep_tracks.tres
│   ├── clue_carapace_molted_shell.tres
│   ├── clue_carapace_false_campfire.tres
│   ├── clue_carapace_cracked_pillar.tres
│   ├── clue_beast_light_fur.tres
│   ├── clue_beast_false_boar_skull.tres
│   ├── clue_beast_resin_blood.tres
│   ├── clue_beast_high_claw_marks.tres
│   ├── entry_armored_carapace.tres
│   └── entry_agile_beast.tres
├── systems/
│   └── grimoire_tracker.gd
├── components/
│   ├── player_interaction_component.gd
│   └── grimoire_component.gd
├── entities/
│   ├── world/
│   │   ├── interactable_clue.gd
│   │   └── interactable_clue.tscn
│   ├── player/
│   │   ├── player.gd                # (Modificado: integra Interaction e Grimoire)
│   │   ├── player.tscn              # (Modificado: adiciona nós Interaction e Grimoire)
│   │   └── player_input_component.gd # (Modificado: interact, toggle_grimoire, gameplay_inputs_blocked)
│   └── monsters/
│       └── combat_dummy.gd          # (Modificado: suporte a monster_id e telemetria oculta '???' até dedução)
└── ui/
    └── grimoire_ui_greybox.gd

tests/
├── unit/
│   ├── run_tests.gd                 # (Modificado: registra suítes da SPEC-003)
│   ├── test_grimoire_tracker.gd
│   └── test_interaction_and_clues.gd
└── sandboxes/
    ├── sandbox_investigation.gd
    └── sandbox_investigation.tscn
```
