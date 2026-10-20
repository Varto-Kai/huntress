# 🏗️ Plano Técnico de Implementação: Movimentação Base, Esquiva e StateMachine da Caçadora

**Diretório da Feature**: `specs/001-player-movement` | **Data**: 2026-10-20 | **Spec**: `specs/001-player-movement/spec.md`  
**Status no Ciclo SDD**: `[x] 4. Plano Técnico Elaborado (/speckit-plan)`  
**Constituição de Referência**: `.specify/memory/constitution.md` (v1.1.0)

---

## 1. Resumo Executivo

Este plano técnico projeta a arquitetura da **`SPEC-001` (Movimentação Base, Esquiva e StateMachine da Caçadora em Greybox)** na Godot 4.x utilizando GDScript com tipagem estática estrita. A solução decompõe a protagonista (`Player`) em componentes desacoplados e reutilizáveis (`MovementComponent`, `PlayerInputComponent`, `PlayerGreyboxVisual`, `StateMachine` e estados dedicados `IdleState`, `MoveState`, `DodgeState`), parametrizados via `PlayerMovementConfig` (`Custom Resource` com `@export`) para garantir resposta tátil imediata (*CrossCode Feel*), recuo tático em repouso (*Backstep*), janela controlada de *i-frames* vs. *recovery* e *Input Buffer* de esquiva.

---

## 2. Contexto Técnico e Arquitetura (Godot 4.x)

- **Engine & Linguagem**: Godot 4.x — GDScript Estrito (`untyped_declaration` e `inferred_declaration` tratados como erro)
- **Camadas Envolvidas**:
  - **Camada de Dados (`Resource`)**: `PlayerMovementConfig` (`res://src/data/player_movement_config.gd` + `default_player_movement.tres`)
  - **Camada de Componentes (`Node` / `Node2D`)**: `MovementComponent`, `PlayerInputComponent`, `PlayerGreyboxVisual`
  - **Camada de Máquina de Estados (`Node`)**: `StateMachine` base + `State` base + estados `PlayerIdleState`, `PlayerMoveState`, `PlayerDodgeState`
  - **Camada de Entidade (`CharacterBody2D`)**: `Player` (`res://src/entities/player/player.tscn`)
  - **Camada de Validação (`Node2D`)**: Cena `SandboxPlayerMovement` (`res://tests/sandboxes/sandbox_player_movement.tscn`) + testes automatizados em `res://tests/unit/`
- **Armazenamento / Dados**: `Custom Resource (.tres)` somente leitura em `res://src/data/default_player_movement.tres` (duplicado em memória caso sofra mutação em runtime)
- **Estratégia de Testes**: Scripts de teste unitário/componente executáveis via CLI/Editor (`res://tests/unit/`) + Cena *Sandbox Greybox* interativa (`res://tests/sandboxes/sandbox_player_movement.tscn`) com HUD de depuração em tempo real
- **Meta de Performance**: 60 FPS estáveis ($\le 16.6\text{ ms}$ por frame físico), zero alocações dinâmicas (`new()`) dentro de `_physics_process`

### 2.1. Árvore de Cenas e Composição de Nós (`Nodes`)

```text
Player (CharacterBody2D) [res://src/entities/player/player.tscn]
├── CollisionShape2D (CircleShape2D — deslize suave em quinas/paredes)
├── PlayerGreyboxVisual (Node2D)
│   ├── BodyPolygon (Polygon2D — cor semântica por estado / i-frames)
│   └── FacingIndicator (Polygon2D — seta geométrica apontando para facing_direction)
├── PlayerInputComponent (Node)
├── MovementComponent (Node)
└── StateMachine (Node)
    ├── IdleState (Node — PlayerIdleState)
    ├── MoveState (Node — PlayerMoveState)
    └── DodgeState (Node — PlayerDodgeState)
```

### 2.2. Responsabilidade Única por Script / Componente

| Script / Cena | Tipo Base | Caminho (`res://`) | Responsabilidade Única (SRP) | Requisitos Atendidos |
| :--- | :--- | :--- | :--- | :--- |
| `PlayerMovementConfig` | `Resource` | `res://src/data/player_movement_config.gd` | Armazenar e validar todos os parâmetros `@export` de *Game Feel* de locomoção, esquiva, *backstep*, *i-frames* e *input buffer*. | `RF-008`, `EC-003`, `EC-006` |
| `MovementComponent` | `Node` | `res://src/components/movement_component.gd` | Calcular velocidade (`velocity`), aceleração, atrito, proporção `y_axis_speed_ratio`, orientação (`facing_direction`) e invocar `move_and_slide()` no `CharacterBody2D` injetado. | `RF-001`, `RF-002`, `RF-004`, `EC-004`, `EC-006` |
| `PlayerInputComponent` | `Node` | `res://src/entities/player/player_input_component.gd` | Ler o `InputMap` da Godot, normalizar o vetor direcional, anular eixos opostos, limpar entrada ao perder foco da janela e gerenciar o temporizador de *Input Buffer* da esquiva. | `RF-001`, `EC-001`, `EC-003`, `EC-005` |
| `State` | `Node` | `res://src/state_machine/state.gd` | Classe base abstrata de um estado (`enter`, `exit`, `update`, `physics_update` e sinal `transition_requested`). | `RF-003` |
| `StateMachine` | `Node` | `res://src/state_machine/state_machine.gd` | Orquestrar o estado ativo, processar transições seguras via sinal e emitir `state_changed(previous_state_name, new_state_name)`. | `RF-003`, `SC-002` |
| `PlayerIdleState` | `State` | `res://src/entities/player/states/player_idle_state.gd` | Aplicar desaceleração até repouso no `MovementComponent` e transitar para `MoveState` (se houver direção) ou `DodgeState` (se esquiva elegível, disparando *Backstep*). | `RF-002`, `RF-003`, `RF-005`, `EC-002` |
| `PlayerMoveState` | `State` | `res://src/entities/player/states/player_move_state.gd` | Aplicar aceleração na direção do input, atualizar `facing_direction` e transitar para `IdleState` (sem input) ou `DodgeState` (esquiva elegível). | `RF-001`, `RF-002`, `RF-004`, `RF-005` |
| `PlayerDodgeState` | `State` | `res://src/entities/player/states/player_dodge_state.gd` | Travar direção da esquiva (ou `-facing_direction` no *Backstep*), controlar curva de velocidade (impulso + desaceleração no terço final), gerenciar janela de *i-frames*, *cooldown* e sinais de esquiva. | `RF-005`, `RF-006`, `RF-007`, `EC-002`, `EC-003`, `EC-004` |
| `PlayerGreyboxVisual` | `Node2D` | `res://src/entities/player/player_greybox_visual.gd` | Atualizar cor geométrica conforme estado/invulnerabilidade e rotacionar o ponteiro de `facing_direction` escutando sinais. | `RF-009`, `SC-004` |
| `Player` | `CharacterBody2D` | `res://src/entities/player/player.gd` | Container de composição que injeta `PlayerMovementConfig` e referências entre os componentes filhos na inicialização. | `RF-003`, `RF-008` |
| `SandboxPlayerMovement` | `Node2D` | `res://tests/sandboxes/sandbox_player_movement.gd` | Cena Greybox com obstáculos (paredes, quinas 45°/90°, corredores) e painel de telemetria em tempo real para validação em < 30s. | `RF-010`, `SC-001` a `SC-004` |

---

## 3. Modelo de Dados, Sinais e Parâmetros `@export`

### 3.1. Custom Resources (`.gd` / `.tres`)
- **`PlayerMovementConfig` (`res://src/data/player_movement_config.gd`)**:
  - Herda de `Resource` com `class_name PlayerMovementConfig`.
  - Instância padrão salva em `res://src/data/default_player_movement.tres`.
  - Na inicialização do `Player`, o recurso pode ser lido diretamente ou editado via Inspector no próprio nó `Player` para testes de *Game Feel* ao vivo (`SC-003`).

### 3.2. Contrato de Sinais (*Call Down, Signal Up*)
- **`State` (`res://src/state_machine/state.gd`)**:
  - `signal transition_requested(from_state: State, to_state_name: StringName)`
- **`StateMachine` (`res://src/state_machine/state_machine.gd`)**:
  - `signal state_changed(previous_state_name: StringName, new_state_name: StringName)`
- **`MovementComponent` (`res://src/components/movement_component.gd`)**:
  - `signal facing_direction_changed(new_direction: Vector2)`
  - `signal velocity_updated(current_velocity: Vector2)`
- **`PlayerDodgeState` (`res://src/entities/player/states/player_dodge_state.gd`)**:
  - `signal dodge_started(direction: Vector2, is_backstep: bool)`
  - `signal dodge_ended()`
  - `signal invulnerability_started()`
  - `signal invulnerability_ended()`
  - `signal dodge_cooldown_updated(time_remaining: float)`
- **`SignalBus`**: Não é necessário para a `SPEC-001`, pois toda a comunicação ocorre internamente nos componentes da Caçadora e na HUD local da Sandbox via sinais diretos (*Call Down, Signal Up*).

### 3.3. Parâmetros de Game Feel (`@export`)
Todos os parâmetros exigidos em `RF-008` ficam agrupados com `@export_group` em `PlayerMovementConfig` (e acessíveis no Inspector do `Player`):

| Variável `@export` | Tipo | Valor Padrão | Faixa (`@export_range`) | Efeito no Game Feel |
| :--- | :--- | :--- | :--- | :--- |
| `max_speed` | `float` | `200.0` | `50.0, 600.0, 5.0` | Velocidade máxima de corrida nos eixos cardinais/diagonais (px/s). |
| `y_axis_speed_ratio` | `float` | `1.0` | `0.5, 1.5, 0.05` | Proporção de velocidade no eixo Y (padrão `1.0` estilo *CrossCode*). |
| `acceleration` | `float` | `1800.0` | `200.0, 5000.0, 50.0` | Taxa de aceleração até `max_speed` (~0.11s para atingir velocidade máxima). |
| `friction` | `float` | `1600.0` | `200.0, 5000.0, 50.0` | Taxa de desaceleração ao soltar o direcional (parada firme e suave). |
| `default_facing_direction` | `Vector2` | `Vector2.DOWN` | N/A | Direção inicial de olhar da Caçadora ao instanciar a cena (`RF-004`). |
| `dodge_speed` | `float` | `460.0` | `100.0, 1200.0, 10.0` | Velocidade inicial de impulso da esquiva direcional (px/s). |
| `backstep_speed_multiplier` | `float` | `0.75` | `0.25, 1.5, 0.05` | Multiplicador aplicado sobre `dodge_speed` quando em *Backstep* (`Idle` -> `Dodge`). |
| `dodge_end_speed_factor` | `float` | `0.35` | `0.0, 1.0, 0.05` | Fator de desaceleração no terço final (*recovery*) da esquiva. |
| `dodge_duration` | `float` | `0.24` | `0.05, 1.0, 0.01` | Duração total do estado `Dodge` em segundos. |
| `invulnerability_duration` | `float` | `0.16` | `0.0, 1.0, 0.01` | Duração dos *i-frames* desde o frame 1 (limitada a `<= dodge_duration`). |
| `dodge_cooldown` | `float` | `0.35` | `0.0, 3.0, 0.05` | Tempo de recarga após o fim de `Dodge` antes de permitir nova esquiva. |
| `dodge_input_buffer_time` | `float` | `0.12` | `0.0, 0.4, 0.01` | Janela de *Input Buffer* para registrar esquiva pressionada um pouco antes de ficar disponível. |

---

## 4. Decisões Técnicas com Justificativa (Trade-offs)

| ID | Decisão | Opção Escolhida | Alternativa Descartada | Justificativa Técnica |
| :--- | :--- | :--- | :--- | :--- |
| **`DT-01`** | Arquitetura da `StateMachine` | `StateMachine` baseada em `Node` com estados filhos (`State`) comunicando via `signal transition_requested` | `match current_state:` com `enum` dentro de `player.gd` | Cumpre a Cláusula 1.2.2 da Constituição, impede que `player.gd` vire um script monolítico quando adicionarmos `AttackState` e `StaggerState` na `SPEC-002`, e permite testar cada estado isoladamente. |
| **`DT-02`** | Armazenamento de parâmetros `@export` de *Game Feel* | `Custom Resource` (`PlayerMovementConfig`) exportado no `Player` | Deixar 12 variáveis `@export` espalhadas entre `MovementComponent` e `DodgeState` | Centraliza todos os ajustes de *Game Feel* de movimento/esquiva em um único painel no Inspector do `Player`, facilitando o tuning em tempo real exigido por `SC-003` e compartilhamento seguro entre estados. |
| **`DT-03`** | Formato do `CollisionShape2D` dos pés da Caçadora | `CircleShape2D` posicionado na base da entidade | `RectangleShape2D` com quinas vivas | Em jogos Top-Down 2D (*CrossCode*), colidir contra quinas usando retângulo causa travamentos secos (*snagging*). O `CircleShape2D` garante deslizamento natural (*wall sliding*) ao contornar obstáculos (`EC-004`). |
| **`DT-04`** | Tratamento de *Input Buffer* da Esquiva (`EC-003`) | Temporizador decrescente (`_dodge_buffer_timer`) no `PlayerInputComponent` com método `consume_dodge_request()` | Ignorar qualquer input durante `Dodge` ou *cooldown* | Evita a sensação de "botão que falhou" em lutas intensas: se o jogador apertar esquiva até `0.12s` antes do fim do `Dodge`/`cooldown`, o pedido fica em buffer e é consumido no exato frame em que a esquiva se torna elegível. |
| **`DT-05`** | Curva de velocidade e *i-frames* na Esquiva (`RF-006`) | Impulso em velocidade máxima nos primeiros $2/3$ da duração + interpolação linear (`move_toward`/`lerpf`) até `dodge_end_speed_factor` no terço final, coincidindo com o fim dos *i-frames* | Velocidade constante do início ao fim da esquiva | Conecta visual e fisicamente a mecânica à leitura do jogador: enquanto a Caçadora está em alta velocidade (2/3 iniciais), os *i-frames* estão ativos (cor Azul Ciano); no terço final de desaceleração (*recovery*), os *i-frames* encerram (cor Amarelo/Laranja), sinalizando vulnerabilidade. |

---

## 5. Constitution Check (Conferência Automática contra a Constituição)

*PORTÃO AUTOMÁTICO: Deve passar 100% antes da geração de Tarefas (`/speckit-tasks`).*

| Regra Constitucional (`.specify/memory/constitution.md`) | Status | Evidência Concreta neste Plano |
| :--- | :---: | :--- |
| **1. Modularidade Total (Sem script monolítico; < 200 linhas)** | ✅ | Responsabilidades divididas em 10 scripts enxutos (~40 a 120 linhas cada); `player.gd` atua apenas como container de composição. |
| **2. Component Pattern (Nodes independentes e reutilizáveis)** | ✅ | `MovementComponent` é agnóstico de input do jogador e poderá ser reutilizado por monstros na `SPEC-005`; `PlayerInputComponent` e `PlayerGreyboxVisual` são nós isolados. |
| **3. StateMachine Isolada (Estados como Nodes separados)** | ✅ | `StateMachine` e `State` em `res://src/state_machine/`, com `PlayerIdleState`, `PlayerMoveState` e `PlayerDodgeState` como nós filhos independentes. |
| **4. Comunicação Desacoplada (*Call Down, Signal Up* / `signals`)** | ✅ | Estados pedem transição via `signal transition_requested`; `PlayerGreyboxVisual` reage aos sinais `state_changed`, `facing_direction_changed`, `invulnerability_started/ended`. Zero uso de `get_parent().get_parent()`. |
| **5. Game Feel 100% Parametrizado (`@export` sem números mágicos)** | ✅ | Todas as 12 variáveis de `RF-008` estão tipadas e expostas com `@export_range` em `PlayerMovementConfig`. |
| **6. Tipagem Estática Estrita em GDScript** | ✅ | `project.godot` configurado com avisos de tipagem estática e todos os scripts usando `: Tipo` e `-> Retorno` explícitos. |
| **7. Placeholder First (Validação em Greybox antes de arte final)** | ✅ | `PlayerGreyboxVisual` utiliza `Polygon2D` puro com cores semânticas (Verde = Idle, Verde-Claro = Move, Azul Ciano = Dodge c/ i-frames, Laranja = Dodge Recovery s/ i-frames) e seta de orientação. |
| **8. Política de Testes (Unitários/Componentes + Cena Sandbox)** | ✅ | Inclui suíte de testes automatizados em `res://tests/unit/` cobrindo normalização, *input buffer*, *backstep*, *i-frames* e transições + `res://tests/sandboxes/sandbox_player_movement.tscn`. |
| **9. Segurança e Integridade de Dados (`Resource` / Save seguro)** | ✅ | `PlayerMovementConfig` sanitiza limites (`clampf` para garantir `invulnerability_duration <= dodge_duration`) e usa `_get_configuration_warnings()` nos componentes. |
| **10. Nomenclatura e Estrutura Oficial de Pastas (`src/`, `tests/`)** | ✅ | Todos os caminhos seguem estritamente a árvore canônica da Seção 4.2 da Constituição (`snake_case` para arquivos, `PascalCase` para `class_name` e Nodes). |

---

## 6. Estrutura de Arquivos a Criar/Modificar

```text
specs/001-player-movement/
├── spec.md                       # Especificação clarificada e aprovada (Portão 1)
├── plan.md                       # Este Plano Técnico (/speckit-plan)
├── research.md                   # Decisões de pesquisa técnica e física 2D Godot 4.x
├── data-model.md                 # Modelo detalhado de Resources, Estados e Sinais
├── quickstart.md                 # Guia rápido de execução da Sandbox e Testes
├── tasks.md                      # Lista de Tarefas + Análise Cruzada (/speckit-tasks & /speckit-analyze)
└── checklists/
    └── requirements.md           # Checklist de qualidade da Spec (Aprovado)

project.godot                     # Inicialização do projeto Godot 4.x com InputMap e Strict Typing
src/
├── components/
│   └── movement_component.gd
├── data/
│   ├── player_movement_config.gd
│   └── default_player_movement.tres
├── state_machine/
│   ├── state.gd
│   └── state_machine.gd
└── entities/
    └── player/
        ├── player.gd
        ├── player.tscn
        ├── player_input_component.gd
        ├── player_greybox_visual.gd
        └── states/
            ├── player_idle_state.gd
            ├── player_move_state.gd
            └── player_dodge_state.gd

tests/
├── unit/
│   ├── test_movement_math.gd
│   └── test_player_state_machine.gd
└── sandboxes/
    ├── sandbox_player_movement.gd
    └── sandbox_player_movement.tscn
```
