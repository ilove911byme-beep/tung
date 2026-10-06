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
| 2 — MapBuilder | ✅ | см. git log |
| 3 — Пролог + главы 1–2, CS-00…CS-06 | ✅ | см. git log |
| 4 — главы 3–4, CS-07…CS-14 | ✅ | см. git log |
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

## Phase 2 — MapBuilder ✅
✅ Done: весь мир строится кодом при старте сервера (`World/MapBuilder` + `World/Map/*`):
рельеф 160×160 блоков колонками с greedy-слиянием (горы на западе и севере террасами, холм с шахтой на
северо-востоке, холм Tung Tung, река с песчаными берегами и мостом, ущелье, поля с каналом, дорожки,
аэродром), туннель в скале с рельсами и заборами с факелами, станция, деревня — 14 домов в стиле
Minecraft (булыжный цоколь, бревенчатые углы, доски/кирпич, окна со скрытыми ставнями, ступенчатые
крыши), таверна с камином, рампой на 2-й этаж, ящиками и 7 укрытиями, дом Балерины (зеркало, половицы),
пекарня, лавка, мастерская Лирили (шкатулка, доска 3-1-2), амбар с камерой, ангар с картой пещер, мельница
с крутящимися крыльями, часовая башня 30 блоков (циферблат со стрелками, колокол, механизм с 3 гнёздами,
спиральная лестница из 44 ступеней, балкон M7, верх M12), площадь с длинным столом сахура (16 стульев,
таблички с именами) и 4 жаровнями, колодец с табличкой координат, фонтан, доска объявлений; лес Патапима
(~100 деревьев, дуб/светлые), огромное дерево с дуплом, трава/цветы/тростник/папоротник/грибы, плоские
облака (дрейфуют на клиенте); шахта вокселями с 3D greedy-слиянием: штольня с лестницей с поверхности,
петля вагонеток с 3 тупиковыми развилками и 4 низкими балками, лаборатория Лирили, комната рычагов
(4 рычага, шипы), лавовое озеро (платформы, тайный уступ), лабиринт (seed 67), пещера Crudelino (колонны,
сталактиты, камни, дыра в небо), руды со светом; все 25 якорей, Memory Pages M2–M12, ~70 именованных
точек для глав (`MapData.Points`, `MapBuilder.point(name)`), NPC-жители (тег NPC, idle-дыхание на клиенте),
спавн на станции, невидимые стены по краю, звуки реки/камина/лавы.
Текстуры: `Shared/World/TextureIds.lua` — все 24 PNG из `assets/textures/` подключены по имени; пока id
пустые, MapBuilder использует запасной материал + цвет из map.md (по брифу). После загрузки PNG в Roblox
достаточно вписать `rbxassetid://…` — на каждую грань встанет Texture с тайлом 4 studs.
📁 Files: `src/Shared/World/{MapData,Blocks,TextureIds}.lua`, `src/Story/ServerScriptService/World/MapBuilder.lua`,
`src/Story/ServerScriptService/World/Map/{Builder,Terrain,Underground,Village,Nature}.lua`,
`src/Story/StarterPlayerScripts/Gameplay/MapClient.lua`, `tools/map_preview/{roblox_mock.luau,run.py}`.
🎬 Cutscene checklist: в этой фазе катсцен нет (якоря для всех CS созданы).
🧪 How to test (Studio): Play → в Output «[MapBuilder] built Brainrot Valley: N parts». Точки для
скриншотов: `/tp station`, `/tp square`, `/tp tavern`, `/tp tower`, `/tp fields`, `/tp river`, `/tp hill`,
`/tp forest`, `/tp gorge`, `/tp mine`, `/tp lab`, `/tp lava`, `/tp cave`, `/tp sky`; также `/tp <имя точки>`
(например `/tp Fireplace`). Проверено офлайн: `python3 tools/map_preview/run.py --luau <luau> --out DIR`
прогоняет RigFactory + MapBuilder в Luau CLI на моке Roblox API — без ошибок, **6233 детали** (лимит 25 000),
все подземные точки достижимы (флуд-филл), рендеры вида сверху и изометрии совпадают со схемой.
Решения (сам):
- Где map.md и map_layout.png расходятся, взята картинка (дом Trippi Troppi — на северо-западе деревни).
- Studio-тестовая площадка Phase 1a выключена (`Config.Debug.TestStage = false`), вместо неё строится карта.
- Переходы между уровнями шахты — лестницы-фермы (TrussPart) и ступени в 1 блок, как в Minecraft.
- Ступени башни по 0.5 блока; на 2-й этаж таверны — пологая рампа.
- Frigo Camelo и Udin Din Din Dun есть днём в главе 1 и исчезают в первую ночь (их имена — на табличке Tung).
⚠️ Known issues: в Studio не запускалось; NPC без анимации ходьбы до фаз 3–5 (стоят дома). Текстуры —
плейсхолдеры (пустые id → материалы). Небесная тропа финала строится главой 6 (по map.md она появляется
только там).

## Phase 3 — пролог, главы 1–2 ✅
✅ Done: глава 1 (прибытие: CS-01 → CS-02 с голосованием; туториал — рубка 6 древесины на деревьях
деревни, фонарь у Chimpanzini с кричалкой, хлеб в пекарне, разговоры с камео, ссора Клубники и Банана у
фонтана, сплетни Tralalero; паркур за яблоком — лестница из листвы, камни через реку, вода = возврат,
CLEAN_JUMPS без падений; CS-03; 90 с до таверны в сгущающемся тумане, при опоздании — 2 глитчлинга;
CHAPTER_1), глава 2 (CS-04 🔒 → голосование: открыть → CS-04A + OPEN_THE_DOOR + флаг sawTungRunning;
баррикада → общий QTE-бар, провал 15 урона; спрятаться → 5 с на укрытие, «задержи дыхание», провал/не
спрятался 20 урона; ночь 2 минуты — костёр гаснет за 40 с, дрова из поленницы, при потухшем огне
глитчлинги лезут в окна, в окнах мелькают морды; CS-05 🔒; утро — дверь Балерины выбита наружу, щепки;
CS-06; CHAPTER_2). Эффекты выборов (настроение, ачивки только голосовавшим, флаги) — `Story/ChoiceEffects`.
NpcService (показ/скрытие, ходьба с A-WALK на клиенте, разговоры, кричалка при первой встрече),
дублёры игроков в катсценах (`@Player1..6` — копии аватаров), посадка в вагонетки (ride/dismount),
экран загрузки с «Hi, [Name]. :)» на один кадр, эффекты DropItem / ShowPart / HidePart, WorldFx silence /
loadingScreen / shuttersOpen / sfx, голоса камео (TTS-настройки, цвета, имена, кричалки).
📁 Files: `src/Shared/Cutscenes/CS_{00,01,03,04,04A,06}.lua`, `src/Shared/CutsceneKit.lua`,
`src/Shared/UI/LoadingScreen.lua`, `src/Shared/Animations/A_{SIT_CART,STAND_STRETCH,DROP_ITEM,GIVE_ITEM,
SHOUT,PANIC_ARMS,GASP,HUG,KNOCK_SOFT,TUNG_LOOK_BACK,DOOR_OPEN_SLOW,KNEEL_HOLD_ITEM,SOB_QUIET,POINT,LOOK_UP}.lua`,
`src/Story/ServerScriptService/Story/{ChoiceEffects.lua,Chapters/Chapter1.lua,Chapters/Chapter2.lua}`,
`src/Story/ServerScriptService/Systems/NpcService.lua`, VoiceLines (Chapter1/2, Chants), Actors, Effects, WorldFx.
🎬 Cutscene checklist: CS-00 ✅ (лобби; якоря лобби заданы, сам мир лобби — Phase 5.5), CS-01 ✅,
CS-02 ✅, CS-03 ✅, CS-04 ✅, CS-04A ✅, CS-05 ✅, CS-06 ✅ (все кадры и тайминги по cutscenes.md,
проверены `check_data`). Анимации: A-STAND_STRETCH ✅, A-DROP_ITEM ✅, A-GIVE_ITEM ✅, A-SHOUT ✅,
A-PANIC_ARMS ✅, A-GASP ✅, A-HUG ✅, A-KNOCK_SOFT ✅, A-TUNG_LOOK_BACK ✅, A-DOOR_OPEN_SLOW ✅,
A-KNEEL_HOLD_ITEM ✅, A-SOB_QUIET ✅ (+ вспомогательные A-SIT_CART, A-POINT, A-LOOK_UP).
🧪 How to test (Studio, Config.SkipLobby = true): 1) Play → глава 1 стартует сама с CS-01 (вагонетки
вылетают из туннеля, облёт, табличка «Ballerina», фонарь загорается) → CS-02 с голосованием.
2) Задачи в HUD: E на деревьях (Chop), E на Chimpanzini (Buy), E на полке в пекарне. 3) Паркур у реки
(восток от амбара), яблоко наверху. 4) CS-03 → 90 с до таверны. 5) Глава 2: CS-04 → голосование.
Повтор катсцен: `/cs CS_00`, `/cs CS_01`, `/cs CS_02`, `/cs CS_03`, `/cs CS_04`, `/cs CS_04A`, `/cs CS_05`,
`/cs CS_06`. Прыжок к главе/шагу: `/chapter 2`, `/chapter 1 parkour`, `/chapter 2 night`.
Решения (сам):
- Фонарь у Chimpanzini — бесплатно всей группе («first lantern free»); дрова идут в камин в главе 2.
- Ночью все жители прячутся (NPC скрыты), утром возвращаются домой, кроме Балерины, Frigo и Udin.
- В CS-04A настоящая дверь таверны прячется, её играет риг Door; после катсцены Giallino её захлопывает.
- «Полная тишина» в CS-04 — затухание групп Music/Ambience/SFX на 3.4 с.
- Скрип тормозов и крик — плейсхолдеры: door_open (быстрее) и TTS-реплика Tralalero.
⚠️ Known issues: в Studio не запускалось — главы проверены только статически (строгие типы, данные,
тайминги). Камеры катсцен рассчитаны по координатам карты, без визуальной проверки в движке.

## Phase 4 — главы 3–4 ✅
✅ Done: глава 3 — журнал, 7 настоящих улик (следы, табличка у колодца, оплавленное стекло на крыше
пекарни через паркур по крышам с чекпоинтами, падение 25 урона, ROOFTOP_RUNNER, тайная ветка к сундуку с
Сияющим фонарём SECRET_LANTERN; скрипящая половица; шкатулка Лирили с кодом 3-1-2 голосованием; карта
Bombardiro только при вежливом выборе; загадка Patapim → riddleCorrect; SIX_SEVEN), 2 фальшивые (бита у
мельницы, записка на доске) с репликой Falsino; допросы Tralalero / Chimpanzini (грубость = «Fanum tax»,
забирает предмет) / Cappuccino, разговоры с Tung на холме (TUNG_FRIEND за 3); при 4+ уликах выход на
площадь → CS-07, карточка FALSINO, выбор «You're not Giallino.» (spottedFalsino + LIAR_SPOTTED), 3 раунда
«правда или ложь» (6 раундов в пуле, таблички с текстом, Falsino читает вслух, 30 урона за неверный голос,
волны глитчлингов между раундами, 2 из 3 — победа, иначе заново) → CS-08 + BEAT_FALSINO; обвинение →
CS-09T/C/B/N (заключённый в амбаре, табличка имён / пуанта / карта пещер, CHAPTER_3).
Глава 4 — CS-10 (рождение Negatino, компаньон исчезает), бой: 4 бутылки масла, 4 жаровни, Negatino не входит
в круги света (жаровни 22, фонарь 10, сияющий 14 studs), касание 35 урона + 3 с темноты, обесцвечивание
экрана по расстоянию, фаза 2 — гасит жаровни с телеграфом 2.5 с (если рядом стоит игрок — не может),
раздувание QTE, волны каждые 20 с, 10 с всех четырёх горящих → CS-11, BEAT_NEGATINO, NEVER_DARK;
CS-12 (два варианта: у двери таверны / из амбара); CS-13 → погоня огромного Giallino по деревне (отставание
3 с = Downed, падающие заборы, глитчлинги); лесной паркур; ущелье: CS-14 + мост из корней (Patapim
засыхает, его имя на табличке) или обход с двумя сложными прыжками; переход к шахте, CHAPTER_4.
📁 Files: `src/Shared/Cutscenes/CS_{07,08,09T,09C,09B,09N,10,11,12,13,14}.lua`, `src/Shared/Dialogues/*`,
`src/Shared/StoryData/FalsinoRounds.lua`, `src/Shared/VoiceLines/Chapter{3,4}.lua`,
`src/Shared/Visual/Effects/Morph.lua` (Transform, Wither, DirtBurst), `src/Shared/Animations/A_{FALSINO_MELT,
WALK_DEFEATED,TRANSFORM_NEGATINO,SHATTER,POUND_DOOR,GIALLINO_GROW,GIALLINO_FALL_SMALL,PATAPIM_RISE,ROOTS_BRIDGE,
KNEEL_SLOW,PATAPIM_BLOOM,DOOR_CLOSE,DOOR_OPEN_FAST}.lua`, `src/Story/ServerScriptService/Story/Chapters/Chapter{3,4}.lua`.
🎬 Cutscene checklist: CS-07 ✅, CS-08 ✅, CS-09T ✅, CS-09C ✅, CS-09B ✅, CS-09N ✅, CS-10 ✅, CS-11 ✅,
CS-12 ✅ (оба варианта), CS-13 ✅, CS-14 ✅; карточки FALSINO и NEGATINO ✅. Анимации: A-FALSINO_MELT ✅,
A-WALK_DEFEATED ✅, A-TRANSFORM_NEGATINO ✅, A-SHATTER ✅, A-POUND_DOOR ✅, A-GIALLINO_GROW ✅,
A-GIALLINO_FALL_SMALL ✅, A-PATAPIM_RISE ✅, A-ROOTS_BRIDGE ✅, A-KNEEL_SLOW ✅, A-PATAPIM_BLOOM ✅.
🧪 How to test (Studio): `/chapter 3` → улики (E на следах у дома Балерины, табличке колодца, половицах,
шкатулке, Bombardiro, Patapim, бите у мельницы, доске объявлений), лестница у юго-западного угла пекарни
→ крыши; с 4+ уликами зайти на площадь → бой Falsino. `/chapter 4` → CS-10 и бой Negatino (бутылки в
переулках, E на жаровнях), `/chapter 4 chase`, `/chapter 4 forest`. Катсцены: `/cs CS_07` … `/cs CS_14`,
варианты `/cs CS_09T`, `/cs CS_09C`, `/cs CS_09B`, `/cs CS_09N` (вариант CS_12 «jailed» — через главу).
Решения (сам):
- Паркур по крышам — по желанию (лестница «Climb the rooftops»), иначе игроки застревали бы в трекинге.
- Шкатулка Лирили — код выбирается голосованием из 4 вариантов.
- Обход ущелья — сегмент с двумя прыжками через узкий западный край (падение 20 урона, возврат к старту).
- Путь от ущелья до шахты — короткое затемнение (через всю карту ночью).
- ParkourService: один наблюдатель на сегмент (раньше каждый track() добавлял ещё один — двойной урон).
- check_data теперь проверяет диалоги, а `scripts/check.sh` падает при ошибках данных.
⚠️ Known issues: проверено статически (типы, данные, тайминги, связность). Баланс боя Negatino (скорость
14, кулдаун касания 3 с) и паркуров не проверен руками.
