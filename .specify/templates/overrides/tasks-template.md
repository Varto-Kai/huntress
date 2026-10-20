---
description: "Template de Lista Ordenada de Tarefas e Relatório de Análise Cruzada (Portão de Qualidade 2)"
---

# ✅ Tarefas & Análise Cruzada: [FEATURE NAME]

**Diretório da Feature**: `specs/[###-feature-name]`  
**Pré-requisitos**: `spec.md` (🔒 Portão 1 Aprovado) e `plan.md` (Constitution Check Aprovado)  
**Status no Ciclo SDD**: `[ ] 5. Tarefas Definidas` | `[ ] 6. Análise Cruzada (🔒 Portão 2 Aprovado)` | `[ ] 7. Implementado`

---

## Formato das Tarefas: `[ID] [P?] [Story] Descrição com caminho exato + Critério de Conclusão`

- **`[P]`**: Pode ser executada em paralelo (arquivos distintos, sem dependência pendente).
- **`[US#]`**: História de usuário / Requisito Funcional de origem (`RF-XXX`, `EC-XXX`).
- **Critério de Conclusão (DoD)** e **Dependências** explícitos em cada tarefa.
- **Distribuição em Issues**: Sincronizado com o GitHub via `/speckit-github-taskstoissues`.

---

## Fase 1: Setup & Infraestrutura Base

- [ ] T001 Criar estrutura de diretórios e cenas base conforme `plan.md`
  - **Origem**: `plan.md` (Seção 6) | **Depende de**: Nenhuma | **Issue**: `#TBD`
  - **Critério de Conclusão (DoD)**: Pastas criadas seguindo a Constituição e sem erros no editor Godot.

---

## Fase 2: Fundacional (Componentes e Recursos Bloqueantes)

**⚠️ CRÍTICO**: Deve estar concluída antes da integração nas histórias de usuário.

- [ ] T002 [P] Implementar `[NomeResourceOuComponente]` em `src/...`
  - **Origem**: `RF-001`, `DT-01` | **Depende de**: `T001` | **Issue**: `#TBD`
  - **Critério de Conclusão (DoD)**: Tipagem estática 100%, variáveis `@export` expostas, sinais emitidos corretamente.

---

## Fase 3: User Story 1 - [Título] (Prioridade: P1) 🎯 MVP (Greybox)

**Objetivo**: [O que esta história entrega]  
**Teste Independente**: [Cena Sandbox Greybox em `tests/sandboxes/...`]

- [ ] T003 [P] [US1] Criar testes unitários/componentes em `tests/unit/test_...gd`
  - **Origem**: `RF-001`, `EC-001` | **Depende de**: `T002` | **Issue**: `#TBD`
  - **Critério de Conclusão (DoD)**: Testes cobrindo caminhos felizes e casos de borda definidos na Spec.
- [ ] T004 [US1] Integrar componentes e montar cena Greybox em `src/entities/...` e `tests/sandboxes/...`
  - **Origem**: `RF-001`, `RF-002` | **Depende de**: `T002`, `T003` | **Issue**: `#TBD`
  - **Critério de Conclusão (DoD)**: Mecânica validada visualmente com formas geométricas (Greybox) atendendo 100% dos critérios de aceitação.

---

## Fase 4: Polimento, Parametrização e Validação Final

- [ ] T005 Validar todos os `@export` de *Game Feel* e casos de borda na cena Sandbox
  - **Origem**: `RF-003`, `EC-001`, `EC-002` | **Depende de**: `T004` | **Issue**: `#TBD`
  - **Critério de Conclusão (DoD)**: Zero números mágicos, zero avisos de tipagem na Godot.

---

## 🔒 PORTÃO DE QUALIDADE 2: Análise Cruzada (`/speckit-analyze`)

> *Preenchido na Etapa 6 antes de qualquer execução do `/speckit-implement`. O Desenvolvedor verifica pessoalmente este relatório.*

### 1. Matriz de Rastreabilidade (`Constituição <-> Spec <-> Plano <-> Tarefas`)

| Requisito / Caso de Borda (`spec.md`) | Seção do Plano (`plan.md`) | Tarefa(s) (`tasks.md`) | Regra Constitucional | Status |
| :--- | :--- | :--- | :--- | :---: |
| `RF-001` | Seção 2.2 | `T002`, `T003`, `T004` | Seção 1.2 (Component Pattern) | ✅ Coberto |
| `EC-001` | Seção 3.2 | `T003`, `T005` | Seção 2.2 (Cobertura de Borda) | ✅ Coberto |

### 2. Auditoria de Consistência e Anomalias
- **Contradições entre `Constituição <-> Spec <-> Plano <-> Tarefas`**: `[Nenhuma detectada / Listar se houver]`
- **Requisitos Órfãos (Requisito na Spec sem Tarefa correspondente)**: `[Nenhum detectado / Listar se houver]`
- **Tarefas sem Origem (Tarefa que não deriva de nenhum Requisito da Spec)**: `[Nenhuma detectada / Listar se houver]`

### 3. Checklist de Qualidade por Tipo de Risco

| Categoria de Risco | Verificação Realizada | Mitigação nas Tarefas | Status |
| :--- | :--- | :--- | :---: |
| **1. Risco Arquitetural / Acoplamento** | Há scripts monolíticos ou chamadas `get_parent()` frágeis? | Componentes isolados + *Call Down, Signal Up* | ✅ |
| **2. Risco de Game Feel / Performance** | Há números mágicos na física ou falta de `@export`? | Todos os parâmetros de ajuste usam `@export` | ✅ |
| **3. Risco de Dados / Estado** | Há risco de mutação de `Resource` compartilhado ou estado inválido na `StateMachine`? | Validação defensiva e testes de transição | ✅ |
| **4. Risco de Escopo / Greyboxing** | Alguma tarefa invade o "Fora do Escopo" ou exige arte final antes do Greybox? | Validação restrita a formas geométricas (Greybox) | ✅ |

### 4. Assinatura Pessoal do Desenvolvedor (Portão 2)
- [ ] Matriz de Rastreabilidade sem contradições, sem requisitos órfãos e sem tarefas sem origem.
- [ ] Checklist de Qualidade por Tipo de Risco 100% validado.
- [ ] Tarefas prontas/distribuídas em Issues no GitHub (`Varto-Kai/huntress`).
- [ ] **Verificado e aprovado pessoalmente pelo Desenvolvedor para Implementação em:** `____-__-__`
