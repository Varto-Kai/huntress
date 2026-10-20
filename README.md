# 🏹 Projeto Huntress

> **RPG de Ação Isométrico/Top-Down 2D em Pixel Art (Godot 4.x)**  
> *Estética e fluidez inspiradas em CrossCode + Caça tática e investigação inspiradas em The Witcher.*

---

## 📌 Visão Geral

Em **Huntress**, você assume o papel de uma caçadora de monstros que precisa investigar o ambiente em busca de pistas físicas, deduzir as fraquezas da criatura no seu **Grimório**, preparar ferramentas/estilos de luta específicos e enfrentar chefes punitivos e estratégicos em seus covis.

Este projeto é desenvolvido utilizando **Godot 4.x (GDScript estrito)** sob a metodologia **SDD (Spec-Driven Development)** assistida por IA no **Antigravity IDE**.

---

## 🧭 Índice da Documentação e Governança SDD

O desenvolvimento segue obrigatoriamente a ordem linear do ciclo SDD com **dois Portões de Qualidade** verificados pessoalmente pelo desenvolvedor:

`1. Constituição` $\rightarrow$ `2. Especificação` $\rightarrow$ `3. Clarificação [🔒 Portão 1]` $\rightarrow$ `4. Plano` $\rightarrow$ `5. Tarefas (Issues)` $\rightarrow$ `6. Análise [🔒 Portão 2]` $\rightarrow$ `7. Implementação`

### Documentos Principais
- ⚙️ **[Workflow e Escopo do Ciclo SDD (`docs/SDD_WORKFLOW.md`)](./docs/SDD_WORKFLOW.md)**: Regras do processo, definição de cada etapa, mecanismo anti-desvio e critérios dos Portões de Qualidade.
- 📜 **[Constituição do Projeto (`docs/CONSTITUICAO.md`)](./docs/CONSTITUICAO.md)**: Padrões de arquitetura modular (Component Pattern, StateMachine, Signals), política de testes e *Greyboxing*, segurança de dados e convenções de código/commits.
- 🎮 **[Game Design Document (`docs/GDD.md`)](./docs/GDD.md)**: Conceito central, Pilares de Design, Core Loop detalhado, análise de referências (*CrossCode*, *The Witcher*, *Monster Hunter*, *Unsighted*) e Roadmap de Especificações.
- 🛡️ **[Regras do Agente (`AGENTS.md`)](./AGENTS.md)**: Instruções sempre ativas para a IA bloquear atalhos e manter a disciplina do SDD.

### Diretórios de Artefatos SDD
- 📂 [`docs/specs/`](./docs/specs/) — Especificações Funcionais e registros de Clarificação (Portão 1).
- 📂 [`docs/plans/`](./docs/plans/) — Planos Técnicos de Arquitetura e auditoria contra a Constituição.
- 📂 [`docs/tasks/`](./docs/tasks/) — Listas de Tarefas atômicas (sincronizadas com GitHub Issues) e Relatórios de Análise Cruzada (Portão 2).
