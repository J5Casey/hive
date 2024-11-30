extends StaticBody2D

func _ready():
	set_process(true)  # Enable processing

func _process(_delta):
	# Get global time in seconds
	var time = Time.get_ticks_msec() / 1000.0  

	# Get current animation details
	var anim_sprite = $AnimatedSprite2D
	var animation = anim_sprite.animation  
	var frames = anim_sprite.sprite_frames.get_frame_count(animation)  

	# Get the animation speed from the sprite_frames resource
	var speed = anim_sprite.sprite_frames.get_animation_speed(animation)  

	# Calculate the current frame based on global time
	var frame_time = time * speed  
	var frame_index = int(frame_time) % frames  
	var frame_progress = frame_time - int(frame_time)  

	# Set the frame and frame progress
	anim_sprite.frame = frame_index
	anim_sprite.frame_progress = frame_progress
