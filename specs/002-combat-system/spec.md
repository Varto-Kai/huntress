# 📋 Especificação da Feature: Sistema de Combate Base, Hitbox/Hurtbox e Estilos/Fraquezas (Greybox)

**Diretório da Feature**: `specs/002-combat-system`  
**Criado em**: 2026-10-20  
**Status no Ciclo SDD**: `[x] 2. Rascunho de Especificação` | `[x] 3. Clarificada (🔒 Portão 1 Aprovado)`  
**Entrada do Usuário**: "Iniciar a SPEC-002 — Sistema de Combate Base, Hitbox/Hurtbox e Estilos/Fraquezas (Greybox)"

---

## 1. Cenários de Usuário & Testes (Histórias do Jogador e Fluxo Principal) *(obrigatório)*

### User Story 1 - Componentes Modulares de Vida, Hitbox e Hurtbox (Prioridade: P1) 🎯 MVP

> **Como** a Caçadora (ou qualquer entidade de combate no mundo),  
> **Quero** causar e receber dano através de áreas de colisão independentes (`HitboxComponent` e `HurtboxComponent`) conectadas a um gerenciador de vida (`HealthComponent`) e resposta de impacto (*knockback* / *hitstop*),  
> **Para que** cada golpe tenha peso tátil imediato (*CrossCode Feel*) e respeite janelas de invencibilidade (como os *i-frames* da esquiva da `SPEC-001` e os *i-frames* pós-dano).

**Por que esta prioridade**: Sem o tripé `HealthComponent` + `HitboxComponent` + `HurtboxComponent`, não existe interação física de combate entre a Caçadora e os monstros. É o alicerce reutilizável exigido pela Cláusula 1.2.1 da Constituição.

**Teste Independente (Greybox)**: Na cena Sandbox de Combate, a Caçadora ataca um Boneco de Treino (*Target Dummy* em Greybox) e observa a barra/indicador de HP do alvo diminuir, aplicando impulso de recuo (*knockback*), breve congelamento de impacto (*hitstop*) e piscar visual de dano; além disso, um emissor de perigo de teste tenta atingir a Caçadora durante os *i-frames* do `Dodge` (sendo completamente ignorado) e fora de *i-frames* (causando transição para `PlayerHurtState` com *knockback* e *i-frames* pós-dano).

**Fluxo Principal e Cenários de Aceitação**:

1. **Dado** que um `HitboxComponent` ativo colide com um `HurtboxComponent` de outra equipe/facção (ex.: Player $\rightarrow$ Monstro), **Quando** o alvo não está invulnerável, **Então** o `HurtboxComponent` calcula o dano final com base no `AttackData` recebido, repassa ao `HealthComponent` (que reduz o HP e emite `damaged`), aplica a força de *knockback* na direção do impacto e aciona o feedback de acerto.
2. **Dado** que a Caçadora está no estado `DodgeState` com *i-frames* ativos (`RF-006` da `SPEC-001`) ou em janela de *i-frames* pós-dano, **Quando** uma `HitboxComponent` inimiga atravessa sua `HurtboxComponent`, **Então** nenhum dano ou *knockback* é aplicado e um sinal de impacto ignorado (`hit_ignored`) é emitido.
3. **Dado** que uma entidade recebe dano suficiente para zerar seu HP atual, **Quando** `current_health` atinge `0`, **Então** o `HealthComponent` emite `health_depleted` (`died`) exatamente uma única vez e desativa novas recepções de dano.

---

### User Story 2 - Ataque Corpo-a-Corpo Direcional, Combos por Estilo e *Dodge Cancel* (Prioridade: P2)

> **Como** a Caçadora,  
> **Quero** executar golpes e combos corpo-a-corpo na direção para a qual estou olhando (`facing_direction`), com fases claras de preparação (*windup*), janela ativa de corte (*active hitbox*) e recuperação (*recovery*), podendo cancelar o ataque com Esquiva no *windup* ou no *recovery*,  
> **Para que** o combate combine posicionamento deliberado, peso nos golpes e fluidez tática estilo *CrossCode*.

**Por que esta prioridade**: Conecta a locomoção/orientação da `SPEC-001` ao sistema de combate, adicionando os estados `PlayerAttackState` e `PlayerHurtState` à `StateMachine` da protagonista.

**Teste Independente (Greybox)**: Na cena Sandbox, pressionar o botão de ataque faz a Caçadora entrar no `AttackState`, projetar uma forma geométrica vermelha/amarela (`HitboxComponent` em Greybox) na frente da sua `facing_direction` durante a janela ativa, encadear combos se pressionar ataque novamente (3 cortes rápidos na Postura Rápida ou 2 impactos pesados na Postura Pesada) e permitir *Dodge Cancel* durante o *windup* ou *recovery* (bloqueando durante o frame *active*, que guarda o comando no *Input Buffer*).

**Cenários de Aceitação**:

1. **Dado** que a Caçadora está em `IdleState` ou `MoveState`, **Quando** o jogador aciona o comando de ataque, **Então** a `StateMachine` transita para `AttackState` (Golpe 1 do Estilo ativo), posiciona a `HitboxComponent` alinhada à `facing_direction` e executa as fases parametrizadas (`windup_duration` $\rightarrow$ `active_duration` $\rightarrow$ `recovery_duration`) com um leve avanço físico (`attack_step_speed`).
2. **Dado** que a Caçadora está executando um golpe do combo e ainda há golpes seguintes na cadeia do Estilo ativo, **Quando** o jogador aciona ataque durante a janela de *active* ou *recovery* (com *Input Buffer*), **Então** ao concluir a janela atual a Caçadora avança imediatamente para o próximo golpe da sequência (permitindo redirecionar `facing_direction` se houver tecla direcional pressionada).
3. **Dado** que a Caçadora está na fase de *windup* ou *recovery* do `AttackState` e a esquiva não está em *cooldown*, **Quando** o jogador aciona `Dodge` (ou quando há um `Dodge` armazenado no *Input Buffer* durante a fase *active*), **Então** o `AttackState` desliga imediatamente a `HitboxComponent` e transita para `DodgeState`.

---

### User Story 3 - Estilos de Luta, Elementos/Óleos e Multiplicadores de Fraqueza/Quebra de Postura (Prioridade: P3)

> **Como** uma Caçadora tática inspirada em *The Witcher* e *CrossCode*,  
> **Quero** alternar entre Estilos de Luta (**Postura Rápida / Corte** com combo de 3 golpes vs. **Postura Pesada / Impacto** com combo de 2 golpes) e aplicar modificadores elementais/óleos que interajam com a tabela de **Fraquezas, Resistências e Postura (*Stagger*)** do alvo,  
> **Para que** atacar um monstro às cegas cause dano reduzido, enquanto usar o Estilo e o Óleo corretos amplifique o dano e quebre sua postura (*Break / Stagger*).

**Por que esta prioridade**: Materializa os **Pilares de Design #1 e #3 do GDD** (*Conhecimento = Poder Real em Combate*): prepara toda a matemática e os `Custom Resources` que serão alimentados pelo Grimório (`SPEC-003`) e pelo Sistema de Preparação (`SPEC-004`).

**Teste Independente (Greybox)**: Na cena Sandbox, existem 2 Bonecos de Treino com perfis de defesa distintos (ex.: um *Dummy Couraçado* resistente a Corte Rápido e vulnerável a Impacto Pesado + Óleo Ígneo/Ácido, e um *Dummy Ágil* vulnerável a Corte Rápido). O jogador alterna o Estilo e o Óleo ativos da Caçadora com teclas de atalho e verifica na HUD de telemetria a diferença imediata entre um acerto resistido (dano reduzido, baixo avanço de *Stagger*), um acerto neutro e um acerto explorando a Fraqueza (dano amplificado + preenchimento rápido da barra de *Stagger* até atordoar o alvo).

**Cenários de Aceitação**:

1. **Dado** que um alvo possui um perfil de defesa (`DefenseProfileData`) configurando resistências e fraquezas por Estilo/Elemento, **Quando** seu `HurtboxComponent` recebe um `AttackData`, **Então** o dano base e o dano de postura (*stagger damage*) são multiplicados pelos fatores correspondentes daquele perfil.
2. **Dado** que o medidor de postura (*Stagger Meter*) do alvo atinge o limite máximo (`max_stagger`) ao ser atingido por ataques eficazes, **Quando** a quebra de postura ocorre, **Então** o alvo entra em estado vulnerável (*Staggered / Break*) por uma duração parametrizada (`stagger_duration`), sofrendo dano extra (`staggered_damage_multiplier`) e mudando sua cor de Greybox.

---

## 2. Casos de Borda (Edge Cases) e O Que Dá Errado *(obrigatório)*

| ID | Cenário de Borda / Estado de Erro | Comportamento Esperado (Tratamento) |
| :--- | :--- | :--- |
| **`EC-001`** | **Múltiplos acertos do mesmo golpe único no mesmo alvo** (a `HitboxComponent` permanece sobreposta à `HurtboxComponent` por vários frames físicos durante `active_duration`) | Cada ativação única de um golpe do combo registra os `HurtboxComponent` já atingidos em uma lista temporária de exclusão, garantindo exatamente **1 acerto por alvo por golpe da cadeia** (limpando a lista ao iniciar o próximo golpe do combo). |
| **`EC-002`** | **Uma única `HitboxComponent` atinge dois alvos simultaneamente no mesmo frame** | Ambos os alvos processam seu próprio cálculo de dano/fraqueza e *knockback* de forma independente, mas o efeito de *hitstop* na Caçadora é acionado apenas uma vez por golpe para não congelar o jogo em dobro. |
| **`EC-003`** | **Caçadora recebe dano enquanto está no meio do `AttackState` (fases *windup*, *active* ou *recovery*)** | O `AttackState` é abortado com segurança (`exit()` desliga imediatamente a `HitboxComponent` para evitar "hitbox fantasma" ligada), a Caçadora transita para `PlayerHurtState` sofrendo *knockback* e ativa os *i-frames* pós-dano (`post_hit_invulnerability_duration`). |
| **`EC-004`** | **Cancelamento de ataque por Esquiva (`AttackState` $\rightarrow$ `DodgeState`)** | Se acionado em *windup* ou *recovery*, transita imediatamente desligando a `HitboxComponent` no `exit()`. Se acionado durante *active*, o comando fica retido no *Input Buffer* e dispara a transição para `DodgeState` no exato frame em que a fase *active* termina e entra em *recovery*. |
| **`EC-005`** | **`AttackData` ou `DefenseProfileData` ausente/nulo em um componente** | O sistema aplica valores padrão seguros (`base_damage = 10.0`, multiplicador `1.0`) e emite aviso defensivo sem causar *crash* ou divisão por zero. |

---

## 3. Requisitos Funcionais Numerados *(obrigatório)*

- **`RF-001` (FR-001)**: O sistema DEVE prover um `HealthComponent` reutilizável que gerencie `max_health`, `current_health` e janela de invulnerabilidade pós-dano (`post_hit_invulnerability_duration`), emitindo os sinais `damaged(amount, knockback_vector)`, `healed(amount)`, `health_changed(current, max)`, `invulnerability_changed(is_invulnerable)` e `health_depleted()`.
- **`RF-002` (FR-002)**: O sistema DEVE prover um `HitboxComponent` (`Area2D`) e um `HurtboxComponent` (`Area2D`) desacoplados que se comuniquem exclusivamente via `AttackData`, garantindo identificação de equipe/facção (`team`: Player vs. Enemy) e que um mesmo golpe não atinja o mesmo `HurtboxComponent` múltiplas vezes na mesma ativação (`EC-001`).
- **`RF-003` (FR-003)**: O `HurtboxComponent` DEVE consultar os estados de invulnerabilidade da entidade (incluindo os *i-frames* do `PlayerDodgeState` da `SPEC-001` e os *i-frames* pós-dano do `HealthComponent`) antes de aplicar dano, ignorando o impacto e emitindo `hit_ignored` quando invulnerável.
- **`RF-004` (FR-004)**: O cálculo de impacto DEVE suportar **Estilos de Luta** (`FAST_STEEL` / Corte Rápido vs. `HEAVY_IMPACT` / Quebra-Guarda) e **Modificadores Elementais/Óleos** (`NONE`, `IGNIS_OIL`, `VITRIOL_ACID`) contrastados contra um `DefenseProfileData` (`Custom Resource`) do alvo, aplicando multiplicadores de **Resistência** (ex.: `0.5x`), **Neutro** (`1.0x`) ou **Fraqueza** (ex.: `1.5x` a `2.0x`) tanto no dano de vida quanto no dano de postura (*Stagger*).
- **`RF-005` (FR-005)**: A `StateMachine` da Caçadora DEVE ser expandida com os estados `PlayerAttackState` e `PlayerHurtState`, posicionando e rotacionando a `HitboxComponent` de acordo com a `facing_direction` atual (`SPEC-001`).
- **`RF-006` (FR-006)**: O `PlayerAttackState` DEVE orientar os golpes por `facing_direction` (permitindo redirecionamento entre golpes se houver input direcional) e suportar cadeias de combo configuráveis por Estilo via *Input Buffer*: **3 cortes ágeis** na Postura Rápida (`FAST_STEEL`) e **2 impactos pesados** na Postura Pesada (`HEAVY_IMPACT`).
- **`RF-007` (FR-007)**: O cancelamento de ataque por Esquiva (*Dodge Cancel*) DEVE ser permitido durante as fases de *Windup* e *Recovery* do golpe, mas bloqueado durante os frames de *Active Hitbox* (armazenando o comando no *Input Buffer* para disparar assim que entrar em *Recovery*).
- **`RF-008` (FR-008)**: Quando a Caçadora sofrer dano válido fora de *i-frames*, ela DEVE transitar imediatamente para `PlayerHurtState` por uma duração configurável (`hurt_duration`), abortando qualquer ataque ativo com segurança (`EC-003`), sofrendo impulso de *knockback* desacelerado por atrito e ativando uma janela de *i-frames* pós-dano (`post_hit_invulnerability_duration`) com feedback visual de piscar no Greybox.
- **`RF-009` (FR-009)**: Todos os parâmetros de *Game Feel* de combate — `windup_duration`, `active_duration`, `recovery_duration`, `combo_input_buffer_time`, `attack_step_speed`, `knockback_force`, `hurt_duration`, `post_hit_invulnerability_duration`, `hitstop_duration`, multiplicadores de fraqueza/resistência, `max_stagger`, `stagger_decay_rate`, `stagger_duration` e `staggered_damage_multiplier` — DEVEM ser expostos com `@export` em `Custom Resources` para ajuste no Inspector.
- **`RF-010` (FR-010)**: Deve existir uma representação visual *Greybox* para o combate (polígono de corte visível na `HitboxComponent` durante a fase *active*, cores distintas no corpo para *Windup*, *Active*, *Hurt* e *Staggered*, e barras geométricas de HP/Postura) e uma cena *Sandbox de Combate* (`res://tests/sandboxes/sandbox_combat.tscn`) contendo alvos de teste (*Combat Dummies*) e um emissor de ataque inimigo para validação completa.

### Entidades de Domínio Envolvidas

- **`AttackData` (`Resource` / Payload)**: Estrutura contendo dano base, dano de postura (*stagger*), tipo de Estilo, elemento/óleo aplicado, força e direção de *knockback*.
- **`CombatStyleData` & `AttackStepData` (`Resource`)**: Configuração de um Estilo de Luta da Caçadora e dos golpes individuais de sua cadeia de combo (*windup*, *active*, *recovery*, dimensões da hitbox, multiplicador de dano/stagger e passo à frente).
- **`DefenseProfileData` (`Resource`)**: Perfil defensivo de uma criatura definindo multiplicadores de dano e de quebra de postura por Estilo/Elemento, limiar `max_stagger` e duração de atordoamento.
- **Boneco de Treino / Alvo Tático (`CombatDummy`)**: Entidade Greybox equipada com `HealthComponent`, `StaggerComponent`, `HurtboxComponent`, `MovementComponent` (para receber *knockback*) e barras visuais de HP/Postura.

---

## 4. Fora do Escopo (Non-Goals) 🚫 *(obrigatório)*

> *Tão importante quanto o que está no escopo. Qualquer item listado abaixo NÃO será projetado nem implementado nesta feature.*

- **Não inclui**: Coleta de pistas no mapa ou interface do Grimório (pertencem à **`SPEC-003`**).
- **Não inclui**: Menus de acampamento/fogueira ou inventário completo de consumíveis e bombas (pertencem à **`SPEC-004`**).
- **Não inclui**: Inteligência Artificial complexa de Boss, fases de fúria ou arenas definitivas (pertencem à **`SPEC-005`** — na `SPEC-002` usaremos Bonecos de Treino e um emissor de perigo/ataque simples em Greybox).
- **Não inclui**: Arte final em Pixel Art, animações de espada desenhadas à mão, partículas finais ou efeitos sonoros definitivos (validação 100% em *Greybox*).

---

## 5. Critérios de Sucesso Mensuráveis *(obrigatório)*

- **`SC-001`**: Um golpe único da Caçadora sobreposto a um alvo durante toda a janela ativa (`active_duration`) aplica dano exatamente **1 vez** naquele alvo (zero múltiplos acertos acidentais por frame).
- **`SC-002`**: Atingir um alvo usando o Estilo/Elemento correspondente à sua **Fraqueza** causa dano de vida e de postura (*Stagger*) matematicamente fiéis aos multiplicadores configurados no `DefenseProfileData` (validado por testes unitários com $\ge 90\%$ de cobertura na camada de cálculo).
- **`SC-003`**: 100% dos ataques inimigos que colidem com a `HurtboxComponent` da Caçadora durante os *i-frames* do `PlayerDodgeState` ou durante os *i-frames* pós-dano resultam em **zero** perda de vida; ataques fora de *i-frames* acionam `PlayerHurtState` com *knockback* e cancelam qualquer hitbox de ataque ativa.
- **`SC-004`**: Na cena `sandbox_combat.tscn`, o desenvolvedor consegue testar os combos dos 2 Estilos de Luta, alternar Óleos, quebrar a postura (*Stagger*) de Bonecos de Treino e validar *Dodge Cancel* e `PlayerHurtState` em menos de 30 segundos.

---

## 6. Clarifications — 🔒 PORTÃO DE QUALIDADE 1 (Verificação Pessoal do Desenvolvedor)

> *Preenchido durante `/speckit-clarify` (Etapa 3). O agente aponta ambiguidades, faz perguntas fechadas com opções de melhoria questionando sempre o **porquê** da decisão, e grava as respostas diretamente aqui e nas seções correspondentes acima.*

### Session 2026-10-20

- **Q1 (`RF-005` / `RF-006` — Direção de Ataque e Cadeia de Golpes)**: Como deve funcionar a direção de ataque e o encadeamento de golpes nos Estilos de Luta? → **A**: Orientação por `facing_direction` (Teclado/Analógico, permitindo redirecionar entre golpes) + Combo curto diferenciado por Estilo com *Input Buffer* (**3 cortes rápidos** na Postura Rápida vs. **2 impactos pesados** na Postura Pesada), diferenciando o ritmo e o compromisso mecânico de cada postura na mão do jogador.
- **Q2 (`RF-007` / `EC-004` — Janela de *Dodge Cancel*)**: Em quais fases do golpe a Esquiva (`Dodge`) pode cancelar o ataque? → **A**: Cancelamento permitido durante o *Windup* (antes da hitbox ativar) e durante o *Recovery* (pós-corte), mas bloqueado durante os frames de *Active Hitbox* (retendo o pedido no *Input Buffer* para disparar no primeiro frame do *Recovery*), preservando o compromisso físico do impacto sem travar a fluidez defensiva.
- **Q3 (`RF-008` / `EC-003` — Reação da Caçadora ao Receber Dano)**: Qual deve ser o comportamento da Caçadora ao receber dano fora de *i-frames*? → **A**: Transição imediata para `PlayerHurtState` curto (`hurt_duration`), abortando qualquer ataque ativo com desligamento seguro da hitbox, aplicando *knockback* desacelerado por atrito e ativando uma janela curta de *i-frames* pós-dano (`post_hit_invulnerability_duration`) com piscar visual no Greybox para evitar *stunlock* ou morte instantânea por múltiplos frames de contato.

### Assinatura do Portão de Qualidade 1
- [x] Todas as ambiguidades foram eliminadas e gravadas de volta na Spec.
- [x] A seção **Fora do Escopo (Non-Goals)** está clara e blindada.
- [x] **Verificado e aprovado pessoalmente pelo Desenvolvedor em:** `2026-10-20`
