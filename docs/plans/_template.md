# 🏗️ PLAN-NNN: [Nome da Feature / Sistema]

> **Status no Ciclo SDD:** `[ ] 4. Plano Técnico Elaborado`  
> **Spec de Origem:** `docs/specs/NNN-nome-da-feature.md` (🔒 Portão 1 Aprovado)  
> **Constituição de Referência:** `docs/CONSTITUICAO.md` (v1.0)

---

## 1. Stack e Arquitetura de Cenas / Nós (Godot 4.x)

### 1.1. Árvore de Cenas e Componentes (`Nodes`)
```text
EntityName (CharacterBody2D / Node2D)
├── VisualGreybox (Polygon2D / ColorRect)
├── CollisionShape2D
├── HealthComponent (Node)
├── HurtboxComponent (Area2D)
└── StateMachine (Node)
    ├── IdleState (Node)
    └── ActionState (Node)
```

### 1.2. Responsabilidade de Cada Componente / Script
| Script / Cena | Tipo Base | Caminho (`res://`) | Responsabilidade Única | Requisitos Atendidos |
| :--- | :--- | :--- | :--- | :--- |
| `ExampleComponent` | `Node` | `res://src/components/...` | ... | `RF-001`, `RF-002` |

---

## 2. Modelo de Dados, Sinais e Parâmetros `@export`

### 2.1. Custom Resources (`.gd` / `.tres`)
- Definição de classes de dados e seus campos tipados.

### 2.2. Contrato de Sinais (`Signals`)
- **Sinais Emitidos:** `signal example_happened(value: float)`
- **Sinais Escutados:** Como os componentes se conectam seguindo *Call Down, Signal Up*.

### 2.3. Parâmetros de Game Feel (`@export`)
- Lista de variáveis exportadas com tipos, valores padrão e faixas (`@export_range`).

---

## 3. Decisões Técnicas com Justificativa (Trade-offs)

| Decisão | Opção Escolhida | Alternativa Descartada | Justificativa Técnica |
| :--- | :--- | :--- | :--- |
| **DT-01** | ... | ... | ... |

---

## 4. Conferência Automática contra a Constituição (`docs/CONSTITUICAO.md`)

| Regra Constitucional | Status | Evidência no Plano |
| :--- | :---: | :--- |
| **Modularidade / Sem Script Monolítico (< 200 linhas)** | ✅ / ❌ | ... |
| **Component Pattern Reutilizável** | ✅ / ❌ | ... |
| **StateMachine Isolada (se aplicável)** | ✅ / ❌ | ... |
| **Comunicação Desacoplada via Signals (*Call Down, Signal Up*)** | ✅ / ❌ | ... |
| **Game Feel 100% Parametrizado (`@export`)** | ✅ / ❌ | ... |
| **Tipagem Estática Estrita em GDScript** | ✅ / ❌ | ... |
| **Placeholder First (Greyboxing antes de Arte)** | ✅ / ❌ | ... |
| **Política de Testes e Sandbox Previstos** | ✅ / ❌ | ... |
| **Segurança e Validação de Dados (`Resource` / Save)** | ✅ / ❌ | ... |
| **Nomenclatura e Estrutura de Pastas Oficial** | ✅ / ❌ | ... |
