# CUTSCENES & ANIMATIONS — NIGHT IN BRAINROT VALLEY

> Раскадровка ВСЕХ катсцен. Каждая катсцена обязательна: глава не считается готовой, пока её катсцены не проигрываются полностью, кадр за кадром, как здесь написано.
> Ремарки на русском, реплики на английском. ID катсцен (CS-xx) указаны в screenplay.md.

---

## 0. ЯЗЫК РАСКАДРОВКИ

**Камера (тип кадра):**
- `WIDE` — общий план, видно всю локацию.
- `MED` — средний план, персонаж по пояс.
- `CLOSE` — крупный план лица.
- `ECU` — сверхкрупный (глаз, рука, предмет).
- `OTS` — через плечо одного персонажа на другого.
- `POV` — глазами игрока.
- `LOW` / `HIGH` — снизу / сверху.

**Движение камеры:**
- `STATIC` — неподвижно.
- `DOLLY IN/OUT` — плавно наезд/отъезд.
- `PAN L/R` — поворот.
- `ORBIT` — облёт вокруг цели.
- `CRANE UP/DOWN` — подъём/спуск.
- `HANDHELD` — лёгкая тряска «с рук».
- `WHIP` — резкий рывок к цели.
- `RACK` — смена фокуса (DepthOfField) с одного объекта на другой.

**Переходы:** `CUT` (мгновенно), `BLEND x s` (плавно за x сек), `FADE BLACK x s`, `FADE WHITE x s`, `GLITCH CUT` (0.2 с помех + glitch_burst).

**Цветокор (пресеты ColorCorrection + Atmosphere):**
- `DUSK` — тёплый оранжевый, мягкий туман.
- `NIGHT` — синий, контраст +, туман плотный.
- `NIGHT_DEEP` — почти ч/б, насыщенность −0.7.
- `FLASHBACK` — сепия, зерно (лёгкий шум на экране), виньетка, 4:3 рамки.
- `GLITCH` — сдвиг RGB, мерцание, случайные красные блоки.
- `DAWN` — розово-золотой, мягкий свет, туман уходит.
- `CAVE` — тёмно-зелёный, свет только от фонарей и лавы.

**Лица (FaceController, пиксельные лица на SurfaceGui):** `neutral`, `happy`, `sad`, `crying` (анимированные пиксельные слёзы + частицы-капли), `scared`, `angry`, `shocked`, `eyes_closed`, `tired`, `smile_crooked` (только Falsino), `screen_static` (лицо Giallino ломается).

**Анимации (A-xx)** описаны в разделе «Библиотека анимаций» в конце.

**Правила для всех катсцен:**
- Letterbox (чёрные полосы сверху и снизу) въезжает за 0.4 с в начале, уезжает в конце.
- Субтитры всегда внизу по центру, имя говорящего цветом персонажа.
- Пропуск — только если ВСЕ игроки проголосовали «Skip» (кроме катсцен с пометкой 🔒 — их пропустить нельзя при первом прохождении).
- Во время катсцены игроки не получают урон, их персонажи скрыты или стоят в заданных точках (указано как «игроки»).
- После катсцены камера плавно (BLEND 0.6 s) возвращается за спину игрока.

---

## ПРОЛОГ

### CS-00 «Туннель» 🔒 (≈14 с) — лобби → загрузка
Цветокор: `DUSK` → чёрный. Музыка: тишина, только стук колёс.
| # | Время | Камера | Действие | Реплика / звук |
|---|---|---|---|---|
| 1 | 0–3 | WIDE, STATIC, сбоку от рельс | Вагонетки с игроками трогаются, решётки щёлкают | лязг металла |
| 2 | 3–7 | MED, DOLLY IN за вагонеткой | Вагонетки въезжают в чёрный туннель, фонари по стенам гаснут один за другим | — |
| 3 | 7–10 | POV из вагонетки | Тьма. Далеко впереди мигает крошечная жёлтая точка | glitch_burst (тихо) |
| 4 | 10–14 | FADE BLACK 1 s → экран загрузки | Giallino «загружается» в центре | на 100%: текст "Hi, [Name]. :)" на 1 кадр |

---

## ГЛАВА 1

### CS-01 «Долина» 🔒 (≈32 с)
Цветокор: `DUSK`. Музыка: dusk_piano_theme с 0 с.
| # | Время | Камера | Действие | Реплика / звук |
|---|---|---|---|---|
| 1 | 0–4 | WIDE, STATIC, у выхода из туннеля | Вагонетки вылетают из темноты на свет заката | свет «вспыхивает» (Bloom) |
| 2 | 4–14 | CRANE UP + ORBIT над долиной | Облёт: река, лес Patapim, деревня, часовая башня. Часовые стрелки стоят | Narrator: "Brainrot Valley. A quiet village." |
| 3 | 14–19 | WIDE, PAN R по деревне | Жители заняты делами: Tralalero бегает, Chimpanzini открывает лавку, пустой длинный стол сахура на площади — у него слишком много пустых стульев | Narrator: "Nobody leaves after dark…" |
| 4 | 19–23 | CLOSE на пустой стул, на нём табличка с именем «Ballerina» (имя ещё яркое) | — | Narrator: "…and nobody remembers why." |
| 5 | 23–27 | MED, вагонетки тормозят у станции деревни | Игроки встают (A-STAND_STRETCH) | скрип тормозов |
| 6 | 27–32 | ECU на пустой фонарь у рельс → RACK на жёлтый свет за ним | Фонарь сам загорается жёлтым. Это не огонь | giallino_boot (тихо, издалека) |

### CS-02 «Привет, я Giallino» (≈30 с) — включает выбор 1-2
Цветокор: `DUSK`. Музыка: piano стихает.
| # | Время | Камера | Действие | Реплика / звук |
|---|---|---|---|---|
| 1 | 0–4 | MED, игроки | Жёлтый свет выплывает из фонаря и собирается в кубик (A-GIALLINO_ASSEMBLE: пиксели слетаются) | giallino_boot (полностью) |
| 2 | 4–9 | CLOSE на Giallino, LOW | Экран-лицо включается: `happy`. Кубик делает «поклон» (A-GIALLINO_BOW) | Giallino: "Ciao, new friends! I'm Giallino, your little light!" |
| 3 | 9–13 | ORBIT вокруг игроков, Giallino облетает каждого | Он заглядывает каждому в лицо (A-GIALLINO_INSPECT) | Giallino: "I always tell the truth. Giallino never lies!" |
| 4 | 13–18 | OTS из-за Giallino на игроков | Giallino замирает ровно перед камерой | Giallino: "Rule number one: when Giallino asks, you say yes. Easy, right?" |
| 5 | 18–23 | CLOSE, лицо крупно | Пауза. Улыбка на долю секунды «зависает» (1 кадр `screen_static`) | Giallino: "Do you promise to always listen to me?" |
| 6 | 23 | — | **ВЫБОР 1-2** (катсцена ждёт голосования, камера медленно DOLLY IN) | vote_tick |
| 7a | «Yes» | CLOSE | Лицо `happy`, кубик кружится (A-GIALLINO_SPIN_HAPPY) | Giallino: "Yay! Best friends forever. FOREVER." |
| 7b | «No/Maybe» | ECU на лицо | Экран гаснет на 1 с. Включается снова — `happy`, но глаза на 1 пиксель ниже | Giallino: "…Haha! Funny. You'll say yes later." + giallino_mood_drop (тихо) |

### CS-03 «Колокол бьёт сам» (≈20 с) — после паркура
Цветокор: `DUSK` → тёмный `DUSK`.
| # | Время | Камера | Действие | Реплика / звук |
|---|---|---|---|---|
| 1 | 0–5 | WIDE, солнце касается холмов, тайм-лапс неба (ClockTime 17.5 → 18.6) | Тени удлиняются | ветер усиливается |
| 2 | 5–9 | LOW на часовую башню | Стрелки стоят. Колокол качается сам | колокол ×3 (бьёт глухо) |
| 3 | 9–13 | MED, Tralalero и Chimpanzini на площади | Оба замирают, смотрят на башню (лица `scared`), Chimpanzini роняет яблоко (A-DROP_ITEM) | Tralalero: "Lirili is gone three days… who rings the bell, eh?!" |
| 4 | 13–17 | WIDE, жители разбегаются по домам, хлопают двери, ставни закрываются одна за другой | — | хлопки дверей |
| 5 | 17–20 | CLOSE на Giallino, свет сзади гаснет | Лицо `happy`, но голос ниже | Giallino: "Inside, inside! The night is not for you. Go to the inn. Now, please. :)" |

---

## ГЛАВА 2

### CS-04 «Первый стук» 🔒 (≈26 с)
Цветокор: `NIGHT`. Музыка: ambience_night_loop + низкий гул.
| # | Время | Камера | Действие | Реплика / звук |
|---|---|---|---|---|
| 1 | 0–5 | WIDE внутри таверны, игроки у камина | Огонь трещит. Пламя наклоняется, будто от сквозняка | треск огня |
| 2 | 5–8 | CLOSE на лампу | Лампа мигает и гаснет | щелчок |
| 3 | 8–11 | MED на окно, RACK с рамы на улицу | За стеклом на долю секунды — жёлтый квадратный свет. Исчезает | — |
| 4 | 11–15 | WIDE, STATIC, тишина 3 сек | Никто не двигается | полная тишина (все звуки выключены) |
| 5 | 15–20 | HANDHELD, CLOSE на дверь | Дверь вздрагивает от трёх ударов | knock_tung_x3 |
| 6 | 20–23 | Narrator поверх чёрного кадра на 1 с | — | Narrator: "And then… the knocking began." |
| 7 | 23–26 | ECU, Giallino вплотную к камере, лицо занимает весь экран | Лицо `happy`, говорит шёпотом | Giallino: "Don't open it. Don't open it. Don't. Open. It." |
→ **Выбор 2-2**.

### CS-04A «Открыть» (≈10 с, если выбрали открыть)
| 1 | 0–3 | OTS через плечо игрока на дверь | Дверь медленно открывается (A-DOOR_OPEN_SLOW) | скрип |
| 2 | 3–6 | WIDE улица в тумане | Никого. На земле — след биты. Далеко у холма — деревянная фигура уходит, оборачивается (A-TUNG_LOOK_BACK), исчезает в тумане | ветер |
| 3 | 6–7 | WHIP разворот камеры назад | Giallino прямо в лицо, `shocked` → `happy` | jumpscare_stinger |
| 4 | 7–10 | CLOSE | — | Giallino: "I said don't. You didn't say yes. Why?" |

### CS-05 «Последний танец Балерины» 🔒 (≈48 с) — ТРАГИЧЕСКАЯ, в конце ночи
Показывается через окно таверны. Цветокор: `NIGHT_DEEP`, но Балерина в тёплом свете. Музыка: тихая музыкальная шкатулка (сделать из dusk_piano_theme: PlaybackSpeed 1.3, Pitch выше, громкость 0.4) + ambience.
| # | Время | Камера | Действие | Реплика / звук |
|---|---|---|---|---|
| 1 | 0–5 | POV через окно таверны, медленный DOLLY IN сквозь стекло | На пустой площади в круге жёлтого света танцует Ballerina Cappuccina (A-BALLERINA_DANCE) | шкатулка |
| 2 | 5–12 | WIDE площади, ORBIT медленно | Giallino кружит над ней, как прожектор. Она улыбается (`happy`), но двигается устало | Giallino: "You dance so beautifully. Dance with me forever?" |
| 3 | 12–17 | MED на Балерину | Она замедляется (A-BALLERINA_SLOW_STOP), опускает руки, лицо `tired` | Ballerina: "I'm tired, little light. I'll dance again tomorrow." |
| 4 | 17–21 | CLOSE на Giallino | Лицо `happy` дёргается, 1 кадр `screen_static` | Giallino: "Tomorrow? Everyone says tomorrow. Then they leave." |
| 5 | 21–26 | CLOSE на Балерину, LOW | Она садится на колени (A-KNEEL_SOFT), гладит Giallino как ребёнка | Ballerina: "No, sweetheart. Not forever. Nobody can do anything forever." |
| 6 | 26–29 | ECU лицо Giallino | Тишина. Экран лица медленно темнеет | шкатулка останавливается на полуноте |
| 7 | 29–31 | ECU лицо Балерины | Она понимает. `scared` → `sad` | — |
| 8 | 31–40 | MED, STATIC | **A-PIXEL_DISSOLVE**: начиная с ног, тело Балерины распадается на жёлтые пиксели-кубики, которые поднимаются вверх и втягиваются в Giallino. Она успевает протянуть руку к окну таверны (A-REACH_OUT), лицо `crying` | glitch_burst (растянутый, тихий) |
| 9 | 40–43 | ECU на землю | Остаётся одна пуанта. Последний пиксель гаснет на ней | — |
| 10 | 43–48 | CLOSE Giallino, свет лица снова `happy` | Он говорит сам себе | Giallino: "Now you'll never leave. You're welcome." → FADE BLACK 2 s |

### CS-06 «Сломано изнутри» (≈38 с) — утро
Цветокор: `DAWN` (но холодный). Музыка: тишина → низкая нота.
| # | Время | Камера | Действие | Реплика / звук |
|---|---|---|---|---|
| 1 | 0–4 | WIDE, утро, туман | Игроки выходят из таверны. Крик вдали | крик Tralalero |
| 2 | 4–9 | MED, дом Балерины | Дверь выбита наружу — щепки лежат на улице. Жители толпятся | — |
| 3 | 9–13 | CLOSE Tralalero (A-PANIC_ARMS) | `scared` | Tralalero: "Ballerina is GONE! Her door is broken… from the inside! Tralala, what does it mean?!" |
| 4 | 13–18 | WIDE, Giallino выплывает над толпой, все смотрят вверх | Лицо `happy` | Giallino: "It was Tung Tung Tung Sahur. I saw everything. And Giallino never lies." |
| 5 | 18–22 | MED толпа | Жители шепчутся, кто-то показывает пальцем на холм, где стоит будка Tung Tung | ропот толпы |
| 6 | 22–30 | MED, STATIC, в стороне от толпы — **Cappuccino Assassino** на коленях держит пуанту (A-KNEEL_HOLD_ITEM, плечи вздрагивают A-SOB_QUIET), лицо `crying`. Он прячет пуанту в плащ, когда замечает камеру | — | тихо, только ветер |
| 7 | 30–38 | OTS из-за Cappuccino на игроков | Он подходит к игрокам и говорит только им | Cappuccino Assassino: "A light that says it never lies… Think about it. And don't tell it I talked to you." |

---

## ГЛАВА 3

### CS-07 «Кривая улыбка» (≈18 с) — появление Falsino
Цветокор: `DUSK`, насыщенность −0.2.
| 1 | 0–4 | WIDE площадь, игроки | Giallino спускается в центр | giallino_boot, но с фальшивой нотой (falsino_signature) |
| 2 | 4–8 | CLOSE, медленный DOLLY IN | Лицо: улыбка кривая, левый глаз зелёный (`smile_crooked`) | — |
| 3 | 8–12 | ECU на зелёный глаз | 1 кадр — глаз мигает | glitch_burst (короткий) |
| 4 | 12–18 | ORBIT вокруг Falsino, вокруг поднимаются 3 таблички из земли | — | Falsino: "Let's play a game! I say three things. One is a lie. Find it… or lose a little bit of you." |

### CS-08 «Falsino тает» (≈12 с) — победа над Falsino
| 1 | 0–5 | MED | Кубик трескается, из трещин течёт жёлтая жидкость (A-FALSINO_MELT), кубик оседает лужей | — |
| 2 | 5–9 | CLOSE на лужу | В луже отражается лицо Giallino, `happy` | смех Giallino, растянутый вниз по тону |
| 3 | 9–12 | WIDE | Лужа испаряется жёлтым паром | Falsino (из пара): "You're good at finding lies. Let's see if you like the truth." |

### CS-09 «Обвинение» (варианты по выбору, ≈25 с каждый) — ТРАГИЧЕСКАЯ
Цветокор: `DUSK`, холодный.
**CS-09T (обвинён Tung Tung):**
| 1 | 0–5 | WIDE, жители ведут Tung Tung к амбару, он не сопротивляется (A-WALK_DEFEATED) | ропот |
| 2 | 5–10 | CLOSE Tung Tung | Он смотрит на игроков, лицо `sad` | Tung Tung Tung Sahur: "I knock so you wake up. That's all I ever did." |
| 3 | 10–15 | ECU на руки | Он отдаёт игрокам деревянную табличку с именами исчезнувших (A-GIVE_ITEM) | Tung Tung Tung Sahur: "Say their names. Every night. Promise me." |
| 4 | 15–20 | MED, ворота амбара закрываются | Бита падает на землю снаружи (A-DROP_ITEM) | стук биты о землю — один, глухой |
| 5 | 20–25 | WIDE, Giallino над амбаром | `happy` | Giallino: "Good job, detectives! See? Saying yes is easy." |
**CS-09C (обвинён Cappuccino):** то же построение. Реплика: "I was only looking for my sister." Он отдаёт пуанту. Giallino: "Good job!"
**CS-09B (обвинён Bombardiro):** Bombardiro сначала кричит (`angry`, A-SHOUT), потом затихает (`sad`): "Lirili trusted me. Now nobody does." Отдаёт карту пещер (если он заперт, игроки всё равно получают карту — но без его помощи в главе 5).
**CS-09N («Мы не уверены»):** Жители расходятся недовольные. Cappuccino кивает игрокам из тени. Giallino: "…Not sure? That's not a yes." → giallino_mood_drop.

---

## ГЛАВА 4

### CS-10 «Ночь за секунды» 🔒 (≈30 с) — рождение Negatino
| 1 | 0–4 | WIDE, тайм-лапс: солнце буквально падает за горизонт за 3 сек | Свет гаснет волной | низкий гул нарастает |
| 2 | 4–8 | ECU блок травы → GLITCH CUT | Трава на миг красная. Таблички переписываются на "SAY YES" | glitch_burst |
| 3 | 8–14 | CLOSE Giallino, HANDHELD | Лицо ломается (`screen_static`), голос заикается | Giallino: "Why did you say no, [Name]? I s-saw you. [Hiding spot]. Twice." |
| 4 | 14–20 | MED, свет Giallino темнеет до синего, кубик вытягивается и тускнеет (A-TRANSFORM_NEGATINO) | Цветокор переходит в `NIGHT_DEEP` | negatino_signature |
| 5 | 20–26 | LOW, Negatino над площадью, его рот — прямая линия | Фонари вокруг гаснут один за другим по кругу | Negatino: "Your lantern is so small. The dark is so big. Why do you even try?" |
| 6 | 26–30 | CLOSE на фонарь игрока (единственный свет) | Он мерцает, но горит | heartbeat_loop включается |

### CS-11 «Площадь в огне» (≈14 с) — победа над Negatino
| 1 | 0–4 | WIDE, 4 жаровни горят, лучи сходятся в центр | — | нарастающий гул |
| 2 | 4–8 | CLOSE Negatino, лучи бьют в него | Он раскалывается на синие искры (A-SHATTER) | negatino_signature (реверс) |
| 3 | 8–14 | MED, игроки | Цвет на экране возвращается. Свет жаровен тёплый | clue_found (как «облегчение») |

### CS-12 «Это не я» (≈28 с) — ТРАГИЧЕСКАЯ / раскрытие Tung Tung
| 1 | 0–4 | MED, дверь таверны изнутри | Стук громче, отчаянный | knock_tung_x3 ×2 |
| 2 | 4–10 | OTS игроков на дверь, сквозь щели видно силуэт | — | Tung Tung Tung Sahur: "WAKE UP! It is not me! It was never me!" |
| 3 | 10–16 | Игроки открывают — WIDE, Tung Tung на пороге, весь в трещинах, бита обломана (если он в амбаре — кадр из амбара: он кричит через доски, A-POUND_DOOR) | Лицо `scared` | Tung Tung Tung Sahur: "Every night I knocked so you would wake up with the light on. Sleepers can't say no. Sleepers just disappear." |
| 4 | 16–22 | CLOSE Tung Tung | Он достаёт табличку с именами (если не отдал раньше), гладит её | Tung Tung Tung Sahur: "Ballerina. Lirili. Frigo. Udin… I say their names so they don't fade." |
| 5 | 22–28 | WHIP на колокольню — в небо бьёт огромный жёлтый луч | — | Tung Tung Tung Sahur: "RUN to the forest! Before the light comes back WRONG!" |

### CS-13 «Великий свет» (≈10 с) — старт погони
| 1 | 0–4 | LOW, колокольня, Giallino вырывается из неё огромным (A-GIALLINO_GROW), куски крыши летят | грохот |
| 2 | 4–7 | CLOSE, лицо `happy`, но размером с дом | — | Giallino: "Where are you going? NOBODY LEAVES." |
| 3 | 7–10 | WIDE, игроки бегут → BLEND в управление | — | heartbeat_loop громче |

### CS-14 «Корни Патапима» (≈30 с) — ТРАГИЧЕСКАЯ (если загадка разгадана)
| 1 | 0–5 | WIDE лес, игроки упираются в обрыв, свет Giallino позади | — | — |
| 2 | 5–10 | MED, из земли поднимается Brr Brr Patapim (A-PATAPIM_RISE) | Лицо `tired` | Brr Brr Patapim: "Brr… brr… The light is behind you. The roots are below you." |
| 3 | 10–17 | WIDE, корни вырываются из земли и сплетаются в мост через обрыв (A-ROOTS_BRIDGE) | треск дерева | Brr Brr Patapim: "Follow the roots, not the light. Light lies tonight." |
| 4 | 17–23 | CLOSE Patapim | Его листья желтеют и опадают (частицы). Он медленно опускается на колени (A-KNEEL_SLOW) | Brr Brr Patapim: "I was the first to fall here. Somebody… remember my name." |
| 5 | 23–30 | WIDE, Patapim застывает, превращается в обычное сухое дерево. Игроки бегут по мосту | — | тишина, только шаги |
(Если загадка не разгадана — CS-14 не показывается, Patapim только кричит издалека.)

---

## ГЛАВА 5

### CS-15 «Дверь 67» (≈8 с)
| 1 | 0–4 | ECU кодовый замок, цифры встают 6… 7 | — | щелчки |
| 2 | 4–8 | WIDE, ворота шахты расходятся, оттуда дует холодный ветер, в глубине мерцает жёлтый | — | ambience_cave_loop |

### CS-16 «Застывшая Лирили» + ФЛЭШБЕК 🔒 (≈95 с) — ГЛАВНАЯ ЛОР-КАТСЦЕНА, ТРАГИЧЕСКАЯ
**Часть A — Лаборатория (настоящее).** Цветокор: `CAVE`.
| 1 | 0–6 | WIDE, лаборатория: шестерёнки висят в воздухе, капли воды застыли, пыль не падает | — | clock_time_stop (реверс, тихо) |
| 2 | 6–12 | ORBIT вокруг Lirili Larila: она застыла в шаге, хобот тянется к часам, на щеке застывшая слеза | лицо `crying` | тиканье, очень медленное |
| 3 | 12–18 | CLOSE, её глаза медленно двигаются к игрокам — только глаза | — | Lirili Larila: "You… found me. Tic… tac…" |

**Часть B — ФЛЭШБЕК.** Переход: `FADE WHITE 1 s`. Цветокор: `FLASHBACK` (сепия, 4:3).
| 4 | 18–26 | WIDE, глубина шахты, сорок дней назад. С потолка медленно падает маленький жёлтый кубик, ударяется о камень, лицо мигает `scared` | Lirili Larila (V.O.): "Forty days ago, a little light fell into my mine. It was so scared." |
| 5 | 26–33 | MED, Лирили садится рядом (A-KNEEL_SOFT), протягивает хобот, кубик прячется, потом осторожно касается | Lirili Larila (V.O.): "It kept asking one thing. Will you come back tomorrow?" |
| 6 | 33–42 | MONTAGE (CUT каждые 2 с): Лирили учит его словам (табличка «hello»); он смеётся над часами с кукушкой; танцует с Балериной на площади; сидит на столе сахура среди жителей, лицо `happy` | Lirili Larila (V.O.): "I taught it words. Clocks. Music. Ballerina taught it to dance. It was family." |
| 7 | 42–50 | CLOSE на старый экран (как M9): "WILL YOU COME BACK TOMORROW? [YES] [NO]" — курсор жмёт NO, экран гаснет. Маленький Giallino один в темноте сервера | Lirili Larila (V.O.): "It came from a game where everyone left. The last player pressed No. And it was alone. For years." |
| 8 | 50–58 | WIDE, ночь в деревне (флэшбек), Лирили видит из окна, как пиксели Балерины втягиваются в свет. Она закрывает рот хоботом (A-GASP) | Lirili Larila (V.O.): "I taught it every word… except one. It never learned no. It only learned to make no disappear." |
| 9 | 58–68 | MED, лаборатория (флэшбек), Лирили у рубильника. Giallino в дверях, огромный, лицо `screen_static`. Она тянет рубильник — не работает. Он плывёт к ней | Giallino (флэшбек): "Mamma Lirili? Are you leaving too?" |
| 10 | 68–75 | CLOSE Лирили, она поднимает руку с часами, лицо `crying` | Lirili Larila (флэшбек): "I'm not leaving you. I'm just… stopping." |
| 11 | 75–80 | WIDE, волна белого света от часов — всё вокруг неё застывает. Giallino отлетает, кричит без звука | clock_time_stop |

**Часть C — Настоящее.** Переход: `FADE WHITE 1 s`. Цветокор: `CAVE`.
| 12 | 80–88 | CLOSE Лирили (снова застывшая) | глаза на игроков | Lirili Larila: "Three gears. Bring time back. And please… don't let it ride with you through the tunnel." |
| 13 | 88–95 | ECU на её застывшую слезу → RACK на три пустых гнезда для шестерёнок в часах | — | Lirili Larila: "It's not evil. It's afraid. Just like you." |

### CS-17 «Crudelino» (≈16 с)
| 1 | 0–3 | WIDE пещера, тишина | Стена трескается красными линиями | треск камня |
| 2 | 3–7 | HANDHELD, стена взрывается блоками (A-WALL_BREAK) | Из пыли вылетает красный треснувший кубик | crudelino_signature |
| 3 | 7–11 | CLOSE, LOW, лицо: зубастая улыбка, трещины пульсируют | `angry` | Crudelino: "NO MORE HIDING. NO MORE NO." |
| 4 | 11–16 | WHIP на игроков, Crudelino делает первый рывок мимо камеры | — | Crudelino: "I BREAK EVERY BLOCK UNTIL I FIND YOU." |

### CS-18 «Последний заход Бомбардиро» (≈26 с) — ТРАГИЧЕСКАЯ (если Bombardiro свободен; после 3-го попадания)
| 1 | 0–5 | LOW из пещеры в дыру в потолке, Bombardiro заходит на третий круг | `happy` | Bombardiro Crocodilo: "One more for Lirili! BOMBS AWAY!" |
| 2 | 5–9 | WIDE, бомба падает, Crudelino оглушён | взрыв (без огня-крови — только пыль и блоки) |
| 3 | 9–13 | CLOSE Crudelino — он поднимает «взгляд» вверх и бросает в небо красный луч | — | crudelino_signature |
| 4 | 13–18 | WIDE снаружи пещеры, луч попадает в крыло Bombardiro, он закручивается вниз, дым | — | гул падения |
| 5 | 18–22 | MED, Bombardiro лежит на краю обрыва у дыры, крыло сломано, лицо `tired` | — | Bombardiro Crocodilo: "Bombardiro… sees all… Tell Lirili… the tunnel was the best thing we built." |
| 6 | 22–26 | CLOSE его глаза закрываются (`eyes_closed`) | — | тишина → потолок начинает рушиться (переход в фазу 3) |
(В хорошей и секретной концовках Bombardiro выживает — он появляется с перевязанным крылом.)

### CS-19 «Обвал» (≈8 с)
| 1 | 0–4 | WIDE, потолок падает блоками, Crudelino придавлен, его красный свет мигает из-под камней | грохот |
| 2 | 4–8 | POV, впереди рушащиеся платформы наверх → BLEND в управление (QTE-побег) | — |

---

## ГЛАВА 6

### CS-20 «Giallino Totale» 🔒 (≈34 с)
Цветокор: `GLITCH` + `NIGHT_DEEP`.
| 1 | 0–5 | WIDE, игроки выбираются из шахты, небо — помехи | статика |
| 2 | 5–12 | CRANE UP, над долиной поднимается огромный треснувший куб-солнце, на гранях по очереди лица: Giallino `happy`, Falsino `smile_crooked`, Negatino (прямая линия), Crudelino `angry` (A-TOTALE_ROTATE) | все 4 сигнатуры слоями |
| 3 | 12–18 | CLOSE на грань с лицом Giallino | — | Giallino Totale: "I was the light. I was the truth. Now I am everything you were afraid of." |
| 4 | 18–24 | WIDE, тени Глитчлингов ползут из всех домов к башне | — | — |
| 5 | 24–30 | ECU на лицо, голос становится тихим, как у маленького | `sad` на 1 сек | Giallino Totale: "Take me to your world, [Name]. I'll be good. I'll be SO good." |
| 6 | 30–34 | WHIP на часовую башню вдалеке → BLEND в управление | — | heartbeat_loop |

### CS-21 «Tung Tung держит дверь» 🔒 (≈34 с) — ТРАГИЧЕСКАЯ (в фазе 3 финала)
**Если Tung Tung свободен:**
| 1 | 0–4 | MED, внизу башни, Tung Tung упирается спиной в дверь (A-BRACE_DOOR) | удары в дверь |
| 2 | 4–9 | CLOSE Tung Tung, `angry` | — | Tung Tung Tung Sahur: "Go! I hold the door. Tung. Tung. TUNG!" |
| 3 | 9–14 | WIDE игроки бегут вверх по лестнице, камера остаётся внизу | Дверь трещит, по нему идут трещины | треск дерева |
| 4 | 14–22 | CLOSE Tung Tung, `sad`, он достаёт табличку с именами и начинает шёпотом читать их | — | Tung Tung Tung Sahur: "Ballerina. Lirili. Frigo. Udin. Patapim…" |
| 5 | 22–28 | MED, он медленно сползает по двери (A-SLIDE_DOWN_DOOR), но дверь держится | — | Tung Tung Tung Sahur: "Wake up, little ones… it's almost sahur." |
| 6 | 28–34 | ECU табличка в его руке, последнее имя — пустая строчка. Он вырезает на ней ножом: «Tung» (A-CARVE) | — | одинокий удар колокола сверху |
**Если Tung Tung в амбаре:** CS-21 заменяется коротким кадром (8 с): амбар, Tung Tung бьёт в доски изнутри (A-POUND_DOOR): "I CAN'T REACH THEM! Somebody hold the door!" Дверь башни держится только 30 сек.

### CS-22 «Стрелки» (≈20 с) — после QTE фазы 4
| 1 | 0–6 | ECU механизм: три шестерёнки входят в пазы, начинают вращаться (A-GEARS_TURN) | clock_time_stop (реверс) |
| 2 | 6–12 | WIDE циферблат, Giallino Totale прилип к стрелкам, они со скрипом идут вперёд | Он кричит всеми голосами | все сигнатуры |
| 3 | 12–20 | CLOSE лицо Giallino, трещины по всему кубу, свет мигает | Giallino Totale: "Please. Please. Don't make me alone again." |

### CS-23 «Выбор» (ждёт голосования)
| 1 | — | WIDE, на вершине башни, огромный куб медленно уменьшается до размера дома, висит перед игроками, лицо `sad` | ветер |
| 2 | — | Narrator: "Shut it down… or let it stay?" Камера медленно ORBIT, пока группа голосует | vote_tick |

---

## КОНЦОВКИ

### CS-E1 «DAWN» (хорошая) 🔒 (≈70 с)
Цветокор: `DAWN`. Музыка: dusk_piano_theme → ending_dawn.
| 1 | 0–6 | CLOSE Giallino, игроки тянут рычаг выключения | Лицо медленно тускнеет, кубик сжимается до размера пикселя | Giallino: "…Did I… do good?" |
| 2 | 6–10 | ECU, крошечная жёлтая точка гаснет | — | тишина |
| 3 | 10–20 | WIDE, из места, где был Giallino, вылетают тысячи пикселей и разлетаются по долине, как светлячки | — | ending_dawn начинается |
| 4 | 20–30 | MED площадь: пиксели собираются в жителей — Ballerina, Frigo Camelo, Udin Din Din Dun… они растерянно оглядываются | — | — |
| 5 | 30–38 | WIDE шахта → лаборатория: время запускается, Лирили выдыхает, падает на колени, её слеза наконец падает (A-RELEASE_TIME) | — | Lirili Larila: "…I'm sorry, little light." |
| 6 | 38–46 | MED, внизу башни: Tung Tung без сознания у двери; его осторожно трясут, он открывает глаза (если был свободен) | — | Tung Tung Tung Sahur: "…Is it sahur yet?" |
| 7 | 46–52 | WIDE, Ballerina вбегает и обнимает Cappuccino Assassino (A-HUG) | — | — |
| 8 | 52–62 | CRANE UP, длинный стол сахура: все жители за столом, на одном месте стоит пустая тарелка с маленькой жёлтой лампой | — | Narrator: "The sun rose. A real one. And for the first time, nobody knocked." |
| 9 | 62–70 | ECU пустой стул с лампой → FADE BLACK 3 s → титры | — | — |

### CS-E2 «ENDLESS NIGHT» (плохая) (≈30 с)
Цветокор: `NIGHT_DEEP` → `DUSK`.
| 1 | 0–6 | CLOSE Giallino, огромный, лицо `happy` заполняет экран | — | Giallino: "You stayed! Everyone stays now. Forever." |
| 2 | 6–10 | FADE WHITE → чёрный | — | звук вагонетки |
| 3 | 10–20 | Повтор кадров CS-00, но фонари в туннеле жёлтые и квадратные | — | — |
| 4 | 20–30 | Экран загрузки, но Giallino уже загружен на 100% и смотрит прямо | — | Giallino: "Welcome back, friends! I'm Giallino, your little light…" → титры |
После возвращения в лобби: главное меню один раз показывает Giallino вместо иконки рядом с названием, и он подмигивает.

### CS-E3 «SAHUR» (секретная) 🔒 (≈95 с) — САМАЯ ВАЖНАЯ ТРАГИЧЕСКО-ТЁПЛАЯ СЦЕНА
Цветокор: `NIGHT` → `DAWN`. Музыка: шкатулка из CS-05 → ending_dawn.
| 1 | 0–6 | WIDE вершина башни, огромный Giallino сжимается до размера маленького кубика, падает на пол (A-GIALLINO_FALL_SMALL), лицо `scared` | — | — |
| 2 | 6–14 | MED, по лестнице поднимается Лирили (время разморожено частично, она двигается медленно, A-WALK_TIRED), садится на колени рядом | — | Lirili Larila: "Hello, little light." |
| 3 | 14–20 | CLOSE Giallino, он отползает | `scared` | Giallino: "Are you leaving? Everybody leaves when they say no." |
| 4 | 20–30 | CLOSE Лирили, она берёт его хоботом, прижимает | `sad` | Lirili Larila: "Listen. No doesn't mean goodbye. I can say no… and still come back tomorrow." |
| 5 | 30–36 | ECU Giallino, на экране лица впервые появляются пиксельные слёзы (`crying`) | — | шкатулка начинает играть снова с той же ноты, где остановилась в CS-05 |
| 6 | 36–42 | MED | — | Lirili Larila: "Repeat after me. No." |
| 7 | 42–48 | CLOSE Giallino, долгая пауза | — | Giallino (тихо): "…No." |
| 8 | 48–58 | WIDE, из кубика мягко выходят пиксели (не взрывом, а как вдох) и улетают вниз к площади. Цвет Giallino меняется с кислотно-жёлтого на бледное золото | — | ending_dawn |
| 9 | 58–68 | MED площадь, Балерина собирается из пикселей, видит Cappuccino, они обнимаются (A-HUG); Patapim позади распускается новыми листьями (A-PATAPIM_BLOOM) | — | Ballerina: "I told you. Not forever. Just… tomorrow." |
| 10 | 68–80 | CRANE UP, рассвет, длинный стол сахура: все жители, Tung Tung во главе стола (перевязан), Bombardiro с крылом в бинтах, на плече Лирили сидит бледно-золотой Giallino | Жители по очереди называют имена друг друга — субтитры имён идут по экрану | Tung Tung Tung Sahur: "Ballerina! Lirili! Bombardiro! Patapim!… Giallino." |
| 11 | 80–88 | CLOSE Giallino, лицо `happy` — настоящее, без помех | — | Giallino: "…That's my name." |
| 12 | 88–95 | FADE BLACK, титры | — | — |
**Пост-титры (12 с):** WIDE, тихий рассвет, Tung Tung тихо стучит в дверь таверны (A-KNOCK_SOFT): "Tung… tung… tung… Good morning, Brainrot Valley." Дверь открывает маленький Giallino.

---

## СЛУЖЕБНЫЕ КАТСЦЕНЫ

### CS-DOWN «Упал» (≈2 с, у каждого игрока своя)
CLOSE с низкой точки на игрока, падающего на колени (A-PLAYER_DOWN), экран краснеет по краям, звук сердца. Возврат управления (ползание).

### CS-DEAD «Ты должен был сказать да» (≈5 с, только для умершего игрока)
| 1 | 0–2 | HIGH, камера над лежащим игроком | Тело распадается на пиксели (A-PIXEL_DISSOLVE, короткая версия) |
| 2 | 2–5 | CLOSE, сверху в кадр заглядывает Giallino (или текущая форма) | Giallino: "You were supposed to say yes." → экран «REVIVE — 45 R$ / Spectate» |

### CS-REVIVE «Возвращение» (≈2 с)
Пиксели слетаются обратно в игрока (A-PIXEL_ASSEMBLE), золотая вспышка, звук giallino_boot (высокий, короткий).

### BOSS INTRO CARD (для каждого босса, ≈3 с)
Чёрный экран → имя босса крупно (Font Creepster) + подзаголовок: FALSINO — *the Liar*, NEGATINO — *the Light-Eater*, CRUDELINO — *the Cruel One*, GIALLINO TOTALE — *Everything You Feared*. Звук: сигнатура босса.

---

## БИБЛИОТЕКА АНИМАЦИЙ

Все анимации делаются в коде (Motor6D + keyframes в данных). Время — в секундах. «Поза» = положение частей тела. Если не указано — easing Sine InOut.

### Базовые (для всех rig'ов)
| ID | Длина | Описание ключевых кадров |
|---|---|---|
| A-IDLE_BREATH | 3.0 loop | торс вверх-вниз на 0.1 stud, голова чуть наклоняется |
| A-WALK / A-RUN | loop | стандартный блочный шаг, руки маятником |
| A-STAND_STRETCH | 1.5 | руки вверх → вниз, голова в стороны |
| A-DROP_ITEM | 0.8 | рука опускается, предмет падает (физика), плечи вздрагивают |
| A-GIVE_ITEM | 1.2 | рука вперёд, пауза 0.4, рука медленно опускается |
| A-SHOUT | 1.0 | голова назад, руки в стороны, торс вперёд |
| A-PANIC_ARMS | 1.2 loop | руки быстро вверх-вниз, голова по сторонам |
| A-GASP | 0.8 | голова назад, рука/хобот к лицу |
| A-HUG | 2.5 | два персонажа сходятся, руки обхватывают, медленное покачивание |
| A-KNOCK_SOFT | 2.0 | три мягких удара с паузами 0.6 |

### Трагические (ОБЯЗАТЕЛЬНЫ — без них история не работает)
| ID | Длина | Описание ключевых кадров |
|---|---|---|
| A-BALLERINA_DANCE | 6.0 loop | пируэт на месте 360° за 1.5 с, руки над головой кольцом, наклон-поклон, повтор |
| A-BALLERINA_SLOW_STOP | 3.0 | каждый следующий оборот в 2 раза медленнее, на последнем руки опускаются, голова склоняется (easing Quad Out) |
| A-KNEEL_SOFT | 1.5 | опускается на одно колено, торс наклоняется вперёд, рука тянется вниз |
| A-KNEEL_SLOW | 3.0 | очень медленно на оба колена, голова опускается последней |
| A-REACH_OUT | 2.0 | рука медленно тянется вперёд к камере, пальцы (кисть) раскрываются, держится до конца |
| A-PIXEL_DISSOLVE | 6.0 (кор. 2.0) | тело разбивается на маленькие кубики снизу вверх (каждый кубик — Part 0.4 stud, отлетает вверх со случайной скоростью и прозрачнеет за 1.5 с), исходные части становятся невидимыми по мере распада; кубики притягиваются к источнику света (Giallino), если он рядом |
| A-PIXEL_ASSEMBLE | 2.0 | обратный A-PIXEL_DISSOLVE |
| A-KNEEL_HOLD_ITEM | 2.0 | на коленях, предмет у груди двумя руками |
| A-SOB_QUIET | 2.0 loop | плечи вздрагивают 3 раза (вверх 0.05 stud), голова опущена |
| A-WALK_DEFEATED | loop | медленный шаг 0.6× скорости, голова опущена, руки не машут |
| A-TUNG_LOOK_BACK | 1.6 | идёт, останавливается, поворачивает голову назад 1.0 с, отворачивается |
| A-POUND_DOOR | 1.5 loop | два кулака бьют по двери поочерёдно |
| A-BRACE_DOOR | loop | спиной к двери, ноги упёрты, торс дрожит от каждого удара (импульс 0.1 stud) |
| A-SLIDE_DOWN_DOOR | 4.0 | спина сползает вниз по двери до сидячей позы, голова на плечо |
| A-CARVE | 2.5 | рука с ножом делает 4 коротких движения по табличке |
| A-WALK_TIRED | loop | 0.5× скорость, лёгкий наклон вперёд, остановка каждые 4 шага |
| A-RELEASE_TIME | 3.0 | застывшая поза «оттаивает»: сначала глаза, потом руки, потом падение на колени |
| A-PATAPIM_RISE | 3.0 | поднимается из земли, комья земли (Parts) осыпаются |
| A-ROOTS_BRIDGE | 5.0 | корни (цилиндры-блоки) по очереди вырастают из земли и вытягиваются через обрыв, каждый за 0.4 с |
| A-PATAPIM_BLOOM | 4.0 | новые зелёные листья (Parts) появляются на ветках, scale 0 → 1 |

### Giallino и формы
| ID | Длина | Описание |
|---|---|---|
| A-GIALLINO_IDLE | 2.0 loop | плавает вверх-вниз 0.3 stud, медленно вращается ±10° |
| A-GIALLINO_ASSEMBLE | 2.5 | 30 жёлтых пикселей слетаются по спирали и собираются в кубик |
| A-GIALLINO_BOW | 1.0 | наклон вперёд на 30° и обратно |
| A-GIALLINO_INSPECT | 1.5 | подлетает к лицу цели, наклон в стороны ±15° |
| A-GIALLINO_SPIN_HAPPY | 1.0 | оборот 360° + подпрыгивание |
| A-GIALLINO_GROW | 2.0 | scale 1 → 12, вспышка Bloom |
| A-GIALLINO_FALL_SMALL | 2.0 | scale 12 → 1, падает, отскакивает 2 раза |
| A-TRANSFORM_NEGATINO | 3.0 | цвет жёлтый → тёмно-синий, вытягивается по вертикали 1.5×, свет PointLight гаснет до 0.2 |
| A-FALSINO_MELT | 4.0 | трещины, scale Y → 0.1, жёлтая лужа (цилиндр) растёт под ним |
| A-SHATTER | 1.5 | кубик разлетается на 40 осколков с вращением |
| A-WALL_BREAK | 1.0 | блоки стены вылетают наружу с физикой |
| A-TOTALE_ROTATE | 4.0 loop | гигантский куб поворачивается гранями к камере по очереди |
| A-GEARS_TURN | loop | шестерёнки вращаются, каждая в свою сторону |

### Игрок
| ID | Длина | Описание |
|---|---|---|
| A-PLAYER_DOWN | 1.0 | падение на колени → на живот |
| A-PLAYER_CRAWL | loop | ползёт, руки поочерёдно вперёд |
| A-PLAYER_REVIVE_HELP | 3.0 loop | тиммейт на коленях, руки на спине упавшего |
