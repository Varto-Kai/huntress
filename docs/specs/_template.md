# 📋 SPEC-NNN: [Nome da Feature / Sistema]

> **Status no Ciclo SDD:** `[ ] 2. Rascunho de Especificação` | `[ ] 3. Clarificada (🔒 Portão 1 Aprovado)`  
> **Data:** YYYY-MM-DD  
> **Relacionado no GDD:** [Seção do GDD]

---

## 1. História de Usuário (Experiência do Jogador) e Fluxo Principal

### 1.1. História do Jogador
> **Como** a Caçadora,  
> **Quero** [ação ou capacidade no jogo],  
> **Para que** [benefício tático / impacto no Core Loop].

### 1.2. Fluxo Principal (Happy Path)
1. O jogador realiza [ação inicial]...
2. O sistema responde [resposta visual/mecânica]...
3. O estado resultante é [estado final]...

---

## 2. Requisitos Funcionais Numerados

- **`RF-001`:** O sistema deve...
- **`RF-002`:** Quando [gatilho], a entidade deve...
- **`RF-003`:** Os parâmetros [X, Y, Z] devem ser expostos via `@export` para ajuste de *Game Feel*.

---

## 3. Casos de Borda (Edge Cases) e O Que Dá Errado

| ID | Cenário / Caso de Borda | Comportamento Esperado (Tratamento) |
| :--- | :--- | :--- |
| **`EC-001`** | [Ex: Jogador tenta esquivar enquanto está atordoado] | [Ex: Input ignorado; permanece em StaggerState] |
| **`EC-002`** | [Ex: Duas pistas sobrepostas no mesmo raio de interação] | [Ex: Interage apenas com a pista mais próxima do centro do Player] |

---

## 4. Fora do Escopo (Non-Goals) 🚫

> *Tão importante quanto o que está no escopo. Qualquer item listado abaixo NÃO será implementado nesta especificação.*

- **Não inclui:** [Ex: Animações finais em Pixel Art — será validado exclusivamente em Greybox].
- **Não inclui:** [Ex: Persistência em disco / Save System].
- **Não inclui:** [Ex: Efeitos sonoros definitivos].

---

## 5. Registro de Clarificação — 🔒 PORTÃO DE QUALIDADE 1

> *Seção preenchida durante a Etapa 3 (Clarificação), onde o Agente aponta ambiguidades, faz perguntas fechadas questionando o "porquê" das decisões, e grava as respostas do Desenvolvedor.*

### 5.1. Perguntas e Decisões Gravadas
- **Q1 (Ambiguidade identificada):** ...
  - *Questionamento de Design (Por quê?):* ...
  - *Decisão do Desenvolvedor:* ...
  - *Impacto na Spec:* Atualizado em `RF-XXX` / `EC-XXX`.

### 5.2. Assinatura do Portão de Qualidade 1
- [ ] Ambiguidades eliminadas e respostas gravadas na Spec.
- [ ] Escopo e Não-Escopo validados.
- [ ] **Aprovado pessoalmente pelo Desenvolvedor em:** `____-__-__`
