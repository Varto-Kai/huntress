class_name CombatTypes
extends RefCounted
## Declaração central de enums tipados do domínio de combate da Caçadora (SPEC-002: RF-002, RF-004).

enum Team {
	PLAYER = 0,
	ENEMY = 1,
	NEUTRAL = 2,
}

enum StyleType {
	FAST_STEEL = 0,
	HEAVY_IMPACT = 1,
}

enum ElementOil {
	NONE = 0,
	IGNIS_OIL = 1,
	VITRIOL_ACID = 2,
}

enum MatchupResult {
	RESISTED = 0,
	NEUTRAL = 1,
	WEAKNESS = 2,
}


static func get_style_display_name(style: StyleType) -> String:
	match style:
		StyleType.FAST_STEEL:
			return "Postura Rápida (Corte 3-Hits)"
		StyleType.HEAVY_IMPACT:
			return "Postura Pesada (Impacto 2-Hits)"
	return "Desconhecido"


static func get_oil_display_name(oil: ElementOil) -> String:
	match oil:
		ElementOil.NONE:
			return "Nenhum (Lâmina Limpa)"
		ElementOil.IGNIS_OIL:
			return "Óleo Ígneo (Fogo)"
		ElementOil.VITRIOL_ACID:
			return "Vitríolo Ácido (Corrosivo)"
	return "Desconhecido"


static func get_matchup_display_name(matchup: MatchupResult) -> String:
	match matchup:
		MatchupResult.RESISTED:
			return "RESISTIDO (Dano Reduzido)"
		MatchupResult.NEUTRAL:
			return "NEUTRO (1.0x)"
		MatchupResult.WEAKNESS:
			return "FRAQUEZA EXPLORADA! (Crítico Tático)"
	return "NEUTRO"
