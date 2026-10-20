# 📋 Especificação da Feature: Movimentação Base, Esquiva e StateMachine da Caçadora

**Diretório da Feature**: `specs/001-player-movement`  
**Criado em**: 2026-10-20  
**Status no Ciclo SDD**: `[x] 2. Rascunho de Especificação` | `[x] 3. Clarificada (🔒 Portão 1 Aprovado)`  
**Entrada do Usuário**: "Iniciar a SPEC-001: Movimentação Base, Esquiva e StateMachine da Caçadora (Greybox)"

---

## 1. Cenários de Usuário & Testes (Histórias do Jogador e Fluxo Principal) *(obrigatório)*

### User Story 1 - Locomoção Direcional Responsiva (*CrossCode Feel*) (Prioridade: P1) 🎯 MVP

> **Como** a Caçadora,  
> **Quero** me mover pelo cenário em qualquer direção com resposta quase instantânea de aceleração e parada suave controlada por atrito,  
> **Para que** eu tenha controle espacial preciso para explorar mapas de investigação e me posicionar taticamente diante de ameaças.

**Por que esta prioridade**: A locomoção é a base sobre a qual todos os outros sistemas (investigação de pistas, infiltração e combate contra Bosses) se apoiam. Se o movimento parecer "escorregadio demais" ou "travado", todo o *Game Feel* do jogo é comprometido.

**Teste Independente (Greybox)**: Em uma cena Sandbox com obstáculos geométricos simples (paredes e pilares em Greybox), o jogador deve conseguir mover a Caçadora em 8 direções / 360°, contornar quinas sem prender e sentir a diferença imediata ao alterar `max_speed`, `acceleration` e `friction` no Inspector.

**Fluxo Principal e Cenários de Aceitação**:

1. **Dado** que a Caçadora está parada no estado `Idle`, **Quando** o jogador pressiona uma ou mais direções de movimento, **Então** a entidade transita para o estado `Move` e acelera até atingir a velocidade máxima parametrizada.
2. **Dado** que a Caçadora está em movimento em diagonal (ex.: Cima + Direita), **Quando** a velocidade é calculada, **Então** o vetor de direção é normalizado para que a velocidade diagonal nunca ultrapasse a velocidade máxima cardinal.
3. **Dado** que a Caçadora está no estado `Move`, **Quando** o jogador solta todas as entradas direcionais, **Então** a entidade desacelera aplicando o atrito parametrizado até atingir velocidade zero e retorna ao estado `Idle`.

---

### User Story 2 - Esquiva Tática (*Dash / Dodge*) (Prioridade: P2)

> **Como** a Caçadora,  
> **Quero** executar uma esquiva rápida com duração controlada, janela de invulnerabilidade visualmente identificável e tempo de recarga (*cooldown*),  
> **Para que** eu possa escapar de investidas letais dos monstros no momento exato sem poder abusar de esquivas infinitas.

**Por que esta prioridade**: O combate de *Huntress* é punitivo e tático. A esquiva é a principal ferramenta defensiva universal da protagonista antes mesmo das contramedidas específicas do Grimório.

**Teste Independente (Greybox)**: Na cena Sandbox, pressionar o botão de esquiva faz a Caçadora avançar rapidamente na direção ativa, mudando temporariamente sua cor de Greybox para indicar o estado de esquiva/invulnerabilidade e respeitando o tempo de recarga antes de permitir novo acionamento.

**Cenários de Aceitação**:

1. **Dado** que a Caçadora está em `Idle` ou `Move` e a esquiva não está em *cooldown*, **Quando** o jogador aciona o comando de esquiva, **Então** a entidade transita para o estado `Dodge` e se desloca rapidamente por uma duração/distância parametrizada.
2. **Dado** que a Caçadora iniciou o estado `Dodge`, **Quando** o estado está ativo, **Então** a direção da esquiva permanece travada (*committed*) até o fim da duração da esquiva, e a representação visual Greybox muda de cor para sinalizar claramente a janela ativa.
3. **Dado** que a duração da esquiva terminou, **Quando** a Caçadora sai do estado `Dodge`, **Então** ela transita automaticamente para `Move` (se houver input direcional mantido) ou `Idle` (se não houver input), e o *cooldown* da esquiva é iniciado.

---

### User Story 3 - Leitura Visual em Greybox e Orientação (*Facing Direction*) (Prioridade: P3)

> **Como** Desenvolvedor/Jogador em fase de validação mecânica,  
> **Quero** visualizar claramente para qual direção a Caçadora está olhando (*facing direction*) e em qual estado da `StateMachine` ela se encontra usando apenas formas geométricas e cores semânticas,  
> **Para que** eu possa validar todas as regras de movimento e esquiva sem depender de nenhuma arte final em Pixel Art.

**Por que esta prioridade**: Cumpre a diretriz constitucional *Placeholder First (Greyboxing Obrigatório)* e prepara a referência de direção (`facing_direction`) que será exigida na `SPEC-002` (ataques e hitboxes direcionais) e `SPEC-003` (interação com pistas à frente).

**Teste Independente (Greybox)**: Na cena Sandbox, a forma geométrica da Caçadora exibe um indicador visual de frente (ponteiro/seta geométrica) que lembra a última direção válida mesmo quando parada em `Idle`, e muda de cor conforme o estado ativo (`Idle`, `Move`, `Dodge`).

**Cenários de Aceitação**:

1. **Dado** que a Caçadora se moveu para uma direção e depois parou (`Idle`), **Quando** nenhuma tecla é pressionada, **Então** ela preserva a última direção válida como sua orientação atual (`facing_direction`).

---

## 2. Casos de Borda (Edge Cases) e O Que Dá Errado *(obrigatório)*

| ID | Cenário de Borda / Estado de Erro | Comportamento Esperado (Tratamento) |
| :--- | :--- | :--- |
| **`EC-001`** | **Inputs opostos simultâneos** (ex.: jogador segura Esquerda e Direita ao mesmo tempo no teclado) | Os eixos opostos se anulam (resultando em `0` naquele eixo) sem causar tremor (*jitter*) de estado ou troca frenética de orientação. Se ambos os eixos resultarem em zero, a entidade desacelera e vai para `Idle`. |
| **`EC-002`** | **Esquiva acionada a partir do repouso (`Idle`) sem nenhuma tecla direcional pressionada** | Executa um **recuo tático (*Backstep*)** impulsionando a Caçadora na direção oposta à sua orientação atual (`-facing_direction`), **mantendo `facing_direction` apontada para a frente** (sem virar de costas para a ameaça). |
| **`EC-003`** | **Spam do botão de esquiva durante `Dodge` ativo ou durante o *cooldown*** | Comandos acionados cedo demais são ignorados, mas existe uma **janela curta de *Input Buffer* (`@export dodge_input_buffer_time`, padrão `~0.12s`)**: se o jogador pressionar esquiva dentro dessa janela final antes do término da esquiva/recarga, a próxima esquiva dispara imediatamente assim que elegível. |
| **`EC-004`** | **Colisão contra parede ou quina durante `Move` ou `Dodge`** | A entidade desliza suavemente ao longo da superfície da parede (*wall sliding*) sem ficar presa no canto e sem encerrar prematuramente o tempo do estado `Dodge`. |
| **`EC-005`** | **Perda de foco da janela do jogo com tecla direcional pressionada** | Ao perder foco (ou quando o vetor de entrada for zerado pelo sistema), a entidade não deve ficar presa correndo infinitamente; deve desacelerar até `Idle`. |
| **`EC-006`** | **Proporção de velocidade no plano Top-Down / Isométrico** | Adota física **1:1 (Top-Down Oblíquo 3/4 estilo *CrossCode*)** por padrão (velocidade vertical idêntica à horizontal após normalização), expondo `@export var y_axis_speed_ratio: float = 1.0` para permitir ajuste fino caso necessário sem alterar a lógica de movimento. |

---

## 3. Requisitos Funcionais Numerados *(obrigatório)*

- **`RF-001` (FR-001)**: O sistema DEVE capturar entradas de movimentação em 4 eixos cardinais (Cima, Baixo, Esquerda, Direita) e combiná-las em um vetor direcional normalizado de comprimento máximo `1.0`.
- **`RF-002` (FR-002)**: A locomoção DEVE operar através de aceleração progressiva até a velocidade máxima quando houver entrada direcional e desaceleração por atrito (*friction*) quando não houver entrada.
- **`RF-003` (FR-003)**: O controle de estados da Caçadora DEVE ser gerenciado por uma Máquina de Estados Finita (`StateMachine`) isolada contendo exclusivamente, neste escopo, os estados `Idle`, `Move` e `Dodge`.
- **`RF-004` (FR-004)**: A entidade DEVE manter registrada sua última direção de orientação válida (`facing_direction`), iniciando com uma direção padrão configurável (ex.: Baixo/Sul) ao nascer na cena.
- **`RF-005` (FR-005)**: Ao acionar o comando de esquiva fora de *cooldown*, a Caçadora DEVE entrar no estado `Dodge`, travando a direção do impulso pelo tempo configurado da esquiva e ignorando mudanças de direção no meio do trajeto. Se acionada em `Move`, esquiva na direção do movimento; se acionada em `Idle` (sem input direcional), executa um *Backstep* na direção oposta à `facing_direction` mantendo o olhar para a frente.
- **`RF-006` (FR-006)**: O estado `Dodge` DEVE ativar uma janela de invulnerabilidade (*i-frames*) imediatamente no frame 1 da esquiva por uma duração configurável (`invulnerability_duration <= dodge_duration`), encerrando os *i-frames* antes do fim do movimento para deixar o terço final de desaceleração (*recovery*) vulnerável. Deve emitir sinais claros de início/fim da esquiva e início/fim dos *i-frames*.
- **`RF-007` (FR-007)**: Após o término do estado `Dodge`, um temporizador de recarga (*cooldown*) DEVE impedir novas transições para `Dodge` até que o tempo expire.
- **`RF-008` (FR-008)**: Todos os parâmetros de *Game Feel* — velocidade máxima (`max_speed`), proporção do eixo Y (`y_axis_speed_ratio`), aceleração (`acceleration`), atrito (`friction`), velocidade inicial da esquiva (`dodge_speed`), multiplicador de velocidade do *Backstep* (`backstep_speed_multiplier`, padrão `0.75`), fator de desaceleração no terço final da esquiva (`dodge_end_speed_factor`), duração da esquiva (`dodge_duration`), duração de *i-frames* (`invulnerability_duration`), tempo de recarga (`dodge_cooldown`) e janela de *Input Buffer* (`dodge_input_buffer_time`) — DEVEM ser expostos com `@export` para ajuste humano no Inspector.
- **`RF-009` (FR-009)**: A Caçadora DEVE possuir uma representação visual *Greybox* (formas geométricas puras) que altere sua cor de acordo com o estado atual (`Idle`, `Move`, `Dodge` com *i-frames* ativos vs. `Dodge` em *recovery* sem *i-frames*) e exiba um indicador geométrico apontando para `facing_direction`.
- **`RF-010` (FR-010)**: Deve existir uma cena de teste isolada (*Sandbox Greybox*) contendo piso e obstáculos geométricos para validar colisões, deslizamento em quinas e todos os requisitos desta especificação.

### Entidades de Domínio Envolvidas

- **Caçadora (`Player`)**: Entidade controlada pelo jogador que compõe movimentação, orientação, representação Greybox e máquina de estados.
- **Estado de Locomoção (`Idle` / `Move` / `Dodge`)**: Estados mutuamente exclusivos que governam como o input e a física se comportam a cada instante.

---

## 4. Fora do Escopo (Non-Goals) 🚫 *(obrigatório)*

> *Tão importante quanto o que está no escopo. Qualquer item listado abaixo NÃO será projetado nem implementado nesta feature.*

- **Não inclui**: Ataques corpo-a-corpo, ataques à distância, mira com mouse/analógico direito ou troca de Estilos de Luta (pertencem à **`SPEC-002`**).
- **Não inclui**: Sistema de vida (`HealthComponent`), recebimento de dano real, *knockback* de ataques inimigos ou estado de atordoamento/morte (pertencem à **`SPEC-002`**).
- **Não inclui**: Interação com pistas físicas ou abertura do Grimório (pertencem à **`SPEC-003`**).
- **Não inclui**: Sprites em Pixel Art, `AnimationPlayer`/`AnimationTree` de arte final, partículas definitivas ou efeitos sonoros (validação 100% em *Greybox*).
- **Não inclui**: Pulo vertical (eixo Z) ou escalada de plataformas em múltiplos níveis de altura nesta primeira versão base.

---

## 5. Critérios de Sucesso Mensuráveis *(obrigatório)*

- **`SC-001`**: A velocidade máxima da Caçadora ao se mover na diagonal tem variação `<= 0.01%` em relação à velocidade máxima horizontal/vertical (vetor 100% normalizado).
- **`SC-002`**: A transição entre `Idle`, `Move` e `Dodge` responde ao comando do jogador no próximo frame de processamento físico ($\le 16.6\text{ ms}$ a 60 FPS), sem estados órfãos ou travamentos mesmo sob entradas simultâneas de teclado.
- **`SC-003`**: 100% das variáveis de *Game Feel* listadas em `RF-008` podem ser alteradas no Inspector sem tocar em código, alterando imediatamente o comportamento da Caçadora na cena Sandbox.
- **`SC-004`**: Um testador consegue abrir a cena Sandbox Greybox e validar visualmente os 3 estados (`Idle`, `Move`, `Dodge`), a direção de orientação (`facing_direction`) e o deslizamento em paredes em menos de 30 segundos.

---

## 6. Clarifications — 🔒 PORTÃO DE QUALIDADE 1 (Verificação Pessoal do Desenvolvedor)

> *Preenchido durante `/speckit-clarify` (Etapa 3). O agente aponta ambiguidades, faz perguntas fechadas com opções de melhoria questionando sempre o **porquê** da decisão, e grava as respostas diretamente aqui e nas seções correspondentes acima.*

### Session 2026-10-20

- **Q1 (`EC-002` / `RF-005` — Esquiva a partir de `Idle`)**: Quando a Caçadora está parada em `Idle` e aciona Esquiva, qual comportamento deve ocorrer e por quê? → **A**: Recuar na direção oposta à última direção olhada (*Backstep* em `-facing_direction`, mantendo o olhar voltado para `facing_direction`), pois prioriza a postura defensiva e tática estilo *The Witcher* / *Souls* para sair do alcance do bote do monstro sem dar as costas para ele.
- **Q2 (`EC-003` / `RF-008` — Input Buffer e Curva da Esquiva)**: Como o sistema deve tratar inputs de esquiva próximos ao fim do estado/cooldown e a curva de velocidade da esquiva, e por quê? → **A**: Incluir janela curta de *Input Buffer* (`@export ~0.12s`) combinada com desaceleração suave no terço final da esquiva, evitando a sensação de "botão que falhou" em momentos críticos de Boss fight e conferindo peso físico realista ao término do avanço/backstep.
- **Q3 (`EC-006` / `RF-001` — Proporção Física 1:1 vs Isométrica 2:1)**: Qual modelo físico de velocidade entre os eixos X e Y devemos adotar e por quê? → **A**: Física 1:1 (Top-Down Oblíquo 3/4 estilo *CrossCode* / *Unsighted*) com `@export y_axis_speed_ratio: float = 1.0`, garantindo leitura espacial previsível para distâncias de esquiva e futuros puzzles na fase de infiltração.
- **Q4 (`RF-005` / `RF-006` / `RF-009` — Janela de *i-frames* e Multiplicador do *Backstep*)**: Como deve funcionar a janela de invulnerabilidade (*i-frames*) dentro da duração da esquiva e a proporção do *Backstep* em relação ao *Dash* direcional, e por quê? → **A**: Os *i-frames* iniciam no frame 1 da esquiva e terminam antes do fim do movimento (deixando o terço final de desaceleração/*recovery* vulnerável e com diferenciação visual no Greybox), somado a um multiplicador `@export backstep_speed_multiplier` próprio (ex.: `0.75x`), recompensando o timing preciso de reação e punindo esquivas precipitadas contra Bosses.

### Assinatura do Portão de Qualidade 1
- [x] Todas as ambiguidades foram eliminadas e gravadas de volta na Spec.
- [x] A seção **Fora do Escopo (Non-Goals)** está clara e blindada.
- [x] **Verificado e aprovado pessoalmente pelo Desenvolvedor em:** `2026-10-20`
