# 🔬 Pesquisa Técnica & Decisões de Engenharia: `002-combat-system`

**Feature**: `specs/002-combat-system`  
**Data**: 2026-10-20  
**Escopo**: Detecção precisa de Hitbox/Hurtbox na Godot 4.x, prevenção de *multi-hit* por ativação, máquina de fases de combo com *Dodge Cancel* e cálculo de Fraqueza/*Stagger*.

---

## 1. Detecção `HitboxComponent` $\rightarrow$ `HurtboxComponent` e Garantia de Único Acerto (`RF-002`, `EC-001`, `SC-001`)

- **Decision**: Conectar `area_entered` no `HitboxComponent` E varrer `get_overlapping_areas()` no frame exato em que `activate(attack_data)` é chamado, registrando cada `HurtboxComponent` atingido em um array `_hit_hurtboxes` limpo a cada novo golpe.
- **Rationale**:
  - Na Godot 4.x, se um alvo já está dentro da área da `HitboxComponent` no momento em que ela é ativada, depender apenas do sinal `area_entered` pode falhar ou exigir toggling de `monitoring` com atraso de 1 frame físico.
  - Ao manter `monitoring = true` e consultar `get_overlapping_areas()` no `activate()` + escutar `area_entered` enquanto `_is_active == true`, garantimos detecção instantânea no frame 1 da janela `ACTIVE` tanto em física contínua quanto em testes unitários/componentes.
  - O registro em `_hit_hurtboxes` garante matematicamente que o mesmo `HurtboxComponent` nunca receba dano duas vezes do mesmo golpe (`SC-001`).

---

## 2. Fases do Golpe (`Windup`, `Active`, `Recovery`), Combos e *Dodge Cancel* (`RF-006`, `RF-007`, `EC-004`)

- **Decision**: Implementar uma máquina de sub-fases determinística dentro de `PlayerAttackState` (`Phase.WINDUP`, `Phase.ACTIVE`, `Phase.RECOVERY`) alimentada pelo array `combo_steps: Array[AttackStepData]` do `CombatStyleData` ativo.
- **Rationale**:
  - Durante `Phase.WINDUP`: A arma se prepara (cor Amarelo Claro no Greybox) e o jogador pode cancelar imediatamente com `Dodge` caso perceba um ataque inimigo.
  - Durante `Phase.ACTIVE`: A `HitboxComponent` fica ativa e visível (cor Vermelho Vibrante), a Caçadora dá um curto passo à frente (`attack_step_speed`) e o *Dodge Cancel* fica temporariamente bloqueado — porém qualquer aperto de `Dodge` ou `Attack` fica guardado nos respectivos *Input Buffers* (`PlayerInputComponent`).
  - Na transição `Phase.ACTIVE` $\rightarrow$ `Phase.RECOVERY`: A `HitboxComponent` é imediatamente desativada. Se houver um `Dodge` no buffer e a esquiva estiver fora de *cooldown*, o *Dodge Cancel* dispara no 1º frame do `RECOVERY`. Caso contrário, se houver um `Attack` no buffer e existir um próximo passo no combo, avança para o golpe seguinte ao término do `RECOVERY` (atualizando `facing_direction` se o jogador estiver segurando uma nova direção).

---

## 3. Cálculo Tático de Fraquezas, Resistências e Quebra de Postura (`RF-004`, `SC-002`)

- **Decision**: Centralizar o cálculo em `DamageResolver.resolve_attack(attack: AttackData, defense: DefenseProfileData, is_target_staggered: bool) -> Dictionary`.
- **Rationale**:
  - Multiplica o dano base e o dano de postura pelos fatores configurados no `DefenseProfileData` para o `StyleType` (`FAST_STEEL` vs `HEAVY_IMPACT`) e para o `ElementOil` (`NONE`, `IGNIS_OIL`, `VITRIOL_ACID`).
  - Se o alvo já estiver em estado *Staggered / Break*, aplica adicionalmente `staggered_damage_multiplier` (ex.: `1.5x`), recompensando o jogador que usou a preparação correta para derrubar a postura do monstro e depois desferiu um combo completo na janela vulnerável.
