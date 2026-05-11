# AXEL — Scene Dialogues

> **How to use this file**
> Every line marked **[SOURCE]** is the exact original text extracted directly from `game.html`.
> Lines marked **[REWRITE]** are your cue to replace that text with your own version.
> Leave a line blank under **[REWRITE]** until you’re ready to fill it in.
> Once you’re happy with a scene, remove the tag entirely — that means it’s locked.

---

## Arc 1 — Intro

---

### 1.1 School Exterior (`start`)

**Location label:** *(empty)*

**Dialogue [SOURCE]:**

> You stand before the rotting wooden school building. The sky is grey. You feel a jolt in your chest, your GUILT lies here. You’ve come to finish what was left undone years ago.

**[REWRITE]:**

> You promised, you'd never come back.  
> [beat]  
> Yet, here we are.  
> [beat]  
> Pathetic.

**Choices:**


| Button label | Target   |
| ------------ | -------- |
| Walk inside  | Corridor |
| Turn away    | Ending 1 |


---

### 1.2 Corridor (`scene_2`)

**Location label:** `CORRIDOR`

**Dialogue [SOURCE]:**

> You step inside. The smell hits you—a mix of mold and old floor cleaner. The past is leaking into the present. You remember that your locker is at the end of the hallway.

**[REWRITE]:**

> Even after all these years the smell is the same. They must've used some really toxic paint.  
> [beat]  
> This was your locker.

**Choices:**


| Button label      | Target     |
| ----------------- | ---------- |
| Go to your locker | Locker Hub |
| Turn away         | Ending 1   |


---

## Arc 2 — Hub

---

### 2.1 Locker Hub (`scene_3`)

**Location label:** `YOUR LOCKER`

**Dialogue [SOURCE]:**

> You are in your sanctuary. There’s a picture of the two of you on the locker door. The map shows four circled locations. The basement entrance has been blacked out.

**[REWRITE]:**

> Oh look, a map of the school.  
> [beat]  
> Was your memory so bad you needed a map of the school?

**Choices:**


| Button label                       | Target                           |
| ---------------------------------- | -------------------------------- |
| Go to the cafeteria                | Cafeteria                        |
| Go to the classroom                | Classroom                        |
| Go to the backyard                 | Backyard                         |
| Go to the teacher’s lounge         | Teachers’ Lounge                 |
| ENTER THE BASEMENT *(red, locked)* | Basement Blocked / Basement Door |


---

### 2.2 Basement Blocked — temporary gate (`basement_blocked_temp`)

**Location label:** `BASEMENT`

**Dialogue [SOURCE]:**

> The basement is sealed off for now. Come back later.

**[REWRITE]:**

> Not yet.

**Choices:**


| Button label | Target     |
| ------------ | ---------- |
| Go back      | Locker Hub |


---

## Arc 3 — Cafeteria

---

### 3.1 Cafeteria (`loc_cafeteria`)

**Location label:** `CAFETERIA`

**Dialogue [SOURCE]:**

> Tables are overturned. The air reeks of rancid grease. In the middle of the hall you see a ghostly figure sitting alone at an intact table. The kitchen area is dark.

**[REWRITE]:**

> Even through all the chaos you can hear the chattering students of the past.

**Choices:**


| Button label        | Target           |
| ------------------- | ---------------- |
| Approach Your table | Cafeteria Memory |
| Search the kitchen  | Kitchen          |
| Return to locker    | Locker Hub       |


---

### 3.2 Cafeteria Memory (`loc_cafeteria_memory`)

**Location label:** `CAFETERIA`
*(Memory — glitch flash on enter, no interaction area)*

**Dialogue [SOURCE]:**

> You are sitting at the same table. The popular kids invite you over. Your friend whispers, ‘Don’t go.’ You stand up, laugh and shout loud: ‘Sorry, I can’t deal with your whining.’ You leave them alone.

**[REWRITE]:**

> "Do you think I'm a bad person?"
>
> [beat]
>
> You answer, "No."
>
> [beat]
>
> "I just - don't have the energy. To be around you."
>
> [beat]
>
> "Sorry."
>
> "Oh."
>
> [beat]
>
> "No. I understand."

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Go back      | Cafeteria |


---

### 3.3 Kitchen (`loc_kitchen`)

**Location label:** `KITCHEN`

**Dialogue [SOURCE]:**

> The kitchen is rotting at the seams. You see the rot pile up in the air. The smell is horrendus.

**[REWRITE]:**

> Everything is rotten here. Everything.
>
> [beat]
>
> This includes you.

**Choices:**


| Button label                                                                            | Target                    |
| --------------------------------------------------------------------------------------- | ------------------------- |
| Turn back                                                                               | Cafeteria                 |
| *(Hidden — click on scene image triggers flashlight pickup before flashlight is found)* | Kitchen Flashlight Pickup |


---

### 3.4 Kitchen — Flashlight Pickup (`action_get_flashlight`)

**Location label:** `KITCHEN`

**Dialogue [SOURCE]:**

> Your hand hits cold metal. You found an industrial flashlight!

**[REWRITE]:**

> Let there be light!

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Nice         | Cafeteria |


---

## Arc 4 — Backyard

---

### 4.1 Backyard — default state (`loc_yard`)

**Location label:** `BACKYARD`

**Dialogue [SOURCE]:**

> The corner at the back of the school. The wall has a weird graffiti on it. You still smell the teen rebelry around.

**[REWRITE]:**

> The spirit of rebellion is still present here. Nice graffiti.
>
> [beat]
>
> You could never be this talented.

**Choices:**


| Button label      | Target        |
| ----------------- | ------------- |
| Smoke a cigarette | Backyard Hint |
| Return to locker  | Locker Hub    |


> **Note:** On first visit (before yard memory plays), clicking anywhere on the scene advances the click sequence below instead of triggering the buttons normally.

---

### 4.1b Backyard — Click step 1: Memory flash (`loc_yard_memory` text)

**Location label:** `BACKYARD`
*(Glitch flash 250ms, then this text replaces scene text — sourced from `story.loc_yard_memory.text`)*

**Dialogue [SOURCE]:**

> Your friend looks gaunt. ‘Just to make sure you don’t steal my lighter again I’m going to write my name on it.’

**[REWRITE]:**

> "Oh. Sorry. I'll go," they say.
>
> "No. I don't mind."
>
> "Haven't seen you in school for awhile."
>
> "Didn't think you'd notice.
>
> "What does that mean?"
>
> "Nothing."
>
> [beat]
>
> "Are we still friends?"

---

### 4.1c Backyard — Click step 2: Name reveal (inline JS `yardRevealText`)

**Location label:** `BACKYARD`
*(No glitch — text swaps directly. This line lives in `loadScene()` JS, not in the `story` object)*

**Dialogue [SOURCE]:**

> YOU look down. There it is. A lighter with the name “AXEL” written on it.

**[REWRITE]:**

> You light up your cigarette.
>
> Tastes of tar and regret.
>
> Yum.

---

### 4.1d Backyard — Named scene (`loc_yard_memory`)

**Location label:** `BACKYARD`
*(This is the actual `story.loc_yard_memory` scene object — same text as 4.1b, but reached via the “Remember the name” button after the sequence)*

**Dialogue [SOURCE]:**

> Your friend looks gaunt. ‘Just to make sure you don’t steal my lighter again I’m going to write my name on it.

**[REWRITE]:**

> x

**Choices:**


| Button label      | Target     |
| ----------------- | ---------- |
| Remember the name | Locker Hub |


---

### 4.2 Backyard Hint / Intermission (`loc_yard_hint`)

**Location label:** `INTERMISSION`

**Dialogue [DYNAMIC — chosen at runtime from `getSmokingHintText()`]:**


| Condition          | Line [SOURCE]                                                         |
| ------------------ | --------------------------------------------------------------------- |
| No flashlight      | The basement is bound to be dark. I need something to light the way   |
| No name            | I remember their face. But their name escapes me                      |
| No key             | The basement is bound to be locked. I better look around for the key. |
| Memories < 5       | I should look around more. There’s something I’m forgetting.          |
| All conditions met | I’m ready.                                                            |


**[REWRITE any hint lines you want to change:]**

**Choices:**


| Button label | Target   |
| ------------ | -------- |
| Continue     | Backyard |


---

## Arc 5 — Teachers’ Lounge

---

### 5.1 Teachers’ Lounge (`loc_teachers`)

**Location label:** `TEACHERS' LOUNGE`

**Dialogue [SOURCE]:**

> The air is stale. You always wondered what the teachers were doing behind closed doors.

**[REWRITE]:**

> You always wondered what the teachers were doing behind closed doors.
>
> [beat]
>
> Pervert.

**Choices:**


| Button label                                                             | Target                         |
| ------------------------------------------------------------------------ | ------------------------------ |
| Return to locker                                                         | Locker Hub                     |
| *(Hidden — click on scene advances memory sequence before key is found)* | → Teachers Memory → Key Pickup |


---

### 5.2 Teachers’ Lounge Memory (`loc_teachers_memory`)

**Location label:** `TEACHERS' LOUNGE`
*(Plays as embedded click step within Teachers’ Lounge — glitch flash 250ms before text swaps)*

**Dialogue [SOURCE]:**

> The cop asked, ‘When did you last see him?’ You answered: ‘That day at lunch. I thought they went home.’ You lied. You knew exactly where THEY were.

**[REWRITE]:**

> "So, when did you see him last?" the police officer asked.
>
> "That day during lunch. I mean I guess he was in the same classes as me."
>
> "You guess?"
>
> "He's so - silent. I barely notice him anymore."
>
> [beat]
>
> Liar. You knew exactly where he was.

---

### 5.3 Key Wall (`loc_key_wall`)

**Location label:** `TEACHERS' LOUNGE`
*(Currently unreachable via normal navigation — reserved for future use)*

**Dialogue [SOURCE]:**

> Most hooks are empty. One rusty key still hangs.

**[REWRITE]:**

> There's a key.
>
> Why hasn't anyone nicked it yet?

**Choices:**


| Button label | Condition  | Target           |
| ------------ | ---------- | ---------------- |
| Take the key | No key yet | Key Pickup       |
| Turn back    | —          | Teachers’ Lounge |


---

### 5.4 Teachers’ Lounge — Key Pickup (`action_get_key`)

**Location label:** `TEACHERS' LOUNGE`

**Dialogue [SOURCE]:**

> You take the key. A bit of tape reads: ‘BASEMENT’.

**[REWRITE]:**

> You take the key.
>
> [beat]
>
> Like a good little boy.

**Choices:**


| Button label | Target           |
| ------------ | ---------------- |
| Nice         | Teachers’ Lounge |


---

## Arc 6 — Classroom

---

### 6.1 Classroom (`loc_classroom`)

**Location label:** `CLASSROOM`

**Dialogue [SOURCE]:**

> Dust dances in the beams of light. In the back row one desk sits apart from the others. A chalkboard stands at the front.

**[REWRITE]:**

> This is where the shit went down.
>
> If shit going down is you, highly caffinated, ignoring your teachers and usually skipping class to go for a smoke.
>
> How did you ever get anywhere in life?

**Choices:**


| Button label      | Target          |
| ----------------- | --------------- |
| Inspect the desk  | Classroom Desk  |
| Look at the board | Classroom Board |
| Return to locker  | Locker Hub      |


---

### 6.2 Classroom — Desk (`loc_desk`)

**Location label:** `CLASSROOM`

**Animation sequence (plays once on first visit):**


| Timestamp    | Background image              | Story text                      |
| ------------ | ----------------------------- | ------------------------------- |
| t = 0 ms     | `desk_empty.jpg`              | *(blank)*                       |
| t = 650 ms   | `desk_hand.png` + shake + dim | *(blank)*                       |
| t = 1 000 ms | `desk.png`                    | *(blank)*                       |
| t = 1 300 ms | `desk.png`                    | Final dialogue revealed (below) |


**Final dialogue [SOURCE]:**

> This is THEIR desk. You remember. It was a dare.

**[REWRITE]:**

> It's THEIR desk.
>
> You said it was a dare.
>
> [beat]
>
> I'd spit on you if I could.

**Choices:**


| Button label  | Target    |
| ------------- | --------- |
| Close the lid | Classroom |


---

### 6.3 Classroom — Board (`loc_board`)

**Location label:** `CLASSROOM`

**Dialogue [SOURCE]:**

> On the board is code: ‘if (name == ____) { remember(); }’. Do you know the name?

**[REWRITE]:**

> On the board there are weird ass symbols and equations.
>
> You can only make out one question:
>
> "[something relevant that is only learned through playing the slots]"

**Input:** Text field — correct answer: `AXEL` (case-insensitive, trimmed)

**Fail text [SOURCE]:**

> The board doesn’t respond.

**[REWRITE fail text]:**

> Nah.

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Turn back    | Classroom |


---

### 6.4 Classroom — Board Success (`loc_board_success`)

**Location label:** `CLASSROOM`

**Dialogue [SOURCE]:**

> At least YOU remember that much.

**[REWRITE]:**

> x

**Choices:**


| Button label  | Target     |
| ------------- | ---------- |
| Take the name | Locker Hub |


---

## Arc 7 — Basement

---

### 7.1 Basement Door (`basement_entry`)

**Location label:** `BASEMENT DOOR`

**Dialogue [SOURCE]:**

> A heavy metal door. The sign reads ‘ENTRY FORBIDDEN’.

**[REWRITE]:**

> x

**Choices:**


| Button label            | Condition | Target          |
| ----------------------- | --------- | --------------- |
| Unlock with key         | Has key   | Basement Stairs |
| Try the handle (Locked) | No key    | Basement Locked |
| Go back                 | —         | Locker Hub      |


---

### 7.2 Basement Locked (`basement_locked`)

**Location label:** `LOCKED`

**Dialogue [SOURCE]:**

> The door won’t budge. You need a key.

**[REWRITE]:**

> You need a key, dumbass.

**Choices:**


| Button label | Target     |
| ------------ | ---------- |
| Go back      | Locker Hub |


---

### 7.3 Basement Stairs (`basement_stairs`)

**Location label:** `STAIRCASE`

**Dialogue [SOURCE]:**

> The door opens. Before you lie pitch-black stairs. The smell is nauseating. Are you ready to step into the darkness?

**[REWRITE]:**

> The door opens to a terrible screetch.
>
> In front of you stairs descending into pitch-blackness.
>
> Are you ready?

**Choices:**


| Button label  | Condition      | Target        |
| ------------- | -------------- | ------------- |
| Go down       | Has flashlight | Basement Main |
| Go down       | No flashlight  | Ending 2      |
| I’m not ready | —              | Locker Hub    |


---

### 7.4 Basement Main (`basement_main`)

**Location label:** `MAIN CHAMBER`

**Dialogue [SOURCE]:**

> The beam hits soft soil. In the corner something metallic glints. There is no going back.

**[REWRITE]:**

> x

**Choices:**


| Button label          | Condition     | Target           |
| --------------------- | ------------- | ---------------- |
| Pick up the shovel    | No shovel yet | Shovel Pickup    |
| Dig (Requires shovel) | Has shovel    | Basement Digging |
| Turn back             | —             | Basement Stuck   |


---

### 7.5 Shovel Pickup (`action_get_shovel`)

**Location label:** `FOUND`

**Dialogue [SOURCE]:**

> You found a rusty shovel.

**[REWRITE]:**

> The same old shovel still here.

**Choices:**


| Button label | Target        |
| ------------ | ------------- |
| Continue     | Basement Main |


---

### 7.6 Basement Stuck (`basement_stuck`)

**Location label:** `NO RETURN`

**Dialogue [SOURCE]:**

> The door is locked behind you. You must face this.

**[REWRITE]:**

> I'm not letting you.

**Choices:**


| Button label | Target        |
| ------------ | ------------- |
| Back         | Basement Main |


---

### 7.7 Basement Digging (`basement_digging`)

**Location label:** `DIGGING`

**Dialogue [SOURCE]:**

> You strike the shovel into the ground. Thud. Fabric… bone. The final memory surfaces.

**[REWRITE]:**

> As you keep digging.
>
> A memory surfaces.

**Choices:**


| Button label   | Target          |
| -------------- | --------------- |
| FACE THE TRUTH | Basement Corpse |


---

### 7.8 Basement Corpse — Puzzle (`basement_question`)

**Location label:** `CORPSE`

**Dialogue [SOURCE]:**

> Before you is a mummified body. Its jaw drops open. A voice echoes in your head: ‘WHO AM I?’

**[REWRITE]:**

> [instead of the name, the game just runs a check if the puzzle was completed in the classroom]

**Input:** Text field — correct answer: `AXEL` (case-insensitive)

**On correct + has Name flag:** → Ending True
**On correct + no Name flag:** → Ending 4
**On wrong answer:** → Ending 3 (auto-routed after 2 seconds, no fail text in source)

---

## Arc 8 — Endings

---

### 8.1 Ending 1 — Fear (`ending_1`)

**Location label:** `ENDING #1`

**Dialogue [SOURCE]:**

> Fear wins over curiosity. You walk away. In the nights that follow you have nightmares, but you never learn the truth.

**[REWRITE]:**

> Coward
>
> Coward
>
> Coward
>
> Coward
>
> ...

**Choices:**


| Button label | Target                       |
| ------------ | ---------------------------- |
| Start again  | School Exterior (full reset) |


---

### 8.2 Ending 2 — Darkness (`ending_2`)

**Location label:** `ENDING #2`

**Dialogue [SOURCE]:**

> You step into darkness without light. Your foot slips. You tumble down the stairs and your neck breaks. The shadows consume you.

**[REWRITE]:**

> The shadows consume you.
>
> You lose your footing.
>
> Is this how it ends?
>
> Really?
>
> I mean...
>
> Your fault for thinking you could see where you're stepping in pitch-black.
>
> If only you had a FLASHLIGHT.
>
> You know the tool that lights up dark places.
>
> Maybe it's in the kitchen. I don't know.
>
> Your dumb.

**Choices:**


| Button label | Target                       |
| ------------ | ---------------------------- |
| Start again  | School Exterior (full reset) |


---

### 8.3 Ending 3 — Wrong Answer (`ending_3`)

**Location label:** `ENDING #3`

**Dialogue [SOURCE]:**

> You answer wrong. ‘You still don’t care!’ the voice screams. The basement walls glow red. Fire engulfs you. You are in hell.

**[REWRITE]:**

> His eyes won't return yours.
>
> It's not complete.

**Choices:**


| Button label | Target                       |
| ------------ | ---------------------------- |
| Start again  | School Exterior (full reset) |


---

### 8.4 Ending 4 — No Name (`ending_4`)

**Location label:** `ENDING #4`

**Dialogue [SOURCE]:**

> You whisper ‘Axel’. The body goes silent. But then the police burst in. You have no evidence (Name missing) that it was suicide. You are convicted of murder.

**[REWRITE]:**

> [instead of the name, the game just runs a check if the puzzle was completed in the classroom]
>
> You hear sirens.
>
> Then see the red and blue lights.
>
> What comes around, goes around.

**Choices:**


| Button label | Target                       |
| ------------ | ---------------------------- |
| Start again  | School Exterior (full reset) |


---

### 8.5 True Ending (`ending_true`)

**Location label:** `TRUE ENDING`

**Dialogue [SOURCE]:**

> You whisper ‘Axel’ and give the name. A spirit leaves the body. He looks at peace. ‘This can’t hurt me anymore,’ he laughs. You are forgiven.

**[REWRITE]:**

> Maybe it wasn't ALL your fault.
>
> Maybe I was too harsh.
>
> Okay.
>
> I'll say it.
>
> Ugh.
>
> I'm sorry.
>
> [a spirit leaves the body]

**Choices:**


| Button label       | Target   |
| ------------------ | -------- |
| Go to the backyard | Epilogue |


---

### 8.6 Epilogue (`epilogue`)

**Location label:** `EPILOGUE`

**Dialogue [SOURCE]:**

> You sit together in the backyard. You and a ghost. You smoke in silence. Smoke rises toward the sky. You are free.

**[REWRITE]:**

> [player smokes in the end screen with the spirit in the backyard]
>
> "I should quit."
>
> "Yeah, don't want to end like me before your time"
>
> It was a really bad joke, but you still laugh.
>
> Just like old times.

**Choices:**


| Button label | Target                       |
| ------------ | ---------------------------- |
| Exit         | School Exterior (full reset) |


---

## What was missing from the first version of this file


| Scene               | What was missing                                                                                                                                                 |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loc_key_wall`      | Entire scene omitted — *“Most hooks are empty. One rusty key still hangs.”*                                                                                      |
| Backyard step 2     | Yard reveal text was buried in inline JS `loadScene()`, not in the `story` object: *“YOU look down. There it is. A lighter with the name ‘AXEL’ written on it.”* |
| `loc_yard_memory`   | Listed only as a click step but the named scene (reached via “Remember the name”) was not separated out                                                          |
| `basement_question` | No fail text is defined in source — player routes to Ending 3 silently after 2s (was implied but not noted)                                                      |


