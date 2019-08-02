tool
extends EditorPlugin

func _enter_tree():
  # Initialization of the plugin goes here
  add_custom_type('BetterParticle2D', 'Node2D', preload('res://addons/BetterParticle2D/script.gd'), preload('res://addons/BetterParticle2D/icon.png'))

func _exit_tree():
  # Clean-up of the plugin goes here
  remove_custom_type('BetterParticle2D')
