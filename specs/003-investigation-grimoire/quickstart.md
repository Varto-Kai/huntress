# 🚀 Guia Rápido de Validação (Quickstart): `SPEC-003` (Investigação e Grimório)

**Feature**: `specs/003-investigation-grimoire`  
**Cena Sandbox**: `res://tests/sandboxes/sandbox_investigation.tscn`

---

## 1. Como Executar os Testes Automatizados (Headless)

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --headless --path . -s res://tests/unit/run_tests.gd
```

A suíte executa os testes da `SPEC-001`, `SPEC-002` e os novos testes da `SPEC-003`:
- `res://tests/unit/test_grimoire_tracker.gd`: Valida idempotência (`EC-002`), vínculo 1:1 por seção (`Q1`), contaminação por Pista Falsa (`is_false_lead = true`), julgamento manual via `toggle_clue_discarded` (`Q5`, `EC-006`) e resolução da síntese + receita de Óleo fabricável.
- `res://tests/unit/test_interaction_and_clues.gd`: Valida seleção determinística da pista não coletada mais próxima (`EC-001`), canalização `inspect_duration` (`Q2`), cancelamento imediato por esquiva/afastamento/dano (`EC-003`) e bloqueio de ataque enquanto o Grimório está aberto.

---

## 2. Como Validar na Cena Sandbox (`sandbox_investigation.tscn`) em < 45s

1. **Estado Inicial (`???`)**:
   - Observe os 2 alvos na arena (*Couraçado das Ruínas* e *Fera Ágil da Clareira*): seus rótulos táticos acima da cabeça iniciam ocultos (`Fraqueza: ??? | Óleo: ???`).
2. **Coleta de Pistas (Autênticas e Falsas)**:
   - Aproxime-se dos vestígios luminosos no chão e segure/aperte `E` (`interact`) por `0.5s` para inspecionar.
   - Experimente esquivar (`Espaço`) ou se mover durante a barra de `0.5s` para verificar o cancelamento imediato (`EC-003`).
3. **Julgamento Manual no Grimório (`Tab` ou `G`)**:
   - Abra o Grimório (`Tab` ou `G`). Note que se você coletou uma **Pista Falsa** junto com as demais, o Grimório mostra a contradição nos cartões de evidência e a síntese fica contaminada!
   - Leia as descrições, clique em **`[Descartar Pista]`** na evidência falsa (ex.: *Cinzas de Acampamento de Caçadores* ou *Crânio Velho de Javali*) e veja a síntese verdadeira destravar imediatamente o **Estilo Recomendado**, a **Fórmula de Materiais do Óleo Fabricável** e atualizar o HUD sobre a cabeça do monstro na arena!
4. **Validação em Combate**:
   - Feche o Grimório, alterne para o Estilo (`Q`) e Óleo (`R`) descobertos e quebre a postura (*Stagger / Break*) dos monstros.
