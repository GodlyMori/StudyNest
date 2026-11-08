import matplotlib.pyplot as plt
import matplotlib.patches as patches
import shutil

# Set up clean canvas
fig, ax = plt.subplots(figsize=(11, 7), dpi=300)
ax.set_xlim(0, 110)
ax.set_ylim(0, 70)
ax.axis('off')

# Clean white background
fig.patch.set_facecolor('#FFFFFF')
ax.set_facecolor('#FFFFFF')

# Title (Clean Academic Style)
plt.text(55, 66, "StudyNest — Use Case Diagram", fontsize=15, fontweight='bold', ha='center', va='center', color='black')

# System Boundary Box (Simple black rectangle)
system_rect = patches.Rectangle((28, 6), 54, 56, fill=False, edgecolor='black', linewidth=1.5)
ax.add_patch(system_rect)
plt.text(30, 59.5, "StudyNest System", fontsize=10, fontweight='bold', ha='left', va='center', color='black')

# Classic UML Stickman Function (Pure black lines)
def draw_stickman(ax, x, y, label):
    # Head
    head = plt.Circle((x, y), 2.0, fill=False, edgecolor='black', linewidth=1.5)
    ax.add_patch(head)
    
    # Torso
    ax.plot([x, x], [y - 2.0, y - 7.5], color='black', linewidth=1.5)
    
    # Arms
    ax.plot([x - 3.2, x + 3.2], [y - 4.5, y - 4.5], color='black', linewidth=1.5)
    
    # Legs
    ax.plot([x, x - 2.5], [y - 7.5, y - 13.0], color='black', linewidth=1.5)
    ax.plot([x, x + 2.5], [y - 7.5, y - 13.0], color='black', linewidth=1.5)
    
    # Label
    plt.text(x, y - 16.0, label, fontsize=10.5, fontweight='bold', ha='center', va='center', color='black')

# Draw Actors
draw_stickman(ax, 13, 38, "User\n(Student)")
draw_stickman(ax, 97, 38, "Super Admin")

# Association origins at actors' hands
user_hand = (16.2, 33.5)
admin_hand = (93.8, 33.5)

# Use Cases: (label, y_center, connect_user, connect_admin)
use_cases = [
    ("Take Quiz & Detect Learning Difficulty", 49, True, False),
    ("Recommend Targeted Study Materials", 37, True, False),
    ("Match Compatible Study Partners", 25, True, False),
    ("Manage Quizzes & System Content", 13, False, True),
]

for label, y, conn_user, conn_admin in use_cases:
    # Classic UML Ellipse (white interior, solid black outline)
    ellipse = patches.Ellipse((55, y), width=42, height=7.2, fill=True,
                              facecolor='white', edgecolor='black', linewidth=1.5)
    ax.add_patch(ellipse)
    plt.text(55, y, label, fontsize=9.2, ha='center', va='center', color='black')
    
    # Association Lines (pure black)
    if conn_user:
        # Left edge of ellipse is at x = 55 - 21 = 34
        ax.plot([user_hand[0], 34], [user_hand[1], y], color='black', linewidth=1.2)
    if conn_admin:
        # Right edge of ellipse is at x = 55 + 21 = 76
        ax.plot([admin_hand[0], 76], [admin_hand[1], y], color='black', linewidth=1.2)

# File destinations
output_path1 = r"c:\CCE106\StudyNest\use_case_diagram.png"
output_path2 = r"C:\Users\Acer\.gemini\antigravity\brain\70769586-880e-4119-ad1d-b119cd476d6b\use_case_diagram.png"

plt.tight_layout()
plt.savefig(output_path1, format='png', bbox_inches='tight', dpi=300)
shutil.copyfile(output_path1, output_path2)
print("Regenerated clean, simple black-and-white use case diagram.")
