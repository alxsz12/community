"""
Applet: Fluid Sim
Summary: Does a little Fluid Sim
Description: Displays a fluid simulation with water particles that splash around the screen
Author: alxsz12
"""

load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Constants for the simulation
WIDTH = 64
HEIGHT = 32
GRAVITY = 1
WATER_COLOR = "#0099ff"
WATER_COLORS = ["#0077cc", "#0088dd", "#0099ee", "#00aaff"]
BACKGROUND_COLOR = "#000022"
OBSTACLE_COLOR = "#aaaaaa"  # Brighter color for better visibility

# Redesigned digital clock font (5x7 pixels per digit) - more elegant design
DIGITS = {
    "0": [
        [0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [0, 1, 1, 1, 0],
    ],
    "1": [
        [0, 0, 1, 0, 0],
        [0, 1, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 1, 1, 1, 0],
    ],
    "2": [
        [0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1],
        [0, 0, 0, 0, 1],
        [0, 0, 1, 1, 0],
        [0, 1, 0, 0, 0],
        [1, 0, 0, 0, 0],
        [1, 1, 1, 1, 1],
    ],
    "3": [
        [0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1],
        [0, 0, 0, 0, 1],
        [0, 0, 1, 1, 0],
        [0, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [0, 1, 1, 1, 0],
    ],
    "4": [
        [0, 0, 0, 1, 0],
        [0, 0, 1, 1, 0],
        [0, 1, 0, 1, 0],
        [1, 0, 0, 1, 0],
        [1, 1, 1, 1, 1],
        [0, 0, 0, 1, 0],
        [0, 0, 0, 1, 0],
    ],
    "5": [
        [1, 1, 1, 1, 1],
        [1, 0, 0, 0, 0],
        [1, 1, 1, 1, 0],
        [0, 0, 0, 0, 1],
        [0, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [0, 1, 1, 1, 0],
    ],
    "6": [
        [0, 1, 1, 1, 0],
        [1, 0, 0, 0, 0],
        [1, 0, 0, 0, 0],
        [1, 1, 1, 1, 0],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [0, 1, 1, 1, 0],
    ],
    "7": [
        [1, 1, 1, 1, 1],
        [0, 0, 0, 0, 1],
        [0, 0, 0, 1, 0],
        [0, 0, 1, 0, 0],
        [0, 1, 0, 0, 0],
        [0, 1, 0, 0, 0],
        [0, 1, 0, 0, 0],
    ],
    "8": [
        [0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [0, 1, 1, 1, 0],
    ],
    "9": [
        [0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1],
        [1, 0, 0, 0, 1],
        [0, 1, 1, 1, 1],
        [0, 0, 0, 0, 1],
        [0, 0, 0, 1, 0],
        [0, 1, 1, 0, 0],
    ],
    ":": [
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
    ],
}

def get_random_water_color():
    """Returns a random water color from the palette."""
    return WATER_COLORS[random.number(0, len(WATER_COLORS) - 1)]

def create_empty_grid(width, height):
    """Creates an empty grid of the specified dimensions."""
    return [[0 for _ in range(width)] for _ in range(height)]

def initialize_water(grid, x, y, width, height):
    """Initializes a block of water at the specified position."""
    for j in range(max(0, y), min(len(grid), y + height)):
        for i in range(max(0, x), min(len(grid[0]), x + width)):
            if grid[j][i] == 0:  # Only add water where there's no obstacle
                grid[j][i] = 1
    return grid

def create_time_obstacles(grid, current_time):
    """Creates obstacles in the shape of the current time."""

    # Format time as HH:MM
    hour = current_time.hour
    minute = current_time.minute

    # Format time as HH:MM using string concatenation instead of format specifiers
    hour_str = "0" + str(hour) if hour < 10 else str(hour)
    minute_str = "0" + str(minute) if minute < 10 else str(minute)
    time_str = hour_str + ":" + minute_str

    # Calculate starting position to center the time
    # Each digit is 5 pixels wide, plus 2 pixel spacing for better readability
    total_width = (len(time_str) * 7) - 2  # 7 pixels per character (5 + 2 spacing)
    start_x = (WIDTH - total_width) // 2
    start_y = (HEIGHT - 7) // 2  # Each digit is 7 pixels tall

    # Draw each character
    x_pos = start_x

    # Convert time_str to a list of characters for iteration
    time_chars = []
    for i in range(len(time_str)):
        time_chars.append(time_str[i:i + 1])

    # Draw the time digits
    for char in time_chars:
        if char in DIGITS:
            digit = DIGITS[char]
            for y in range(7):
                for x in range(5):
                    if digit[y][x] == 1:
                        grid_y = start_y + y
                        grid_x = x_pos + x
                        if grid_y >= 0 and grid_y < HEIGHT and grid_x >= 0 and grid_x < WIDTH:
                            grid[grid_y][grid_x] = 2  # 2 represents obstacle
        x_pos += 7  # Move to next character position (5 pixels + 2 space)

    return grid

def update_fluid(grid):
    """Updates the fluid simulation using a simple cellular automaton approach."""
    new_grid = create_empty_grid(len(grid[0]), len(grid))

    # Copy the current state including obstacles
    for y in range(len(grid)):
        for x in range(len(grid[0])):
            new_grid[y][x] = grid[y][x]

    # Update water particles
    for y in range(len(grid) - 1, -1, -1):  # Start from bottom
        for x in range(len(grid[0])):
            if grid[y][x] == 1:  # If this is a water particle
                # Try to move down
                if y < len(grid) - 1 and new_grid[y + 1][x] == 0:
                    new_grid[y][x] = 0
                    new_grid[y + 1][x] = 1
                    # Try to move diagonally down

                elif y < len(grid) - 1:
                    moved = False

                    # Try down-left and down-right in random order
                    directions = [(-1, 1), (1, 1)]

                    # Simple randomization instead of shuffle
                    if random.number(0, 1) == 0:
                        directions = [(1, 1), (-1, 1)]

                    for dx, dy in directions:
                        nx, ny = x + dx, y + dy
                        if nx >= 0 and nx < len(grid[0]) and ny < len(grid) and new_grid[ny][nx] == 0:
                            new_grid[y][x] = 0
                            new_grid[ny][nx] = 1
                            moved = True
                            break

                    # If couldn't move diagonally, try to spread horizontally
                    if not moved:
                        directions = [(-1, 0), (1, 0)]

                        # Simple randomization instead of shuffle
                        if random.number(0, 1) == 0:
                            directions = [(1, 0), (-1, 0)]

                        for dx, dy in directions:
                            nx, ny = x + dx, y
                            if nx >= 0 and nx < len(grid[0]) and new_grid[ny][nx] == 0:
                                new_grid[y][x] = 0
                                new_grid[ny][nx] = 1
                                break

    return new_grid

def render_fluid(grid, frame):
    """Renders the fluid simulation as a Tidbyt-compatible image."""
    cells = []

    # Create a background
    cells.append(render.Box(
        width = WIDTH,
        height = HEIGHT,
        color = BACKGROUND_COLOR,
    ))

    # Add obstacles and water particles with absolute positioning
    for y in range(len(grid)):
        for x in range(len(grid[0])):
            if grid[y][x] == 1:  # Water particle
                # Use a slightly different color based on position and frame for visual interest
                color_index = (x + y + frame) % len(WATER_COLORS)
                color = WATER_COLORS[color_index]

                cells.append(render.Padding(
                    pad = (x, y, 0, 0),  # Left, top, right, bottom
                    child = render.Box(
                        width = 1,
                        height = 1,
                        color = color,
                    ),
                ))
            elif grid[y][x] == 2:  # Obstacle
                cells.append(render.Padding(
                    pad = (x, y, 0, 0),  # Left, top, right, bottom
                    child = render.Box(
                        width = 1,
                        height = 1,
                        color = OBSTACLE_COLOR,
                    ),
                ))

    return render.Stack(children = cells)

def main():
    # Get current time
    current_time = time.now()

    # Create frames for animation
    frames = []

    # Create initial state with empty grid
    grid = create_empty_grid(WIDTH, HEIGHT)

    # Add time-shaped obstacles
    grid = create_time_obstacles(grid, current_time)

    # Add several water sources across the top
    water_sources = [
        {"x": 5, "y": 0, "width": 8, "height": 2},
        {"x": 20, "y": 0, "width": 8, "height": 2},
        {"x": 35, "y": 0, "width": 8, "height": 2},
        {"x": 50, "y": 0, "width": 8, "height": 2},
    ]

    # Initialize with water sources
    for source in water_sources:
        grid = initialize_water(grid, source["x"], source["y"], source["width"], source["height"])

    # Create animation frames
    num_frames = 75

    # Generate all frames
    for frame in range(num_frames):
        # Render this frame
        frames.append(render_fluid(grid, frame))

        # Update the fluid simulation for the next frame
        grid = update_fluid(grid)

        # Add a small amount of new water every few frames
        if frame % 2 == 0:
            for source in water_sources:
                # Add a bit of randomness to the water source
                width = source["width"] - 2
                x_offset = random.number(0, 2)
                grid = initialize_water(grid, source["x"] + x_offset, 0, width, 1)

    # Return animation with all frames
    return render.Root(
        delay = 100,
        child = render.Animation(
            children = frames,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
