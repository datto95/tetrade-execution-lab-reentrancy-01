# Roteiro de Evolucao - Tetrade Execution Lab

Este documento define os proximos marcos para o laboratorio `reentrancy-01` e para os laboratorios seguintes.

## Fase 1 - Consolidacao do reentrancy-01

Objetivo:
Garantir que o laboratorio atual esteja robusto para uso didatico e revisao tecnica.

Entregas:
- CI no GitHub executando `forge build`, `forge test` e validacao de evidencia.
- README revisado para reproducibilidade completa.
- Script de evidencia validando schema e registrando hash dos artefatos.

Criterio de aceite:
- Pipeline verde em push e pull request.
- Evidencia gerada e validada sem intervencao manual extra.

## Fase 2 - Fortalecimento de qualidade

Objetivo:
Reduzir risco de regressao e ampliar cobertura de comportamento.

Entregas:
- Testes adicionais para limites de saque e multiplas tentativas de ataque.
- Testes de propriedades (fuzz) para invariantes basicas de saldo.
- Relatorio de gas comparando vault vulneravel e vault corrigido.

Criterio de aceite:
- Novos testes cobrindo cenarios de borda e invariantes criticas.
- Sem quebra do fluxo de evidencia.

## Fase 3 - Pacote didatico

Objetivo:
Tornar o lab pronto para treinamento interno/externo.

Entregas:
- Guia passo a passo para aluno.
- Guia para instrutor com explicacao do exploit e da correcao.
- Checklist de auditoria rapida para contratos semelhantes.

Criterio de aceite:
- Um usuario novo consegue executar e interpretar o lab sem apoio adicional.

## Fase 4 - Escala para novos labs

Objetivo:
Padronizar o formato para outros vetores de vulnerabilidade.

Labs candidatos:
- `overflow-underflow-01`
- `access-control-01`
- `oracle-manipulation-01`

Padrao minimo por lab:
- Contrato vulneravel.
- Contrato corrigido.
- Contrato atacante/simulador.
- Testes de exploit, fix e controle negativo.
- Evidencia com schema.

## Backlog tecnico imediato

1. Adicionar badge de CI no README.
2. Gerar release `v0.1.0` do `reentrancy-01`.
3. Criar template de issue para novos laboratorios.
4. Criar template de pull request com checklist de reproducibilidade.
