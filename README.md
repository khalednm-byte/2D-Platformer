# Royal Blood

**Royal Blood** is a work-in-progress 2D action-platformer built with **Godot 4** and **GDScript**. The project focuses on responsive character movement, modular gameplay systems, and close-range combat with animation-driven hit windows.

## Project Status

The game is currently in active development. Core player movement and the combat architecture are being built and tested before expanding into enemies, levels, progression, and final content.

## Current Features

- Component-based player architecture
- Ground movement with acceleration and deceleration
- Air movement and gravity
- Jump buffering and coyote time
- Crouching with enter/exit transitions and head-clearance checks
- Momentum-based sliding
- Direction-aware slide collision polygons
- Character facing and turn animations
- Generic one-shot animation locking
- Data-driven attacks using `AttackData` resources
- Runtime attack context using `AttackInfo`
- Frame-based attack hit windows
- Hitbox, hurtbox, health, and knockback separation
- Moving, stationary, and crouched attack variants
- Combo-system development
- Input-source abstraction for future player and AI control

## Architecture

The project separates gameplay responsibilities into focused scripts:

- **`Player.gd`** — coordinates input, stance, facing direction, and action priority.
- **`SimpleMovementComponent.gd`** — handles velocity, acceleration, gravity, jumping, crouch speed, and slide movement.
- **`CharacterAnimationComponent.gd`** — controls animation playback, visual facing, one-shot locks, and completion signals.
- **`CharacterAnimationSet.gd`** — stores configurable locomotion and transition animation names.
- **`CombatComponent.gd`** — selects attacks, manages combo state, activates hit windows, and creates runtime attack information.
- **`AttackData.gd`** — stores reusable attack configuration such as damage, knockback, animation name, and active frames.
- **`AttackInfo.gd`** — stores runtime information for one specific attack instance.
- **`HitBoxComponent.gd`** — detects hurtboxes during active attack frames and prevents repeated hits within the same hit window.
- **`HurtBoxComponent.gd`** — receives attacks and forwards damage and knockback information.
- **`HealthComponent.gd`** — manages health changes and death.
- **`BaseInputSource.gd` / `CharacterIntent.gd`** — separate input collection from character behavior.

## Gameplay Systems in Progress

- Complete standing combo progression
- Moving and stationary combo variants
- Crouched attacks
- Per-attack collision polygons
- Multiple hit windows for multi-swing attacks
- Attack movement restrictions
- Damage reactions and knockback
- Enemy combat and AI
- Improved state transitions and interruption rules

## Requirements

- Godot Engine 4.x
- No external runtime dependencies are currently required

## Running the Project

1. Clone the repository:

   ```bash
   git clone <repository-url>
   ```

2. Open Godot.
3. Select **Import**.
4. Choose the project's `project.godot` file.
5. Open the project and run the main scene.

## Development Goals

The project is being developed with these principles:

- High cohesion and low coupling
- Data-driven combat configuration
- Reusable character components
- Clear separation between gameplay rules, physics, animation, and collision detection
- Responsive action-platformer controls
- Systems that can later support both player-controlled and AI-controlled characters

## Repository Notes

Generated Godot files are excluded through `.gitignore`. Source scenes, scripts, resources, and original game assets should remain tracked.

Large source assets may require Git LFS or separate storage depending on the repository host's file restrictions.

## Credits

Developed by **Khaled Alnwelate**.

Third-party visual, audio, and other assets remain the property of their respective creators. Exact asset credits should be added before a public release.

## License

No open-source license has been added yet. All rights are reserved unless stated otherwise.
