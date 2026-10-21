# 🚀 Guia Rápido de Validação (Quickstart): `SPEC-004`

**Feature**: `specs/004-preparation-crafting`  
**Cena Sandbox**: `res://tests/sandboxes/sandbox_preparation.tscn`

---

## 1. Execução da Suíte Automatizada (Headless)
```powershell
& "C:\Users\victor.lacerda\Documents\DEV\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s res://tests/unit/run_tests.gd
```

## 2. Roteiro de Teste em Menos de 60 Segundos (`sandbox_preparation.tscn`)
1. **Início (Lâmina Limpa & Sem Óleos Prontos)**:
   - Pressione `Q` fora da Fogueira: a Caçadora não consegue aplicar Óleos porque o estoque inicial de cargas é `0`.
   - Pressione `1` / `2`: as Posturas (`FAST_STEEL` e `HEAVY_IMPACT`) alternam normalmente em campo (`Q1`).
2. **Coleta de Pistas e Reagentes (`[E]`)**:
   - Inspecione as pistas no chão e colete os nós de reagentes (`Base Alquímica Pura`, `Bile Corrosiva`, `Pó de Enxofre`, `Sebo Inflamável`, `Brasa Seca`).
3. **Fogueira Lado a Lado (`[E]` na Fogueira Central)**:
   - Interaja com a Fogueira (`InteractableCampfire`): o **Grimório** abre à esquerda e a **Bancada de Alquimia & Loadout** abre acoplada à direita (`Q3`).
   - Leia as pistas à esquerda, descarte a Pista Falsa e sintetize o Óleo correto à direita (`+8 cargas`).
4. **Combate, Desgaste por Golpe (`Q2`) e Adaptação Silenciosa (`Q4`)**:
   - Golpeie no vazio (*whiff*): as cargas de Óleo **não** diminuem.
   - Golpeie o alvo (`CombatDummy`): cada acerto confirmado consome `1` carga.
   - Volte à Fogueira e clique em **`[Descansar na Fogueira]`**: o HP da Caçadora e os reagentes do mapa são restaurados, e os monstros da região se adaptam silenciosamente (atacando mais rápido e punindo golpes sem o Óleo certo!).
