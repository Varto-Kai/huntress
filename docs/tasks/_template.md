# ✅ TASKS & ANÁLISE-NNN: [Nome da Feature / Sistema]

> **Status no Ciclo SDD:** `[ ] 5. Tarefas Definidas` | `[ ] 6. Análise Cruzada (🔒 Portão 2 Aprovado)` | `[ ] 7. Implementado`  
> **Spec de Origem:** `docs/specs/NNN-nome-da-feature.md`  
> **Plano de Origem:** `docs/plans/NNN-nome-da-feature-plan.md`

---

## 1. Lista Ordenada de Tarefas (Etapa 5)

### `TASK-001`: [Título claro e atômico da tarefa]
- **Issue no GitHub:** `#TBD`
- **Origem:** `RF-001`, `DT-01`
- **Dependências:** Nenhuma
- **Arquivos Envolvidos:** `res://src/...`
- **Critério de Conclusão (Definition of Done):**
  - [ ] Critério verificável 1
  - [ ] Critério verificável 2

---

## 2. Relatório de Análise Cruzada — 🔒 PORTÃO DE QUALIDADE 2 (Etapa 6)

### 2.1. Matriz de Rastreabilidade (`Constituição <-> Spec <-> Plano <-> Tarefas`)

| Requisito / Caso de Borda (Spec) | Seção do Plano | Tarefa(s) (`TASK-XXX`) | Conformidade Constitucional | Status |
| :--- | :--- | :--- | :--- | :---: |
| `RF-001` | Seção 1.2 | `TASK-001` | Item 1.2 (Component Pattern) | ✅ Coberto |
| `EC-001` | Seção 2.2 | `TASK-002` | Item 2.2 (Teste de Borda) | ✅ Coberto |

### 2.2. Verificação de Anomalias
- **Contradições entre Documentos:** `[Nenhuma encontrada / Listar se houver]`
- **Requisitos Órfãos (RF/EC sem Task):** `[Nenhum encontrado / Listar se houver]`
- **Tarefas sem Origem (Task sem RF/EC na Spec):** `[Nenhuma encontrada / Listar se houver]`

### 2.3. Checklist de Qualidade por Tipo de Risco

| Tipo de Risco | Ponto Verificado | Mitigação Aplicada nas Tasks | Status |
| :--- | :--- | :--- | :---: |
| **1. Risco Arquitetural / Acoplamento** | Há dependências diretas entre irmãos ou pais usando caminhos frágeis? | Uso estrito de `@export` + `signals`. | ✅ |
| **2. Risco de Game Feel / Performance** | Há números mágicos hardcoded na física ou falta de `@export`? | Todas as variáveis de ajuste estão listadas com `@export`. | ✅ |
| **3. Risco de Dados / Estado** | Há risco de mutação indevida de `Resource` compartilhado ou estado órfão? | Validação defensiva e testes de transição. | ✅ |
| **4. Risco de Escopo / Greyboxing** | Alguma tarefa invade a seção "Fora do Escopo" ou exige arte final? | Tudo validado em cena *Sandbox Greybox*. | ✅ |

### 2.4. Assinatura do Portão de Qualidade 2
- [ ] Matriz de Rastreabilidade sem requisitos órfãos e sem tarefas sem origem.
- [ ] Zero contradições entre Constituição, Spec, Plano e Tarefas.
- [ ] Issues criadas no GitHub.
- [ ] **Aprovado pessoalmente pelo Desenvolvedor para Implementação em:** `____-__-__`
