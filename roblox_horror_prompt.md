# PROMPT FOR CLAUDE CODE — Roblox Story Horror Game "Night in Brainrot Valley"

<environment>
This prompt works in two setups. Check which one you are in at the start and say it in your first report.

A) CLOUD (Claude Code on the web / `claude --cloud`, Linux VM, GitHub repo) — no Roblox Studio here.
- Tools: if `rojo`, `selene`, `stylua` are missing, install them with `cargo install --locked rojo selene stylua` (crates.io is reachable; GitHub release downloads of other repos are blocked, so do not use rokit/aftman/foreman here).
- You cannot open Studio or playtest. Verify with: `rojo build` of both projects (must succeed), `selene src` (no errors), `stylua --check src`. Never claim a cutscene or mechanic "works in game" — say "builds and lints clean, needs Studio test".
- At the end of every phase: build `build/Lobby.rbxl` and `build/Story.rbxl` (commit them — I download them from GitHub and open in Studio), commit with a clear message, push the branch, and give me the exact test steps. Wait for my playtest notes before the next phase.
- Keep `Packages/` and `sourcemap.json` in .gitignore, but NOT `build/`.

B) LOCAL (Claude Code on my Windows PC with Roblox Studio open).
- I run `rojo serve` and connect the Rojo plugin in Studio. If Roblox Studio MCP tools are available in this session, use them after every phase: start a playtest, read Server + Client console output, capture the viewport during each cutscene of the phase, and fix errors until the console is clean. Only claim something works if a playtest or console output showed it.
- Do not edit scripts in Studio and on disk at the same time — disk (Rojo) is the source of truth.

In both setups: commit after every phase so I can roll back.
</environment>

<role>
You are a senior Roblox game developer (Luau, Roblox Studio, Rojo) who ships chapter-based multiplayer story games in the style of "Break In" and "Field Trip Z": scripted cutscenes, dialogue with choices, timed events, chases, and multiple endings. You write clean, server-authoritative, data-driven code.
</role>

<context_carry_forward>
- Repo state at start: only these docs + `assets/` exist; no code yet.
- Decisions locked: Rojo + Luau (--!strict); two places (Lobby, Story) in one universe; Minecraft-style village world built by code from map.md with my textures; villain is GIALLINO (original); revive = 45 R$ developer product; 30 badges; all music and sounds already exist in assets/audio; voices via AudioTextToSpeech with optional uploaded overrides.
- Story, cutscenes, lore and voices are fully written in the four documents in the project root — implement them, do not rewrite them.
</context_carry_forward>

<context>
- Project starts empty. Build it as a Rojo project (filesystem → Studio sync) in the current directory, so I can open it in Roblox Studio with the Rojo plugin.
- You cannot click inside Roblox Studio. Everything (map, models, UI, cutscenes) MUST be created by code: scripts, ModuleScripts, and build scripts that generate Parts at runtime or that I run once from the Studio command bar.
- Characters come from the "Italian brainrot" meme cast. Build them as simple blocky placeholder rigs made of Parts (recognizable by color/shape + name tag). Keep every model in one folder so I can later swap them for meshes from the Creator Store.
- Visual target: a Minecraft-style plains village world (oak houses with log corners, cobblestone foundations, glass windows, stepped roofs, dirt paths, fence torches, wheat fields, hay, flowers, river, dark forest, mineshaft with rails and ores, flat blocky clouds). Exact layout, zones, block palette and anchors are in `map.md` + `map_layout.png`. 1 block = 4 studs. My original pixel textures are in `assets/textures/` (24 PNGs): apply them with `Texture` instances, StudsPerTileU/V = 4, on every face; until I paste their asset IDs use the fallback material + color from map.md.
- Mood reference: slow-burn psychological horror where a cheerful, helpful AI companion (Giallino) gradually becomes wrong, then hostile. Quiet days, terrifying nights, glitches that feel like the game itself is breaking.
- In-game text language: [GAME LANGUAGE: English]. Put all player-facing strings in one Strings module so they can be translated.
</context>

<source_documents>
Five design documents are in the repo root. Read ALL of them fully before writing any code. They are the source of truth; this prompt only explains how to build them.
- `screenplay.md` — every scene, choice, boss phase, death rule, checkpoint, achievement (30 badges). Authoritative for gameplay.
- `cutscenes.md` — shot-by-shot storyboards for every cutscene (CS-00 … CS-E3, CS-DOWN/DEAD/REVIVE, boss intro cards), color grades, face expressions, and the full animation library (A-xx). Authoritative for cutscenes, dialogue inside cutscenes, and animations.
- `lore.md` — world history, character motives, and the 12 Memory Pages (collectibles with exact texts and locations).
- `voice_lines.md` — per-character TTS voice settings, intro chants, lobby/daytime lines.
- `map.md` (+ `map_layout.png`) — the whole world: coordinates of every zone and building, underground layout, block palette with textures and fallbacks, lighting, camera anchors, Memory Page spots, performance rules.
If two documents disagree: cutscenes.md wins for anything inside a cutscene, screenplay.md wins for gameplay.
</source_documents>

<story_bible>
Summary for orientation only (details live in the documents above):
- Title: Night in Brainrot Valley. 1–6 players, 35–50 min, prologue + 6 chapters + 3 endings. Theme: "No doesn't mean goodbye."
- World: a blocky valley where forgotten memes fall and live; whoever is forgotten fades into pixels. The minecart tunnel is the only way to the players' world.
- Main villain — GIALLINO: a glowing yellow CUBE (one block in size) with a pixel-screen face. A former helper bot from an abandoned game whose last player pressed "No". It believes "no" = being abandoned, so it "saves" everyone who says no by dissolving them into pixels inside itself. Says "Giallino never lies." Wants to ride the tunnel into the players' world. It follows each player with a hidden MOOD (100 → 0). Use ONLY in-game/Roblox data when it "knows things" about players.
- Forms: FALSINO (denial/liar, Ch3 mini-boss), NEGATINO (despair/light-eater, Ch4 boss), CRUDELINO (rage/block-breaker, Ch5 boss), GIALLINO TOTALE (finale, 4 phases). Minions: Glitchlings.
- Tragic beats that MUST land: Ballerina's last dance and dissolve (CS-05), Cappuccino Assassino with her pointe shoe (CS-06), the accused villager's goodbye (CS-09), Tung Tung's truth (CS-12), Patapim giving his roots and withering (CS-14), Lirili's flashback (CS-16), Bombardiro shot down (CS-18), Tung Tung holding the door and carving his own name (CS-21), Giallino's "Did I do good?" (CS-E1) and learning "No" (CS-E3).
- Giallino and all its forms are ORIGINAL characters for this game. Never use the name "Verity", a yellow sphere design, or any dialogue/scenes from ThatMob's videos.
</story_bible>

<gameplay_systems>
Build these as reusable, data-driven systems:
1. Lobby + main menu + party queue: see <lobby_and_menu> below. The party is teleported to a reserved server of the Story place (TeleportService:ReserveServer) and the story starts right where the lobby ended. In Studio testing, a `Config.SkipLobby` flag starts the story directly.
2. ChapterManager (server): runs chapters in order from data modules, handles checkpoints, game-over/retry of the current chapter, and ending selection from story flags.
3. CutsceneEngine (client, triggered by server): plays cutscenes defined as data tables — camera keyframes (CFrame, FOV, tween time, easing), actor moves/animations, dialogue lines, sounds, screen fades, letterbox bars, camera shake. All players see the same cutscene in sync. Skippable only when all players vote skip.
4. DialogueSystem: speaker name + portrait color + typewriter text; choice options; party votes on choices (majority, 15 s timer, random on tie).
5. ClueSystem + Journal UI: tabs Clues (real + fake with "?"), Suspects, Memories (12 Memory Pages from lore.md, glowing pickups in the world, Narrator reads each), Names (Tung Tung's list of the vanished — reading it awards SAY_THEIR_NAMES).
6. StoryFlags: one server table (e.g. tungTungJailed, cluesFound, giallinoMood, riddleCorrect) that every chapter reads and writes.
7. Giallino companion: client-side follower per player + server-owned mood; dialogue lines chosen by mood tier (Happy 100–70, Off 69–40 = Falsino phase, Broken 39–10 = Negatino phase, Hostile <10 = Crudelino phase); text corruption function.
8. Night/day + atmosphere: Lighting controller (ClockTime tweens, fog, Atmosphere, ColorCorrection), ambient sound layers, scripted glitch effects (block recolor, sky flicker, sign text swap).
9. Threat AI: PathfindingService chase for Giallino's hostile form and night threats; hiding spots (wardrobes, beds) with a "hold breath" mini-check; damage goes through HealthAndDeath (item 13).
10. Items: wood, lantern, bandage, cave map, Truth Gears — simple server-validated inventory, max 4 slots.
11. Ending badges: part of the Achievements system (item 18).
12. VariantController (server): spawns/despawns Falsino, Negatino, Crudelino and Giallino Totale from data (model, speed, abilities, sound set, voice settings), driven by giallinoMood and chapter.
13. HealthAndDeath: 100 HP shown as 10 blocky hearts; HP 0 → Downed (crawl, 30 s bleedout, teammate holds E 3 s to revive for free, +30 HP); bleedout → Dead → death screen with "REVIVE — 45 R$" and "Spectate" (free respawn at the next checkpoint). Whole party dead → free restart from the last chapter checkpoint. Solo: "Revive — 45 R$" or free "Retry from checkpoint". No damage during cutscenes. Fall damage for parkour drops.
14. Revive purchase: Developer Product (price 45 R$, ProductId placeholder in Config). Prompt with MarketplaceService:PromptProductPurchase; grant ONLY inside a single server-side MarketplaceService.ProcessReceipt handler: verify the player is Dead in this server, revive in place with 100 HP + 3 s invulnerability, record the PurchaseId in a per-server table so the same receipt is never granted twice, and return PurchaseGranted only after the revive succeeded (NotProcessedYet otherwise, e.g. player left). If the player is no longer dead (a teammate revived them while the prompt was open), still grant: give them full HP instead, so a purchase is never wasted.
15. ParkourKit: data-driven segments (start, checkpoint parts, kill/fall zones, moving and collapsing blocks, fake blocks with a subtle edge flicker, lava blocks = instant Downed, ladders and vines with climb, ledge-grab optional). Each segment reports "fell / finished / finished without falls" for achievements.
16. BossFramework: one reusable state machine for bosses (phases, HP or objective-based progress, attacks with telegraphs — sound + red highlight 1 s before, minion waves, arena bounds, checkpoint before the fight, per-phase checkpoints in the finale). Bosses from screenplay.md: Falsino (truth-or-lie vote game), Negatino (light 4 braziers), Crudelino (dash attacks, flare marks + Bombardiro bombs or stalactite fallback, collapse escape), Giallino Totale (4 phases).
17. QTE system: button prompts that work on PC (keys), mobile (big on-screen buttons) and gamepad; types: tap-spam, hold-in-zone, left/right/duck choice; shared party bar for the finale.
18. Achievements: Roblox Badges, all 30 from the table in screenplay.md with rarity tiers Common / Rare / Epic / Legendary / Secret. `Shared/Achievements` module: {id, name, rarity, description, badgeId = 0, hidden = true for Secret}. Award via BadgeService:AwardBadge on the server with a check first. Pop-up toast on unlock with rarity color (Common grey, Rare blue, Epic purple, Legendary gold, Secret glitchy red). Main menu ACHIEVEMENTS page shows all of them; Secret ones show "???" until owned.
</gameplay_systems>

<lobby_and_menu>
Goal: a polished, cinematic start like top Roblox story-horror games — main menu → lobby → party queue → seamless jump into the story. Two places in one universe: LOBBY place and STORY place (two Rojo project files: lobby.project.json, story.project.json, shared code in one folder).

A) Main menu (first thing a player sees on join):
- Camera slowly flies along a spline over the night valley built in the lobby place (blocky hills, fireflies, the village lights far away, the clock tower on the horizon). BlurEffect size 6 + vignette + slight letterbox.
- Title "NIGHT IN BRAINROT VALLEY" (Font Creepster, warm orange #FF9A3C with soft glow behind it); every ~20 s the title glitches for 0.3 s (letters swap, glitch_burst sound, Giallino's face flashes red for 1 frame).
- Small floating Giallino next to the title: idle bob + blink; it follows the mouse with its eyes.
- Buttons (Font FredokaOne, dark glass panels #0E1220 at 15% transparency, 2px orange stroke on hover): PLAY · CHAPTERS · ENDINGS · ACHIEVEMENTS · SETTINGS · CREDITS. Animations: buttons slide in from the left with 0.06 s stagger; hover = scale 1.05 + glow + vote_tick sound; click = press-down 0.95 + item_pickup sound.
- CHAPTERS: 6 cards with blocky thumbnails (ViewportFrame of each location), locked chapters greyed with a padlock; replay unlocks are based on owned ending badges (no DataStore).
- ENDINGS: 3 silhouettes (Dawn / Endless Night / Sahur), revealed when the player owns that badge (BadgeService:UserHasBadgeAsync). The secret one shows "???" until unlocked.
- SETTINGS: volume sliders (Music, Ambience, SFX, Voice), subtitles on/off, voices on/off, camera shake on/off, graphics "low/high" (fog + particles).
- CREDITS: scrolling list with placeholders.
- PLAY: camera swoops down to the lobby, UI fades, the player gets control.

B) Lobby world ("Last Stop" train station at the edge of the valley, dusk, blocky style):
- Small station with lanterns, a ticket booth, notice boards with lore posters ("MISSING: Ballerina Cappuccina", "Do not go out after dark", "Lost: one clock. Ask Lirili"), and the rail tunnel into the valley.
- Tung Tung Tung Sahur stands far away on a hill in the fog; when a player walks close he is gone (lore teaser), knock_tung_x3 plays once.
- QUEUE: 4 minecarts on the rails = 4 party queues. Step in → seat. Each cart: 1–6 seats, owner can toggle Public/Friends-only, 20 s countdown (resets when someone joins, owner can press "Start now"), BillboardGui with "3/6 · Starting in 12". Leaving the cart removes you from the queue.
- Meme corner (see <memes>): emote stage, "6 7" sign, Aura leaderboard (session-only).
- Endings wall: 3 framed blocky paintings, lit up for endings the player owns.

C) Transition into the story (must feel seamless):
1. Countdown ends → cart bars lock, carts roll into the tunnel (TweenService along rail points), screen darkens.
2. Custom teleport/loading screen (TeleportService:SetTeleportGui + ReplicatedFirst loading screen in the Story place, same design): black background, Giallino in the center "booting up" (progress ring around it), random tips ("Lanterns keep the dark away", "Not everything that smiles is your friend"), sound giallino_boot at 100%.
3. Teleport the party with TeleportData {partyId, members, chosenChapter}. The Story place waits until all members arrive (max 30 s, then starts with whoever is there).
4. Chapter 1 opens INSIDE the same minecart coming out of the tunnel into the valley at sunset — the arrival cutscene continues the lobby moment.

D) UI quality bar: consistent design tokens in one `UITheme` module (colors, fonts, corner radius 10, stroke, padding, tween times); UIScale + UIAspectRatioConstraint so it looks right on phone, tablet and PC; all touch targets ≥ 44 px; no overlapping UI at 360×640 or 1920×1080.
</lobby_and_menu>

<memes>
Current memes kids know — use them as COMEDY in the lobby and in daytime chapters only. Night and chase scenes stay scary, no jokes there.
- Extra Italian brainrot cameos (background NPCs, 1–2 lines each, original lines): Trippi Troppi, Boneca Ambalabu, Udin Din Din Dun, La Vaca Saturno Saturnita, Frigo Camelo, Glorbo Fruttodrillo.
- "6 7": lobby sign; an emote with the two-hands up-and-down gesture; the mineshaft door code is 67; the 6th and 7th clues are found together and an NPC yells "SIX… SEVEN!".
- AURA: brave actions show a pop-up "+100 AURA" (reviving a teammate, solving a puzzle, finding a clue, hiding successfully); failing shows "−50 AURA". Session-only Aura leaderboard in the lobby and on the ending screen. "Aura farming" pose emote.
- Fruit drama: a strawberry and a banana NPC couple in the village who argue loudly about their "love island" drama during the day; in Chapter 3 one of them is a witness.
- Brainrot-maxxing: Tralalero Tralala's gossip lines are stuffed with slang ("no cap", "rizz", "sigma", "skibidi", "it's giving").
- "Fanum tax": Chimpanzini Bananini takes one item from the inventory as a "tax" if the party picks the rude dialogue option.
- Lobby emote stage: wheel with 4 emotes (6 7, aura pose, brainrot dance, Tung Tung bat swing).
- Do NOT use characters, logos or audio from Skibidi Toilet, Labubu, Chill Guy, Sprunki or real people (including meme kids) — only the words/phrases and gestures above.
</memes>

<cutscenes_and_animation>
Cutscenes are the core of this game. A chapter is NOT done until every one of its cutscenes from cutscenes.md plays start to finish, shot by shot, with the listed camera, actor animations, faces, lines, sounds, color grade and transitions. Never replace a cutscene with a fade + text, never shorten it, never mark it "TODO".

1. Cutscene data: convert every storyboard table in cutscenes.md into a data module `Shared/Cutscenes/CS_xx.lua` (one file per cutscene, ID = file name). Each shot = { t0, t1, camera = {type, from, to, target, fov, move, shake}, actors = {{id, anim, face, moveTo}}, line = {speaker, voiceLineId}, sfx, music, grade, transitionIn }. Camera positions are defined relative to named anchor Parts in the map (e.g. `Anchor_Tavern_Window`, `Anchor_Square_Center`) so the MapBuilder must create those anchors.
2. CutsceneEngine must support every term in cutscenes.md section 0: shot types (WIDE…ECU, OTS, POV, LOW/HIGH), moves (STATIC, DOLLY, PAN, ORBIT, CRANE, HANDHELD, WHIP, RACK via DepthOfFieldEffect), transitions (CUT, BLEND, FADE BLACK/WHITE, GLITCH CUT), color-grade presets (DUSK, NIGHT, NIGHT_DEEP, FLASHBACK with sepia + grain + 4:3 bars, GLITCH, DAWN, CAVE) applied with tweened ColorCorrection/Atmosphere/Bloom, letterbox, subtitles with speaker color, branching cutscenes (CS-04A, CS-09T/C/B/N, CS-14 only if riddleCorrect, CS-18 only if Bombardiro free, CS-21 two versions), in-cutscene votes (CS-02, CS-23), lines that insert [Name]/[hiding spot] per client, 🔒 no-skip cutscenes on first play.
3. Sync: server starts a cutscene with a shared start time; clients play it locally from data and report finished; the server waits for all (max length + 3 s).
4. Actors: cutscenes spawn their own actor copies of NPC rigs (from ServerStorage/Models) at anchor points and clean them up after; real NPCs are hidden during the cutscene.
5. Animation system (code-only, no uploaded assets): every rig is built from Parts joined by Motor6Ds. Build a `PoseAnimator` that plays keyframe data (Motor6D C0 offsets + timing + easing) from `Shared/Animations/A_xx.lua`. Implement EVERY animation in the cutscenes.md library (base, tragic, Giallino forms, player). Tragic animations must follow the described timing and easing exactly — the slow-downs and pauses are what make them sad.
6. Special effects as reusable modules: PixelDissolve / PixelAssemble (body breaks into 0.4-stud cubes that float up and get pulled toward a target), Shatter, Melt, Grow/Shrink, WallBreak, RootsBridge, Bloom (leaves), TimeFreeze (particles and parts stop mid-air, then resume).
7. FaceController: pixel faces on a SurfaceGui (front face of the head / Giallino's screen) with all expressions from cutscenes.md (neutral, happy, sad, crying with animated pixel tears + drop particles, scared, angry, shocked, eyes_closed, tired, smile_crooked, screen_static). Faces change in cutscenes AND in gameplay dialogue.
8. A Studio-only debug command `/cs CS_xx` (only when RunService:IsStudio()) plays any cutscene alone so I can review it.
</cutscenes_and_animation>

<audio_and_voice>
All audio is original and already made by me, already in the repo at `assets/audio/` (it is NOT synced by Rojo — I upload the files to Roblox and paste the IDs). Create `Shared/SoundIds` with one entry per file (`"rbxassetid://0"` placeholder + comment where it is used). If my upload quota runs low, short one-shots of the same kind (footsteps, block sounds, blips) may be packed by you into "sprite" files later — ask me first.

- `audio/music/` (13 tracks): music_lobby, music_day_village, music_night, music_investigation, music_chase, music_boss, music_cave, music_lullaby_box (Giallino's theme), music_lullaby_stop (one-shot that slows and stops), music_flashback, music_tragic, music_finale, music_ending_dawn (one-shot).
- `audio/sfx/` (26 story sounds): knock_tung_x3, tung_chant_rhythm, giallino_boot, giallino_blip_1..5, giallino_blip_broken_1..3, giallino_mood_drop, falsino_signature, negatino_signature, crudelino_signature, glitch_burst, jumpscare_stinger, clue_found, item_pickup, vote_tick, clock_time_stop, ending_dawn, dusk_piano_theme, ambience_night_loop, ambience_cave_loop, heartbeat_loop.
- `audio/world/` (58 Minecraft-STYLE world sounds): step_{grass,stone,wood,gravel,sand}_1..4; block_break_/block_place_{dirt,stone,wood,glass,leaves}; door_open, door_close, chest_open, lever_click, button_click, torch_ignite, water_splash, village_bell, explosion_boom, player_hurt, xp_orb_pickup; npc_hum_{neutral,question,no,happy}; cave_eerie_1..4; loops: amb_birds_loop, amb_crickets_loop, amb_wind_loop, amb_rain_loop, amb_water_stream_loop, amb_fireplace_loop, amb_lava_loop, amb_minecart_loop.

Systems:
1. Audio helper (`Audio.play(name, parent?)`, `Audio.loop`, `Audio.stop`, random variant picker for `_1.._4` sets) with SoundGroups Music / Ambience / SFX / Voice and volume sliders in Settings.
2. MusicDirector: one music state at a time with 2 s crossfades. States → tracks: lobby/main menu → music_lobby; daytime village (Ch1, Ch3) → music_day_village; dusk (CS-03) → dusk_piano_theme; night (Ch2, Ch4) → music_night; investigation & clue hunting → music_investigation; any CHASE → music_chase; Falsino/Negatino/Crudelino fights → music_boss; mineshaft → music_cave; finale → music_finale; ending Dawn/Sahur → music_ending_dawn. Cutscenes can override the state: CS-05 plays music_lullaby_box and switches to music_lullaby_stop at shot 6; CS-16 part B → music_flashback; CS-06, CS-09, CS-12, CS-14, CS-18, CS-21 → music_tragic; CS-E3 restarts music_lullaby_box at shot 5 then music_ending_dawn. Silence is also a state (CS-04 shot 4: everything muted).
3. AmbienceDirector by zone + time of day: day outdoors → amb_birds_loop + amb_wind_loop (quiet); night outdoors → amb_crickets_loop + ambience_night_loop + owl_hoot every 25–60 s; near the river (≤ 20 blocks) → amb_water_stream_loop (3D, on river parts); tavern → amb_fireplace_loop (3D at the fireplace); hills → amb_wind_loop louder; mineshaft → ambience_cave_loop + random cave_eerie_1..4 every 40–90 s; lava cave → amb_lava_loop; minecart rides → amb_minecart_loop; optional rain on the second night (Ch4) → amb_rain_loop.
4. Footsteps: every character (players and NPC actors) plays step_<material>_1..4 by the block under the feet (grass, dirt → grass set; stone/cobble/bricks → stone; planks/logs → wood; gravel/path → gravel; sand → sand), rate tied to walk speed.
5. World interaction sounds: chopping wood (Ch1) → block_break_wood; picking items → item_pickup or xp_orb_pickup; doors/chests/levers/buttons use their sounds; lighting braziers → torch_ignite; falling into water → water_splash; CS-03 bell → village_bell; Bombardiro bombs → explosion_boom; taking damage → player_hurt; Crudelino breaking blocks → block_break_stone/wood.
6. NPCs: before each NPC TTS line play one npc_hum (question for questions, no for refusals, happy for jokes, otherwise neutral); idle villagers hum randomly every 20–40 s in the daytime.
7. Giallino "talks" with random blips (giallino_blip_1..5) per typewriter letter; when mood < 40 switch to giallino_blip_broken_1..3. Each form plays its signature sound when it appears. heartbeat_loop fades in by distance to any active threat.

Character voices:
- Spoken lines come from `cutscenes.md` + `screenplay.md` (story dialogue), `lore.md` (Memory Page texts, read by Narrator) and `voice_lines.md` (voice settings, intro chants, lobby/daytime lines) — both in the project root. Convert them into `Shared/VoiceLines` data: { id, speaker, text, chapter, scene, soundId = nil }.
- VoiceService: if a line has a soundId, play that Sound; otherwise speak it with Roblox `AudioTextToSpeech` (Text ≤ 300 chars, per-character Pitch and Speed from voice_lines.md, VoiceId chosen from the Roblox text-to-speech voice list in the docs). Route through AudioEmitter on the speaker's model so voices are 3D, and AudioDeviceOutput for narrator. Respect the TTS rate limit: cache/queue requests, never spam, fall back to subtitles only if a request fails.
- Every line ALSO shows as a subtitle in the dialogue box. Intro chants play the first time each character appears.
- For [DisplayName] in lines, insert the player's DisplayName on the client of that player only.
</audio_and_voice>

<technical_requirements>
- Rojo project layout (two places: lobby.project.json + story.project.json; shared code in src/Shared used by both):
  - src/Lobby (MainMenu, LobbyWorldBuilder, QueueService, CartController, EmoteWheel, AuraLeaderboard)
  - src/ReplicatedStorage/Shared (Config, Strings, StoryData/Chapters, Cutscenes, Dialogues, Types)
  - src/ServerScriptService (ChapterManager, StoryFlags, Party, Threats, Inventory)
  - src/StarterPlayer/StarterPlayerScripts (CutsceneEngine, DialogueUI, JournalUI, GiallinoClient, Atmosphere)
  - src/ServerStorage/Models (placeholder character rigs, built by code)
  - src/Workspace build: MapBuilder module that generates the blocky world from a seeded height-map + hand-placed structure tables (village houses, inn, clock tower, forest, river, mineshaft).
- Server is authoritative: clients only send requests (vote, interact, pick up); every RemoteEvent is validated (distance, chapter state, rate limit).
- Story content (cutscenes, dialogue, clues) lives in data modules — no story text hard-coded inside systems.
- Performance: map ≤ 25k parts; use one-part-per-region merging where possible, anchored, CanCollide false for decoration, StreamingEnabled on.
- Keep within Roblox Community Standards: fear and jump scares are OK, no gore or blood. Target content maturity "Mild/Moderate fear".
- Strict typing (--!strict) in all modules. Format with StyLua and lint with Selene if available.
</technical_requirements>

<constraints>
- Use only original assets and code. Do NOT insert free models, Toolbox scripts, Mojang/Minecraft textures, or anything from ThatMob's Verity videos.
- Only build what is described here. The ONLY monetization is the 45 Robux Revive developer product. No game passes, extra modes, or features I did not ask for.
- Audio: use only the files in assets/audio (placeholders until I paste IDs). Never use Minecraft/Mojang sounds or music.
- Stop and ask me before: adding any package/dependency (Wally etc.), using HttpService, writing DataStore code, or deleting any file.
</constraints>

<phases>
Work in phases. After EACH phase: stop, report, and wait for me to write "continue".
- Phase 0: Rojo scaffold (lobby + story projects), folder structure, Config/Strings/Types/UITheme, README with how to sync, publish both places in one universe, and test.
- Phase 1a: Cutscene & animation stack — CutsceneEngine (all camera/transition/grade features), PoseAnimator, FaceController, special effects, VoiceService (TTS + subtitles), Audio + MusicDirector + AmbienceDirector + Footsteps. Prove it by fully implementing CS-02 and CS-05 (with A-BALLERINA_DANCE, A-BALLERINA_SLOW_STOP, A-KNEEL_SOFT, A-REACH_OUT, A-PIXEL_DISSOLVE) on a test baseplate with placeholder rigs. STOP here so I can review how the cutscenes look before you build anything else.
- Phase 1b: Gameplay systems — StoryFlags, ChapterManager, DialogueSystem with votes, Journal (with Memories and Names tabs), Inventory, HealthAndDeath + Revive product, QTE, ParkourKit, BossFramework, Achievements, plus one test parkour segment.
- Phase 2: MapBuilder — the full world exactly as in map.md (all 27 surface zones + 8 underground zones, coordinates in blocks), greedy meshing with textures tiled per block, Minecraft-style houses/trees/fields/clouds, every camera anchor, Memory Page spots M1–M12, placeholder brainrot rigs, day/night + atmosphere, ambience zones. Send me a short list of screenshot spots (`/tp` debug command in Studio) so I can check the village looks like a Minecraft village.
- Phase 3: Prologue + Chapters 1–2 fully playable exactly as in screenplay.md, with CS-00 … CS-06 complete.
- Phase 4: Chapters 3–4 with CS-07 … CS-14 complete (investigation, rooftop parkour, Falsino truth-or-lie fight, accusation vote, Negatino boss, chase + forest parkour).
- Phase 5: Chapters 5–6 with CS-15 … CS-23, all endings CS-E1/E2/E3 and service cutscenes complete (minecart QTE chase, gear puzzles, lava parkour, Crudelino boss, Giallino Totale 4-phase boss), three endings, all achievements.
- Phase 5.5: Main menu, lobby station world, minecart queue, loading screen, teleport + seamless Chapter 1 start, meme content (aura, emotes, cameos).
- Phase 6: Polish pass — cutscene timing, sound hooks, UI consistency, bug fixes from my playtest notes.
</phases>

<reporting>
At the end of every phase output:
✅ Done: list of systems/features finished
📁 Files: created/changed file paths
🎬 Cutscene checklist: every CS-xx and A-xx in this phase with ✅ done / ❌ missing — nothing in this phase may stay ❌
🧪 How to test in Studio: numbered steps + what I should see (including `/cs` commands to replay each cutscene)
⚠️ Known issues / placeholders I must fill (SoundIds, BadgeIds, meshes)
Only claim something works if you checked it (lint, type check, or a test you ran). If you could not test something, say so.
</reporting>

<done_when>
- Lobby place: Play shows the main menu → lobby → minecart queue → loading screen → teleport into the Story place, where Chapter 1 starts in the same minecart.
- Story place with Config.SkipLobby = true: pressing Play starts Chapter 1 directly.
- Main menu and lobby UI look correct at 360×640 and 1920×1080.
- All 6 chapters are playable start to finish solo and with 2+ players (Studio "Start Server" with 2 clients).
- Going Down, teammate revive, Dead → Spectate → checkpoint respawn, and full-party wipe → checkpoint restart all work. The Revive purchase is testable in Studio (test purchases are free there) and never grants twice for one receipt.
- Every boss can be won and lost; every achievement can be earned.
- Every cutscene in cutscenes.md plays fully (check each with `/cs`), every animation in the library exists, all 12 Memory Pages are placed.
- Story flags change the ending; all 3 endings are reachable.
- No errors in the Output window during a full playthrough.
</done_when>

Start with Phase 0 now.
