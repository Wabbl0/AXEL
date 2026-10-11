extends RichTextEffect

const RED := Color(0.86, 0.08, 0.08, 1.0)
const WHITE := Color(1.0, 1.0, 1.0, 1.0)
const CHASE_SEC := 0.12
const BOB_SPEED := 7.0
const BOB_PHASE := 0.55

var bbcode := "jackpot"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var amp := float(char_fx.env.get("amp", 6.0))
	var chase := int(char_fx.env.get("chase", 1)) != 0
	var index := char_fx.relative_index
	var t := char_fx.elapsed_time
	char_fx.offset.y += sin(t * BOB_SPEED + float(index) * BOB_PHASE) * amp
	var step := int(floor(t / CHASE_SEC)) if chase else 0
	var tint := WHITE if (index + step) % 2 == 0 else RED
	char_fx.color = Color(tint.r, tint.g, tint.b, char_fx.color.a)
	return true
