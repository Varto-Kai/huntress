# 🏗️ Plano Técnico de Implementação: Sistema de Combate Base, Hitbox/Hurtbox e Estilos/Fraquezas (Greybox)

**Diretório da Feature**: `specs/002-combat-system` | **Data**: 2026-10-20 | **Spec**: `specs/002-combat-system/spec.md`  
**Status no Ciclo SDD**: `[x] 4. Plano Técnico Elaborado (/speckit-plan)`  
**Constituição de Referência**: `.specify/memory/constitution.md` (v1.1.0)

---

## 1. Resumo Executivo

Este plano técnico projeta a arquitetura da **`SPEC-002` (Sistema de Combate Base, Hitbox/Hurtbox e Estilos/Fraquezas em Greybox)** na Godot 4.x com GDScript estrito. A solução introduz o tripé modular e reutilizável de combate exigido pela Constituição (`HealthComponent`, `HitboxComponent` e `HurtboxComponent`), complementado pelo `StaggerComponent` (quebra de postura estilo *CrossCode*/*Monster Hunter*), pelo `CombatStyleComponent` (alternância de Posturas e Óleos estilo *The Witcher*) e pela matemática pura em `DamageResolver`. A `StateMachine` da Caçadora (`SPEC-001`) é expandida com `PlayerAttackState` (combos de 3 cortes ágeis ou 2 impactos pesados orientados por `facing_direction`, com *Dodge Cancel* no *windup* e *recovery*) e `PlayerHurtState` (recuo físico com *i-frames* pós-dano).

---

## 2. Contexto Técnico e Arquitetura (Godot 4.x)

- **Engine & Linguagem**: Godot 4.x (v4.7.2) — GDScript Estrito (`untyped_declaration` e `inferred_declaration` tratados como erro)
- **Camadas Envolvidas**:
  - **Camada Core & Cálculo (`RefCounted`)**: `CombatTypes` (enums de Equipe, Estilo e Óleo/Elemento) e `DamageResolver` (fórmula pura de dano, fraqueza/resistência e *stagger*)
  - **Camada de Dados (`Resource`)**: `AttackData`, `AttackStepData`, `CombatStyleData`, `DefenseProfileData` + instâncias `.tres` de catálogo em `res://src/data/`
  - **Camada de Componentes (`Node` / `Area2D`)**: `HealthComponent`, `StaggerComponent`, `HitboxComponent`, `HurtboxComponent`, `CombatStyleComponent`
  - **Camada de Máquina de Estados (`State`)**: `PlayerAttackState` e `PlayerHurtState` integrados à `StateMachine` existente da Caçadora
  - **Camada de Entidade & Validação (`CharacterBody2D` / `Node2D`)**: Expansão de `Player`, criação de `CombatDummy` e `HazardPulseEmitter` (emissor de ataque inimigo para testar *i-frames* e `PlayerHurtState`) e cena `SandboxCombat` (`res://tests/sandboxes/sandbox_combat.tscn`)
- **Armazenamento / Dados**: `Custom Resources (.tres)` somente leitura em `res://src/data/` (duplicados quando necessário em runtime conforme Cláusula 3.2 da Constituição)
- **Estratégia de Testes**: Suíte automatizada headless (`test_combat_damage_resolver.gd` e `test_combat_components_and_states.gd` integrados ao `run_tests.gd`) + Cena `sandbox_combat.tscn`
- **Meta de Performance**: 60 FPS estáveis, zero alocações desnecessárias por frame físico, controle de *hitstop* local sem travar a árvore global indevidamente

### 2.1. Árvore de Cenas e Composição de Nós (`Nodes`)

#### Entidade `Player` Expandida (`res://src/entities/player/player.tscn`)
```text
Player (CharacterBody2D)
├── CollisionShape2D (CircleShape2D)
├── PlayerGreyboxVisual (Node2D)
│   ├── BodyPolygon (Polygon2D — cores semânticas + piscar de i-frames pós-dano)
│   └── FacingIndicator (Polygon2D)
├── WeaponPivot (Node2D — rotaciona conforme facing_direction)
│   └── HitboxComponent (Area2D)
│       ├── CollisionShape2D (RectangleShape2D — dimensionado por AttackStepData)
│       └── SlashVisual (Polygon2D — arco/retângulo de corte visível na fase Active)
├── HurtboxComponent (Area2D)
│   └── CollisionShape2D (CircleShape2D)
├── HealthComponent (Node)
├── CombatStyleComponent (Node)
├── PlayerInputComponent (Node)
├── MovementComponent (Node)
└── StateMachine (Node)
    ├── IdleState (PlayerIdleState)
    ├── MoveState (PlayerMoveState)
    ├── DodgeState (PlayerDodgeState)
    ├── AttackState (PlayerAttackState)
    └── HurtState (PlayerHurtState)
```

#### Entidade `CombatDummy` (`res://src/entities/monsters/combat_dummy.tscn`)
```text
CombatDummy (CharacterBody2D)
├── CollisionShape2D (CircleShape2D)
├── DummyVisual (Polygon2D — muda cor ao sofrer dano ou entrar em Staggered)
├── HurtboxComponent (Area2D)
│   └── CollisionShape2D (CircleShape2D)
├── HealthComponent (Node)
├── StaggerComponent (Node)
├── MovementComponent (Node — processa knockback e atrito)
└── OverheadBars (Node2D — barras geométricas de HP e Stagger)
```

### 2.2. Responsabilidade Única por Script / Componente

| Script / Cena | Tipo Base | Caminho (`res://`) | Responsabilidade Única (SRP) | Requisitos Atendidos |
| :--- | :--- | :--- | :--- | :--- |
| `CombatTypes` | `RefCounted` | `res://src/core/combat_types.gd` | Declarar enums tipados (`Team`, `StyleType`, `ElementOil`, `MatchupResult`) usados em toda a camada de combate. | `RF-002`, `RF-004` |
| `AttackData` | `Resource` | `res://src/data/attack_data.gd` | Transportar o payload imutável de um golpe (`base_damage`, `stagger_damage`, `knockback_force`, `hitstop_duration`, `style_type`, `element_oil`, `direction`, `team`). | `RF-002`, `RF-004`, `EC-005` |
| `AttackStepData` | `Resource` | `res://src/data/attack_step_data.gd` | Configurar um golpe individual dentro de um combo (`windup_duration`, `active_duration`, `recovery_duration`, `damage_multiplier`, `stagger_multiplier`, `attack_step_speed`, `hitbox_size`). | `RF-006`, `RF-009` |
| `CombatStyleData` | `Resource` | `res://src/data/combat_style_data.gd` | Definir um Estilo de Luta completo (nome, `style_type`, dano base, *stagger* base, *knockback* e array `combo_steps: Array[AttackStepData]`). | `RF-004`, `RF-006`, `RF-009` |
| `DefenseProfileData` | `Resource` | `res://src/data/defense_profile_data.gd` | Armazenar multiplicadores de resistência/fraqueza por `StyleType` e `ElementOil`, além de parâmetros de postura (`max_stagger`, `stagger_duration`, `staggered_damage_multiplier`). | `RF-004`, `RF-009`, `EC-005` |
| `DamageResolver` | `RefCounted` | `res://src/systems/damage_resolver.gd` | Calcular de forma determinística e pura o resultado de `AttackData` vs `DefenseProfileData` (dano final, *stagger* final e classificação `RESISTED`, `NEUTRAL`, `WEAKNESS`). | `RF-004`, `SC-002`, `EC-005` |
| `HealthComponent` | `Node` | `res://src/components/health_component.gd` | Gerenciar `current_health`, `max_health`, janela de *i-frames* pós-dano (`post_hit_invulnerability_duration`) e emitir `damaged`, `healed`, `health_changed`, `invulnerability_changed` e `health_depleted`. | `RF-001`, `RF-008` |
| `StaggerComponent` | `Node` | `res://src/components/stagger_component.gd` | Acumular dano de postura, decair gradualmente fora de combate e gerenciar a janela de *Break / Staggered* (`stagger_started`, `stagger_ended`, `stagger_changed`). | `RF-004`, `RF-009` |
| `HitboxComponent` | `Area2D` | `res://src/components/hitbox_component.gd` | Detectar `HurtboxComponent` compatíveis durante a janela ativa, impedir múltiplos acertos no mesmo alvo por ativação (`_hit_targets`) e emitir `hit_landed` uma vez por impacto. | `RF-002`, `EC-001`, `EC-002`, `SC-001` |
| `HurtboxComponent` | `Area2D` | `res://src/components/hurtbox_component.gd` | Verificar equipe e estados de invulnerabilidade (`DodgeState` *i-frames* + `HealthComponent` *i-frames*), resolver dano via `DamageResolver` e repassar a `HealthComponent` e `StaggerComponent`. | `RF-002`, `RF-003`, `RF-004`, `SC-003` |
| `CombatStyleComponent` | `Node` | `res://src/components/combat_style_component.gd` | Gerenciar o Estilo de Luta ativo (`FAST_STEEL` vs `HEAVY_IMPACT`) e o Óleo equipado (`NONE`, `IGNIS_OIL`, `VITRIOL_ACID`), construindo o `AttackData` para cada golpe do combo. | `RF-004`, `RF-006` |
| `PlayerAttackState` | `State` | `res://src/entities/player/states/player_attack_state.gd` | Executar fases `WINDUP` $\rightarrow$ `ACTIVE` $\rightarrow$ `RECOVERY`, posicionar `WeaponPivot` na `facing_direction`, encadear golpes do combo via *Input Buffer* e permitir *Dodge Cancel* no `WINDUP` e `RECOVERY` (desligando a hitbox no `exit()`). | `RF-005`, `RF-006`, `RF-007`, `EC-003`, `EC-004` |
| `PlayerHurtState` | `State` | `res://src/entities/player/states/player_hurt_state.gd` | Interromper ações ao sofrer dano válido, aplicar impulso de *knockback* desacelerado por atrito durante `hurt_duration` e retornar para `MoveState` ou `IdleState`. | `RF-005`, `RF-008`, `EC-003` |
| `CombatDummy` | `CharacterBody2D` | `res://src/entities/monsters/combat_dummy.gd` | Alvo tático Greybox que reage a golpes, sofre *knockback*, acumula *Stagger*, entra em estado *Break* e regenera vida ao zerar para permitir treino contínuo na Sandbox. | `RF-010`, `SC-004` |

---

## 3. Modelo de Dados, Sinais e Parâmetros `@export`

### 3.1. Custom Resources (`.gd` / `.tres`)
- **`AttackStepData` (`res://src/data/attack_step_data.gd`)**: Configura cada golpe da sequência de combo.
- **`CombatStyleData` (`res://src/data/combat_style_data.gd`)**:
  - `res://src/data/style_fast_steel.tres`: **Postura Rápida (Corte)** — 3 golpes ágeis (`windup` `0.06s`, `active` `0.08s`, `recovery` `0.12s`), alto DPS contra alvos ágeis, baixo dano de postura base.
  - `res://src/data/style_heavy_impact.tres`: **Postura Pesada (Quebra-Guarda)** — 2 golpes cadenciados (`windup` `0.16s`, `active` `0.11s`, `recovery` `0.20s`), alcance maior, alto *knockback* e alto dano de postura (*Stagger*).
- **`DefenseProfileData` (`res://src/data/defense_profile_data.gd`)**:
  - `res://src/data/defense_armored_carapace.tres`: **Couraça Pesada** — Resistente a `FAST_STEEL` (`0.5x` dano, `0.25x` stagger), Vulnerável a `HEAVY_IMPACT` (`1.5x` dano, `2.0x` stagger) e Vulnerável a `VITRIOL_ACID` (`1.5x` dano, `1.5x` stagger).
  - `res://src/data/defense_agile_beast.tres`: **Fera Ágil** — Vulnerável a `FAST_STEEL` (`1.5x` dano, `1.5x` stagger) e Vulnerável a `IGNIS_OIL` (`1.5x` dano, `1.5x` stagger), Resistente a `HEAVY_IMPACT` (`0.7x`).

### 3.2. Contrato de Sinais (*Call Down, Signal Up*)
- **`HealthComponent`**:
  - `signal damaged(amount: float, knockback_vector: Vector2, matchup: int)`
  - `signal healed(amount: float)`
  - `signal health_changed(current_health: float, max_health: float)`
  - `signal invulnerability_changed(is_invulnerable: bool)`
  - `signal health_depleted()`
- **`StaggerComponent`**:
  - `signal stagger_changed(current_stagger: float, max_stagger: float)`
  - `signal stagger_started(duration: float)`
  - `signal stagger_ended()`
- **`HitboxComponent`**:
  - `signal hit_landed(hurtbox: HurtboxComponent, resolution: Dictionary)`
- **`HurtboxComponent`**:
  - `signal hit_received(attack_data: AttackData, resolution: Dictionary)`
  - `signal hit_ignored(attack_data: AttackData)`
- **`CombatStyleComponent`**:
  - `signal style_changed(new_style: CombatStyleData)`
  - `signal oil_changed(new_oil: int)`
- **`PlayerAttackState`**:
  - `signal attack_step_started(step_index: int, total_steps: int, phase_name: StringName)`
  - `signal attack_phase_changed(phase_name: StringName)`
  - `signal attack_finished()`

### 3.3. Parâmetros de Game Feel (`@export`)
| Variável `@export` | Recurso / Nó | Valor Padrão | Faixa (`@export_range`) | Efeito no Game Feel |
| :--- | :--- | :--- | :--- | :--- |
| `windup_duration` | `AttackStepData` | `0.06` / `0.16` | `0.01, 1.0, 0.01` | Tempo de preparação antes da hitbox ligar (permite *Dodge Cancel*). |
| `active_duration` | `AttackStepData` | `0.08` / `0.11` | `0.02, 0.5, 0.01` | Janela em que a lâmina corta (bloqueia *Dodge Cancel*, retendo no buffer). |
| `recovery_duration` | `AttackStepData` | `0.12` / `0.20` | `0.02, 1.0, 0.01` | Janela pós-corte (permite *Dodge Cancel* ou avanço para próximo golpe do combo). |
| `attack_step_speed` | `AttackStepData` | `110.0` | `0.0, 400.0, 5.0` | Impulso frontal durante o corte para dar peso ao golpe. |
| `combo_input_buffer_time` | `PlayerMovementConfig` | `0.18` | `0.05, 0.5, 0.01` | Janela de *Input Buffer* para encadear o próximo golpe do combo. |
| `hurt_duration` | `PlayerMovementConfig` | `0.22` | `0.05, 1.0, 0.01` | Duração do estado `PlayerHurtState` ao sofrer dano. |
| `post_hit_invulnerability_duration` | `HealthComponent` | `0.60` | `0.0, 3.0, 0.05` | Duração dos *i-frames* pós-dano para evitar *stunlock*. |
| `hitstop_duration` | `CombatStyleData` | `0.04` / `0.07` | `0.0, 0.25, 0.01` | Breve pausa tátil no instante em que o golpe acerta um alvo. |
| `max_stagger` | `DefenseProfileData` | `100.0` | `10.0, 500.0, 5.0` | Limiar para quebrar a postura do monstro (*Break*). |
| `stagger_duration` | `DefenseProfileData` | `3.0` | `0.5, 10.0, 0.1` | Tempo que o alvo permanece atordoado e vulnerável após *Break*. |
| `staggered_damage_multiplier` | `DefenseProfileData` | `1.5` | `1.0, 4.0, 0.1` | Multiplicador extra de dano sofrido enquanto atordoado (*Staggered*). |

---

## 4. Decisões Técnicas com Justificativa (Trade-offs)

| ID | Decisão | Opção Escolhida | Alternativa Descartada | Justificativa Técnica |
| :--- | :--- | :--- | :--- | :--- |
| **`DT-01`** | Prevenção de múltiplos hits por golpe (`EC-001`) | Array interno `_hit_hurtboxes: Array[HurtboxComponent]` dentro de `HitboxComponent`, limpo a cada chamada de `activate(attack_data)` | Desligar a `HitboxComponent` no primeiro alvo atingido | Se desligássemos a hitbox no 1º alvo, um corte de espada nunca conseguiria atingir 2 inimigos próximos no mesmo golpe (`EC-002`). Registrar os `HurtboxComponent` já atingidos por ativação garante 1 hit exato por alvo permitindo acertos múltiplos em alvos distintos. |
| **`DT-02`** | Cálculo de Fraquezas, Resistências e *Stagger* (`RF-004`) | Classe estática/pura `DamageResolver` consumindo `AttackData` e `DefenseProfileData` | Embutir `if/else` de fraquezas dentro de `HurtboxComponent` ou `CombatDummy` | Isola 100% da matemática tática de *Huntress* em uma classe pura sem dependência de cena, permitindo cobertura de testes unitários $\ge 90\%$ exigida pela Seção 2.2 da Constituição. |
| **`DT-03`** | Máquina de fases interna do `PlayerAttackState` (`RF-006`, `RF-007`) | Sub-fases explícitas `enum Phase { WINDUP, ACTIVE, RECOVERY }` dentro de `PlayerAttackState`, lendo os tempos de `AttackStepData` do passo atual do combo | Criar 9 estados separados na `StateMachine` (`Slash1Windup`, `Slash1Active`...) | Evita explosão combinatória de nós na árvore da `StateMachine`, mantendo a `StateMachine` limpa (`Idle`, `Move`, `Dodge`, `Attack`, `Hurt`) e parametrizando combos de qualquer tamanho via `CombatStyleData`. |
| **`DT-04`** | Segurança contra "Hitbox Fantasma" (`EC-003`, `EC-004`) | Desativação incondicional de `hitbox_component.deactivate()` dentro de `PlayerAttackState.exit()` | Desativar apenas quando o timer de `ACTIVE` chega ao fim | Garante que qualquer interrupção abrupta do ataque (seja por *Dodge Cancel* ou por sofrer dano e ir para `PlayerHurtState`) desligue imediatamente a colisão e o polígono visual da arma. |

---

## 5. Constitution Check (Conferência Automática contra a Constituição)

*PORTÃO AUTOMÁTICO: Deve passar 100% antes da geração de Tarefas (`/speckit-tasks`).*

| Regra Constitucional (`.specify/memory/constitution.md`) | Status | Evidência Concreta neste Plano |
| :--- | :---: | :--- |
| **1. Modularidade Total (Sem script monolítico; < 200 linhas)** | ✅ | 14 scripts modulares e coesos (< 180 linhas cada); `DamageResolver` separa o cálculo matemático da física de colisão. |
| **2. Component Pattern (Nodes independentes e reutilizáveis)** | ✅ | `HealthComponent`, `StaggerComponent`, `HitboxComponent` e `HurtboxComponent` funcionam de forma idêntica tanto no `Player` quanto no `CombatDummy` (e futuros Bosses). |
| **3. StateMachine Isolada (Estados como Nodes separados)** | ✅ | `PlayerAttackState` e `PlayerHurtState` adicionados como nós filhos `State` na `StateMachine` da Caçadora. |
| **4. Comunicação Desacoplada (*Call Down, Signal Up* / `signals`)** | ✅ | Transições de dano e *Dodge Cancel* usam sinais (`damaged`, `transition_requested`, `hit_landed`); zero acoplamento com UI global. |
| **5. Game Feel 100% Parametrizado (`@export` sem números mágicos)** | ✅ | Tempos de *windup/active/recovery*, *knockback*, *hitstop*, *stagger* e multiplicadores de fraqueza expostos em `Custom Resources` com `@export`. |
| **6. Tipagem Estática Estrita em GDScript** | ✅ | Todos os scripts e sinais utilizam tipagem estática explícita validada pelo compilador do Godot 4.7.2. |
| **7. Placeholder First (Validação em Greybox antes de arte final)** | ✅ | Hitboxes de corte, indicadores de estado (*Windup*, *Active*, *Hurt*, *Staggered*) e barras de vida/postura desenhados com `Polygon2D` / `ColorRect`. |
| **8. Política de Testes (Unitários/Componentes + Cena Sandbox)** | ✅ | Testes unitários em `test_combat_damage_resolver.gd` ($\ge 90\%$ da camada de cálculo), testes de componente em `test_combat_components_and_states.gd` e cena `sandbox_combat.tscn`. |
| **9. Segurança e Integridade de Dados (`Resource` / Save seguro)** | ✅ | Catálogos `.tres` (`style_fast_steel.tres`, `style_heavy_impact.tres`, `defense_*.tres`) duplicados/sanitizados em runtime; fallback seguro para recursos nulos (`EC-005`). |
| **10. Nomenclatura e Estrutura Oficial de Pastas (`src/`, `tests/`)** | ✅ | Segue rigorosamente a árvore da Seção 4.2 da Constituição. |

---

## 6. Estrutura de Arquivos a Criar/Modificar

```text
specs/002-combat-system/
├── spec.md                                      # Especificação clarificada e aprovada (Portão 1)
├── plan.md                                      # Este Plano Técnico (/speckit-plan)
├── research.md                                  # Decisões de física de colisão, hitstop e combos
├── data-model.md                                # Modelo de Resources, Estados e Sinais de Combate
├── quickstart.md                                # Roteiro de validação (< 30s) da Sandbox de Combate
├── tasks.md                                     # Lista de Tarefas + Análise Cruzada (Portão 2)
└── checklists/
    └── requirements.md                          # Checklist de qualidade da Spec (Aprovado)

project.godot                                    # Adição das ações: attack, switch_style, switch_oil
src/
├── core/
│   └── combat_types.gd
├── data/
│   ├── player_movement_config.gd                # Adição de combo_input_buffer_time e hurt_duration
│   ├── attack_data.gd
│   ├── attack_step_data.gd
│   ├── combat_style_data.gd
│   ├── defense_profile_data.gd
│   ├── style_fast_steel.tres
│   ├── style_heavy_impact.tres
│   ├── defense_armored_carapace.tres
│   └── defense_agile_beast.tres
├── systems/
│   └── damage_resolver.gd
├── components/
│   ├── health_component.gd
│   ├── stagger_component.gd
│   ├── hitbox_component.gd
│   ├── hurtbox_component.gd
│   └── combat_style_component.gd
└── entities/
    ├── player/
    │   ├── player.gd                            # Integração de combate, Hurtbox, Hitbox e novos estados
    │   ├── player.tscn
    │   ├── player_input_component.gd            # Buffer de ataque e atalhos de troca de Estilo/Óleo
    │   ├── player_greybox_visual.gd             # Cores de Attack/Hurt e blink de i-frames pós-dano
    │   └── states/
    │       ├── player_idle_state.gd             # Transição para AttackState
    │       ├── player_move_state.gd             # Transição para AttackState
    │       ├── player_attack_state.gd
    │       └── player_hurt_state.gd
    └── monsters/
        ├── combat_dummy.gd
        ├── combat_dummy.tscn
        └── hazard_pulse_emitter.gd

tests/
├── unit/
│   ├── run_tests.gd                             # Inclusão das novas suítes da SPEC-002
│   ├── test_combat_damage_resolver.gd
│   └── test_combat_components_and_states.gd
└── sandboxes/
    ├── sandbox_combat.gd
    └── sandbox_combat.tscn
```
