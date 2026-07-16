# AXEL — Scene Dialogues: Arc 4 — Teachers' Lounge

---

### 4.1 Teachers' Lounge (`loc_teachers`)

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

### 4.2 Teachers' Lounge Memory (`loc_teachers_memory`)

**Location label:** `TEACHERS' LOUNGE`
*(Plays as embedded click step within Teachers' Lounge — glitch flash 250ms before text swaps)*

**Dialogue [SOURCE]:**

> The cop asked, 'When did you last see him?' You answered: 'That day at lunch. I thought they went home.' You lied. You knew exactly where THEY were.

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

### 4.3 Key Wall (`loc_key_wall`)

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
| Turn back    | —          | Teachers' Lounge |


---

### 4.4 Teachers' Lounge — Key Pickup (`action_get_key`)

**Location label:** `TEACHERS' LOUNGE`

**Dialogue [SOURCE]:**

> You take the key. A bit of tape reads: 'BASEMENT'.

**[REWRITE]:**

> You take the key.
>
> [beat]
>
> Like a good little boy.

**Choices:**


| Button label | Target           |
| ------------ | ---------------- |
| Nice         | Teachers' Lounge |


---
