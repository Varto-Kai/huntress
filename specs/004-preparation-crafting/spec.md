# 📋 Especificação da Feature: Sistema de Preparação, Coleta de Reagentes e Alquimia de Óleos (Greybox)

**Diretório da Feature**: `specs/004-preparation-crafting`  
**Criado em**: 2026-10-21  
**Status no Ciclo SDD**: `[x] 2. Rascunho de Especificação` | `[x] 3. Clarificada (🔒 Portão 1 Aprovado)`  
**Entrada do Usuário**: "Vamos para a spec 4"

---

## 1. Cenários de Usuário & Testes (Histórias do Jogador e Fluxo Principal) *(obrigatório)*

### User Story 1 - Coleta de Reagentes Alquímicos no Mapa e Inventário de Materiais (Prioridade: P1) 🎯 MVP

> **Como** a Caçadora explorando os arredores do covil durante a investigação,  
> **Quero** coletar reagentes físicos do ambiente (ex.: *Bile Corrosiva*, *Pó de Enxofre*, *Sebo Inflamável*, *Brasa Seca*) e armazená-los no meu inventário tático,  
> **Para que** eu possua os insumos materiais necessários para sintetizar os Óleos de Caça na fase de Preparação.

**Por que esta prioridade**: Materializa a decisão de design consolidada no GDD (§3.2) e na `SPEC-003` (`Q5`): os Óleos não são seletores infinitos gratuitos; eles exigem materiais reais coletados no mundo, tornando o ato de deduzir corretamente no Grimório uma questão de sobrevivência e economia tática de recursos.

**Teste Independente (Greybox)**: Na cena Sandbox de Preparação, a Caçadora aproxima-se de nós de reagentes (`InteractableReagent` em *Greybox*) e interage com eles (`[E] Coletar`). O reagente é adicionado ao `InventoryComponent`, atualizando o contador de materiais por `reagent_id` e emitindo um sinal de inventário atualizado + notificação *Toast*.

**Fluxo Principal e Cenários de Aceitação**:

1. **Dado** que a Caçadora se aproxima de um nó de reagente (`InteractableReagent`) não esgotado dentro do raio de interação, **Quando** o jogador aciona `interact`, **Então** o `InventoryComponent` adiciona a quantidade configurada do reagente (`ReagentData`), marca o nó como coletado/esgotado e emite `reagent_collected(reagent_id, amount, total_count)`.
2. **Dado** que o jogador coleta múltiplos exemplares do mesmo reagente em pontos diferentes do mapa, **Quando** o inventário é consultado, **Então** as quantidades são somadas de forma determinística até o limite de pilha (`max_stack`) configurado via `@export`.

---

### User Story 2 - Síntese Alquímica de Óleos Baseada nas Fórmulas do Grimório (Prioridade: P2)

> **Como** uma Caçadora profissional inspirada em *The Witcher*,  
> **Quero** usar uma Estação de Preparação (Fogueira/Acampamento) para sintetizar Óleos (`IGNIS_OIL`, `VITRIOL_ACID`) consumindo os reagentes exatos de suas receitas (`OilRecipeData`),  
> **Para que** a minha dedução no Grimório se transforme em munição elemental concreta — e para que um erro de dedução (cair em uma Pista Falsa) tenha a consequência real de consumir reagentes escassos no Óleo errado.

**Por que esta prioridade**: Conecta diretamente o julgamento detetivesco da `SPEC-003` com o sistema de combate da `SPEC-002`. Sem o consumo de reagentes por receita, a punição tática das Pistas Falsas (*Red Herrings*) não se concretiza.

**Teste Independente (Greybox)**: Na Estação de Preparação (`PreparationUIGreybox`), a Bancada de Alquimia & Loadout é exibida **lado a lado com o Grimório** (`GrimoireUIGreybox`). O jogador lê as pistas e fórmulas no Grimório à esquerda, cruza por conta própria as informações (sem que a bancada sugira ou destaque automaticamente qual óleo fabricar) e, na bancada à direita, vê as receitas disponíveis (`OilRecipeData`) e os reagentes possuídos (ex.: `1x Bile Corrosiva + 1x Pó de Enxofre` $\rightarrow$ `Vitríolo Ácido`). Ao clicar em `[Sintetizar Óleo]`, se houver reagentes suficientes, eles são debitados do `InventoryComponent` e o Óleo fabricado é adicionado ao estoque de preparados da Caçadora.

**Cenários de Aceitação**:

1. **Dado** que a Caçadora possui no `InventoryComponent` todos os reagentes exigidos por uma `OilRecipeData`, **Quando** o jogador aciona `[Sintetizar]` na Estação de Preparação, **Então** o sistema consome os reagentes na proporção da receita, incrementa o estoque/cargas daquele `CombatTypes.ElementOil` e emite `oil_crafted(oil_type, charges_added)`.
2. **Dado** que a Caçadora NÃO possui reagentes suficientes para uma receita, **Quando** o jogador visualiza ou tenta acionar `[Sintetizar]`, **Então** o botão indica claramente os materiais faltantes, bloqueia a síntese sem alterar o inventário e emite feedback visual de recurso insuficiente (`EC-001`).
3. **Dado** que o jogador foi enganado por uma Pista Falsa ativa no Grimório e sintetizou o Óleo incorreto gastando um reagente compartilhado ou escasso, **Quando** ele percebe o erro em combate, **Então** precisa retornar ao mapa (ou usar uma fonte de reabastecimento/coleta adicional) e corrigir sua dedução no Grimório antes de sintetizar o Óleo verdadeiro (`EC-002`).

---

### User Story 3 - Configuração de Loadout na Fogueira e Aplicação Tática em Combate (Prioridade: P3)

> **Como** jogador preparando-se antes de entrar no covil do monstro,  
> **Quero** configurar minha *Build de Caça* na Estação de Preparação (escolhendo a Postura de Luta principal/ativa e revestindo minha lâmina com um Óleo já sintetizado) sob regras claras de troca dentro vs. fora da Fogueira,  
> **Para que** minhas escolhas de preparação importem durante o confronto contra o monstro alvo.

**Por que esta prioridade**: Fecha a **Fase 2 do Core Loop (Preparação)** do GDD e substitui os atalhos livres de debug (`1`/`2` e `Q` infinitos da `SPEC-002`) por um sistema de *Loadout* governado pelas regras de preparação do jogo (preservando um modo debug opcional via `@export` para testes rápidos).

**Teste Independente (Greybox)**: Na cena `sandbox_preparation.tscn`, a Caçadora começa com a lâmina limpa (`ElementOil.NONE`) e sem óleos prontos. Ela investiga as pistas (incluindo Pistas Falsas), coleta os reagentes pelo mapa, interage com a Fogueira (`InteractableCampfire`), abre a `PreparationUIGreybox`, sintetiza o Óleo correto, equipa a Postura e o Óleo na lâmina, e enfrenta os alvos `CombatDummy` para validar o impacto do preparo.

**Cenários de Aceitação**:

1. **Dado** que a Caçadora interage com uma Fogueira/Acampamento (`InteractableCampfire`), **Quando** o painel `PreparationUIGreybox` é aberto, **Então** o jogador pode selecionar a Postura de Luta (`FAST_STEEL` ou `HEAVY_IMPACT`), sintetizar Óleos com seus reagentes e aplicar na lâmina qualquer Óleo que possua cargas disponíveis no inventário (ou limpar a lâmina para `NONE`).
2. **Dado** que a Caçadora sai da Fogueira para o combate (**Híbrido Tático *CrossCode + The Witcher***), **Quando** o jogador pressiona `1`/`2` em campo, **Então** as Posturas (`FAST_STEEL` / `HEAVY_IMPACT`) alternam livremente, mas **Quando** pressiona `Q` (ou seleciona Óleo), **Então** apenas Óleos que já possuam cargas sintetizadas no inventário podem ser aplicados na lâmina (e a síntese de novos frascos exige retornar à Fogueira).
3. **Dado** que o jogador gastou seus reagentes sintetizando o Óleo errado (ou ficou sem cargas/vida) e aciona **`[Descansar na Fogueira]`**, **Quando** o descanso é concluído, **Então** a Caçadora recupera seu HP máximo, os nós de reagentes (`InteractableReagent`) e monstros da região sofrem respawn, e o **Nível de Alerta/Adaptação da Presa (`region_alert_level`) sobe silenciosamente nos bastidores (+1, até o limite `max_alert_level = 3`)**, deixando os monstros mais rápidos, com maior resiliência de *Stagger* e mais punitivos contra ataques Neutros/Resistidos (enquanto a combinação exata da Fraqueza Verdadeira continua furando sua guarda com eficiência máxima).

---

## 2. Casos de Borda (Edge Cases) e O Que Dá Errado *(obrigatório)*

| ID | Cenário de Borda / Estado de Erro | Comportamento Esperado (Tratamento) |
| :--- | :--- | :--- |
| **`EC-001`** | **Tentativa de sintetizar um Óleo sem possuir todos os reagentes exigidos na receita** | A transação é rejeitada atomicamente (nenhum reagente é debitado parcialmente), o botão exibe o ingrediente faltante e o sinal `crafting_failed(recipe_id, reason)` é emitido. |
| **`EC-002`** | **Jogador gasta reagentes no Óleo errado (induzido por erro de dedução/Pista Falsa) e fica sem material na região** | O jogador pode acionar **`[Descansar na Fogueira]`** (`InteractableCampfire`), o que restaura o HP da Caçadora, faz todos os nós de reagentes (`InteractableReagent`) reaparecerem no mapa e reseta o HP/Stagger dos monstros, mas incrementa silenciosamente nos bastidores o `region_alert_level` (`0..3`), tornando os monstros mais adaptados contra improviso e mais rápidos. |
| **`EC-003`** | **Caçadora sofre dano enquanto a UI da Estação de Preparação (Fogueira) está aberta** | Seguindo o padrão tático da `SPEC-003`, os inputs de ataque/movimento ficam bloqueados enquanto a UI da Fogueira está aberta e, se a Caçadora sofrer dano, a janela fecha imediatamente liberando o controle para `PlayerHurtState`. |
| **`EC-004`** | **Tentativa de equipar um Óleo com estoque/cargas `0` ou quando as cargas do Óleo na lâmina se esgotam em combate** | O sistema impede equipar Óleos sem estoque; cada golpe que efetivamente acerta uma `HurtboxComponent` inimiga (`hit_landed`) consome `1` carga (golpes no ar não consomem carga); ao consumir a última carga, a lâmina reverte automaticamente para `ElementOil.NONE` (Lâmina Limpa) e emite `active_oil_depleted`. |
| **`EC-005`** | **`ReagentData` ou `OilRecipeData` nulo, com quantidades $\le 0$ ou referenciando IDs inválidos** | O sistema sanitiza quantidades mínimas (`max(1, amount)`), ignora recursos inválidos com `push_warning` e mantém o `InventoryComponent` íntegro sem *crash*. |
| **`EC-006`** | **Compatibilidade com cenas Sandbox anteriores (`sandbox_combat.tscn` e `sandbox_investigation.tscn`)** | O `PlayerCombatComponent` preserva uma flag `@export var allow_free_debug_switching: bool = true` nas cenas legadas (e `false` na `sandbox_preparation.tscn`), garantindo que 100% dos testes anteriores continuem funcionando sem regressão. |

---

## 3. Requisitos Funcionais Numerados *(obrigatório)*

- **`RF-001` (FR-001)**: O sistema DEVE prover os `Custom Resources` tipados `ReagentData` (`src/data/reagent_data.gd` — definindo `reagent_id`, `display_name`, `description`, `max_stack`, `greybox_color`) e `OilRecipeData` (`src/data/oil_recipe_data.gd` — definindo `recipe_id`, `result_oil: CombatTypes.ElementOil`, `display_name`, `required_reagents: Dictionary` ou lista tipada de pares reagente/quantidade, e `charges_per_craft: int`).
- **`RF-002` (FR-002)**: O sistema DEVE prover um `InventoryComponent` (`Node`) e um motor puro testável `PreparationManager` / `AlchemyTracker` (`RefCounted`) capazes de armazenar quantidades de reagentes por `reagent_id`, armazenar o estoque/cargas de Óleos sintetizados por `CombatTypes.ElementOil`, validar receitas e executar a síntese alquímica de forma atômica (`EC-001`, `EC-005`).
- **`RF-003` (FR-003)**: O sistema DEVE prover nós de mundo `InteractableReagent` (coleta de materiais no mapa com suporte a respawn ao descansar na fogueira) e `InteractableCampfire` (Estação de Preparação / Fogueira), integrados ao sistema de detecção de interação da Caçadora (`PlayerInteractionComponent`) e comunicando-se exclusivamente via `signals` (*Signals First*); ao acionar **`[Descansar na Fogueira]`**, o sistema DEVE restaurar o HP da Caçadora, reabastecer os `InteractableReagent` da região, resetar o HP/Stagger dos monstros e incrementar silenciosamente o **Nível de Adaptação/Alerta Regional (`region_alert_level`, de `0` até `max_alert_level = 3`)** (`Q4`).
- **`RF-004` (FR-004)**: O sistema DEVE operar no modelo **Híbrido Tático (*CrossCode + The Witcher*)** (`Q1`): as Posturas de Luta (`FAST_STEEL` e `HEAVY_IMPACT`) permanecem alternáveis livremente em campo/combate (`1`/`2`), enquanto a **síntese alquímica de Óleos (`IGNIS_OIL` e `VITRIOL_ACID`) é restrita exclusivamente à Estação de Preparação (`InteractableCampfire`)** mediante consumo de reagentes; fora da Fogueira, o jogador só pode revestir a lâmina (`Q`) com Óleos que já possuam cargas sintetizadas disponíveis no `InventoryComponent` (ou quando `allow_free_debug_switching == true` nas cenas legadas — `EC-006`).
- **`RF-005` (FR-005)**: O sistema DEVE utilizar o modelo de **Cargas por Golpe Acertado (*Hit-Connected Charges*)** (`Q2`): cada síntese na Fogueira adiciona `@export var charges_per_craft: int = 8` cargas ao estoque daquele `CombatTypes.ElementOil` (até o limite `@export var max_oil_charges: int = 16`); ataques no vazio (*whiffs*) não consomem cargas, mas cada acerto confirmado em um alvo (`hit_landed`) debita `1` carga do Óleo ativo e, ao atingir `0` cargas, reverte automaticamente a lâmina para `ElementOil.NONE` emitindo `active_oil_depleted` (`EC-004`).
- **`RF-006` (FR-006)**: Quando a Caçadora interagir com a Estação de Preparação (`InteractableCampfire`), o sistema DEVE exibir a **Bancada de Alquimia & Loadout anexada lado a lado ao Grimório** (`Q3`), permitindo ao jogador consultar calmamente suas pistas à esquerda e sintetizar os Óleos à direita; a bancada **NÃO** deve destacar nem sugerir automaticamente qual receita é a correta ou falsa, deixando 100% para o jogador a responsabilidade de juntar as peças da investigação e escolher os reagentes/receitas certos.
- **`RF-007` (FR-007)**: O sistema DEVE prover a interface *Greybox* da Bancada de Preparação (`PreparationUIGreybox` em `src/ui/preparation_ui_greybox.gd`) acoplada lado a lado ao Grimório quando na Fogueira, exibindo: inventário atual de reagentes, catálogo neutro de receitas de Óleos (`OilRecipeData`), seletor de *Loadout* ativo (Postura + Óleo revestido na lâmina com contador de cargas), botão **`[Descansar na Fogueira]`** (sem exibir indicadores ou avisos explícitos do Nível de Adaptação/Alerta oculto dos monstros — `Q4`) e fechamento automático de ambos os painéis caso a Caçadora sofra dano (`EC-003`).
- **`RF-008` (FR-008)**: O sistema de **Adaptação Silenciosa da Presa (`region_alert_level: 0..3`)** DEVE escalar os monstros da região a cada descanso na Fogueira (`Q4`), aumentando o limiar máximo de postura (`max_stagger`), acelerando a cadência de ataque/reação do monstro e reduzindo severamente o dano e o *Stagger* causados por ataques **Neutros ou Resistidos** (improviso/óleo errado), enquanto preserva 100% da eficiência máxima quando a Caçadora atinge a **Fraqueza Verdadeira** (`WEAKNESS` de Postura + `WEAKNESS` de Óleo); todos os parâmetros de *Game Feel* e balanceamento (`charges_per_craft`, `max_oil_charges`, `max_stack`, `max_alert_level`, curvas de penalidade por nível de alerta, `allow_free_debug_switching`, `heal_on_campfire_rest` e cores *Greybox*) DEVEM ser expostos via `@export` para ajuste humano no Inspector.
- **`RF-009` (FR-009)**: Deve existir uma cena *Sandbox de Preparação & Alquimia* (`res://tests/sandboxes/sandbox_preparation.tscn`) integrando o loop completo até aqui: **Investigar Pistas (com Pistas Falsas) $\rightarrow$ Coletar Reagentes no Mapa $\rightarrow$ Abrir Fogueira e Sintetizar Óleo $\rightarrow$ Equipar Build $\rightarrow$ Enfrentar os Alvos de Combate**.

### Entidades de Domínio Envolvidas

- **`ReagentData` (`Resource`)**: Ingrediente bruto coletável no mapa (*Bile Corrosiva*, *Pó de Enxofre*, *Sebo Inflamável*, *Brasa Seca*).
- **`OilRecipeData` (`Resource`)**: Fórmula alquímica que transforma reagentes em cargas de um `CombatTypes.ElementOil` (`IGNIS_OIL` ou `VITRIOL_ACID`).
- **`PreparationManager` (`RefCounted`) & `InventoryComponent` (`Node`)**: Gerenciam o inventário de reagentes, o estoque de óleos fabricados, a síntese atômica e o *Loadout* preparado da Caçadora.
- **`InteractableReagent` & `InteractableCampfire` (`Area2D`)**: Nós interativos *Greybox* posicionados no mapa para coleta de insumos e acesso à Fogueira de Preparação.
- **`PreparationUIGreybox` (`CanvasLayer`)**: Interface tática da Fogueira para fabricar óleos e equipar a *Build de Caça*.

---

## 4. Fora do Escopo (Non-Goals) 🚫 *(obrigatório)*

> *Tão importante quanto o que está no escopo. Qualquer item listado abaixo NÃO será projetado nem implementado nesta feature.*

- **Não inclui**: Inteligência Artificial completa do Boss, máquina de estados de fases do monstro ou arena final do covil (pertencem à **`SPEC-005` — Primeiro Monstro Alvo: Boss 01**).
- **Não inclui**: Economia monetária (ouro/moedas), lojas de mercadores na Vila, árvores de talentos passivos ou sistema de salvamento em disco (`SaveManager`) (pertencem à **`SPEC-006`** ou expansões futuras).
- **Não inclui**: Dezenas de receitas complexas ou poções de atributos secundários (+1% crítico) — o foco é 100% tático nos Óleos de Caça (`IGNIS_OIL` e `VITRIOL_ACID`) e Posturas da Fatia Vertical.
- **Não inclui (Reservado no GDD para Iteração Futura)**: Mini-puzzles espaciais de síntese alquímica inspirados em *Potion Permit* (encaixar blocos geométricos dos reagentes em uma grade para sintetizar a fórmula) — ideia documentada e guardada em `docs/GDD.md` (§3.2 e §4.4) para futura expansão do sistema de alquimia.
- **Não inclui**: Arte final em Pixel Art para frascos, ervas, fogueira ou menus definitivos (validação estritamente em *Greybox / Placeholder First*).

---

## 5. Critérios de Sucesso Mensuráveis *(obrigatório)*

- **`SC-001`**: A lógica de inventário de reagentes, validação de receitas, débito atômico de materiais e controle de cargas de Óleo (`PreparationManager` / `InventoryComponent`) possui cobertura de testes unitários automatizados $\ge 90\%$ em modo headless.
- **`SC-002`**: 100% das tentativas de síntese com reagentes insuficientes são bloqueadas sem corromper quantidades no inventário (`EC-001`), e 100% das cenas legadas (`sandbox_combat.tscn` e `sandbox_investigation.tscn`) continuam funcionando sem regressão (`EC-006`).
- **`SC-003`**: Na cena `sandbox_preparation.tscn`, o jogador consegue coletar pistas e reagentes, usar a Fogueira para sintetizar o Óleo correto com base no Grimório, equipar sua *Build* e derrotar/quebrar a postura do alvo correspondente em menos de 60 segundos.

---

## 6. Clarifications — 🔒 PORTÃO DE QUALIDADE 1 (Verificação Pessoal do Desenvolvedor)

> *Preenchido durante `/speckit-clarify` (Etapa 3). O agente aponta ambiguidades, faz perguntas fechadas com opções de melhoria questionando sempre o **porquê** da decisão, e grava as respostas diretamente aqui e nas seções correspondentes acima.*

### Session 2026-10-21

- **Q1 (`RF-004` — Regra de Troca de Postura vs. Síntese/Aplicação de Óleo dentro e fora da Fogueira)**: Como deve funcionar a restrição entre trocar de Postura de Luta (`FAST_STEEL` / `HEAVY_IMPACT`) e sintetizar/aplicar Óleos (`IGNIS_OIL` / `VITRIOL_ACID`) dentro da Fogueira vs. durante o combate em campo aberto? → **A**: Híbrido Tático (*CrossCode + The Witcher*): Posturas (`1`/`2`) continuam alternáveis livremente em campo/combate para preservar a fluidez de combate 2D, mas Óleos só podem ser sintetizados na Fogueira (`InteractableCampfire`) gastando reagentes; fora da Fogueira, a tecla `Q` apenas aplica/alterna entre Óleos que já possuam cargas fabricadas no inventário.
- **Q2 (`RF-005` / `EC-004` — Modelo de Consumo e Durabilidade do Óleo na Lâmina)**: Como um Óleo sintetizado e aplicado na lâmina deve ser consumido durante o combate? → **A**: Cargas por Golpe Acertado (*Hit-Connected Charges* — Estilo *The Witcher 3*): cada síntese na Fogueira adiciona `@export var charges_per_craft: int = 8` cargas ao estoque daquele Óleo; golpes no ar não gastam cargas, apenas acertos confirmados (`hit_landed`) consomem `1` carga, revertendo automaticamente para `ElementOil.NONE` ao zerar.
- **Q3 (`RF-006` / `RF-007` — Layout da Bancada com o Grimório e Autonomia Dedutiva do Jogador)**: Como a Bancada de Alquimia na Fogueira deve interagir com o Grimório e com as receitas? → **A**: Bancada Anexada Lado a Lado ao Grimório + Zero Spoiler/Sugestão Automática: ao abrir a Fogueira, o Grimório e a Bancada de Alquimia aparecem lado a lado para o jogador estudar com calma as pistas e receitas; a bancada lista as receitas neutramente sem destacar nem sugerir qual é a correta ou falsa, cabendo 100% ao jogador juntar as peças e usar os reagentes certos (a ideia de mini-puzzles de alquimia estilo *Potion Permit* foi registrada no `docs/GDD.md` para implementação futura).
- **Q4 (`RF-003` / `RF-008` / `EC-002` — Escassez de Reagentes, Descanso na Fogueira e Adaptação Silenciosa dos Monstros via `/grill-me`)**: Como estruturar a escassez dos reagentes e o que acontece com os monstros quando a Caçadora descansa na Fogueira para reabastecer a região? → **A**: Escassez Tática + Descanso na Fogueira com Adaptação Silenciosa em Camadas (Nível 0 a 3): descansar na Fogueira restaura o HP da Caçadora, faz os reagentes (`InteractableReagent`) reaparecerem no mapa e reseta o HP/Stagger dos monstros, mas incrementa **silenciosamente nos bastidores** (sem avisos na UI da Fogueira nem no HUD do monstro) o Nível de Adaptação da Região (`region_alert_level: 0..3`); a cada nível, os monstros ficam mais rápidos/agressivos, aumentam sua resiliência de *Stagger* e punem severamente golpes Neutros/Resistidos (improviso ou óleo errado), enquanto a combinação exata da Fraqueza Verdadeira continua furando sua guarda com eficiência máxima.

### Assinatura do Portão de Qualidade 1
- [x] Todas as ambiguidades foram eliminadas e gravadas de volta na Spec.
- [x] A seção **Fora do Escopo (Non-Goals)** está clara e blindada.
- [x] **Verificado e aprovado pessoalmente pelo Desenvolvedor em:** `2026-10-21`
