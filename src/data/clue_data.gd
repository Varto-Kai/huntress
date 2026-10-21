class_name ClueData
extends Resource
## Recurso de dados imutável que define uma pista física (autêntica ou falsa / Red Herring)
## e a conclusão tática que ela injeta no Grimório (SPEC-003: RF-002, RF-004, EC-005).

@export_group("Identidade da Pista")
@export var clue_id: StringName = &""
@export var monster_id: StringName = &""
@export var title: String = "Vestígio Desconhecido"
@export_multiline var evidence_description: String = ""
@export var section_type: GrimoireTypes.SectionType = GrimoireTypes.SectionType.STYLE_MATCHUP
@export var visual_shape: GrimoireTypes.ClueVisualShape = GrimoireTypes.ClueVisualShape.FOOTPRINT
@export var greybox_color: Color = Color("#F39C12")

@export_group("Dedução & Veracidade (Q5)")
## Se verdadeiro, representa uma pista falsa/enganosa (Red Herring) que contamina a seção
## até que o jogador a descarte manualmente no Grimório.
@export var is_false_lead: bool = false

@export_group("Conclusões Táticas Apontadas pela Pista")
@export var concluded_style_weakness: CombatTypes.StyleType = CombatTypes.StyleType.FAST_STEEL
@export var concluded_style_resistance: CombatTypes.StyleType = CombatTypes.StyleType.HEAVY_IMPACT
@export var concluded_element_weakness: CombatTypes.ElementOil = CombatTypes.ElementOil.NONE
@export var concluded_oil_recipe: String = "Nenhuma receita identificada"
@export_multiline var concluded_behavior_hint: String = ""


func is_valid() -> bool:
	return clue_id != &"" and monster_id != &""


func sanitize() -> void:
	if title.strip_edges().is_empty():
		title = String(clue_id) if clue_id != &"" else "Vestígio"
	if concluded_oil_recipe.strip_edges().is_empty():
		concluded_oil_recipe = "Sem fórmula alquímica associada"
