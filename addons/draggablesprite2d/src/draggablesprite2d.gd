@tool
class_name DraggableSprite2D extends Area2D


## Emitted when the sprite is grabbed
signal grabbed
## Emitted when the sprite is released
signal released


## Sprite texture
## This is a bit crap, since it can't be resized as nicely as a normal sprite2d
@export var texture : Texture2D : 
	set(x):
		texture = x
		sprite.texture = texture
		## Update the default_collider with the shape and size of the sprite, if it exists
		update_default_collider()
## Whether or not the sprite should return to it's starting position when released
@export var return_to_origin := false
## Whether or not it should be possible to grab the sprite
@export var grabbable := true


## The Sprite node that will be used to display the texture
var sprite := Sprite2D.new()
## The default collider. It is automatically created and updated to match the size of the sprite
var default_collider : CollisionShape2D
## Whether or not the sprite is currently grabbed
var is_grabbed := false :
	set(value):
		is_grabbed = value
		if is_grabbed:
			grabbed.emit()
		else:
			released.emit()


# Helps a bit to make the dragging less choppy
var grabbed_offset := Vector2.ZERO
# Store for the original position
var origin := Vector2.ZERO
# Mouse button pressed tracker, used to essentially replicate the behavior of 'is_action_just_released'
var mb_pressed = false


func _ready():
	# Connect signals
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	input_event.connect(_on_input_event)

	# Add the sprite to the node
	add_child(sprite)

	# Create the default collider
	default_collider = CollisionShape2D.new()
	default_collider.shape = RectangleShape2D.new()

	update_default_collider()
	
	add_child(default_collider)
	# Hide the default_collider if there is a custom collider
	if has_custom_collider():
		default_collider.visible = false
	
	# Set the starting origin if necessary
	if return_to_origin:
		origin = position


func _process(delta):
	# If the left mouse button is down and the object is and can be grabbed, update it's position
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and is_grabbed and grabbable:
		position = get_global_mouse_position() + grabbed_offset
		mb_pressed = true
	# Otherwise, if the mouse button was pressed on the previous frame but now isn't, the object is released
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and mb_pressed:
		if return_to_origin:
			position = origin
		mb_pressed = false


func has_custom_collider() -> bool:
	var children = get_children()
	for child in children:
		if child is CollisionShape2D and child != default_collider:
			return true
	
	return false


func update_default_collider():
		if default_collider and default_collider.shape:
			if not texture:
				default_collider.shape.size = Vector2(0, 0)
				return
			default_collider.shape.size = Vector2(texture.get_width(), texture.get_height())


func _on_input_event(viewport, event, shape_idx):
	## Detect when mouse button is clicked inside the area2d
	if event is InputEventMouseButton and grabbable:
		is_grabbed = event.is_pressed()
		## Helps a bit to make the dragging less choppy
		grabbed_offset = position - get_global_mouse_position()


func _on_child_entered_tree(child):
	if child is CollisionShape2D and child != default_collider:
		default_collider.visible = false


func _on_child_exiting_tree(child):
	if child is CollisionShape2D and child != default_collider:
		default_collider.visible = true
