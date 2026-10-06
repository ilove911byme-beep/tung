# PROGRESS — Night in Brainrot Valley

Журнал сборки по фазам брифа (`roblox_horror_prompt.md`). Окружение: **CLOUD** (Claude Code on the web,
без Roblox Studio). «Работает» здесь значит: собирается (`rojo build`), проходит `selene`, `stylua`,
строгую проверку типов (luau-lsp + определения Roblox API) и `tools/check_data.py`. В Studio не
проверялось — это нужно сделать по шагам «Как проверить» в каждой фазе.

Если сессия оборвётся: прочитать этот файл и `git log -1`, продолжить с первой фазы, у которой нет ✅.

Проверки после каждой фазы: `./scripts/check.sh` (stylua, selene, luau-lsp, check_data, rojo build).

| Фаза | Статус | Коммит |
|---|---|---|
| 0 — скаффолд Rojo | ✅ | f07d9a2 |
| 1a — катсцены/анимации/голоса/звук, CS-02 и CS-05 | ✅ | a9c37b9 |
| 1b — геймплейные системы | ✅ | см. git log |
| 2 — MapBuilder | ⏳ | |
| 3 — Пролог + главы 1–2, CS-00…CS-06 | ⏳ | |
| 4 — главы 3–4, CS-07…CS-14 | ⏳ | |
| 5 — главы 5–6, CS-15…CS-23, концовки, служебные | ⏳ | |
| 5.5 — меню, лобби, очередь, загрузка, телепорт, мемы | ⏳ | |
| 6 — полировка | ⏳ | |

---

## Phase 0 — скаффолд ✅
✅ Done: два Rojo-проекта (lobby/story), `src/Shared` (Config, Strings, Types, UITheme), README.
📁 Files: `lobby.project.json`, `story.project.json`, `src/Shared/*`, `scripts/build.sh`, `selene.toml`, `roblox_min.yml`, `stylua.toml`.
🎬 Катсцен нет.
⚠️ selene использует `roblox_min.yml` (облако не может скачать API dump); stylua собирать с `--features luau`.

## Phase 1a — стек катсцен ✅
✅ Done: CutsceneEngine (клиент) + CutsceneService (сервер, общий старт по серверным часам, сегменты,
голосования, пропуск по голосам всех, 🔒), CameraRig (все типы планов и движения), переходы, цветокоры,
Overlay, PoseMath/PoseMixer/PoseAnimator, FaceController, эффекты (PixelDissolve/Assemble, Shatter, Melt,
Grow/Shrink, WallBreak, RootsBridge, Bloom, TimeFreeze), VoiceService (TTS, кеш, лимит), Audio,
MusicDirector, AmbienceDirector, Footsteps, SoundIds (97), тестовая площадка, `/cs`, `/fx`.
🎬 CS-02 ✅, CS-05 ✅; A-BALLERINA_DANCE, A-BALLERINA_SLOW_STOP, A-KNEEL_SOFT, A-REACH_OUT,
A-PIXEL_DISSOLVE, A-PIXEL_ASSEMBLE, A-GIALLINO_ASSEMBLE/BOW/INSPECT/SPIN_HAPPY/IDLE, A-IDLE_BREATH,
A-WALK, A-RUN ✅ (+ вспомогательная A-STROKE_SOFT).
Решения: в CS-05 музыка `music_lullaby_box` → `music_lullaby_stop` (бриф) вместо переделанного пиано.

---

## Phase 1b — геймплейные системы ✅
✅ Done: ChapterManager (главы = списки шагов, чекпоинты со снимком флагов и инвентаря, вайп → откат и
повтор шага), StoryContext (API для глав), StoryFlags (+ настроение Giallino → атрибут игрока),
HealthService (HP 100, Downed 30 с с ползанием, ревайв напарником 3 с, Dead → REVIVE 45 R$ / Spectate,
соло — «Retry from checkpoint», вайп партии), InventoryService (4 слота, фонарь с топливом, предметы),
QTEService (tap / hold / choice / party-бар), ParkourService (ParkourKit: block, start, checkpoint,
finish, moving, collapse, fake, lava, ladder, vine, линия падения), ThreatService (Glitchlings, погони),
HidingService (тег HidingSpot), BossFramework (карточка, телеграфы, волны, арена), DialogueService
(диалоги с выбором/условиями), ClueService (улики, Memory Pages, дневник), AchievementService (все
ачивки + BadgeService), AuraService (Aura-очки и доска), AtmosphereService (пресеты освещения, туман,
глитчи), PartyService (данные телепорта, ожидание партии), Hud (сервер) + клиентские UI: HUD
(цель, таймер, тосты, босс-карточка, Memory Page), DialogueUI, JournalUI, QTEUI, DeathUI; клиент:
DownedClient, WorldFx, FakeBlocks, GiallinoClient (компаньон с лицом и репликами по настроению).
RigFactory: humanoid / cube / custom-пропы (дверь, вагонетка, шестерни, табличка, рычаг), масштаб,
Giallino Totale с лицом на каждой грани, все персонажи и формы в RigSpecs.
📁 Files: `src/Story/ServerScriptService/{Systems,Story}/*`, `src/Story/StarterPlayerScripts/{UI,Gameplay}/*`,
`src/Story/StarterCharacterScripts/Health.server.lua`, `src/Shared/{Achievements,GiallinoText}.lua`,
`src/Shared/StoryData/*`, `src/Shared/Cutscenes/CS_{DOWN,DEAD,REVIVE}.lua`, `src/Shared/VoiceLines/Service.lua`,
`src/Shared/Animations/A_PLAYER_{DOWN,CRAWL,REVIVE_HELP}.lua`.
🎬 Cutscene checklist: CS-DOWN ✅ (CLOSE снизу, красная виньетка, сердце), CS-DEAD ✅ (HIGH + распад
на пиксели 2 с; CLOSE снизу — текущая форма Giallino заглядывает сверху, "You were supposed to say yes."
→ экран REVIVE/Spectate), CS-REVIVE ✅ (PixelAssemble + золотая вспышка + giallino_boot выше тоном).
A-PLAYER_DOWN / A-PLAYER_CRAWL / A-PLAYER_REVIVE_HELP ✅.
🧪 How to test (Studio, тестовая площадка): `/help`; `/down` → CS-DOWN, ползание, красные края, напарник
держит E 3 с; `/kill` → CS-DEAD → экран смерти (соло — Retry); `/revive` → CS-REVIVE; `/park` —
паркур со всеми типами блоков; `/qte tap|hold|choice|party`; `/mood 30` — компаньон «ломается»;
`/ach FIRST_NO` — тост; `/chapter N` — запуск глав (после фаз 3–5).
Решения (сам):
- Компаньон рисуется локально в масштабе 0.75, чтобы не закрывать обзор.
- Голос «maybe» в CS-02 меняет только настроение; FIRST_NO получают только голосовавшие «no».
- Пока ProductId Revive = 0, в Studio покупка симулируется (ревайв сразу), в live — кнопка неактивна.
- Грейд `KEEP` для служебных катсцен (не трогать освещение главы).
- В локальных катсценах персонаж игрока анимируется катсценой только если её cue его анимирует
  (иначе позу держит DownedClient).
- Здоровье: свой скрипт `Health` в StarterCharacterScripts отключает стандартную регенерацию.
⚠️ Known issues: проверено только сборкой/типами/данными, не в Studio. preview-инструмент не учитывает
поворот аксессуаров (`rot`) и прозрачность — только визуально в превью.
