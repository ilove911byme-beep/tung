# Night in Brainrot Valley

Roblox story-horror game: Italian brainrot characters, a Minecraft-style village, and a villain called Giallino.

| File | What it is |
|---|---|
| `roblox_horror_prompt.md` | Build brief for Claude Code (phases, systems, rules) |
| `screenplay.md` | Full story script, bosses, death/revive, 30 achievements |
| `cutscenes.md` | Shot-by-shot storyboards + animation library |
| `lore.md` | World history, characters, 12 Memory Pages |
| `voice_lines.md` | Voice settings and extra lines |
| `map.md`, `map_layout.png` | World layout, block palette, camera anchors |
| `assets/audio/` | 97 original sounds and music tracks (.ogg) |
| `assets/textures/` | 24 original 16×16 block textures (.png) |
| `cloud-setup.sh` | Setup script for the Claude Code cloud environment |

## Start

Open this repo in Claude Code on the web (claude.ai/code) and write: **«Начинай Phase 0 по roblox_horror_prompt.md»**.
Дальше — по фазам из брифа: после каждой фазы Claude останавливается и ждёт слова «continue».

---

## Структура проекта (Phase 0)

Два плейса в одной вселенной, у каждого свой Rojo-проект. Общий код — `src/Shared`.

| Путь | Куда попадает в Studio |
|---|---|
| `lobby.project.json` / `story.project.json` | Rojo-проекты Lobby и Story |
| `src/Shared/` | `ReplicatedStorage.Shared` (оба плейса): `Config`, `Strings`, `Types`, `UITheme`; дальше сюда придут Cutscenes, Animations, Dialogues, VoiceLines, SoundIds, Achievements |
| `src/Lobby/ServerScriptService`, `src/Lobby/StarterPlayerScripts`, `src/Lobby/ReplicatedFirst` | серверные/клиентские скрипты лобби и экран загрузки |
| `src/Story/ServerScriptService`, `src/Story/StarterPlayerScripts`, `src/Story/ReplicatedFirst` | то же для Story |
| `src/Story/ServerStorage/Models` | плейсхолдер-риги персонажей (строятся кодом) |
| `build/Lobby.rbxl`, `build/Story.rbxl` | готовые файлы плейсов (коммитятся) |
| `scripts/build.sh` | stylua + selene + `rojo build` обоих плейсов |
| `assets/` | аудио и текстуры (Rojo их **не** синкает — грузишь в Roblox вручную и вставляешь ID) |

Расширения скриптов: `*.server.lua` — Script, `*.client.lua` — LocalScript, просто `*.lua` — ModuleScript.

## Как открыть игру в Studio

### Вариант 1 — скачать готовые плейсы (проще всего)
1. Открой этот репозиторий на GitHub, ветку с текущей фазой.
2. Скачай `build/Lobby.rbxl` и `build/Story.rbxl` (кнопка Download raw file).
3. Открой каждый файл в Roblox Studio.

### Вариант 2 — живая синхронизация (Rojo)
Нужен Rojo 7.7.x (в облаке стоит 7.7.1) и плагин Rojo в Studio той же версии (7.7.x).
1. Склонируй репозиторий на свой ПК и установи Rojo: <https://rojo.space/docs/v7/getting-started/installation/> (плагин ставится оттуда же или из Creator Store).
2. Открой пустой плейс в Studio (Baseplate).
3. В папке репозитория запусти ОДИН из серверов:
   - `rojo serve lobby.project.json` — для Lobby,
   - `rojo serve story.project.json` — для Story.
4. В Studio: вкладка **Plugins → Rojo → Connect**, порт по умолчанию 34872.
5. Скрипты на диске — источник правды. Не редактируй те же скрипты внутри Studio.

## Как опубликовать оба плейса в одной вселенной

1. В Studio открой `Lobby.rbxl` → **File → Publish to Roblox As…** → создай новую игру (Create new game). Это создаёт вселенную (universe) и первый плейс — Lobby.
2. Открой `Story.rbxl`. **File → Publish to Roblox As…** → выбери ту же игру и в списке мест нажми **Create new place** (или в Creator Hub открой игру → **Places → Create place**, а потом выбери его).
3. Узнай PlaceId каждого плейса: Creator Hub → твоя игра → Places → у каждого плейса число в ссылке/в меню «Copy Place ID».
4. Впиши их в `src/Shared/Config.lua`:
   ```lua
   Config.PlaceIds = { Lobby = 111, Story = 222 }
   ```
   Пересобери (`./scripts/build.sh`) или просто сохрани файл при работе через Rojo, и опубликуй оба плейса ещё раз.
5. Стартовым плейсом игры (Start Place) сделай Lobby: Creator Hub → игра → Places → Lobby → Set as start place.
6. Для теста перехода Lobby → Story телепорт не работает внутри Studio — для этого нужны опубликованные плейсы и запуск через Roblox Player (Phase 5.5).
7. Позже (по фазам): создай Developer Product «Revive» на 45 R$ и впиши ProductId в `Config.Revive.ProductId`; создай 30 бейджей (по 5 в день бесплатно) и впиши badgeId в `Shared/Achievements`.

## Как проверить, что Phase 0 работает

1. Открой `Story.rbxl` в Studio, нажми **Play**.
2. В Output должно быть: `[NIGHT IN BRAINROT VALLEY] Story place booted. place=Unknown version=0.0.1-phase0 skipLobby=true` (`place=Unknown` — нормально, пока плейс не опубликован и PlaceId не вписан).
3. То же для `Lobby.rbxl`: строка `Lobby place booted…`.
4. В Explorer проверь: `ReplicatedStorage → Shared` содержит `Config`, `Strings`, `Types`, `UITheme`.
5. Красных ошибок в Output быть не должно.

`Config.SkipLobby = true` действует **только внутри Studio** (`Config.shouldSkipLobby()` дополнительно проверяет `RunService:IsStudio()`), в опубликованной игре лобби не пропускается.

## Проверки в облаке

```
./scripts/build.sh      # stylua --check, selene, rojo build обоих плейсов
```
Из облака нельзя открыть Studio и запустить игру: «собирается и проходит линтеры» ≠ «работает в игре».

## UI-стандарты

Все цвета, шрифты, радиусы и тайминги — только из `Shared/UITheme`; все строки игрока — из `Shared/Strings`.
Для телефона и ПК: `UIScale` от `UITheme.ReferenceResolution` + `UIAspectRatioConstraint`, зоны нажатия не меньше `UITheme.MinTouchTarget` (44 px).

## Заметки по инструментам (облако)

- `stylua` должен быть собран с Luau: `cargo install --locked stylua --features luau` (без флага он не понимает типы Luau). `cloud-setup.sh` уже обновлён.
- `selene generate-roblox-std` в облаке не работает (прокси, TLS), поэтому `selene.toml` использует `roblox_min.yml` — минимальный список глобальных Roblox-имён. На своём ПК можно выполнить `selene generate-roblox-std`, поставить `std = "roblox"` и удалить `roblox_min.yml`.
- `--!strict` проверяется только в Studio (Script Analysis); в облаке нет `luau-analyze`.
