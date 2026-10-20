# 🔬 Pesquisa Técnica & Decisões de Engenharia: `001-player-movement`

**Feature**: `specs/001-player-movement`  
**Data**: 2026-10-20  
**Escopo**: Resolução de escolhas de física 2D na Godot 4.x, tratamento de entradas simultâneas, curva de esquiva e *Input Buffer*.

---

## 1. Captura de Entrada Direcional e Anulação de Eixos Opostos (`RF-001`, `EC-001`, `EC-005`)

- **Decision**: Utilizar `Input.get_vector("move_left", "move_right", "move_up", "move_down")` combinado com verificação manual de eixos opostos (`Input.is_action_pressed`) e tratamento de `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- **Rationale**:
  - Na Godot 4.x, `Input.get_vector()` já aplica zona morta (*deadzone*) circular e retorna um vetor normalizado de comprimento máximo `1.0`, garantindo que o movimento diagonal tenha exatamente a mesma magnitude que o movimento cardinal (`SC-001`: variação $\le 0.01\%$).
  - Além disso, caso a janela do sistema operacional perca o foco (`NOTIFICATION_APPLICATION_FOCUS_OUT`), o `PlayerInputComponent` zera imediatamente o vetor de entrada e o *buffer* de esquiva (`EC-005`), impedindo que a Caçadora continue correndo sozinha.
- **Alternatives considered**:
  - *Cálculo manual com `if Input.is_action_pressed()` sem normalização*: Descartado por causar velocidade diagonal $\approx 41.4\%$ maior ($\sqrt{2}$) e não tratar *deadzone* de controles analógicos.

---

## 2. Física de Aceleração, Atrito e Proporção Top-Down (`RF-002`, `EC-004`, `EC-006`)

- **Decision**: Utilizar `Vector2.move_toward(target_velocity, rate * delta)` dentro de `_physics_process(delta)` no `MovementComponent`, com `CharacterBody2D.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING` e colisor `CircleShape2D`.
- **Rationale**:
  - `MOTION_MODE_FLOATING` é o modo oficial da Godot 4.x para jogos Top-Down 2D (sem gravidade lateral/inferior de plataforma), permitindo que `move_and_slide()` deslize suavemente ao longo de paredes em qualquer ângulo (`EC-004`).
  - `Vector2.move_toward()` evita *overshooting* em taxas de quadros variáveis e garante parada exata em `Vector2.ZERO` quando não há entrada direcional.
  - A proporção `y_axis_speed_ratio` (padrão `1.0`) multiplica apenas a componente vertical da velocidade final após a normalização da direção, preservando o modelo 1:1 estilo *CrossCode* e permitindo ajuste fino via Inspector sem alterar o código.
- **Alternatives considered**:
  - *Interpolação exponencial (`lerp`) pura*: Descartada porque nunca atinge matematicamente `0.0` sem um corte arbitrário (*epsilon*) e depende de ajuste não-linear com `delta`.

---

## 3. Curva da Esquiva, *Backstep* e Janela de *i-frames* (`RF-005`, `RF-006`, `EC-002`)

- **Decision**: Dividir a duração do `PlayerDodgeState` (`dodge_duration`) em duas fases internas:
  1. **Fase de Impulso / *i-frames* (`0.0` até `invulnerability_duration`)**: Velocidade mantida no pico (`dodge_speed` para esquiva direcional ou `dodge_speed * backstep_speed_multiplier` para *Backstep* a partir de `Idle`), com `_is_invulnerable = true`.
  2. **Fase de Recuperação / *Recovery* (`invulnerability_duration` até `dodge_duration`)**: `_is_invulnerable = false` (emitindo `invulnerability_ended`), enquanto a velocidade desacelera suavemente até `initial_dodge_speed * dodge_end_speed_factor`.
- **Rationale**:
  - Atende integralmente às clarificações `Q1`, `Q2` e `Q4` do Portão de Qualidade 1: o jogador sente o impulso imediato no frame 1, mantém o olhar (`facing_direction`) voltado para o monstro durante o *Backstep*, e visualiza claramente no Greybox quando está invulnerável (Azul Ciano) e quando entrou na janela final vulnerável de recuperação (Laranja).
- **Alternatives considered**:
  - *Usar `Tween` assíncrono fora do `_physics_process`*: Descartado por dificultar o cancelamento determinístico e dessincronizar com os ticks de física em testes unitários.
