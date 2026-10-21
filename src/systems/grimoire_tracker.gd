class_name GrimoireTracker
extends RefCounted
## Motor dedutivo puro (sem dependência de Node/UI) para registro idempotente de pistas,
## julgamento manual de Pistas Falsas (toggle_clue_discarded) e resolução da síntese do Grimório
## incluindo a Fórmula de Materiais do Óleo Fabricável (SPEC-003: RF-004, RF-005, EC-002, EC-005, EC-006, SC-001).

var _entries: Dictionary = {}              ## monster_id (StringName) -> MonsterGrimoireEntryData
var _discovered_clues: Dictionary = {}     ## clue_id (StringName) -> ClueData
var _discarded_clues: Dictionary = {}      ## clue_id (StringName) -> bool
var _completed_monsters: Dictionary = {}   ## monster_id (StringName) -> bool


func register_entry(entry: MonsterGrimoireEntryData) -> bool:
	if entry == null or not entry.is_valid():
		push_warning("GrimoireTracker: Tentativa de registrar MonsterGrimoireEntryData nulo ou inválido.")
		return false
	entry.sanitize()
	_entries[entry.monster_id] = entry
	return true


func has_entry(monster_id: StringName) -> bool:
	return _entries.has(monster_id)


func get_entry(monster_id: StringName) -> MonsterGrimoireEntryData:
	return _entries.get(monster_id, null) as MonsterGrimoireEntryData


func get_registered_monster_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in _entries.keys():
		ids.append(key as StringName)
	return ids


## Registra uma pista coletada no mapa de forma idempotente (EC-002).
## Retorna true apenas se for uma descoberta inédita na sessão.
func discover_clue(clue: ClueData) -> bool:
	if clue == null or not clue.is_valid():
		push_warning("GrimoireTracker: Tentativa de descobrir ClueData nulo ou inválido (EC-005).")
		return false
	if not _entries.has(clue.monster_id):
		push_warning("GrimoireTracker: monster_id '%s' não registrado (EC-005)." % String(clue.monster_id))
		return false
	if _discovered_clues.has(clue.clue_id):
		return false

	clue.sanitize()
	_discovered_clues[clue.clue_id] = clue
	return true


func is_clue_discovered(clue_id: StringName) -> bool:
	return _discovered_clues.has(clue_id)


func is_clue_discarded(clue_id: StringName) -> bool:
	return bool(_discarded_clues.get(clue_id, false))


## Alterna manualmente o descarte de uma pista coletada no Grimório (Q5 / EC-006).
func toggle_clue_discarded(clue_id: StringName) -> bool:
	if not _discovered_clues.has(clue_id):
		return false
	var next_state: bool = not is_clue_discarded(clue_id)
	_discarded_clues[clue_id] = next_state
	return next_state


func set_clue_discarded(clue_id: StringName, discarded: bool) -> void:
	if _discovered_clues.has(clue_id):
		_discarded_clues[clue_id] = discarded


func get_discovered_clues_for_monster(monster_id: StringName) -> Array[ClueData]:
	var result: Array[ClueData] = []
	var entry: MonsterGrimoireEntryData = get_entry(monster_id)
	if entry == null:
		return result
	for clue: ClueData in entry.available_clues:
		if clue != null and _discovered_clues.has(clue.clue_id):
			result.append(clue)
	return result


## Resolve a síntese atual de uma seção específica do monstro com base nas pistas coletadas e NÃO descartadas.
## Regra Q5: Se uma pista falsa (is_false_lead == true) permanecer ativa na seção, ela contamina a recomendação!
func resolve_section(monster_id: StringName, section: GrimoireTypes.SectionType) -> Dictionary:
	var entry: MonsterGrimoireEntryData = get_entry(monster_id)
	var placeholder: String = entry.locked_placeholder_text if entry != null else "???"
	var active_clues: Array[ClueData] = []

	if entry != null:
		for clue: ClueData in entry.available_clues:
			if clue == null or clue.section_type != section:
				continue
			if _discovered_clues.has(clue.clue_id) and not is_clue_discarded(clue.clue_id):
				active_clues.append(clue)

	if active_clues.is_empty():
		return {
			"unlocked": false,
			"is_accurate": false,
			"is_contaminated": false,
			"has_conflict": false,
			"active_clue_count": 0,
			"style_weakness_text": placeholder,
			"style_resistance_text": placeholder,
			"element_weakness_text": placeholder,
			"oil_recipe_text": placeholder,
			"behavior_text": placeholder,
		}

	# Se houver qualquer pista falsa não descartada ativa na seção, ela contamina a conclusão do jogador desatento
	var chosen_clue: ClueData = active_clues[0]
	var has_false_active: bool = false
	for c: ClueData in active_clues:
		if c.is_false_lead:
			chosen_clue = c
			has_false_active = true
			break

	var has_conflict: bool = active_clues.size() > 1
	return {
		"unlocked": true,
		"is_accurate": not has_false_active,
		"is_contaminated": has_false_active,
		"has_conflict": has_conflict,
		"active_clue_count": active_clues.size(),
		"style_weakness": chosen_clue.concluded_style_weakness,
		"style_resistance": chosen_clue.concluded_style_resistance,
		"element_weakness": chosen_clue.concluded_element_weakness,
		"style_weakness_text": _format_style_name(chosen_clue.concluded_style_weakness),
		"style_resistance_text": _format_style_name(chosen_clue.concluded_style_resistance),
		"element_weakness_text": _format_oil_name(chosen_clue.concluded_element_weakness),
		"oil_recipe_text": chosen_clue.concluded_oil_recipe,
		"behavior_text": chosen_clue.concluded_behavior_hint,
	}


func resolve_monster_entry(monster_id: StringName) -> Dictionary:
	var entry: MonsterGrimoireEntryData = get_entry(monster_id)
	var placeholder: String = entry.locked_placeholder_text if entry != null else "???"
	var style_sec: Dictionary = resolve_section(monster_id, GrimoireTypes.SectionType.STYLE_MATCHUP)
	var oil_sec: Dictionary = resolve_section(monster_id, GrimoireTypes.SectionType.ELEMENT_OIL_RECIPE)
	var beh_sec: Dictionary = resolve_section(monster_id, GrimoireTypes.SectionType.BEHAVIOR_STAGGER)

	var all_sections_unlocked: bool = (
		bool(style_sec["unlocked"])
		and bool(oil_sec["unlocked"])
		and bool(beh_sec["unlocked"])
	)
	var deduction_solved: bool = (
		all_sections_unlocked
		and bool(style_sec["is_accurate"])
		and bool(oil_sec["is_accurate"])
		and bool(beh_sec["is_accurate"])
	)

	if deduction_solved:
		_completed_monsters[monster_id] = true

	var discovered_list: Array[ClueData] = get_discovered_clues_for_monster(monster_id)
	var total_clues: int = entry.available_clues.size() if entry != null else 0

	return {
		"monster_id": monster_id,
		"display_name": entry.display_name if entry != null else placeholder,
		"subtitle": entry.subtitle if entry != null else placeholder,
		"discovered_count": discovered_list.size(),
		"total_clues": total_clues,
		"style_section": style_sec,
		"oil_section": oil_sec,
		"behavior_section": beh_sec,
		"all_sections_unlocked": all_sections_unlocked,
		"deduction_solved": deduction_solved,
	}


func is_monster_deduction_solved(monster_id: StringName) -> bool:
	var state: Dictionary = resolve_monster_entry(monster_id)
	return bool(state.get("deduction_solved", false))


static func _format_style_name(style: CombatTypes.StyleType) -> String:
	match style:
		CombatTypes.StyleType.FAST_STEEL:
			return "Postura Rápida (Corte)"
		CombatTypes.StyleType.HEAVY_IMPACT:
			return "Postura Pesada (Impacto)"
		_:
			return "Desconhecida"


static func _format_oil_name(oil: CombatTypes.ElementOil) -> String:
	match oil:
		CombatTypes.ElementOil.IGNIS_OIL:
			return "Óleo de Ignis (Fogo)"
		CombatTypes.ElementOil.VITRIOL_ACID:
			return "Ácido de Vitríolo (Corrosão)"
		_:
			return "Sem Óleo Elemental"
