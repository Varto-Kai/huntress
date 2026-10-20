# 🚀 Guia Rápido de Validação (Quickstart): `002-combat-system`

**Feature**: `specs/002-combat-system`  
**Cena Sandbox Alvo**: `res://tests/sandboxes/sandbox_combat.tscn`

---

## 1. Como Executar a Cena Sandbox de Combate (< 30 segundos)

```bash
"/home/liandra/Documentos/Projetos Dev/Huntress/Godot_v4.7.2-stable_linux.x86_64" --path . res://tests/sandboxes/sandbox_combat.tscn
```

### Controles na Arena de Combate:
- **`WASD` / `Setas`**: Mover e orientar `facing_direction`
- **`J` ou `Botão Esquerdo do Mouse` ou `Enter`**: Atacar / Encadear Combo (`AttackState`)
- **`Espaço` / `Shift`**: Esquivar (`Dash` / `Backstep` / `Dodge Cancel`)
- **`Q` ou `Tab`**: Alternar **Estilo de Luta** (**Postura Rápida: Corte 3-Hits** $\leftrightarrow$ **Postura Pesada: Impacto 2-Hits**)
- **`E`**: Alternar **Óleo Aplicado na Lâmina** (`Nenhum` $\rightarrow$ `Óleo Ígneo` $\rightarrow$ `Vitríolo Ácido`)

---

## 2. Roteiro de Verificação Visual (`SC-001` a `SC-004`)

1. **Combo de 3 Cortes vs. 2 Impactos e *Dodge Cancel* (`RF-006`, `RF-007`)**:
   - Pressione `J` 3 vezes seguidas na **Postura Rápida** para observar os 3 cortes ágeis orientados pela seta frontal.
   - Pressione `Q` para mudar para a **Postura Pesada** e pressione `J` 2 vezes para sentir o *windup* maior e o arco de impacto amplo.
   - Durante um ataque, pressione `Espaço`: verifique que o ataque é cancelado imediatamente na preparação (*Windup*) ou logo após o corte (*Recovery*).
2. **Exploração Tática de Fraquezas e Quebra de Postura (*Stagger*) (`RF-004`, `SC-002`)**:
   - Ataque o **Dummy Couraçado (Esquerda)** com a **Postura Rápida sem óleo**: observe na HUD que o golpe é **RESISTIDO** (dano reduzido e quase nenhum avanço na barra amarela de *Stagger*).
   - Troque para a **Postura Pesada (`Q`) + Vitríolo Ácido (`E`)** e ataque o mesmo Dummy Couraçado: o golpe acusa **FRAQUEZA EXPLORADA!**, enchendo rapidamente a barra de postura até o Dummy entrar em **BREAK / STAGGERED** (sofrendo `1.5x` dano extra).
3. **Validação de *i-frames* da Esquiva vs. `PlayerHurtState` (`RF-003`, `RF-008`, `SC-003`)**:
   - Aproxime-se do **Totem Emissor de Perigo (Centro-Sul)** que dispara pulsos ofensivos periódicos:
   - Esquive (`Espaço`) através do pulso: a HUD registra **ATAQUE ESQUIVADO (i-frames)** com zero dano.
   - Deixe o pulso atingir a Caçadora parada ou atacando: ela interrompe o ataque, sofre *knockback* em `PlayerHurtState` e pisca durante os *i-frames* pós-dano (`0.60s`).

---

## 3. Como Executar a Suíte Completa de Testes Automatizados (SPEC-001 + SPEC-002)

```bash
"/home/liandra/Documentos/Projetos Dev/Huntress/Godot_v4.7.2-stable_linux.x86_64" --headless --path . -s res://tests/unit/run_tests.gd
```
