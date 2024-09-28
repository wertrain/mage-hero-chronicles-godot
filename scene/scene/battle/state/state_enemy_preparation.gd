class_name EnemyPreparation
extends State

enum IconType {
	
}

func enter():
	var root: BattleScene = get_tree().current_scene
	var enemies = root.get_enemies()
	for e in enemies:
		var enemy = e as BattleEnemy
		var data: EnemyData = enemy.get_data()
		for a in data.actions:
			pass
	
