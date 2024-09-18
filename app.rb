require "js"

puts RUBY_VERSION # (Printed to the Web browser console)

puts "Starting app.rb"

GAME_WIDTH = 640
GAME_HEIGHT = 480
GAME_SPEED = 1000 / 60
BRICK_WIDTH = 64
BRICK_HEIGHT = 32
PADDLE_WIDTH = 104
PADDLE_HEIGHT = 24
PADDLE_SPEED = 6
BALL_WIDTH = 22
BALL_HEIGHT = 22

class Rect
  attr_reader :x, :y, :width, :height

  def initialize(x, y, width, height)
    @x = x
    @y = y
    @width = width
    @height = height
  end
end

class BrickType
  attr_reader :image, :points

  def initialize(image, points)
    @image = image
    @points = points
  end
end


class Brick
  attr_reader :x, :y
  def initialize(btype, x, y)
    @btype = btype
    @x = x
    @y = y
  end

  def draw(ctx)
    ctx.drawImage(@btype.image, x, y)
  end

  def height
    BRICK_HEIGHT
  end

  def width
    BRICK_WIDTH
  end
end


class Paddle
  attr_reader :velocity, :rect

  def initialize(image, rect)
    @velocity = [0, 0]
    @image = image
    @rect = rect
    @velocity = velocity
  end

  def draw(ctx)
    ctx.drawImage(@image, rect.x, rect.y, rect.width, rect.height)
  end
end

class Ball
  attr_reader :velocity, :rect

  def initialize(image, rect)
    @velocity = [1.0, 3.0]
    @image = image
    @rect = rect
    @velocity = velocity
  end

  def draw(ctx)
    ctx.drawImage(@image, rect.x, rect.y, rect.width, rect.height)
  end
end


class Level
  attr_reader :bricks

  def initialize(layout)
    puts "Initializing layout"
    @bricks = initialize_bricks(layout)
    puts "Initialized a level with #{@bricks.size} bricks"
  end

  private

  def initialize_bricks(layout)
    rows = layout.size
    cols = layout[0].size
    offset_x = (GAME_WIDTH - (BRICK_WIDTH * cols)) / 2
    offset_y = 48

    bricks = []

    layout.each_with_index do |row, y|
      row.each_with_index do |btype, x|
        flat_index = (y * cols) + x
        bricks[flat_index] = Brick.new(btype,
                                           (x * BRICK_WIDTH) + offset_x,
                                           (y * BRICK_HEIGHT) + offset_y)
        puts "Building block #{flat_index} at #{bricks[flat_index].x}, #{bricks[flat_index].y}"
      end
    end

    bricks
  end
end


class Game
  attr_reader :canvas, :ctx

  def initialize(canvas)
    @canvas = canvas
    @canvas[:width] = GAME_WIDTH
    @canvas[:height] = GAME_WIDTH
    @ctx = @canvas.getContext("2d")

    JS.global[:document].addEventListener("keydown"){|e| on_keydown(e) }
    JS.global[:document].addEventListener("keyup"){|e| on_keyup(e) }

    brick_types = {
      red: BrickType.new(image("assets/images/brick-red.png"), 10),
      green: BrickType.new(image("assets/images/brick-green.png"), 20),
      blue: BrickType.new(image("assets/images/brick-blue.png"), 30)
    }

    # Level 1
    @level = Level.new(
      [
        [:red, :green, :blue, :red, :green, :blue, :red, :green],
        [:green, :blue, :red, :green, :blue, :red, :green, :blue],
        [:blue, :red, :green, :blue, :red, :green, :blue, :red],
        [:red, :green, :blue, :red, :green, :blue, :red, :green],
        [:green, :blue, :red, :green, :blue, :red, :green, :blue],
        [:blue, :red, :green, :blue, :red, :green, :blue, :red]
      ].map{|row| row.map{|color| brick_types[color] }}
    )

    @paddle = Paddle.new(
      image("assets/images/paddle.png"),
      Rect.new(
        (GAME_WIDTH/2) - (PADDLE_WIDTH/2),
        GAME_HEIGHT - PADDLE_HEIGHT - 8,
        PADDLE_WIDTH,
        PADDLE_HEIGHT
      )
    )

    @ball = Ball.new(
      image("assets/images/ball.png"),
      Rect.new(
        GAME_WIDTH / 2,
        GAME_HEIGHT / 2,
        BALL_WIDTH,
        BALL_HEIGHT
      )
    )
  end

  def start!
    puts "Running Game#start!"
    request_draw_callback
    request_update_callback
  end

  private

  def update
    @ball.rect.x = @ball.rect.x + @ball.velocity[0]
    @ball.rect.y = @ball.rect.y + @ball.velocity[1]

    request_update_callback
  end

  def draw(ts)
    # Draw background
    ctx[:fillStyle] = "#140c1c"
    ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT)

    # Draw bricks
    @level.bricks.each do |brick|
      brick.draw(ctx)
    end

    @ball.draw(ctx)
    @paddle.draw(ctx)

    request_draw_callback
  end

  def on_keydown(event)
    puts "On keydown!"
    puts event
  end

  def on_keyup(event)
    puts "On keyup!"
    puts event
  end

  def request_draw_callback
    JS.global.setTimeout(
      -> {JS.global.requestAnimationFrame{|ts| draw(ts) } },
      GAME_SPEED
    )
  end

  def request_update_callback
    JS.global.setTimeout(-> { update() }, GAME_SPEED)
  end

  def image(src)
    img = JS.global[:Image].new
    img[:src] = src
    img
  end
end



puts "The game has loaded!"

puts "Initializing game"

Game.new(JS.global[:document].getElementById("canvas")).start!

"Starting up"
