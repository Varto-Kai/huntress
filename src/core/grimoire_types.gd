class_name GrimoireTypes
extends RefCounted
## Enums e helpers estáticos de domínio para o Sistema de Investigação e Grimório (SPEC-003).

enum SectionType {
	STYLE_MATCHUP = 0,       ## Couraça / Estrutura física -> Estilo recomendado e resistido
	ELEMENT_OIL_RECIPE = 1,  ## Biologia / Secreção -> Fraqueza elemental e Fórmula do Óleo Fabricável
	BEHAVIOR_STAGGER = 2,    ## Padrão de caça / Marcas -> Ataque letal e janela de Stagger
}

enum ClueVisualShape {
	FOOTPRINT = 0,  ## Pegadas / Rastro no solo
	RESIDUE = 1,    ## Secreção / Cinzas / Carcaça
	CLAW_MARK = 2,  ## Marcas de garra / Impacto em estrutura
}


static func get_section_title(section: SectionType) -> String:
	match section:
		SectionType.STYLE_MATCHUP:
			return "Estrutura & Postura de Luta"
		SectionType.ELEMENT_OIL_RECIPE:
			return "Alquimia & Receita de Óleo"
		SectionType.BEHAVIOR_STAGGER:
			return "Comportamento & Quebra de Postura"
		_:
			return "Seção Desconhecida"
