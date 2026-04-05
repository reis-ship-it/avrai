#!/usr/bin/env python3
"""
Generate Visual Diagrams for Patent #31: Topological Knot Theory for Personality Representation

This script generates all 10 visual diagrams specified in the patent visuals document.
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Circle, Rectangle
from matplotlib.patches import ConnectionPatch
import numpy as np
from pathlib import Path
import sys

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Output directory
output_dir = project_root / 'docs' / 'patents' / 'category_1_quantum_ai_systems' / '31_topological_knot_theory_personality' / 'visuals'
output_dir.mkdir(parents=True, exist_ok=True)

def create_visual_1():
    """Visual 1: Personality Dimension to Braid Conversion"""
    fig, ax = plt.subplots(figsize=(10, 12))
    ax.axis('off')
    
    # Title
    ax.text(0.5, 0.95, 'Visual 1: Personality Dimension to Braid Conversion', 
            ha='center', va='top', fontsize=16, fontweight='bold')
    
    y_pos = 0.85
    step = 0.12
    
    # Step 1: Personality Profile
    box1 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08, 
                          boxstyle="round,pad=0.01", 
                          facecolor='lightblue', edgecolor='black', linewidth=2)
    ax.add_patch(box1)
    ax.text(0.5, y_pos, 'Personality Profile (12 Dimensions)\nd₁, d₂, d₃, d₄, d₅, d₆, d₇, d₈, d₉, d₁₀, d₁₁, d₁₂',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Arrow
    y_pos -= step
    arrow1 = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                             arrowstyle='->', mutation_scale=20, linewidth=2, color='black')
    ax.add_patch(arrow1)
    ax.text(0.5, y_pos, '↓', ha='center', va='center', fontsize=20)
    
    # Step 2: Correlation Matrix
    y_pos -= step
    box2 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightgreen', edgecolor='black', linewidth=2)
    ax.add_patch(box2)
    ax.text(0.5, y_pos, 'Correlation Matrix\nC(dᵢ, dⱼ) for all i, j',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Arrow
    y_pos -= step
    arrow2 = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                             arrowstyle='->', mutation_scale=20, linewidth=2, color='black')
    ax.add_patch(arrow2)
    ax.text(0.5, y_pos, '↓', ha='center', va='center', fontsize=20)
    
    # Step 3: Braid Crossings
    y_pos -= step
    box3 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightyellow', edgecolor='black', linewidth=2)
    ax.add_patch(box3)
    ax.text(0.5, y_pos, 'Braid Crossings\nC(d₁, d₄) > threshold → positive crossing',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Arrow
    y_pos -= step
    arrow3 = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                             arrowstyle='->', mutation_scale=20, linewidth=2, color='black')
    ax.add_patch(arrow3)
    ax.text(0.5, y_pos, '↓', ha='center', va='center', fontsize=20)
    
    # Step 4: Braid Sequence
    y_pos -= step
    box4 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightcoral', edgecolor='black', linewidth=2)
    ax.add_patch(box4)
    ax.text(0.5, y_pos, 'Braid Sequence B\n{c₁, c₂, ..., cₘ}',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Arrow
    y_pos -= step
    arrow4 = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                             arrowstyle='->', mutation_scale=20, linewidth=2, color='black')
    ax.add_patch(arrow4)
    ax.text(0.5, y_pos, '↓', ha='center', va='center', fontsize=20)
    
    # Step 5: Knot Closure
    y_pos -= step
    box5 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightpink', edgecolor='black', linewidth=2)
    ax.add_patch(box5)
    ax.text(0.5, y_pos, 'Knot Closure\nK = closure(B)',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Arrow
    y_pos -= step
    arrow5 = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                             arrowstyle='->', mutation_scale=20, linewidth=2, color='black')
    ax.add_patch(arrow5)
    ax.text(0.5, y_pos, '↓', ha='center', va='center', fontsize=20)
    
    # Step 6: Knot Invariants
    y_pos -= step
    box6 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lavender', edgecolor='black', linewidth=2)
    ax.add_patch(box6)
    ax.text(0.5, y_pos, 'Knot Invariants\nJones: J_K(q), Alexander: Δ_K(t), Crossing: c(K)',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_1_dimension_to_braid.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 1: Dimension to Braid Conversion")

def create_visual_2():
    """Visual 2: Multi-Dimensional Knot Spaces"""
    fig = plt.figure(figsize=(14, 10))
    
    # Title
    fig.suptitle('Visual 2: Multi-Dimensional Knot Spaces', fontsize=16, fontweight='bold', y=0.95)
    
    # 3D Knot Section
    ax1 = fig.add_subplot(2, 2, 1)
    ax1.axis('off')
    ax1.set_title('3D Knot (Classical): S¹ → R³', fontsize=12, fontweight='bold')
    
    # Draw simple knot representation
    theta = np.linspace(0, 2*np.pi, 100)
    x = np.cos(theta) + 0.5*np.cos(3*theta)
    y = np.sin(theta) + 0.5*np.sin(3*theta)
    z = 0.5*np.sin(2*theta)
    
    ax1.plot(x, y, 'b-', linewidth=2, label='Trefoil Knot')
    ax1.plot([-1.5, 1.5], [0, 0], 'k--', alpha=0.3)
    ax1.plot([0, 0], [-1.5, 1.5], 'k--', alpha=0.3)
    ax1.text(0, -1.8, 'Unknot: Simple\nTrefoil: 3 crossings\nFigure-8: 4 crossings\nConway: 11 crossings',
             ha='center', fontsize=9)
    ax1.set_xlim(-2, 2)
    ax1.set_ylim(-2, 2)
    ax1.set_aspect('equal')
    
    # 4D Knot Section
    ax2 = fig.add_subplot(2, 2, 2)
    ax2.axis('off')
    ax2.set_title('4D Knot (Temporal): S² → R⁴', fontsize=12, fontweight='bold')
    
    # Draw 4D representation (projection)
    t = np.linspace(0, 2*np.pi, 100)
    x4d = np.cos(t)
    y4d = np.sin(t)
    z4d = np.cos(2*t)
    w4d = np.sin(2*t)
    
    # Project to 2D
    ax2.plot(x4d, y4d, 'g-', linewidth=2, label='4D Knot Projection')
    ax2.text(0, -1.5, 'Slice knots: Can simplify\nNon-slice: Stable (Conway)\nPiccirillo (2020): 4D trace',
             ha='center', fontsize=9)
    ax2.set_xlim(-1.5, 1.5)
    ax2.set_ylim(-1.5, 1.5)
    ax2.set_aspect('equal')
    
    # 5D+ Knots Section
    ax3 = fig.add_subplot(2, 2, 3)
    ax3.axis('off')
    ax3.set_title('5D+ Knots (Contextual): S^(n-2) → Rⁿ', fontsize=12, fontweight='bold')
    
    # Draw dimensional progression
    dims = ['3D', '4D', '5D', '6D', '7D+']
    y_pos = np.arange(len(dims))
    
    for i, dim in enumerate(dims):
        ax3.barh(i, 1, color=plt.cm.viridis(i/len(dims)), alpha=0.7)
        if i == 0:
            ax3.text(0.5, i, f'{dim}: Personality', ha='center', va='center', fontweight='bold')
        elif i == 1:
            ax3.text(0.5, i, f'{dim}: + Time', ha='center', va='center', fontweight='bold')
        elif i == 2:
            ax3.text(0.5, i, f'{dim}: + Location', ha='center', va='center', fontweight='bold')
        elif i == 3:
            ax3.text(0.5, i, f'{dim}: + Social Network', ha='center', va='center', fontweight='bold')
        else:
            ax3.text(0.5, i, f'{dim}: + Mood, Energy', ha='center', va='center', fontweight='bold')
    
    ax3.set_xlim(0, 1)
    ax3.set_ylim(-0.5, len(dims)-0.5)
    ax3.set_xlabel('Dimensional Complexity', fontsize=10)
    ax3.set_yticks(y_pos)
    ax3.set_yticklabels(dims)
    
    # Summary
    ax4 = fig.add_subplot(2, 2, 4)
    ax4.axis('off')
    ax4.set_title('Summary', fontsize=12, fontweight='bold')
    
    summary_text = """
    Multi-Dimensional Representation:
    
    • 3D: Classical knots
       S¹ → R³
    
    • 4D: Temporal evolution
       S² → R⁴
       Slice/Non-slice distinction
    
    • 5D+: Contextual dimensions
       S^(n-2) → Rⁿ
       Rich contextual spaces
    """
    ax4.text(0.1, 0.5, summary_text, ha='left', va='center', fontsize=10, 
             family='monospace')
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_2_multidimensional_spaces.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 2: Multi-Dimensional Knot Spaces")

def create_visual_3():
    """Visual 3: Knot Weaving Patterns"""
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))
    fig.suptitle('Visual 3: Knot Weaving Patterns for Relationship Types', 
                 fontsize=16, fontweight='bold')
    
    # Friendship (Balanced)
    ax1 = axes[0, 0]
    ax1.axis('off')
    ax1.set_title('Friendship (Balanced)', fontsize=12, fontweight='bold')
    
    # Draw balanced interweaving
    x = np.linspace(0, 4, 100)
    y1 = np.sin(2*np.pi*x) * 0.3
    y2 = -np.sin(2*np.pi*x) * 0.3
    
    ax1.plot(x, y1, 'b-', linewidth=3, label='K_A')
    ax1.plot(x, y2, 'r-', linewidth=3, label='K_B')
    ax1.plot(x, (y1+y2)/2, 'g--', linewidth=2, alpha=0.5, label='Braided')
    ax1.text(2, 0.6, 'Balanced\nInterweaving', ha='center', fontsize=10, 
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    ax1.set_xlim(-0.5, 4.5)
    ax1.set_ylim(-1, 1)
    ax1.legend(loc='upper right')
    
    # Mentorship (Asymmetric)
    ax2 = axes[0, 1]
    ax2.axis('off')
    ax2.set_title('Mentorship (Asymmetric)', fontsize=12, fontweight='bold')
    
    # Draw asymmetric wrapping
    x = np.linspace(0, 4, 100)
    y_mentor = np.sin(2*np.pi*x) * 0.5
    y_mentee = np.zeros_like(x)
    
    ax2.plot(x, y_mentor, 'b-', linewidth=3, label='K_mentor')
    ax2.plot(x, y_mentee, 'r-', linewidth=3, label='K_mentee')
    ax2.text(2, 0.7, 'Asymmetric\nWrapping', ha='center', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.5))
    ax2.set_xlim(-0.5, 4.5)
    ax2.set_ylim(-1, 1)
    ax2.legend(loc='upper right')
    
    # Romantic (Deep)
    ax3 = axes[1, 0]
    ax3.axis('off')
    ax3.set_title('Romantic (Deep)', fontsize=12, fontweight='bold')
    
    # Draw deep interweaving
    x = np.linspace(0, 4, 100)
    y1 = np.sin(3*np.pi*x) * 0.4
    y2 = -np.sin(3*np.pi*x) * 0.4
    
    ax3.plot(x, y1, 'b-', linewidth=3, label='K_A')
    ax3.plot(x, y2, 'r-', linewidth=3, label='K_B')
    ax3.fill_between(x, y1, y2, alpha=0.3, color='purple')
    ax3.text(2, 0.6, 'Deep\nInterweaving', ha='center', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='pink', alpha=0.5))
    ax3.set_xlim(-0.5, 4.5)
    ax3.set_ylim(-1, 1)
    ax3.legend(loc='upper right')
    
    # Collaborative (Parallel)
    ax4 = axes[1, 1]
    ax4.axis('off')
    ax4.set_title('Collaborative (Parallel)', fontsize=12, fontweight='bold')
    
    # Draw parallel with crossings
    x = np.linspace(0, 4, 100)
    y1 = np.ones_like(x) * 0.3
    y2 = np.ones_like(x) * -0.3
    
    ax4.plot(x, y1, 'b-', linewidth=3, label='K_A')
    ax4.plot(x, y2, 'r-', linewidth=3, label='K_B')
    # Add crossings
    for i in range(3):
        x_cross = 1 + i * 1.5
        ax4.plot([x_cross-0.2, x_cross+0.2], [-0.3, 0.3], 'g-', linewidth=2, alpha=0.7)
        ax4.plot([x_cross-0.2, x_cross+0.2], [0.3, -0.3], 'g-', linewidth=2, alpha=0.7)
    
    ax4.text(2, 0.6, 'Parallel with\nCrossings', ha='center', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.5))
    ax4.set_xlim(-0.5, 4.5)
    ax4.set_ylim(-1, 1)
    ax4.legend(loc='upper right')
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_3_weaving_patterns.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 3: Knot Weaving Patterns")

def create_visual_4():
    """Visual 4: Integrated Compatibility Formula"""
    fig, ax = plt.subplots(figsize=(12, 10))
    ax.axis('off')
    
    # Title
    ax.text(0.5, 0.95, 'Visual 4: Integrated Compatibility Formula', 
            ha='center', va='top', fontsize=16, fontweight='bold')
    
    # Main formula
    formula_y = 0.75
    formula_box = FancyBboxPatch((0.1, formula_y-0.1), 0.8, 0.15,
                                 boxstyle="round,pad=0.02",
                                 facecolor='lightblue', edgecolor='black', linewidth=3)
    ax.add_patch(formula_box)
    ax.text(0.5, formula_y, 'C_integrated = α · C_quantum + β · C_topological',
            ha='center', va='center', fontsize=18, fontweight='bold', family='serif')
    
    # Weights
    weights_y = 0.55
    weights_text = 'Where:\nα = 0.7 (quantum weight)\nβ = 0.3 (topological weight)'
    ax.text(0.5, weights_y, weights_text, ha='center', va='center', 
            fontsize=14, bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.7))
    
    # Quantum component
    quantum_y = 0.35
    quantum_box = FancyBboxPatch((0.1, quantum_y-0.08), 0.8, 0.1,
                                 boxstyle="round,pad=0.02",
                                 facecolor='lightgreen', edgecolor='black', linewidth=2)
    ax.add_patch(quantum_box)
    ax.text(0.5, quantum_y, 'C_quantum = |⟨ψ_A|ψ_B⟩|²\n(from Patent #1)',
            ha='center', va='center', fontsize=14, fontweight='bold')
    
    # Topological component
    topo_y = 0.15
    topo_box = FancyBboxPatch((0.1, topo_y-0.1), 0.8, 0.15,
                              boxstyle="round,pad=0.02",
                              facecolor='lightcoral', edgecolor='black', linewidth=2)
    ax.add_patch(topo_box)
    topo_text = 'C_topological = α·(1-d_J) + β·(1-d_Δ) + γ·(1-d_c/N)\n(knot invariants)'
    ax.text(0.5, topo_y, topo_text, ha='center', va='center', 
            fontsize=14, fontweight='bold')
    
    # Result
    result_y = 0.02
    result_text = 'Result: Enhanced matching accuracy'
    ax.text(0.5, result_y, result_text, ha='center', va='bottom',
            fontsize=14, fontweight='bold', style='italic',
            bbox=dict(boxstyle='round', facecolor='gold', alpha=0.7))
    
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_4_integrated_formula.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 4: Integrated Compatibility Formula")

def create_visual_5():
    """Visual 5: Dynamic Knot Evolution"""
    fig, ax = plt.subplots(figsize=(14, 8))
    
    # Title
    ax.text(0.5, 0.95, 'Visual 5: Dynamic Knot Evolution', 
            ha='center', va='top', fontsize=16, fontweight='bold')
    
    # Time points
    times = ['t₀', 't₁', 't₂', 't₃', 't₄']
    x_pos = np.linspace(0.1, 0.9, len(times))
    
    # Knot types
    knot_types = ['Trefoil', 'Trefoil', 'Figure-8', 'Figure-8', 'Trefoil']
    complexities = [0.3, 0.4, 0.6, 0.5, 0.3]
    moods = ['Calm', 'Happy', 'Stressed', 'Relaxed', 'Calm']
    
    # Draw timeline
    for i, (t, kt, comp, mood) in enumerate(zip(times, knot_types, complexities, moods)):
        y_base = 0.7
        
        # Time label
        ax.text(x_pos[i], y_base + 0.15, t, ha='center', va='bottom', 
                fontsize=12, fontweight='bold')
        
        # Knot representation (circle size based on complexity)
        circle = Circle((x_pos[i], y_base), comp*0.1, 
                       color=plt.cm.viridis(comp), alpha=0.7, linewidth=2)
        ax.add_patch(circle)
        
        # Knot type
        ax.text(x_pos[i], y_base - 0.1, kt, ha='center', va='top', 
                fontsize=10, fontweight='bold')
        
        # Complexity
        ax.text(x_pos[i], y_base - 0.18, f'{comp:.1f}', ha='center', va='top',
                fontsize=9)
        
        # Mood
        ax.text(x_pos[i], y_base - 0.26, mood, ha='center', va='top',
                fontsize=9, style='italic')
        
        # Arrow to next
        if i < len(times) - 1:
            arrow = FancyArrowPatch((x_pos[i]+0.05, y_base), (x_pos[i+1]-0.05, y_base),
                                   arrowstyle='->', mutation_scale=15, linewidth=2)
            ax.add_patch(arrow)
    
    # Milestone annotation
    ax.annotate('Milestone: Knot type change\n(Trefoil → Figure-8)', 
                xy=(x_pos[2], y_base + 0.05), xytext=(x_pos[2], y_base + 0.3),
                arrowprops=dict(arrowstyle='->', lw=2, color='red'),
                fontsize=11, fontweight='bold', ha='center',
                bbox=dict(boxstyle='round', facecolor='yellow', alpha=0.7))
    
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis('off')
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_5_dynamic_evolution.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 5: Dynamic Knot Evolution")

def create_visual_6():
    """Visual 6: Knot Invariants Comparison"""
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('Visual 6: Knot Invariants Comparison', fontsize=16, fontweight='bold')
    
    # Jones Polynomial
    ax1 = axes[0, 0]
    ax1.axis('off')
    ax1.set_title('Jones Polynomial Distance', fontsize=12, fontweight='bold')
    
    poly_text = """
    J_A(q) = q + q³ - q⁴
    
    J_B(q) = q + q³ - q⁵
    
    d_J = distance(J_A, J_B)
    """
    ax1.text(0.5, 0.5, poly_text, ha='center', va='center', fontsize=12,
             family='monospace', bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.5))
    
    # Alexander Polynomial
    ax2 = axes[0, 1]
    ax2.axis('off')
    ax2.set_title('Alexander Polynomial Distance', fontsize=12, fontweight='bold')
    
    alex_text = """
    Δ_A(t) = t² - t + 1
    
    Δ_B(t) = t² - 2t + 1
    
    d_Δ = distance(Δ_A, Δ_B)
    """
    ax2.text(0.5, 0.5, alex_text, ha='center', va='center', fontsize=12,
             family='monospace', bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.5))
    
    # Combined Topological
    ax3 = axes[1, 0]
    ax3.axis('off')
    ax3.set_title('Combined Topological Compatibility', fontsize=12, fontweight='bold')
    
    combined_text = """
    C_topological = 0.4·(1-d_J) + 
                    0.4·(1-d_Δ) + 
                    0.2·(1-d_c/N)
    """
    ax3.text(0.5, 0.5, combined_text, ha='center', va='center', fontsize=14,
             family='monospace', fontweight='bold',
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.7))
    
    # Enhanced with 4D
    ax4 = axes[1, 1]
    ax4.axis('off')
    ax4.set_title('Enhanced with 4D Invariants', fontsize=12, fontweight='bold')
    
    enhanced_text = """
    C_topological_enhanced = 
        0.3·(1-d_J) + 
        0.3·(1-d_Δ) + 
        0.2·(1-d_c/N) + 
        0.2·slice_compatibility
    
    slice_compatibility:
    • 1.0 if both slice/non-slice
    • 0.5 if one slice, one non-slice
    """
    ax4.text(0.5, 0.5, enhanced_text, ha='center', va='center', fontsize=10,
             family='monospace',
             bbox=dict(boxstyle='round', facecolor='lavender', alpha=0.7))
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_6_invariants_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 6: Knot Invariants Comparison")

def create_visual_6a():
    """Visual 6a: Conway Knot Problem"""
    fig, axes = plt.subplots(1, 3, figsize=(16, 6))
    fig.suptitle('Visual 6a: Conway Knot Problem - Invariant Limitations', 
                 fontsize=16, fontweight='bold')
    
    # The Problem
    ax1 = axes[0]
    ax1.axis('off')
    ax1.set_title('The Problem', fontsize=12, fontweight='bold')
    
    problem_text = """
    Conway Knot (11 crossings):
    
    • Jones polynomial: 
      J_Conway(q) = 1
      (same as unknot!)
    
    • Alexander polynomial: 
      Δ_Conway(t) = 1
      (same as unknot!)
    
    • Conway polynomial: 
      ∇_Conway(z) = 1
      (same as unknot!)
    
    Yet: Conway knot ≠ Unknot
         (fundamentally different!)
    
    Standard Invariants: FAIL
    4D Analysis Required: 
    Slice/Non-Slice property
    """
    ax1.text(0.5, 0.5, problem_text, ha='center', va='center', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.7))
    
    # Piccirillo's Solution
    ax2 = axes[1]
    ax2.axis('off')
    ax2.set_title("Piccirillo's Solution (2020)", fontsize=12, fontweight='bold')
    
    solution_text = """
    Conway Knot Problem
    (1970-2020):
    Open for 50 years
    
    Question: Is Conway knot slice?
    
    Piccirillo's Method:
    1. Construct knot with same 
       4D trace as Conway
    2. Prove constructed knot 
       is non-slice
    3. Therefore: Conway knot 
       is non-slice
    
    Result: Conway knot is NOT slice
    """
    ax2.text(0.5, 0.5, solution_text, ha='center', va='center', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.7))
    
    # Personality Application
    ax3 = axes[2]
    ax3.axis('off')
    ax3.set_title('Personality Application', fontsize=12, fontweight='bold')
    
    app_text = """
    Conway-like Personalities:
    
    • Appear simple by standard 
      metrics (Jones/Alexander)
    
    • But are fundamentally 
      complex (non-slice)
    
    • Require 4D analysis for 
      complete classification
    
    Standard Compatibility: 
    May miss Conway-like 
    personalities
    
    Enhanced Compatibility: 
    4D invariants catch them
    """
    ax3.text(0.5, 0.5, app_text, ha='center', va='center', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.7))
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_6a_conway_knot_problem.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 6a: Conway Knot Problem")

def create_visual_7():
    """Visual 7: Knot-Based Community Discovery"""
    fig, ax = plt.subplots(figsize=(10, 8))
    ax.axis('off')
    
    # Title
    ax.text(0.5, 0.95, 'Visual 7: Knot-Based Community Discovery', 
            ha='center', va='top', fontsize=16, fontweight='bold')
    
    # Trefoil Group
    trefoil_y = 0.7
    ax.text(0.2, trefoil_y + 0.1, 'Trefoil Group', ha='center', va='bottom',
            fontsize=14, fontweight='bold')
    
    users_trefoil = ['User A', 'User B', 'User C', 'User D']
    for i, user in enumerate(users_trefoil):
        y = trefoil_y - i * 0.08
        # User node
        circle = Circle((0.1, y), 0.03, color='blue', alpha=0.7)
        ax.add_patch(circle)
        ax.text(0.05, y, user, ha='right', va='center', fontsize=10)
        # Connection line
        if i < len(users_trefoil) - 1:
            ax.plot([0.1, 0.1], [y-0.03, y-0.05], 'b-', linewidth=2)
    
    # Group box
    group_box1 = FancyBboxPatch((0.15, trefoil_y - 0.25), 0.3, 0.15,
                               boxstyle="round,pad=0.01",
                               facecolor='lightblue', edgecolor='blue', linewidth=2)
    ax.add_patch(group_box1)
    ax.text(0.3, trefoil_y - 0.175, 'Knot Tribe:\nTrefoil Group', 
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Arrow to group
    arrow1 = FancyArrowPatch((0.15, trefoil_y - 0.1), (0.2, trefoil_y - 0.175),
                            arrowstyle='->', mutation_scale=15, linewidth=2, color='blue')
    ax.add_patch(arrow1)
    
    # Figure-8 Group
    fig8_y = 0.35
    ax.text(0.7, fig8_y + 0.1, 'Figure-8 Group', ha='center', va='bottom',
            fontsize=14, fontweight='bold')
    
    users_fig8 = ['User E', 'User F']
    for i, user in enumerate(users_fig8):
        y = fig8_y - i * 0.08
        # User node
        circle = Circle((0.9, y), 0.03, color='green', alpha=0.7)
        ax.add_patch(circle)
        ax.text(0.95, y, user, ha='left', va='center', fontsize=10)
        # Connection line
        if i < len(users_fig8) - 1:
            ax.plot([0.9, 0.9], [y-0.03, y-0.05], 'g-', linewidth=2)
    
    # Group box
    group_box2 = FancyBboxPatch((0.55, fig8_y - 0.1), 0.3, 0.15,
                               boxstyle="round,pad=0.01",
                               facecolor='lightgreen', edgecolor='green', linewidth=2)
    ax.add_patch(group_box2)
    ax.text(0.7, fig8_y - 0.025, 'Knot Tribe:\nFigure-8 Group', 
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Arrow to group
    arrow2 = FancyArrowPatch((0.85, fig8_y - 0.05), (0.75, fig8_y - 0.025),
                            arrowstyle='->', mutation_scale=15, linewidth=2, color='green')
    ax.add_patch(arrow2)
    
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_7_community_discovery.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 7: Knot-Based Community Discovery")

def create_visual_8():
    """Visual 8: Higher-Dimensional Knot Embeddings"""
    fig, axes = plt.subplots(1, 3, figsize=(16, 6))
    fig.suptitle('Visual 8: Higher-Dimensional Knot Embeddings', 
                fontsize=16, fontweight='bold')
    
    # 4D: Personality + Time
    ax1 = axes[0]
    ax1.axis('off')
    ax1.set_title('4D: Personality + Time', fontsize=12, fontweight='bold')
    
    # Draw 3D + Time
    box_3d = FancyBboxPatch((0.2, 0.5), 0.3, 0.2,
                            boxstyle="round,pad=0.01",
                            facecolor='lightblue', edgecolor='black', linewidth=2)
    ax1.add_patch(box_3d)
    ax1.text(0.35, 0.6, '3D Personality\nSpace', ha='center', va='center', fontsize=10)
    
    ax1.text(0.5, 0.6, '+', ha='center', va='center', fontsize=20, fontweight='bold')
    
    box_time = FancyBboxPatch((0.6, 0.5), 0.3, 0.2,
                              boxstyle="round,pad=0.01",
                              facecolor='lightgreen', edgecolor='black', linewidth=2)
    ax1.add_patch(box_time)
    ax1.text(0.75, 0.6, 'Time\nDimension', ha='center', va='center', fontsize=10)
    
    ax1.text(0.5, 0.4, '=', ha='center', va='center', fontsize=20, fontweight='bold')
    
    result_box = FancyBboxPatch((0.3, 0.1), 0.4, 0.2,
                               boxstyle="round,pad=0.01",
                               facecolor='wheat', edgecolor='black', linewidth=2)
    ax1.add_patch(result_box)
    ax1.text(0.5, 0.2, '4D Knot\n(S² → R⁴)', ha='center', va='center', 
            fontsize=11, fontweight='bold')
    
    # 5D: Personality + Time + Context
    ax2 = axes[1]
    ax2.axis('off')
    ax2.set_title('5D: Personality + Time + Context', fontsize=12, fontweight='bold')
    
    box_4d = FancyBboxPatch((0.1, 0.5), 0.25, 0.2,
                            boxstyle="round,pad=0.01",
                            facecolor='wheat', edgecolor='black', linewidth=2)
    ax2.add_patch(box_4d)
    ax2.text(0.225, 0.6, '4D Knot', ha='center', va='center', fontsize=10)
    
    ax2.text(0.4, 0.6, '+', ha='center', va='center', fontsize=20, fontweight='bold')
    
    box_context = FancyBboxPatch((0.5, 0.5), 0.4, 0.2,
                                boxstyle="round,pad=0.01",
                                facecolor='lightcoral', edgecolor='black', linewidth=2)
    ax2.add_patch(box_context)
    ax2.text(0.7, 0.6, 'Context Dimension\n(Location/Mood)', ha='center', va='center', fontsize=9)
    
    ax2.text(0.5, 0.4, '=', ha='center', va='center', fontsize=20, fontweight='bold')
    
    result_box2 = FancyBboxPatch((0.3, 0.1), 0.4, 0.2,
                                 boxstyle="round,pad=0.01",
                                 facecolor='lavender', edgecolor='black', linewidth=2)
    ax2.add_patch(result_box2)
    ax2.text(0.5, 0.2, '5D Knot\n(S³ → R⁵)', ha='center', va='center',
            fontsize=11, fontweight='bold')
    
    # General n-Dimensional
    ax3 = axes[2]
    ax3.axis('off')
    ax3.set_title('General n-Dimensional', fontsize=12, fontweight='bold')
    
    formula_text = """
    Base: 12D Personality
    
    Add: Time, Context₁, 
         Context₂, ..., 
         Contextₙ
    
    Result: (12+n)D Knot
    """
    ax3.text(0.5, 0.5, formula_text, ha='center', va='center', fontsize=11,
            family='monospace',
            bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.7))
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_8_higher_dimensional.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 8: Higher-Dimensional Knot Embeddings")

def create_visual_9():
    """Visual 9: Knot Generation Algorithm Flow"""
    fig, ax = plt.subplots(figsize=(10, 12))
    ax.axis('off')
    
    # Title
    ax.text(0.5, 0.95, 'Visual 9: Knot Generation Algorithm Flow', 
            ha='center', va='top', fontsize=16, fontweight='bold')
    
    y_pos = 0.85
    step = 0.12
    
    # Input
    box0 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightblue', edgecolor='black', linewidth=2)
    ax.add_patch(box0)
    ax.text(0.5, y_pos, 'Input: Personality Profile P',
            ha='center', va='center', fontsize=12, fontweight='bold')
    
    # Step 1
    y_pos -= step
    arrow = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                           arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow)
    
    y_pos -= step
    box1 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightgreen', edgecolor='black', linewidth=2)
    ax.add_patch(box1)
    ax.text(0.5, y_pos, 'Step 1: Calculate Correlations\nC(dᵢ, dⱼ) for all i, j',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Step 2
    y_pos -= step
    arrow = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                           arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow)
    
    y_pos -= step
    box2 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightyellow', edgecolor='black', linewidth=2)
    ax.add_patch(box2)
    ax.text(0.5, y_pos, 'Step 2: Create Crossings\nIf |C(dᵢ, dⱼ)| > threshold: Create crossing',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Step 3
    y_pos -= step
    arrow = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                           arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow)
    
    y_pos -= step
    box3 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightcoral', edgecolor='black', linewidth=2)
    ax.add_patch(box3)
    ax.text(0.5, y_pos, 'Step 3: Generate Braid\nB = {c₁, c₂, ..., cₘ}',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Step 4
    y_pos -= step
    arrow = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                           arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow)
    
    y_pos -= step
    box4 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lightpink', edgecolor='black', linewidth=2)
    ax.add_patch(box4)
    ax.text(0.5, y_pos, 'Step 4: Close Braid\nK = closure(B)',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Step 5
    y_pos -= step
    arrow = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                           arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow)
    
    y_pos -= step
    box5 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='lavender', edgecolor='black', linewidth=2)
    ax.add_patch(box5)
    ax.text(0.5, y_pos, 'Step 5: Calculate Invariants\nJ_K(q), Δ_K(t), c(K)',
            ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Output
    y_pos -= step
    arrow = FancyArrowPatch((0.5, y_pos+0.05), (0.5, y_pos-0.05),
                           arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow)
    
    y_pos -= step
    box6 = FancyBboxPatch((0.1, y_pos-0.05), 0.8, 0.08,
                          boxstyle="round,pad=0.01",
                          facecolor='gold', edgecolor='black', linewidth=3)
    ax.add_patch(box6)
    ax.text(0.5, y_pos, 'Output: Knot K with invariants',
            ha='center', va='center', fontsize=12, fontweight='bold')
    
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_9_algorithm_flow.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 9: Knot Generation Algorithm Flow")

def create_visual_10():
    """Visual 10: Integrated System Architecture"""
    fig, ax = plt.subplots(figsize=(10, 12))
    ax.axis('off')
    
    # Title
    ax.text(0.5, 0.95, 'Visual 10: Integrated System Architecture', 
            ha='center', va='top', fontsize=16, fontweight='bold')
    
    y_pos = 0.85
    step = 0.15
    
    # Input
    input_box = FancyBboxPatch((0.2, y_pos-0.04), 0.6, 0.06,
                               boxstyle="round,pad=0.01",
                               facecolor='lightblue', edgecolor='black', linewidth=2)
    ax.add_patch(input_box)
    ax.text(0.5, y_pos-0.01, 'Personality Profile',
            ha='center', va='center', fontsize=12, fontweight='bold')
    
    # Arrow
    y_pos -= step
    arrow1 = FancyArrowPatch((0.5, y_pos+0.04), (0.5, y_pos-0.04),
                            arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow1)
    
    # Quantum System
    y_pos -= step
    quantum_box = FancyBboxPatch((0.15, y_pos-0.06), 0.7, 0.1,
                                 boxstyle="round,pad=0.01",
                                 facecolor='lightgreen', edgecolor='black', linewidth=2)
    ax.add_patch(quantum_box)
    ax.text(0.5, y_pos, 'Quantum System\n(Patent #1)',
            ha='center', va='center', fontsize=12, fontweight='bold')
    
    # Output arrow
    output_arrow1 = FancyArrowPatch((0.85, y_pos), (0.95, y_pos),
                                   arrowstyle='->', mutation_scale=15, linewidth=2, color='green')
    ax.add_patch(output_arrow1)
    ax.text(0.9, y_pos+0.08, 'C_quantum', ha='center', va='bottom', fontsize=10, 
            fontweight='bold', color='green')
    
    # Arrow
    y_pos -= step
    arrow2 = FancyArrowPatch((0.5, y_pos+0.06), (0.5, y_pos-0.04),
                             arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow2)
    
    # Knot System
    y_pos -= step
    knot_box = FancyBboxPatch((0.15, y_pos-0.06), 0.7, 0.1,
                              boxstyle="round,pad=0.01",
                              facecolor='lightcoral', edgecolor='black', linewidth=2)
    ax.add_patch(knot_box)
    ax.text(0.5, y_pos, 'Knot System\n(Patent #31)',
            ha='center', va='center', fontsize=12, fontweight='bold')
    
    # Output arrow
    output_arrow2 = FancyArrowPatch((0.85, y_pos), (0.95, y_pos),
                                    arrowstyle='->', mutation_scale=15, linewidth=2, color='red')
    ax.add_patch(output_arrow2)
    ax.text(0.9, y_pos+0.08, 'C_topological', ha='center', va='bottom', fontsize=10,
            fontweight='bold', color='red')
    
    # Arrow
    y_pos -= step
    arrow3 = FancyArrowPatch((0.5, y_pos+0.06), (0.5, y_pos-0.04),
                             arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow3)
    
    # Integrated System
    y_pos -= step
    integrated_box = FancyBboxPatch((0.15, y_pos-0.06), 0.7, 0.1,
                                    boxstyle="round,pad=0.01",
                                    facecolor='gold', edgecolor='black', linewidth=3)
    ax.add_patch(integrated_box)
    ax.text(0.5, y_pos, 'Integrated Compatibility',
            ha='center', va='center', fontsize=12, fontweight='bold')
    
    # Output arrow
    output_arrow3 = FancyArrowPatch((0.85, y_pos), (0.95, y_pos),
                                    arrowstyle='->', mutation_scale=15, linewidth=2, color='orange')
    ax.add_patch(output_arrow3)
    ax.text(0.9, y_pos+0.08, 'C_integrated', ha='center', va='bottom', fontsize=10,
            fontweight='bold', color='orange')
    
    # Arrow
    y_pos -= step
    arrow4 = FancyArrowPatch((0.5, y_pos+0.06), (0.5, y_pos-0.04),
                             arrowstyle='->', mutation_scale=20, linewidth=2)
    ax.add_patch(arrow4)
    
    # Final output
    y_pos -= step
    output_box = FancyBboxPatch((0.2, y_pos-0.04), 0.6, 0.06,
                                boxstyle="round,pad=0.01",
                                facecolor='lavender', edgecolor='black', linewidth=2)
    ax.add_patch(output_box)
    ax.text(0.5, y_pos-0.01, 'Matching & Recommendations',
            ha='center', va='center', fontsize=12, fontweight='bold')
    
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    
    plt.tight_layout()
    plt.savefig(output_dir / 'visual_10_system_architecture.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✅ Created Visual 10: Integrated System Architecture")

def main():
    """Generate all visual diagrams."""
    print("=" * 80)
    print("Generating Patent #31 Visual Diagrams")
    print("=" * 80)
    print()
    
    try:
        create_visual_1()
        create_visual_2()
        create_visual_3()
        create_visual_4()
        create_visual_5()
        create_visual_6()
        create_visual_6a()
        create_visual_7()
        create_visual_8()
        create_visual_9()
        create_visual_10()
        
        print()
        print("=" * 80)
        print("✅ All visual diagrams generated successfully!")
        print(f"📁 Output directory: {output_dir}")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ Error generating visuals: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()

