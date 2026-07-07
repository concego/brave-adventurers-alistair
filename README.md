# Brave Adventurers: Alistair 🐉

Beat 'em up medieval fantasy para Android — primeiro jogo da série *Brave Adventurers*.

**Protagonista:** Kyle Alistair, paladino  
**Engine:** Godot 4.3 | **Plataforma:** Android (APK) | **Orientação:** Landscape

---

## Controles (gestos na tela)

| Mão | Gesto | Ação |
|-----|-------|------|
| Direita | Swipe → | Ataque básico |
| Direita | Swipe ↑ | Pulo / desvio |
| Direita | Swipe ↓ | Bloqueio / defesa |
| Direita | Swipe ← | Ativar habilidade especial |
| Esquerda | Segurar →/← | Mover personagem |
| Esquerda | Swipe ↑ | Próxima habilidade |
| Esquerda | Swipe ↓ | Habilidade anterior |

## Habilidades de Kyle

| Habilidade | Descrição |
|---|---|
| Golpe Sagrado | Ataque potencializado com luz divina |
| Imposição de Mãos | Cura HP do Kyle |
| Escudo da Fé | Bloqueio reforçado temporário |
| Julgamento | Dano em área — útil quando cercado |

Todas as habilidades sobem de nível conforme são usadas.

## Acessibilidade

- TTS nos menus (narração completa)
- TTS ao trocar de habilidade durante o combate
- Áudio como mecânica: inimigos emitem sons de preparação antes de golpes pesados
- Inimigos com HP baixo fogem e emitem sons de recuo

## Estrutura do Projeto

```
brave-adventurers-alistair/
├── scripts/
│   ├── GameManager.gd       # Singleton: TTS, skills, progressão
│   ├── GestureController.gd # Detecção de swipes e hold
│   ├── Kyle.gd              # Personagem principal
│   ├── Enemy.gd             # IA de inimigo (patrol/chase/attack/flee)
│   └── MainMenu.gd          # Menu com TTS
├── scenes/                  # Cenas Godot (.tscn)
├── assets/
│   ├── sprites/
│   ├── sounds/
│   └── music/
├── .github/workflows/
│   └── build-android.yml    # Build automático → APK
└── export_presets.cfg
```

## Build

O APK é gerado automaticamente via GitHub Actions a cada push na `main`.  
Acesse a aba **Actions** → último workflow → **Artifacts** para baixar o APK.

## Série Brave Adventurers

Cada jogo da série apresenta um aventureiro diferente com seu conjunto único de habilidades.  
*Alistair* é o primeiro título.
