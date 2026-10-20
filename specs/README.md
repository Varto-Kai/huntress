# 📂 Diretório de Especificações por Feature (`specs/`)

Este diretório segue a convenção oficial do **GitHub Spec Kit**. Cada mecânica ou sistema do **Projeto Huntress** é organizado em sua própria pasta numerada sequencialmente:

```text
specs/
└── NNN-nome-curto-da-feature/
    ├── spec.md              # Etapa 2 (Especificação) & Etapa 3 (Clarificação - 🔒 Portão 1)
    ├── plan.md              # Etapa 4 (Plano Técnico Godot 4.x + Constitution Check)
    ├── tasks.md             # Etapa 5 (Tarefas + Issues) & Etapa 6 (Análise Cruzada - 🔒 Portão 2)
    ├── research.md          # Notas de pesquisa técnica ou referências de design (opcional)
    ├── data-model.md        # Detalhamento de Custom Resources (.tres) e Sinais (opcional)
    └── checklists/
        └── requirements.md  # Checklist automático de qualidade da Especificação
```

> **Governança:** Consulte [`docs/SDD_WORKFLOW.md`](../docs/SDD_WORKFLOW.md) e [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) antes de iniciar uma nova feature com `/speckit-specify`.
