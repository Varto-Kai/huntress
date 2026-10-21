# 🏗️ Plano Técnico de Implementação: Sistema de Preparação, Coleta de Reagentes e Alquimia de Óleos (Greybox)

**Diretório da Feature**: `specs/004-preparation-crafting` | **Data**: 2026-10-21 | **Spec**: `specs/004-preparation-crafting/spec.md`  
**Status no Ciclo SDD**: `[x] 4. Plano Técnico Elaborado (/speckit-plan)`  
**Constituição de Referência**: `.specify/memory/constitution.md` (v1.1.0)

---

## 1. Resumo Executivo

Este plano técnico projeta a arquitetura da **`SPEC-004` (Sistema de Preparação, Coleta de Reagentes, Alquimia de Óleos e Adaptação Silenciosa da Presa em Greybox)** na Godot 4.x com GDScript estrito. A solução implementa a **Fase 2 completa do Core Loop (Preparação)**:
1. **Insumos e Receitas Tipadas (`ReagentData` & `OilRecipeData`)**: 5 reagentes `.tres` (incluindo o catalisador escasso `Base Alquímica Pura`) e 2 receitas de Óleos (`Vitríolo Ácido` e `Óleo Ígneo`), processados pelo motor puro `PreparationManager` (`RefCounted`) e expostos via `InventoryComponent` (`Node`).
2. **Híbrido Tático (`Q1`) e Cargas por Golpe Conectado (`Q2`)**: Posturas (`FAST_STEEL` e `HEAVY_IMPACT`) alternam livremente em combate (`1`/`2`), mas Óleos só são sintetizados na Fogueira (`InteractableCampfire`) e cada acerto conectado (`HitboxComponent.hit_landed`) consome `1` carga (revertendo para `ElementOil.NONE` ao zerar — `EC-004`).
3. **Bancada Anexada Lado a Lado ao Grimório (`Q3`)**: Interagir com a Fogueira abre `GrimoireUIGreybox` à esquerda e `PreparationUIGreybox` à direita, sem sugestões ou spoilers automáticos de receita.
4. **Descanso na Fogueira & Adaptação Silenciosa da Presa (`Q4` / `/grill-me`)**: Descansar na Fogueira restaura o HP da Caçadora, reabastece os `InteractableReagent` no mapa e reseta os monstros, mas incrementa silenciosamente nos bastidores `region_alert_level (0..3)` — acelerando os ataques dos monstros, aumentando seu limiar de *Stagger* e aplicando punição progressiva contra golpes Neutros/Resistidos, enquanto preserva 100% de eficácia na Fraqueza Verdadeira.

---

## 2. Contexto Técnico e Arquitetura (Godot 4.x)

- **Engine & Linguagem**: Godot 4.x (v4.7.2) — GDScript Estrito (Tipagem Estática Obrigatória)
- **Camadas Envolvidas**:
  - **Camada de Dados (`Resource`)**: `ReagentData`, `OilRecipeData` e catálogo `.tres` em `res://src/data/`
  - **Camada de Domínio & Sistemas (`RefCounted`)**: `PreparationManager` (inventário de reagentes, síntese atômica de óleos, controle de cargas por golpe e matemática de adaptação silenciosa da região) e integração em `DamageResolver`
  - **Camada de Componentes & Mundo (`Node` / `Area2D`)**: `InventoryComponent` na Caçadora; `InteractableReagent` e `InteractableCampfire` no mundo, detectados por `PlayerInteractionComponent`
  - **Camada de Interface & Validação (`CanvasLayer` / `Control`)**: `PreparationUIGreybox` acoplada lado a lado ao `GrimoireUIGreybox` + cena `SandboxPreparation` (`res://tests/sandboxes/sandbox_preparation.tscn`)
- **Armazenamento / Dados**: `Custom Resources (.tres)` somente leitura em `res://src/data/`
- **Estratégia de Testes**: Suíte automatizada headless (`test_preparation_manager.gd` e `test_reagent_and_campfire.gd` integrados ao `run_tests.gd`) + Cena `sandbox_preparation.tscn`
- **Meta de Performance**: 60 FPS estáveis, zero acoplamento direto (`get_node`) entre reagentes/fogueira e UI (*Signals First*)

### 2.1. Árvore de Cenas e Composição de Nós (`Nodes`)

#### Entidade `Player` Expandida (`res://src/entities/player/player.tscn`)
```text
Player (CharacterBody2D)
├── ... (Nós existentes das SPEC-001, SPEC-002 e SPEC-003)
├── CombatStyleComponent (Node — atualizado com suporte a InventoryComponent e allow_free_debug_switching)
├── PlayerInteractionComponent (Area2D — expandido para detectar InteractableClue, InteractableReagent e InteractableCampfire)
├── GrimoireComponent (Node)
└── InventoryComponent (Node — encapsula PreparationManager e emite sinais de reagentes, óleos e descanso)
```

#### Entidades de Mundo (`res://src/entities/world/`)
```text
InteractableReagent (Area2D — Layer 8 [Interactables], Mask 0)
├── CollisionShape2D (CircleShape2D)
├── ReagentVisual (Polygon2D — losango/cristal com cor do ReagentData)
└── PromptLabel (Label — "[E] Coletar <Nome>")

InteractableCampfire (Area2D — Layer 8 [Interactables], Mask 0)
├── CollisionShape2D (CircleShape2D)
├── CampfireBaseVisual (Polygon2D — octógono de pedra Greybox)
├── FlameVisual (Polygon2D — chama laranja/amarela Greybox)
└── PromptLabel (Label — "[E] Fogueira (Grimório & Bancada)")
```

### 2.2. Responsabilidade Única por Script / Componente

| Script / Cena | Tipo Base | Caminho (`res://`) | Responsabilidade Única (SRP) | Requisitos Atendidos |
| :--- | :--- | :--- | :--- | :--- |
| `ReagentData` | `Resource` | `res://src/data/reagent_data.gd` | Definir dados imutáveis de um reagente alquímico (`reagent_id`, `display_name`, `max_stack`, `greybox_color`). | `RF-001`, `EC-005` |
| `OilRecipeData` | `Resource` | `res://src/data/oil_recipe_data.gd` | Definir a fórmula alquímica de um Óleo (`result_oil`, lista de reagentes e `charges_per_craft`). | `RF-001`, `RF-005`, `EC-005` |
| `PreparationManager` | `RefCounted` | `res://src/systems/preparation_manager.gd` | Processar de forma pura e atômica o estoque de reagentes, validação/síntese de receitas (`EC-001`), débito de cargas por acerto (`Q2`, `EC-004`) e cálculo dos multiplicadores de Adaptação Silenciosa (`region_alert_level: 0..3`, `Q4`). | `RF-002`, `RF-005`, `RF-008`, `SC-001` |
| `InventoryComponent` | `Node` | `res://src/components/inventory_component.gd` | Expor `PreparationManager` na Caçadora via sinais (`reagent_changed`, `oil_charges_changed`, `oil_crafted`, `crafting_failed`, `active_oil_depleted`, `campfire_rested`). | `RF-002`, `RF-004`, `RF-005` |
| `InteractableReagent` | `Area2D` | `res://src/entities/world/interactable_reagent.gd` | Representar um nó de reagente coletável no mapa com estado esgotado e método `respawn_reagent()` acionado ao descansar na Fogueira (`EC-002`). | `RF-003`, `RF-008`, `EC-002` |
| `InteractableCampfire` | `Area2D` | `res://src/entities/world/interactable_campfire.gd` | Representar a Estação de Preparação (Fogueira) no mapa, disparando a abertura do painel Lado a Lado (`Grimório + Bancada`). | `RF-003`, `RF-006` |
| `PreparationUIGreybox` | `Control` | `res://src/ui/preparation_ui_greybox.gd` | Renderizar a Bancada de Alquimia & Loadout acoplada ao lado direito do Grimório (`Q3`), com botões neutros de síntese, seleção de Postura/Óleo e botão `[Descansar na Fogueira]` sem expor o alerta oculto (`Q4`). | `RF-006`, `RF-007`, `EC-003` |

---

## 3. Modelo de Dados, Sinais e Parâmetros `@export`

### 3.1. Custom Resources (`.gd` / `.tres`)
Detalhados em [`data-model.md`](./data-model.md):
- `ReagentData` (`res://src/data/reagent_data.gd`) + 5 arquivos `.tres` (`reagent_alchemical_base.tres`, `reagent_corrosive_bile.tres`, `reagent_sulfur_powder.tres`, `reagent_flammable_tallow.tres`, `reagent_dry_ember.tres`).
- `OilRecipeData` (`res://src/data/oil_recipe_data.gd`) + 2 arquivos `.tres` (`recipe_vitriol_acid.tres` e `recipe_ignis_oil.tres`).

### 3.2. Contrato de Sinais (*Call Down, Signal Up*)
- **`PlayerInteractionComponent` (Expansão)**:
  - `signal reagent_collected_from_world(reagent_data: ReagentData, amount: int)`
  - `signal campfire_interacted(campfire: InteractableCampfire)`
- **`InventoryComponent`**:
  - `signal reagent_count_changed(reagent_id: StringName, new_count: int)`
  - `signal oil_charges_changed(oil: CombatTypes.ElementOil, new_charges: int)`
  - `signal oil_crafted(recipe: OilRecipeData, new_charges: int)`
  - `signal crafting_failed(recipe_id: StringName, reason: String)`
  - `signal active_oil_depleted(depleted_oil: CombatTypes.ElementOil)`
  - `signal campfire_rest_completed(new_hidden_alert_level: int)`

### 3.3. Parâmetros de Game Feel (`@export`)
| Variável `@export` | Script | Valor Padrão | Faixa (`@export_range`) | Efeito no Game Feel |
| :--- | :--- | :--- | :--- | :--- |
| `charges_per_craft` | `OilRecipeData` | `8` | `1, 30, 1` | Cargas de impacto concedidas a cada frasco sintetizado (`Q2`) |
| `max_oil_charges` | `InventoryComponent` | `16` | `1, 50, 1` | Teto máximo de cargas acumuláveis por tipo de Óleo |
| `max_stack` | `ReagentData` | `10` | `1, 99, 1` | Teto máximo de reagentes do mesmo tipo na bolsa |
| `allow_free_debug_switching` | `CombatStyleComponent` | `true` | `bool` | Mantém troca livre nas sandboxes legadas (`true`) e exige estoque na `SPEC-004` (`false`) |
| `max_alert_level` | `InventoryComponent` | `3` | `1, 5, 1` | Limite máximo de camadas de Adaptação Silenciosa da Presa (`Q4`) |
| `non_weakness_penalty_per_level` | `PreparationManager` | `0.20` | `0.05, 0.40, 0.05` | Penalidade por nível de alerta aplicada a ataques Neutros/Resistidos |
| `stagger_scale_per_level` | `PreparationManager` | `0.15` | `0.0, 0.50, 0.05` | Aumento percentual do `max_stagger` do monstro por descanso |
| `hazard_speedup_per_level` | `PreparationManager` | `0.12` | `0.0, 0.30, 0.02` | Aceleração da cadência de ataques do monstro por descanso |

---

## 4. Decisões Técnicas com Justificativa (Trade-offs)

| ID | Decisão | Opção Escolhida | Alternativa Descartada | Justificativa Técnica |
| :--- | :--- | :--- | :--- | :--- |
| **`DT-01`** | Motor Puro `PreparationManager` (`RefCounted`) + `InventoryComponent` (`Node`) | Lógica de inventário, receitas, cargas e adaptação isolada em `RefCounted` | Misturar dicionários de itens dentro de `Player.gd` ou na UI | Garante testes unitários instantâneos ($\ge 90\%$ de cobertura) e respeita o limite constitucional de 200 linhas por script. |
| **`DT-02`** | Layout Lado a Lado (`Grimório [Esquerda] + Bancada [Direita]`) ao abrir a Fogueira | `GrimoireUIGreybox` possui modo acoplado (`set_docked_mode(true)`) ao lado de `PreparationUIGreybox` | Duplicar o código do Grimório dentro da UI da Fogueira | Reutiliza 100% do componente `GrimoireUIGreybox` da `SPEC-003` (DRY), posicionando-o à esquerda (`x: 20..630`) enquanto a Bancada ocupa a direita (`x: 650..1260`). |
| **`DT-03`** | Adaptação Silenciosa via Sinal `campfire_rest_completed(alert_level)` | `CombatDummy` e `HazardPulseEmitter` escutam o sinal de descanso e ajustam silenciosamente seus multiplicadores sem renderizar avisos na UI | Mostrar barra de "Nível de Alerta" na HUD | Cumpre fielmente a decisão do `/grill-me` (`Q4`): o jogador sente a adaptação na prática pelo comportamento e resistência do monstro, sem spoilers de interface. |
| **`DT-04`** | Preservação de Cenas Legadas via `allow_free_debug_switching` | Flag `@export` em `CombatStyleComponent` (`true` por padrão, `false` na `sandbox_preparation.tscn`) | Forçar estoque de óleos em todas as cenas antigas | Cumpre `EC-006` e `SC-002`: nenhuma suíte de teste ou cena sandbox das `SPEC-001`, `SPEC-002` e `SPEC-003` sofre regressão. |

---

## 5. Constitution Check (Conferência Automática contra a Constituição)

*PORTÃO AUTOMÁTICO: 100% aprovado antes da geração de Tarefas (`/speckit-tasks`).*

| Regra Constitucional (`.specify/memory/constitution.md`) | Status | Evidência Concreta neste Plano |
| :--- | :---: | :--- |
| **1. Modularidade Total (Sem script monolítico; < 200 linhas)** | ✅ | Responsabilidades distribuídas em 7 novos scripts enxutos (`ReagentData`, `OilRecipeData`, `PreparationManager`, `InventoryComponent`, `InteractableReagent`, `InteractableCampfire`, `PreparationUIGreybox`). |
| **2. Component Pattern (Nodes independentes e reutilizáveis)** | ✅ | `InventoryComponent`, `InteractableReagent` e `InteractableCampfire` são nós modulares independentes. |
| **3. StateMachine Isolada (Estados como Nodes separados)** | ✅ | Interações com reagentes e fogueira respeitam a verificação de `IdleState` / `MoveState` da `StateMachine` e cancelam/fecham ao entrar em `HurtState`. |
| **4. Comunicação Desacoplada (*Call Down, Signal Up* / `signals`)** | ✅ | Coleta de reagentes, síntese na bancada, consumo de cargas por `hit_landed` e descanso na fogueira comunicam-se 100% por `signals`. |
| **5. Game Feel 100% Parametrizado (`@export` sem números mágicos)** | ✅ | Cargas por síntese (`8`), limite de cargas (`16`), pilhas de reagentes (`10`) e curvas de adaptação expostos via `@export`. |
| **6. Tipagem Estática Estrita em GDScript** | ✅ | Todos os scripts, sinais, recursos e dicionários utilizam tipagem explícita `:`. |
| **7. Placeholder First (Validação em Greybox antes de arte final)** | ✅ | Reagentes e Fogueira usam polígonos geométricos (`Polygon2D`) e a Bancada usa painéis `Control` em *Greybox*. |
| **8. Política de Testes (Unitários/Componentes + Cena Sandbox)** | ✅ | `test_preparation_manager.gd` + `test_reagent_and_campfire.gd` + `sandbox_preparation.tscn`. |
| **9. Segurança e Integridade de Dados (`Resource` / Save seguro)** | ✅ | Transações atômicas de síntese (`EC-001`) e sanitização defensiva em `ReagentData` e `OilRecipeData` (`EC-005`). |
| **10. Nomenclatura e Estrutura Oficial de Pastas (`src/`, `tests/`)** | ✅ | Segue rigorosamente `res://src/{data,systems,components,entities,ui}/` e `res://tests/{unit,sandboxes}/`. |

---

## 6. Estrutura de Arquivos a Criar/Modificar

```text
specs/004-preparation-crafting/
├── spec.md                      # Especificação clarificada (Portão 1 Aprovado)
├── plan.md                      # Este arquivo (/speckit-plan)
├── research.md                  # Decisões técnicas e de design (Q1..Q4 + /grill-me)
├── data-model.md                # Modelo de dados, receitas e fórmulas de Adaptação Silenciosa
├── quickstart.md                # Guia rápido de validação
├── tasks.md                     # Tarefas + GitHub Issues + Análise Cruzada (Portão 2)
└── checklists/
    └── requirements.md          # Checklist de qualidade da Spec (9/9)

src/
├── data/
│   ├── reagent_data.gd
│   ├── oil_recipe_data.gd
│   ├── reagent_alchemical_base.tres
│   ├── reagent_corrosive_bile.tres
│   ├── reagent_sulfur_powder.tres
│   ├── reagent_flammable_tallow.tres
│   ├── reagent_dry_ember.tres
│   ├── recipe_vitriol_acid.tres
│   ├── recipe_ignis_oil.tres
│   ├── clue_carapace_molted_shell.tres     # (Atualizado: cita 1x Base Alquímica Pura + 1x Bile Corrosiva + 1x Pó de Enxofre)
│   ├── clue_carapace_false_campfire.tres   # (Atualizado: cita 1x Base Alquímica Pura + 1x Sebo Inflamável + 1x Brasa Seca)
│   └── clue_beast_resin_blood.tres         # (Atualizado: cita 1x Base Alquímica Pura + 1x Sebo Inflamável + 1x Brasa Seca)
├── systems/
│   ├── preparation_manager.gd
│   └── damage_resolver.gd                  # (Modificado: aplica modificadores de Adaptação Silenciosa quando alert_level > 0)
├── components/
│   ├── inventory_component.gd
│   ├── combat_style_component.gd           # (Modificado: respeita estoque de cargas quando allow_free_debug_switching == false)
│   └── player_interaction_component.gd     # (Modificado: detecta InteractableReagent e InteractableCampfire além de InteractableClue)
├── entities/
│   ├── world/
│   │   ├── interactable_reagent.gd
│   │   ├── interactable_reagent.tscn
│   │   ├── interactable_campfire.gd
│   │   ├── interactable_campfire.tscn
│   │   └── hazard_pulse_emitter.gd         # (Modificado: acelera cadência silenciosamente conforme alert_level)
│   ├── player/
│   │   ├── player.gd                       # (Modificado: integra InventoryComponent e debita 1 carga em HitboxComponent.hit_landed)
│   │   └── player.tscn                     # (Modificado: adiciona nó InventoryComponent)
│   └── monsters/
│       └── combat_dummy.gd                 # (Modificado: aplica adaptação silenciosa de Stagger/Defesa e respawn ao descansar na Fogueira)
└── ui/
    ├── grimoire_ui_greybox.gd              # (Modificado: adiciona modo acoplado à esquerda set_docked_mode para abrir lado a lado com a Bancada)
    └── preparation_ui_greybox.gd           # (Novo: Bancada de Alquimia & Loadout acoplada à direita + botão Descansar na Fogueira)

tests/
├── unit/
│   ├── run_tests.gd                        # (Modificado: registra suítes da SPEC-004)
│   ├── test_preparation_manager.gd
│   └── test_reagent_and_campfire.gd
└── sandboxes/
    ├── sandbox_preparation.gd
    └── sandbox_preparation.tscn
```
