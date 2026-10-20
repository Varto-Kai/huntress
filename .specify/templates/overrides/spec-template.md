# 📋 Especificação da Feature: [FEATURE NAME]

**Diretório da Feature**: `specs/[###-feature-name]`  
**Criado em**: [DATE]  
**Status no Ciclo SDD**: `[ ] 2. Rascunho de Especificação` | `[ ] 3. Clarificada (🔒 Portão 1 Aprovado)`  
**Entrada do Usuário**: "$ARGUMENTS"

---

## 1. Cenários de Usuário & Testes (Histórias do Jogador e Fluxo Principal) *(obrigatório)*

### User Story 1 - [Título Curto] (Prioridade: P1) 🎯 MVP

> **Como** a Caçadora,  
> **Quero** [ação ou capacidade no jogo],  
> **Para que** [benefício tático / impacto no Core Loop].

**Por que esta prioridade**: [Explicar o valor para o Core Loop e por que é P1]

**Teste Independente (Greybox)**: [Descrever como esta história pode ser testada isoladamente em uma cena Sandbox Greybox]

**Fluxo Principal e Cenários de Aceitação**:

1. **Dado** [estado inicial], **Quando** [ação do jogador/sistema], **Então** [resultado esperado].
2. **Dado** [estado inicial], **Quando** [ação do jogador/sistema], **Então** [resultado esperado].

---

### User Story 2 - [Título Curto] (Prioridade: P2)

> **Como** a Caçadora,  
> **Quero** [ação ou capacidade complementar],  
> **Para que** [benefício tático].

**Teste Independente (Greybox)**: [Como testar isoladamente]

**Cenários de Aceitação**:

1. **Dado** [estado inicial], **Quando** [ação], **Então** [resultado esperado].

---

## 2. Casos de Borda (Edge Cases) e O Que Dá Errado *(obrigatório)*

| ID | Cenário de Borda / Estado de Erro | Comportamento Esperado (Tratamento) |
| :--- | :--- | :--- |
| **`EC-001`** | [Ex.: Input simultâneo / colisão em esquina / interrupção por dano] | [Ex.: Estado cancelado com segurança e transição para StaggerState] |
| **`EC-002`** | [Ex.: Recurso ou pista ausente / limite atingido] | [Ex.: Feedback visual/sinal emitido sem crash] |

---

## 3. Requisitos Funcionais Numerados *(obrigatório)*

- **`RF-001` (FR-001)**: O sistema DEVE [capacidade específica e testável].
- **`RF-002` (FR-002)**: Quando [gatilho], a entidade DEVE [comportamento esperado].
- **`RF-003` (FR-003)**: Os parâmetros de *Game Feel* ([listar parâmetros]) DEVEM ser expostos para ajuste humano.
- **`RF-004` (FR-004)**: [Marcar com `[NEEDS CLARIFICATION: pergunta específica]` apenas onde houver ambiguidade crítica].

### Entidades de Domínio Envolvidas *(se aplicável)*

- **[Entidade / Conceito 1]**: [O que representa no jogo e seus atributos conceituais]

---

## 4. Fora do Escopo (Non-Goals) 🚫 *(obrigatório)*

> *Tão importante quanto o que está no escopo. Qualquer item listado abaixo NÃO será projetado nem implementado nesta feature.*

- **Não inclui**: Arte final em Pixel Art ou animações definitivas (validação estritamente em *Greybox / Placeholder First*).
- **Não inclui**: [Listar sistemas adjacentes que ficam para outra Spec].
- **Não inclui**: [Listar expansões futuras fora deste recorte].

---

## 5. Critérios de Sucesso Mensuráveis *(obrigatório)*

- **`SC-001`**: [Métrica verificável de gameplay/resposta, ex.: "Transição de estado ocorre em até 1 frame físico sem travamento"].
- **`SC-002`**: [Critério de validação em cena Sandbox Greybox em menos de 30 segundos].

---

## 6. Clarifications — 🔒 PORTÃO DE QUALIDADE 1 (Verificação Pessoal do Desenvolvedor)

> *Preenchido durante `/speckit-clarify` (Etapa 3). O agente aponta ambiguidades, faz perguntas fechadas com opções de melhoria questionando sempre o **porquê** da decisão, e grava as respostas diretamente aqui e nas seções correspondentes acima.*

### Session [DATE]

- *Aguardando execução da Etapa 3 (`/speckit-clarify`).*

### Assinatura do Portão de Qualidade 1
- [ ] Todas as ambiguidades foram eliminadas e gravadas de volta na Spec.
- [ ] A seção **Fora do Escopo (Non-Goals)** está clara e blindada.
- [ ] **Verificado e aprovado pessoalmente pelo Desenvolvedor em:** `____-__-__`
