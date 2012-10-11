define_behavior :blasted_by_bomb do
  requires :bomb_coordinator
  setup do
    bomb_coordinator.register_bombable actor

    reacts_with :remove, :esplode
  end

  helpers do
    def esplode(bomb, distance)
      log "PUSH"
      # TODO only apply if below feet
      forceV =  vec2(actor.x, actor.y) - vec2(bomb.x, bomb.y)
      
      force = (1-(distance / bomb.radius)) * bomb.force
      forceV.scale! force
      actor.vel += forceV
    end

    def remove
      log "removing blasted for #{actor.name}"
      bomb_coordinator.unregister_bombable actor
    end

  end
end
