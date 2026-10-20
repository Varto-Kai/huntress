# 🚀 Guia Rápido de Validação (Quickstart): `001-player-movement`

**Feature**: `specs/001-player-movement`  
**Cena Sandbox Alvo**: `res://tests/sandboxes/sandbox_player_movement.tscn`

---

## 1. Pré-requisitos

- **Godot Engine 4.x** (4.2+ ou 4.3+) instalado no sistema.
- Repositório na branch `main` (ou branch da feature).

---

## 2. Como Executar a Cena Sandbox Greybox (< 30 segundos)

1. Abra o projeto na Godot 4.x (`project.godot`) ou execute via terminal:
   ```bash
   godot --path . res://tests/sandboxes/sandbox_player_movement.tscn
   ```
2. **Controles de Teste**:
   - **Mover**: `WASD` ou `Setas Direcionais`
   - **Esquivar (*Dash / Backstep*)**: `Espaço` (`Space`) ou `Shift`

---

## 3. Roteiro de Verificação Visual dos Requisitos (`SC-001` a `SC-004`)

1. **Locomoção e Normalização Diagonal (`RF-001`, `RF-002`, `SC-001`)**:
   - Mova-se para a Direita (`D`) e observe a velocidade máxima exibida na HUD de telemetria (`200.0 px/s`).
   - Mova-se na Diagonal (`W + D`) e confirme que a magnitude da velocidade permanece cravada em `200.0 px/s`.
   - Pressione `A + D` simultaneamente (`EC-001`) e verifique que a Caçadora desacelera suavemente até `Idle` (Verde Esmeralda) sem tremer.
2. **Orientação Persistente (`RF-004`, `RF-009`)**:
   - Mova-se para qualquer direção e solte as teclas: a seta branca frontal (`FacingIndicator`) deve continuar apontando para a última direção olhada.
3. **Esquiva Direcional, *Backstep* e *i-frames* (`RF-005`, `RF-006`, `EC-002`)**:
   - Em movimento (`Move`), pressione `Espaço`: a Caçadora avança na direção atual, ficando **Azul Ciano** durante os *i-frames* e **Laranja** no terço final de desaceleração (*recovery*).
   - Parada em `Idle`, pressione `Espaço` sem tocar nas teclas direcionais: a Caçadora executa um **Backstep** (recua para trás com `0.75x` da velocidade de dash), mantendo a seta branca apontada para a frente.
4. **Input Buffer e Cooldown (`RF-007`, `EC-003`)**:
   - Pressione `Espaço` novamente um instante antes do término do *cooldown* (~`0.12s` finais): a segunda esquiva dispara imediatamente assim que o *cooldown* zera.
5. **Colisão e Deslizamento em Quinas (`EC-004`)**:
   - Corra ou esquive diagonalmente contra os pilares e quinas de 45°/90° na arena Sandbox: a Caçadora deve deslizar suavemente sem travar.

---

## 4. Como Executar os Testes Automatizados

Para rodar os testes unitários e de máquina de estados via linha de comando (modo headless):

```bash
godot --headless --path . -s res://tests/unit/run_tests.gd
```
*(Os testes validam matematicamente normalização diagonal, anulação de eixos opostos, transições `Idle <-> Move <-> Dodge`, *Backstep*, janela de *i-frames* e *Input Buffer*).*
