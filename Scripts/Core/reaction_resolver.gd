extends Node

class_name ReactionResolver

static func resolve(obj_a: Node, obj_b: Node) -> void:
	if not obj_a or not obj_b:
		return

	# Pega os atributos de ambos
	var elem_a = obj_a.element if obj_a.has_meta("element") else obj_a.get("element")
	var tag_a = obj_a.tag if obj_a.has_meta("tag") else obj_a.get("tag")
	var elem_b = obj_b.element if obj_b.has_meta("element") else obj_b.get("element")
	var tag_b = obj_b.tag if obj_b.has_meta("tag") else obj_b.get("tag")

	var rule = ReactionDatabase.find_rule(elem_a, tag_a, elem_b, tag_b)
	if not rule:
		return

	# Executa a reação baseada no outcome
	match rule.outcome:
		ReactionRuleResource.Outcome.SPAWN_AND_SPAWN:
			_spawn_and_spawn(obj_a, obj_b, rule)

		ReactionRuleResource.Outcome.INFUSE:
			_infuse(obj_a, obj_b, rule)

		ReactionRuleResource.Outcome.DELAYED_TRIGGER:
			_delayed_trigger(obj_a, obj_b, rule)

		ReactionRuleResource.Outcome.MUTATE_DECAL:
			_mutate_decal(obj_a, obj_b, rule)


static func _spawn_and_spawn(obj_a: Node, obj_b: Node, rule: ReactionRuleResource) -> void:
	if not rule.result_scene:
		return

	var world = obj_a.get_tree().get_root().get_child(0)
	var effect = rule.result_scene.instantiate()
	effect.global_position = (obj_a.global_position + obj_b.global_position) / 2.0
	world.add_child(effect)

	obj_a.queue_free()
	obj_b.queue_free()


static func _infuse(obj_a: Node, obj_b: Node, rule: ReactionRuleResource) -> void:
	# A absorve B, muda de estado
	if obj_a.has_method("set_infused_with"):
		obj_a.set_infused_with(obj_b.element)

	if rule.result_scene:
		var effect = rule.result_scene.instantiate()
		effect.global_position = obj_a.global_position
		obj_a.add_child(effect)

	obj_b.queue_free()


static func _delayed_trigger(obj_a: Node, obj_b: Node, rule: ReactionRuleResource) -> void:
	# Para o dano periódico de obj_a (se for decal)
	if obj_a.has_method("stop_periodic_damage"):
		obj_a.stop_periodic_damage()

	# Cria timer de espera
	var timer = Timer.new()
	obj_a.add_child(timer)
	timer.wait_time = rule.delay
	timer.one_shot = true

	timer.timeout.connect(func():
		if rule.result_scene:
			var effect = rule.result_scene.instantiate()
			effect.global_position = obj_a.global_position
			obj_a.get_parent().add_child(effect)

		obj_a.queue_free()
	)

	timer.start()
	obj_b.queue_free()


static func _mutate_decal(obj_a: Node, obj_b: Node, rule: ReactionRuleResource) -> void:
	# Muda shader do decal para versão "prestes a explodir"
	if obj_a.has_method("set_infused_with"):
		obj_a.set_infused_with(obj_b.element)

	if rule.result_scene:
		# O result_scene pode ser um material ou efeito visual
		pass

	obj_b.queue_free()
