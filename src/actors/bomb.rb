define_actor :bomb do
  
  has_behaviors do
    positioned
    audible
    layered ZOrder::Projectile
    animated_with_spritemap file: 'trippers/props.png', rows: 4, cols: 6, actions: { idle: 0..2 }
    bound_by_box
    mover
    tile_collision_detector
    tile_bouncer
    bomb_collision_points
    explode_by_bomb
    explode_by_bullet
    pulled_by_black_hole
  end

  behavior do
    requires :timer_manager, :stage

    setup do
      reacts_with :remove
    
      actor.has_attributes(
        force: 8, # force of the effect at 0 distance (impulse will be force/distance)
        radius: 200 # radius of effect - the distance at which the effect's influence will drop to zero
      )
      setup_timers
      actor.when :boom do
        make_shrapnel
      end
    end

    helpers do
      def tick_timer_name; "#{object_id}_bomb_tick"; end
      def death_timer_name; "#{object_id}_bomb_death"; end

      def remove
        timer_manager.remove_timer tick_timer_name
        timer_manager.remove_timer death_timer_name
        actor.unsubscribe_all self
      end

      def setup_timers
        timer_tick_acculation = 0
        interval = 30
        next_beep = 800
        timer_manager.add_timer tick_timer_name, interval do
          if timer_tick_acculation > next_beep
            actor.react_to :play_sound, :bomb_tick 
            timer_tick_acculation = 0
            next_beep = next_beep * 0.8
          else
            timer_tick_acculation += interval
          end
        end

        timer_manager.add_timer death_timer_name, 3_000, false do
          actor.react_to :play_sound, :bomb
          actor.emit :boom
          actor.remove
        end
      end

      def make_shrapnel(args={})
        force = args[:force] || vec2(0,0)
        count = args[:count] || 30
        count.times do
          vel = vec2(3,0).rotate!(degrees_to_radians(rand(360))) * rand(4)
          stage.create_actor :shrapnel, x: actor.x, y: actor.y, vel: vel + force + actor.vel, map: actor.map, size: rand(8), color: Color::GRAY
        end
      end
    end
  end

  view do
    draw do |target, x_off, y_off, z|
      x = actor.x
      y = actor.y

      offset_x = x+x_off
      offset_y = y+y_off
      rot = normalize_angle(actor.rotation)

      img = actor.image
      #target.fill offset_x, offset_y, offset_x+2, offset_y+2, Color::YELLOW, z
      target.draw_rotated_image img, offset_x, offset_y, z, rot#, 0.5, 0.5, x_scale

      if ENV['DEBUG']
        target.draw_circle offset_x, offset_y, 100, Color::WHITE, ZOrder::PlayerDecoration
      end
      
    end
  end
end
