# 🔬 Pesquisa Técnica & Decisões de Arquitetura: `SPEC-004` (Preparação, Alquimia e Adaptação Silenciosa)

**Feature**: `specs/004-preparation-crafting`  
**Data**: 2026-10-21

---

## 1. Modelo Híbrido Tático: Postura Livre vs. Alquimia Restrita à Fogueira (`Q1` / `RF-004`)
- **Decisão**: Manter a troca de Posturas (`FAST_STEEL` e `HEAVY_IMPACT` via teclas `1`/`2`) livre em tempo real durante o combate, enquanto a **síntese de Óleos (`IGNIS_OIL`, `VITRIOL_ACID`)** só pode ocorrer na Fogueira (`InteractableCampfire`) consumindo reagentes do `InventoryComponent`. Fora da Fogueira, a tecla `Q` cicla apenas entre `ElementOil.NONE` e os Óleos que já possuam `cargas > 0` sintetizadas no inventário.
- **Retrocompatibilidade (`EC-006`)**: `CombatStyleComponent` expõe `@export var allow_free_debug_switching: bool = true` por padrão (mantendo `sandbox_combat.tscn` e `sandbox_investigation.tscn` intactos) e `false` em `sandbox_preparation.tscn`.

## 2. Consumo de Óleo por Golpe Conectado (*Hit-Connected Charges* — `Q2` / `RF-005`)
- **Decisão**: Cada síntese na Fogueira adiciona `@export var charges_per_craft: int = 8` cargas ao estoque daquele `ElementOil` (até `@export var max_oil_charges: int = 16`).
- **Gatilho Exato**: O sinal `HitboxComponent.hit_landed(hurtbox, resolution)` já garante na `SPEC-002` que apenas golpes que efetivamente acertam um alvo inimigo disparam o evento. Ao escutar `hit_landed`, se `active_oil != ElementOil.NONE` e `not allow_free_debug_switching`, o `InventoryComponent` debita `1` carga. Quando as cargas daquele Óleo chegam a `0`, o `CombatStyleComponent` reverte imediatamente para `ElementOil.NONE` e emite `active_oil_depleted`.

## 3. Layout Lado a Lado (Grimório + Bancada) e Autonomia Dedutiva (`Q3` / `RF-006`)
- **Decisão**: Ao interagir com `InteractableCampfire`, o sistema abre o `GrimoireUIGreybox` posicionado na metade esquerda da tela (`1280x720`) e o `PreparationUIGreybox` acoplado na metade direita.
- **Zero Spoiler na Bancada**: A Bancada de Alquimia exibe todas as receitas conhecidas pela Caçadora (`OilRecipeData`) de forma neutra, sem destacar nem sugerir qual receita corresponde ao monstro alvo. O jogador lê as pistas (e filtra as Pistas Falsas) no Grimório à esquerda e escolhe por conta própria qual receita sintetizar à direita.

## 4. Escassez Tática, Descanso na Fogueira e Adaptação Silenciosa da Presa (`Q4` / `/grill-me`)
- **Decisão**: As receitas de `VITRIOL_ACID` e `IGNIS_OIL` exigem um insumo catalisador compartilhado escasso (`reagent_alchemical_base.tres` — *Base Alquímica Pura*) além dos reagentes específicos de cada fórmula. Na região inicial antes de descansar, há catalisadores contados: se o jogador cair em uma Pista Falsa e sintetizar o Óleo errado, ele fica sem a *Base Alquímica Pura* para o Óleo verdadeiro.
- **Recuperação & Consequência Sistêmica Oculta**: Ao acionar **`[Descansar na Fogueira]`**, o HP da Caçadora é restaurado, os nós `InteractableReagent` reaparecem no mapa e o HP/Stagger dos monstros é resetado. Nos bastidores (sem avisos de UI na Fogueira nem no HUD do monstro), `region_alert_level` sobe de `0` até `3`:
  - **Punição Assimétrica ao Improviso**: Golpes que **não** combinam a Fraqueza Verdadeira completa (Postura Certa + Óleo Certo) sofrem redução progressiva de dano e *Stagger* (`-20%` por nível de alerta).
  - **Preservação da Fraqueza Verdadeira**: Quando a Caçadora atinge o alvo com a Postura correta **e** o Óleo correto simultaneamente, ela ignora a penalidade de adaptação (`100%` de eficácia).
  - **Escalada Física e Comportamental**: A cada nível de alerta, o `max_stagger` efetivo do monstro aumenta (`+15%` por nível) e a cadência de pulso hostil (`HazardPulseEmitter` / reação do alvo) fica mais rápida (`-12%` no intervalo por nível).
