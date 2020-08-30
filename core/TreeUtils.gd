static func change_parent_preserve_global_position(child: Node2D, new_parent: Node):
    var old_glob = child.global_position
    child.get_parent().remove_child(child)
    new_parent.add_child(child)
    child.global_position = old_glob