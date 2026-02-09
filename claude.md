# ChessBrawl

## Project Overview
ChessBrawl is a 2D mobile game built with Godot 4.6 (stable).

## Tech Stack
- **Engine:** Godot 4.6 stable
- **Languages:** GDScript and C#
- **Renderer:** GL Compatibility (mobile target)
- **Target platform:** Mobile (iOS / Android)

## Project Structure
- `scenes/` — Scene files (.tscn)
- `scripts/` — GDScript (.gd) and C# (.cs) scripts
- `resources/` — Resources, themes, materials
- `assets/` — Art, audio, fonts

## Coding Conventions

### GDScript
- Follow the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- Always use static typing (e.g. `var speed: float = 10.0`, `func foo() -> void:`)
- Use snake_case for variables, functions, and signals
- Use PascalCase for classes and node names
- Prefix private members with underscore (`_my_var`)
- Use `@onready` for node references, never `get_node()` in `_ready()`
- Use `floori()` / `floorf()` / `ceili()` for float-to-int math instead of `int(x) / y` to avoid integer division warnings
- Always validate resource/state constraints (e.g. cost, cooldown, ammo) at the moment of action, not only when selecting the action — GDScript is single-threaded so checks are synchronous, but the guard must live in the execution function, not just the UI button handler

### C#
- Follow standard C# conventions (PascalCase for methods/properties, camelCase for locals)
- Use PascalCase for class names matching the file name
- Use explicit access modifiers on all members

### General
- Node names use PascalCase
- File names use snake_case for GDScript, PascalCase for C#
- Scene files use snake_case (e.g. `main_menu.tscn`)
- Keep scenes and their scripts co-located or in matching directory structures
- Prefer signals over direct node references for decoupling
- Use `class_name` to register reusable GDScript classes globally

## Mobile Considerations
- Design for touch input — no keyboard/mouse assumptions
- Keep draw calls and node count low for performance
- Use the GL Compatibility renderer (not Forward+)
- Design UI with varying screen sizes and aspect ratios in mind
- Test with touch input emulation in the editor

## Build & Run
- Open `project.godot` in Godot 4.6
- Main scene: `res://scenes/menu.tscn`
- Export templates needed for mobile builds (iOS / Android)

---

# GDScript Patterns (Skill: godot-gdscript-patterns)

Production patterns for Godot 4.x game development with GDScript, covering architecture, signals, scenes, and optimization.

## Core Architecture

```
Node: Base building block
├── Scene: Reusable node tree (saved as .tscn)
├── Resource: Data container (saved as .tres)
├── Signal: Event communication
└── Group: Node categorization
```

## Pattern 1: State Machine

```gdscript
# state_machine.gd
class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name] = child
            child.state_machine = self
            child.process_mode = Node.PROCESS_MODE_DISABLED
    if initial_state:
        current_state = initial_state
        current_state.process_mode = Node.PROCESS_MODE_INHERIT
        current_state.enter()

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
    if not states.has(state_name):
        push_error("State '%s' not found" % state_name)
        return
    var previous_state := current_state
    previous_state.exit()
    previous_state.process_mode = Node.PROCESS_MODE_DISABLED
    current_state = states[state_name]
    current_state.process_mode = Node.PROCESS_MODE_INHERIT
    current_state.enter(msg)
    state_changed.emit(previous_state.name, current_state.name)
```

```gdscript
# state.gd
class_name State
extends Node

var state_machine: StateMachine

func enter(_msg: Dictionary = {}) -> void:
    pass

func exit() -> void:
    pass

func update(_delta: float) -> void:
    pass

func physics_update(_delta: float) -> void:
    pass

func handle_input(_event: InputEvent) -> void:
    pass
```

## Pattern 2: Autoload Singletons

```gdscript
# game_manager.gd (Add to Project Settings > Autoload)
extends Node

signal game_started
signal game_paused(is_paused: bool)
signal game_over(won: bool)
signal score_changed(new_score: int)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var state: GameState = GameState.MENU
var score: int = 0:
    set(value):
        score = value
        score_changed.emit(score)

func start_game() -> void:
    score = 0
    state = GameState.PLAYING
    game_started.emit()

func toggle_pause() -> void:
    var is_paused := state != GameState.PAUSED
    if is_paused:
        state = GameState.PAUSED
        get_tree().paused = true
    else:
        state = GameState.PLAYING
        get_tree().paused = false
    game_paused.emit(is_paused)

func end_game(won: bool) -> void:
    state = GameState.GAME_OVER
    game_over.emit(won)
```

```gdscript
# event_bus.gd (Global signal bus)
extends Node

signal player_spawned(player: Node2D)
signal player_died(player: Node2D)
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy: Node2D, position: Vector2)
signal item_collected(item_type: StringName, value: int)
signal level_started(level_number: int)
signal level_completed(level_number: int, time: float)
```

## Pattern 3: Resource-based Data

```gdscript
# weapon_data.gd
class_name WeaponData
extends Resource

@export var name: StringName
@export var damage: int
@export var attack_speed: float
@export var range: float
@export_multiline var description: String
@export var icon: Texture2D
@export var projectile_scene: PackedScene
@export var sound_attack: AudioStream
```

```gdscript
# character_stats.gd
class_name CharacterStats
extends Resource

signal stat_changed(stat_name: StringName, new_value: float)

@export var max_health: float = 100.0
@export var attack: float = 10.0
@export var defense: float = 5.0
@export var speed: float = 200.0

var _current_health: float

func _init() -> void:
    _current_health = max_health

func take_damage(amount: float) -> float:
    var actual_damage := maxf(amount - defense, 1.0)
    _current_health = maxf(_current_health - actual_damage, 0.0)
    stat_changed.emit("health", _current_health)
    return actual_damage

func heal(amount: float) -> void:
    _current_health = minf(_current_health + amount, max_health)
    stat_changed.emit("health", _current_health)

func duplicate_for_runtime() -> CharacterStats:
    var copy := duplicate() as CharacterStats
    copy._current_health = copy.max_health
    return copy
```

## Pattern 4: Object Pooling

```gdscript
# object_pool.gd
class_name ObjectPool
extends Node

@export var pooled_scene: PackedScene
@export var initial_size: int = 10
@export var can_grow: bool = true

var _available: Array[Node] = []
var _in_use: Array[Node] = []

func _ready() -> void:
    for i in initial_size:
        _create_instance()

func _create_instance() -> Node:
    var instance := pooled_scene.instantiate()
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    instance.visible = false
    add_child(instance)
    _available.append(instance)
    if instance.has_signal("returned_to_pool"):
        instance.returned_to_pool.connect(_return_to_pool.bind(instance))
    return instance

func get_instance() -> Node:
    var instance: Node
    if _available.is_empty():
        if can_grow:
            instance = _create_instance()
            _available.erase(instance)
        else:
            return null
    else:
        instance = _available.pop_back()
    instance.process_mode = Node.PROCESS_MODE_INHERIT
    instance.visible = true
    _in_use.append(instance)
    if instance.has_method("on_spawn"):
        instance.on_spawn()
    return instance

func _return_to_pool(instance: Node) -> void:
    if not instance in _in_use:
        return
    _in_use.erase(instance)
    if instance.has_method("on_despawn"):
        instance.on_despawn()
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    instance.visible = false
    _available.append(instance)
```

## Pattern 5: Component System

```gdscript
# health_component.gd
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

@export var max_health: int = 100
@export var invincibility_time: float = 0.0

var current_health: int:
    set(value):
        var old := current_health
        current_health = clampi(value, 0, max_health)
        if current_health != old:
            health_changed.emit(current_health, max_health)

var _invincible: bool = false

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int, source: Node = null) -> int:
    if _invincible or current_health <= 0:
        return 0
    var actual := mini(amount, current_health)
    current_health -= actual
    damaged.emit(actual, source)
    if current_health <= 0:
        died.emit()
    elif invincibility_time > 0:
        _start_invincibility()
    return actual

func heal(amount: int) -> int:
    var actual := mini(amount, max_health - current_health)
    current_health += actual
    if actual > 0:
        healed.emit(actual)
    return actual

func _start_invincibility() -> void:
    _invincible = true
    await get_tree().create_timer(invincibility_time).timeout
    _invincible = false
```

```gdscript
# hitbox_component.gd
class_name HitboxComponent
extends Area2D

signal hit(hurtbox: HurtboxComponent)

@export var damage: int = 10
@export var knockback_force: float = 200.0

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
    if area is HurtboxComponent:
        var hurtbox := area as HurtboxComponent
        if hurtbox.owner_node != get_parent():
            hit.emit(hurtbox)
            hurtbox.receive_hit(self)
```

```gdscript
# hurtbox_component.gd
class_name HurtboxComponent
extends Area2D

signal hurt(hitbox: HitboxComponent)

@export var health_component: HealthComponent

var owner_node: Node

func _ready() -> void:
    owner_node = get_parent()

func receive_hit(hitbox: HitboxComponent) -> void:
    hurt.emit(hitbox)
    if health_component:
        health_component.take_damage(hitbox.damage, hitbox.owner_node)
```

## Pattern 6: Scene Management

```gdscript
# scene_manager.gd (Autoload)
extends Node

signal scene_loaded(scene: Node)
signal transition_finished

var _current_scene: Node

func _ready() -> void:
    _current_scene = get_tree().current_scene

func change_scene(scene_path: String) -> void:
    _load_scene(scene_path)

func _load_scene(path: String) -> void:
    if ResourceLoader.has_cached(path):
        var scene := load(path) as PackedScene
        _swap_scene(scene.instantiate())
        return
    ResourceLoader.load_threaded_request(path)
    while true:
        var progress := []
        var status := ResourceLoader.load_threaded_get_status(path, progress)
        match status:
            ResourceLoader.THREAD_LOAD_IN_PROGRESS:
                await get_tree().process_frame
            ResourceLoader.THREAD_LOAD_LOADED:
                var scene := ResourceLoader.load_threaded_get(path) as PackedScene
                _swap_scene(scene.instantiate())
                return
            _:
                push_error("Failed to load scene: %s" % path)
                return

func _swap_scene(new_scene: Node) -> void:
    if _current_scene:
        _current_scene.queue_free()
    _current_scene = new_scene
    get_tree().root.add_child(_current_scene)
    get_tree().current_scene = _current_scene
    scene_loaded.emit(_current_scene)
```

## Pattern 7: Save System

```gdscript
# save_manager.gd (Autoload)
extends Node

const SAVE_PATH := "user://savegame.save"

signal save_completed
signal load_completed

func save_game(data: Dictionary) -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Could not open save file")
        return
    file.store_string(JSON.stringify(data))
    file.close()
    save_completed.emit()

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return {}
    var parsed := JSON.parse_string(file.get_as_text())
    file.close()
    if parsed == null:
        return {}
    load_completed.emit()
    return parsed

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
```

## Performance Tips

- Cache node references with `@onready` — never use `$Node` in `_process()`
- Use object pooling for frequently spawned objects (bullets, particles)
- Reuse arrays/dictionaries instead of allocating new ones in hot paths
- Always use static typing for better performance and error catching
- Disable processing when not needed: `set_process(false)`, `set_physics_process(false)`

## Best Practices

### Do's
- Use signals for decoupling — avoid direct references
- Type everything — static typing catches errors early
- Use Resources for data — separate data from logic
- Pool frequently spawned objects — avoid GC hitches
- Use Autoloads sparingly — only for truly global systems

### Don'ts
- Don't use `get_node()` in loops — cache references
- Don't couple scenes tightly — use signals
- Don't put logic in Resources — keep them data-only
- Don't ignore the Profiler — monitor performance
- Don't fight the scene tree — work with Godot's design

---

# Godot UI/UX (Skill: godot-ui)

Expert knowledge of Godot's UI system including Control nodes, themes, styling, responsive layouts, and common UI patterns.

## Control Node Hierarchy

**Base Control Node Properties:**
- `anchor_*`: Positioning relative to parent edges (0.0 to 1.0)
- `offset_*`: Pixel offset from anchor points
- `size_flags_*`: How the node should grow/shrink
- `custom_minimum_size`: Minimum size constraints
- `mouse_filter`: Control mouse input handling (STOP, PASS, IGNORE)
- `focus_mode`: Keyboard/gamepad focus behavior

### Container Nodes (Layout Management)
- **VBoxContainer**: Vertical stacking with automatic spacing
- **HBoxContainer**: Horizontal arrangement with automatic spacing
- **GridContainer**: Grid layout with columns
- **MarginContainer**: Adds margins around children
- **CenterContainer**: Centers a single child
- **PanelContainer**: Container with panel background
- **ScrollContainer**: Scrollable area for overflow content
- **TabContainer**: Tabbed interface with multiple pages

### Interactive Controls
- **Button**, **TextureButton**, **CheckBox**, **CheckButton**
- **OptionButton**: Dropdown selection menu
- **LineEdit**: Single-line text input
- **TextEdit**: Multi-line text editor
- **Slider/HSlider/VSlider**: Value adjustment sliders
- **ProgressBar**: Visual progress indicator
- **ItemList**: Scrollable list of items
- **Tree**: Hierarchical tree view

### Display Nodes
- **Label**, **RichTextLabel** (BBCode formatting)
- **TextureRect**, **NinePatchRect**, **ColorRect**

## Anchor & Container System

```gdscript
# Common anchor configurations
# Top-left (default): anchor_left=0, anchor_top=0, anchor_right=0, anchor_bottom=0
# Full rect: anchor_left=0, anchor_top=0, anchor_right=1, anchor_bottom=1
# Center: anchor_left=0.5, anchor_top=0.5, anchor_right=0.5, anchor_bottom=0.5
```

**Responsive Design Pattern:**
```gdscript
func _ready() -> void:
    get_viewport().size_changed.connect(_on_viewport_size_changed)
    _on_viewport_size_changed()

func _on_viewport_size_changed() -> void:
    var viewport_size := get_viewport_rect().size
    if viewport_size.x / viewport_size.y < 1.5:
        # Portrait/square — mobile layout
        pass
    else:
        # Landscape — desktop layout
        pass
```

## Theme System

**Theme Structure:** StyleBoxes, Fonts, Colors, Icons, Constants

```gdscript
var theme := Theme.new()

var style_normal := StyleBoxFlat.new()
style_normal.bg_color = Color(0.2, 0.2, 0.2)
style_normal.corner_radius_top_left = 5
style_normal.corner_radius_top_right = 5
style_normal.corner_radius_bottom_left = 5
style_normal.corner_radius_bottom_right = 5
style_normal.content_margin_left = 10
style_normal.content_margin_right = 10
style_normal.content_margin_top = 5
style_normal.content_margin_bottom = 5

theme.set_stylebox("normal", "Button", style_normal)
$MyControl.theme = theme
```

Best practice: Create `.tres` theme files in `resources/themes/` for reusability and Inspector editing.

## Common UI Patterns

### Main Menu
```
CanvasLayer
├── MarginContainer
│   └── VBoxContainer
│       ├── TextureRect (logo)
│       ├── VBoxContainer (buttons)
│       │   ├── Button (New Game)
│       │   ├── Button (Continue)
│       │   ├── Button (Settings)
│       │   └── Button (Quit)
│       └── Label (version info)
```

### HUD
```
CanvasLayer (layer = 10)
├── MarginContainer
│   └── VBoxContainer
│       ├── HBoxContainer (top bar)
│       │   ├── TextureRect (health icon)
│       │   ├── ProgressBar (health)
│       │   ├── Control (spacer)
│       │   ├── Label (score)
│       │   └── TextureRect (coin icon)
│       ├── Control (spacer - expands)
│       └── HBoxContainer (bottom bar)
│           ├── TextureButton (inventory)
│           ├── TextureButton (map)
│           └── TextureButton (pause)
```

### Settings Menu
```
CanvasLayer
├── ColorRect (overlay)
└── PanelContainer
    └── MarginContainer
        └── VBoxContainer
            ├── Label (header)
            ├── TabContainer
            │   ├── VBoxContainer (Graphics)
            │   └── VBoxContainer (Audio)
            └── HBoxContainer
                ├── Button (Apply)
                └── Button (Back)
```

### Inventory System
```
CanvasLayer
├── ColorRect (overlay)
└── PanelContainer
    └── MarginContainer
        └── VBoxContainer
            ├── Label (header)
            ├── HBoxContainer
            │   ├── GridContainer (item grid - columns=5)
            │   └── PanelContainer (item details)
            └── Button (Close)
```

### Dialogue System
```
CanvasLayer (layer = 5)
├── Control (spacer)
└── PanelContainer (anchored bottom)
    └── MarginContainer
        └── VBoxContainer
            ├── HBoxContainer (character info)
            │   ├── TextureRect (portrait)
            │   └── Label (name)
            ├── RichTextLabel (dialogue text)
            └── VBoxContainer (choices)
```

### Pause Menu
```
CanvasLayer (layer = 100)
├── ColorRect (overlay)
└── CenterContainer (full rect)
    └── PanelContainer
        └── MarginContainer
            └── VBoxContainer
                ├── Label (PAUSED)
                ├── Button (Resume)
                ├── Button (Settings)
                ├── Button (Main Menu)
                └── Button (Quit)
```

## Common UI Scripting Patterns

### Button Connections
```gdscript
@onready var start_button: Button = $VBoxContainer/StartButton

func _ready() -> void:
    start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_game.tscn")
```

### Gamepad Navigation
```gdscript
func _ready() -> void:
    $VBoxContainer/StartButton.grab_focus()

    # Configure focus neighbors
    for i in range($ButtonContainer.get_child_count() - 1):
        var current := $ButtonContainer.get_child(i)
        var next := $ButtonContainer.get_child(i + 1)
        current.focus_neighbor_bottom = next.get_path()
        next.focus_neighbor_top = current.get_path()
```

### Animated Transitions
```gdscript
func show_menu() -> void:
    modulate.a = 0
    visible = true
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_menu() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.tween_callback(func() -> void: visible = false)

func slide_in() -> void:
    position.x = -get_viewport_rect().size.x
    visible = true
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "position:x", 0, 0.5)
```

### Health Bar Updates
```gdscript
@onready var health_bar: ProgressBar = $HealthBar

func update_health(current: int, maximum: int) -> void:
    health_bar.max_value = maximum
    var tween := create_tween()
    tween.tween_property(health_bar, "value", current, 0.2)

    if current < maximum * 0.3:
        health_bar.modulate = Color.RED
    elif current < maximum * 0.6:
        health_bar.modulate = Color.YELLOW
    else:
        health_bar.modulate = Color.GREEN
```

## UI Performance Tips

- Use **CanvasLayers** for depth management instead of z_index
- Set `clip_contents = true` on ScrollContainers
- Limit RichTextLabel complexity — BBCode parsing can be slow
- Pool UI elements — reuse nodes instead of creating/destroying
- Use **TextureAtlas** for UI sprites to reduce draw calls
- Set `process_mode = PROCESS_MODE_DISABLED` when UI is hidden

## Important Reminders

- Always consider **gamepad/keyboard navigation** in addition to touch
- Use **CanvasLayers** to manage rendering order
- **Anchor presets** are essential for responsive design on mobile
- **Themes** should be `.tres` resources for reusability
- **Signals** are the primary way to handle UI interactions
- **Tweens** make UI feel polished with smooth animations
- **Test on multiple resolutions** via Project Settings > Display > Window
