extends Area2D

# Node References
@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	set_process(true)

func _process(_delta):
	var time = Time.get_ticks_msec() / 1000.0
	
	var animation = anim_sprite.animation
	var frames = anim_sprite.sprite_frames.get_frame_count(animation)
	var speed = anim_sprite.sprite_frames.get_animation_speed(animation)
	
	var frame_time = time * speed
	var frame_index = int(frame_time) % frames
	var frame_progress = frame_time - int(frame_time)
	
	anim_sprite.frame = frame_index
	anim_sprite.frame_progress = frame_progress
