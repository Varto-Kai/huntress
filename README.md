# 🏹 Projeto Huntress

> **RPG de Ação Isométrico/Top-Down 2D em Pixel Art (Godot 4.x)**  
> *Estética e fluidez inspiradas em CrossCode + Caça tática e investigação inspiradas em The Witcher.*

---

## 📌 Visão Geral

Em **Huntress**, você assume o papel de uma caçadora de monstros que precisa investigar o ambiente em busca de pistas físicas, deduzir as fraquezas da criatura no seu **Grimório**, preparar ferramentas/estilos de luta específicos e enfrentar chefes punitivos e estratégicos em seus covis.

Este projeto é desenvolvido utilizando **Godot 4.x (GDScript estrito)** sob a metodologia **SDD (Spec-Driven Development)** instrumentada com o **[GitHub Spec Kit](https://github.com/github/spec-kit)** nativo para o **Antigravity IDE**.

---

## 🧭 Índice da Documentação e Governança SDD

O desenvolvimento segue obrigatoriamente a ordem linear do ciclo SDD com **dois Portões de Qualidade** verificados pessoalmente pelo desenvolvedor:

`1. Constituição` $\rightarrow$ `2. Especificação` $\rightarrow$ `3. Clarificação [🔒 Portão 1]` $\rightarrow$ `4. Plano` $\rightarrow$ `5. Tarefas (Issues)` $\rightarrow$ `6. Análise [🔒 Portão 2]` $\rightarrow$ `7. Implementação`

### Documentos Principais
- ⚙️ **[Workflow e Escopo do Ciclo SDD (`docs/SDD_WORKFLOW.md`)](./docs/SDD_WORKFLOW.md)**: Regras do processo, mapeamento dos comandos `/speckit-*`, mecanismo anti-desvio e critérios dos Portões de Qualidade.
- 📜 **[Constituição do Projeto (`.specify/memory/constitution.md`)](./.specify/memory/constitution.md)** *(espelhada em [`docs/CONSTITUICAO.md`](./docs/CONSTITUICAO.md))*: Padrões de arquitetura modular (Component Pattern, StateMachine, Signals), política de testes e *Greyboxing*, segurança de dados e convenções de código/commits.
- 🎮 **[Game Design Document (`docs/GDD.md`)](./docs/GDD.md)**: Conceito central, Pilares de Design, Core Loop detalhado, análise de referências (*CrossCode*, *The Witcher*, *Monster Hunter*, *Unsighted*) e Roadmap de Especificações.
- 🛡️ **[Regras do Agente (`AGENTS.md`)](./AGENTS.md)**: Instruções sempre ativas para a IA bloquear atalhos e manter a disciplina do SDD.

### Estrutura Oficial Spec Kit no Projeto
- 📂 [`.specify/`](./.specify/) — Motor do GitHub Spec Kit:
  - [`.specify/memory/constitution.md`](./.specify/memory/constitution.md) — Constituição ativa do projeto.
  - [`.specify/templates/overrides/`](./.specify/templates/overrides/) — Templates customizados em PT-BR para Godot 4.x com os Portões de Qualidade 1 e 2.
  - [`.specify/scripts/powershell/`](./.specify/scripts/powershell/) — Scripts de resolução de contexto, pré-requisitos e templates.
  - [`.specify/extensions/`](./.specify/extensions/) — Extensões oficiais instaladas (`github`, `assess`, `bug`).
- 📂 [`.agents/skills/`](./.agents/skills/) — Skills nativas do Spec Kit para o Antigravity (`/speckit-constitution`, `/speckit-specify`, `/speckit-clarify`, `/speckit-plan`, `/speckit-tasks`, `/speckit-github-taskstoissues`, `/speckit-analyze`, `/speckit-implement`, `/speckit-converge`, `/speckit-assess-*`, `/speckit-bug-*`).
- 📂 [`specs/`](./specs/) — Diretório onde cada feature recebe sua pasta numerada (`specs/001-nome-feature/{spec.md, plan.md, tasks.md, checklists/}`).
