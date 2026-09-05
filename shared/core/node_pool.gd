class_name NodePool
extends Node

## Centralized node pooling service for high-frequency objects
## like projectiles, particle emitters, and damage labels to minimize GC hitches.

var _pools: Dictionary = {}
var _factories: Dictionary = {}
var _max_sizes: Dictionary = {}

func register_pool(pool_name: String, factory_callable: Callable, initial_size: int = 8, max_size: int = 64) -> void:
	if not _pools.has(pool_name):
		_pools[pool_name] = []
		_factories[pool_name] = factory_callable
		_max_sizes[pool_name] = max_size

		for _i in range(initial_size):
			var node = factory_callable.call()
			if node is Node:
				node.visible = false
				node.set_process(false)
				node.set_physics_process(false)
				_pools[pool_name].append(node)

func acquire(pool_name: String) -> Node:
	if not _pools.has(pool_name):
		return null

	var pool: Array = _pools[pool_name]
	if pool.size() > 0:
		var node: Node = pool.pop_back()
		node.visible = true
		node.set_process(true)
		node.set_physics_process(true)
		return node

	# Pool exhausted: create new if below max size
	if _factories.has(pool_name):
		var factory: Callable = _factories[pool_name]
		var new_node: Node = factory.call()
		return new_node

	return null

func release(pool_name: String, node: Node) -> void:
	if not is_instance_valid(node):
		return

	if not _pools.has(pool_name):
		node.queue_free()
		return

	var pool: Array = _pools[pool_name]
	var max_sz: int = _max_sizes.get(pool_name, 64)

	if pool.size() < max_sz:
		if node.get_parent():
			node.get_parent().remove_child(node)
		node.visible = false
		node.set_process(false)
		node.set_physics_process(false)
		pool.append(node)
	else:
		node.queue_free()

func get_pool_size(pool_name: String) -> int:
	if _pools.has(pool_name):
		return _pools[pool_name].size()
	return 0

func clear_pool(pool_name: String) -> void:
	if _pools.has(pool_name):
		for node in _pools[pool_name]:
			if is_instance_valid(node):
				node.queue_free()
		_pools[pool_name].clear()

func clear_all() -> void:
	for pool_name in _pools.keys():
		clear_pool(pool_name)
	_pools.clear()
	_factories.clear()
	_max_sizes.clear()
