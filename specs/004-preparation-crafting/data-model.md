# 🗂️ Modelo de Dados, Sinais e Adaptação: `SPEC-004` (Preparação e Alquimia)

**Feature**: `specs/004-preparation-crafting`  
**Data**: 2026-10-21

---

## 1. Custom Resources (`res://src/data/`)

### 1.1. `ReagentData` (`res://src/data/reagent_data.gd`)
| Propriedade `@export` | Tipo | Padrão | Papel |
| :--- | :--- | :--- | :--- |
| `reagent_id` | `StringName` | `&""` | Identificador único do reagente (`EC-005`) |
| `display_name` | `String` | `""` | Nome legível exibido no Toast e na Bancada |
| `description` | `String` | `""` | Descrição curta da propriedade alquímica do insumo |
| `max_stack` | `int` | `10` | Limite máximo acumulável no inventário (`RF-008`) |
| `greybox_color` | `Color` | `Color("#2ECC71")` | Cor semântica do nó `InteractableReagent` no mapa |

### 1.2. `OilRecipeData` (`res://src/data/oil_recipe_data.gd`)
| Propriedade `@export` | Tipo | Padrão | Papel |
| :--- | :--- | :--- | :--- |
| `recipe_id` | `StringName` | `&""` | ID único da receita (`&"recipe_vitriol_acid"`, `&"recipe_ignis_oil"`) |
| `display_name` | `String` | `""` | Nome da fórmula na Bancada de Alquimia |
| `result_oil` | `CombatTypes.ElementOil` | `NONE` | Óleo produzido ao sintetizar (`VITRIOL_ACID` ou `IGNIS_OIL`) |
| `required_reagent_ids` | `Array[StringName]` | `[]` | Lista ordenada de IDs de reagentes exigidos |
| `required_reagent_amounts` | `Array[int]` | `[]` | Quantidade exigida correspondente a cada `reagent_id` |
| `charges_per_craft` | `int` | `8` | Cargas de impacto adicionadas por síntese (`Q2` / `RF-005`) |

---

## 2. Catálogo `.tres` de Reagentes e Receitas (`res://src/data/`)

### 2.1. Reagentes (`ReagentData`)
1. `reagent_alchemical_base.tres` (`&"alchemical_base"` — **Base Alquímica Pura**): Catalisador destilado essencial para fixar qualquer óleo na lâmina (Insumo escasso compartilhado entre todas as receitas).
2. `reagent_corrosive_bile.tres` (`&"corrosive_bile"` — **Bile Corrosiva**): Secreção ácida orgânica.
3. `reagent_sulfur_powder.tres` (`&"sulfur_powder"` — **Pó de Enxofre**): Mineral amarelo reativo.
4. `reagent_flammable_tallow.tres` (`&"flammable_tallow"` — **Sebo Inflamável**): Gordura animal de alta combustão.
5. `reagent_dry_ember.tres` (`&"dry_ember"` — **Brasa Seca**): Fragmento ígneo concentrado.

### 2.2. Receitas de Óleos (`OilRecipeData`)
1. `recipe_vitriol_acid.tres` (**Vitríolo Ácido** $\rightarrow$ `CombatTypes.ElementOil.VITRIOL_ACID`, `+8 cargas`):
   - `1x Base Alquímica Pura` (`&"alchemical_base"`) + `1x Bile Corrosiva` (`&"corrosive_bile"`) + `1x Pó de Enxofre` (`&"sulfur_powder"`).
2. `recipe_ignis_oil.tres` (**Óleo Ígneo** $\rightarrow$ `CombatTypes.ElementOil.IGNIS_OIL`, `+8 cargas`):
   - `1x Base Alquímica Pura` (`&"alchemical_base"`) + `1x Sebo Inflamável` (`&"flammable_tallow"`) + `1x Brasa Seca` (`&"dry_ember"`).

---

## 3. Fórmulas de Adaptação Silenciosa da Presa (`region_alert_level: 0..3`)

Gerenciadas em `PreparationManager` (`res://src/systems/preparation_manager.gd`) e aplicadas silenciosamente em `CombatDummy` e `HazardPulseEmitter`:

- **`region_alert_level`**: Inteiro em `[0, max_alert_level]` (padrão `max_alert_level = 3`), incrementado em `+1` a cada chamada de `rest_at_campfire()`.
- **`is_true_weakness`**: Verdadeiro quando o golpe atinge simultaneamente `style_dmg_mult > 1.1` **e** `oil_dmg_mult > 1.1` no `DefenseProfileData` do alvo.
- **Modificadores por Nível de Alerta (`L = region_alert_level`)**:
  - `non_weakness_penalty_mult = max(0.25, 1.0 - 0.20 * L)` (Em `L=0`: `1.0x`; `L=1`: `0.8x`; `L=2`: `0.6x`; `L=3`: `0.4x` para golpes Neutros/Resistidos).
  - `true_weakness_mult = 1.0` (A Fraqueza Verdadeira mantém `100%` do seu multiplicador crítico em todos os níveis de alerta).
  - `max_stagger_scale = 1.0 + 0.15 * L` (Aumenta a barra de postura máxima do monstro em `+15%` por descanso).
  - `hazard_interval_scale = max(0.50, 1.0 - 0.12 * L)` (Reduz o intervalo entre pulsos de ataque do monstro em `-12%` por descanso, deixando-o visivelmente mais rápido).
