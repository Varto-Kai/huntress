# 🏗️ Plano Técnico de Implementação: [FEATURE]

**Diretório da Feature**: `specs/[###-feature-name]` | **Data**: [DATE] | **Spec**: `specs/[###-feature-name]/spec.md`  
**Status no Ciclo SDD**: `[ ] 4. Plano Técnico Elaborado (/speckit-plan)`  
**Constituição de Referência**: `.specify/memory/constitution.md` (v1.1.0)

---

## 1. Resumo Executivo

[Síntese do requisito principal da Spec + abordagem técnica modular escolhida na Godot 4.x]

---

## 2. Contexto Técnico e Arquitetura (Godot 4.x)

- **Engine & Linguagem**: Godot 4.x — GDScript Estrito (Tipagem Estática Obrigatória)
- **Camadas Envolvidas**: [Ex.: Camada de Entidade (`CharacterBody2D`), Camada de Componentes (`Node` / `Area2D`), Camada de Dados (`Resource`)]
- **Armazenamento / Dados**: [Ex.: `Custom Resources (.tres)` somente leitura em `res://src/data/` ou JSON validado em `user://`]
- **Estratégia de Testes**: Testes unitários/componentes + Cena *Sandbox Greybox* (`res://tests/sandboxes/`)
- **Meta de Performance**: 60 FPS estáveis, zero alocações desnecessárias em `_physics_process`

### 2.1. Árvore de Cenas e Composição de Nós (`Nodes`)

```text
EntityRoot (CharacterBody2D / Node2D)
├── VisualGreybox (Polygon2D / ColorRect)
├── CollisionShape2D
├── MovementComponent (Node)
├── HealthComponent (Node)
├── HurtboxComponent (Area2D)
└── StateMachine (Node)
    ├── IdleState (Node)
    ├── MoveState (Node)
    └── DodgeState (Node)
```

### 2.2. Responsabilidade Única por Script / Componente

| Script / Cena | Tipo Base | Caminho (`res://`) | Responsabilidade Única (SRP) | Requisitos Atendidos |
| :--- | :--- | :--- | :--- | :--- |
| `[NomeComponente]` | `Node` | `res://src/components/...` | [Descrever responsabilidade isolada] | `RF-001` |

---

## 3. Modelo de Dados, Sinais e Parâmetros `@export`

### 3.1. Custom Resources (`.gd` / `.tres`)
- [Listar classes `Resource`, propriedades tipadas e garantia de imutabilidade/duplicação]

### 3.2. Contrato de Sinais (*Call Down, Signal Up*)
- **Sinais Locais Emitidos**: `signal exemplo_concluido(valor: float)`
- **Sinais Globais (`SignalBus`)**: [Apenas se houver comunicação entre sistemas distantes]

### 3.3. Parâmetros de Game Feel (`@export`)
| Variável `@export` | Tipo | Valor Padrão | Faixa (`@export_range`) | Efeito no Game Feel |
| :--- | :--- | :--- | :--- | :--- |
| `max_speed` | `float` | `180.0` | `50.0, 500.0, 5.0` | Velocidade máxima de deslocamento |

---

## 4. Decisões Técnicas com Justificativa (Trade-offs)

| ID | Decisão | Opção Escolhida | Alternativa Descartada | Justificativa Técnica |
| :--- | :--- | :--- | :--- | :--- |
| **`DT-01`** | [Tema] | [Escolha] | [Alternativa] | [Por que esta decisão é superior e respeita a Constituição] |

---

## 5. Constitution Check (Conferência Automática contra a Constituição)

*PORTÃO AUTOMÁTICO: Deve passar 100% antes da geração de Tarefas (`/speckit-tasks`).*

| Regra Constitucional (`.specify/memory/constitution.md`) | Status | Evidência Concreta neste Plano |
| :--- | :---: | :--- |
| **1. Modularidade Total (Sem script monolítico; < 200 linhas)** | ✅ / ❌ | [Evidência] |
| **2. Component Pattern (Nodes independentes e reutilizáveis)** | ✅ / ❌ | [Evidência] |
| **3. StateMachine Isolada (Estados como Nodes separados)** | ✅ / ❌ | [Evidência] |
| **4. Comunicação Desacoplada (*Call Down, Signal Up* / `signals`)** | ✅ / ❌ | [Evidência] |
| **5. Game Feel 100% Parametrizado (`@export` sem números mágicos)** | ✅ / ❌ | [Evidência] |
| **6. Tipagem Estática Estrita em GDScript** | ✅ / ❌ | [Evidência] |
| **7. Placeholder First (Validação em Greybox antes de arte final)** | ✅ / ❌ | [Evidência] |
| **8. Política de Testes (Unitários/Componentes + Cena Sandbox)** | ✅ / ❌ | [Evidência] |
| **9. Segurança e Integridade de Dados (`Resource` / Save seguro)** | ✅ / ❌ | [Evidência] |
| **10. Nomenclatura e Estrutura Oficial de Pastas (`src/`, `tests/`)** | ✅ / ❌ | [Evidência] |

---

## 6. Estrutura de Arquivos a Criar/Modificar

```text
specs/[###-feature]/
├── spec.md              # Especificação clarificada (Portão 1)
├── plan.md              # Este arquivo (/speckit-plan)
├── tasks.md             # Tarefas + Análise Cruzada (/speckit-tasks & /speckit-analyze)
└── checklists/
    └── requirements.md  # Checklist de qualidade da Spec

src/
├── components/
├── state_machine/
├── entities/
└── data/

tests/
├── unit/
└── sandboxes/
```
