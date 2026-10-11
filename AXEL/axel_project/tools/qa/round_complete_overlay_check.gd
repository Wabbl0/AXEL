extends SceneTree

const WANT_W := 1920.0
const WANT_H := 1280.0
const SCRIM_A := 0.72
const SIZE_SLACK := 2.0


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	await process_frame
	var failures: Array[String] = []
	var fx := root.get_node_or_null("AxelEventFx")
	if fx == null or not fx.has_method("show_round_complete_card"):
		push_error("round_complete_overlay_check: AxelEventFx.show_round_complete_card missing")
		quit(1)
		return
	fx.call("show_round_complete_card", 12, 340)
	await process_frame
	await process_frame
	var scrim: ColorRect = fx.call("get_round_complete_scrim")
	var label := fx.call("get_round_complete_label") as Control
	if scrim == null:
		failures.append("RoundScrim missing after show_round_complete_card")
	else:
		var rect := scrim.get_global_rect()
		if rect.size.x < WANT_W - SIZE_SLACK or rect.size.y < WANT_H - SIZE_SLACK:
			failures.append(
				"scrim size %s is not full window (want %.0fx%.0f)" % [rect.size, WANT_W, WANT_H]
			)
		if absf(scrim.color.a - SCRIM_A) > 0.02:
			failures.append("scrim alpha %.3f should be %.2f" % [scrim.color.a, SCRIM_A])
		if not scrim.visible:
			failures.append("scrim should be visible before any click")
	if label == null:
		failures.append("RoundCompleteLabel missing after show_round_complete_card")
	else:
		if not label.visible:
			failures.append("Round Complete! should show before any click")
		if absf(label.modulate.a - 1.0) > 0.02:
			failures.append("label alpha %.3f should be 1" % label.modulate.a)
		var shown := ""
		if label is RichTextLabel:
			shown = (label as RichTextLabel).get_parsed_text()
		elif label is Label:
			shown = (label as Label).text
		if shown.findn("Round Complete") < 0:
			failures.append("label text '%s' is not Round Complete!" % shown)
		var lab_rect := label.get_global_rect()
		if lab_rect.size.x < WANT_W - SIZE_SLACK or lab_rect.size.y < WANT_H - SIZE_SLACK:
			failures.append(
				"label size %s is not full window (want %.0fx%.0f)" % [lab_rect.size, WANT_W, WANT_H]
			)
	var bets_ok := false
	var balance_ok := false
	var root_ctrl := label.get_parent() if label != null else null
	if root_ctrl != null:
		for child in root_ctrl.get_children():
			var text := ""
			if child is Label:
				text = (child as Label).text
			elif child is RichTextLabel:
				text = (child as RichTextLabel).get_parsed_text()
			if text.findn("Bets used: 12") >= 0:
				bets_ok = true
			if text.findn("Current balance: 340") >= 0:
				balance_ok = true
	if not bets_ok:
		failures.append("missing label text 'Bets used: 12'")
	if not balance_ok:
		failures.append("missing label text 'Current balance: 340'")
	if label != null:
		var title_size := label.get_theme_font_size("normal_font_size")
		if title_size < 96:
			failures.append("title font size %d should be at least 96" % title_size)
	var jackpot: Node = null
	if root_ctrl != null:
		jackpot = root_ctrl.get_node_or_null("RoundJackpotFx")
	if jackpot == null:
		failures.append("RoundJackpotFx missing after show_round_complete_card")
	if not fx.has_method("is_round_intro_playing") or not fx.has_method("skip_round_intro"):
		failures.append("AxelEventFx needs is_round_intro_playing and skip_round_intro")
	else:
		fx.call("skip_round_intro")
		if bool(fx.call("is_round_intro_playing")):
			failures.append("intro still playing after skip_round_intro")
		if label != null and (absf(label.scale.x - 1.0) > 0.01 or absf(label.modulate.a - 1.0) > 0.02):
			failures.append("title not at rest after skip (scale %s, alpha %.2f)" % [label.scale, label.modulate.a])
	await fx.call("finish_round_complete_fade")
	await process_frame
	if jackpot != null and is_instance_valid(jackpot) and jackpot.is_inside_tree():
		failures.append("RoundJackpotFx still alive after finish_round_complete_fade")
	if failures.is_empty():
		print("Round complete overlay check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("round_complete_overlay_check: %s" % f)
		quit(1)
