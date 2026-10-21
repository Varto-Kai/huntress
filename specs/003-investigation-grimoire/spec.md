# 📋 Especificação da Feature: Sistema de Investigação (Coleta de Pistas) e Grimório Dinâmico (Greybox)

**Diretório da Feature**: `specs/003-investigation-grimoire`  
**Criado em**: 2026-10-21  
**Status no Ciclo SDD**: `[x] 2. Rascunho de Especificação` | `[x] 3. Clarificada (🔒 Portão 1 Aprovado)`  
**Entrada do Usuário**: "Vamos dar seguimento então na spec 3"

---

## 1. Cenários de Usuário & Testes (Histórias do Jogador e Fluxo Principal) *(obrigatório)*

### User Story 1 - Detecção e Inspeção de Pistas Físicas no Mapa (Prioridade: P1) 🎯 MVP

> **Como** a Caçadora explorando uma zona de caça,  
> **Quero** detectar vestígios físicos deixados pelo monstro no cenário (pegadas profundas, carcaças dilaceradas, secreções ácidas/ígneas, marcas de garras) e interagir com eles quando estiver no raio de alcance,  
> **Para que** eu possa coletar evidências concretas sobre a criatura antes de enfrentá-la em seu covil.

**Por que esta prioridade**: Materializa a **Fase 1 do Core Loop (Investigação)** e o **Pilar de Design #1 (*Conhecimento = Poder Real em Combate*)** do GDD. Sem a coleta desacoplada de pistas no mundo, o Grimório não recebe dados e a preparação tática não existe.

**Teste Independente (Greybox)**: Na cena Sandbox de Investigação, a Caçadora caminha até 3 ou mais nós de pista (`ClueNode` em Greybox com formas/cores distintas por tipo de vestígio). Ao entrar no raio de detecção (`InteractionArea`), surge um indicador visual de interação (`[E] Inspecionar`) e o destaque da pista mais próxima. Ao acionar o comando de interação (`interact`), a pista é inspecionada, muda seu estado visual para "Já Inspecionada" e emite um sinal desacoplado com os dados da pista (`ClueData`).

**Fluxo Principal e Cenários de Aceitação**:

1. **Dado** que a Caçadora se aproxima de uma pista não inspecionada (`ClueNode`) dentro do raio do seu `PlayerInteractionComponent`, **Quando** a pista entra na área de alcance, **Então** ela é marcada como candidata ativa de interação e exibe seu feedback visual *Greybox* (indicador de prompt e destaque).
2. **Dado** que a Caçadora tem uma pista candidata ativa no alcance e está em `IdleState` ou `MoveState`, **Quando** o jogador aciona `interact`, **Então** inicia-se uma canalização curta parametrizada (`@export var inspect_duration: float = 0.5`, com barra de progresso *Greybox* e suporte a `0.0` para modo instantâneo), cancelável imediatamente por Esquiva, Movimento de afastamento ou Dano recebido (`EC-003`), e ao completar marca o `ClueNode` como coletado emitindo o sinal de pista descoberta.
3. **Dado** que uma pista já foi inspecionada anteriormente na sessão, **Quando** a Caçadora passa novamente por ela, **Então** a pista exibe cor/opacidade de vestígio já analisado e permite apenas releitura rápida ou ignora re-coleta duplicada no progresso do Grimório.

---

### User Story 2 - Registro Desacoplado e Desbloqueio de Conhecimento no Grimório (Prioridade: P2)

> **Como** uma Caçadora tática inspirada em *The Witcher*,  
> **Quero** que cada pista inspecionada (seja um vestígio autêntico do monstro ou uma **pista falsa / enganosa** do ambiente) alimente o **Grimório**, permitindo-me julgar e descartar manualmente pistas contraditórias para revelar a verdadeira **Identidade**, **Comportamentos Letais**, **Fraquezas de Estilo** e a **Fórmula do Óleo Fabricável** (que exigirá materiais na `SPEC-004`),  
> **Para que** a leitura atenta das evidências seja recompensada e a falta de atenção induza ao erro tático (como desperdiçar materiais fabricando o Óleo errado).

**Por que esta prioridade**: Conecta os dados coletados na exploração (`SPEC-003`) diretamente à taxonomia tática criada na `SPEC-002` (`CombatTypes.StyleType`, `CombatTypes.ElementType` e `DefenseProfileData`) e prepara a alquimia baseada em materiais da `SPEC-004`, exigindo raciocínio dedutivo real do jogador.

**Teste Independente (Greybox)**: Ao coletar pistas verdadeiras e pistas falsas (*Red Herrings*) na Sandbox, o sistema do Grimório registra cada `ClueData` sob o `monster_id` investigado. Se houver uma pista falsa ativa (não descartada) contradizendo a pista verdadeira, a síntese do Grimório exibe a conclusão contaminada/enganosa (ou alerta de conflito), induzindo o jogador desatento a acreditar na fraqueza/receita de óleo errada. Quando o jogador lê as descrições no Grimório e clica em **"Descartar Pista"** (`toggle_clue_discarded`) na pista falsa, o Grimório recalcula imediatamente a síntese verdadeira e emite `monster_deduction_solved`.

**Cenários de Aceitação**:

1. **Dado** que o Grimório possui entradas de monstros configuradas via `Custom Resources` (`MonsterGrimoireEntryData`) inicialmente com campos ocultos (`???`), **Quando** uma nova pista (`ClueData`, autêntica ou falsa) é registrada, **Então** o Grimório adiciona a pista à lista de evidências daquela categoria (vínculo 1:1 — ex.: Pegada $\rightarrow$ Couraça/Estilo; Resíduo $\rightarrow$ Elemento & Receita de Óleo Fabricável; Marca $\rightarrow$ Comportamento/Stagger) e emite `clue_registered`.
2. **Dado** que o jogador coletou uma **pista falsa (`is_false_lead = true`)** e não a descartou no Grimório, **Quando** o Grimório sintetiza a recomendação daquela seção, **Então** a pista falsa contamina a recomendação exibida (apontando um Estilo ou Receita de Óleo incorreto para enganar o jogador desatento).
3. **Dado** que o jogador analisa os textos das pistas no Grimório e identifica a contradição, **Quando** ele aciona **"Descartar Pista"** na pista falsa (mantendo as pistas verdadeiras ativas), **Então** o Grimório risca visualmente a pista descartada, revela a Fraqueza real + a Fórmula de Materiais do Óleo correto e emite `monster_research_completed(monster_id)`.

---

### User Story 3 - Interface Greybox do Grimório e Validação Tática na Sandbox (Prioridade: P3)

> **Como** jogador,  
> **Quero** abrir e fechar o painel do Grimório (`toggle_grimoire`) a qualquer momento para consultar o progresso de investigação de cada criatura, vendo claramente o que ainda está oculto (`???`) e o que já foi descoberto (Estilo recomendado, Óleo eficaz, Resistências a evitar e Comportamento),  
> **Para que** eu possa decidir qual postura (`FAST_STEEL` vs. `HEAVY_IMPACT`) e qual óleo (`IGNIS_OIL` vs. `VITRIOL_ACID`) usar contra o alvo de teste na própria arena Sandbox.

**Por que esta prioridade**: Fecha o ciclo completo de validação em *Greybox*: Investigar pistas $\rightarrow$ Ler o Grimório $\rightarrow$ Aplicar o Estilo/Óleo descoberto contra o monstro alvo.

**Teste Independente (Greybox)**: Na cena `sandbox_investigation.tscn`, o jogador começa sem saber qual perfil defensivo um *Monstro Misterioso (Greybox)* possui (suas etiquetas de fraqueza começam ocultas como `???`). O jogador coleta as pistas espalhadas pela sala, abre o Grimório (`Tab` ou `G`), lê a síntese descoberta (ex.: Couraça Pesada vulnerável a `HEAVY_IMPACT` + `VITRIOL_ACID`), equipa a combinação indicada e derrota/quebra a postura do alvo.

**Cenários de Aceitação**:

1. **Dado** que o jogador aciona `toggle_grimoire`, **Quando** o painel *Greybox* do Grimório se abre, **Então** ele lista as criaturas conhecidas/em investigação, exibe a contagem de pistas (`X / Y`), destaca visualmente as informações recém-descobertas e opera em tempo real tático por padrão (`@export var pause_tree_on_open: bool = false`), suprimindo inputs de ataque/locomoção da Caçadora enquanto aberto e fechando automaticamente o painel caso a Caçadora sofra dano (`EC-003`).
2. **Dado** que uma pista de fraqueza foi descoberta no Grimório, **Quando** o jogador visualiza a entrada do monstro e enfrenta o alvo correspondente na Sandbox, **Então** o sistema funciona estritamente como **Conhecimento Real + Telemetria Desbloqueada no Alvo** (mantendo a matemática do `DefenseProfileData` da `SPEC-002` 100% imutável sem bônus artificial de status, e revelando no Grimório e no HUD acima do monstro as etiquetas de Fraqueza/Resistência que antes apareciam como `???`).

---

## 2. Casos de Borda (Edge Cases) e O Que Dá Errado *(obrigatório)*

| ID | Cenário de Borda / Estado de Erro | Comportamento Esperado (Tratamento) |
| :--- | :--- | :--- |
| **`EC-001`** | **Duas ou mais pistas físicas (`ClueNode`) sobrepostas ou dentro do raio de interação ao mesmo tempo** | O `PlayerInteractionComponent` seleciona deterministicamente apenas **1 pista ativa por vez** — priorizando a pista **ainda não inspecionada mais próxima** do centro da Caçadora — evitando disparar duas inspeções simultâneas com um único aperto de botão. |
| **`EC-002`** | **Tentativa de registrar a mesma pista (`clue_id`) múltiplas vezes** | O `GrimoireComponent` verifica idempotência por `clue_id`: se a pista já constar como descoberta, não incrementa contadores nem re-emite sinais de desbloqueio inédito, apenas emite sinal para abrir/focar a nota caso o jogador re-inspecione o vestígio. |
| **`EC-003`** | **Jogador tenta atacar ou esquivar enquanto a UI do Grimório está aberta (ou recebe ataque durante inspeção)** | Enquanto o Grimório estiver aberto (ou durante inspeção), os inputs de ataque são suprimidos para não disparar golpes acidentais ao navegar na interface; se a Caçadora sofrer dano durante uma inspeção no mundo, a inspeção é cancelada imediatamente com transição segura para `PlayerHurtState`. |
| **`EC-004`** | **Jogador tenta interagir com pista durante `DodgeState`, `AttackState` ou `HurtState`** | A interação com pistas (`interact`) só é permitida quando a Caçadora está em `IdleState` ou `MoveState`, ignorando o comando durante estados de compromisso de combate. |
| **`EC-005`** | **`ClueData` ou `MonsterGrimoireEntryData` nulo/inválido ou referenciando `monster_id` inexistente** | O sistema ignora o registro com aviso defensivo (`push_warning`), mantendo o estado do Grimório íntegro sem *crash*. |
| **`EC-006`** | **Jogador descarta por engano uma pista verdadeira ou deixa uma pista falsa ativa no Grimório** | O descarte é reversível a qualquer momento (`toggle_clue_discarded`): se uma pista verdadeira for descartada, a seção correspondente volta a exibir `???` (ou exibe a conclusão enganosa de uma pista falsa ativa); restaurar a pista verdadeira e descartar a falsa restabelece imediatamente a síntese correta. |

---

## 3. Requisitos Funcionais Numerados *(obrigatório)*

- **`RF-001` (FR-001)**: O sistema DEVE prover um `PlayerInteractionComponent` (`Area2D`) acoplado à Caçadora capaz de detectar nós interativos de pista (`InteractableClue` / `ClueNode`) em uma camada de colisão dedicada, selecionando sempre a pista não coletada mais próxima quando houver múltiplos candidatos (`EC-001`).
- **`RF-002` (FR-002)**: O nó `InteractableClue` DEVE ser configurável com um `ClueData` (`Custom Resource`) e suportar estados visuais *Greybox* distintos para **Não Inspecionada**, **Em Alcance (Focada)**, **Em Inspeção** e **Já Inspecionada**, executando uma canalização curta cancelável (`@export var inspect_duration: float = 0.5` com barra de progresso *Greybox* e suporte a `0.0` para inspeção instantânea), abortada imediatamente se a Caçadora esquivar, sair do raio ou sofrer dano (`EC-003`).
- **`RF-003` (FR-003)**: A comunicação entre a inspeção de uma pista (`InteractableClue` / `PlayerInteractionComponent`) e o Grimório DEVE ocorrer exclusivamente via `signals` nativos da Godot (*Signals First* — Cláusula 1.2.3 da Constituição), proibindo referências diretas (`get_node`) da pista para a UI do Grimório.
- **`RF-004` (FR-004)**: O sistema de dados do Grimório DEVE utilizar `Custom Resources` tipados (`ClueData` e `MonsterGrimoireEntryData`) com **vínculo determinístico 1:1 por categoria de evidência** (**Identidade/Lore Tático**, **Comportamento Letal / Janela de Stagger**, **Fraqueza/Resistência de Estilo (`CombatTypes.StyleType`)** e **Fraqueza Elemental + Fórmula de Materiais do Óleo Fabricável (`CombatTypes.ElementType` + `oil_recipe_materials`)**), suportando tanto **pistas autênticas** quanto **pistas falsas (`is_false_lead = true`)** que apontam conclusões enganosas se não forem descartadas pelo jogador.
- **`RF-005` (FR-005)**: O gerenciador de estado do Grimório (`GrimoireComponent` / `GrimoireTracker`) DEVE manter o registro idempotente de pistas coletadas (`EC-002`), permitir ao jogador **Descartar / Restaurar manualmente qualquer pista coletada (`toggle_clue_discarded`)** (`EC-006`), resolver a síntese ativa de cada seção (exibindo a recomendação enganosa caso uma pista falsa daquela seção permaneça ativa, ou a recomendação verdadeira quando apenas a pista autêntica estiver ativa), sincronizar a revelação das etiquetas no HUD do alvo sem alterar artificialmente o `DefenseProfileData` (`SPEC-002`), e emitir sinais ao registrar pista (`clue_discovered`), atualizar julgamento/seção (`entry_updated`) e solucionar a dedução completa do monstro (`monster_research_completed`).
- **`RF-006` (FR-006)**: O sistema DEVE prover uma interface *Greybox* para o Grimório (`GrimoireUIGreybox`) acionada pela ação `toggle_grimoire`, operando em **Tempo Real Tático** por padrão (`@export var pause_tree_on_open: bool = false`), suprimindo inputs de ataque/locomoção da Caçadora enquanto aberta, fechando automaticamente se a Caçadora sofrer dano (`EC-003`) e exibindo: lista de monstros, progresso de pistas, cartões de pistas coletadas com botão interativo `[Descartar Pista / Restaurar]` e o painel tático de Síntese (Estilo, Óleo Fabricável + Materiais requeridos, Resistências e Comportamento).
- **`RF-007` (FR-007)**: Deve existir um feedback visual rápido de notificação (*Toast / Banner Greybox*) na HUD sempre que uma nova pista for coletada no mapa, informando o título da pista e qual seção do Grimório foi atualizada sem forçar a abertura imediata da tela cheia do Grimório.
- **`RF-008` (FR-008)**: Todos os parâmetros de *Game Feel* e configuração de investigação — `interaction_radius`, `inspect_duration`, `pause_tree_on_open`, `notification_display_duration`, cores *Greybox* por tipo/estado de pista e textos de bloqueio (`locked_placeholder_text`) — DEVEM ser expostos via `@export` para ajuste humano no Inspector.
- **`RF-009` (FR-009)**: Deve existir uma cena *Sandbox de Investigação & Grimório* (`res://tests/sandboxes/sandbox_investigation.tscn`) combinando uma zona com pistas físicas de 2 criaturas distintas (Couraçado e Fera Ágil), a UI do Grimório e os respectivos alvos de combate para validar o fluxo *Investigar $\rightarrow$ Consultar Grimório $\rightarrow$ Lutar com a Fraqueza Descoberta*.

### Entidades de Domínio Envolvidas

- **`ClueData` (`Resource`)**: Representa uma pista física única (`clue_id`, `monster_id`, `title`, `description`, `clue_category`, ` unlocks_section`, `visual_color`).
- **`MonsterGrimoireEntryData` (`Resource`)**: Ficha tática de um monstro no Grimório (`monster_id`, `display_name`, `classification`, `behavior_summary`, `stagger_hint`, `recommended_style`, `recommended_element`, `resisted_style`, lista de `ClueData` associadas e vínculo com `DefenseProfileData`).
- **`InteractableClue` (`Area2D`)**: Entidade física posicionada no mapa representando um vestígio inspecionável em *Greybox*.
- **`GrimoireTracker` / `GrimoireComponent`**: Lógica pura e testável que processa a coleção de pistas e resolve o estado de visibilidade de cada campo do Grimório.

---

## 4. Fora do Escopo (Non-Goals) 🚫 *(obrigatório)*

> *Tão importante quanto o que está no escopo. Qualquer item listado abaixo NÃO será projetado nem implementado nesta feature.*

- **Não inclui**: Estações de Fogueira/Acampamento, restrição de troca de *Loadout* apenas em pontos seguros ou criação alquímica de itens/bombas (pertencem à **`SPEC-004` — Sistema de Preparação**).
- **Não inclui**: Inteligência Artificial completa do Boss, máquina de estados do monstro ou arena final do covil (pertencem à **`SPEC-005`**).
- **Não inclui**: Sistema de salvamento em disco criptografado (`SaveManager`) ou múltiplos contratos na Vila (pertencem à **`SPEC-006`**).
- **Não inclui**: Arte final de interface (pergaminhos ilustrados em Pixel Art, ícones definitivos, fontes customizadas ou dublagem) — toda a interface e as pistas no chão usarão *Greybox* geométrico limpo e legível.

---

## 5. Critérios de Sucesso Mensuráveis *(obrigatório)*

- **`SC-001`**: Coletar 100% das pistas de uma criatura atualiza o Grimório em tempo real via sinais (zero referências diretas entre `InteractableClue` e `GrimoireUIGreybox`), com cobertura de testes unitários $\ge 90\%$ na lógica do `GrimoireTracker`.
- **`SC-002`**: Quando 2 ou mais pistas estão dentro do raio de interação da Caçadora, 100% dos comandos `interact` acionam exclusivamente a pista não inspecionada mais próxima, e re-inspecionar uma pista já coletada nunca duplica contadores (`EC-001`, `EC-002`).
- **`SC-003`**: Na cena `sandbox_investigation.tscn`, um jogador que inicia sem informações visíveis (`???`) consegue inspecionar as pistas no chão, abrir o Grimório, identificar a Fraqueza exata de Estilo/Óleo de ambos os monstros e validar o combate contra os alvos em menos de 45 segundos.

---

## 6. Clarifications — 🔒 PORTÃO DE QUALIDADE 1 (Verificação Pessoal do Desenvolvedor)

> *Preenchido durante `/speckit-clarify` (Etapa 3). O agente aponta ambiguidades, faz perguntas fechadas com opções de melhoria questionando sempre o **porquê** da decisão, e grava as respostas diretamente aqui e nas seções correspondentes acima.*

### Session 2026-10-21

- **Q1 (`RF-004` / `RF-005` — Modelo de Desbloqueio no Grimório por Pista)**: Como a coleta de cada pista física no mapa deve destravar as seções táticas do monstro no Grimório? → **A**: Vínculo 1:1 Determinístico por Evidência + Síntese Completa no 100%: cada pista física revela imediatamente a seção exata que ela prova (ex.: Pegada Profunda $\rightarrow$ Couraça/Estilo; Carcaça Corroída $\rightarrow$ Elemento/Óleo; Marca de Garra $\rightarrow$ Comportamento/Stagger), premiando a leitura dedutiva do mundo mesmo em investigações parciais.
- **Q2 (`RF-002` / `EC-003` — Tempo de Inspeção de Pista e Cancelamento)**: Ao interagir com uma pista física no mapa, como deve funcionar o tempo de inspeção e o cancelamento? → **A**: Canalização curta cancelável (`@export var inspect_duration: float = 0.5` com barra de progresso *Greybox*, suportando `0.0` para instantâneo), cancelável imediatamente por Esquiva, Movimento para fora do raio ou Dano recebido, dando peso tátil de investigação em campo hostil sem travar a responsividade.
- **Q3 (`RF-006` / `EC-003` — Comportamento do Mundo ao Abrir o Grimório)**: Quando o jogador abre a interface do Grimório, como o mundo e os inputs da Caçadora devem se comportar? → **A**: Tempo Real Tático com bloqueio de ataque/movimento da Caçadora (parametrizável via `@export var pause_tree_on_open: bool = false`) e fechamento automático caso sofra dano, mantendo a tensão de consultar o diário em local seguro sem perder a opção de pausa no Inspector.
- **Q4 (`US-003` / `RF-005` — Efeito da Investigação no Combate vs. Matemática do Alvo)**: Qual deve ser a relação entre descobrir as pistas no Grimório e o combate contra o monstro alvo? → **A**: Conhecimento Real + Telemetria Desbloqueada no Alvo (Zero Bônus Artificial de Status): a matemática do `DefenseProfileData` (`SPEC-002`) é 100% imutável; investigar revela no Grimório e no HUD acima da cabeça do monstro quais são suas Fraquezas/Resistências (que antes apareciam como `???`), recompensando o domínio e a preparação real do jogador.
- **Q5 (`RF-004` / `RF-005` / `RF-006` — Pistas Falsas, Julgamento Manual no Grimório e Fórmulas de Óleos Fabricáveis)**: Como as Pistas Falsas (*Red Herrings*) e a referência aos Óleos Fabricáveis devem funcionar no Grimório? → **A**: Julgamento Manual no Grimório (Modo Detetive Ativo): existem pistas falsas no cenário (`is_false_lead = true`) que entram no Grimório lado a lado com as verdadeiras e contaminam a recomendação tática (podendo induzir o jogador desatento a fabricar o Óleo errado com seus materiais na `SPEC-004`); o jogador atento deve ler as descrições e clicar manualmente em **"Descartar Pista"** (`toggle_clue_discarded`) na pista contraditória para destravar a síntese verdadeira do monstro (incluindo a fórmula de materiais do Óleo eficaz).

### Assinatura do Portão de Qualidade 1
- [x] Todas as ambiguidades foram eliminadas e gravadas de volta na Spec.
- [x] A seção **Fora do Escopo (Non-Goals)** está clara e blindada.
- [x] **Verificado e aprovado pessoalmente pelo Desenvolvedor em:** `2026-10-21`
