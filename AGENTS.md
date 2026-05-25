# Ki Adventure - Instruções para Codex

## Objetivo do projeto

Este projeto é um protótipo de jogo 2D top-down de ação e aventura feito em Godot 4 com GDScript.

A inspiração é um RPG de ação com combate corpo a corpo e ataques de energia, mas não devem ser usados personagens, nomes, sprites, músicas ou conteúdos protegidos de Dragon Ball.

## Tecnologias

- Godot 4.x
- GDScript
- Git
- VS Code

## Estrutura de pastas

- `scenes/`: cenas Godot
- `scenes/player/`: cena do jogador
- `scenes/enemies/`: cenas de inimigos
- `scenes/projectiles/`: cenas de projéteis
- `scenes/ui/`: interface
- `scripts/`: scripts separados seguindo a mesma estrutura de scenes
- `assets/`: sprites, sons e recursos visuais

## Regras de implementação

- O jogo é top-down, sem gravidade e sem pulo.
- O jogador deve usar `CharacterBody2D`.
- Ataques e projéteis devem usar `Area2D`.
- O movimento inicial deve utilizar `ui_left`, `ui_right`, `ui_up` e `ui_down`.
- Criar inputs novos apenas para ações como `attack` e `ki_blast`.
- Priorizar código simples e educativo.
- Não implementar sistemas grandes sem solicitação explícita.
- Não adicionar plugins ou dependências externas.
- Não usar assets protegidos por direitos autorais.
- Usar formas simples ou placeholders quando precisar de visual temporário.

## Fluxo de trabalho

- Antes de alterar cenas existentes, explicar quais arquivos serão modificados.
- Implementar uma mecânica por vez.
- Ao finalizar, listar arquivos criados/modificados e explicar como testar dentro do Godot.
- Não modificar funcionalidades existentes que já estejam funcionando sem necessidade.