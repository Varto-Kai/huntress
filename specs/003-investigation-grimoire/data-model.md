# 🗂️ Modelo de Dados, Sinais e Telemetria: `SPEC-003` (Investigação e Grimório)

**Feature**: `specs/003-investigation-grimoire`  
**Data**: 2026-10-21

---

## 1. Enums de Investigação (`GrimoireTypes` — `res://src/core/grimoire_types.gd`)

```gdscript
class_name GrimoireTypes
extends RefCounted

enum SectionType {
	STYLE_MATCHUP = 0,       ## Couraça / Estrutura física -> Estilo recomendado e resistido
	ELEMENT_OIL_RECIPE = 1,  ## Biologia / Secreção -> Fraqueza elemental e Receita do Óleo Fabricável
	BEHAVIOR_STAGGER = 2,    ## Padrão de caça / Marcas -> Ataque letal e janela de Stagger
}

enum ClueVisualShape {
	FOOTPRINT = 0,  ## Pegadas / Rastro pesado
	RESIDUE = 1,    ## Secreção / Queimadura / Carcaça
	CLAW_MARK = 2,  ## Marcas de garra / Impacto em rocha/árvore
}
```

---

## 2. Custom Resources (`res://src/data/`)

### 2.1. `ClueData` (`res://src/data/clue_data.gd`)
| Propriedade `@export` | Tipo | Padrão | Papel |
| :--- | :--- | :--- | :--- |
| `clue_id` | `StringName` | `&""` | Identificador único e idempotente da pista (`EC-002`) |
| `monster_id` | `StringName` | `&""` | Identificador da criatura associada |
| `title` | `String` | `""` | Nome curto exibido no Toast e no cartão do Grimório |
| `evidence_description` | `String` | `""` | Descrição observacional com pistas textuais para o jogador julgar se é verdadeira ou falsa |
| `section_type` | `GrimoireTypes.SectionType` | `0` | Qual seção do Grimório esta pista preenche (`Q1` — vínculo 1:1) |
| `is_false_lead` | `bool` | `false` | Se `true`, é uma pista falsa (*Red Herring*) que contamina a síntese enquanto não for descartada (`Q5`) |
| `concluded_style_weakness` | `CombatTypes.StyleType` | `0` | Estilo apontado por esta pista (verdadeiro ou enganoso) |
| `concluded_style_resistance` | `CombatTypes.StyleType` | `0` | Estilo resistido apontado por esta pista |
| `concluded_element_weakness` | `CombatTypes.ElementOil` | `0` | Óleo/Elemento apontado por esta pista |
| `concluded_oil_recipe` | `String` | `""` | Fórmula de materiais para fabricar o Óleo apontado (ex.: `"1x Glândula Ácida + 1x Cinza Vulcânica"`) |
| `concluded_behavior_hint` | `String` | `""` | Resumo tático de comportamento e janela de *Stagger* apontado pela pista |
| `greybox_color` | `Color` | `Color("#F39C12")` | Cor base do vestígio no mapa |

### 2.2. `MonsterGrimoireEntryData` (`res://src/data/monster_grimoire_entry_data.gd`)
| Propriedade `@export` | Tipo | Padrão | Papel |
| :--- | :--- | :--- | :--- |
| `monster_id` | `StringName` | `&""` | ID único do monstro (ex.: `&"armored_carapace"`, `&"agile_beast"`) |
| `display_name` | `String` | `""` | Nome da criatura no Grimório |
| `subtitle` | `String` | `""` | Classificação ecológica/tática |
| `defense_profile` | `DefenseProfileData` | `null` | Vínculo com o perfil de defesa da `SPEC-002` |
| `available_clues` | `Array[ClueData]` | `[]` | Lista completa de pistas (autênticas e falsas) associadas a esta caçada |
| `locked_placeholder_text` | `String` | `"???"` | Texto exibido para seções ainda não descobertas (`RF-008`) |

---

## 3. Catálogo `.tres` para a Sandbox (`res://src/data/`)

1. **Monstro 1: Couraçado das Ruínas (`entry_armored_carapace.tres`)**:
   - **Pista Autêntica 1 (Estilo)**: `clue_carapace_deep_tracks.tres` (*Pegadas Afundadas no Granito*) $\rightarrow$ Revela couraça densa: Vulnerável a `HEAVY_IMPACT`, Resistente a `FAST_STEEL`.
   - **Pista Autêntica 2 (Óleo & Receita)**: `clue_carapace_molted_shell.tres` (*Fragmento de Carapaça Calcificada*) $\rightarrow$ Reage violentamente a corrosão: Vulnerável a `VITRIOL_ACID` (*Receita: 1x Bile Corrosiva + 1x Pó de Enxofre*).
   - **Pista Falsa (*Red Herring* — Óleo)**: `clue_carapace_false_campfire.tres` (*Cinzas de Acampamento de Caçadores*) $\rightarrow$ Fuligem recente de fogueira humana com restos de sebo comum; se não for descartada, sugere erroneamente `IGNIS_OIL` (*Receita: 1x Sebo Inflamável + 1x Brasa Seca*).
   - **Pista Autêntica 3 (Comportamento/Stagger)**: `clue_carapace_cracked_pillar.tres` (*Pilar Rachado por Investida*) $\rightarrow$ Revela que impactos pesados após sua investida quebram a postura (`Stagger`) rapidamente.
2. **Monstro 2: Fera Ágil da Clareira (`entry_agile_beast.tres`)**:
   - **Pista Autêntica 1 (Estilo)**: `clue_beast_light_fur.tres` (*Pelagem Espessa sem Escamas*) $\rightarrow$ Golpes lentos erram o alvo; Vulnerável a `FAST_STEEL`, Resistente a `HEAVY_IMPACT`.
   - **Pista Falsa (*Red Herring* — Estilo)**: `clue_beast_false_boar_skull.tres` (*Crânio Velho de Javali Couraçado*) $\rightarrow$ Ossada antiga ressecada de outra presa; se não for descartada, sugere erroneamente `HEAVY_IMPACT`.
   - **Pista Autêntica 2 (Óleo & Receita)**: `clue_beast_resin_blood.tres` (*Sangue Resinoso nas Folhas*) $\rightarrow$ Secreção altamente inflamável: Vulnerável a `IGNIS_OIL` (*Receita: 1x Sebo Inflamável + 1x Brasa Seca*).
   - **Pista Autêntica 3 (Comportamento/Stagger)**: `clue_beast_high_claw_marks.tres` (*Marcas de Garras em Salto*) $\rightarrow$ Cadeias rápidas de 3 cortes interrompem seu equilíbrio e forçam *Break*.
